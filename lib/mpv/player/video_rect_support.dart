import 'player.dart';

mixin VideoRectSupport on Player {
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  });
}
