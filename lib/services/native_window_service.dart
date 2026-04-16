import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'fullscreen_state_manager.dart';

/// Windows-only native window wrapper. Exposes a monitor-aware fullscreen
/// implementation that lives in the Win32 runner (windows/runner/flutter_window.cpp)
/// as a workaround for window_manager's multi-monitor fullscreen bug
/// (edde746/plezy#880).
///
/// No-op on non-Windows platforms — callers should keep using
/// `MacOSWindowService` on macOS and `window_manager` on Linux.
class NativeWindowService {
  static const _channel = MethodChannel('plezy/window');
  static bool _initialized = false;

  /// Hook the native → Dart callback that keeps [FullscreenStateManager] in
  /// sync with OS-driven fullscreen transitions. Safe to call more than once.
  static void initialize() {
    if (!Platform.isWindows || _initialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFullScreenChanged') {
      final value = call.arguments;
      if (value is bool) {
        FullscreenStateManager().setFullscreen(value);
      }
    }
  }

  /// Enter or exit native fullscreen on the current monitor.
  static Future<void> setFullScreen(bool isFullScreen) async {
    if (!Platform.isWindows) return;
    await _channel.invokeMethod('setFullScreen', {'isFullScreen': isFullScreen});
  }

  /// Query the native fullscreen state. Returns false off-Windows.
  static Future<bool> isFullScreen() async {
    if (!Platform.isWindows) return false;
    return await _channel.invokeMethod<bool>('isFullScreen') ?? false;
  }
}
