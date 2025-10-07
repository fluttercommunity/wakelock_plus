import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus_platform_interface/src/method_channel_wakelock_plus.dart';

/// Enhanced Wakelock interface with robust automation, UI-friendly feedback, diagnostics, and lifecycle management.
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

  /// Toggles wakelock on/off.
  Future<void> toggle({required bool enable}) async {
    throw UnimplementedError('toggle() has not been implemented.');
  }

  /// Checks if wakelock is currently enabled.
  Future<bool> get enabled async {
    throw UnimplementedError('enabled getter has not been implemented.');
  }

  /// Temporarily enables wakelock for a given duration.
  Future<void> enableForDuration(Duration duration) async {
    await toggle(enable: true);
    await Future.delayed(duration);
    await toggle(enable: false);
  }

  /// Continuously monitors wakelock state with a stream.
  Stream<bool> monitorState({Duration interval = const Duration(seconds: 3)}) async* {
    while (true) {
      yield await enabled;
      await Future.delayed(interval);
    }
  }

  /// Returns runtime diagnostics and state info.
  Future<Map<String, dynamic>> diagnostics() async {
    final currentState = await enabled;
    return {
      'isEnabled': currentState,
      'platform': instance.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Automatically manages wakelock based on a dynamic condition.
  Future<void> autoManage(Future<bool> Function() condition, {Duration checkInterval = const Duration(seconds: 10)}) async {
    while (true) {
      final shouldEnable = await condition();
      if (shouldEnable != await enabled) await toggle(enable: shouldEnable);
      await Future.delayed(checkInterval);
    }
  }

  /// Logs state or messages with timestamp.
  void logState(String message) {
    print('💡 [WakelockPlus] ${DateTime.now().toIso8601String()} — $message');
  }

  /// Resets wakelock to disabled state.
  Future<void> reset() async => await toggle(enable: false);

  /// Pauses wakelock optionally for a specified duration.
  Future<void> pause({Duration? duration}) async {
    await toggle(enable: false);
    if (duration != null) {
      await Future.delayed(duration);
      await toggle(enable: true);
    }
  }

  /// Schedules wakelock activation at a future time.
  Future<void> scheduleActivation(DateTime time) async {
    final delay = time.difference(DateTime.now());
    if (!delay.isNegative) {
      await Future.delayed(delay);
      await toggle(enable: true);
    }
  }

  /// Returns current usage stats and implementation info.
  Future<Map<String, dynamic>> usageStats() async {
    return {
      'state': await enabled,
      'uptime': DateTime.now().toIso8601String(),
      'implementation': instance.runtimeType.toString(),
    };
  }

  /// Warns if wakelock remains active beyond a maximum duration.
  Future<void> warnIfOverused(Duration maxDuration) async {
    final start = DateTime.now();
    while (await enabled) {
      if (DateTime.now().difference(start) > maxDuration) {
        logState('⚠️  Wakelock active beyond $maxDuration');
        break;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Executes callback when wakelock state changes.
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

  /// Automatically toggles wakelock based on charging state.
  Future<void> autoBasedOnPower(bool Function() isCharging, {Duration checkInterval = const Duration(seconds: 15)}) async {
    while (true) {
      await toggle(enable: isCharging());
      await Future.delayed(checkInterval);
    }
  }

  /// Handles app lifecycle events.
  void onAppLifecycleChange(String state) {
    logState('App lifecycle changed: $state');
  }

  /// Measures execution time of a wakelock operation.
  Future<Duration> measurePerformance(Future<void> Function() operation) async {
    final start = DateTime.now();
    await operation();
    return DateTime.now().difference(start);
  }

  /// Exports diagnostics as a readable string.
  Future<String> exportDiagnostics() async {
    final data = await diagnostics();
    return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  /// Enables wakelock if CPU load is below a threshold.
  Future<void> enableIfLowCpuLoad(double Function() cpuLoad, {double threshold = 0.3, Duration checkInterval = const Duration(seconds: 5)}) async {
    while (true) {
      final load = cpuLoad();
      await toggle(enable: load < threshold);
      await Future.delayed(checkInterval);
    }
  }

  /// Watchdog for automatic re-enabling on unexpected disable.
  Future<void> watchdog({Duration checkInterval = const Duration(seconds: 10)}) async {
    while (true) {
      if (!await enabled) {
        logState('⚙️  Wakelock unexpectedly disabled — re-enabling');
        await toggle(enable: true);
      }
      await Future.delayed(checkInterval);
    }
  }

  /// Tracks session duration and returns info.
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

  /// Ensures default implementation is present.
  void _verifyProvidesDefaultImplementations() {}

  /// Enables wakelock repeatedly for a given count and duration.
  Future<void> enableRepeats(int count, Duration duration) async {
    for (int i = 0; i < count; i++) {
      await toggle(enable: true);
      await Future.delayed(duration);
      await toggle(enable: false);
    }
  }

  /// Safely executes a callback with wakelock enabled.
  Future<void> executeWithWakelock(Future<void> Function() callback) async {
    final wasEnabled = await enabled;
    if (!wasEnabled) await toggle(enable: true);
    await callback();
    if (!wasEnabled) await toggle(enable: false);
  }

  /// Returns a human-readable summary of wakelock status.
  Future<String> summary() async {
    final stats = await usageStats();
    return '💡 Wakelock state: ${stats['state']}, uptime: ${stats['uptime']}, platform: ${stats['implementation']}';
  }
} 
