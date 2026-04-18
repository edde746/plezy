import 'dart:math' as math;
import 'package:flutter/material.dart';

/// [GappedSliderTrackShape] without the hardcoded stop indicator dot.
class GappedTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const GappedTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) return;

    final activeColor = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    ).evaluate(enableAnimation)!;
    final inactiveColor = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    ).evaluate(enableAnimation)!;

    final Paint leftPaint, rightPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftPaint = Paint()..color = activeColor;
        rightPaint = Paint()..color = inactiveColor;
      case TextDirection.rtl:
        leftPaint = Paint()..color = inactiveColor;
        rightPaint = Paint()..color = activeColor;
    }

    final trackGap = sliderTheme.trackGap ?? 0;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final outerRadius = Radius.circular(trackRect.shortestSide / 2);
    const innerRadius = Radius.circular(2.0);
    final trackRRect = RRect.fromRectAndRadius(trackRect, outerRadius);

    final leftRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      math.max(trackRect.left, thumbCenter.dx - trackGap),
      trackRect.bottom,
      topLeft: outerRadius,
      bottomLeft: outerRadius,
      topRight: innerRadius,
      bottomRight: innerRadius,
    );

    final rightRRect = RRect.fromLTRBAndCorners(
      thumbCenter.dx + trackGap,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topRight: outerRadius,
      bottomRight: outerRadius,
      topLeft: innerRadius,
      bottomLeft: innerRadius,
    );

    final canvas = context.canvas
      ..save()
      ..clipRRect(trackRRect);

    if (thumbCenter.dx > leftRRect.left + sliderTheme.trackHeight! / 2) {
      canvas.drawRRect(leftRRect, leftPaint);
    }
    if (thumbCenter.dx < rightRRect.right - sliderTheme.trackHeight! / 2) {
      canvas.drawRRect(rightRRect, rightPaint);
    }

    canvas.restore();
  }
}
