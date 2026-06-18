import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';
import 'async_singleton.dart';
import 'device_channel.dart';

const _androidFeatureTelevision = 'android.hardware.type.television';
const _androidFeatureLeanback = 'android.software.leanback';
const _androidFeatureFireTv = 'amazon.hardware.fire_tv';
const _androidFeatureTouchscreen = 'android.hardware.touchscreen';
const _androidFeatureAutomotive = 'android.hardware.type.automotive';

class AndroidTvFeatureDetection {
  final bool isTv;

  /// True on Android Automotive OS head units. Never true together with
  /// [isTv]: `FEATURE_AUTOMOTIVE` is authoritative for the car form factor.
  final bool isAutomotive;

  /// Diagnostic TV signals, surfaced in the log export only while TV mode is
  /// active. Non-empty with [isTv] false when automotive vetoed the verdict.
  final List<String> reasons;

  const AndroidTvFeatureDetection({required this.isTv, required this.isAutomotive, required this.reasons});
}

AndroidTvFeatureDetection detectAndroidTvFromSystemFeatures(Iterable<String> features) {
  final featureSet = features.toSet();
  final reasons = <String>[];
  if (featureSet.contains(_androidFeatureTelevision)) reasons.add('television_feature');
  if (featureSet.contains(_androidFeatureLeanback)) reasons.add('leanback');
  if (featureSet.contains(_androidFeatureFireTv)) reasons.add('fire_tv');
  if (featureSet.isNotEmpty && !featureSet.contains(_androidFeatureTouchscreen)) reasons.add('no_touchscreen');

  // A car is never a TV. Rotary-only head units report no touchscreen, and OEM
  // images derived from other AOSP variants can carry a stray leanback flag;
  // either would otherwise route a vehicle through the leanback experience.
  final isAutomotive = featureSet.contains(_androidFeatureAutomotive);

  return AndroidTvFeatureDetection(
    isTv: !isAutomotive && reasons.isNotEmpty,
    isAutomotive: isAutomotive,
    reasons: reasons,
  );
}

/// Whether a floating player may be offered, given the host platform's own
/// picture-in-picture capability and the detected form factor.
///
/// Cars commonly lack `FEATURE_PICTURE_IN_PICTURE`, and a floating player would
/// keep the app's UI on screen while driving, which `DD-2` forbids. TV form
/// factors have no windowed surface to float into.
///
/// [hostSupportsPictureInPicture] is injected rather than read from [Platform]
/// so the form-factor vetoes stay observable on hosts that never support PiP:
/// on the Linux and Windows CI runners every [Platform] branch of the real gate
/// is false and unmockable, which would otherwise make the vetoes vacuous
/// exactly where the release is gated.
bool pictureInPictureAllowed({
  required bool hostSupportsPictureInPicture,
  required bool isAppleTv,
  required bool isTv,
  required bool isAutomotive,
}) => hostSupportsPictureInPicture && !isAppleTv && !isTv && !isAutomotive;

/// Service for detecting if the app is running on Android TV or Apple TV.
class TvDetectionService {
  static final AsyncSingleton<TvDetectionService> _singleton = AsyncSingleton();
  @visibleForTesting
  static set debugDetectionGate(Future<void>? value) => _singleton.debugGate = value;
  static bool? _debugAppleTVOverride;
  static bool? _debugAutomotiveOverride;
  bool _detected = false;
  bool _forceTv = false;
  bool _isTV = false;
  bool _isAppleTV = false;
  bool _isAutomotive = false;
  bool _initialized = false;
  List<String> _detectionReasons = const [];

  TvDetectionService._();

