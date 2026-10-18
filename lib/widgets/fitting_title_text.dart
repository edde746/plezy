import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/platform_detector.dart';
import '../utils/text_measure_cache.dart';

typedef _FitKey = (String, TextStyle, int, double, double, double, TextScaler, TextDirection);

/// Fitted font sizes per (text, style, maxLines, box, minFontSize, scaler,
/// direction); see [FittingTitleText._fitFontSize]. Bounded and
/// insertion-ordered: the oldest entry goes first.
final LinkedHashMap<_FitKey, double> _fittedSizes = LinkedHashMap<_FitKey, double>();
const int _maxFittedEntries = 128;

/// A title that shrinks to fit its box instead of ellipsizing.
///
/// Hero titles stand in for a clear logo, so they are given the logo's
/// height and a bounded width. The largest font size at which [text] fits
/// [maxLines] lines of that box wins, down to [minFontSize]; only a title
/// that cannot fit even at the floor is ellipsized.
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

  /// The largest font size, down to [minFontSize], at which [text] fits
  /// [maxLines] lines of the box.
  ///
  /// Shaping is the single most expensive thing a TV spotlight swap does on
  /// a low-end box, so the common case is settled without laying the title
  /// out here: the title measured on one unconstrained line is cached per
  /// text and style, and a title whose one line fits the box fits. Anything
  /// longer is laid out for real, and the answer is memoized per text, style
  /// and box so a hero's rebuilds (episode focus on TV detail, a spotlight
  /// swap back to the same item) cost a hash lookup. The search is
  /// bracketed: width scales with font size, so at `base × maxWidth /
  /// singleLineWidth` the title fits on one line, and height scales with it
  /// at a fixed line count, so the smaller of the two proportional shrinks
  /// is a fitting lower bound and the bisection only refines between it and
  /// the base size.
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

    final singleLine = cachedSingleLineTextSize(
      text,
      style: style,
      textScaler: textScaler,
      textDirection: textDirection,
    );
    if (singleLine.width <= maxWidth + 0.1 && singleLine.height <= maxHeight + 0.1) return baseFontSize;

    final key = (text, style, maxLines, maxWidth, maxHeight, minFontSize, textScaler, textDirection);
    final cached = _fittedSizes[key];
    if (cached != null) return cached;

    final fitted = _searchFontSize(
      text: text,
      style: style,
      baseFontSize: baseFontSize,
      singleLineWidth: singleLine.width,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    if (_fittedSizes.length >= _maxFittedEntries) _fittedSizes.remove(_fittedSizes.keys.first);
    _fittedSizes[key] = fitted;
    return fitted;
  }

  double _searchFontSize({
    required String text,
    required TextStyle style,
    required double baseFontSize,
    required double singleLineWidth,
    required double maxWidth,
    required double maxHeight,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
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
        return !painter.didExceedMaxLines && painter.height <= maxHeight + 0.1 && painter.width <= maxWidth + 0.1;
      }

      if (fits(baseFontSize)) return baseFontSize;
      final shrink = math.min(maxHeight / painter.height, maxWidth / singleLineWidth);

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
