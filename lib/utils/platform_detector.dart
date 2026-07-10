import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _androidFeatureTelevision = 'android.hardware.type.television';
const _androidFeatureLeanback = 'android.software.leanback';
const _androidFeatureFireTv = 'amazon.hardware.fire_tv';
const _androidFeatureTouchscreen = 'android.hardware.touchscreen';

class AndroidTvFeatureDetection {
  final bool isTv;
  final List<String> reasons;

  const AndroidTvFeatureDetection({required this.isTv, required this.reasons});
}

AndroidTvFeatureDetection detectAndroidTvFromSystemFeatures(Iterable<String> features) {
  final featureSet = features.toSet();
  final reasons = <String>[];
  if (featureSet.contains(_androidFeatureTelevision)) reasons.add('television_feature');
  if (featureSet.contains(_androidFeatureLeanback)) reasons.add('leanback');
  if (featureSet.contains(_androidFeatureFireTv)) reasons.add('fire_tv');
  if (featureSet.isNotEmpty && !featureSet.contains(_androidFeatureTouchscreen)) reasons.add('no_touchscreen');

  return AndroidTvFeatureDetection(isTv: reasons.isNotEmpty, reasons: reasons);
}

/// Service for detecting if the app is running on Android TV or Apple TV.
class TvDetectionService {
  static TvDetectionService? _instance;
  static bool? _debugAppleTVOverride;
  bool _detected = false;
  bool _forceTv = false;
  bool _isTV = false;
  bool _isAppleTV = false;
  bool _initialized = false;
  List<String> _detectionReasons = const [];

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
  static const MethodChannel _deviceChannel = MethodChannel('com.plezy/device');

  Future<void> _detect(bool forceTv) async {
    if (_initialized) return;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final nativeDetection = await _getNativeAndroidTvDetection();
      final detection =
          nativeDetection ?? detectAndroidTvFromSystemFeatures((await deviceInfo.androidInfo).systemFeatures);
      _detected = detection.isTv;
      _detectionReasons = detection.reasons;
    } else if (Platform.isIOS) {
      if (_tvosBuild) {
        _isAppleTV = true;
        _detected = true;
        _detectionReasons = const ['tvos_build'];
      } else {
        final iosInfo = await deviceInfo.iosInfo;
        final sysName = iosInfo.systemName.toLowerCase();
        _isAppleTV =
            sysName == 'tvos' ||
            sysName.contains('appletv') ||
            iosInfo.model.toLowerCase().contains('appletv') ||
            iosInfo.utsname.machine.toLowerCase().contains('appletv');
        _detected = _isAppleTV;
        _detectionReasons = _isAppleTV ? const ['apple_tv'] : const [];
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

  List<String> get tvDetectionReasons => _effectiveDetectionReasons;

  List<String> get _effectiveDetectionReasons {
    final reasons = <String>[..._detectionReasons];
    if (_forceTv && !reasons.contains('force_tv')) reasons.add('force_tv');
    return reasons;
  }

  Future<AndroidTvFeatureDetection?> _getNativeAndroidTvDetection() async {
    try {
      final result = await _deviceChannel.invokeMapMethod<dynamic, dynamic>('getTvDetection');
      if (result == null) return null;
      final reasonsValue = result['reasons'];
      final reasons = reasonsValue is Iterable ? reasonsValue.whereType<String>().toList() : <String>[];
      final isTv = result['isTv'] == true;
      if (isTv && reasons.isEmpty) reasons.add('native');
      return AndroidTvFeatureDetection(isTv: isTv, reasons: reasons);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// User-assigned Android device name (Settings > About > Device name), or
  /// null if unavailable. Android only.
  static Future<String?> getAndroidDeviceName() async {
    if (!Platform.isAndroid) return null;
    try {
      final name = (await _deviceChannel.invokeMethod<String>('getDeviceName'))?.trim();
      return (name == null || name.isEmpty) ? null : name;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Update the user force-TV override and recompute the effective flag.
  void setForceTv(bool value) {
    _forceTv = value;
    _isTV = _detected || _forceTv;
  }

  /// Synchronous access after initialization (returns false if not initialized)
  static bool isTVSync() => _debugAppleTVOverride ?? _instance?._isTV ?? false;

  /// Synchronous Apple TV check (returns false if not initialized or not tvOS).
  static bool isAppleTVSync() => _debugAppleTVOverride ?? (_tvosBuild || _instance?._isAppleTV == true);

  @visibleForTesting
  static void debugSetAppleTVOverride(bool? value) {
    _debugAppleTVOverride = value;
  }

  static List<String> tvDetectionReasonsSync() => _instance?._effectiveDetectionReasons ?? const [];

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

  /// True for iPhone/iPad-style iOS navigation. Excludes tvOS and forced-TV
  /// modes, where route back gestures conflict with D-pad navigation.
  static bool isHandheldIOS(BuildContext context) {
    return !isTV() && Theme.of(context).platform == TargetPlatform.iOS;
  }

  /// Detects if running on a desktop platform (Windows, macOS, or Linux)
  static bool isDesktop(BuildContext context) {
    return !isMobile(context);
  }

  /// True on the desktop OS (Windows / macOS / Linux), without needing a
  /// BuildContext. Use for OS-level capability checks (window state, native
  /// keyboard, etc.); use [isDesktop] for layout decisions.
  static bool isDesktopOS() {
    return _debugIsDesktopOSOverride ?? (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }

  static bool? _debugIsDesktopOSOverride;

  /// Test-only: override [isDesktopOS] so device simulations (Android TV /
  /// Apple TV) don't inherit the test host's real platform.
  @visibleForTesting
  static void debugSetIsDesktopOSOverride(bool? value) {
    _debugIsDesktopOSOverride = value;
  }

  static bool supportsExternalPlayers() {
    if (isAppleTV()) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  static bool supportsAudioPassthrough() {
    // Apple TV: EAC3+JOC rides the AVPlayer Atmos sink in the mpv fork's
    // ao_avfoundation; other Dolby content decodes to multichannel PCM.
    // Route capability is gated at runtime inside the AO itself.
    return isAppleTV() || isDesktopOS() || (Platform.isAndroid && isTV());
  }

  static bool supportsPictureInPicture() {
    return !isAppleTV() && !isTV() && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
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
