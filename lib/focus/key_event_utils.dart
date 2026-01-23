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
KeyEventResult handleBackKeyNavigation<T>(BuildContext context, KeyEvent event, {T? result}) {
  // Handle on KeyUpEvent to prevent double-pop when returning from child screens
  // (KeyDownEvent can be received by both the popping screen and the returned-to screen)
  if (event is KeyUpEvent && event.logicalKey.isBackKey) {
    Navigator.pop(context, result);
    return KeyEventResult.handled;
  }
  // Consume KeyDownEvent to prevent it from propagating but don't pop yet
  if (event is KeyDownEvent && event.logicalKey.isBackKey) {
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
