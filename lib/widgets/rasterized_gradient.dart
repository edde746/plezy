import 'dart:async' show unawaited;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints an axis-aligned [LinearGradient] as a pre-rasterized 1-D strip
/// texture stretched across the box instead of evaluating Skia's gradient
/// shader per pixel.
///
/// Skia's dithered gradient shaders cost ~10ms per full-screen pass on
/// low-end TV GPUs (measured on a Mali-G31 box: the two spotlight scrims
/// alone were ~20ms of a 27ms raster frame, while flat blended quads on the
/// same coverage were ~free). A strip texture blends at flat-quad cost: the
/// strip stays resident in the GPU texture cache, so per-pixel bandwidth is
/// framebuffer-only.
///
/// The strip quantizes the ramp to 8-bit without dithering, which is
/// indistinguishable for scrims with large alpha ranges (steps land every
/// few pixels). Don't use it for subtle low-contrast ramps spanning huge
/// areas — those are where undithered gradients band visibly.
///
/// Gradients that aren't pure-horizontal/vertical (or that carry a
/// transform or non-clamp tile mode) paint through the regular shader path
/// unchanged, as does the first frame while the strip decodes.
class RasterizedGradient extends StatefulWidget {
  final LinearGradient gradient;
  final Widget? child;

  const RasterizedGradient({super.key, required this.gradient, this.child});

  /// Bakes [gradient]'s strip ahead of time so the first build paints it
  /// instead of the shader fallback. Tests use this to guarantee they
  /// exercise the strip path.
  @visibleForTesting
  static Future<ui.Image?> prebake(LinearGradient gradient) => _GradientStripCache.bake(gradient);

  @override
  State<RasterizedGradient> createState() => _RasterizedGradientState();
}

class _RasterizedGradientState extends State<RasterizedGradient> {
  ui.Image? _strip;

  @override
  void initState() {
    super.initState();
    _resolveStrip();
  }

  @override
  void didUpdateWidget(RasterizedGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gradient != oldWidget.gradient) {
      _strip = null;
      _resolveStrip();
    }
  }

  void _resolveStrip() {
    final gradient = widget.gradient;
    final cached = _GradientStripCache.get(gradient);
    if (cached != null) {
      _strip = cached;
      return;
    }
    _GradientStripCache.bake(gradient).then((image) {
      if (!mounted || image == null || widget.gradient != gradient) return;
      setState(() => _strip = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientStripPainter(strip: _strip, gradient: widget.gradient),
      child: widget.child,
    );
  }
}

class _GradientStripPainter extends CustomPainter {
  final ui.Image? strip;
  final LinearGradient gradient;

  const _GradientStripPainter({required this.strip, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final strip = this.strip;
    if (strip == null) {
      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
      return;
    }
    canvas.drawImageRect(
      strip,
      Rect.fromLTWH(0, 0, strip.width.toDouble(), strip.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_GradientStripPainter oldDelegate) =>
      strip != oldDelegate.strip || gradient != oldDelegate.gradient;
}

abstract final class _GradientStripCache {
  static const _stripLength = 1024;
  static const _maxEntries = 32;

  // Strips are ~4KB each and may be referenced by in-flight frames, so the
  // cache never disposes entries; the cap bounds it to ~128KB worst case.
  static final _strips = <LinearGradient, ui.Image>{};
  static final _pending = <LinearGradient, Future<ui.Image?>>{};

  static ui.Image? get(LinearGradient gradient) => _strips[gradient];

  static Future<ui.Image?> bake(LinearGradient gradient) {
    final cached = _strips[gradient];
    if (cached != null) return Future.value(cached);
    return _pending[gradient] ??= _bake(gradient);
  }

  static Future<ui.Image?> _bake(LinearGradient gradient) async {
    final bytes = _stripBytes(gradient);
    if (bytes == null) return null; // Unsupported shape: shader fallback.

    try {
      final image = await _decode(bytes, _isVertical(gradient));
      if (_strips.length >= _maxEntries) _strips.remove(_strips.keys.first);
      _strips[gradient] = image;
      return image;
    } catch (_) {
      return null; // Keep painting through the shader path.
    } finally {
      unawaited(_pending.remove(gradient));
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes, bool vertical) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: vertical ? 1 : _stripLength,
      height: vertical ? _stripLength : 1,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  static bool _isVertical(LinearGradient gradient) {
    final begin = gradient.begin as Alignment;
    final end = gradient.end as Alignment;
    return begin.x == end.x;
  }

  /// Premultiplied RGBA texels along the gradient axis ([ui.PixelFormat.rgba8888]
  /// is consumed as premultiplied), or null when the gradient can't be
  /// represented as an axis-aligned clamped strip.
  static Uint8List? _stripBytes(LinearGradient gradient) {
    if (gradient.transform != null || gradient.tileMode != TileMode.clamp) return null;
    final begin = gradient.begin;
    final end = gradient.end;
    if (begin is! Alignment || end is! Alignment) return null;
    final vertical = begin.x == end.x && begin.y != end.y;
    final horizontal = begin.y == end.y && begin.x != end.x;
    if (!vertical && !horizontal) return null;

    // Box-relative fractions of the ramp's endpoints along the axis.
    final b = vertical ? (begin.y + 1) / 2 : (begin.x + 1) / 2;
    final e = vertical ? (end.y + 1) / 2 : (end.x + 1) / 2;

    final colors = gradient.colors;
    if (colors.isEmpty) return null;
    final stops =
        gradient.stops ?? [for (var i = 0; i < colors.length; i++) colors.length == 1 ? 0.0 : i / (colors.length - 1)];
    if (stops.length != colors.length) return null;

    final bytes = Uint8List(_stripLength * 4);
    for (var i = 0; i < _stripLength; i++) {
      final f = i / (_stripLength - 1);
      final t = ((f - b) / (e - b)).clamp(0.0, 1.0);
      final color = _colorAt(colors, stops, t);
      // Skia gradients interpolate straight-alpha, then premultiply at
      // shading — lerp first, premultiply last replicates that exactly.
      final a = color.a;
      bytes[i * 4] = (color.r * a * 255.0).round().clamp(0, 255);
      bytes[i * 4 + 1] = (color.g * a * 255.0).round().clamp(0, 255);
      bytes[i * 4 + 2] = (color.b * a * 255.0).round().clamp(0, 255);
      bytes[i * 4 + 3] = (a * 255.0).round().clamp(0, 255);
    }
    return bytes;
  }

  static Color _colorAt(List<Color> colors, List<double> stops, double t) {
    if (t <= stops.first) return colors.first;
    if (t >= stops.last) return colors.last;
    for (var i = 0; i < stops.length - 1; i++) {
      if (t > stops[i + 1]) continue;
      final span = stops[i + 1] - stops[i];
      final local = span <= 0 ? 0.0 : (t - stops[i]) / span;
      return Color.lerp(colors[i], colors[i + 1], local)!;
    }
    return colors.last;
  }
}
