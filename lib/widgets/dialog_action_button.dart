import 'package:flutter/material.dart';

import '../focus/focusable_button.dart';

/// A dialog action button that wraps [FocusableButton] around a [TextButton]
/// (or [FilledButton] when [isPrimary] is true).
///
/// Use in an [AlertDialog]'s `actions:` list — replaces the 4-line
/// `FocusableButton(onPressed: ..., child: TextButton(onPressed: ..., ...))`
/// boilerplate with a single call.
class DialogActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isPrimary;
  final bool? useBackgroundFocus;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final ButtonStyle? style;
  final Widget? icon;
  const DialogActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.focusNode,
    this.autofocus = false,
    this.isPrimary = false,
    this.useBackgroundFocus,
    this.onBack,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = switch ((isPrimary, icon)) {
      (true, final Widget icon) => FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon,
        label: Text(label),
      ),
      (true, null) => FilledButton(onPressed: onPressed, style: style, child: Text(label)),
      (false, final Widget icon) => TextButton.icon(onPressed: onPressed, style: style, icon: icon, label: Text(label)),
      (false, null) => TextButton(onPressed: onPressed, style: style, child: Text(label)),
    };

    return FocusableButton(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      useBackgroundFocus: useBackgroundFocus ?? isPrimary,
      onBack: onBack,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      onNavigateLeft: onNavigateLeft,
      onNavigateRight: onNavigateRight,
      child: button,
    );
  }
}
