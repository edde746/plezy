import 'package:flutter/material.dart';

import 'focus_theme.dart';
import 'focusable_wrapper.dart';
import 'input_mode_tracker.dart';

/// A focusable button wrapper for D-pad navigation on TV.
///
/// Wraps any button widget with [FocusableWrapper] and adds a white overlay
/// + contrasting border when focused. Tracks focus state internally so callers
/// don't need manual state management.
///
/// ```dart
/// FocusableButton(
///   autofocus: true,
///   onPressed: _doSomething,
///   child: FilledButton.icon(
///     onPressed: _doSomething,
///     icon: Icon(Symbols.add_rounded),
///     label: Text('Create'),
///   ),
/// )
/// ```
class FocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Navigation callbacks for explicit focus control (e.g. horizontal button rows).
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onBack;

  /// Whether to scroll the widget into view when focused.
  final bool autoScroll;

  /// Whether to use background color instead of border for focus indicator.
  final bool useBackgroundFocus;

  const FocusableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
    this.autoScroll = true,
    this.useBackgroundFocus = false,
  });

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isKeyboard = InputModeTracker.isKeyboardMode(context);
    final showFocus = _isFocused && isKeyboard;
    final duration = FocusTheme.getAnimationDuration(context);
    // In dpad mode: focused = full opacity, unfocused = dimmed
    final opacity = isKeyboard && !_isFocused ? 0.6 : 1.0;

    return FocusableWrapper(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      disableScale: true,
      borderRadius: 100,
      useBackgroundFocus: widget.useBackgroundFocus,
      descendantsAreFocusable: false,
      onFocusChange: (f) => setState(() => _isFocused = f),
      autoScroll: widget.autoScroll,
      onSelect: widget.onPressed,
      onNavigateUp: widget.onNavigateUp,
      onNavigateDown: widget.onNavigateDown,
      onNavigateLeft: widget.onNavigateLeft,
      onNavigateRight: widget.onNavigateRight,
      onBack: widget.onBack,
      child: AnimatedOpacity(
        opacity: showFocus ? 1.0 : opacity,
        duration: duration,
        child: widget.child,
      ),
    );
  }
}
