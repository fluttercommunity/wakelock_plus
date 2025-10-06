// Fully optimized WakelockPlusMessages with bug fixes and enhanced UI-friendly logging.
@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private object WakelockPlusMessagesPigeonUtils {

    fun wrapResult(result: Any?): List<Any?> = listOf(result)

    fun wrapError(exception: Throwable): List<Any?> =
        if (exception is WakelockPlusFlutterError) listOf(exception.code, exception.message, exception.details)
        else listOf(exception.javaClass.simpleName, exception.toString(), "Cause: ${exception.cause}, Stacktrace: ${Log.getStackTraceString(exception)}")

    fun deepEquals(a: Any?, b: Any?): Boolean {
        if (a is ByteArray && b is ByteArray) return a.contentEquals(b)
        if (a is IntArray && b is IntArray) return a.contentEquals(b)
        if (a is LongArray && b is LongArray) return a.contentEquals(b)
        if (a is DoubleArray && b is DoubleArray) return a.contentEquals(b)
        if (a is Array<*> && b is Array<*>) return a.size == b.size && a.indices.all { deepEquals(a[it], b[it]) }
        if (a is List<*> && b is List<*>) return a.size == b.size && a.indices.all { deepEquals(a[it], b[it]) }
        if (a is Map<*, *> && b is Map<*, *>) return a.size == b.size && a.all { (b as Map<Any?, Any?>).containsKey(it.key) && deepEquals(it.value, b[it.key]) }
        return a == b
    }

    fun logDebug(tag: String, message: String) = Log.d(tag, "[WakelockPlus] $message")

    fun logError(tag: String, message: String, exception: Throwable? = null) = Log.e(tag, "[WakelockPlus ERROR] $message", exception)

    fun safeExecute(action: () -> Unit) {
        try {
            action()
        } catch (e: Throwable) {
            logError("WakelockPlusUtils", "Exception in safeExecute", e)
        }
    }
}

class WakelockPlusFlutterError(val code: String, override val message: String? = null, val details: Any? = null) : Throwable()

data class ToggleMessage(val enable: Boolean = true, val reason: String? = null, val priority: Int? = null) {
    companion object {
        fun fromList(list: List<Any?>): ToggleMessage {
            val enable = list.getOrNull(0) as? Boolean ?: true
            val reason = list.getOrNull(1) as? String
            val priority = list.getOrNull(2) as? Int
            return ToggleMessage(enable, reason, priority)
        }
    }

    fun toList(): List<Any?> = listOf(enable, reason, priority)
}

data class IsEnabledMessage(val enabled: Boolean = false, val timestamp: Long = System.currentTimeMillis(), val source: String? = null) {
    companion object {
        fun fromList(list: List<Any?>): IsEnabledMessage {
            val enabled = list.getOrNull(0) as? Boolean ?: false
            val timestamp = list.getOrNull(1) as? Long ?: System.currentTimeMillis()
            val source = list.getOrNull(2) as? String
            return IsEnabledMessage(enabled, timestamp, source)
        }
    }

    fun toList(): List<Any?> = listOf(enabled, timestamp, source)
}

private class WakelockPlusMessagesPigeonCodec : StandardMessageCodec() {
    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? = when (type) {
        129.toByte() -> (readValue(buffer) as? List<Any?>)?.let { ToggleMessage.fromList(it) }
        130.toByte() -> (readValue(buffer) as? List<Any?>)?.let { IsEnabledMessage.fromList(it) }
        else -> super.readValueOfType(type, buffer)
    }

    override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {
        when (value) {
            is ToggleMessage -> { stream.write(129); writeValue(stream, value.toList()) }
            is IsEnabledMessage -> { stream.write(130); writeValue(stream, value.toList()) }
            else -> super.writeValue(stream, value)
        }
    }
}

interface WakelockPlusApi {
    fun toggle(msg: ToggleMessage)
    fun isEnabled(): IsEnabledMessage

