import '../player_native.dart';
import '../video_rect_support.dart';

/// Dedicated mpv preview core rendered into a caller-provided screen rect.
class PlayerPreviewNative extends PlayerNative with VideoRectSupport {
  PlayerPreviewNative() : super.preview();

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
