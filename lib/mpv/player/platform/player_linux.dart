import '../player_native.dart';

/// Uses libmpv with FlTextureGL — video rendered to an offscreen FBO
/// and composited GPU-side via Flutter's Texture widget.
class PlayerLinux extends PlayerNative {}
