import '../player_native.dart';
import '../video_rect_support.dart';

/// Uses libmpv on a native Wayland video plane — Linux's only render path.
///
/// Video goes to a `wl_subsurface` stacked below the Flutter surface, the same
/// shape Windows gets from a child HWND: geometry arrives via
/// [VideoRectSupport.setVideoRect] and Flutter never composites the frames.
/// A session that cannot host the plane fails `initialize` outright rather than
/// degrading, so the user sees the reason instead of a black rectangle.
class PlayerLinux extends PlayerNative with VideoRectSupport {}
