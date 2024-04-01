import 'package:flutter/foundation.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

export 'src/wakelock_plus_linux_plugin.dart';
export 'src/wakelock_plus_macos_plugin.dart';
export 'src/wakelock_plus_windows_plugin.dart'
    if (dart.library.html) 'src/wakelock_plus_web_plugin.dart';

/// The [WakelockPlusPlatformInterface] that is used by [WakelockPlus].
///
/// This needs to be exposed for testing as unit tests might run on macOS.
/// In that case, the "hacky" instance override that we use here would be
/// triggered for the unit tests, even though the unit tests should actually
/// test the `pigeon` method channel implementation. Therefore, we want to
/// override this in tests that run on macOS (where there is no actual device).
@visibleForTesting
var wakelockPlusPlatformInstance = WakelockPlusPlatformInterface.instance;

/// Class providing all wakelock functionality using static members.
///
/// To enable the wakelock, you can use [WakelockPlus.enable] and to disable it,
/// you can call [WakelockPlus.disable].
/// You do not need to worry about making redundant calls, e.g. calling
/// [WakelockPlus.enable] when the wakelock is already enabled as the plugin handles
/// this for you, i.e. it checks the status to determine if the wakelock is
/// already enabled or disabled.
/// If you want the flexibility to pass a [bool] to control whether the wakelock
/// should be enabled or disabled, you can use [WakelockPlus.toggle].
///
/// The [WakelockPlus.enabled] getter allows you to retrieve the current wakelock
/// status of the device..
class WakelockPlus {
  /// Enables the wakelock.
  ///
  /// This can simply be called using `WakelockPlus.enable()` and does not return
  /// anything.
  /// You can await the [Future] to wait for the operation to complete.
  ///
  /// See also:
  /// * [toggle], which allows to enable or disable using a [bool] parameter.
  static Future<void> enable() => toggle(enable: true);

  /// Enables the CPU-wakelock.
  /// CURRENTLY ONLY AVAILABLE ON ANDROID
  ///
  /// This can simply be called using `WakelockPlus.enableCPU()` and does not return
  /// anything.
  /// You can await the [Future] to wait for the operation to complete.
  ///
  /// See also:
  /// * [toggleCPU], which allows to enable or disable using a [bool] parameter.
  static Future<void> enableCPU() => toggleCPU(enable: true);

  /// Disables the wakelock.
  ///
  /// This can simply be called using `WakelockPlus.disable()` and does not return
  /// anything.
  /// You can await the [Future] to wait for the operation to complete.
  ///
  /// See also:
  /// * [toggle], which allows to enable or disable using a [bool] parameter.
  static Future<void> disable() => toggle(enable: false);

  /// Disables the CPU-wakelock.
  /// CURRENTLY ONLY AVAILABLE ON ANDROID
  ///
  /// This can simply be called using `WakelockPlus.disableCPU()` and does not return
  /// anything.
  /// You can await the [Future] to wait for the operation to complete.
  ///
  /// See also:
  /// * [toggleCPU], which allows to enable or disable using a [bool] parameter.
  static Future<void> disableCPU() => toggleCPU(enable: false);


  /// Toggles the wakelock on or off.
  ///
  /// You can simply use this function to toggle the wakelock using a [bool]
  /// value (for the [enable] parameter).
  ///
  /// ```dart
  /// // This line keeps the screen on.
  /// WakelockPlus.toggle(enable: true);
  ///
  /// bool enableWakelock = false;
  /// // The following line disables the WakelockPlus.
  /// WakelockPlus.toggle(enable: enableWakelock);
  /// ```
  ///
  /// You can await the [Future] to wait for the operation to complete.
  static Future<void> toggle({
    required bool enable,
  }) {
    return wakelockPlusPlatformInstance.toggle(enable: enable);
  }

  /// Toggles the CPU-wakelock on or off.
  /// CURRENTLY ONLY AVAILABLE ON ANDROID
  ///
  /// You can simply use this function to toggle the CPU-wakelock using a [bool]
  /// value (for the [enable] parameter).
  ///
  /// ```dart
  /// // This line keeps the CPU on.
  /// WakelockPlus.toggleCPU(enable: true);
  ///
  /// bool enableWakelock = false;
  /// // The following line disables the WakelockPlus.
  /// WakelockPlus.toggleCPU(enable: enableWakelock);
  /// ```
  ///
  /// You can await the [Future] to wait for the operation to complete.
  static Future<void> toggleCPU({
    required bool enable,
  }) {
    return wakelockPlusPlatformInstance.toggleCPU(enable: enable);
  }

  /// Returns whether the wakelock is currently enabled or not.
  ///
  /// If you want to retrieve the current wakelock status, you will have to call
  /// [WakelockPlus.enabled] and await its result:
  ///
  /// ```dart
  /// bool wakelockEnabled = await WakelockPlus.enabled;
  /// ```
  static Future<bool> get enabled => wakelockPlusPlatformInstance.enabled;

  /// Returns whether the CPU-wakelock is currently enabled or not.
  /// CURRENTLY ONLY AVAILABLE ON ANDROID
  ///
  /// If you want to retrieve the current CPU-wakelock status, you will have to call
  /// [WakelockPlus.enabledCPU] and await its result:
  ///
  /// ```dart
  /// bool wakelockEnabled = await WakelockPlus.enabledCPU;
  /// ```
  static Future<bool> get enabledCPU => wakelockPlusPlatformInstance.enabledCPU;

}
