import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:wakelock_plus/src/web_impl/import_js_library.dart';
import 'package:wakelock_plus/src/web_impl/js_wakelock.dart'
    as wakelock_plus_web;
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// The web implementation of the [WakelockPlatformInterface].
///
/// This class implements the `wakelock_plus` plugin functionality for web.
class WakelockPlusWebPlugin extends WakelockPlusPlatformInterface {
  /// Registers [WakelockPlusWebPlugin] as the default instance of the
  /// [WakelockPlatformInterface].
  static void registerWith(Registrar registrar) {
    WakelockPlusPlatformInterface.instance = WakelockPlusWebPlugin();
  }

  // The future that signals when the JS is loaded.
  // This needs to be `await`ed before accessing any methods of the
  // JS-interop layer.
  Future<void>? _jsLoaded;

  //
  // Lazily imports the JS library once, then awaits to ensure that
  // it's loaded into the DOM.
  //
  Future<void> _ensureJsLoaded() async {
    _jsLoaded ??= importJsLibrary(
      url: 'assets/no_sleep.js',
      flutterPluginName: 'wakelock_plus',
    );
    return _jsLoaded;
  }

  @override
  Future<void> toggle({required bool enable}) async {
    // Make sure the JS library is loaded before calling it.
    await _ensureJsLoaded();
    await wakelock_plus_web.toggle(enable);
  }

  @override
  Future<bool> get enabled async {
    // Make sure the JS library is loaded before calling it.
    await _ensureJsLoaded();
    return wakelock_plus_web.enabled();
  }
}
