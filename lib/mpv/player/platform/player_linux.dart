import '../player_native.dart';

/// Linux implementation of [Player].
///
/// Uses libmpv with OpenGL rendering via GtkGLArea.
/// The mpv video is rendered to a GtkGLArea positioned behind
/// the Flutter view using a GtkOverlay, with transparent regions
/// in the Flutter UI allowing the video to show through.
class PlayerLinux extends PlayerNative {
  @override
  int? get textureId => null; // Uses GtkGLArea, not Flutter texture
}
