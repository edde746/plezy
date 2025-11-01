import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'platform_detector.dart';

/// Helper class for managing device orientation preferences across the app.
class OrientationHelper {
  /// Restores default orientation preferences based on device type.
  ///
  /// For phones: Locks to portrait-only (up and down)
  /// For tablets/desktop: Allows all orientations
  ///
  /// This should be called when leaving full-screen experiences like
  /// the video player to restore the app's default orientation behavior.
  static void restoreDefaultOrientations(BuildContext context) {
    final isPhone = PlatformDetector.isPhone(context);

    if (isPhone) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // For tablets and desktop, allow all orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Sets orientation to landscape-only mode.
  ///
  /// Used by the video player to force landscape orientation during playback.
  static void setLandscapeOrientation() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Restores edge-to-edge system UI mode.
  ///
  /// Should be called when exiting full-screen mode.
  static void restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
