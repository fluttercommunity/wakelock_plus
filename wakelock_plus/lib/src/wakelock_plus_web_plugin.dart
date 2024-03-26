import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
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
    _jsLoaded = importJsLibrary(
        url: 'assets/no_sleep.js', flutterPluginName: 'wakelock_plus');

    WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
  }

  // The future that resolves when the JS library is loaded.
  static late Future<void> _jsLoaded;

  @override
  Future<void> toggle({required bool enable}) async {
    // Make sure the JS library is loaded before calling it.
    await _jsLoaded;

    wakelock_plus_web.toggle(enable);
  }

  @override
  Future<bool> get enabled async {
    // Make sure the JS library is loaded before calling it.
    await _jsLoaded;

    final completer = Completer<bool>();

    wakelock_plus_web.enabled().toDart.then(
      // onResolve
      (value) {
        completer.complete(value.toDart);
      },
      // onReject
      onError: (error) {
        completer.completeError(error);
      },
    );

    return completer.future;
  }
}
