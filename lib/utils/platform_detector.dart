import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// Service for detecting if the app is running on Android TV
class TvDetectionService {
  static TvDetectionService? _instance;
  bool _isTV = false;
  bool _initialized = false;

  TvDetectionService._();

  /// Get the singleton instance, initializing if needed
  static Future<TvDetectionService> getInstance() async {
    if (_instance == null) {
      _instance = TvDetectionService._();
      await _instance!._detect();
    }
    return _instance!;
  }

  Future<void> _detect() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Check for android.software.leanback feature (standard Android TV detection)
      _isTV = androidInfo.systemFeatures.contains('android.software.leanback');
    }
    _initialized = true;
  }

  bool get isTV => _isTV;

  /// Synchronous access after initialization (returns false if not initialized)
  static bool isTVSync() => _instance?._isTV ?? false;
}

/// Utility class for platform detection
class PlatformDetector {
  /// Detects if running on Android TV (requires TvDetectionService to be initialized)
  static bool isTV() {
    return TvDetectionService.isTVSync();
  }

  /// Detects if the app should use side navigation (Desktop or TV)
  static bool shouldUseSideNavigation(BuildContext context) {
    return isDesktop(context) || isTV();
  }

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
}
