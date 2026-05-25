import 'package:flutter/material.dart';

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

    bool fits(double fontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: fontSize),
        ),
        maxLines: maxLines,
        ellipsis: overflow == TextOverflow.ellipsis ? '\u2026' : null,
        textDirection: textDirection,
        textScaler: textScaler,
        textAlign: textAlign ?? TextAlign.start,
      )..layout(maxWidth: maxWidth);
      final result = painter.height <= maxHeight + 0.1 && painter.width <= maxWidth + 0.1;
      painter.dispose();
      return result;
    }

    if (fits(baseFontSize)) return baseFontSize;

    if (!fits(minFontSize)) return minFontSize;

    var low = minFontSize;
    var high = baseFontSize;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
