import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/packed_stereo_layout.dart';
import 'package:plezy/widgets/packed_stereo_ui.dart';

void main() {
  testWidgets('duplicates live UI into both side-by-side eye regions', (tester) async {
    final pixels = await _render(tester, PackedStereoLayout.sideBySideLeftFirst, const _HorizontalColors());

    expect(_pixel(pixels, 12, 20), _red);
    expect(_pixel(pixels, 37, 20), _blue);
    expect(_pixel(pixels, 62, 20), _red);
    expect(_pixel(pixels, 87, 20), _blue);
  });

  testWidgets('duplicates live UI into both over-under eye regions', (tester) async {
    final pixels = await _render(tester, PackedStereoLayout.topBottomRightFirst, const _VerticalColors());

    expect(_pixel(pixels, 50, 5), _red);
    expect(_pixel(pixels, 50, 15), _blue);
    expect(_pixel(pixels, 50, 25), _red);
    expect(_pixel(pixels, 50, 35), _blue);
  });

  testWidgets('disabled mode paints the ordinary UI once', (tester) async {
    final pixels = await _render(
      tester,
      PackedStereoLayout.sideBySideLeftFirst,
      const _HorizontalColors(),
      enabled: false,
    );

    expect(_pixel(pixels, 25, 20), _red);
    expect(_pixel(pixels, 75, 20), _blue);
  });
}

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);

Future<ByteData> _render(
  WidgetTester tester,
  PackedStereoLayout layout,
  CustomPainter painter, {
  bool enabled = true,
}) async {
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 100,
            height: 40,
            child: PackedStereoUi(
              layout: layout,
              enabled: enabled,
              child: CustomPaint(painter: painter),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    } finally {
      image.dispose();
    }
  }))!;
}

Color _pixel(ByteData bytes, int x, int y) {
  const width = 100;
  final index = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(index + 3),
    bytes.getUint8(index),
    bytes.getUint8(index + 1),
    bytes.getUint8(index + 2),
  );
}

class _HorizontalColors extends CustomPainter {
  const _HorizontalColors();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height), Paint()..color = _red);
    canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height), Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(_HorizontalColors oldDelegate) => false;
}

class _VerticalColors extends CustomPainter {
  const _VerticalColors();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 2), Paint()..color = _red);
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(_VerticalColors oldDelegate) => false;
}
