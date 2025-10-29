import 'package:flutter/material.dart';

/// Utility class for platform detection
class PlatformDetector {
  /// Detects if running on a mobile platform (iOS or Android)
  /// Uses Theme for consistent platform detection across the app
  static bool isMobile(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Detects if running on a desktop platform (Windows, macOS, or Linux)
  static bool isDesktop(BuildContext context) {
    return !isMobile(context);
  }
}