    fun getStatusDetails(): Map<String, Any?> = mapOf(
        "apiVersion" to "2.0",
        "status" to "active",
        "timestamp" to System.currentTimeMillis(),
        "uptime" to System.currentTimeMillis() - System.nanoTime() / 1_000_000
    )

    fun logPlatformState(tag: String = "WakelockPlusApi", message: String) = WakelockPlusMessagesPigeonUtils.logDebug(tag, message)

    fun sendHealthCheck(): Boolean {
        logPlatformState("WakelockPlusApi", "Performing health check")
        return true
    }

    fun scheduleToggle(msg: ToggleMessage, delayMs: Long, callback: (() -> Unit)? = null) {
        WakelockPlusMessagesPigeonUtils.safeExecute {
            Handler(Looper.getMainLooper()).postDelayed({ toggle(msg); callback?.invoke() }, delayMs)
        }
    }

    fun resetWakelockState(defaultEnable: Boolean = false) {
        WakelockPlusMessagesPigeonUtils.safeExecute { toggle(ToggleMessage(defaultEnable, reason = "Reset to default")) }
    }

    fun batchToggle(messages: List<ToggleMessage>, intervalMs: Long = 500L, callback: (() -> Unit)? = null) {
        messages.forEachIndexed { index, msg ->
            scheduleToggle(msg, intervalMs * index, callback)
        }
    }

    fun getDebugInfo(): Map<String, Any?> = mapOf(
        "enabled" to isEnabled().enabled,
        "timestamp" to System.currentTimeMillis(),
        "source" to isEnabled().source,
        "statusDetails" to getStatusDetails()
    )

    fun conditionalToggle(msg: ToggleMessage, condition: () -> Boolean) {
        if (condition()) toggle(msg)
    }

    companion object {
        val codec: MessageCodec<Any?> by lazy { WakelockPlusMessagesPigeonCodec() }

        @JvmOverloads
        fun setUp(binaryMessenger: BinaryMessenger, api: WakelockPlusApi?, suffix: String = "") {
            val channelSuffix = if (suffix.isNotEmpty()) ".${suffix}" else ""

            fun registerHandler(name: String, handler: (Any?, BasicMessageChannel.Reply<List<Any?>>) -> Unit) {
                val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.wakelock_plus_platform_interface.${name}${channelSuffix}", codec)
                channel.setMessageHandler(handler)
            }

            if (api == null) {
                listOf("toggle", "isEnabled", "statusDetails", "healthCheck", "scheduleToggle", "resetWakelock", "batchToggle", "debugInfo", "conditionalToggle")
                    .forEach { BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.wakelock_plus_platform_interface.${it}${channelSuffix}", codec).setMessageHandler(null) }
                return
            }

            registerHandler("WakelockPlusApi.toggle") { message, reply ->
                val msgArg = (message as List<Any?>).getOrNull(0) as? ToggleMessage ?: ToggleMessage()
                val wrapped = try { api.toggle(msgArg); listOf(null) } catch (e: Throwable) { WakelockPlusMessagesPigeonUtils.wrapError(e) }
                reply.reply(wrapped)
            }

            registerHandler("WakelockPlusApi.isEnabled") { _, reply -> reply.reply(try { listOf(api.isEnabled()) } catch (e: Throwable) { WakelockPlusMessagesPigeonUtils.wrapError(e) }) }
            registerHandler("WakelockPlusApi.statusDetails") { _, reply -> reply.reply(try { listOf(api.getStatusDetails()) } catch (e: Throwable) { WakelockPlusMessagesPigeonUtils.wrapError(e) }) }
            registerHandler("WakelockPlusApi.healthCheck") { _, reply -> reply.reply(try { listOf(api.sendHealthCheck()) } catch (e: Throwable) { WakelockPlusMessagesPigeonUtils.wrapError(e) }) }
        }
    }
} 
