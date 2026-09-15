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

  /// Light-dominant mark with only incidental color (≤15% saturated pixels):
  /// a white wordmark with a small colored accent. Safe to remap everywhere —
  /// the accent keeps its pixels and the mark stays recognizable.
  lightAccented,

  /// Light content beside *significant* color (an NBC peacock, a red-outline
  /// wordmark with white fill). Remapping is legibility-correct but changes
  /// the mark's character, so hero surfaces leave these untouched while the
  /// guide's tiny channel cells still remap them.
  lightMixed,

  /// Artwork that supplies its own contrast and must never be remapped: a
  /// dark or colored mark (abc's black disc, PBS KIDS' blue chip), and any
  /// mark where one neutral tone is *enclosed* by the other — dark ink on a
  /// light plate, white text inside a dark disc, white letters inside a dark
  /// outline. [remapLightNeutral] folds light and dark neutrals into one
  /// tone, so an enclosed pair would collapse into an illegible blot; such
  /// artwork is already legible on a light surface as it is.
  backed,
}

// Pixel classes of the sampled grid used by [analyzeLogoTone].
const int _kTransparent = 0;
const int _kLightNeutral = 1; // remap weight > 0: luma ≥ 0.60, saturation < 0.35
const int _kDarkNeutral = 2; // luma < 0.60, saturation < 0.35
const int _kColored = 3; // saturation ≥ 0.35: keeps its pixels under the remap

/// Tone analysis over a **straight-alpha** RGBA frame
/// (`ImageByteFormat.rawStraightRgba`). Premultiplied input reads antialiased
/// and semi-transparent pixels darker than they are and must not be used.
///
/// Two questions, in order. First, transformation safety: [remapLightNeutral]
/// is permitted only when no neutral tone is enclosed by the opposite one
/// (see [LogoTone.backed]); a light majority never grants permission on its
/// own, because a white plate carrying dark text is mostly light too. Then,
/// for artwork the remap cannot harm, the light/color mix decides which light
/// tone it is.
///
/// Enclosure is decided on the sampled grid by four linear scans: a pixel is
/// enclosed when the first differently-classed pixel in every one of the four
/// axis directions is the opposite neutral tone. A dark underline sitting
/// beside a white wordmark, or a colored badge next to it, reaches
/// transparency or color in some direction and stays open; the glyphs of a
/// backed plate and the text of a self-backed disc do not.
///
/// [stride] samples every Nth pixel on both axes; 1 visits every pixel.
/// Cost is O(w·h / stride²) plus two bytes per sampled pixel.
LogoTone analyzeLogoTone(ByteData rgba, int width, int height, {int stride = 1}) {
  final bytes = rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes);
  final cols = (width + stride - 1) ~/ stride;
  final rows = (height + stride - 1) ~/ stride;
  final sampled = cols * rows;
  if (sampled == 0) return LogoTone.unknown;

  final classes = Uint8List(sampled);
  var opaque = 0;
  var light = 0;
  var lightLowSat = 0;
  var colored = 0;
  var lightNeutral = 0;
  var darkNeutral = 0;

  var cell = 0;
  for (var y = 0; y < height; y += stride) {
    var i = y * width * 4;
    final rowEnd = i + width * 4;
    for (; i < rowEnd; i += 4 * stride, cell++) {
      final a = bytes[i + 3];
      if (a < 32) continue;
      opaque++;
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      // Relative saturation ≥0.35: the same boundary at which
      // [remapLightNeutral]'s weight reaches zero.
      final saturated = maxC > 0 && 255 * (maxC - minC) ~/ maxC >= 89;
      // Rec.601 integer luma.
      final luma = (r * 77 + g * 150 + b * 29) >> 8;
      if (saturated) {
        colored++;
        classes[cell] = _kColored;
      } else if (luma >= 153) {
        // Remap weight > 0 starts at 0.60 luma.
        lightNeutral++;
        classes[cell] = _kLightNeutral;
      } else {
        darkNeutral++;
        classes[cell] = _kDarkNeutral;
      }
      if (luma < 176) continue;
      light++;
      if (maxC - minC <= 48) lightLowSat++;
    }
  }

  if (opaque * 50 < sampled) return LogoTone.unknown; // <2% coverage
  if (darkNeutral > 0 && lightNeutral > 0 && _hasEnclosedNeutral(classes, cols, rows, lightNeutral, darkNeutral)) {
    return LogoTone.backed;
  }
  final lightFrac = light / opaque;
  if (lightFrac >= 0.85 && lightLowSat / opaque >= 0.80) return LogoTone.lightMonochrome;
  if (lightFrac >= 0.30) {
    // Measured on real clear-logo sets: remap-friendly marks (white wordmark,
    // small accent) sit at ≤0.11 colored, identity-colored marks at ≥0.28 —
    // 0.15 splits them with margin on both sides.
    return colored * 100 <= opaque * 15 ? LogoTone.lightAccented : LogoTone.lightMixed;
  }
  return LogoTone.backed;
}

/// Whether most of either neutral tone is enclosed by the opposite one.
///
/// Four scans (left, right, up, down) each record, per neutral pixel, the
/// class of the first differently-classed pixel in that direction; the image
/// edge counts as transparent. A pixel stays enclosed only if all four are
/// the opposite neutral. "Most" is half the tone's pixels: a plate's glyphs
/// and a disc's text are enclosed almost entirely, while an underline or a
/// badge that merely touches the mark along one edge is not.
bool _hasEnclosedNeutral(Uint8List classes, int cols, int rows, int lightNeutral, int darkNeutral) {
  // 1 = open in some direction. Only neutral cells are ever read.
  final open = Uint8List(classes.length);

  // Horizontal scans.
  for (var y = 0; y < rows; y++) {
    final rowStart = y * cols;
    _scan(classes, open, rowStart, rowStart + cols, 1);
    _scan(classes, open, rowStart + cols - 1, rowStart - 1, -1);
  }
  // Vertical scans.
  for (var x = 0; x < cols; x++) {
    _scan(classes, open, x, x + rows * cols, cols);
    _scan(classes, open, x + (rows - 1) * cols, x - cols, -cols);
  }

  var enclosedLight = 0;
  var enclosedDark = 0;
  for (var i = 0; i < classes.length; i++) {
    if (open[i] != 0) continue;
    final c = classes[i];
    if (c == _kLightNeutral) {
      enclosedLight++;
    } else if (c == _kDarkNeutral) {
      enclosedDark++;
    }
  }
  return enclosedLight * 2 >= lightNeutral || enclosedDark * 2 >= darkNeutral;
}

/// One directional pass from [from] (inclusive) toward [to] (exclusive) in
/// steps of [step]. Marks a neutral cell open when the nearest cell of any
/// other class behind it in scan direction is not the opposite neutral.
void _scan(Uint8List classes, Uint8List open, int from, int to, int step) {
  // Class of the most recent cell that was not light / not dark; the edge
  // reads as transparent.
  var behindLight = _kTransparent;
  var behindDark = _kTransparent;
  for (var i = from; i != to; i += step) {
    final c = classes[i];
    if (c == _kLightNeutral) {
      if (behindLight != _kDarkNeutral) open[i] = 1;
      behindDark = c;
    } else if (c == _kDarkNeutral) {
      if (behindDark != _kLightNeutral) open[i] = 1;
      behindLight = c;
    } else {
      behindLight = c;
      behindDark = c;
    }
  }
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
