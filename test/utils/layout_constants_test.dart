import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/layout_constants.dart';

void main() {
  group('ScreenBreakpoints boundaries', () {
    test('isWideTabletOrLarger: w ≥ 900', () {
      expect(ScreenBreakpoints.isWideTabletOrLarger(899.9), isFalse);
      expect(ScreenBreakpoints.isWideTabletOrLarger(900), isTrue);
      expect(ScreenBreakpoints.isWideTabletOrLarger(5000), isTrue);
    });
  });
}
