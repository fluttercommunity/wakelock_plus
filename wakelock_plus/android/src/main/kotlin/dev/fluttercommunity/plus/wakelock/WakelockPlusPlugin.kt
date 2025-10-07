package dev.fluttercommunity.plus.wakelock

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

// -----------------------------
// Pigeon-like message classes
// -----------------------------

data class ToggleMessage(val enable: Boolean? = null) {
  companion object {
    fun fromList(list: List<Any?>): ToggleMessage {
      val enable = list.getOrNull(0) as? Boolean
      return ToggleMessage(enable)
    }
  }
  fun toList(): List<Any?> = listOf(enable)
}

data class IsEnabledMessage(val enabled: Boolean? = null) {
  companion object {
    fun fromList(list: List<Any?>): IsEnabledMessage {
      val enabled = list.getOrNull(0) as? Boolean
      return IsEnabledMessage(enabled)
    }
  }
  fun toList(): List<Any?> = listOf(enabled)
}

// -----------------------------
// Wakelock manager
// -----------------------------

internal class Wakelock(private val context: Context? = null) {
  @Volatile var activity: Activity? = null
  private val cpuWakeLockTag = "wakelock_plus:cpu"
  private val pm: PowerManager? get() = activity?.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: context?.getSystemService(Context.POWER_SERVICE) as? PowerManager
  private var cpuWakeLock: PowerManager.WakeLock? = null
  private val userRequested = AtomicBoolean(false)
  private val handler = Handler(Looper.getMainLooper())
  private var scheduledDisableRunnable: Runnable? = null

  private val screenFlagSet: Boolean
    get() = activity?.window?.attributes?.flags?.and(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0

  /** Toggle using only window flag (screen) and a PARTIAL_WAKE_LOCK for CPU. */
  @Synchronized
  fun toggle(msg: ToggleMessage) {
    ensureActivity()
    if (msg.enable == true) enable()
    else disable()
  }

  @Synchronized
  fun enable() {
    ensureActivity()
    activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    userRequested.set(true)
    acquireCpuWakeLock()
    log("Enabled wakelock")
  }

  @Synchronized
  fun disable() {
    activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    userRequested.set(false)
    releaseCpuWakeLock()
    log("Disabled wakelock")
  }

  fun isEnabled(): IsEnabledMessage {
    // Do not throw here — return a safe message even if activity is null
    return IsEnabledMessage(enabled = screenFlagSet || (cpuWakeLock?.isHeld == true))
  }

  fun enableForDuration(durationMs: Long) {
    enable()
    scheduleAutoDisable(durationMs)
  }

  fun forceEnable() {
    enable()
  }

  fun statusDetails(): Map<String, Any?> = mapOf(
    "screenFlag" to screenFlagSet,
    "cpuWakeLockHeld" to (cpuWakeLock?.isHeld == true),
    "userRequested" to userRequested.get(),
    "activityAttached" to (activity != null),
    "timestamp" to System.currentTimeMillis()
  )

  fun resetState() {
    cancelScheduledDisable()
    disable()
    log("Reset wakelock state")
  }

  fun debugInfo(): String = "Wakelock(screen=${screenFlagSet}, cpuHeld=${cpuWakeLock?.isHeld == true}, activity=${activity?.localClassName ?: "none"})"

  private fun acquireCpuWakeLock(timeoutMs: Long = 0L) {
    val p = pm ?: return
    try {
      if (cpuWakeLock?.isHeld == true) return
      cpuWakeLock = p.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, cpuWakeLockTag)
      if (timeoutMs > 0) cpuWakeLock?.acquire(timeoutMs) else cpuWakeLock?.acquire()
    } catch (e: SecurityException) {
      log("Missing WAKE_LOCK permission: ${e.message}")
    } catch (t: Throwable) {
      log("Failed to acquire CPU wakelock: ${t.message}")
    }
  }

  private fun releaseCpuWakeLock() {
    try {
      if (cpuWakeLock?.isHeld == true) cpuWakeLock?.release()
    } catch (t: Throwable) {
      log("Failed to release CPU wakelock: ${t.message}")
    } finally {
      cpuWakeLock = null
    }
  }

  private fun scheduleAutoDisable(delayMs: Long) {
    cancelScheduledDisable()
    val r = Runnable {
      try { disable() } finally { scheduledDisableRunnable = null }
    }
    scheduledDisableRunnable = r
    handler.postDelayed(r, delayMs)
  }

