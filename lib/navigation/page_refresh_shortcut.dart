import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mixins/refreshable.dart';
import '../utils/platform_detector.dart';

/// Whether [event] is the exact current-page refresh chord for this desktop.
bool _isPageRefreshShortcut(KeyEvent event) {
  if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyR) return false;
  if (!PlatformDetector.isDesktopOS() || PlatformDetector.isTV()) return false;

  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed || keyboard.isAltPressed) return false;

  return defaultTargetPlatform == TargetPlatform.macOS
      ? keyboard.isMetaPressed && !keyboard.isControlPressed
      : keyboard.isControlPressed && !keyboard.isMetaPressed;
}

/// Handles the refresh chord only when the current scope supplies [onRefresh].
KeyEventResult handlePageRefreshShortcut(KeyEvent event, VoidCallback? onRefresh) {
  if (!_isPageRefreshShortcut(event) || onRefresh == null) return KeyEventResult.ignored;
  onRefresh();
  return KeyEventResult.handled;
}

/// Dispatches the refresh chord to a current screen with manual refresh support.
KeyEventResult dispatchPageRefreshShortcut(KeyEvent event, Object? currentScreen) {
  return handlePageRefreshShortcut(event, currentScreen is ManualRefreshable ? currentScreen.manualRefresh : null);
}
