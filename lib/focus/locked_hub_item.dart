import 'package:flutter/material.dart';

import 'focus_theme.dart';
import 'input_mode_tracker.dart';

/// A hub item that renders focus visuals based on passed-in state.
/// Does NOT use FocusNode - relies on parent-managed visual focus.
class LockedHubItem extends StatelessWidget {
  /// Whether this item is visually focused
  final bool isFocused;

  /// The child widget to wrap
  final Widget child;

  /// Border radius for the focus indicator
  final double borderRadius;

  const LockedHubItem({
    super.key,
    required this.isFocused,
    required this.child,
    this.borderRadius = FocusTheme.defaultBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final duration = FocusTheme.getAnimationDuration(context);
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = isFocused && InputModeTracker.isKeyboardMode(context);

    return AnimatedScale(
      scale: showFocus ? FocusTheme.focusScale : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: FocusTheme.focusDecoration(
          context,
          isFocused: showFocus,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}
