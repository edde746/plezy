import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mixins/refreshable.dart';
import '../utils/platform_detector.dart';

/// Whether [event] is the exact current-page refresh chord for this desktop.
bool isPageRefreshShortcut(KeyEvent event) {
  if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyR) return false;
  if (!PlatformDetector.isDesktopOS() || PlatformDetector.isTV()) return false;

  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed || keyboard.isAltPressed) return false;

  return defaultTargetPlatform == TargetPlatform.macOS
      ? keyboard.isMetaPressed && !keyboard.isControlPressed
      : keyboard.isControlPressed && !keyboard.isMetaPressed;
}

/// Handles a refresh chord only when the current scope supplies [onRefresh].
KeyEventResult handlePageRefreshShortcut(KeyEvent event, {required VoidCallback? onRefresh}) {
  if (!isPageRefreshShortcut(event) || onRefresh == null) return KeyEventResult.ignored;
  onRefresh();
  return KeyEventResult.handled;
}

/// Dispatches a refresh chord to a current screen with manual refresh support.
KeyEventResult dispatchPageRefreshShortcut(KeyEvent event, Object? currentScreen) {
  return handlePageRefreshShortcut(
    event,
    onRefresh: currentScreen is ManualRefreshable ? currentScreen.manualRefresh : null,
  );
}

/// A non-traversable refresh shortcut scope for pushed refreshable routes.
class PageRefreshShortcut extends StatelessWidget {
  const PageRefreshShortcut({super.key, required this.onRefresh, required this.child});

  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (_, event) => handlePageRefreshShortcut(event, onRefresh: onRefresh),
      child: child,
    );
  }
}
