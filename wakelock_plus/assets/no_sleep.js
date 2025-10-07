// NoSleep — Bug-fixed, Feature-complete single-file script
// Includes: reliable native wake lock handling, robust fallback video strategy,
// event system, diagnostics, safe async flows, and a small embedded UI panel
// that can be dropped onto any page. Keep the webm/mp4 dataURIs as placeholders
// (replace with full data URIs if you want) so the file remains readable here.

var webm = 'data:video/webm;base64,REPLACE_WEBM_BASE64'
var mp4 = 'data:video/mp4;base64,REPLACE_MP4_BASE64'

// ===== Helpers =====
function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i]
    descriptor.enumerable = descriptor.enumerable || false
    descriptor.configurable = true
    if ('value' in descriptor) descriptor.writable = true
    Object.defineProperty(target, descriptor.key, descriptor)
  }
}
function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps)
  if (staticProps) _defineProperties(Constructor, staticProps)
  return Constructor
}
function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError('Cannot call a class as a function')
  }
}

// ===== Environment detection (robust) =====
var isNavigatorAvailable = typeof navigator !== 'undefined' && navigator !== null
var userAgent = isNavigatorAvailable ? navigator.userAgent || '' : ''
var oldIOS = (function () {
  try {
    var match = /CPU.*OS ([0-9_]{3,4})[0-9_]{0,1}|(CPU like).*AppleWebKit.*Mobile/i.exec(userAgent)
    var ver = (match && match[1]) || ''
    ver = ver.replace('_', '.')
    var num = parseFloat(ver || '3.2')
    return !window.MSStream && num > 0 && num < 10
  } catch (e) {
    return false
  }
})()
var nativeWakeLock = isNavigatorAvailable && 'wakeLock' in navigator

