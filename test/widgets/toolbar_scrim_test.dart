import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/toolbar_scrim.dart';

void main() {
  testWidgets('light scrim only lightens the content beneath it', (tester) async {
    // A fade from white to Colors.transparent (transparent black) passes
    // through translucent gray and paints a shadow band below the toolbar.
    const key = Key('scrim');
    const backdrop = Color(0xFFF7F7F8);
    expect(MonoPalette.light.bg, backdrop);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Theme(
          data: monoTheme(MonoPalette.light),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 64,
                  child: ColoredBox(
                    color: backdrop,
                    child: ToolbarScrim(child: SizedBox(height: 232)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    late ui.Image image;
    late ByteData bytes;
    await tester.runAsync(() async {
      image = await boundary.toImage();
      bytes = (await image.toByteData())!;
    });
    addTearDown(image.dispose);

    final floor = [(backdrop.r * 255).round(), (backdrop.g * 255).round(), (backdrop.b * 255).round()];
    final x = image.width ~/ 2;
    for (var y = 0; y < image.height; y++) {
      final offset = (y * image.width + x) * 4;
      for (var channel = 0; channel < 3; channel++) {
        final value = bytes.getUint8(offset + channel);
        // One level of slack for gradient dithering.
        expect(
          value,
          greaterThanOrEqualTo(floor[channel] - 1),
          reason: 'row $y of ${image.height}, channel $channel: $value is darker than the backdrop',
        );
      }
    }
  });
}
