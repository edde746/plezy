import 'package:flutter/material.dart';

/// TV-specific UI helpers for webOS.
///
/// Provides constants and utilities for 10-foot UI design on LG TVs.
class TVUIConstants {
  TVUIConstants._();

  /// Minimum recommended font size for TV (readable at ~3 meters).
  static const double minFontSize = 18.0;

  /// Recommended body text size for TV.
  static const double bodyFontSize = 22.0;

  /// Recommended title text size for TV.
  static const double titleFontSize = 28.0;

  /// Recommended heading text size for TV.
  static const double headingFontSize = 36.0;

  /// TV safe area margin (5% of screen for overscan).
  static const double safeAreaMargin = 48.0; // ~5% of 1920px

  /// Minimum touch/focus target size for TV remote interaction.
  static const double minInteractiveSize = 48.0;

  /// Recommended padding for focused items.
  static const double focusPadding = 8.0;

  /// Recommended border width for focus indicators.
  static const double focusBorderWidth = 3.0;

  /// Standard TV resolution.
  static const Size tvResolution = Size(1920, 1080);
}

/// Extension to add TV safe area padding to widgets.
extension TVSafeArea on Widget {
  Widget withTVSafeArea() {
    return Padding(
      padding: const EdgeInsets.all(TVUIConstants.safeAreaMargin),
      child: this,
    );
  }
}
