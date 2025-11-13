import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io' show Platform;

/// Utility class for platform detection
class PlatformDetector {
  // Cache TV detection result since it won't change during app lifecycle
  static bool? _isTVCached;
  static const _platformChannel = MethodChannel('com.edde746.plezy/platform');

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
  /// Uses Android's UiModeManager to check for UI_MODE_TYPE_TELEVISION
  /// This is the proper, reliable way to detect TV devices on Android

  /// Initialize TV detection asynchronously
  /// Should be called early in app initialization
  static Future<void> initializeTVDetection() async {
    if (!Platform.isAndroid || _isTVCached != null) {
      return;
    }

    try {
      final bool result = await _platformChannel.invokeMethod('isAndroidTV');
      _isTVCached = result;
    } catch (e) {
      // Fallback: If platform channel fails, use screen size heuristics
      // This can happen on non-Android platforms or if method isn't implemented
      _isTVCached = false;
    }
  }

  /// Synchronous TV check that requires prior initialization
  /// Returns cached TV detection result
  /// If not initialized, returns false (safe default)
  static bool isTVSync() {
    return _isTVCached ?? false;
  }
}
