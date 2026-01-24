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
KeyEventResult handleBackKeyAction(
  KeyEvent event,
  VoidCallback onBack,
) {
  if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;

  if (event is KeyUpEvent) {
    BackKeyCoordinator.markHandled();
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
