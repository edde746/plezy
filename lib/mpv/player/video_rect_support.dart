import 'player.dart';

/// Mixin for players that support video rect positioning.
///
/// Players that render video behind the Flutter view (e.g., using
/// native window embedding or GtkGLArea) implement this mixin to
/// receive layout updates from the [Video] widget.
mixin VideoRectSupport on Player {
  /// Updates the video rendering area.
  ///
  /// Called by the [Video] widget when the layout changes.
  ///
  /// [left], [top], [right], [bottom] define the rect in physical pixels.
  /// [devicePixelRatio] is the device's pixel ratio for scaling.
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  });
}
