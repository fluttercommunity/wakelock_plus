package dev.fluttercommunity.plus.wakelock

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * A Flutter plugin for managing wakelock functionality on Android.
 *
 * This class implements [WakelockPlusApi] for handling wakelock toggle and status queries,
 * and [ActivityAware] for managing the Android activity lifecycle.
 */
class WakelockPlusPlugin : FlutterPlugin, WakelockPlusApi, ActivityAware {
    private var wakelock: Wakelock? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        wakelock = Wakelock()
        WakelockPlusApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        WakelockPlusApi.setUp(binding.binaryMessenger, null)
        wakelock = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        wakelock?.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        wakelock?.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    /**
     * Toggles the wakelock state based on the provided message.
     *
     * @param message The [ToggleMessage] containing the enable state.
     * @throws NoActivityException If no activity is available for wakelock operations.
     */
    override fun toggle(message: ToggleMessage) {
        wakelock?.toggle(message) ?: throw NoActivityException()
    }

    /**
     * Queries the current wakelock state.
     *
     * @return An [IsEnabledMessage] indicating whether the wakelock is enabled.
     * @throws NoActivityException If no activity is available for wakelock operations.
     */
    override fun isEnabled(): IsEnabledMessage {
        return wakelock?.isEnabled() ?: throw NoActivityException()
    }
}
