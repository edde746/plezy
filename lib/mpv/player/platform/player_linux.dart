import 'package:flutter/services.dart';

import '../player_native.dart';

/// Linux implementation of [Player].
///
/// Uses libmpv with OpenGL rendering via GtkGLArea.
/// The mpv video is rendered to a GtkGLArea positioned behind
/// the Flutter view using a GtkOverlay, with transparent regions
/// in the Flutter UI allowing the video to show through.
class PlayerLinux extends PlayerNative {
  static const _methodChannel = MethodChannel('com.plezy/mpv_player');

  @override
  int? get textureId => null; // Uses GtkGLArea, not Flutter texture

  /// Sets the visibility of the video controls overlay.
  ///
  /// On Linux, due to Flutter's lack of transparency support in GtkOverlay,
  /// we hide the video layer when controls are visible and show it when
  /// controls are hidden. This provides a workaround for the transparency
  /// limitation.
  @override
  Future<void> setControlsVisible(bool visible) async {
    await _methodChannel.invokeMethod('setControlsVisible', {
      'visible': visible,
    });
  }
}
