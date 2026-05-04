import '../player_native.dart';
import '../video_rect_support.dart';

/// Uses libmpv with native window embedding behind the Flutter window.
class PlayerWindows extends PlayerNative with VideoRectSupport {
  // Native window embedding, not a Flutter texture.
  @override
  int? get textureId => null;

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
