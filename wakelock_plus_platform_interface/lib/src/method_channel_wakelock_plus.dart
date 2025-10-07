import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus_platform_interface/messages.g.dart';

/// Method channel implementation of the [WakelockPlusPlatformInterface] with extended utilities.
class MethodChannelWakelockPlus extends WakelockPlusPlatformInterface {
  final _api = WakelockPlusApi();

  @override
  Future<bool> get enabled async {
    try {
      final message = await _api.isEnabled();
      return message.enabled ?? false;
    } catch (e) {
      // If the platform call fails, we assume disabled and log.
      debugPrint('[WakelockPlus] isEnabled error: \$e');
      return false;
    }
  }

  @override
  Future<void> toggle({required bool enable}) async {
    final message = ToggleMessage();
    message.enable = enable;
    try {
      await _api.toggle(message);
    } catch (e) {
      debugPrint('[WakelockPlus] toggle error: \$e');
      rethrow;
    }
  }

  /// Toggles wakelock multiple times for testing.
  Future<void> toggleRepeats(int count, Duration duration) async {
    for (int i = 0; i < count; i++) {
      await toggle(enable: true);
      await Future.delayed(duration);
      await toggle(enable: false);
    }
  }

  /// Safely runs a callback ensuring wakelock is active.
  Future<void> runWithWakelock(Future<void> Function() callback) async {
    final wasEnabled = await enabled;
    if (!wasEnabled) await toggle(enable: true);
    try {
      await callback();
    } finally {
      if (!wasEnabled) await toggle(enable: false);
    }
  }
}

/// Comprehensive interface for wakelock management, diagnostics, and automation.
abstract class WakelockPlusPlatformInterface extends PlatformInterface {
  WakelockPlusPlatformInterface() : super(token: _token);

  static final Object _token = Object();
  static WakelockPlusPlatformInterface _instance = MethodChannelWakelockPlus();

