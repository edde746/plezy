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

/// Base class for suppressing key events after a key category triggers an
/// action (e.g. opening a sheet). While suppressed, every event of the matched
/// key category is consumed — including a [KeyDownEvent] when
/// [consumeKeyDowns] is set, because an armer running in the
/// [HardwareKeyboard] handler phase (the hotkey recorder) arms against the
/// very KeyDown that is then re-dispatched through the focus tree.
///
/// Suppression ends with the physical press: a global [HardwareKeyboard]
/// observer watches for the matching [KeyUpEvent] and clears the armed state
/// in a microtask — after that KeyUp's own synchronous focus dispatch, so
/// focus-phase consumers still swallow it — which guarantees a stale armed
/// state (a KeyUp delivered to a focus chain that never consulted us) can
/// never swallow the next press.
///
/// Armers that target an in-flight KeyUp ([consumeKeyDowns] unset) treat a
/// matching [KeyDownEvent] as proof the suppressed press already ended without
/// its KeyUp reaching us (e.g. a closing TV IME session ate it): the armed
/// state is cleared and the fresh press passes through unconsumed.
class _KeyUpSuppressor {
  final bool Function(LogicalKeyboardKey) _keyMatcher;

  /// Whether a matching [KeyDownEvent] is consumed while armed. See the class
  /// documentation for why armers targeting an in-flight KeyUp must unset it.
  final bool consumeKeyDowns;

  _KeyUpSuppressor(this._keyMatcher, {this.consumeKeyDowns = true});

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
  /// category and suppression is active. Clears suppression on [KeyUpEvent],
  /// and on a stale [KeyDownEvent] when [consumeKeyDowns] is unset.
  bool consumeIfSuppressed(KeyEvent event) {
    if (!_suppressed) return false;
    if (!_keyMatcher(event.logicalKey)) return false;
    if (event is KeyUpEvent) _suppressed = false;
    if (event is KeyDownEvent && !consumeKeyDowns) {
      // The in-flight KeyUp never arrived; this is a fresh press, not the
      // suppressed one. Clear and let it through.
      _suppressed = false;
      return false;
    }
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

/// Global helper to suppress the next BACK key-up event.
///
/// Armed when a modal (dialog, sheet) closes while a back key is still held —
/// e.g. by [BackKeySuppressorObserver] when a route pops mid-press — or when a
/// down-only back handler moves focus before the matching KeyUp is dispatched.
/// A matching KeyDown while armed clears the arming instead of consuming: it
/// can only mean the suppressed press's KeyUp was swallowed off-app, so the
/// fresh press must act normally.
class BackKeyUpSuppressor {
  static final _instance = _KeyUpSuppressor((k) => k.isBackKey, consumeKeyDowns: false);

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
