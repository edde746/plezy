import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'platform_helper.dart';
import 'tv_detection_native.dart'
    if (dart.library.js_interop) 'tv_detection_web.dart' as tv_impl;

/// Service for detecting if the app is running on a TV platform.
///
/// Supports Android TV (via leanback feature detection) and webOS (via web detection).
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
    _isTV = await tv_impl.detectTV();
    if (_isTV) {
      AppPlatform.setAndroidTV(_isTV);
    }
    _initialized = true;
  }

  bool get isTV => _isTV;

  /// Synchronous access after initialization (returns false if not initialized)
  static bool isTVSync() {
    if (kIsWeb) return true; // Web build is always for TV (webOS)
    return _instance?._isTV ?? false;
  }
}

/// Utility class for platform detection
class PlatformDetector {
  /// Detects if running on a TV platform (Android TV or webOS)
  static bool isTV() {
    return TvDetectionService.isTVSync();
  }

  /// Detects if running on webOS (LG TV)
  static bool isWebOS() {
    return AppPlatform.isWebOS;
  }

  /// Detects if running on any web platform
  static bool isWeb() {
    return kIsWeb;
  }

  /// Detects if the app should use side navigation (Desktop or TV)
  static bool shouldUseSideNavigation(BuildContext context) {
    return isDesktop(context) || isTV();
  }

  /// Detects if running on a mobile platform (iOS or Android)
  /// Uses Theme for consistent platform detection across the app
  static bool isMobile(BuildContext context) {
    if (kIsWeb) return false; // Web/webOS is not mobile
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Detects if running on a desktop platform (Windows, macOS, or Linux)
  static bool isDesktop(BuildContext context) {
    if (kIsWeb) return false; // Web/webOS is not desktop
    return !isMobile(context);
  }

  /// Detects if the device is likely a tablet based on screen size
  static bool isTablet(BuildContext context) {
    if (kIsWeb) return false; // TV is not a tablet
    final data = MediaQuery.of(context);
    final size = data.size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = data.devicePixelRatio;
    final diagonalInches = diagonal / (devicePixelRatio * 160 / 2.54);
    return diagonalInches >= 7.0;
  }

  /// Detects if the device is a phone (mobile but not tablet)
  static bool isPhone(BuildContext context) {
    return isMobile(context) && !isTablet(context);
  }
}
