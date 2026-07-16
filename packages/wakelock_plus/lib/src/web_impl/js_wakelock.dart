@JS('Wakelock')
library;

import 'dart:js_interop';

@JS('toggle')
external JSPromise<JSAny?> _toggle(JSBoolean enable);

/// Toggles the JS wakelock.
Future<void> toggle(bool enable) {
  return _toggle(enable.toJS).toDart.then((_) => null);
}

@JS('enabled')
external JSPromise<JSBoolean> _enabled();

/// Returns a JS promise of whether the wakelock is enabled or not.
Future<bool> enabled() {
  return _enabled().toDart.then((enabled) => enabled.toDart);
}
