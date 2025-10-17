import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Global manager for tracking fullscreen state across the app
class FullscreenStateManager extends ChangeNotifier with WindowListener {
  static final FullscreenStateManager _instance =
      FullscreenStateManager._internal();

  factory FullscreenStateManager() => _instance;

  FullscreenStateManager._internal();

  bool _isFullscreen = false;
  bool _isListening = false;

  bool get isFullscreen => _isFullscreen;

  /// Manually set fullscreen state (called by NSWindowDelegate callbacks on macOS)
  void setFullscreen(bool value) {
    if (_isFullscreen != value) {
      _isFullscreen = value;
      notifyListeners();
    }
  }

  /// Start monitoring fullscreen state
  void startMonitoring() {
    if (!_shouldMonitor() || _isListening) return;

    // Use window_manager listener for Windows/Linux
    // macOS uses NSWindowDelegate callbacks instead (see FullscreenWindowDelegate)
    if (!Platform.isMacOS) {
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
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
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
