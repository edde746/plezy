import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/visualization/visualizer_content_limits.dart';
import 'package:plezy/services/visualization/visualizer_pack_store.dart';

// Source only; execute on the required private JIT runner before release.
void main() {
  test('portable library paths reject aliasing and Windows device names', () {
    for (final path in ['a//b.milk', 'a/../b.milk', 'a./b.milk', 'a /b.milk',
      'a/CON.milk', 'a/Lpt1.png', 'C:/a.milk', 'a\\b.milk', 'a/b.milk/']) {
      expect(() => VisualizerPackStore.safeArchivePath(path), throwsA(isA<VisualizerPackException>()));
    }
    expect(VisualizerPackStore.safeArchivePath('textures/Artist - café.png'), 'textures/Artist - café.png');
  });

  test('shader include directives are rejected but comments are preserved', () {
    for (final source in ['warp_1=`#include "outside.hlsl"', 'comp_2=# include <https://example.invalid/a>', '#include "a"']) {
      expect(() => VisualizerContentLimits.checkPreset(utf8.encode(source)), throwsFormatException);
    }
    VisualizerContentLimits.checkPreset(latin1.encode('// #include is not used\nwave_r=1\n'));
    expect(() => VisualizerContentLimits.checkPreset([0, 1, 2]), throwsFormatException);
  });

  test('executable assets cannot be smuggled in as notices', () {
    for (final path in ['plugins/a.js', 'licenses/notice.dll', 'textures/a.svg', 'shader.hlsl']) {
      expect(() => VisualizerContentLimits.checkAssetPath(path, isNotice: true), throwsFormatException);
    }
    VisualizerContentLimits.checkAssetPath('licenses/LICENSE', isNotice: true);
    VisualizerContentLimits.checkAssetPath('plugins/playlist.json');
  });

  Uint8List pngHeader(int width, int height) {
    final bytes = Uint8List(33)..setRange(0, 8, [137, 80, 78, 71, 13, 10, 26, 10])
      ..setRange(12, 16, ascii.encode('IHDR'));
    ByteData.sublistView(bytes)..setUint32(8, 13)..setUint32(16, width)..setUint32(20, height);
    return bytes;
  }

  test('dimensions are bounded before any pixel allocation', () {
    expect(VisualizerContentLimits.imagePixels('.png', pngHeader(1280, 720)), 921600);
    for (final dimensions in [(0, 1), (65536, 1), (4096, 4096)]) {
      expect(() => VisualizerContentLimits.imagePixels('.png', pngHeader(dimensions.$1, dimensions.$2)), throwsFormatException);
    }
    expect(() => VisualizerContentLimits.imagePixels('.png', Uint8List(4)), throwsFormatException);
  });

  test('JPEG segment lengths cannot skip beyond the bounded input', () {
    final invalid = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0xff, 0xff, 0]);
    expect(() => VisualizerContentLimits.imagePixels('.jpg', invalid), throwsFormatException);
    final validHeader = Uint8List.fromList([0xff, 0xd8, 0xff, 0xc0, 0, 8, 8, 0, 16, 0, 32, 1]);
    expect(VisualizerContentLimits.imagePixels('.jpg', validHeader), 512);
  });
}
