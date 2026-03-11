import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus_platform_interface/messages.g.dart';
import 'package:wakelock_plus_platform_interface/src/method_channel_wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'messages.g.dart';

class _ApiLogger implements TestWakelockPlusApi {
  final List<String> log = [];
  late ToggleMessage toggleMessage;

  @override
  IsEnabledMessage isEnabled() {
    log.add('isEnabled');
    return IsEnabledMessage()..enabled = true;
  }

  @override
  void toggle(ToggleMessage message) {
    log.add('toggle');
    toggleMessage = message;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$WakelockPlusPlatformInterface', () {
    test('$MethodChannelWakelockPlus() is the default instance', () {
      expect(
        WakelockPlusPlatformInterface.instance,
        isInstanceOf<MethodChannelWakelockPlus>(),
      );
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        WakelockPlusPlatformInterface.instance =
            ImplementsWakelockPlusPlatformInterface();
      }, throwsA(isA<AssertionError>()));
    });

    test('Can be mocked with `implements`', () {
      WakelockPlusPlatformInterface.instance =
          WakelockPlusPlatformInterfaceMock();
    });

    test('Can be extended', () {
      WakelockPlusPlatformInterface.instance = ExtendsWakelockPlusPlatform();
    });
  });

  group('$MethodChannelWakelockPlus', () {
    final wakelock = MethodChannelWakelockPlus();
    late final _ApiLogger logger;

    setUpAll(() {
      logger = _ApiLogger();
      TestWakelockPlusApi.setUp(logger);
    });

    test('toggle', () async {
      await wakelock.toggle(enable: true);

      expect(logger.log.last, 'toggle');
      expect(logger.toggleMessage.enable, isTrue);

      await wakelock.toggle(enable: false);

      expect(logger.log.last, 'toggle');
      expect(logger.log, hasLength(2));
      expect(logger.toggleMessage.enable, isFalse);
    });

    test('enabled', () async {
      final enabled = await wakelock.enabled;

      expect(logger.log.last, 'isEnabled');
      expect(enabled, isTrue);
    });
  });
}

/// This class should fail verification because it uses `implements`
/// and does NOT use [MockPlatformInterfaceMixin].
class ImplementsWakelockPlusPlatformInterface
    implements WakelockPlusPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// This class should pass verification because it uses [MockPlatformInterfaceMixin].
class WakelockPlusPlatformInterfaceMock
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {
  @override
  Future<bool> get enabled => throw UnimplementedError();

  @override
  bool get isMock => throw UnimplementedError();

  @override
  Future<void> toggle({required bool enable}) {
    throw UnimplementedError();
  }
}

/// This class should pass verification because it uses `extends`.
class ExtendsWakelockPlusPlatform extends WakelockPlusPlatformInterface {}
