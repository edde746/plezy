import 'player_native.dart';

/// Players whose video lives in a native surface behind the Flutter window,
/// and so must be told where to put it.
///
/// Constrained to [PlayerNative] because the request is the same on every such
/// platform — a Windows child HWND and a Wayland subsurface take identical
/// geometry — so the mixin carries the call instead of each platform repeating
/// it. `Video` keys its layout reporting off this type: mixing it in is what
/// says the player has a surface worth positioning.
mixin VideoRectSupport on PlayerNative {
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
