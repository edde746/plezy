import 'dart:typed_data';

/// Classification of a channel-logo frame for theme-adaptive rendering.
///
/// Broadcast channel logos (Gracenote and most Jellyfin/Emby lineups) are
/// designed for dark UIs: white or near-white marks on transparency. On the
/// light theme's white cards they are invisible (issue #2197). The tone drives
/// whether [remapLightNeutral] may recolor a logo for a light surface.
enum LogoTone {
  /// Too few opaque pixels to judge — leave untouched.
  unknown,

  /// Near-white, low-saturation mark (CBS/FOX-style wordmarks).
  lightMonochrome,

  /// Mixed light and colored content (NBC-style peacock + white wordmark).
  lightMixed,

  /// Dark or self-backed artwork (abc's black disc, PBS KIDS' blue chip):
  /// legible on light surfaces as-is. Also the gate that keeps
  /// [remapLightNeutral] away from light text sitting inside an opaque dark
  /// shape, which a per-pixel remap alone would erase.
  dark,
}

/// Single-pass tone analysis over a **straight-alpha** RGBA frame
/// (`ImageByteFormat.rawStraightRgba`). Premultiplied input reads antialiased
/// and semi-transparent pixels darker than they are and must not be used.
///
/// [stride] samples every Nth pixel on both axes; 1 visits every pixel.
/// Cost is O(w·h / stride²) with no allocation.
LogoTone analyzeLogoTone(ByteData rgba, int width, int height, {int stride = 1}) {
  final bytes = rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes);
  var opaque = 0;
  var light = 0;
  var lightLowSat = 0;

  for (var y = 0; y < height; y += stride) {
    var i = y * width * 4;
    final rowEnd = i + width * 4;
    for (; i < rowEnd; i += 4 * stride) {
      final a = bytes[i + 3];
      if (a < 32) continue;
      opaque++;
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      // Rec.601 integer luma.
      final luma = (r * 77 + g * 150 + b * 29) >> 8;
      if (luma < 176) continue;
      light++;
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxC - minC <= 48) lightLowSat++;
    }
  }

  final sampled = ((height + stride - 1) ~/ stride) * ((width + stride - 1) ~/ stride);
  if (sampled == 0 || opaque * 50 < sampled) return LogoTone.unknown; // <2% coverage
  final lightFrac = light / opaque;
  if (lightFrac >= 0.85 && lightLowSat / opaque >= 0.80) return LogoTone.lightMonochrome;
  if (lightFrac >= 0.30) return LogoTone.lightMixed;
  return LogoTone.dark;
}

/// Bakes a light-surface-adapted copy of a light-toned logo frame.
///
/// Input is **straight-alpha** RGBA (`ImageByteFormat.rawStraightRgba`);
/// output is **premultiplied** RGBA, ready for
/// `ImageDescriptor.raw(..., PixelFormat.rgba8888)`. Reading the widely used
/// `rawRgba` instead silently premultiplies, which drags antialiased glyph
/// edges below the luma ramp — they escape the remap and render as a light
/// fringe around the recolored mark.
///
/// Lerps each pixel toward [targetArgb] weighted by how light *and* neutral it
/// is: full weight above ~0.85 luma at ~zero saturation, zero weight below
/// ~0.6 luma or above ~0.35 saturation, smooth ramp between. Colored content
/// (an NBC peacock) keeps its pixels; white wordmarks become the target;
/// antialiased boundary pixels land proportionally in between. Alpha is
/// preserved. Only call for [LogoTone.lightMonochrome] /
/// [LogoTone.lightMixed]; the classification is the gate that protects
/// self-backed logos (white text inside an opaque dark disc).
Uint8List remapLightNeutral(ByteData rgba, {required int targetArgb}) {
  final src = rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes);
  final out = Uint8List.fromList(src);
  final tr = (targetArgb >> 16) & 0xFF, tg = (targetArgb >> 8) & 0xFF, tb = targetArgb & 0xFF;

  for (var i = 0; i < out.length; i += 4) {
    final a = out[i + 3];
    if (a == 0) {
      out[i] = 0;
      out[i + 1] = 0;
      out[i + 2] = 0;
      continue;
    }
    var r = out[i], g = out[i + 1], b = out[i + 2];
    final luma = (r * 77 + g * 150 + b * 29) >> 8;
    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final sat = maxC == 0 ? 0 : 255 * (maxC - minC) ~/ maxC;
    // Luma ramp 153..217 (0.60..0.85), saturation ramp 89..38 (0.35..0.15).
    final lw = ((luma - 153) * 4).clamp(0, 255);
    final sw = ((89 - sat) * 5).clamp(0, 255);
    final w = lw * sw ~/ 255;
    if (w != 0) {
      r += (tr - r) * w ~/ 255;
      g += (tg - g) * w ~/ 255;
      b += (tb - b) * w ~/ 255;
    }
    // Premultiply for PixelFormat.rgba8888 consumption.
    out[i] = r * a ~/ 255;
    out[i + 1] = g * a ~/ 255;
    out[i + 2] = b * a ~/ 255;
  }
  return out;
}
