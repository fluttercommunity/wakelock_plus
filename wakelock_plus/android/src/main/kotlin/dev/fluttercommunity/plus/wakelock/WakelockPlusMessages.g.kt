@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")

package dev.fluttercommunity.plus.wakelock

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/**
 * Utility for Pigeon message wrapping and error handling.
 */
private object WakelockPlusPigeonUtils {
    fun wrapResult(result: Any?): List<Any?> = listOf(result)

    fun wrapError(exception: Throwable): List<Any?> = when (exception) {
        is WakelockPlusFlutterError -> listOf(exception.code, exception.message, exception.details)
        else -> listOf(
            exception.javaClass.simpleName,
            exception.message,
            "Cause: ${exception.cause}, Stacktrace: ${Log.getStackTraceString(exception)}"
        )
    }

    fun deepEquals(a: Any?, b: Any?): Boolean = when {
        a is ByteArray && b is ByteArray -> a.contentEquals(b)
        a is IntArray && b is IntArray -> a.contentEquals(b)
        a is LongArray && b is LongArray -> a.contentEquals(b)
        a is DoubleArray && b is DoubleArray -> a.contentEquals(b)
        a is Array<*> && b is Array<*> -> a.size == b.size && a.indices.all { deepEquals(a[it], b[it]) }
        a is List<*> && b is List<*> -> a.size == b.size && a.indices.all { deepEquals(a[it], b[it]) }
        a is Map<*, *> && b is Map<*, *> -> a.size == b.size && a.all { (b as Map<Any?, Any?>).containsKey(it.key) && deepEquals(it.value, b[it.key]) }
        else -> a == b
    }
}

/**
 * Custom error for passing details to Flutter via PlatformException.
 *
 * @property code Error code.
 * @property message Error message, optional.
 * @property details Additional details, must be codec-supported.
 */
data class WakelockPlusFlutterError(
    val code: String,
    override val message: String? = null,
    val details: Any? = null
) : Throwable()

/**
 * Message to toggle the wakelock state.
 */
data class ToggleMessage(val enable: Boolean?) {
    companion object {
        fun fromList(list: List<Any?>) = ToggleMessage(list[0] as Boolean?)
    }

    fun toList(): List<Any?> = listOf(enable)

    override fun equals(other: Any?): Boolean = when {
        this === other -> true
        other !is ToggleMessage -> false
        else -> WakelockPlusPigeonUtils.deepEquals(toList(), other.toList())
    }

    override fun hashCode(): Int = toList().hashCode()
}

/**
 * Message reporting the wakelock state.
 */
data class IsEnabledMessage(val enabled: Boolean?) {
    companion object {
        fun fromList(list: List<Any?>) = IsEnabledMessage(list[0] as Boolean?)
    }

    fun toList(): List<Any?> = listOf(enabled)

    override fun equals(other: Any?): Boolean = when {
        this === other -> true
        other !is IsEnabledMessage -> false
        else -> WakelockPlusPigeonUtils.deepEquals(toList(), other.toList())
    }

    override fun hashCode(): Int = toList().hashCode()
}

/**
 * Codec for Pigeon message encoding/decoding.
 */
private object WakelockPlusPigeonCodec : StandardMessageCodec() {
    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? = when (type) {
        129.toByte() -> (readValue(buffer) as? List<Any?>)?.let(ToggleMessage::fromList)
        130.toByte() -> (readValue(buffer) as? List<Any?>)?.let(IsEnabledMessage::fromList)
        else -> super.readValueOfType(type, buffer)
    }

    override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {
        when (value) {
            is ToggleMessage -> write(stream, 129, value.toList())
            is IsEnabledMessage -> write(stream, 130, value.toList())
            else -> super.writeValue(stream, value)
        }
    }

    private fun write(stream: ByteArrayOutputStream, type: Int, value: List<Any?>) {
        stream.write(type)
        writeValue(stream, value)
    }
}

/**
 * Interface for handling wakelock messages from Flutter.
 */
interface WakelockPlusApi {
    fun toggle(message: ToggleMessage)
    fun isEnabled(): IsEnabledMessage

    companion object {
        val codec: MessageCodec<Any?> by lazy { WakelockPlusPigeonCodec }

        /**
         * Configures message handling for [WakelockPlusApi].
         *
         * @param binaryMessenger Messenger for Flutter communication.
         * @param api Implementation of [WakelockPlusApi], or null to disable.
         * @param messageChannelSuffix Optional channel name suffix.
         */
        fun setUp(
            binaryMessenger: BinaryMessenger,
            api: WakelockPlusApi?,
            messageChannelSuffix: String = ""
        ) {
            val suffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""

            setupChannel(
                binaryMessenger,
                "dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle$suffix",
                api
            ) { message, reply ->
                val msgArg = (message as List<Any?>)[0] as ToggleMessage
                api?.toggle(msgArg)
                listOf(null)
            }

            setupChannel(
                binaryMessenger,
                "dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled$suffix",
                api
            ) { _, reply ->
                listOf(api?.isEnabled())
            }
        }

        private inline fun setupChannel(
            binaryMessenger: BinaryMessenger,
            channelName: String,
            api: WakelockPlusApi?,
            crossinline handler: (Any?, BasicMessageChannel.Reply<Any?>) -> List<Any?>
        ) {
            BasicMessageChannel<Any?>(binaryMessenger, channelName, codec).apply {
                setMessageHandler { message, reply ->
                    reply.reply(try {
                        handler(message, reply)
                    } catch (exception: Throwable) {
                        WakelockPlusPigeonUtils.wrapError(exception)
                    })
                }
            }
        }
    }
}
