import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../focus/focus_theme.dart';

/// Dims the content beneath it by drawing a translucent [color] quad on top,
/// as a saveLayer-free replacement for wrapping the content in
/// [AnimatedOpacity]. Widget opacity below 1.0 forces an offscreen render
/// pass every frame — a permanent GPU cost on the weak GLES devices most
/// Android TVs are — while a color-blended quad is free. Over a
/// [color]-colored underlay the result is mathematically identical to
/// `Opacity(opacity: 1 - alpha)`; over artwork it darkens toward [color]
/// instead of turning translucent.
///
/// Unlike content opacity, the quad also darkens whatever shows through
/// gaps in the content, so its rectangle boundary can read as a hard line
/// across backdrop artwork. [fadeTop]/[fadeBottom] soften that by ramping
/// the dim in over a band of pixels. The bands are gradient-shaded, which
/// costs GPU per covered pixel on low-end TVs — keep them narrow; the
/// interior stays a flat quad.
///
/// Stack this above the content (with `IgnorePointer` built in so taps pass
/// through). Animates with [FocusTheme.getAnimationDuration], so the full
/// tier fades and the reduced tier snaps, matching the [AnimatedOpacity]
/// behavior it replaces.
class AnimatedDimScrim extends StatelessWidget {
  const AnimatedDimScrim({
    super.key,
    required this.dimmed,
    required this.color,
    required this.alpha,
    this.fadeTop = 0,
    this.fadeBottom = 0,
  });

  final bool dimmed;
  final Color color;

  /// Scrim strength while [dimmed]; visually equivalent to
  /// `Opacity(opacity: 1 - alpha)` over a [color] underlay.
  final double alpha;

  /// Height of the ramp from transparent to full strength at the top edge.
  final double fadeTop;

  /// Height of the ramp from full strength back to transparent at the
  /// bottom edge.
  final double fadeBottom;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: dimmed ? alpha : 0.0),
        duration: FocusTheme.getAnimationDuration(context),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          if (value == 0) return const SizedBox.shrink();
          if (fadeTop == 0 && fadeBottom == 0) {
            return ColoredBox(color: color.withValues(alpha: value));
          }
          return CustomPaint(
            painter: _DimScrimPainter(color: color, alpha: value, fadeTop: fadeTop, fadeBottom: fadeBottom),
          );
        },
      ),
    );
  }
}

class _DimScrimPainter extends CustomPainter {
  const _DimScrimPainter({required this.color, required this.alpha, required this.fadeTop, required this.fadeBottom});

  final Color color;
  final double alpha;
  final double fadeTop;
  final double fadeBottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final full = color.withValues(alpha: alpha);
    final none = color.withValues(alpha: 0.0);
    final top = fadeTop.clamp(0.0, size.height);
    final bottom = fadeBottom.clamp(0.0, size.height - top);

    // Anti-aliasing off: adjacent translucent rects sharing an edge would
    // otherwise double-blend along the seam.
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, size.height - bottom),
      Paint()
        ..color = full
        ..isAntiAlias = false,
    );
    if (top > 0) {
      final band = Rect.fromLTRB(0, 0, size.width, top);
      canvas.drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(band.topLeft, band.bottomLeft, [none, full])
          ..isAntiAlias = false,
      );
    }
    if (bottom > 0) {
      final band = Rect.fromLTRB(0, size.height - bottom, size.width, size.height);
      canvas.drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(band.topLeft, band.bottomLeft, [full, none])
          ..isAntiAlias = false,
      );
    }
  }

  @override
  bool shouldRepaint(_DimScrimPainter oldDelegate) =>
      color != oldDelegate.color ||
      alpha != oldDelegate.alpha ||
      fadeTop != oldDelegate.fadeTop ||
      fadeBottom != oldDelegate.fadeBottom;
}
