import 'package:flutter/material.dart';
import '../theme/mono_tokens.dart';

class FocusTheme {
  FocusTheme._();

  static const double focusScale = 1.02;
  static const double fullCardFocusScale = 1.03;
  static const double focusBorderWidth = 2.5;
  static const double defaultBorderRadius = 8.0;
  static const double focusGlowInnerBlurRadius = 18;
  static const double focusGlowOuterBlurRadius = 34;
  static const double focusGlowSpreadRadius = 1.5;

  static Color getFocusBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Duration getAnimationDuration(BuildContext context) {
    return Theme.of(context).extension<MonoTokens>()?.fast ?? const Duration(milliseconds: 150);
  }

  static BoxDecoration focusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    double borderStrokeAlign = BorderSide.strokeAlignInside,
    Color? color,
  }) {
    final focusColor = color ?? getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.transparent,
        width: focusBorderWidth,
        strokeAlign: borderStrokeAlign,
      ),
    );
  }

  static BoxDecoration focusGlowDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    Color? color,
  }) {
    final focusColor = color ?? getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isFocused ? focusColor.withValues(alpha: 0.34) : Colors.transparent,
          blurRadius: focusGlowInnerBlurRadius,
          spreadRadius: focusGlowSpreadRadius,
        ),
        BoxShadow(
          color: isFocused ? focusColor.withValues(alpha: 0.20) : Colors.transparent,
          blurRadius: focusGlowOuterBlurRadius,
        ),
      ],
    );
  }

  /// Build focus decoration with background color instead of border.
  /// Useful for video controls where it should match the native hover style.
  static BoxDecoration focusBackgroundDecoration({required bool isFocused, double borderRadius = defaultBorderRadius}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
    );
  }
}
