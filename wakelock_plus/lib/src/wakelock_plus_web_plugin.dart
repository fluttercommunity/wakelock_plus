import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:wakelock_plus/src/web_impl/import_js_library.dart';
import 'package:wakelock_plus/src/web_impl/js_wakelock.dart'
    as wakelock_plus_web;

/// The web implementation of the [WakelockPlatformInterface].
///
/// This class implements the `wakelock_plus` plugin functionality for web.
class WakelockPlusWebPlugin extends WakelockPlusPlatformInterface {
  /// Registers [WakelockPlusWebPlugin] as the default instance of the
  /// [WakelockPlatformInterface].
  static void registerWith(Registrar registrar) {
    // Import a version of `NoSleep.js` that was adjusted for the wakelock
    // plugin.
    importJsLibrary(
        url: 'assets/no_sleep.js', flutterPluginName: 'wakelock_plus');

    WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
  }

  @override
  Future<void> toggle({required bool enable}) async {
    wakelock_plus_web.toggle(enable);
  }

  @override
  Future<bool> get enabled async {
    final completer = Completer<bool>();

    wakelock_plus_web.enabled().then(
      // onResolve
      allowInterop((value) {
        assert(value is bool);

        completer.complete(value);
      }),
      // onReject
      allowInterop((error) {
        completer.completeError(error);
      }),
    );

    return completer.future;
  }
}
