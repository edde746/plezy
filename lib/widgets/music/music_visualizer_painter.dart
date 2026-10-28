import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../media/media_source_info.dart';
import 'music_visualizer_preset.dart';

@immutable
class MusicVisualizerFrame {
  const MusicVisualizerFrame({
    this.timeSeconds = 0,
    this.energy = 0.4,
    this.transient = 0,
    this.progress = 0,
    this.playing = true,
  });

  final double timeSeconds;
  final double energy;
  final double transient;
  final double progress;
  final bool playing;
}

@immutable
class MusicVisualizerPalette {
  const MusicVisualizerPalette({
    required this.background,
    required this.backgroundGlow,
    required this.colors,
    required this.outline,
  });

  factory MusicVisualizerPalette.fromTheme({
    required Color accent,
    required Color background,
    required Color surface,
    required Color outline,
    required MusicVisualizerPreset preset,
  }) {
    final seed = HSLColor.fromColor(accent);
    final hueOffset = switch (preset) {
      MusicVisualizerPreset.aurora => 132.0,
      MusicVisualizerPreset.bloom => 342.0,
      MusicVisualizerPreset.orbitals => 212.0,
      MusicVisualizerPreset.prism => 278.0,
      MusicVisualizerPreset.tunnel => 28.0,
      MusicVisualizerPreset.trackMap => 0.0,
    };

    Color tint(double offset, double lightness) => HSLColor.fromAHSL(
      1,
      (seed.hue + hueOffset + offset) % 360,
      math.max(seed.saturation, 0.72),
      lightness,
    ).toColor();

    return MusicVisualizerPalette(
      background: Color.lerp(background, const Color(0xFF05060B), 0.9)!,
      backgroundGlow: Color.lerp(surface, const Color(0xFF0A0D18), 0.9)!,
      colors: [tint(0, 0.66), tint(62, 0.70), tint(142, 0.58), tint(225, 0.72)],
      outline: outline.withValues(alpha: 0.14),
    );
  }

  final Color background;
  final Color backgroundGlow;
  final List<Color> colors;
  final Color outline;
}

/// Draws one original, procedural scene per preset. The only audio-derived
/// inputs available to the Flutter player are Plex's time-indexed loudness
/// profile or MPV's compact centroid/flatness statistics. The scenes react to
/// those envelopes; they never receive decoded samples or frequency bins.
class MusicVisualizerPainter extends CustomPainter {
  MusicVisualizerPainter({required this.frame, required this.preset, required this.palette, required this.profile})
    : super(repaint: frame);

  final ValueListenable<MusicVisualizerFrame> frame;
  final MusicVisualizerPreset preset;
  final MusicVisualizerPalette palette;
  final AudioLoudnessProfile? profile;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;

    final frame = this.frame.value;
    final time = frame.timeSeconds * (frame.playing ? 1.0 : 0.35);
    final energy = frame.energy.clamp(0.04, 1.2).toDouble();
    final transient = frame.transient.clamp(0.0, 1.0).toDouble();

