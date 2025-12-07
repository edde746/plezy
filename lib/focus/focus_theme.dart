import 'package:flutter/material.dart';
import '../theme/mono_tokens.dart';

/// Focus styling constants for D-pad navigation.
class FocusTheme {
  FocusTheme._();

  /// Scale factor when an item is focused.
  static const double focusScale = 1.02;

  /// Border width for the focus indicator.
  static const double focusBorderWidth = 2.5;

  /// Default border radius (matches MonoTokens.radiusSm).
  static const double defaultBorderRadius = 8.0;

  /// Get the focus border color from the theme.
  static Color getFocusBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Get the animation duration from MonoTokens.
  static Duration getAnimationDuration(BuildContext context) {
    return Theme.of(context).extension<MonoTokens>()?.fast ??
        const Duration(milliseconds: 150);
  }

  /// Build the focus border decoration.
  static BoxDecoration focusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
  }) {
    final focusColor = getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.transparent,
        width: focusBorderWidth,
      ),
    );
  }
}
