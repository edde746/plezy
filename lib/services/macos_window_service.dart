import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'fullscreen_state_manager.dart';

/// Service for manipulating macOS window properties.
/// This is a native implementation replacing the macos_window_utils package.
///
/// Note: Titlebar, toolbar, and traffic light position management is now handled
/// directly in Swift (WindowDelegate.swift) during fullscreen transitions.
/// This service only exposes what's needed externally:
/// - Traffic light visibility (for video controls)
/// - Fullscreen enter/exit (for video controls)
/// - Fullscreen state tracking (for FullscreenStateManager updates)
class MacOSWindowService {
  static const _channel = MethodChannel('com.plezy/window_utils');
  static bool _initialized = false;
  static bool _delegateEnabled = false;

  static Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod(method, args);
  }

  /// Window manipulation (toolbar, titlebar, traffic lights) is handled directly
  /// in Swift's WindowDelegate; this only mirrors the transition into Dart state.
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'windowWillEnterFullScreen':
        FullscreenStateManager().setFullscreen(true);
      case 'windowDidExitFullScreen':
        FullscreenStateManager().setFullscreen(false);
    }
  }

  /// Initialize the window service and set up the titlebar.
  ///
  /// Note: The initial window configuration (transparent titlebar, toolbar,
  /// button positions, fullscreen presentation options) is now applied in
  /// MainFlutterWindow.swift / WindowDelegate.swift BEFORE frame restoration
  /// to prevent the window from shrinking on launch.
  ///
  /// This method sets up the Dart-side callbacks for fullscreen state tracking.
  static Future<void> setupCustomTitlebar() async {
    if (!Platform.isMacOS) return;

    if (_initialized && _delegateEnabled) {
      await syncWindowChrome();
      FullscreenStateManager().setFullscreen(await isFullscreen());
      return;
    }

    await initialize(enableWindowDelegate: true);
    await syncWindowChrome();
    FullscreenStateManager().setFullscreen(await isFullscreen());
  }

  /// Initialize the window service.
  /// Must be called before using other methods.
  /// Set [enableWindowDelegate] to true to receive fullscreen callbacks.
  static Future<void> initialize({bool enableWindowDelegate = false}) async {
    if (!Platform.isMacOS) return;

    if (!_initialized || (enableWindowDelegate && !_delegateEnabled)) {
      await _channel.invokeMethod('initialize', {'enableWindowDelegate': enableWindowDelegate});
      _initialized = true;
    }

    // Set up handler if not already done and delegate is requested
    if (enableWindowDelegate && !_delegateEnabled) {
      _channel.setMethodCallHandler(_handleMethodCall);
      _delegateEnabled = true;
    }
  }

  static Future<void> setTrafficLightsVisible(bool visible) => _invoke('setTrafficLightsVisible', {'visible': visible});

  static Future<void> syncWindowChrome() => _invoke('syncWindowChrome');

  static Future<void> enterFullscreen() => _invoke('enterFullscreen');

  static Future<void> exitFullscreen() => _invoke('exitFullscreen');

  static Future<bool> isFullscreen() async {
    if (!Platform.isMacOS) return false;
    return await _channel.invokeMethod<bool>('isFullscreen') ?? false;
  }
}
