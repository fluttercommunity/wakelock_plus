package dev.fluttercommunity.plus.wakelock

import ToggleMessage
import android.app.Activity
import android.os.Build
import android.view.WindowManager
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for [Wakelock] covering the "no foreground activity attached"
 * behaviour introduced to stop [toggle]/[isEnabled] from throwing when the app
 * is backgrounded or mid lifecycle transition. The desired state is tracked in
 * Kotlin and (re)applied to whichever activity window is attached.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class WakelockTest {

  private fun buildActivity(): Activity =
      Robolectric.buildActivity(Activity::class.java).setup().get()

  private val Activity.keepScreenOn: Boolean
    get() = window.attributes.flags and
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0

  @Test
  fun `toggle enable with no activity attached does not throw`() {
    val wakelock = Wakelock()

    wakelock.toggle(ToggleMessage(enable = true))

    assertTrue(wakelock.isEnabled().enabled == true)
  }

  @Test
  fun `isEnabled with no activity attached does not throw and defaults to false`() {
    assertFalse(Wakelock().isEnabled().enabled == true)
  }

  @Test
  fun `enabling before an activity attaches applies the flag once it does`() {
    val wakelock = Wakelock()

    wakelock.toggle(ToggleMessage(enable = true))
    val activity = buildActivity()
    wakelock.activity = activity

    assertTrue(activity.keepScreenOn)
  }

  @Test
  fun `attaching an activity while disabled leaves the flag untouched`() {
    val wakelock = Wakelock()
    val activity = buildActivity()

    wakelock.activity = activity

    assertFalse(activity.keepScreenOn)
  }

  @Test
  fun `disabling clears the flag on the attached activity`() {
    val wakelock = Wakelock()
    val activity = buildActivity()
    wakelock.activity = activity

    wakelock.toggle(ToggleMessage(enable = true))
    assertTrue(activity.keepScreenOn)

    wakelock.toggle(ToggleMessage(enable = false))
    assertFalse(activity.keepScreenOn)
  }

  @Test
  fun `enabled state is re-applied to a new activity after detach`() {
    val wakelock = Wakelock()
    val first = buildActivity()
    wakelock.activity = first
    wakelock.toggle(ToggleMessage(enable = true))
    assertTrue(first.keepScreenOn)

    // The activity goes away (e.g. the app is backgrounded). This used to throw.
    wakelock.activity = null
    assertTrue(wakelock.isEnabled().enabled == true)

    // A fresh activity attaches; the requested state must be re-asserted on it.
    val second = buildActivity()
    wakelock.activity = second
    assertTrue(second.keepScreenOn)
  }
}
