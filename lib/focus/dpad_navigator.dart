import 'dart:async';
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

  /// Whether this key is a shell / remote control key rather than a text
  /// character — D-pad direction, select, back, context menu, or Tab.
  ///
  /// Use it to decide "is this a printable character?" and "must this route
  /// consume the key so it cannot leak to the route below?". It is NOT evidence
  /// that the viewer wants to navigate by focus — `eventRequestsFocusNavigation`
  /// in focus_navigation_intent.dart answers that, and conflating the two is what
  /// made a plain Enter switch the whole app into keyboard mode.
  bool get isReservedControlKey =>
      isDpadDirection || isSelectKey || isBackKey || isContextMenuKey || this == LogicalKeyboardKey.tab;

  bool get isLeftKey => this == LogicalKeyboardKey.arrowLeft;
  bool get isRightKey => this == LogicalKeyboardKey.arrowRight;
  bool get isUpKey => this == LogicalKeyboardKey.arrowUp;
  bool get isDownKey => this == LogicalKeyboardKey.arrowDown;
}

/// Suppresses SELECT key events after a select press already acted (e.g. a
/// long press opened a sheet). While suppressed, every select event is
/// consumed — including a [KeyDownEvent], because an armer running in the
/// [HardwareKeyboard] handler phase (the hotkey recorder) arms against the
/// very KeyDown that is then re-dispatched through the focus tree.
///
/// Suppression ends with the physical press: a global [HardwareKeyboard]
/// observer watches for the matching [KeyUpEvent] and clears the armed state
/// in a microtask — after that KeyUp's own synchronous focus dispatch, so
/// focus-phase consumers still swallow it — which guarantees a stale armed
/// state (a KeyUp delivered to a focus chain that never consulted us) can
/// never swallow the next press.
class _KeyUpSuppressor {
  final bool Function(LogicalKeyboardKey) _keyMatcher;

  _KeyUpSuppressor(this._keyMatcher);

  bool _suppressed = false;

  void suppress() {
    // Re-registered on every arm because flutter_test's HardwareKeyboard
    // clearState() drops handlers between tests; remove-then-add keeps exactly
    // one live registration. The observer only reads state and returns false,
    // so it can never consume an event, and it is intentionally never removed
    // outside re-registration.
    HardwareKeyboard.instance
      ..removeHandler(_observeKeyUp)
      ..addHandler(_observeKeyUp);
    _suppressed = true;
  }

  bool _observeKeyUp(KeyEvent event) {
    if (_suppressed && event is KeyUpEvent && _keyMatcher(event.logicalKey)) {
      // The hardware phase runs before the same event's focus dispatch;
      // clearing in a microtask keeps the armed state visible to the KeyUp's
      // focus-phase consumers while ending it before any later event.
      scheduleMicrotask(clearSuppression);
    }
    return false;
  }

  void clearSuppression() => _suppressed = false;

  /// Returns `true` (consumed) when the event belongs to the matched key
  /// category and suppression is active. Clears suppression on [KeyUpEvent].
  bool consumeIfSuppressed(KeyEvent event) {
    if (!_suppressed) return false;
    if (!_keyMatcher(event.logicalKey)) return false;
    if (event is KeyUpEvent) _suppressed = false;
    return true;
  }
}

/// Global helper to suppress the next SELECT key-up event.
class SelectKeyUpSuppressor {
  static final _instance = _KeyUpSuppressor((k) => k.isSelectKey);

  static void suppressSelectUntilKeyUp() => _instance.suppress();
  static void clearSuppression() => _instance.clearSuppression();
  static bool consumeIfSuppressed(KeyEvent event) => _instance.consumeIfSuppressed(event);
}
