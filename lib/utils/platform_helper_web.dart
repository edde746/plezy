/// Web platform implementation with webOS detection.
library;

import 'dart:js_interop';

bool get isAndroid => false;
bool get isIOS => false;
bool get isMacOS => false;
bool get isWindows => false;
bool get isLinux => false;
bool get isFuchsia => false;
bool get isWeb => true;
bool get isWebOS => _detectWebOS();

bool? _webOSCached;

bool _detectWebOS() {
  if (_webOSCached != null) return _webOSCached!;
  _webOSCached = _checkWebOS();
  return _webOSCached!;
}

@JS('window.isWebOS')
external bool? get _jsIsWebOS;

bool _checkWebOS() {
  try {
    return _jsIsWebOS ?? false;
  } catch (_) {
    return false;
  }
}
