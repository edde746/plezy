import 'dart:ui' as ui;

import 'package:flutter/services.dart';

extension KeyEventActionable on KeyEvent {
  bool get isActionable => this is KeyDownEvent || this is KeyRepeatEvent;
  bool get isPhysicalKeyboardEvent => deviceType == ui.KeyEventDeviceType.keyboard;
  // Only true keyboard submit keys belong here. LogicalKeyboardKey.select is
  // a TV-remote / dpad-center key (Android DPAD_CENTER, tvOS UIPressTypeSelect)
  // — USB keyboards never emit it. The custom Flutter tvOS engine reports its
  // synthesized Siri Remote presses with deviceType=keyboard, so classifying
  // select-with-keyboard-deviceType as a "keyboard enter" would route center
  // dpad through TextField submit and skip the TV virtual keyboard.
  bool get isPhysicalKeyboardEnter =>
      deviceType == ui.KeyEventDeviceType.keyboard &&
      (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter);

  bool get isTvSelectEvent {
    // Dpad-center / gamepad-A are TV-remote-only — always treat as TV select,
    // regardless of the deviceType claim from the engine.
    if (logicalKey == LogicalKeyboardKey.select || logicalKey == LogicalKeyboardKey.gameButtonA) return true;
    if (isPhysicalKeyboardEvent) return false;
    return logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter;
  }
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
/// Armed when a modal (dialog, sheet) closes while a back key is still held —
/// e.g. by [BackKeySuppressorObserver] when a route pops mid-press — so the
/// in-flight key-up doesn't propagate to the underlying screen's back handler.
class BackKeyUpSuppressor {
  static final _instance = _KeyUpSuppressor((k) => k.isBackKey);

  static void suppressBackUntilKeyUp() => _instance.suppress();

  /// Clear any pending suppression. Call when opening a new modal
  /// to ensure stale suppression from previous closes doesn't affect it.
  static void clearSuppression() => _instance.clearSuppression();

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
