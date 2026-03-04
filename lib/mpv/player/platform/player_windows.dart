import '../player_native.dart';
import '../video_rect_support.dart';

/// Windows implementation of [Player].
///
/// Uses libmpv via platform channels with native window embedding.
/// The mpv video window is positioned behind the Flutter window,
/// with transparent regions allowing the video to show through.
class PlayerWindows extends PlayerNative with VideoRectSupport {
  @override
  int? get textureId => null; // Uses native window embedding, not Flutter texture

  @override
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  }) async {
    await invoke('setVideoRect', {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'devicePixelRatio': devicePixelRatio,
    });
  }
}
