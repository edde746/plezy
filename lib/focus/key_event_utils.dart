import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dpad_navigator.dart';

// Back key handling lives in back_press.dart (BackPressGate for owners that
// consume Back before the route) and navigator_back_handler.dart (the
// per-navigator fallback that turns Back into Navigator.maybePop).

/// Consumes all select-key events (down, repeat, up) so they don't reach
/// platform-level handlers; fires [onActivate] on the initial KeyDown only.
KeyEventResult handleOneShotSelect(KeyEvent event, VoidCallback onActivate) {
  if (!event.logicalKey.isSelectKey) return KeyEventResult.ignored;
  if (event is KeyDownEvent) onActivate();
  return KeyEventResult.handled;
}

/// Whether the primary focus currently belongs to an active text editor.
///
/// Ancestor key handlers use this to stay off keys a focused field owns.
/// Flutter dispatches a key event from the focused node upwards, and the
/// editing shortcuts that turn Backspace into a deletion live in
/// [DefaultTextEditingShortcuts] at the very top of the app — *above* any
/// screen. An ancestor that claims Backspace as "back" therefore both steals
/// the navigation and stops the character from ever being deleted (#1741).
///
/// [EditableText] builds its [Focus] internally, so the focused node's context
/// resolves to the owning [EditableTextState].
bool isTextEditingFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.findAncestorStateOfType<EditableTextState>() != null;
}

/// Expands a UTF-16 [range] to whole extended grapheme clusters in [text].
///
/// Flutter selections use UTF-16 code-unit offsets. Custom editors must pass a
/// non-empty range containing the code units they intend to replace; the
/// returned range is normalized, clamped, and safe to use with
/// [String.replaceRange] without splitting a user-perceived character.
TextRange expandToGraphemeRange(String text, TextRange range) {
  if (text.isEmpty) return TextRange.empty;

  final first = range.start.clamp(0, text.length);
  final second = range.end.clamp(0, text.length);
  final start = first <= second ? first : second;
  final end = first <= second ? second : first;
  if (start == end) return TextRange.collapsed(start);

  final boundary = CharacterBoundary(text);
  return TextRange(
    start: boundary.getLeadingTextBoundaryAt(start) ?? 0,
    end: boundary.getTrailingTextBoundaryAt(end - 1) ?? text.length,
  );
}

/// Creates a [FocusOnKeyEventCallback] that dispatches d-pad / arrow keys to
/// the provided directional callbacks.
///
/// Each callback is optional. Directions without a callback are ignored
/// (passed through to the framework). Directions mapped to a callback
/// automatically return [KeyEventResult.handled].
///
/// When [trapHorizontalEdges] is true, LEFT/RIGHT with no callback return
/// [KeyEventResult.handled] (consumed) instead of being passed through. Use
/// this for a self-contained horizontal group (e.g. a button row) so D-pad
/// can't escape off the edge into an off-screen "black hole" (#1181); wire an
/// explicit [onLeft]/[onRight] only where edge-escape into another region is
/// intended. UP/DOWN are unaffected and always pass through when unmapped.
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
  bool trapHorizontalEdges = false,
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
    if (key.isLeftKey) {
      if (onLeft != null) {
        onLeft();
        return KeyEventResult.handled;
      }
      if (trapHorizontalEdges) return KeyEventResult.handled;
    }
    if (key.isRightKey) {
      if (onRight != null) {
        onRight();
        return KeyEventResult.handled;
      }
      if (trapHorizontalEdges) return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  };
}
