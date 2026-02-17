import '../player_native.dart';

/// Linux implementation of [Player].
///
/// Uses libmpv with FlTextureGL — video is rendered to an offscreen FBO
/// and composited GPU-side via Flutter's Texture widget.
class PlayerLinux extends PlayerNative {
  // textureId is set during initialize() via PlayerNative
}
