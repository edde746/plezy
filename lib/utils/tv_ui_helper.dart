import 'package:flutter/material.dart';
import 'platform_detector.dart';

/// Utility class for TV-specific UI adjustments
/// Provides scaled values for 10-foot UI (viewing from distance)
class TVUIHelper {
  /// Get font size adjusted for TV viewing distance
  /// TV: Increases base size by 30% for better readability from distance
  /// Mobile/Desktop: Returns base size unchanged
  static double getFontSize(BuildContext context, double baseSize) {
    if (PlatformDetector.isTVSync()) {
      return baseSize * 1.3;
    }
    return baseSize;
  }

  /// Get spacing adjusted for TV
  /// TV: Increases spacing by 50% for better touch target separation
  /// Mobile/Desktop: Returns base spacing unchanged
  static double getSpacing(BuildContext context, double baseSpacing) {
    if (PlatformDetector.isTVSync()) {
      return baseSpacing * 1.5;
    }
    return baseSpacing;
  }

  /// Get minimum touch target size for TV
  /// TV: Returns 80dp (recommended for D-pad navigation)
  /// Mobile: Returns 48dp (Material Design standard)
  static double getMinTouchTarget(BuildContext context) {
    if (PlatformDetector.isTVSync()) {
      return 80.0;
    }
    return 48.0;
  }

  /// Get card padding adjusted for TV
  static EdgeInsets getCardPadding(BuildContext context) {
    if (PlatformDetector.isTVSync()) {
      return const EdgeInsets.all(12.0);
    }
    return const EdgeInsets.all(8.0);
  }

  /// Get text style with TV-adjusted font size
  static TextStyle getTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    if (PlatformDetector.isTVSync()) {
      final fontSize = baseStyle.fontSize ?? 14.0;
      return baseStyle.copyWith(fontSize: fontSize * 1.3);
    }
    return baseStyle;
  }
}
