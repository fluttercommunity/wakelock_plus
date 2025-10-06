package dev.fluttercommunity.plus.wakelock

// Single-file wakelock manager + simple UI activity.
// This file includes:
// - data classes used for IPC-like messages (ToggleMessage / IsEnabledMessage)
// - Wakelock manager with robust handling and fixes
// - A lightweight, programmatic Activity that provides a simple, attractive UI to control and monitor the wakelock
//
// Notes:
// - If you use WakeLock, add <uses-permission android:name="android.permission.WAKE_LOCK" /> to AndroidManifest.xml
// - This Activity builds its UI programmatically so the file is standalone.
// - Some PowerManager wake lock types are intentionally conservative (PARTIAL_WAKE_LOCK). The window flag FLAG_KEEP_SCREEN_ON keeps the display awake.

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
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
import android.widget.Switch
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import java.util.concurrent.atomic.AtomicLong

// Simple message-like data classes used earlier in the file
data class ToggleMessage(val enable: Boolean?)
data class IsEnabledMessage(val enabled: Boolean)

class NoActivityException : Exception("wakelock requires a foreground activity")

/**
 * Wakelock manager — robust, thread-safe, and self-contained.
 * Responsibilities:
 *  - keep screen awake via window flag
 *  - keep CPU awake via PARTIAL_WAKE_LOCK
 *  - provide utilities for temporary disable, scheduling, and debug info
 */
internal class Wakelock {
  @Volatile
  var activity: Activity? = null

  private var powerManager: PowerManager? = null
  private var wakeLock: PowerManager.WakeLock? = null
  private val wakeLockAcquireTime = AtomicLong(0)
  private val mainHandler = Handler(Looper.getMainLooper())
  @Volatile
  private var scheduledDisableRunnable: Runnable? = null