    _paintBackdrop(canvas, size, time);
    switch (preset) {
      case MusicVisualizerPreset.aurora:
        _paintAurora(canvas, size, time, energy, transient);
      case MusicVisualizerPreset.bloom:
        _paintBloom(canvas, size, time, energy, transient);
      case MusicVisualizerPreset.orbitals:
        _paintOrbitals(canvas, size, time, energy, transient);
      case MusicVisualizerPreset.prism:
        _paintPrism(canvas, size, time, energy, transient);
      case MusicVisualizerPreset.tunnel:
        _paintTunnel(canvas, size, time, energy, transient);
      case MusicVisualizerPreset.trackMap:
        _paintTrackMap(canvas, size, time, energy);
    }
    _paintVignette(canvas, size);
  }

  void _paintBackdrop(Canvas canvas, Size size, double time) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.background, palette.backgroundGlow, palette.background],
          stops: const [0, 0.52, 1],
        ).createShader(rect),
    );

    final center = Offset(size.width * (0.5 + 0.035 * math.sin(time * 0.11)), size.height * 0.48);
    final radius = math.max(size.width, size.height) * 0.72;
    for (var i = 0; i < 3; i++) {
      final color = palette.colors[i].withValues(alpha: i == 0 ? 0.13 : 0.065);
      final offset = Offset((i - 1) * size.width * 0.16, (i.isEven ? 1 : -1) * size.height * 0.08);
      final glowRect = Rect.fromCircle(center: center + offset, radius: radius);
      canvas.drawCircle(
        center + offset,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ).createShader(glowRect),
      );
    }

    final starCount = (size.width * size.height / 30000).round().clamp(28, 96);
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < starCount; i++) {
      final x = _fract(i * 0.61803398875 + 0.13) * size.width;
      final y = _fract(i * 0.75487766625 + 0.51) * size.height;
      final shimmer = 0.18 + 0.42 * (0.5 + 0.5 * math.sin(time * (0.18 + i % 5 * 0.025) + i * 2.17));
      starPaint.color = palette.colors[i % palette.colors.length].withValues(alpha: shimmer);
      canvas.drawCircle(Offset(x, y), 0.65 + (i % 4) * 0.25, starPaint);
    }
  }

  void _paintAurora(Canvas canvas, Size size, double time, double energy, double transient) {
    final segments = (size.width / 6).round().clamp(72, 384);
    final height = size.height;
    final amplitude = height * (0.045 + energy * 0.035 + transient * 0.045);
    for (var layer = 0; layer < 9; layer++) {
      final path = Path();
      final row = layer / 8;
      final baseline = height * (0.19 + row * 0.62);
      for (var i = 0; i <= segments; i++) {
        final xRatio = i / segments;
        final x = xRatio * size.width;
        final wave = math.sin(xRatio * math.pi * (2.0 + row * 2.0) + time * 0.54 + layer * 0.62);
        final detail = math.sin(xRatio * 17.0 - time * 0.31 + layer * 1.4);
        final y = baseline + wave * amplitude * (0.58 + row * 0.14) + detail * height * (0.012 + energy * 0.005);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      _drawNeonPath(canvas, path, palette.colors[layer % 4], 0.85 + (layer % 3) * 0.2);
    }
  }

  void _paintBloom(Canvas canvas, Size size, double time, double energy, double transient) {
    final center = Offset(
      size.width * (0.5 + math.sin(time * 0.16) * 0.055),
      size.height * (0.49 + math.cos(time * 0.13) * 0.045),
    );
    final radius = math.min(size.width, size.height) * (0.33 + energy * 0.035 + transient * 0.04);
    final petals = size.shortestSide > 900 ? 14 : 12;
    final samples = (size.width / 7).round().clamp(96, 320);
    for (var layer = 0; layer < 5; layer++) {
      final path = Path();
      final rotation = time * (0.08 + layer * 0.014) * (layer.isEven ? 1 : -1);
      for (var i = 0; i <= samples; i++) {
        final angle = i / samples * math.pi * 2;
        final petal = 0.57 + 0.34 * math.cos(petals * angle + rotation + layer * 0.43);
        final ripple = 0.06 * math.sin(angle * 3 - time * 0.23 + layer);
        final r = radius * (0.42 + layer * 0.125) * (petal + ripple);
        final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      final color = palette.colors[layer % 4];
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.14), palette.colors[(layer + 1) % 4].withValues(alpha: 0.012)],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2)),
      );
      _drawNeonPath(canvas, path, color, 1 + layer * 0.12);
    }

    final coreRadius = math.min(size.width, size.height) * (0.035 + transient * 0.02);
    canvas.drawCircle(
      center,
      coreRadius * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.colors[0].withValues(alpha: 0.8), palette.colors[1].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius * 1.8)),
    );
    canvas.drawCircle(center, coreRadius * 0.42, Paint()..color = Colors.white.withValues(alpha: 0.76));
  }

  void _paintOrbitals(Canvas canvas, Size size, double time, double energy, double transient) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final base = math.min(size.width, size.height) * (0.2 + energy * 0.025 + transient * 0.03);
    final samples = (size.width / 9).round().clamp(80, 280);
    for (var orbit = 0; orbit < 7; orbit++) {
      final path = Path();
      final rx = base * (0.55 + orbit * 0.22);
      final ry = base * (0.34 + orbit * 0.13);
      final rotation = time * (0.11 + orbit * 0.017) * (orbit.isEven ? 1 : -1);
      for (var i = 0; i <= samples; i++) {
        final angle = i / samples * math.pi * 2;
        final wobble = 1 + 0.035 * math.sin(angle * 3 + time * 0.33 + orbit * 1.6);
        final local = Offset(math.cos(angle) * rx * wobble, math.sin(angle) * ry * wobble);
        final c = math.cos(rotation);
        final s = math.sin(rotation);
        final point = center + Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      final color = palette.colors[orbit % 4];
      _drawNeonPath(canvas, path, color, 0.85 + (orbit % 3) * 0.22);

      for (var moon = 0; moon < 2; moon++) {
        final angle = time * (0.32 + orbit * 0.026) * (moon == 0 ? 1 : -1) + orbit * 1.83 + moon * math.pi;
        final local = Offset(math.cos(angle) * rx, math.sin(angle) * ry);
        final c = math.cos(rotation);
        final s = math.sin(rotation);
        final point = center + Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
        final dotRadius = math.max(1.6, size.shortestSide * (0.003 + transient * 0.002));
        canvas.drawCircle(point, dotRadius * 2.4, Paint()..color = color.withValues(alpha: 0.13));
        canvas.drawCircle(point, dotRadius, Paint()..color = color.withValues(alpha: 0.96));
      }
    }

    canvas.drawCircle(center, base * 0.15, Paint()..color = palette.colors[0].withValues(alpha: 0.35));
    canvas.drawCircle(center, base * 0.055, Paint()..color = Colors.white.withValues(alpha: 0.86));
  }

  void _paintPrism(Canvas canvas, Size size, double time, double energy, double transient) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = math.min(size.width, size.height) * (0.39 + energy * 0.035 + transient * 0.035);
    final sectors = size.width > 900 ? 24 : 18;
    final bands = 7;
    final step = math.pi * 2 / sectors;
    final turn = time * 0.075;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, size.shortestSide / 1200);

    for (var sector = 0; sector < sectors; sector++) {
      final a0 = sector * step + turn;
      final a1 = a0 + step;
      for (var band = 0; band < bands; band++) {
        final inner = maxRadius * (0.07 + band * 0.128);
        final outer = maxRadius * (0.07 + (band + 1) * 0.128);
        final middle = (a0 + a1) * 0.5 + 0.065 * math.sin(time * 0.2 + sector * 0.7 + band);
        final p0 = center + Offset(math.cos(a0) * inner, math.sin(a0) * inner);
        final p1 = center + Offset(math.cos(middle) * outer, math.sin(middle) * outer);
        final p2 = center + Offset(math.cos(a1) * inner, math.sin(a1) * inner);
        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(center.dx, center.dy, p1.dx, p1.dy)
          ..quadraticBezierTo(center.dx, center.dy, p2.dx, p2.dy)
          ..close();
        final color = palette.colors[(sector + band * 2) % 4];
        final shimmer = 0.035 + 0.07 * (0.5 + 0.5 * math.sin(time * 0.34 + sector + band * 1.4));
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: shimmer));
        outline
          ..color = color.withValues(alpha: 0.48 + transient * 0.18)
          ..strokeWidth = math.max(0.75, size.shortestSide / 1150);
        canvas.drawPath(path, outline);
      }
    }

    final core = math.min(size.width, size.height) * (0.035 + transient * 0.018);
    canvas.drawCircle(center, core * 2.1, Paint()..color = palette.colors[1].withValues(alpha: 0.18));
    canvas.drawCircle(center, core * 0.55, Paint()..color = Colors.white.withValues(alpha: 0.78));
  }

  void _paintTunnel(Canvas canvas, Size size, double time, double energy, double transient) {
    final center = Offset(
      size.width * (0.5 + 0.07 * math.sin(time * 0.12)),
      size.height * (0.49 + 0.055 * math.cos(time * 0.16)),
    );
    final base = math.min(size.width, size.height) * (0.58 + energy * 0.035 + transient * 0.055);
    final speed = time * 0.22;
    final rings = size.shortestSide > 900 ? 22 : 16;
    final samples = 128;
    for (var ring = 0; ring < rings; ring++) {
      final depth = _fract(ring / rings + speed);
      final radius = base * (0.055 + depth * 0.92);
      final path = Path();
      for (var i = 0; i <= samples; i++) {
        final angle = i / samples * math.pi * 2;
        final facet = 1 + 0.045 * math.cos(angle * 8 + time * 0.14 - depth * 4);
        final point =
            center +
            Offset(math.cos(angle) * radius * facet, math.sin(angle) * radius * facet * size.height / size.width);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      final color = palette.colors[ring % 4];
      final focus = 0.24 + 0.72 * (1 - depth);
      _drawNeonPath(canvas, path, color.withValues(alpha: focus), 0.7 + depth * 1.15);
    }

    final rays = size.width > 900 ? 64 : 40;
    final rayPaint = Paint()..strokeWidth = math.max(0.7, size.shortestSide / 1300);
    for (var ray = 0; ray < rays; ray++) {
      final angle = ray / rays * math.pi * 2 + time * 0.025;
      final end = center + Offset(math.cos(angle) * base, math.sin(angle) * base * size.height / size.width);
      rayPaint.color = palette.colors[ray % 4].withValues(alpha: ray.isEven ? 0.17 : 0.09);
      canvas.drawLine(center, end, rayPaint);
    }
    canvas.drawCircle(
      center,
      math.min(size.width, size.height) * 0.025,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  void _paintTrackMap(Canvas canvas, Size size, double time, double energy) {
    const top = 0.19;
    const bottom = 0.82;
    final centerY = size.height * 0.51;
    final count = math.min(192, math.max(36, (size.width / 10).round()));
    final barWidth = math.min(7.0, size.width / (count * 1.65));
    final gap = (size.width - count * barWidth) / (count + 1);
    final maxHeight = size.height * ((bottom - top) * 0.5);
    final profileLevels = profile?.levelsDb ?? const <double>[];
    final playProgress = frame.value.progress.clamp(0.0, 1.0).toDouble();
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = palette.outline
        ..strokeWidth = 1,
    );

    for (var i = 0; i < count; i++) {
      final ratio = count == 1 ? 0.0 : i / (count - 1);
      final level = profileLevels.isEmpty
          ? (0.23 + 0.09 * math.sin(i * 0.27 + time * 0.22 + energy))
          : _normalizedLevel(_sample(profileLevels, ratio));
      final height = math.max(2.5, maxHeight * (0.07 + level * 0.92));
      final left = gap + i * (barWidth + gap);
      final rect = Rect.fromLTWH(left, centerY - height, barWidth, height * 2);
      final played = ratio <= playProgress;
      final color = palette.colors[played ? 0 : 2].withValues(alpha: played ? 0.92 : 0.27);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)), Paint()..color = color);
      if (barWidth > 3 && played && level > 0.58) {
        canvas.drawCircle(
          Offset(left + barWidth / 2, centerY - height),
          1.1,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }

    final playheadX = size.width * playProgress;
    final playhead = Paint()
      ..color = palette.colors[1].withValues(alpha: 0.9)
      ..strokeWidth = math.max(1.1, size.shortestSide / 900);
    canvas.drawLine(Offset(playheadX, size.height * top), Offset(playheadX, size.height * bottom), playhead);
    canvas.drawCircle(Offset(playheadX, size.height * top), math.max(2.5, size.shortestSide / 250), playhead);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          math.max(size.width, size.height) * 0.76,
          [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
          const [0.43, 1],
        ),
    );
  }

  void _drawNeonPath(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width * 5.5
        ..color = color.withValues(alpha: 0.055),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width * 2.2
        ..color = color.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: 0.88),
    );
  }

  static double _sample(List<double> values, double ratio) {
    final at = ratio.clamp(0.0, 1.0).toDouble() * (values.length - 1);
    final lower = at.floor();
    final upper = (lower + 1).clamp(0, values.length - 1);
    final start = values[lower].isFinite ? values[lower] : -72;
    final end = values[upper].isFinite ? values[upper] : -72;
    return start + (end - start) * (at - lower);
  }

  static double _normalizedLevel(double db) => ((db + 72) / 62).clamp(0.035, 1.0).toDouble();

  static double _fract(double value) => value - value.floorToDouble();

  @override
  bool shouldRepaint(covariant MusicVisualizerPainter oldDelegate) =>
      !identical(oldDelegate.frame, frame) ||
      oldDelegate.preset != preset ||
      oldDelegate.palette.background != palette.background ||
      oldDelegate.palette.backgroundGlow != palette.backgroundGlow ||
      !listEquals(oldDelegate.palette.colors, palette.colors) ||
      oldDelegate.palette.outline != palette.outline ||
      !identical(oldDelegate.profile, profile);
}
