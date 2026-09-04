import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/fitting_title_text.dart';

const _style = TextStyle(fontSize: 40, letterSpacing: 0, wordSpacing: 0);

Future<double> _fittedSize(WidgetTester tester, String text, {required double width, required double height}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: FittingTitleText(text, style: _style),
        ),
      ),
    ),
  );
  return tester.widget<Text>(find.text(text)).style!.fontSize!;
}

/// Whether [text] at [fontSize], wrapped to two lines like the widget does,
/// fits [height] — the widget's own definition of fitting.
bool _fits(String text, double fontSize, {required double width, required double height}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: _style.copyWith(fontSize: fontSize),
    ),
    maxLines: 2,
    ellipsis: '\u2026',
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final fits = painter.height <= height + 0.1;
  painter.dispose();
  return fits;
}

void main() {
  testWidgets('keeps the base size when two lines fit the box', (tester) async {
    expect(await _fittedSize(tester, 'ABCDE', width: 400, height: 100), 40);
    // Width never shrinks the title: a too-long line is ellipsized instead.
    expect(await _fittedSize(tester, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', width: 50, height: 100), 40);
  });

  testWidgets('a box shorter than two lines gets the largest size that still fits', (tester) async {
    for (final (text, width, height) in [
      ('ABCDE FGHIJ', 50.0, 8.0), // one line beats two: 11 chars on one line at ~4.5 > two lines at 4
      ('ABCDE FGHIJ', 50.0, 20.0), // two lines at ~10, bounded by the line width
      ('The Lord of the Rings: The Return of the King', 300.0, 60.0),
    ]) {
      final size = await _fittedSize(tester, text, width: width, height: height);
      expect(size, lessThan(40), reason: '$text in ${width}x$height');
      expect(
        _fits(text, size, width: width, height: height),
        isTrue,
        reason: '$text at $size must fit',
      );
      expect(
        _fits(text, size + 0.5, width: width, height: height),
        isFalse,
        reason: '$text at $size is not maximal',
      );
    }
  });

  testWidgets('never goes below the minimum size', (tester) async {
    expect(await _fittedSize(tester, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', width: 5, height: 0.5), 1);
  });
}
