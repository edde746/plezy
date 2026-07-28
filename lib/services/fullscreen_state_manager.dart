import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/platform_detector.dart';
import 'macos_window_service.dart';
import 'native_window_service.dart';

class FullscreenStateManager extends ChangeNotifier with WindowListener {
  static final FullscreenStateManager _instance = FullscreenStateManager._internal();

  factory FullscreenStateManager() => _instance;

  FullscreenStateManager._internal();

  bool _isFullscreen = false;
  bool _isListening = false;
  bool _wasMaximized = false;

  bool get isFullscreen => _isFullscreen;

  /// Manually set fullscreen state (called by NSWindowDelegate callbacks on macOS)
  void setFullscreen(bool value) {
    if (_isFullscreen != value) {
      _isFullscreen = value;
      notifyListeners();
    }
  }

  /// Toggle fullscreen state, handling maximized-to-fullscreen transition on Windows/Linux
  Future<void> toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;

    final isCurrentlyFullscreen = await _platformIsFullscreen();
    await _platformSetFullscreen(!isCurrentlyFullscreen);
  }

  /// Enter fullscreen, preserving maximized state on Windows/Linux for restoration on exit.
  Future<void> enterFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;

    await _platformSetFullscreen(true);
  }

  /// Exit fullscreen, restoring maximized state if needed
  Future<void> exitFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;

    await _platformSetFullscreen(false);
  }

  /// Exits fullscreen when the platform window is currently fullscreen.
  ///
  /// Returns whether fullscreen consumed the request. Querying the native
  /// source avoids relying on listener state that may still be catching up.
  Future<bool> exitFullscreenIfActive() async {
    if (!PlatformDetector.isDesktopOS()) return false;

    final isActive = await _platformIsFullscreen();
    if (!isActive) return false;

    await _platformSetFullscreen(false);
    return true;
  }

  Future<bool> _platformIsFullscreen() {
    if (Platform.isMacOS) return MacOSWindowService.isFullscreen();
    if (Platform.isWindows) return NativeWindowService.isFullScreen();
    return windowManager.isFullScreen();
  }

  Future<void> _platformSetFullscreen(bool value) async {
    if (Platform.isMacOS) {
      if (value) {
        await MacOSWindowService.enterFullscreen();
      } else {
        await MacOSWindowService.exitFullscreen();
      }
    } else if (Platform.isWindows) {
      // Route through the native Win32 runner, which restores to the monitor
      // the window is currently on (window_manager 0.5.1 picks the wrong one
      // on multi-monitor setups — see issue #880). The native code also
      // preserves maximized state internally, so no unmaximize dance here.
      await NativeWindowService.setFullScreen(value);
    } else if (value) {
      _wasMaximized = await windowManager.isMaximized();
      if (_wasMaximized) {
        await windowManager.unmaximize();
      }
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
      if (_wasMaximized) {
        await windowManager.maximize();
        _wasMaximized = false;
      }
    }
  }

  void startMonitoring() {
    if (!_shouldMonitor() || _isListening) return;

    // Use window_manager listener for Windows/Linux
    // macOS uses NSWindowDelegate callbacks instead (see FullscreenWindowDelegate)
    if (!Platform.isMacOS) {
      windowManager.addListener(this);
      _isListening = true;
    }
  }

  void stopMonitoring() {
    if (_isListening) {
      windowManager.removeListener(this);
      _isListening = false;
    }
  }

  bool _shouldMonitor() {
    return PlatformDetector.isDesktopOS();
  }

  @override
  void onWindowEnterFullScreen() {
    setFullscreen(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    setFullscreen(false);
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
