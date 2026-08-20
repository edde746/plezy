import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/rasterized_gradient.dart';

/// The strip texture must composite identically to Skia's gradient shader.
/// Translucent non-black ramps are the regression case: rgba8888 strips are
/// consumed premultiplied, so straight-alpha baking renders them far too
/// bright (a white fade-to-transparent scrim becomes an opaque sheet).
void main() {
  Future<ui.Image> capture(WidgetTester tester, Key key) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    late ui.Image image;
    await tester.runAsync(() async => image = await boundary.toImage());
    return image;
  }

  Future<List<int>> centerColumn(WidgetTester tester, ui.Image image) async {
    late ByteData bytes;
    await tester.runAsync(() async => bytes = (await image.toByteData())!);
    final x = image.width ~/ 2;
    final column = <int>[];
    for (var y = 0; y < image.height; y += 8) {
      final offset = (y * image.width + x) * 4;
      column.addAll([bytes.getUint8(offset), bytes.getUint8(offset + 1), bytes.getUint8(offset + 2)]);
    }
    return column;
  }

  testWidgets('strip path matches the gradient shader over a colored background', (tester) async {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.8),
        Colors.white.withValues(alpha: 0.4),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    // Bake ahead of the build so RasterizedGradient paints the strip from
    // its first frame instead of the (trivially identical) shader fallback.
    late ui.Image? strip;
    await tester.runAsync(() async => strip = await RasterizedGradient.prebake(gradient));
    expect(strip, isNotNull, reason: 'axis-aligned gradient must bake to a strip');

    const rasterizedKey = Key('rasterized');
    const shaderKey = Key('shader');
    Widget sample(Key key, Widget gradientBox) => RepaintBoundary(
      key: key,
      child: SizedBox(
        width: 64,
        height: 256,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF406080)),
            gradientBox,
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sample(rasterizedKey, RasterizedGradient(gradient: gradient)),
              sample(shaderKey, DecoratedBox(decoration: BoxDecoration(gradient: gradient))),
            ],
          ),
        ),
      ),
    );

    final rasterized = await centerColumn(tester, await capture(tester, rasterizedKey));
    final shader = await centerColumn(tester, await capture(tester, shaderKey));

    for (var i = 0; i < shader.length; i++) {
      // Skia dithers its gradient shader; the strip doesn't. Allow a couple
      // of levels of noise — the premul bug is off by 50+ on this ramp.
      expect(
        (rasterized[i] - shader[i]).abs(),
        lessThanOrEqualTo(3),
        reason: 'channel ${i % 3} at sample ${i ~/ 3}: strip=${rasterized[i]} shader=${shader[i]}',
      );
    }
  });
}
