/// Players whose video is hosted in a native surface behind the Flutter
/// window and must follow the visible viewport reported by Flutter.
///
/// Rectangles use the Flutter render surface's physical-pixel coordinate
/// space. Each native adapter converts that into the coordinate system of its
/// surface host.
abstract interface class VideoRectSupport {
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  });
}
