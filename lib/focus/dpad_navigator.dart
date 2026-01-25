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

  static void suppressBackUntilKeyUp() {
    _suppressBackUntilKeyUp = true;
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
