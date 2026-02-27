import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'fullscreen_state_manager.dart';

/// Abstract class for receiving macOS window delegate callbacks.
/// Extend this class and register with [MacOSWindowService] to receive
/// fullscreen transition events.
abstract class MacOSWindowDelegate {
  /// Called when the window is about to enter fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowWillEnterFullScreen() {}

  /// Called when the window has entered fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowDidEnterFullScreen() {}

  /// Called when the window is about to exit fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowWillExitFullScreen() {}

  /// Called when the window has exited fullscreen mode.
  // ignore: no-empty-block - default no-op, subclasses override as needed
  void windowDidExitFullScreen() {}
}

/// Service for manipulating macOS window properties.
/// This is a native implementation replacing the macos_window_utils package.
///
/// Note: Titlebar, toolbar, and traffic light position management is now handled
/// directly in Swift (WindowDelegate.swift) during fullscreen transitions.
/// This service only exposes what's needed externally:
/// - Traffic light visibility (for video controls)
/// - Fullscreen enter/exit (for video controls)
/// - Delegate registration (for FullscreenStateManager updates)
class MacOSWindowService {
  static const _channel = MethodChannel('com.plezy/window_utils');
  static bool _initialized = false;
  static bool _delegateEnabled = false;
  static final List<MacOSWindowDelegate> _delegates = [];

  // MARK: - Private Helpers

  static Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod(method, args);
  }

  static void _notifyDelegates(void Function(MacOSWindowDelegate) callback) {
    for (final delegate in _delegates) {
      callback(delegate);
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'windowWillEnterFullScreen':
        _notifyDelegates((d) => d.windowWillEnterFullScreen());
      case 'windowDidEnterFullScreen':
        _notifyDelegates((d) => d.windowDidEnterFullScreen());
      case 'windowWillExitFullScreen':
        _notifyDelegates((d) => d.windowWillExitFullScreen());
      case 'windowDidExitFullScreen':
        _notifyDelegates((d) => d.windowDidExitFullScreen());
    }
  }

  // MARK: - Initialization

  /// Initialize the window service and set up the titlebar.
  ///
  /// Note: The initial window configuration (transparent titlebar, toolbar,
  /// button positions, fullscreen presentation options) is now applied in
  /// MainFlutterWindow.swift / WindowDelegate.swift BEFORE frame restoration
  /// to prevent the window from shrinking on launch.
  ///
  /// This method sets up the Dart-side callbacks for fullscreen state tracking.
  static Future<void> setupCustomTitlebar() async {
    if (!Platform.isMacOS || _initialized) return;

    await initialize(enableWindowDelegate: true);
    addWindowDelegate(_FullscreenWindowDelegate());
  }

  /// Initialize the window service.
  /// Must be called before using other methods.
  /// Set [enableWindowDelegate] to true to receive fullscreen callbacks.
  static Future<void> initialize({bool enableWindowDelegate = false}) async {
    if (!Platform.isMacOS) return;

    if (!_initialized) {
      await _channel.invokeMethod('initialize', {'enableWindowDelegate': enableWindowDelegate});
      _initialized = true;
    }

    // Set up handler if not already done and delegate is requested
    if (enableWindowDelegate && !_delegateEnabled) {
      _channel.setMethodCallHandler(_handleMethodCall);
      _delegateEnabled = true;
    }
  }

  /// Add a delegate to receive window events.
  static void addWindowDelegate(MacOSWindowDelegate delegate) {
    if (!_delegates.contains(delegate)) {
      _delegates.add(delegate);
    }
  }

  /// Remove a previously added delegate.
  static void removeWindowDelegate(MacOSWindowDelegate delegate) {
    _delegates.remove(delegate);
  }

  // MARK: - Traffic Light Buttons

  /// Show or hide all traffic light buttons (close, miniaturize, zoom).
  static Future<void> setTrafficLightsVisible(bool visible) => _invoke('setTrafficLightsVisible', {'visible': visible});

  // MARK: - Fullscreen

  /// Enter fullscreen mode.
  static Future<void> enterFullscreen() => _invoke('enterFullscreen');

  /// Exit fullscreen mode.
  static Future<void> exitFullscreen() => _invoke('exitFullscreen');

  /// Check if the window is in fullscreen mode.
  static Future<bool> isFullscreen() async {
    if (!Platform.isMacOS) return false;
    return await _channel.invokeMethod<bool>('isFullscreen') ?? false;
  }
}

/// Internal window delegate that manages fullscreen state.
/// Note: Window manipulation (toolbar, titlebar, traffic lights) is now handled
/// directly in Swift's WindowDelegate. This class only updates Dart-side state.
class _FullscreenWindowDelegate extends MacOSWindowDelegate {
  @override
  void windowWillEnterFullScreen() {
    FullscreenStateManager().setFullscreen(true);
  }

  @override
  void windowDidExitFullScreen() {
    FullscreenStateManager().setFullscreen(false);
  }
}