// ===== NoSleep Class =====
var NoSleep = (function () {
  var _releasedNative = true

  function NoSleep(opts) {
    _classCallCheck(this, NoSleep)
    opts = opts || {}

    // internal state
    this._wakeLock = null
    this._eventHandlers = {}
    this._videoAttached = false
    this._video = null
    this._opts = opts

    // Prepare fallback video element if needed
    if (!nativeWakeLock) this._prepareVideoFallback()

    // Bind visibility handlers only when native wake lock support exists
    if (nativeWakeLock) {
      var self = this
      var visibilityHandler = function () {
        if (document.visibilityState === 'visible' && self._wakeLock == null && !self.isEnabled()) {
          // Try to re-acquire if previously enabled
          // (do not auto-enable if user hasn't explicitly enabled)
          // We don't automatically re-request here to avoid UX surprises.
        }
      }
      document.addEventListener('visibilitychange', visibilityHandler)
    }
  }

  _createClass(NoSleep, [
    {
      key: '_prepareVideoFallback',
      value: function _prepareVideoFallback() {
        // create a hidden video element and add two sources
        var v = document.createElement('video')
        v.setAttribute('playsinline', '')
        v.setAttribute('muted', '')
        v.setAttribute('preload', 'auto')
        v.style.position = 'fixed'
        v.style.left = '-9999px'
        v.style.width = '1px'
        v.style.height = '1px'
        v.style.opacity = '0'
        v.setAttribute('aria-hidden', 'true')

        // add sources if provided
        if (typeof webm === 'string' && webm.indexOf('data:video') === 0) {
          var s1 = document.createElement('source')
          s1.type = 'video/webm'
          s1.src = webm
          v.appendChild(s1)
        }
        if (typeof mp4 === 'string' && mp4.indexOf('data:video') === 0) {
          var s2 = document.createElement('source')
          s2.type = 'video/mp4'
          s2.src = mp4
          v.appendChild(s2)
        }

        // Ensure it loops: some browsers require loop attribute
        v.loop = true

        // Keep reference but do not attach to DOM until enable() called
        this._video = v
      }
    },

    // enable: acquire native wake lock or play hidden looping video
    {
      key: 'enable',
      value: async function enable() {
        try {
          if (nativeWakeLock) {
            if (this._wakeLock != null) return
            // request sentinel
            var sentinel = await navigator.wakeLock.request('screen')
            this._wakeLock = sentinel
            _releasedNative = false

            // listen for the release event so we can update state
            if (sentinel && typeof sentinel.addEventListener === 'function') {
              var self = this
              sentinel.addEventListener('release', function () {
                _releasedNative = true
                self._wakeLock = null
                self._emit('release')
                self._emit('disabled')
              })
            }

            this._emit('enabled')
            return
          }

          // Fallback: use hidden looping video
          if (this._video && !this._videoAttached) {
            document.body.appendChild(this._video)
            this._videoAttached = true
          }

          if (!this._video) throw new Error('No fallback video available')

          // Attempt to play. Some browsers reject play() without a user gesture.
          var p = this._video.play()
          if (p && typeof p.then === 'function') await p
          this._emit('enabled')
        } catch (err) {
          // On iOS Safari older versions, play may throw; propagate via event
          this._emit('error', err)
          throw err
        }
      }
    },

    // disable: release native or pause video
    {
      key: 'disable',
      value: async function disable() {
        try {
          if (this._wakeLock) {
            // release sentinel
            if (typeof this._wakeLock.release === 'function') await this._wakeLock.release()
            // browsers will fire release event which clears state
            this._wakeLock = null
            _releasedNative = true
            this._emit('disabled')
            return
          }

          if (this._video) {
            try {
              this._video.pause()
            } catch (e) {
              // ignore
            }
            if (this._videoAttached) {
              try {
                document.body.removeChild(this._video)
              } catch (e) {
                // ignore
              }
              this._videoAttached = false
            }
            this._emit('disabled')
          }
        } catch (err) {
          this._emit('error', err)
          throw err
        }
      }
    },

    // query support
    {
      key: 'isSupported',
      value: function isSupported() {
        try {
          return nativeWakeLock || !!(this._video && typeof this._video.play === 'function')
        } catch (e) {
          return false
        }
      }
    },

    // isEnabled: robust truthy check
    {
      key: 'isEnabled',
      value: function isEnabled() {
        try {
          if (nativeWakeLock) return this._wakeLock != null && !_releasedNative
          return !!(this._video && !this._video.paused && this._videoAttached)
        } catch (e) {
          return false
        }
      }
    },

    // status summary
    {
      key: 'status',
      value: function status() {
        return {
          supported: this.isSupported(),
          enabled: this.isEnabled(),
          native: nativeWakeLock,
          visibility: typeof document !== 'undefined' ? document.visibilityState : 'unknown'
        }
      }
    },

    // toggle convenience
    {
      key: 'toggle',
      value: async function toggle() {
        if (this.isEnabled()) return this.disable()
        return this.enable()
      }
    },

    // keepAwakeDuring wraps an async task
    {
      key: 'keepAwakeDuring',
      value: async function keepAwakeDuring(task) {
        if (typeof task !== 'function') throw new TypeError('task must be a function returning a Promise')
        await this.enable()
        try {
          return await task()
        } finally {
          await this.disable()
        }
      }
    },

    // diagnose: returns informative object and logs
    {
      key: 'diagnose',
      value: function diagnose() {
        var s = this.status()
        try {
          console.groupCollapsed('NoSleep diagnose')
          console.info('Supported:', s.supported)
          console.info('Enabled:', s.enabled)
          console.info('Native Wake Lock:', s.native)
          console.info('Visibility:', s.visibility)
          console.groupEnd()
        } catch (e) {
          // ignore console issues
        }
        return s
      }
    },

    // simulateInactivity: useful for tests
    {
      key: 'simulateInactivity',
      value: function simulateInactivity(ms) {
        ms = typeof ms === 'number' ? ms : 3000
        return new Promise(function (resolve) {
          setTimeout(resolve, ms)
        })
      }
    },

    // event emitter
    {
      key: 'on',
      value: function on(event, handler) {
        if (!this._eventHandlers[event]) this._eventHandlers[event] = []
        this._eventHandlers[event].push(handler)
        return this
      }
    },
    {
      key: 'off',
      value: function off(event, handler) {
        if (!this._eventHandlers[event]) return this
        if (!handler) {
          delete this._eventHandlers[event]
          return this
        }
        this._eventHandlers[event] = this._eventHandlers[event].filter(function (h) {
          return h !== handler
        })
        return this
      }
    },
    {
      key: '_emit',
      value: function _emit(event, data) {
        var handlers = this._eventHandlers[event]
        if (!handlers || !handlers.length) return
        handlers.slice(0).forEach(function (h) {
          try {
            h(data)
          } catch (e) {
            console.error('NoSleep event handler error', e)
          }
        })
      }
    }
  ])

  return NoSleep
})()

