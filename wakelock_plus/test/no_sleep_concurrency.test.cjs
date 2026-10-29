// Regression tests for browser Wake Lock and video fallback concurrency.
// Run: node --test wakelock_plus/test/no_sleep_concurrency.test.cjs
const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

const sourcePath = path.join(__dirname, '..', 'lib', 'assets', 'no_sleep.js')
const flush = () => new Promise(resolve => setImmediate(resolve))

function deferred() {
  let resolve
  let reject
  const promise = new Promise((yes, no) => { resolve = yes; reject = no })
  return { promise, resolve, reject }
}

function browser(native) {
  const requests = []
  const plays = []
  const video = {
    paused: true,
    setAttribute() {},
    addEventListener() {},
    appendChild() {},
    play() {
      const request = deferred()
      plays.push(request)
      return request.promise.then(() => { video.paused = false })
    },
    pause() { video.paused = true },
  }
  const document = {
    visibilityState: 'visible',
    addEventListener() {},
    createElement(tag) {
      if (tag === 'video') return video
      if (tag === 'source') return {}
      throw new Error('Unexpected element: ' + tag)
    },
  }
  const navigator = native ? { wakeLock: { request(type) {
    assert.equal(type, 'screen')
    const request = deferred()
    requests.push(request)
    return request.promise
  } } } : {}
  const sandbox = vm.createContext({ navigator, document, console, setTimeout, clearTimeout })
  vm.runInContext(fs.readFileSync(sourcePath, 'utf8'), sandbox, { filename: sourcePath })
  const NoSleep = vm.runInContext('NoSleep', sandbox)
  const noSleep = new NoSleep()
  function createLock() {
    const handlers = []
    let releases = 0
    return {
      addEventListener(name, fn) { assert.equal(name, 'release'); handlers.push(fn) },
      async release() { releases++; handlers.forEach(fn => fn()) },
      emitRelease() { handlers.forEach(fn => fn()) },
      get releases() { return releases },
    }
  }
  return { noSleep, requests, plays, video, createLock }
}

test('native: concurrent enable calls share a single request', async () => {
  const b = browser(true)
  const all = [b.noSleep.enable(), b.noSleep.enable(), b.noSleep.enable()]
  await flush()
  assert.equal(b.requests.length, 1)
  b.requests[0].resolve(b.createLock())
  await Promise.all(all)
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('native: concurrent request rejection reaches each caller', async () => {
  const b = browser(true)
  const all = [b.noSleep.enable(), b.noSleep.enable()]
  await flush()
  assert.equal(b.requests.length, 1)
  b.requests[0].reject(Object.assign(new Error('activation required'), { name: 'NotAllowedError' }))
  assert.deepEqual((await Promise.allSettled(all)).map(x => x.status), ['rejected', 'rejected'])
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('native: disable during pending request releases resulting lock', async () => {
  const b = browser(true)
  const enable = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  const lock = b.createLock()
  b.requests[0].resolve(lock)
  await Promise.all([enable, disable])
  assert.equal(lock.releases, 1)
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('native: enable-disable-enable preserves last requested state', async () => {
  const b = browser(true)
  const first = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  const second = b.noSleep.enable()
  b.requests[0].resolve(b.createLock())
  await flush()
  if (b.requests[1]) b.requests[1].resolve(b.createLock())
  await Promise.all([first, disable, second])
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('native: redundant enable does not request a second lock', async () => {
  const b = browser(true)
  const enable = b.noSleep.enable()
  await flush()
  const lock = b.createLock()
  b.requests[0].resolve(lock)
  await enable
  await b.noSleep.enable()
  assert.equal(b.requests.length, 1)
  assert.equal(lock.releases, 0)
})

test('native: rejected request permits later retry', async () => {
  const b = browser(true)
  const first = b.noSleep.enable()
  await flush()
  b.requests[0].reject(new Error('denied'))
  await assert.rejects(first)
  const retry = b.noSleep.enable()
  await flush()
  assert.equal(b.requests.length, 2)
  b.requests[1].resolve(b.createLock())
  await retry
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('native: disable after failure remains safe', async () => {
  const b = browser(true)
  const enable = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  b.requests[0].reject(new Error('denied'))
  await assert.rejects(enable)
  await assert.doesNotReject(disable)
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('native: stale release event cannot clear a newer wake lock', async () => {
  const b = browser(true)
  const first = b.noSleep.enable()
  await flush()
  const previous = b.createLock()
  b.requests[0].resolve(previous)
  await first
  await b.noSleep.disable()
  const second = b.noSleep.enable()
  await flush()
  b.requests[1].resolve(b.createLock())
  await second
  previous.emitRelease()
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('native: external release updates enabled state', async () => {
  const b = browser(true)
  const enable = b.noSleep.enable()
  await flush()
  const lock = b.createLock()
  b.requests[0].resolve(lock)
  await enable
  lock.emitRelease()
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('fallback: concurrent enables share a single play request', async () => {
  const b = browser(false)
  const all = [b.noSleep.enable(), b.noSleep.enable(), b.noSleep.enable()]
  await flush()
  assert.equal(b.plays.length, 1)
  b.plays[0].resolve()
  await Promise.all(all)
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('fallback: rejected play reaches callers and later retry works', async () => {
  const b = browser(false)
  const all = [b.noSleep.enable(), b.noSleep.enable()]
  await flush()
  assert.equal(b.plays.length, 1)
  b.plays[0].reject(new Error('denied'))
  assert.deepEqual((await Promise.allSettled(all)).map(x => x.status), ['rejected', 'rejected'])
  const retry = b.noSleep.enable()
  await flush()
  assert.equal(b.plays.length, 2)
  b.plays[1].resolve()
  await retry
  assert.equal(await b.noSleep.isEnabled(), true)
})

test('fallback: disable during play ends paused', async () => {
  const b = browser(false)
  const enable = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  b.plays[0].resolve()
  await Promise.all([enable, disable])
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('fallback: disable after play rejection succeeds', async () => {
  const b = browser(false)
  const enable = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  b.plays[0].reject(new Error('denied'))
  await assert.rejects(enable)
  await assert.doesNotReject(disable)
  assert.equal(await b.noSleep.isEnabled(), false)
})

test('fallback: enable-disable-enable ends playing', async () => {
  const b = browser(false)
  const first = b.noSleep.enable()
  await flush()
  const disable = b.noSleep.disable()
  const second = b.noSleep.enable()
  b.plays[0].resolve()
  await flush()
  if (b.plays[1]) b.plays[1].resolve()
  await Promise.all([first, disable, second])
  assert.equal(await b.noSleep.isEnabled(), true)
})


test('fallback: first play remains synchronous for user activation', async () => {
  const b = browser(false)
  const enabling = b.noSleep.enable()
  assert.equal(b.plays.length, 1, 'play() should run during the event handler')
  b.plays[0].resolve()
  await enabling
})
