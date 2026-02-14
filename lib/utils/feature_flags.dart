import 'package:flutter/foundation.dart' show kIsWeb;

/// Feature flags for platform-specific feature availability.
///
/// Used to gate features that are not available on all platforms.
/// On webOS/web, many native features are unavailable.
class FeatureFlags {
  FeatureFlags._();

  /// Whether file downloads are available.
  /// Disabled on web/webOS (no filesystem access).
  static bool get downloadsAvailable => !kIsWeb;

  /// Whether offline mode is available.
  /// Requires downloads, so disabled on web.
  static bool get offlineModeAvailable => !kIsWeb;

  /// Whether Picture-in-Picture is available.
  static bool get pipAvailable => !kIsWeb;

  /// Whether external player launching is available.
  static bool get externalPlayerAvailable => !kIsWeb;

  /// Whether Discord Rich Presence is available.
  static bool get discordRPCAvailable => !kIsWeb;

  /// Whether QR code scanning is available.
  static bool get qrScannerAvailable => !kIsWeb;

  /// Whether gamepad input is available (via native plugin).
  /// webOS remote works as keyboard events, no plugin needed.
  static bool get gamepadPluginAvailable => !kIsWeb;

  /// Whether window management is available.
  static bool get windowManagerAvailable => !kIsWeb;

  /// Whether OS media controls integration is available.
  static bool get osMediaControlsAvailable => !kIsWeb;

  /// Whether GPU shader upscaling is available.
  /// TV handles upscaling in hardware.
  static bool get shaderUpscalingAvailable => !kIsWeb;

  /// Whether in-app review is available.
  static bool get inAppReviewAvailable => !kIsWeb;

  /// Whether background download manager is available.
  static bool get backgroundDownloaderAvailable => !kIsWeb;

  /// Whether the app can open URLs in external browser.
  static bool get urlLauncherAvailable => !kIsWeb;

  /// Whether MPV/ExoPlayer config screens should be shown.
  static bool get nativePlayerConfigAvailable => !kIsWeb;

  /// Whether wakelock is available via plugin.
  static bool get wakelockAvailable => !kIsWeb;

  /// Whether the companion remote feature is available.
  static bool get companionRemoteAvailable => true; // WebSocket works on web

  /// Whether Watch Together is available.
  static bool get watchTogetherAvailable => true; // WebSocket works on web
}
