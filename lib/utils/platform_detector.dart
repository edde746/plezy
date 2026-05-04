import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// Service for detecting if the app is running on Android TV or Apple TV.
class TvDetectionService {
  static TvDetectionService? _instance;
  bool _detected = false;
  bool _forceTv = false;
  bool _isTV = false;
  bool _isAppleTV = false;
  bool _initialized = false;

  TvDetectionService._();

  /// Get the singleton instance, initializing if needed.
  /// Pass [forceTv] to combine a user override with the system-feature check.
  static Future<TvDetectionService> getInstance({bool forceTv = false}) async {
    if (_instance == null) {
      _instance = TvDetectionService._();
      await _instance!._detect(forceTv);
    }
    return _instance!;
  }

  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  Future<void> _detect(bool forceTv) async {
    if (_initialized) return;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _detected = androidInfo.systemFeatures.contains('android.software.leanback');
    } else if (Platform.isIOS) {
      if (_tvosBuild) {
        _isAppleTV = true;
        _detected = true;
      } else {
        final iosInfo = await deviceInfo.iosInfo;
        final sysName = iosInfo.systemName.toLowerCase();
        _isAppleTV =
            sysName == 'tvos' ||
            sysName.contains('appletv') ||
            iosInfo.model.toLowerCase().contains('appletv') ||
            iosInfo.utsname.machine.toLowerCase().contains('appletv');
        _detected = _isAppleTV;
      }
    }
    _forceTv = forceTv;
    _isTV = _detected || _forceTv;
    _initialized = true;
  }

  /// True when running on Apple TV (tvOS). False for all other platforms
  /// including force-TV on non-tvOS devices.
  bool get isAppleTV => _isAppleTV;

  bool get isTV => _isTV;

  /// Update the user force-TV override and recompute the effective flag.
  void setForceTv(bool value) {
    _forceTv = value;
    _isTV = _detected || _forceTv;
  }

  /// Synchronous access after initialization (returns false if not initialized)
  static bool isTVSync() => _instance?._isTV ?? false;

  /// Synchronous Apple TV check (returns false if not initialized or not tvOS).
  static bool isAppleTVSync() => _instance?._isAppleTV ?? false;

  /// Convenience setter that forwards to the singleton if available.
  static void setForceTVSync(bool value) => _instance?.setForceTv(value);
}

class PlatformDetector {
  static bool isTV() {
    return TvDetectionService.isTVSync();
  }

  static bool isAppleTV() {
    return TvDetectionService.isAppleTVSync();
  }

  /// Detects if the app should use side navigation (Desktop or TV)
  static bool shouldUseSideNavigation(BuildContext context) {
    return isDesktop(context) || isTV();
  }

  /// Whether this device should act as a companion remote host (receiver).
  /// Desktop platforms and Android TV are hosts; phones/tablets are controllers.
  static bool shouldActAsRemoteHost(BuildContext context) {
    return isDesktop(context) || isTV();
  }

  /// Detects if running on a mobile platform (iOS or Android).
  /// Excludes TV platforms (Android TV / Apple TV) even though the underlying
  /// OS is iOS or Android.
  /// Uses Theme for consistent platform detection across the app.
  static bool isMobile(BuildContext context) {
    if (isTV()) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  static bool isHandheld(BuildContext context) {
    return isMobile(context) && !isTV();
  }

  /// Detects if running on a desktop platform (Windows, macOS, or Linux)
  static bool isDesktop(BuildContext context) {
    return !isMobile(context);
  }

  /// True on the desktop OS (Windows / macOS / Linux), without needing a
  /// BuildContext. Use for OS-level capability checks (window state, native
  /// keyboard, etc.); use [isDesktop] for layout decisions.
  static bool isDesktopOS() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Detects if the device is likely a tablet based on screen size
  /// Uses diagonal screen size to determine if device is a tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    // Convert diagonal from logical pixels to inches (assuming 160 DPI as baseline)
    final diagonalInches = diagonal / (devicePixelRatio * 160 / 2.54);

    return diagonalInches >= 7.0;
  }

  static bool isPhone(BuildContext context) {
    return isHandheld(context) && !isTablet(context);
  }
}
