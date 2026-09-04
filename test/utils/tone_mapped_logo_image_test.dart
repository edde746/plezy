import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/tone_mapped_logo_image.dart';

/// Pipeline tests for [ToneMappedLogoImage]: the provider must recolor a
/// light-toned logo during decode, leave self-backed dark artwork untouched,
/// and keep plain and tone-mapped variants in distinct image-cache entries.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const target = Color(0xFF111111);

  setUp(() => PaintingBinding.instance.imageCache.clear());
  tearDown(() => PaintingBinding.instance.imageCache.clear());

  Future<Uint8List> encodePng(void Function(Canvas canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final image = await recorder.endRecording().toImage(300, 150);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  }

  Future<Uint8List> whiteWordmarkPng() => encodePng((c) {
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(30.0 + i * 65, 40, 45, 70), Paint()..color = Colors.white);
    }
  });

  Future<Uint8List> selfBackedDiscPng() => encodePng((c) {
    c.drawCircle(const Offset(150, 75), 65, Paint()..color = const Color(0xFF0F0F0F));
    c.drawRect(const Rect.fromLTWH(115, 60, 70, 30), Paint()..color = Colors.white);
  });

  // White wordmark beside a large saturated block: LogoTone.lightMixed.
  Future<Uint8List> mixedMarkPng() => encodePng((c) {
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(150.0 + i * 50, 40, 35, 70), Paint()..color = Colors.white);
    }
    c.drawRect(const Rect.fromLTWH(20, 30, 110, 90), Paint()..color = Colors.red);
  });

  Future<ui.Image> resolveImage(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      completer.complete(info.image.clone());
      info.dispose();
    }, onError: completer.completeError);
    stream.addListener(listener);
    try {
      return await completer.future;
    } finally {
      stream.removeListener(listener);
    }
  }

  ImageProvider bounded(Uint8List png) =>
      ResizeImage(MemoryImage(png), width: 300, height: 150, policy: ResizeImagePolicy.fit);

  Future<Uint8List> straightPixels(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  test('recolors a white logo toward the target during decode', () async {
    final png = await whiteWordmarkPng();
    final image = await resolveImage(ToneMappedLogoImage(bounded(png), target: target));
    final px = await straightPixels(image);
    image.dispose();

    var opaque = 0;
    for (var i = 0; i < px.length; i += 4) {
      if (px[i + 3] != 255) continue;
      opaque++;
      final luma = (px[i] * 77 + px[i + 1] * 150 + px[i + 2] * 29) >> 8;
      expect(luma, lessThan(32), reason: 'opaque pixel at byte $i should match the near-black target');
    }
    expect(opaque, greaterThan(0));
  });

  test('leaves self-backed dark artwork byte-identical to the plain decode', () async {
    final png = await selfBackedDiscPng();
    final mapped = await resolveImage(ToneMappedLogoImage(bounded(png), target: target));
    final plain = await resolveImage(bounded(png));
    final mappedPx = await straightPixels(mapped);
    final plainPx = await straightPixels(plain);
    mapped.dispose();
    plain.dispose();

    expect(mappedPx, plainPx);
  });

  test('remapMixed:false leaves a mixed-tone mark byte-identical; the default still remaps it', () async {
    final png = await mixedMarkPng();
    final conservative = await resolveImage(ToneMappedLogoImage(bounded(png), target: target, remapMixed: false));
    final plain = await resolveImage(bounded(png));
    expect(await straightPixels(conservative), await straightPixels(plain));

    final aggressive = await resolveImage(ToneMappedLogoImage(bounded(png), target: target));
    final px = await straightPixels(aggressive);
    // The white wordmark region is remapped toward the near-black target.
    var darkened = 0;
    for (var i = 0; i < px.length; i += 4) {
      if (px[i + 3] != 255) continue;
      final luma = (px[i] * 77 + px[i + 1] * 150 + px[i + 2] * 29) >> 8;
      if (luma < 32) darkened++;
    }
    expect(darkened, greaterThan(0), reason: 'default policy should still remap mixed marks');
    conservative.dispose();
    plain.dispose();
    aggressive.dispose();
  });

  test('plain and tone-mapped variants occupy distinct cache entries', () async {
    final png = await whiteWordmarkPng();
    final inner = bounded(png);
    final mappedKey = await ToneMappedLogoImage(inner, target: target).obtainKey(ImageConfiguration.empty);
    final sameKey = await ToneMappedLogoImage(inner, target: target).obtainKey(ImageConfiguration.empty);
    final otherTargetKey = await ToneMappedLogoImage(
      inner,
      target: const Color(0xFFEDEDED),
    ).obtainKey(ImageConfiguration.empty);
    final otherPolicyKey = await ToneMappedLogoImage(
      inner,
      target: target,
      remapMixed: false,
    ).obtainKey(ImageConfiguration.empty);
    final innerKey = await inner.obtainKey(ImageConfiguration.empty);

    expect(mappedKey, sameKey);
    expect(mappedKey.hashCode, sameKey.hashCode);
    expect(mappedKey, isNot(otherTargetKey));
    expect(mappedKey, isNot(otherPolicyKey));
    expect(mappedKey, isNot(innerKey));

    final image = await resolveImage(ToneMappedLogoImage(inner, target: target));
    image.dispose();
    final plain = await resolveImage(inner);
    plain.dispose();
    expect(PaintingBinding.instance.imageCache.currentSize, 2);
  });

  test('logoToneTargetFor engages only over light backdrops', () {
    const foreground = Color(0xFF111111);
    // Light theme surfaces and backgrounds.
    expect(logoToneTargetFor(surface: const Color(0xFFFFFFFF), foreground: foreground), foreground);
    expect(logoToneTargetFor(surface: const Color(0xFFF7F7F8), foreground: foreground), foreground);
    // Dark theme surfaces and the light theme's inverted (dark) focus card.
    expect(logoToneTargetFor(surface: const Color(0xFF15171C), foreground: foreground), isNull);
    expect(logoToneTargetFor(surface: const Color(0xFF111111), foreground: foreground), isNull);
    // The dark theme's inverted focus card is light and re-engages the remap.
    expect(
      logoToneTargetFor(surface: const Color(0xFFEDEDED), foreground: const Color(0xFF0E0F12)),
      const Color(0xFF0E0F12),
    );
  });
}