  /// Get the singleton instance, initializing if needed.
  /// Pass [forceTv] to combine a user override with the system-feature check.
  static Future<TvDetectionService> getInstance({bool forceTv = false}) =>
      _singleton.getInstance(TvDetectionService._, (instance) => instance._detect(forceTv));

  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  Future<void> _detect(bool forceTv) async {
    if (_initialized) return;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final nativeDetection = await _getNativeAndroidTvDetection();
      final detection =
          nativeDetection ?? detectAndroidTvFromSystemFeatures((await deviceInfo.androidInfo).systemFeatures);
      _detected = detection.isTv;
      _isAutomotive = detection.isAutomotive;
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

  /// True on Android Automotive OS. Independent of the force-TV override so
  /// driver-distraction gating cannot be switched off from settings.
  bool get isAutomotive => _isAutomotive;

  List<String> get _effectiveDetectionReasons {
    final reasons = <String>[..._detectionReasons];
    if (_forceTv && !reasons.contains('force_tv')) reasons.add('force_tv');
    return reasons;
  }

  Future<AndroidTvFeatureDetection?> _getNativeAndroidTvDetection() async {
    try {
      final result = await deviceChannel.invokeMapMethod<dynamic, dynamic>('getTvDetection');
      if (result == null) return null;
      final reasonsValue = result['reasons'];
      final reasons = reasonsValue is Iterable ? reasonsValue.whereType<String>().toList() : <String>[];
      final isTv = result['isTv'] == true;
      final isAutomotive = result['isAutomotive'] == true;
      if (isTv && reasons.isEmpty) reasons.add('native');
      return AndroidTvFeatureDetection(isTv: isTv && !isAutomotive, isAutomotive: isAutomotive, reasons: reasons);
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
      final name = (await deviceChannel.invokeMethod<String>('getDeviceName'))?.trim();
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
  static bool isTVSync() => _debugAppleTVOverride ?? _singleton.instance?._isTV ?? false;

  /// Synchronous Apple TV check (returns false if not initialized or not tvOS).
  static bool isAppleTVSync() => _debugAppleTVOverride ?? (_tvosBuild || _singleton.instance?._isAppleTV == true);

  /// Synchronous Android Automotive OS check (false before initialization).
  static bool isAutomotiveSync() => _debugAutomotiveOverride ?? _singleton.instance?._isAutomotive ?? false;

  @visibleForTesting
  static void debugSetAppleTVOverride(bool? value) {
    _debugAppleTVOverride = value;
  }

  @visibleForTesting
  static void debugSetAutomotiveOverride(bool? value) {
    _debugAutomotiveOverride = value;
  }

  @visibleForTesting
  static void debugReset() {
    _singleton.debugReset();
    _debugAppleTVOverride = null;
    _debugAutomotiveOverride = null;
  }

  static List<String> tvDetectionReasonsSync() => _singleton.instance?._effectiveDetectionReasons ?? const [];

  /// Convenience setter that forwards to the singleton if available.
  static void setForceTVSync(bool value) => _singleton.instance?.setForceTv(value);
}

class PlatformDetector {
  static bool isTV() {
    return TvDetectionService.isTVSync();
  }

  static bool isAppleTV() {
    return TvDetectionService.isAppleTVSync();
  }

  /// True on Android Automotive OS head units.
  static bool isAutomotive() {
    return TvDetectionService.isAutomotiveSync();
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

  /// Detects if running on a mobile platform (iOS, Android or Linux Mobile).
  /// Excludes TV platforms (Android TV / Apple TV) even though the underlying
  /// OS is iOS or Android.
  /// Uses Theme for consistent platform detection across the app.
  static bool isMobile(BuildContext context) {
    if (isTV()) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android ||
      (platform == TargetPlatform.linux && getDiagonalInches(context) <= 7.0);
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

  /// Whether an executable path belongs to a packaged (MSIX/Store) install.
  /// Packaged apps run from C:\Program Files\WindowsApps\<package>\, matched
  /// case-insensitively because a casing difference would silently re-enable
  /// the paths a read-only package cannot support.
  @visibleForTesting
  static bool isPackagedExecutablePath(String exePath) {
    return exePath.toLowerCase().contains('\\windowsapps\\');
  }

  /// True inside a packaged (MSIX/Microsoft Store) install. The Store owns
  /// updates and the package directory is read-only, and Store policy treats an
  /// external donation link as a commerce mechanism, so both of those
  /// affordances are suppressed there.
  static bool isPackagedInstall() {
    try {
      if (!Platform.isWindows) return false;
      return isPackagedExecutablePath(Platform.resolvedExecutable);
    } catch (error, stackTrace) {
      appLogger.e('Failed to determine packaged install status', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  static bool supportsExternalPlayers() {
    if (isAppleTV()) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  static bool supportsAudioPassthrough() {
    // Apple TV hands AC3/EAC3 access units to the native sample-buffer audio
    // renderer; unsupported streams and renderer failures fall back to PCM.
    return isAppleTV() || isDesktopOS() || (Platform.isAndroid && isTV());
  }

  static bool supportsPictureInPicture() => pictureInPictureAllowed(
    hostSupportsPictureInPicture: Platform.isAndroid || Platform.isIOS || Platform.isMacOS,
    isAppleTv: isAppleTV(),
    isTv: isTV(),
    isAutomotive: isAutomotive(),
  );

  /// Gets diagonal screen size.
  /// Used to determine if a device is a tablet. Also, used to detect if a device is on LinuxMobile
  static num getDiagonalInches(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    // Convert diagonal from logical pixels to inches (assuming 160 DPI as baseline)
    return diagonal / (devicePixelRatio * 160 / 2.54);
  }

  /// Detects if the device is likely a tablet based on screen size
  /// Uses diagonal screen size to determine if device is a tablet
  static bool isTablet(BuildContext context) {
    return getDiagonalInches(context) >= 7.0;
  }

  static bool isPhone(BuildContext context) {
    return isHandheld(context) && !isTablet(context);
  }
}
