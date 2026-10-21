import 'package:flutter/material.dart';

import '../theme/mono_theme.dart';
import '../theme/mono_tokens.dart';

/// A theme at a glance: its page, a card with text, and the accent. A null
/// [palette] is System, drawn as Light and Dark halves.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.palette, this.size = 36});

  final MonoPalette? palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.25);
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: tokens(context).outline),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(painter: _PalettePainter(palette)),
      ),
    );
  }
}

class _PalettePainter extends CustomPainter {
  const _PalettePainter(this.palette);

  final MonoPalette? palette;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = this.palette;
    if (palette != null) {
      _paintPalette(canvas, size, palette);
      return;
    }
    _paintPalette(canvas, size, MonoPalette.light);
    canvas.save();
    canvas.clipPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
    );
    _paintPalette(canvas, size, MonoPalette.dark);
    canvas.restore();
  }

  static void _paintPalette(Canvas canvas, Size size, MonoPalette p) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = p.bg);
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.44, w * 0.68, h * 0.40),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(card, Paint()..color = p.surface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = p.outline
        ..style = PaintingStyle.stroke,
    );
    final bar = Radius.circular(h * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.54, w * 0.40, h * 0.07), bar),
      Paint()..color = p.text,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.68, w * 0.26, h * 0.06), bar),
      Paint()..color = p.textMuted,
    );
    canvas.drawCircle(Offset(w * 0.30, h * 0.24), w * 0.11, Paint()..color = p.accent);
  }

  @override
  bool shouldRepaint(_PalettePainter oldDelegate) => oldDelegate.palette != palette;
}

/// One colour as a dot, over a checkerboard so translucency shows.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color, this.size = 28});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens(context).outline),
      ),
      child: ClipOval(child: CustomPaint(painter: _ColorDotPainter(color))),
    );
  }
}

class _ColorDotPainter extends CustomPainter {
  const _ColorDotPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a < 1) {
      final cell = size.width / 4;
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
      final dark = Paint()..color = const Color(0xFFBDBDBD);
      for (var row = 0; row < 4; row++) {
        for (var column = row.isEven ? 0 : 1; column < 4; column += 2) {
          canvas.drawRect(Rect.fromLTWH(column * cell, row * cell, cell, cell), dark);
        }
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ColorDotPainter oldDelegate) => oldDelegate.color != color;
}