  // Safe check for whether the window flag is set (keeps screen on)
  private val enabled: Boolean
    get() = activity?.window?.attributes?.flags?.and(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0

  /** Attach the foreground activity so window flags can be used. */
  fun attachActivity(activity: Activity) {
    this.activity = activity
    this.powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
  }

  /** Detach the activity and release resources. */
  fun detachActivity() {
    this.activity = null
    this.powerManager = null
    releaseWakeLock()
    cancelScheduledDisable()
  }

  /** Toggle based on a ToggleMessage (null-safe). */
  fun toggle(message: ToggleMessage) {
    if (activity == null) throw NoActivityException()
    if (message.enable == true) enable() else disable()
  }

  /** Returns current state as a message object. */
  fun isEnabled(): IsEnabledMessage {
    if (activity == null) throw NoActivityException()
    return IsEnabledMessage(enabled = enabled)
  }

  /** Enable wakelock: set window flag and acquire a partial wake lock for CPU. */
  @Synchronized
  fun enable() {
    val act = activity ?: throw NoActivityException()
    if (!enabled) {
      act.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    acquireWakeLock()
    logState("Enabled wakelock")
  }

  /** Disable wakelock: clear window flag and release wake lock. */
  @Synchronized
  fun disable() {
    val act = activity ?: throw NoActivityException()
    if (enabled) {
      act.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    releaseWakeLock()
    logState("Disabled wakelock")
  }

  /** Refresh state without throwing when no activity is attached. */
  fun refreshState(): IsEnabledMessage = IsEnabledMessage(enabled = enabled)

  /** Acquire a PARTIAL_WAKE_LOCK (safe, keeps CPU on). */
  @Synchronized
  fun acquireWakeLock(timeoutMillis: Long = 10 * 60 * 1000L) {
    if (wakeLock?.isHeld == true) return
    val pm = powerManager ?: return
    // PARTIAL_WAKE_LOCK doesn't keep the screen on by itself — we use window flag for that.
    wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "wakelock:keepCpuAwake")
    // Use timed acquire when timeout supplied (>0). modern acquire() without timeout is discouraged.
    try {
      if (timeoutMillis > 0L) wakeLock?.acquire(timeoutMillis) else wakeLock?.acquire()
      wakeLockAcquireTime.set(System.currentTimeMillis())
      logState("WakeLock acquired at ${wakeLockAcquireTime.get()}")
    } catch (e: SecurityException) {
      // WAKE_LOCK permission may be missing; log and continue without crashing.
      logState("Failed to acquire wakeLock: ${e.message}")
    }
  }

  /** Release the wake lock if held. */
  @Synchronized
  fun releaseWakeLock() {
    try {
      if (wakeLock?.isHeld == true) {
        wakeLock?.release()
        logState("WakeLock released after ${getHeldDuration()} ms")
      }
    } catch (e: Throwable) {
      // Defensive: some devices may throw when releasing.
      logState("Error releasing wakeLock: ${e.message}")
    } finally {
      wakeLockAcquireTime.set(0)
      wakeLock = null
    }
  }

  fun isWakeLockHeld(): Boolean = wakeLock?.isHeld == true

  fun forceRefresh() {
    if (activity != null && enabled) {
      disable()
      enable()
      logState("Force refreshed wakelock")
    }
  }

  fun getActivityName(): String? = activity?.javaClass?.simpleName

  private fun logState(message: String) {
    // Lightweight logging; replace with your logger if desired.
    android.util.Log.d("Wakelock", message)
  }

  fun getWakeLockDuration(): Long = if (isWakeLockHeld()) System.currentTimeMillis() - wakeLockAcquireTime.get() else 0L

  fun getHeldDuration(): Long = if (wakeLockAcquireTime.get() == 0L) 0L else System.currentTimeMillis() - wakeLockAcquireTime.get()

  fun ensureWakeLockConsistency() {
    if (enabled && !isWakeLockHeld()) acquireWakeLock()
    if (!enabled && isWakeLockHeld()) releaseWakeLock()
  }

  fun reset() {
    releaseWakeLock()
    activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    cancelScheduledDisable()
    logState("Reset wakelock state")
  }

  /** Temporarily disable wakelock for given duration (milliseconds) — safe main-thread scheduling. */
  fun temporarilyDisable(durationMillis: Long) {
    if (!isWakeLockHeld() && !enabled) return
    disable()
    logState("Temporarily disabled wakelock for ${durationMillis}ms")
    mainHandler.postDelayed({ enable() }, durationMillis)
  }

  /** Schedule an auto-disable after delayMillis on the main thread. Replaces any existing scheduled task. */
  fun scheduleAutoDisable(delayMillis: Long) {
    cancelScheduledDisable()
    val r = Runnable {
      try {
        disable()
        logState("Auto disabled wakelock after ${delayMillis}ms")
      } finally {
        scheduledDisableRunnable = null
      }
    }
    scheduledDisableRunnable = r
    mainHandler.postDelayed(r, delayMillis)
  }

  fun cancelScheduledDisable() {
    scheduledDisableRunnable?.let { mainHandler.removeCallbacks(it) }
    scheduledDisableRunnable = null
    logState("Auto disable cancelled")
  }

  fun debugInfo(): String {
    return "Activity: ${getActivityName() ?: "None"}\nEnabled: $enabled\nWakeLockHeld: ${isWakeLockHeld()}\nHeldDuration: ${getWakeLockDuration()} ms"
  }

  fun onAppBackgrounded() {
    // Typically it's better to release wake locks when in background.
    releaseWakeLock()
    logState("App backgrounded: released wakelock")
  }

  fun onAppForegrounded() {
    // If window flag is present, attempt to re-acquire wake lock to preserve behavior.
    if (enabled) acquireWakeLock()
    logState("App foregrounded: ensured wakelock consistency")
  }

  /** Battery-aware toggle example. Returns true if enabled after the call. */
  fun toggleBasedOnBatteryLevel(context: Context, threshold: Int): Boolean {
    val batteryStatus = context.registerReceiver(null, android.content.IntentFilter(android.os.BatteryManager.ACTION_BATTERY_CHANGED))
    val level = batteryStatus?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
    if (level in 0..100) {
      if (level < threshold) {
        try {
          disable()
        } catch (e: Throwable) {
          logState("Error when disabling: ${e.message}")
        }
        logState("Battery below $threshold% ($level%), wakelock disabled.")
        return false
      } else {
        try { enable() } catch (e: Throwable) { logState("Error when enabling: ${e.message}") }
        logState("Battery above $threshold% ($level%), wakelock enabled.")
        return true
      }
    }
    // Unknown battery level -> keep previous state
    logState("Unknown battery level; no change")
    return enabled
  }
}

// -----------------------------------------------------------------------------
// Simple Activity with programmatic UI to control the Wakelock manager.
// This is intended as a helpful demo and lightweight management UI.
// -----------------------------------------------------------------------------

class WakelockActivity : AppCompatActivity() {
  private val manager = Wakelock()
  private lateinit var statusText: TextView
  private lateinit var debugText: TextView
  private lateinit var toggleSwitch: SwitchCompat
  private val uiHandler = Handler(Looper.getMainLooper())
  private var monitorRunnable: Runnable? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // Build a simple, attractive layout programmatically
    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setPadding(dp(16), dp(16), dp(16), dp(16))
      setBackgroundColor(resolveAttrColor(android.R.attr.colorBackground))
    }

    val title = TextView(this).apply {
      text = "Wakelock Manager"
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
      setPadding(0, 0, 0, dp(8))
      setTextColor(resolveAttrColor(android.R.attr.textColorPrimary))
      gravity = Gravity.START
    }

    statusText = TextView(this).apply {
      text = "Status: unknown"
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
      setPadding(0, 0, 0, dp(12))
      setTextColor(resolveAttrColor(android.R.attr.textColorSecondary))
    }

    toggleSwitch = SwitchCompat(this).apply {
      text = "Keep screen on"
      isChecked = false
      setOnCheckedChangeListener { _, isChecked ->
        try {
          if (isChecked) manager.enable() else manager.disable()
          updateStatus()
        } catch (e: Exception) {
          appendDebug("Error toggling: ${e.message}")
        }
      }
    }

    val btnRow = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      setPadding(0, dp(8), 0, dp(8))
    }