  static WakelockPlusPlatformInterface get instance => _instance;
  static set instance(WakelockPlusPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  @visibleForTesting
  bool get isMock => false;

  /// Core wakelock functionality
  Future<void> toggle({required bool enable}) {
    throw UnimplementedError('toggle() has not been implemented.');
  }

  Future<bool> get enabled {
    throw UnimplementedError('enabled getter has not been implemented.');
  }

  /// Enables wakelock for a specific duration
  Future<void> enableFor(Duration duration) async {
    await toggle(enable: true);
    await Future.delayed(duration);
    await toggle(enable: false);
  }

  /// Continuous monitoring of wakelock state
  Stream<bool> monitorState({Duration interval = const Duration(seconds: 3)}) async* {
    while (true) {
      yield await enabled;
      await Future.delayed(interval);
    }
  }

  /// Returns diagnostics info
  Future<Map<String, dynamic>> diagnostics() async {
    return {
      'isEnabled': await enabled,
      'platform': instance.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Automatically manage wakelock based on condition
  Future<void> autoManage(Future<bool> Function() condition, {Duration checkInterval = const Duration(seconds: 10)}) async {
    while (true) {
      final shouldEnable = await condition();
      if (shouldEnable != await enabled) await toggle(enable: shouldEnable);
      await Future.delayed(checkInterval);
    }
  }

  /// Logs messages with timestamp
  void logState(String message) {
    debugPrint('[WakelockPlus] \${DateTime.now().toIso8601String()} — \$message');
  }

  /// Resets wakelock
  Future<void> reset() async => await toggle(enable: false);

  /// Pause wakelock optionally for a duration
  Future<void> pause({Duration? duration}) async {
    await toggle(enable: false);
    if (duration != null) {
      await Future.delayed(duration);
      await toggle(enable: true);
    }
  }

  /// Schedules wakelock activation
  Future<void> scheduleActivation(DateTime time) async {
    final delay = time.difference(DateTime.now());
    if (!delay.isNegative) {
      await Future.delayed(delay);
      await toggle(enable: true);
    }
  }

  /// Retrieves usage statistics
  Future<Map<String, dynamic>> usageStats() async {
    return {
      'state': await enabled,
      'uptime': DateTime.now().toIso8601String(),
      'implementation': instance.runtimeType.toString(),
    };
  }

  /// Warns if wakelock is overused
  Future<void> warnIfOverused(Duration maxDuration) async {
    final start = DateTime.now();
    while (await enabled) {
      if (DateTime.now().difference(start) > maxDuration) {
        logState('⚠️ Wakelock active beyond \$maxDuration');
        break;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Callback on state change
  Future<void> onStateChange(void Function(bool state) callback, {Duration interval = const Duration(seconds: 2)}) async {
    bool prev = await enabled;
    callback(prev);
    while (true) {
      final now = await enabled;
      if (now != prev) {
        callback(now);
        prev = now;
      }
      await Future.delayed(interval);
    }
  }

  /// Automatic toggle based on charging status
  Future<void> autoBasedOnPower(bool Function() isCharging, {Duration checkInterval = const Duration(seconds: 15)}) async {
    while (true) {
      await toggle(enable: isCharging());
      await Future.delayed(checkInterval);
    }
  }

  /// Handles app lifecycle changes
  void onAppLifecycleChange(String state) => logState('App lifecycle changed: \$state');

  /// Measures wakelock operation performance
  Future<Duration> measurePerformance(Future<void> Function() operation) async {
    final start = DateTime.now();
    await operation();
    return DateTime.now().difference(start);
  }

  /// Exports diagnostics as string
  Future<String> exportDiagnostics() async {
    final data = await diagnostics();
    return data.entries.map((e) => '\${e.key}: \${e.value}').join('\n');
  }

  /// Watchdog to re-enable wakelock if unexpectedly disabled
  Future<void> watchdog({Duration checkInterval = const Duration(seconds: 10)}) async {
    while (true) {
      if (!await enabled) {
        logState('⚙️ Wakelock unexpectedly disabled — re-enabling');
        await toggle(enable: true);
      }
      await Future.delayed(checkInterval);
    }
  }

  /// Tracks wakelock session duration
  Future<Map<String, dynamic>> sessionTracking() async {
    final start = DateTime.now();
    await toggle(enable: true);
    await Future.delayed(const Duration(seconds: 3));
    await toggle(enable: false);
    return {
      'start': start.toIso8601String(),
      'end': DateTime.now().toIso8601String(),
      'duration': DateTime.now().difference(start).inSeconds,
    };
  }

  /// Enables wakelock for repeated cycles
  Future<void> enableRepeats(int count, Duration duration) async {
    for (int i = 0; i < count; i++) {
      await toggle(enable: true);
      await Future.delayed(duration);
      await toggle(enable: false);
    }
  }

  /// Safely executes callback with wakelock active
  Future<void> executeWithWakelock(Future<void> Function() callback) async {
    final wasEnabled = await enabled;
    if (!wasEnabled) await toggle(enable: true);
    await callback();
    if (!wasEnabled) await toggle(enable: false);
  }

  /// Returns human-readable summary
  Future<String> summary() async {
    final stats = await usageStats();
    return 'Wakelock state: \${stats['state']}, uptime: \${stats['uptime']}, platform: \${stats['implementation']}';
  }

  /// Verifies default implementations
  void _verifyProvidesDefaultImplementations() {}
}

/// ----------------------
/// Flutter UI: NoSleepPanel
/// ----------------------
/// A lightweight, modern control panel widget that can be embedded in any
/// Flutter app. It displays the current wakelock state, allows toggling,
/// and shows diagnostic info. The design is intentionally minimal and
/// visually appealing (rounded card, gradient button, smooth transitions).

class NoSleepPanel extends StatefulWidget {
  final WakelockPlusPlatformInterface wakelock;
  final bool autoAttach; // if true, panel will poll state automatically
  const NoSleepPanel({Key? key, WakelockPlusPlatformInterface? wakelock, this.autoAttach = true})
      : wakelock = wakelock ?? const _DefaultWakelockAccessor().instance,
        super(key: key);

  @override
  State<NoSleepPanel> createState() => _NoSleepPanelState();
}

class _NoSleepPanelState extends State<NoSleepPanel> with SingleTickerProviderStateMixin {
  bool _enabled = false;
  bool _loading = true;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _readState();
    if (widget.autoAttach) _startPolling();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _readState() async {
    setState(() => _loading = true);
    try {
      final val = await widget.wakelock.enabled;
      setState(() {
        _enabled = val;
      });
    } catch (e) {
      debugPrint('[NoSleepPanel] failed to read state: \$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Timer? _pollTimer;
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final val = await widget.wakelock.enabled;
        if (mounted && val != _enabled) setState(() => _enabled = val);
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      await widget.wakelock.toggle(enable: !_enabled);
      setState(() => _enabled = !_enabled);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NoSleep', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_loading ? 'Loading...' : (_enabled ? 'Awake (prevent sleep)' : 'Sleeping'),
                  style: theme.textTheme.bodySmall),
            ])),
            _buildStatusIcon(),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildToggleButton()),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Info',
              onPressed: _showDiagnostics,
              icon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            )
          ])
        ]),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _enabled
            ? const LinearGradient(colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)])
            : const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)]),
        boxShadow: _enabled
            ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 4))]
            : [],
      ),
      child: Center(
        child: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_enabled ? Icons.power : Icons.power_off, color: _enabled ? Colors.white : Colors.grey[700]),
      ),
    );
  }

  Widget _buildToggleButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _toggle,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        backgroundColor: _enabled ? const Color(0xFF7C3AED) : Colors.white,
        foregroundColor: _enabled ? Colors.white : Colors.black87,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? const SizedBox(key: ValueKey('loading'), width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
                _enabled ? 'Disable' : 'Enable',
                key: ValueKey(_enabled),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _showDiagnostics() async {
    final diag = await widget.wakelock.diagnostics();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NoSleep Diagnostics'),
        content: SingleChildScrollView(
          child: ListBody(
            children: diag.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}

/// Helper to provide default wakelock instance in widget constructor without
/// importing platform_interface directly at call site.
class _DefaultWakelockAccessor {
  const _DefaultWakelockAccessor();
  WakelockPlusPlatformInterface get instance => WakelockPlusPlatformInterface.instance;
} 
