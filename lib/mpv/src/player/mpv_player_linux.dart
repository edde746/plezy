import 'package:flutter/services.dart';

import 'mpv_player_native.dart';

/// Linux implementation of [MpvPlayer].
///
/// Uses libmpv with OpenGL rendering via GtkGLArea.
/// The mpv video is rendered to a GtkGLArea positioned behind
/// the Flutter view using a GtkOverlay, with transparent regions
/// in the Flutter UI allowing the video to show through.
class MpvPlayerLinux extends MpvPlayerNative {
  static const _methodChannel = MethodChannel('com.plezy/mpv_player');

  @override
  int? get textureId => null; // Uses GtkGLArea, not Flutter texture

  /// Updates the video rendering area.
  ///
  /// On Linux, the GtkGLArea fills the entire overlay area,
  /// and mpv handles its own aspect ratio. This method triggers
  /// a redraw if needed.
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  }) async {
    await _methodChannel.invokeMethod('setVideoRect', {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'devicePixelRatio': devicePixelRatio,
    });
  }

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