    val btnEnable = Button(this).apply {
      text = "Enable"
      setOnClickListener { try { manager.enable(); updateStatus() } catch (e: Exception) { appendDebug(e.message) } }
    }

    val btnDisable = Button(this).apply {
      text = "Disable"
      setOnClickListener { try { manager.disable(); updateStatus() } catch (e: Exception) { appendDebug(e.message) } }
    }

    val btnRefresh = Button(this).apply {
      text = "Refresh"
      setOnClickListener { updateStatus() }
    }

    val btnAutoDisable = Button(this).apply {
      text = "AutoDisable 30s"
      setOnClickListener { manager.scheduleAutoDisable(30_000); appendDebug("Scheduled auto-disable in 30s") }
    }

    btnRow.addView(btnEnable, rowBtnLayout())
    btnRow.addView(btnDisable, rowBtnLayout())
    btnRow.addView(btnRefresh, rowBtnLayout())

    val btnRow2 = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      setPadding(0, dp(6), 0, dp(8))
    }

    btnRow2.addView(btnAutoDisable, rowBtnLayout())

    debugText = TextView(this).apply {
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
      setPadding(0, dp(8), 0, dp(8))
      setTextColor(resolveAttrColor(android.R.attr.textColorSecondary))
    }

    val scroll = ScrollView(this).apply {
      addView(debugText)
      layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
    }

    root.addView(title)
    root.addView(statusText)
    root.addView(toggleSwitch)
    root.addView(btnRow)
    root.addView(btnRow2)
    root.addView(scroll)

    setContentView(root)

    // Attach manager to this activity for window flags
    manager.attachActivity(this)
    // Start a small monitor that updates status every 2 seconds
    startMonitoring()
  }

  override fun onResume() {
    super.onResume()
    manager.attachActivity(this)
    manager.onAppForegrounded()
    updateStatus()
  }

  override fun onPause() {
    super.onPause()
    // We keep wake locks only while in foreground (this is a design choice). Detach to avoid leaks.
    manager.onAppBackgrounded()
    manager.detachActivity()
  }

  override fun onDestroy() {
    super.onDestroy()
    stopMonitoring()
    manager.reset()
  }

  private fun updateStatus() {
    uiHandler.post {
      val enabled = try { manager.refreshState().enabled } catch (e: Exception) { false }
      statusText.text = "Status: ${if (enabled) "Keeping screen on" else "Not keeping screen on"}"
      toggleSwitch.isChecked = enabled
      debugText.text = manager.debugInfo()
    }
  }

  private fun appendDebug(msg: Any?) {
    uiHandler.post {
      val text = debugText.text.toString()
      val add = "${System.currentTimeMillis()}: ${msg ?: "null"}\n"
      debugText.text = add + text
    }
  }

  private fun startMonitoring() {
    monitorRunnable = object : Runnable {
      override fun run() {
        try { updateStatus() } finally { uiHandler.postDelayed(this, 2000) }
      }
    }
    uiHandler.post(monitorRunnable!!)
  }

  private fun stopMonitoring() {
    monitorRunnable?.let { uiHandler.removeCallbacks(it) }
    monitorRunnable = null
  }

  // Utility helpers
  private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

  private fun rowBtnLayout(): LinearLayout.LayoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
    marginEnd = dp(6)
  }

  private fun resolveAttrColor(attr: Int): Int {
    val typedValue = TypedValue()
    theme.resolveAttribute(attr, typedValue, true)
    return typedValue.data
  }

  companion object {
    fun start(context: Context) {
      context.startActivity(Intent(context, WakelockActivity::class.java))
    }
  }
}
 
