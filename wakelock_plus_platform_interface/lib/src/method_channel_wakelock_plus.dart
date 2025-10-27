import 'package:wakelock_plus_platform_interface/messages.g.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Method channel implementation of the [WakelockPlusPlatformInterface].
class MethodChannelWakelockPlus extends WakelockPlusPlatformInterface {
  final _api = WakelockPlusApi();

  @override
  bool get isMock => false;

  @override
  Future<bool> get enabled async {
    final message = await _api.isEnabled();

    return message.enabled ?? false;
  }

  @override
  Future<void> toggle({required bool enable}) async {
    final message = ToggleMessage();
    message.enable = enable;

    await _api.toggle(message);
  }

  /// Enables the wakelock.
  @override
  Future<void> enable() async {
    await toggle(enable: true);
  }

  /// Disables the wakelock.
  @override
  Future<void> disable() async {
    await toggle(enable: false);
  }
}
