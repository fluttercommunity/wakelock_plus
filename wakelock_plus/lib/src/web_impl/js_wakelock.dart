@JS('Wakelock')
library wakelock.js;

import 'package:js/js.dart';
import 'package:wakelock_plus/src/web_impl/promise.dart';

/// Toggles the JS wakelock.
external void toggle(bool enable);

/// Returns a JS promise of whether the wakelock is enabled or not.
external PromiseJsImpl<bool> enabled();
