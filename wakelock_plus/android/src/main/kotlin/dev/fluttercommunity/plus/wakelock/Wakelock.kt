package dev.fluttercommunity.plus.wakelock

import android.app.Activity
import android.view.WindowManager
import IsEnabledMessage
import ToggleMessage

/**
 * Manages the wakelock state to keep the screen on or off for an Android Activity.
 */
internal class Wakelock {
    var activity: Activity? = null
        set(value) {
            require(value != null) { "Activity cannot be null" }
            field = value
        }

    private val isScreenKeptOn: Boolean
        get() = activity?.window?.attributes?.flags
            ?.and(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0

    /**
     * Toggles the wakelock state based on the provided [ToggleMessage].
     *
     * @param message The toggle message containing the enable state.
     * @throws NoActivityException If no activity is set.
     */
    fun toggle(message: ToggleMessage) {
        val currentActivity = activity ?: throw NoActivityException()
        val enable = message.enable ?: return // Gracefully handle null enable

        when {
            enable && !isScreenKeptOn -> {
                currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            !enable && isScreenKeptOn -> {
                currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    /**
     * Checks if the wakelock is currently enabled.
     *
     * @return [IsEnabledMessage] indicating whether the screen is kept on.
     * @throws NoActivityException If no activity is set.
     */
    fun isEnabled(): IsEnabledMessage {
        return IsEnabledMessage(enabled = isScreenKeptOn)
    }
}

/**
 * Exception thrown when an operation requires a foreground activity but none is available.
 */
class NoActivityException : Exception("Wakelock requires a foreground activity")
