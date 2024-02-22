import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:wakelock_plus/src/web_impl/import_js_library.dart';
import 'package:wakelock_plus/src/web_impl/js_wakelock.dart'
    as wakelock_plus_web;

/// The web implementation of the [WakelockPlatformInterface].
///
/// This class implements the `wakelock_plus` plugin functionality for web.
class WakelockPlusWebPlugin extends WakelockPlusPlatformInterface {
  /// Builds an instance of the plugin, and imports the JS implementation.
  WakelockPlusWebPlugin() {
    _jsLoaded = importJsLibrary(
        url: 'assets/no_sleep.js', flutterPluginName: 'wakelock_plus');
  }

  // The future that signals when the JS is loaded.
  // This needs to be `await`ed before accessing any methods of the
  // JS-interop layer.
  Future<void>? _jsLoaded;

  /// Registers [WakelockPlusWebPlugin] as the default instance of the
  /// [WakelockPlatformInterface].
  static void registerWith(Registrar registrar) {
    WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
  }

  @override
  Future<void> toggle({required bool enable}) async {
    // Await _jsLoaded before accessing wakelock_plus_web
    await _jsLoaded!;

    wakelock_plus_web.toggle(enable);
  }

  @override
  Future<bool> get enabled async {
    await _jsLoaded!;

    // Can be simplified a lot
    return promiseToFuture(wakelock_plus_web.enabled());
  }
}
