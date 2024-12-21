import 'package:pigeon/pigeon.dart';

/// Message for toggling the wakelock on the platform side.
class ToggleMessage {
  bool? enable;
}

/// Message for reporting the wakelock state from the platform side.
class IsEnabledMessage {
  bool? enabled;
}

@ConfigurePigeon(PigeonOptions(
  dartOut: '../wakelock_plus_platform_interface/lib/messages.g.dart',
  dartTestOut: '../wakelock_plus_platform_interface/test/messages.g.dart',
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'WAKELOCKPLUS',
  ),
  kotlinOptions: KotlinOptions(errorClassName: "WakelockPlusFlutterError"),
  kotlinOut:
      'android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt',
))
@HostApi(dartHostTestHandler: 'TestWakelockPlusApi')
abstract class WakelockPlusApi {
  void toggle(ToggleMessage msg);

  IsEnabledMessage isEnabled();
}
