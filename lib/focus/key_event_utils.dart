import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dpad_navigator.dart';

/// Handles back key events by popping the current route.
///
/// Optionally pass a [result] to return to the previous route.
///
/// Use this as an `onKeyEvent` callback for Focus widgets that need
/// simple back navigation behavior:
///
/// ```dart
/// Focus(
///   onKeyEvent: (node, event) => handleBackKeyNavigation(context, event),
///   child: ...
/// )
/// ```
///
/// With a result value:
/// ```dart
/// Focus(
///   onKeyEvent: (node, event) => handleBackKeyNavigation(
///     context,
///     event,
///     result: _hasChanges,
///   ),
///   child: ...
/// )
/// ```
class BackKeyCoordinator {
  static bool _handledThisFrame = false;
  static bool _clearScheduled = false;

  static void markHandled() {
    _handledThisFrame = true;
    if (_clearScheduled) return;
    _clearScheduled = true;
    // Clear on next frame to avoid blocking unrelated future back presses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handledThisFrame = false;
      _clearScheduled = false;
    });
  }

  static bool consumeIfHandled() {
    if (_handledThisFrame) {
      _handledThisFrame = false;
      return true;
    }
    return false;
  }
}

/// Handle a BACK key press by running [onBack] on key up.
///
/// This consumes KeyDown/KeyRepeat to avoid duplicate actions from key repeat.
/// Optionally suppresses stray KeyUp events delivered to the next route after a pop.
KeyEventResult handleBackKeyAction(KeyEvent event, VoidCallback onBack) {
  if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;

  // Check if this BACK event should be suppressed (e.g., after modal closed)
  if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
    return KeyEventResult.handled;
  }

  if (event is KeyUpEvent) {
    BackKeyCoordinator.markHandled();
    // Mark that we're closing via back key so suppressBackUntilKeyUp() knows to skip
    BackKeyUpSuppressor.markClosedViaBackKey();
    onBack();
    return KeyEventResult.handled;
  }
  if (event is KeyDownEvent || event is KeyRepeatEvent) {
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

KeyEventResult handleBackKeyNavigation<T>(BuildContext context, KeyEvent event, {T? result}) {
  // Handle on KeyUpEvent to prevent double-pop when returning from child screens
  // (KeyDownEvent can be received by both the popping screen and the returned-to screen)
  return handleBackKeyAction(event, () => Navigator.pop(context, result));
}

/// Creates a [FocusOnKeyEventCallback] that dispatches d-pad / arrow keys to
/// the provided directional callbacks.
///
/// Each callback is optional. Directions without a callback are ignored
/// (passed through to the framework). Directions mapped to a callback
/// automatically return [KeyEventResult.handled].
///
/// Only [KeyDownEvent] and [KeyRepeatEvent] are handled (via [isActionable]).
///
/// ```dart
/// Focus(
///   onKeyEvent: dpadKeyHandler(
///     onUp: () => _focusAppBar(),
///     onDown: () => _focusContent(),
///     onLeft: () => _navigateToSidebar(),
///     onSelect: () => _play(),
///   ),
///   child: ...
/// )
/// ```
FocusOnKeyEventCallback dpadKeyHandler({
  VoidCallback? onUp,
  VoidCallback? onDown,
  VoidCallback? onLeft,
  VoidCallback? onRight,
  VoidCallback? onSelect,
}) {
  return (FocusNode _, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isUpKey && onUp != null) {
      onUp();
      return KeyEventResult.handled;
    }
    if (key.isDownKey && onDown != null) {
      onDown();
      return KeyEventResult.handled;
    }
    if (key.isLeftKey && onLeft != null) {
      onLeft();
      return KeyEventResult.handled;
    }
    if (key.isRightKey && onRight != null) {
      onRight();
      return KeyEventResult.handled;
    }
    if (key.isSelectKey && onSelect != null) {
      onSelect();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  };
}

/// Navigator observer that automatically suppresses stray back KeyUp events
/// after any route pop caused by a back key press.
///
/// This catches pops triggered by Flutter's built-in DismissAction (which fires
/// on KeyDown for dialogs) and Android TV system back gestures, preventing the
/// orphaned KeyUp from propagating to the underlying screen's back handler.
class BackKeySuppressorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    if (BackKeyPressTracker.isBackKeyDown) {
      BackKeyUpSuppressor.suppressBackUntilKeyUp();
    }
  }
}
