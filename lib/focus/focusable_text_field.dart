import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dpad_navigator.dart';

/// A [TextField] wrapper that exposes D-pad navigation callbacks with
/// caret-aware edge escapes — so LEFT at the start of the field and RIGHT
/// at the end escape to neighbouring focus targets instead of bouncing
/// against the caret boundary, while UP/DOWN always escape.
///
/// Collapsed selection only: if text is selected, LEFT/RIGHT fall through
/// to the TextField's default caret movement.
class FocusableTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;

  const FocusableTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onNavigateUp,
    this.onNavigateDown,
  });

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isUpKey && onNavigateUp != null) {
      onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (key.isDownKey && onNavigateDown != null) {
      onNavigateDown!();
      return KeyEventResult.handled;
    }

    final sel = controller.selection;
    if (sel.isCollapsed) {
      if (key.isLeftKey && sel.baseOffset == 0 && onNavigateLeft != null) {
        onNavigateLeft!();
        return KeyEventResult.handled;
      }
      if (key.isRightKey && sel.baseOffset == controller.text.length && onNavigateRight != null) {
        onNavigateRight!();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKey,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: decoration,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
      ),
    );
  }
}
