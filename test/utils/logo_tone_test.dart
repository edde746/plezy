import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/logo_tone.dart';

/// Contract tests for the channel-logo tone pipeline behind issue #2197.
///
/// The four synthesized archetypes mirror the logos in the report: a white
/// monochrome wordmark (CBS/FOX), a colored mark with a white wordmark (NBC),
/// a self-backed dark disc with light text inside (abc), and a colored chip
/// (PBS KIDS).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 300, h = 150;

  Future<ByteData> rasterize(void Function(Canvas canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    image.dispose();
    return data!;
  }

  // Fractional offsets and round caps guarantee antialiased (partial-alpha)
  // edge pixels; integer-aligned rects rasterize without any.
  Future<ByteData> whiteWordmark() => rasterize((c) {
    for (var i = 0; i < 4; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(30.5 + i * 65, 40.5, 45, 70), const Radius.circular(12)),
        Paint()..color = Colors.white,
      );
    }
  });

  Future<ByteData> mixedMark() => rasterize((c) {
    const colors = [Colors.purple, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.red];
    for (var i = 0; i < colors.length; i++) {
      final angle = math.pi + i * math.pi / colors.length;
      c.drawCircle(Offset(75 + 35 * math.cos(angle), 85 + 35 * math.sin(angle)), 14, Paint()..color = colors[i]);
    }
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(150.0 + i * 50, 50, 35, 50), Paint()..color = Colors.white);
    }
  });

  // White wordmark with a dark underline and one small colored accent (a
  // Babylon/Attack on Titan shape): light-dominant but not monochrome, and
  // the colored fraction sits well under the 15% split.
  Future<ByteData> accentedMark() => rasterize((c) {
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(30.5 + i * 65, 40.5, 45, 70), Paint()..color = Colors.white);
    }
    c.drawRect(const Rect.fromLTWH(30.5, 118.5, 260, 12), Paint()..color = const Color(0xFF303030));
    c.drawCircle(const Offset(285, 55), 12, Paint()..color = Colors.red);
  });

  Future<ByteData> selfBackedDisc() => rasterize((c) {
    c.drawCircle(const Offset(150, 75), 65, Paint()..color = const Color(0xFF0F0F0F));
    c.drawRect(const Rect.fromLTWH(115, 60, 70, 30), Paint()..color = Colors.white);
  });

  Future<ByteData> coloredChip() => rasterize((c) {
    c.drawCircle(const Offset(150, 75), 70, Paint()..color = const Color(0xFF2638C4));
    c.drawRect(const Rect.fromLTWH(110, 55, 80, 40), Paint()..color = const Color(0xFF8EC63F));
  });

  group('analyzeLogoTone', () {
    test('classifies the issue-2197 archetypes', () async {
      expect(analyzeLogoTone(await whiteWordmark(), w, h), LogoTone.lightMonochrome);
      expect(analyzeLogoTone(await accentedMark(), w, h), LogoTone.lightAccented);
      expect(analyzeLogoTone(await mixedMark(), w, h), LogoTone.lightMixed);
      expect(analyzeLogoTone(await selfBackedDisc(), w, h), LogoTone.dark);
      expect(analyzeLogoTone(await coloredChip(), w, h), LogoTone.dark);
    });

    test('near-empty frame is unknown, not a remap candidate', () async {
      final sparse = await rasterize((c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = Colors.white);
      });
      expect(analyzeLogoTone(sparse, w, h), LogoTone.unknown);
    });

    test('sparse sampling agrees with full-res on every archetype', () async {
      for (final data in [
        await whiteWordmark(),
        await accentedMark(),
        await mixedMark(),
        await selfBackedDisc(),
        await coloredChip(),
      ]) {
        expect(analyzeLogoTone(data, w, h, stride: 4), analyzeLogoTone(data, w, h));
      }
    });
  });

  group('remapLightNeutral', () {
    const target = 0xFF111111;

    int lumaAt(Uint8List px, int i) => (px[i] * 77 + px[i + 1] * 150 + px[i + 2] * 29) >> 8;

    test('recolors white pixels to the target and keeps colored pixels', () async {
      final data = await mixedMark();
      final out = remapLightNeutral(data, targetArgb: target);

      // Wordmark interior (opaque white source) becomes the near-black target.
      final wordmarkIndex = ((75 * w) + 165) * 4;
      expect(out[wordmarkIndex + 3], 255);
      expect(lumaAt(out, wordmarkIndex), lessThan(32));

      // A saturated feather pixel keeps its hue: red channel still dominates.
      final src = data.buffer.asUint8List();
      var featherIndex = -1;
      for (var i = 0; i < src.length; i += 4) {
        if (src[i + 3] == 255 && src[i] > 200 && src[i + 1] < 80 && src[i + 2] < 80) {
          featherIndex = i;
          break;
        }
      }
      expect(featherIndex, isNot(-1), reason: 'synthesized mark should contain a saturated red pixel');
      expect(out[featherIndex], src[featherIndex]);
      expect(out[featherIndex + 1], src[featherIndex + 1]);
      expect(out[featherIndex + 2], src[featherIndex + 2]);
    });

    test('antialiased edge pixels darken instead of leaving a light fringe', () async {
      final data = await whiteWordmark();
      final out = remapLightNeutral(data, targetArgb: target);
      var partials = 0;
      for (var i = 0; i < out.length; i += 4) {
        final a = out[i + 3];
        if (a < 16 || a > 240) continue;
        partials++;
        // Output is premultiplied; unpremultiply before judging lightness.
        final luma = ((out[i] * 77 + out[i + 1] * 150 + out[i + 2] * 29) >> 8) * 255 ~/ a;
        expect(luma, lessThanOrEqualTo(96), reason: 'edge pixel at byte $i stayed light (luma $luma, alpha $a)');
      }
      expect(partials, greaterThan(0), reason: 'rasterized wordmark should have antialiased edges');
    });

    test('output is valid premultiplied RGBA', () async {
      final out = remapLightNeutral(await whiteWordmark(), targetArgb: target);
      for (var i = 0; i < out.length; i += 4) {
        final a = out[i + 3];
        expect(out[i], lessThanOrEqualTo(a));
        expect(out[i + 1], lessThanOrEqualTo(a));
        expect(out[i + 2], lessThanOrEqualTo(a));
      }
    });
  });
}
