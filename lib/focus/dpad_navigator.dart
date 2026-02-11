import 'package:flutter/services.dart';

/// Extension on KeyEvent for common event type checks.
extension KeyEventActionable on KeyEvent {
  /// Whether this event should trigger an action (KeyDownEvent or KeyRepeatEvent).
  /// Use this to filter out KeyUpEvents early in key handlers.
  bool get isActionable => this is KeyDownEvent || this is KeyRepeatEvent;
}

/// Shared sets for keyboard key categories.
final _dpadDirectionKeys = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
};

final _selectKeys = {
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.gameButtonA,
};

final _backKeys = {
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.goBack,
  LogicalKeyboardKey.browserBack,
  LogicalKeyboardKey.gameButtonB,
};

final _contextMenuKeys = {LogicalKeyboardKey.contextMenu, LogicalKeyboardKey.gameButtonX};

/// Extension methods for checking D-pad related keys.
extension DpadKeyExtension on LogicalKeyboardKey {
  /// Whether this key is a D-pad directional key.
  bool get isDpadDirection => _dpadDirectionKeys.contains(this);

  /// Whether this key is a select/activate key.
  bool get isSelectKey => _selectKeys.contains(this);

  /// Whether this key is a back/cancel key.
  bool get isBackKey => _backKeys.contains(this);

  /// Whether this key is a context menu key.
  bool get isContextMenuKey => _contextMenuKeys.contains(this);

  /// Whether this key is a navigation key (dpad, select, back, context menu, tab).
  /// Use this to distinguish navigation keys from typing/volume/media keys.
  bool get isNavigationKey =>
      isDpadDirection || isSelectKey || isBackKey || isContextMenuKey || this == LogicalKeyboardKey.tab;

  /// Whether this key moves focus left.
  bool get isLeftKey => this == LogicalKeyboardKey.arrowLeft;

  /// Whether this key moves focus right.
  bool get isRightKey => this == LogicalKeyboardKey.arrowRight;

  /// Whether this key moves focus up.
  bool get isUpKey => this == LogicalKeyboardKey.arrowUp;

  /// Whether this key moves focus down.
  bool get isDownKey => this == LogicalKeyboardKey.arrowDown;
}

/// Global helper to suppress the next SELECT key-up event.
class SelectKeyUpSuppressor {
  static bool _suppressSelectUntilKeyUp = false;

  static void suppressSelectUntilKeyUp() {
    _suppressSelectUntilKeyUp = true;
  }

  static bool consumeIfSuppressed(KeyEvent event) {
    if (!_suppressSelectUntilKeyUp) return false;
    if (event.logicalKey.isSelectKey) {
      if (event is KeyUpEvent) {
        _suppressSelectUntilKeyUp = false;
      }
      return true;
    }
    return false;
  }
}

/// Global helper to suppress the next BACK key-up event.
///
/// Use this when a modal (bottom sheet, dialog) closes to prevent
/// the BACK key-up from propagating to the underlying screen.
class BackKeyUpSuppressor {
  static bool _suppressBackUntilKeyUp = false;
  static bool _closedViaBackKey = false;

  /// Mark that a modal is being closed via back key press.
  /// Call this before Navigator.pop() in back key handlers.
  static void markClosedViaBackKey() {
    _closedViaBackKey = true;
  }

  /// Request suppression of back key-up events.
  /// Suppression is skipped if the modal was closed via back key
  /// (since the key-up already triggered the close).
  static void suppressBackUntilKeyUp() {
    if (_closedViaBackKey) {
      _closedViaBackKey = false;
      return;
    }
    _suppressBackUntilKeyUp = true;
  }

  /// Clear any pending suppression. Call when opening a new modal
  /// to ensure stale suppression from previous closes doesn't affect it.
  static void clearSuppression() {
    _suppressBackUntilKeyUp = false;
    _closedViaBackKey = false;
  }

  static bool consumeIfSuppressed(KeyEvent event) {
    if (!_suppressBackUntilKeyUp) return false;
    if (event.logicalKey.isBackKey) {
      if (event is KeyUpEvent) {
        _suppressBackUntilKeyUp = false;
      }
      return true;
    }
    return false;
  }
}

/// Tracks whether a back key is currently physically pressed.
///
/// Used by [BackKeySuppressorObserver] to detect when a route pop was
/// caused by a back key press (e.g. Flutter's built-in DismissAction,
/// DismissAction on KeyRepeat, or Android TV system back gesture) so it
/// can automatically suppress the stray KeyUp that follows.
class BackKeyPressTracker {
  static bool _isBackKeyDown = false;

  /// Whether a back key is currently held down.
  ///
  /// Also checks [HardwareKeyboard.instance.logicalKeysPressed] as a
  /// fallback in case our tracking drifted out of sync.
  static bool get isBackKeyDown {
    if (_isBackKeyDown) return true;
    return HardwareKeyboard.instance.logicalKeysPressed.any((key) => key.isBackKey);
  }

  static bool handleKeyEvent(KeyEvent event) {
    if (event.logicalKey.isBackKey) {
      // KeyDown and KeyRepeat both mean the key is physically held.
      _isBackKeyDown = event is! KeyUpEvent;
    }
    return false; // Never consume
  }
}
