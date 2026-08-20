import 'package:flutter/material.dart';
import '../services/device_performance.dart';
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
    // Reduced tier: snap focus transitions (scale/border/glow) instead of
    // animating — each animation frame re-rasterizes the focused card.
    if (DevicePerformance.isReduced) return Duration.zero;
    return Theme.of(context).extension<MonoTokens>()?.fast ?? const Duration(milliseconds: 150);
  }

  /// [radii] overrides [borderRadius] when per-corner radii are needed
  /// (M3E grouped cards: large outer / small inner corners).
  static BoxDecoration focusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
    double borderStrokeAlign = BorderSide.strokeAlignInside,
    Color? color,
  }) {
    final focusColor = color ?? getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.transparent,
        width: focusBorderWidth,
        strokeAlign: borderStrokeAlign,
      ),
    );
  }

  /// The focus glow as a list of [BoxShadow]s.
  ///
  /// Rendered by [FocusGlowOverlay] in the root overlay so the glow paints
  /// above sibling cards on all four sides (an in-tree background shadow is
  /// occluded by later-painted neighbours, which produced the one-sided halo).
  static List<BoxShadow> focusGlowShadows(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.34),
        blurRadius: focusGlowInnerBlurRadius,
        spreadRadius: focusGlowSpreadRadius,
      ),
      BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: focusGlowOuterBlurRadius),
    ];
  }

  /// How far the focus glow visibly reaches beyond the card edge. Used to size
  /// the overlay paint area so the blur is not clipped.
  static double get focusGlowExtent => focusGlowOuterBlurRadius * 2 + focusGlowSpreadRadius;

  /// Build focus decoration with background color instead of border.
  /// Useful for video controls where it should match the native hover style.
  /// [radii] overrides [borderRadius] when per-corner radii are needed.
  static BoxDecoration focusBackgroundDecoration({
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
    );
  }

  /// Focus background fill derived from the theme's text color, so it stays
  /// visible on BOTH light and dark surfaces — the white-based
  /// [focusBackgroundDecoration] disappears on light ones. This is the mono
  /// convention used by [TrackRow], the navigation rail, and the music player
  /// surfaces. Prefer this for any new mono-themed surface.
  static BoxDecoration textFillFocusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? tokens(context).text.withValues(alpha: 0.12) : Colors.transparent,
    );
  }
}
