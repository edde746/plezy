import 'package:flutter/foundation.dart';
import '../utils/platform_helper.dart';
import 'package:window_manager/window_manager.dart';
import 'macos_window_service.dart';

/// Global manager for tracking fullscreen state across the app
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
    final isCurrentlyFullscreen = await windowManager.isFullScreen();

    if (AppPlatform.isMacOS) {
      if (isCurrentlyFullscreen) {
        await MacOSWindowService.exitFullscreen();
      } else {
        await MacOSWindowService.enterFullscreen();
      }
    } else {
      if (isCurrentlyFullscreen) {
        await windowManager.setFullScreen(false);
        if (_wasMaximized) {
          await windowManager.maximize();
          _wasMaximized = false;
        }
      } else {
        _wasMaximized = await windowManager.isMaximized();
        if (_wasMaximized) {
          await windowManager.unmaximize();
        }
        await windowManager.setFullScreen(true);
      }
    }
  }

  /// Exit fullscreen, restoring maximized state if needed
  Future<void> exitFullscreen() async {
    if (AppPlatform.isMacOS) {
      await MacOSWindowService.exitFullscreen();
    } else {
      await windowManager.setFullScreen(false);
      if (_wasMaximized) {
        await windowManager.maximize();
        _wasMaximized = false;
      }
    }
  }

  /// Start monitoring fullscreen state
  void startMonitoring() {
    if (!_shouldMonitor() || _isListening) return;

    // Use window_manager listener for Windows/Linux
    // macOS uses NSWindowDelegate callbacks instead (see FullscreenWindowDelegate)
    if (!AppPlatform.isMacOS) {
      windowManager.addListener(this);
      _isListening = true;
    }
  }

  /// Stop monitoring fullscreen state
  void stopMonitoring() {
    if (_isListening) {
      windowManager.removeListener(this);
      _isListening = false;
    }
  }

  bool _shouldMonitor() {
    return AppPlatform.isMacOS || AppPlatform.isWindows || AppPlatform.isLinux;
  }

  // WindowListener callbacks for Windows/Linux
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
