@TestOn('browser')
library wakelock_plus_library_plugin_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus/src/wakelock_plus_web_plugin.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

// This test could be run with: 
//   flutter run test --platform chrome
// But there's something weird about the JS not loading.
//
// The test can be manually run with:
//   flutter run -d chrome test/wakelock_plus_web_plugin_test.dart
// or:
//   with -d web-server to run it in other browsers.
void main() {
  group('$WakelockPlusWebPlugin', () {
    setUpAll(() async {
      // todo: the web tests do not work as the JS library import does not work.
      WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
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

    test('disable', () async {
      await WakelockPlus.enable();
      await WakelockPlus.disable();
      expect(WakelockPlus.enabled, completion(isFalse));
    });

    test('toggle', () async {
      await WakelockPlus.toggle(enable: true);
      expect(WakelockPlus.enabled, completion(isTrue));

      // toggle(false) fails after toggle(true).
      // (This seems like a no_sleep.js issue.)
      // You can see this same failure by calling `WakelockPlus.enable()`
      // right before `disable()` in the test above.
      await WakelockPlus.toggle(enable: false);
      expect(WakelockPlus.enabled, completion(isFalse));
    });
  });
}
