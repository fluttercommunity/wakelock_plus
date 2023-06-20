import 'package:flutter_test/flutter_test.dart';
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
      expect(WakelockPlusPlatformInterface.instance,
          isInstanceOf<MethodChannelWakelockPlus>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        WakelockPlusPlatformInterface.instance =
            const ImplementsWakelockPlusPlatformInterface(false);
      }, throwsA(isInstanceOf<NoSuchMethodError>()));
    });

    test('Can be mocked with `implements`', () {
      WakelockPlusPlatformInterface.instance =
          const ImplementsWakelockPlusPlatformInterface(true);
    });

    test('Can be extended', () {
      WakelockPlusPlatformInterface.instance = ExtendsVideoPlayerPlatform();
    });
  });

  group('$MethodChannelWakelockPlus', () {
    final wakelock = MethodChannelWakelockPlus();
    late final _ApiLogger logger;

    setUpAll(() {
      logger = _ApiLogger();
      TestWakelockPlusApi.setup(logger);
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

class ImplementsWakelockPlusPlatformInterface implements WakelockPlusPlatformInterface {
  const ImplementsWakelockPlusPlatformInterface(this.mocked);

  final bool mocked;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #isMock && mocked) return true;
    throw NoSuchMethodError.withInvocation(this, invocation);
  }
}

class ExtendsVideoPlayerPlatform extends WakelockPlusPlatformInterface {}
