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
  // Let system handle back if there's nothing to pop (e.g. root screen)
  if (!Navigator.canPop(context)) {
    return KeyEventResult.ignored;
  }
  // Don't handle back when a dialog/overlay is on top of our route —
  // the overlay handles its own dismissal via DismissAction.
  if (ModalRoute.of(context)?.isCurrent != true) {
    return KeyEventResult.ignored;
  }
  // Handle on KeyUpEvent to prevent double-pop when returning from child screens
  // (KeyDownEvent can be received by both the popping screen and the returned-to screen)
  return handleBackKeyAction(event, () => Navigator.pop(context, result));
}

/// Handles a select key as a one-shot button activation.
///
/// Fires [onActivate] on the initial [KeyDownEvent] only.
/// Consumes all select key events (down, repeat, up) to prevent
/// unhandled events from reaching platform-level handling.
/// Returns [KeyEventResult.ignored] for non-select keys.
KeyEventResult handleOneShotSelect(KeyEvent event, VoidCallback onActivate) {
  if (!event.logicalKey.isSelectKey) return KeyEventResult.ignored;
  if (event is KeyDownEvent) onActivate();
  return KeyEventResult.handled;
}

/// Creates a [FocusOnKeyEventCallback] that dispatches d-pad / arrow keys to
/// the provided directional callbacks.
///
/// Each callback is optional. Directions without a callback are ignored
/// (passed through to the framework). Directions mapped to a callback
/// automatically return [KeyEventResult.handled].
///
/// Directional keys repeat on [KeyRepeatEvent] (via [isActionable]).
/// Select is one-shot: fires on [KeyDownEvent] only, consumes repeat and up.
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
    // Select: one-shot activation (no repeat), must run before isActionable
    // filter so KeyUpEvent is also consumed.
    if (onSelect != null) {
      final result = handleOneShotSelect(event, onSelect);
      if (result != KeyEventResult.ignored) return result;
    }

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
