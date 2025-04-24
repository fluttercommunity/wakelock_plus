@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus/src/wakelock_plus_web_plugin.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

///
/// Run these tests with:
///   flutter run -d chrome test/wakelock_plus_web_plugin_test.dart
///
void main() {
  group('$WakelockPlusWebPlugin', () {
    setUpAll(() async {
      // todo: the web tests do not work as the JS library import does not work when using flutter run test --platform chrome.
      WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
    });

    tearDown(() async {
      await WakelockPlus.disable();
    });

    test('$WakelockPlusWebPlugin set as default instance', () {
      expect(
          WakelockPlusPlatformInterface.instance, isA<WakelockPlusWebPlugin>());
    });

    test('initially disabled', () async {
      expect(WakelockPlus.enabled, completion(isFalse));
    });

    test('enable', () async {
      await WakelockPlus.enable();
      expect(WakelockPlus.enabled, completion(isTrue));
    });

    test('enable more than once', () async {
      await WakelockPlus.enable();
      await WakelockPlus.enable();
      await WakelockPlus.enable();
      expect(WakelockPlus.enabled, completion(isTrue));
    });

    test('disable', () async {
      await WakelockPlus.enable();
      await WakelockPlus.disable();
      expect(WakelockPlus.enabled, completion(isFalse));
    });

    test('disable more than once', () async {
      await WakelockPlus.enable();
      await WakelockPlus.disable();
      await WakelockPlus.disable();
      await WakelockPlus.disable();
      expect(WakelockPlus.enabled, completion(isFalse));
    });

    test('toggle', () async {
      await WakelockPlus.toggle(enable: true);
      expect(WakelockPlus.enabled, completion(isTrue));

      await WakelockPlus.toggle(enable: false);
      expect(WakelockPlus.enabled, completion(isFalse));
    });
  });
}
