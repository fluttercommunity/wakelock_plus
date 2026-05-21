package dev.fluttercommunity.plus.wakelock

import IsEnabledMessage
import ToggleMessage
import android.app.Activity
import android.view.WindowManager

internal class Wakelock {
  // The desired wakelock state. Tracked independently of [activity] so that a
  // toggle requested while no activity is attached (e.g. the app is in the
  // background or mid lifecycle transition) is remembered and re-applied once an
  // activity (re)attaches, instead of throwing a NoActivityException.
  private var enableWakelock = false

  var activity: Activity? = null
    set(value) {
      field = value
      // Re-assert the wakelock on the newly attached activity's window, but only
      // when it was actually requested. If the user never enabled it (or last
      // disabled it), leave the flag alone — the activity may keep the screen on
      // for its own reasons.
      if (enableWakelock) applyWakelock()
    }

  private fun applyWakelock() {
    val window = activity?.window ?: return
    if (enableWakelock) {
      window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    } else {
      window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
  }

  fun toggle(message: ToggleMessage) {
    enableWakelock = message.enable!!
    applyWakelock()
  }

  fun isEnabled(): IsEnabledMessage = IsEnabledMessage(enabled = enableWakelock)
}
