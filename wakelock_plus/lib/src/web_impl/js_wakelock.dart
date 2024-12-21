@JS('Wakelock')
library;

import 'dart:js_interop';

/// Toggles the JS wakelock.
@JS()
external JSPromise<JSAny?> toggle(bool enable);

/// Returns a JS promise of whether the wakelock is enabled or not.
@JS()
external JSPromise<JSBoolean> enabled();
