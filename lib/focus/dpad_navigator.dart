import 'package:flutter/services.dart';

extension KeyEventActionable on KeyEvent {
  bool get isActionable => this is KeyDownEvent || this is KeyRepeatEvent;
}

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

extension DpadKeyExtension on LogicalKeyboardKey {
  bool get isDpadDirection => _dpadDirectionKeys.contains(this);
  bool get isSelectKey => _selectKeys.contains(this);
  bool get isBackKey => _backKeys.contains(this);
  bool get isContextMenuKey => _contextMenuKeys.contains(this);

  bool get isNavigationKey =>
      isDpadDirection || isSelectKey || isBackKey || isContextMenuKey || this == LogicalKeyboardKey.tab;

  bool get isLeftKey => this == LogicalKeyboardKey.arrowLeft;
  bool get isRightKey => this == LogicalKeyboardKey.arrowRight;
  bool get isUpKey => this == LogicalKeyboardKey.arrowUp;
  bool get isDownKey => this == LogicalKeyboardKey.arrowDown;
}

/// Base class for suppressing key-up events after a key category triggers an
/// action (e.g. opening a sheet). While suppressed, all events for the matched
/// key category are consumed; suppression auto-clears on [KeyUpEvent].
class _KeyUpSuppressor {
  final bool Function(LogicalKeyboardKey) _keyMatcher;

  _KeyUpSuppressor(this._keyMatcher);

  bool _suppressed = false;

  void suppress() => _suppressed = true;

  void clearSuppression() => _suppressed = false;

  /// Returns `true` (consumed) when the event belongs to the matched key
  /// category and suppression is active. Clears suppression on [KeyUpEvent].
  bool consumeIfSuppressed(KeyEvent event) {
    if (!_suppressed) return false;
    if (_keyMatcher(event.logicalKey)) {
      if (event is KeyUpEvent) _suppressed = false;
      return true;
    }
    return false;
  }
}

/// Global helper to suppress the next SELECT key-up event.
class SelectKeyUpSuppressor {
  static final _instance = _KeyUpSuppressor((k) => k.isSelectKey);

  static void suppressSelectUntilKeyUp() => _instance.suppress();
  static void clearSuppression() => _instance.clearSuppression();
  static bool consumeIfSuppressed(KeyEvent event) => _instance.consumeIfSuppressed(event);
}

/// Global helper to suppress the next BACK key-up event.
///
/// Use this when a modal (bottom sheet, dialog) closes to prevent
/// the BACK key-up from propagating to the underlying screen.
class BackKeyUpSuppressor {
  static final _instance = _KeyUpSuppressor((k) => k.isBackKey);
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
    _instance.suppress();
  }

  /// Clear any pending suppression. Call when opening a new modal
  /// to ensure stale suppression from previous closes doesn't affect it.
  static void clearSuppression() {
    _instance.clearSuppression();
    _closedViaBackKey = false;
  }

  static bool consumeIfSuppressed(KeyEvent event) => _instance.consumeIfSuppressed(event);
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
