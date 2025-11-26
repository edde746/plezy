import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A mixin that provides keyboard long-press detection for focusable widgets.
///
/// This allows keyboard/gamepad users to access context menus by holding
/// the activation key (Enter, Space, Select, or GameButtonA) for 1 second.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with KeyboardLongPressMixin {
///   @override
///   void onKeyboardTap() {
///     // Handle short press (normal tap)
///   }
///
///   @override
///   void onKeyboardLongPress() {
///     // Handle long press (show context menu)
///   }
///
///   KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
///     final result = handleKeyboardLongPress(event);
///     if (result == KeyEventResult.handled) return result;
///     // Handle other keys...
///     return KeyEventResult.ignored;
///   }
/// }
/// ```
mixin KeyboardLongPressMixin<T extends StatefulWidget> on State<T> {
  Timer? _longPressTimer;
  LogicalKeyboardKey? _pressedKey;
  bool _longPressTriggered = false;

  static const _longPressDuration = Duration(seconds: 1);

  /// Override to handle tap action (short press)
  void onKeyboardTap();

  /// Override to handle long press action (e.g., show context menu)
  void onKeyboardLongPress();

  /// Check if the given key is an activation key
  bool _isActivationKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  /// Call this from your onKeyEvent handler to enable long-press detection.
  /// Returns [KeyEventResult.handled] if the event was an activation key,
  /// [KeyEventResult.ignored] otherwise.
  KeyEventResult handleKeyboardLongPress(KeyEvent event) {
    if (!_isActivationKey(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      // Only start timer on initial press (not key repeat)
      if (_pressedKey == null) {
        _pressedKey = event.logicalKey;
        _longPressTriggered = false;
        _longPressTimer = Timer(_longPressDuration, () {
          _longPressTriggered = true;
          onKeyboardLongPress();
        });
      }
      return KeyEventResult.handled;
    }

    // Handle key repeat events (suppress system sound on macOS)
    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent && event.logicalKey == _pressedKey) {
      _longPressTimer?.cancel();
      _longPressTimer = null;
      _pressedKey = null;

      // Only trigger tap if long press wasn't already triggered
      if (!_longPressTriggered) {
        onKeyboardTap();
      }
      _longPressTriggered = false;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Cancel any pending long-press timer. Call this if focus is lost
  /// or the widget is being disposed while a key is held.
  void cancelKeyboardLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _pressedKey = null;
    _longPressTriggered = false;
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }
}
