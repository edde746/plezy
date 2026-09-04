import 'package:flutter/services.dart';
import 'platform_detector.dart';

class OrientationHelper {
  /// Restores the app's default orientation preferences: every orientation
  /// on every handheld. Phones rotate into the landscape shell (leading
  /// navigation rail) like tablets do; the video player owns its own lock.
  ///
  /// This should be called when leaving full-screen experiences like
  /// the video player to restore the app's default orientation behavior.
  static Future<void> restoreDefaultOrientations() async {
    // Cars are fixed-orientation devices; asking would only pin a compact
    // head unit that reads as a phone.
    if (PlatformDetector.isAutomotive()) return;
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  /// Sets orientation to landscape-only mode.
  ///
  /// Used by the video player to force landscape orientation during playback.
  static void setLandscapeOrientation() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (PlatformDetector.isAutomotive()) return;
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  /// Restores the app's default visible system UI mode.
  ///
  /// Should be called when exiting full-screen mode.
  static Future<void> restoreSystemUI() async {
    // Explicitly show both overlays first to clear any legacy immersive flags.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