// ===== UI utilities =====
var NoSleepUI = (function () {
  function _createStyles() {
    var css = """
    /* NoSleep control panel styles */
    .nosleep-panel { position: fixed; right: 16px; bottom: 16px; width: 220px; background: linear-gradient(180deg, #ffffff, #f6f9ff); border-radius: 12px; box-shadow: 0 8px 24px rgba(16,24,40,0.12); font-family: Inter, system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; color: #0f172a; z-index: 2147483647; padding: 12px; }
    .nosleep-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px }
    .nosleep-title { font-weight: 600; font-size: 13px }
    .nosleep-status { font-size: 12px; opacity: 0.8 }
    .nosleep-controls { display:flex; gap:8px; margin-top:8px }
    .nosleep-btn { flex:1; border: none; padding:8px 10px; border-radius:8px; cursor:pointer; font-weight:600 }
    .nosleep-btn-enable { background: linear-gradient(90deg,#2563eb,#7c3aed); color: #fff }
    .nosleep-btn-disable { background: #eef2ff; color: #3730a3 }
    .nosleep-small { font-size:11px; color:#475569 }
    .nosleep-footer { font-size:11px; margin-top:8px; opacity:0.85 }
    """
    return css
  }

  function injectStyles() {
    if (document.getElementById('nosleep-styles')) return
    var style = document.createElement('style')
    style.id = 'nosleep-styles'
    style.type = 'text/css'
    style.appendChild(document.createTextNode(_createStyles()))
    document.head.appendChild(style)
  }

  function createPanel(noSleepInstance) {
    injectStyles()

    var panel = document.createElement('div')
    panel.className = 'nosleep-panel'
    panel.setAttribute('role', 'region')
    panel.setAttribute('aria-label', 'NoSleep control panel')

    var header = document.createElement('div')
    header.className = 'nosleep-header'

    var title = document.createElement('div')
    title.className = 'nosleep-title'
    title.textContent = 'NoSleep'

    var status = document.createElement('div')
    status.className = 'nosleep-status'
    status.textContent = 'Initializing...'

    header.appendChild(title)
    header.appendChild(status)

    var controls = document.createElement('div')
    controls.className = 'nosleep-controls'

    var btnEnable = document.createElement('button')
    btnEnable.className = 'nosleep-btn nosleep-btn-enable'
    btnEnable.textContent = 'Enable'

    var btnDisable = document.createElement('button')
    btnDisable.className = 'nosleep-btn nosleep-btn-disable'
    btnDisable.textContent = 'Disable'

    controls.appendChild(btnEnable)
    controls.appendChild(btnDisable)

    var footer = document.createElement('div')
    footer.className = 'nosleep-footer'
    footer.innerHTML = '<span class="nosleep-small">Status: <strong id="nosleep-status-val">—</strong></span>'

    panel.appendChild(header)
    panel.appendChild(controls)
    panel.appendChild(footer)

    // attach logic
    function refresh() {
      var s = noSleepInstance.status()
      status.textContent = s.enabled ? 'Awake' : 'Sleeping'
      var stVal = panel.querySelector('#nosleep-status-val')
      if (stVal) stVal.textContent = s.enabled ? (s.native ? 'Native' : 'Video') : 'Off'
    }

    btnEnable.addEventListener('click', async function () {
      try {
        await noSleepInstance.enable()
        refresh()
      } catch (e) {
        alert('Failed to enable NoSleep: ' + (e && e.message ? e.message : e))
      }
    })

    btnDisable.addEventListener('click', async function () {
      try {
        await noSleepInstance.disable()
        refresh()
      } catch (e) {
        alert('Failed to disable NoSleep: ' + (e && e.message ? e.message : e))
      }
    })

    // update on events
    noSleepInstance.on('enabled', refresh)
    noSleepInstance.on('disabled', refresh)
    noSleepInstance.on('release', refresh)

    // initial state
    setTimeout(refresh, 100)

    return panel
  }

  return {
    attach: function (noSleepInstance, opts) {
      opts = opts || {}
      if (!noSleepInstance || typeof noSleepInstance.status !== 'function') throw new Error('NoSleep instance required')
      // Avoid adding multiple panels
      if (document.getElementById('nosleep-panel-root')) return document.getElementById('nosleep-panel-root')
      var root = createPanel(noSleepInstance)
      root.id = 'nosleep-panel-root'
      document.body.appendChild(root)
      return root
    }
  }
})()

// ===== Initialization & Exports =====
var noSleep = new NoSleep()

// helpful console hooks
noSleep.on('enabled', function () {
  console.log('[NoSleep] enabled')
})
noSleep.on('disabled', function () {
  console.log('[NoSleep] disabled')
})
noSleep.on('error', function (e) {
  console.error('[NoSleep] error', e)
})

// attach UI automatically, but only if DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    try { NoSleepUI.attach(noSleep) } catch (e) { /* ignore UI attach errors */ }
  } else {
    document.addEventListener('DOMContentLoaded', function () {
      try { NoSleepUI.attach(noSleep) } catch (e) { /* ignore */ }
    })
  }
}

// Export for module environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { NoSleep: NoSleep, noSleep: noSleep, NoSleepUI: NoSleepUI }
} else {
  window.NoSleep = NoSleep
  window.noSleep = noSleep
  window.NoSleepUI = NoSleepUI
}

// End of file — replace the two dataURIs (webm/mp4) with the full data if you want
 
