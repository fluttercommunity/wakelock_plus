import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus_platform_interface/src/method_channel_wakelock_plus.dart';

/// The interface that implementations of wakelock must implement.
///
/// Platform implementations should extend this class rather than implement it
/// because `implements` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation.
abstract class WakelockPlusPlatformInterface extends PlatformInterface {
  /// Creates a new [WakelockPlusPlatformInterface] instance
  WakelockPlusPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static WakelockPlusPlatformInterface _instance = MethodChannelWakelockPlus();

  /// The default instance of [WakelockPlusPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelWakelockPlus].
  static WakelockPlusPlatformInterface get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [WakelockPlusPlatformInterface] when they register
  /// themselves.
  static set instance(WakelockPlusPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Only mock implementations should set this to true.
  ///
  /// Mockito mocks are implementing this class with `implements`, which is
  /// forbidden for anything other than mocks (see class docs). This property
  /// provides a backdoor for mockito mocks to skip the verification that the
  /// class is not implemented with `implements`.
  @visibleForTesting
  bool get isMock => false;

  /// Toggles the wakelock based on the given [enable] value.
  Future<void> toggle({required bool enable}) {
    throw UnimplementedError('toggle() has not been implemented.');
  }

  /// Toggles the CPU wakelock based on the given [enable] value.
  Future<void> toggleCPU({required bool enable}) {
    throw UnimplementedError('toggleCPU() has not been implemented.');
  }

  /// Returns whether the wakelock is enabled or not.
  Future<bool> get enabled {
    throw UnimplementedError('isEnabled has not been implemented.');
  }

  /// Returns whether the CPU wakelock is enabled or not.
  Future<bool> get enabledCPU {
    throw UnimplementedError('isEnabledCPU has not been implemented.');
  }

  // This method makes sure that VideoPlayer isn't implemented with `implements`.
  //
  // See class doc for more details on why implementing this class is forbidden.
  //
  // This private method is called by the instance setter, which fails if the
  // class is implemented with `implements`.
  // ignore: unused_element
  void _verifyProvidesDefaultImplementations() {}
}
