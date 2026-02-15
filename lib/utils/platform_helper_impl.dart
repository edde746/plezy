/// Platform helper implementation.
///
/// Uses conditional imports to select native vs web implementation.
library;

import 'platform_helper_native.dart'
    if (dart.library.js_interop) 'platform_helper_web.dart' as impl;

/// Unified platform detection that works on both native and web.
class AppPlatform {
  AppPlatform._();

  static bool get isAndroid => impl.isAndroid;
  static bool get isIOS => impl.isIOS;
  static bool get isMacOS => impl.isMacOS;
  static bool get isWindows => impl.isWindows;
  static bool get isLinux => impl.isLinux;
  static bool get isFuchsia => impl.isFuchsia;
  static bool get isWeb => impl.isWeb;
  static bool get isWebOS => impl.isWebOS;

  /// True on any desktop platform (macOS, Windows, Linux).
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// True on any mobile platform (Android, iOS) but NOT TV.
  static bool get isMobile => isAndroid || isIOS;

  /// True if running on a TV platform (Android TV or webOS).
  static bool get isTV => isWebOS || _isAndroidTV;

  /// Set by TvDetectionService on Android.
  static bool _isAndroidTV = false;
  static void setAndroidTV(bool value) => _isAndroidTV = value;

  /// True if native file I/O is available.
  static bool get hasFileSystem => !isWeb;

  /// True if window management APIs are available.
  static bool get hasWindowManager => isDesktop;

  /// Returns the operating system name string.
  static String get operatingSystem {
    if (isWebOS) return 'webos';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isMacOS) return 'macos';
    if (isWindows) return 'windows';
    if (isLinux) return 'linux';
    if (isWeb) return 'web';
    return 'unknown';
  }
}
