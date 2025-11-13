import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io' show Platform;

/// Utility class for platform detection
class PlatformDetector {
  // Cache TV detection result since it won't change during app lifecycle
  static bool? _isTVCached;

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

  /// Detects if the device is likely a tablet based on screen size
  /// Uses diagonal screen size to determine if device is a tablet
  static bool isTablet(BuildContext context) {
    final data = MediaQuery.of(context);
    final size = data.size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = data.devicePixelRatio;

    // Convert diagonal from logical pixels to inches (assuming 160 DPI as baseline)
    final diagonalInches = diagonal / (devicePixelRatio * 160 / 2.54);

    // Consider devices with diagonal >= 7 inches as tablets
    return diagonalInches >= 7.0;
  }

  /// Detects if the device is a phone (mobile but not tablet)
  static bool isPhone(BuildContext context) {
    return isMobile(context) && !isTablet(context);
  }

  /// Detects if running on Android TV
  /// Checks for large screen and landscape orientation, typical of TV devices
  static bool isTV(BuildContext context) {
    // Return cached result if available
    if (_isTVCached != null) return _isTVCached!;

    // Only check on Android platform
    if (!Platform.isAndroid) {
      _isTVCached = false;
      return false;
    }

    final data = MediaQuery.of(context);
    final size = data.size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = data.devicePixelRatio;

    // Convert diagonal from logical pixels to inches
    final diagonalInches = diagonal / (devicePixelRatio * 160 / 2.54);

    // Android TV devices typically:
    // - Have screens >= 24 inches (minimum TV size)
    // - Default to landscape orientation
    // - Have lower pixel density (typically mdpi to xhdpi)
    final isLargeScreen = diagonalInches >= 24.0;
    final isLandscape = size.width > size.height;
    final isLowDensity = devicePixelRatio <= 2.0;

    _isTVCached = isLargeScreen && isLandscape && isLowDensity;
    return _isTVCached!;
  }
}
