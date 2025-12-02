import 'package:flutter/services.dart';

import 'player_native.dart';

/// Windows implementation of [Player].
///
/// Uses libmpv via platform channels with native window embedding.
/// The mpv video window is positioned behind the Flutter window,
/// with transparent regions allowing the video to show through.
class PlayerWindows extends PlayerNative {
  static const _methodChannel = MethodChannel('com.plezy/mpv_player');

  @override
  int? get textureId => null; // Uses native window embedding, not Flutter texture

  /// Updates the video window position and size.
  ///
  /// This is called by [Video] when the widget layout changes.
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
}
