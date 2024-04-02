package dev.fluttercommunity.plus.wakelock

import IsEnabledMessage
import ToggleMessage
import android.app.Activity
import android.view.WindowManager
import android.os.PowerManager
import android.content.Context


internal class Wakelock {
  var activity: Activity? = null
  var cpuWakeLock: PowerManager.WakeLock? = null

  private val enabled
    get() = activity!!.window.attributes.flags and
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0

  private val cpuEnabled
    get() = cpuWakeLock?.isHeld ?: false

  fun toggle(message: ToggleMessage) {
    if (activity == null) {
      throw NoActivityException()
    }

    val activity = this.activity!!
    val enabled = this.enabled

    if (message.enable!!) {
      if (!enabled) activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    } else if (enabled) {
      activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
  }

  fun toggleCPU(message: ToggleMessage) {
    if (activity == null) {
      throw NoActivityException()
    }

    val activity = this.activity!!
    val enabled = this.cpuEnabled

    if (message.enable!!) {
      if (!enabled) {
        cpuWakeLock =
        (activity?.getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Vibration::KeepVibratingWakeLog").apply {
                acquire()
            }
        }
      }
    } else if (enabled) {
      cpuWakeLock?.release()
    }
  }

  fun isEnabled(): IsEnabledMessage {
    if (activity == null) {
      throw NoActivityException()
    }

    return IsEnabledMessage(enabled = enabled)
  }

  fun isCPUEnabled(): IsEnabledMessage {
    return IsEnabledMessage(enabled = cpuEnabled)
  }

}

class NoActivityException : Exception("wakelock requires a foreground activity")