  private fun cancelScheduledDisable() {
    scheduledDisableRunnable?.let { handler.removeCallbacks(it) }
    scheduledDisableRunnable = null
  }

  private fun log(msg: String) {
    Log.d("WakelockManager", msg)
  }

  private fun ensureActivity() {
    if (activity == null) throw NoActivityException()
  }
}

class NoActivityException : Exception("wakelock requires a foreground activity")

// -----------------------------
// Pigeon-like API binding
// -----------------------------

interface WakelockPlusApi {
  fun toggle(msg: ToggleMessage)
  fun isEnabled(): IsEnabledMessage
  fun enableForDuration(durationMs: Long)
  fun forceEnable()
  fun disable()
  fun statusDetails(): Map<String, Any?>
  fun resetState()
  fun debugInfo(): String

  companion object {
    private const val BASE = "dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi"
    val codec: MessageCodec<Any?> by lazy { StandardMessageCodec() }

    @JvmOverloads
    fun setUp(binaryMessenger: BinaryMessenger, api: WakelockPlusApi?, suffix: String = "") {
      val sfx = if (suffix.isNotEmpty()) ".${suffix}" else ""

      fun channel(name: String) = BasicMessageChannel<Any?>(binaryMessenger, "$BASE.$name$sfx", codec)

      val toggleChan = channel("toggle")
      val isEnabledChan = channel("isEnabled")
      val enableForDurationChan = channel("enableForDuration")
      val forceEnableChan = channel("forceEnable")
      val disableChan = channel("disable")
      val statusDetailsChan = channel("statusDetails")
      val resetStateChan = channel("resetState")
      val debugInfoChan = channel("debugInfo")

      if (api == null) {
        listOf(toggleChan, isEnabledChan, enableForDurationChan, forceEnableChan, disableChan, statusDetailsChan, resetStateChan, debugInfoChan)
          .forEach { it.setMessageHandler(null) }
        return
      }

      toggleChan.setMessageHandler { message, reply ->
        val args = message as? List<Any?> ?: listOf()
        val msg = args.getOrNull(0) as? List<Any?> ?: listOf()
        val toggle = ToggleMessage.fromList(msg)
        try { api.toggle(toggle); reply.reply(listOf(null)) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      isEnabledChan.setMessageHandler { _, reply ->
        try { reply.reply(listOf(api.isEnabled())) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      enableForDurationChan.setMessageHandler { message, reply ->
        val args = message as? List<Any?> ?: listOf()
        val duration = (args.getOrNull(0) as? Number)?.toLong() ?: 0L
        try { api.enableForDuration(duration); reply.reply(listOf(true)) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      forceEnableChan.setMessageHandler { _, reply ->
        try { api.forceEnable(); reply.reply(listOf(true)) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      disableChan.setMessageHandler { _, reply ->
        try { api.disable(); reply.reply(listOf(true)) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      statusDetailsChan.setMessageHandler { _, reply ->
        try { reply.reply(listOf(api.statusDetails())) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      resetStateChan.setMessageHandler { _, reply ->
        try { api.resetState(); reply.reply(listOf(true)) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }

      debugInfoChan.setMessageHandler { _, reply ->
        try { reply.reply(listOf(api.debugInfo())) } catch (e: Throwable) { reply.reply(listOf(e.javaClass.simpleName, e.message, null)) }
      }
    }
  }
}

// -----------------------------
// Flutter plugin implementation + simple UI Activity for debugging/control
// -----------------------------

class WakelockPlusPlugin : FlutterPlugin, WakelockPlusApi, ActivityAware {
  private var wakelock: Wakelock? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    WakelockPlusApi.setUp(binding.binaryMessenger, this)
    wakelock = Wakelock(binding.applicationContext)
    Log.d("WakelockPlusPlugin", "Attached to engine")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    WakelockPlusApi.setUp(binding.binaryMessenger, null)
    wakelock = null
    Log.d("WakelockPlusPlugin", "Detached from engine")
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    wakelock?.activity = binding.activity
    Log.d("WakelockPlusPlugin", "Activity attached: ${binding.activity.localClassName}")
  }

  override fun onDetachedFromActivity() {
    wakelock?.activity = null
    Log.d("WakelockPlusPlugin", "Activity detached")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
  override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

  override fun toggle(msg: ToggleMessage) = wakelock?.toggle(msg) ?: throw NoActivityException()
  override fun isEnabled(): IsEnabledMessage = wakelock?.isEnabled() ?: IsEnabledMessage(enabled = false)
  override fun enableForDuration(durationMs: Long) = wakelock?.enableForDuration(durationMs) ?: throw NoActivityException()
  override fun forceEnable() = wakelock?.forceEnable() ?: throw NoActivityException()
  override fun disable() = wakelock?.disable() ?: throw NoActivityException()
  override fun statusDetails(): Map<String, Any?> = wakelock?.statusDetails() ?: mapOf("error" to "no activity")
  override fun resetState() = wakelock?.resetState() ?: Log.w("WakelockPlusPlugin", "resetState skipped - no activity")
  override fun debugInfo(): String = wakelock?.debugInfo() ?: "Wakelock unavailable"
}

// Optional: A lightweight Activity providing a clean UI to control and inspect wakelock state.
// This activity is for debugging/demo purposes and can be removed in production.

class WakelockControlActivity : AppCompatActivity() {
  private val manager = Wakelock()
  private lateinit var statusText: TextView
  private lateinit var debugText: TextView
  private lateinit var toggleSwitch: SwitchCompat
  private val uiHandler = Handler(Looper.getMainLooper())
  private var monitorRunnable: Runnable? = null

  override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)

    // Programmatic, visually clean UI
    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setPadding(dp(20), dp(20), dp(20), dp(20))
      setBackgroundColor(resolveAttrColor(android.R.attr.colorBackground))
    }

    val title = TextView(this).apply {
      text = "Wakelock Control"
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
      setPadding(0, 0, 0, dp(8))
      setTextColor(resolveAttrColor(android.R.attr.textColorPrimary))
    }

    statusText = TextView(this).apply {
      text = "Status: unknown"
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
      setPadding(0, 0, 0, dp(12))
      setTextColor(resolveAttrColor(android.R.attr.textColorSecondary))
    }

    toggleSwitch = SwitchCompat(this).apply {
      text = "Keep screen on"
      setOnCheckedChangeListener { _, isChecked ->
        try {
          if (isChecked) manager.enable() else manager.disable()
          updateStatus()
        } catch (e: Exception) {
          appendDebug("Error: ${e.message}")
        }
      }
    }

    val btnRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }

    val enableBtn = Button(this).apply { text = "Enable"; setOnClickListener { manager.enable(); updateStatus() } }
    val disableBtn = Button(this).apply { text = "Disable"; setOnClickListener { manager.disable(); updateStatus() } }
    val tempBtn = Button(this).apply { text = "Enable 30s"; setOnClickListener { manager.enableForDuration(30_000); updateStatus() } }

    listOf(enableBtn, disableBtn, tempBtn).forEach { btn -> btn.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { marginEnd = dp(8) }; btnRow.addView(btn) }

    debugText = TextView(this).apply {
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
      setPadding(0, dp(12), 0, 0)
      setTextColor(resolveAttrColor(android.R.attr.textColorSecondary))
    }

    val scroll = ScrollView(this).apply { addView(debugText); layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f) }

    root.addView(title)
    root.addView(statusText)
    root.addView(toggleSwitch)
    root.addView(btnRow)
    root.addView(scroll)

    setContentView(root)

    manager.activity = this
    startMonitoring()
  }

  override fun onDestroy() {
    super.onDestroy()
    stopMonitoring()
    manager.resetState()
  }

  private fun updateStatus() {
    uiHandler.post {
      val enabled = manager.isEnabled().enabled == true
      statusText.text = "Status: ${if (enabled) "Keeping screen on" else "Not keeping screen on"}"
      toggleSwitch.isChecked = enabled
      debugText.text = manager.debugInfo()
    }
  }

  private fun appendDebug(msg: Any?) {
    uiHandler.post {
      debugText.text = "${System.currentTimeMillis()}: ${msg ?: "null"}\n" + debugText.text
    }
  }

  private fun startMonitoring() {
    monitorRunnable = object : Runnable {
      override fun run() { updateStatus(); uiHandler.postDelayed(this, 2000) }
    }
    uiHandler.post(monitorRunnable!!)
  }

  private fun stopMonitoring() { monitorRunnable?.let { uiHandler.removeCallbacks(it) }; monitorRunnable = null }

  private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

  private fun resolveAttrColor(attr: Int): Int {
    val tv = TypedValue()
    theme.resolveAttribute(attr, tv, true)
    return tv.data
  }

  companion object {
    fun start(context: Context) { context.startActivity(android.content.Intent(context, WakelockControlActivity::class.java)) }
  }
}
 
