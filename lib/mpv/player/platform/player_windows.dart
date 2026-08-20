import '../player_native.dart';
import '../video_rect_support.dart';

/// Uses libmpv with native window embedding behind the Flutter window.
///
/// mpv renders into a child HWND, so Flutter only ever tells it where to sit
/// (see [VideoRectSupport]).
class PlayerWindows extends PlayerNative with VideoRectSupport {
  PlayerWindows() : super();
  PlayerWindows.preview() : super.preview();
}
