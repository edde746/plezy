import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/platform_detector.dart';
import '../utils/text_measure_cache.dart';

class FittingTitleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final AlignmentGeometry alignment;
  final double minFontSize;

  const FittingTitleText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.alignment = Alignment.centerLeft,
    this.minFontSize = 1,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    if (PlatformDetector.isAutomotive()) {
      return Align(
        alignment: alignment,
        child: Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow, textAlign: textAlign),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        var fittedStyle = baseStyle;
        if (constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0) {
          fittedStyle = baseStyle.copyWith(
            fontSize: _fitFontSize(
              text: text,
              style: baseStyle,
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          );
        }

        return Align(
          alignment: alignment,
          child: Text(text, style: fittedStyle, maxLines: maxLines, overflow: overflow, textAlign: textAlign),
        );
      },
    );
  }

  /// Sizes that differ by less than this are indistinguishable on screen, so
  /// the bisection stops there instead of running a fixed iteration count.
  static const double _fontSizeTolerance = 0.25;

  /// The largest font size, down to [minFontSize], at which [text] fits the
  /// box.
  ///
  /// The box can only overflow vertically: [Text] wraps and ellipsizes at
  /// [maxLines], so a title fits whenever [maxLines] lines of the base style
  /// do. That is settled from one cached one-glyph line height, without
  /// shaping the title — which the render tree is about to do anyway and
  /// which is the single most expensive thing a TV spotlight swap does on a
  /// low-end box. Only a box shorter than [maxLines] lines needs the search,
  /// and it is bracketed: layout height scales with the font size at a fixed
  /// line count, so the proportional shrink of the base layout is a fitting
  /// lower bound and the bisection only refines between it and the base size.
  double _fitFontSize({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final baseFontSize = style.fontSize ?? 14;
    if (baseFontSize <= minFontSize) return baseFontSize;

    final lineHeight = cachedSingleLineTextSize(
      'X',
      style: style,
      textScaler: textScaler,
      textDirection: textDirection,
    ).height;
    if (maxLines * lineHeight <= maxHeight + 0.1) return baseFontSize;

    final painter = TextPainter(
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '\u2026' : null,
      textDirection: textDirection,
      textScaler: textScaler,
      textAlign: textAlign ?? TextAlign.start,
    );
    try {
      bool fits(double fontSize) {
        painter
          ..text = TextSpan(
            text: text,
            style: style.copyWith(fontSize: fontSize),
          )
          ..layout(maxWidth: maxWidth);
        return painter.height <= maxHeight + 0.1 && painter.width <= maxWidth + 0.1;
      }

      if (fits(baseFontSize)) return baseFontSize;
      final shrink = math.min(maxHeight / painter.height, maxWidth / painter.width);

      var low = math.max(minFontSize, baseFontSize * shrink);
      if (low <= minFontSize || !fits(low)) {
        if (!fits(minFontSize)) return minFontSize;
        low = minFontSize;
      }
      var high = baseFontSize;
      while (high - low > _fontSizeTolerance) {
        final mid = (low + high) / 2;
        if (fits(mid)) {
          low = mid;
        } else {
          high = mid;
        }
      }
      return low;
    } finally {
      painter.dispose();
    }
  }
}
