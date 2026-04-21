import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/layout_constants.dart';

void main() {
  group('ScreenBreakpoints boundaries', () {
    test('isMobile: strict < 600', () {
      expect(ScreenBreakpoints.isMobile(0), isTrue);
      expect(ScreenBreakpoints.isMobile(599.9), isTrue);
      expect(ScreenBreakpoints.isMobile(600), isFalse);
    });

    test('isTablet: 600 ≤ w < 1200', () {
      expect(ScreenBreakpoints.isTablet(599.9), isFalse);
      expect(ScreenBreakpoints.isTablet(600), isTrue);
      expect(ScreenBreakpoints.isTablet(899.9), isTrue);
      expect(ScreenBreakpoints.isTablet(900), isTrue);
      expect(ScreenBreakpoints.isTablet(1199.9), isTrue);
      expect(ScreenBreakpoints.isTablet(1200), isFalse);
    });

    test('isWideTablet: 900 ≤ w < 1200', () {
      expect(ScreenBreakpoints.isWideTablet(899.9), isFalse);
      expect(ScreenBreakpoints.isWideTablet(900), isTrue);
      expect(ScreenBreakpoints.isWideTablet(1199.9), isTrue);
      expect(ScreenBreakpoints.isWideTablet(1200), isFalse);
    });

    test('isDesktop: 1200 ≤ w < 1600', () {
      expect(ScreenBreakpoints.isDesktop(1199.9), isFalse);
      expect(ScreenBreakpoints.isDesktop(1200), isTrue);
      expect(ScreenBreakpoints.isDesktop(1599.9), isTrue);
      expect(ScreenBreakpoints.isDesktop(1600), isFalse);
    });

    test('isLargeDesktop: w ≥ 1600', () {
      expect(ScreenBreakpoints.isLargeDesktop(1599.9), isFalse);
      expect(ScreenBreakpoints.isLargeDesktop(1600), isTrue);
      expect(ScreenBreakpoints.isLargeDesktop(10000), isTrue);
    });

    test('isDesktopOrLarger: w ≥ 1200', () {
      expect(ScreenBreakpoints.isDesktopOrLarger(1199.9), isFalse);
      expect(ScreenBreakpoints.isDesktopOrLarger(1200), isTrue);
      expect(ScreenBreakpoints.isDesktopOrLarger(5000), isTrue);
    });

    test('isWideTabletOrLarger: w ≥ 900', () {
      expect(ScreenBreakpoints.isWideTabletOrLarger(899.9), isFalse);
      expect(ScreenBreakpoints.isWideTabletOrLarger(900), isTrue);
      expect(ScreenBreakpoints.isWideTabletOrLarger(5000), isTrue);
    });

    test('constant values match expected thresholds', () {
      expect(ScreenBreakpoints.mobile, 600);
      expect(ScreenBreakpoints.tablet, 600);
      expect(ScreenBreakpoints.wideTablet, 900);
      expect(ScreenBreakpoints.desktop, 1200);
      expect(ScreenBreakpoints.largeDesktop, 1600);
    });

    test('partitioning: every width matches exactly one of mobile/tablet/desktop/largeDesktop', () {
      for (final w in const [0.0, 300, 599.9, 600, 899.9, 1199.9, 1200, 1599.9, 1600, 2500]) {
        final matches = [
          ScreenBreakpoints.isMobile(w.toDouble()),
          ScreenBreakpoints.isTablet(w.toDouble()) && !ScreenBreakpoints.isDesktopOrLarger(w.toDouble()),
          ScreenBreakpoints.isDesktop(w.toDouble()),
          ScreenBreakpoints.isLargeDesktop(w.toDouble()),
        ].where((b) => b).length;
        expect(matches, 1, reason: 'width $w should match exactly one tier');
      }
    });
  });
}
