import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/services/settings_service.dart' show LibraryDensity;
import 'package:vibe_stream/utils/grid_size_calculator.dart';
import 'package:vibe_stream/utils/layout_constants.dart';

/// Column count the stock [SliverGridDelegateWithMaxCrossAxisExtent] renders for
/// [crossAxisExtent]. This is the source of truth that the navigation column
/// count ([GridSizeCalculator.getColumnCount]) must match — a disagreement makes
/// dpad "down" (`index + columnCount`) land diagonally (issue #1288).
int _renderedColumnCount(double crossAxisExtent, double maxCrossAxisExtent, double spacing) {
  final delegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxCrossAxisExtent,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    childAspectRatio: 2 / 3,
  );
  final layout = delegate.getLayout(
    SliverConstraints(
      axisDirection: AxisDirection.down,
      growthDirection: GrowthDirection.forward,
      userScrollDirection: ScrollDirection.idle,
      scrollOffset: 0,
      precedingScrollExtent: 0,
      overlap: 0,
      remainingPaintExtent: 10000,
      crossAxisExtent: crossAxisExtent,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: 10000,
      remainingCacheExtent: 10000,
      cacheOrigin: 0,
    ),
  );
  return (layout as SliverGridRegularTileLayout).crossAxisCount;
}

void main() {
  group('GridSizeCalculator.getColumnCount', () {
    // crossAxisSpacing is 0 in the current layout constants, so the formula
    // reduces to ceil(crossAxisExtent / maxCrossAxisExtent).
    test('returns 1 when extent equals maxCrossAxisExtent', () {
      expect(GridSizeCalculator.getColumnCount(200, 200), 1);
    });

    test('returns 2 when extent slightly exceeds maxCrossAxisExtent', () {
      expect(GridSizeCalculator.getColumnCount(201, 200), 2);
    });

    test('rounds up partial columns', () {
      // 600 / 200 = 3 exactly
      expect(GridSizeCalculator.getColumnCount(600, 200), 3);
      // 601 / 200 = 3.005 -> ceil to 4
      expect(GridSizeCalculator.getColumnCount(601, 200), 4);
    });

    test('clamps to at least 1 column for zero/tiny widths', () {
      expect(GridSizeCalculator.getColumnCount(0, 200), 1);
      expect(GridSizeCalculator.getColumnCount(10, 200), 1);
    });

    test('clamps to at most 100 columns', () {
      // 100000 / 100 = 1000 -> clamped to 100
      expect(GridSizeCalculator.getColumnCount(100000, 100), 100);
    });

    test('uses GridLayoutConstants.crossAxisSpacing in the formula', () {
      // The formula adds crossAxisSpacing to the denominator only (matching the
      // stock grid delegate), and that constant is currently 0. If it ever
      // becomes non-zero, this test forces a rethink.
      expect(GridLayoutConstants.crossAxisSpacing, 0);
      // Identity-ish: extent = max -> 1 column.
      expect(GridSizeCalculator.getColumnCount(200, 200), 1);
    });
  });

  group('GridSizeCalculator.getColumnCount matches the rendered grid', () {
    // The grid is laid out by the stock SliverGridDelegateWithMaxCrossAxisExtent;
    // navigation uses getColumnCount. When they disagree the dpad "down" target
    // (index + columnCount) lands one column to the right — the diagonal scroll
    // of issue #1288. Grid spacing is only non-zero in TV full-card layouts,
    // which is why the bug is TV-only; sweep the non-zero spacings here.
    for (final spacing in <double>[8, 12, 16]) {
      test('equals the stock delegate column count across widths (spacing=$spacing)', () {
        for (final maxExtent in <double>[120, 175, 200, 240]) {
          for (var w = maxExtent; w <= 3000; w += 1) {
            expect(
              GridSizeCalculator.getColumnCount(w, maxExtent, crossAxisSpacing: spacing),
              _renderedColumnCount(w, maxExtent, spacing),
              reason: 'width=$w maxExtent=$maxExtent spacing=$spacing would scroll diagonally',
            );
          }
        }
      });
    }

    test('regression: #1288 diagonal case (200px cells, 8px spacing, 1040px wide)', () {
      // The old formula gave ceil((1040 + 8) / 208) = 6, but the grid renders
      // ceil(1040 / 208) = 5, so "down" jumped a column right. Must be 5.
      expect(GridSizeCalculator.getColumnCount(1040, 200, crossAxisSpacing: 8), 5);
      expect(_renderedColumnCount(1040, 200, 8), 5);
    });
  });

  group('GridSizeCalculator.isFirstRow / isFirstColumn', () {
    test('isFirstRow: true for indices < columnCount', () {
      expect(GridSizeCalculator.isFirstRow(0, 4), isTrue);
      expect(GridSizeCalculator.isFirstRow(3, 4), isTrue);
      expect(GridSizeCalculator.isFirstRow(4, 4), isFalse);
      expect(GridSizeCalculator.isFirstRow(7, 4), isFalse);
    });

    test('isFirstColumn: true at column 0 of every row', () {
      expect(GridSizeCalculator.isFirstColumn(0, 4), isTrue);
      expect(GridSizeCalculator.isFirstColumn(4, 4), isTrue);
      expect(GridSizeCalculator.isFirstColumn(8, 4), isTrue);
      expect(GridSizeCalculator.isFirstColumn(1, 4), isFalse);
      expect(GridSizeCalculator.isFirstColumn(5, 4), isFalse);
    });
  });

  group('GridSizeCalculator.getMaxCrossAxisExtent', () {
    Future<void> pumpWithWidth(WidgetTester tester, double width, void Function(BuildContext) onContext) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (ctx) {
              onContext(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
    }

    testWidgets('mobile width (< 600): extent in [100, 200] range', (tester) async {
      late double extent;
      await pumpWithWidth(tester, 360, (ctx) {
        extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, LibraryDensity.defaultValue);
      });
      // f at default(3) = (3-1)/(5-1) = 0.5 -> 100 + (200-100)*0.5 = 150
      expect(extent, 150);
    });

    testWidgets('tablet width (600-1199): extent in [120, 230] range', (tester) async {
      late double extent;
      await pumpWithWidth(tester, 800, (ctx) {
        extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, LibraryDensity.defaultValue);
      });
      // 120 + 110 * 0.5 = 175
      expect(extent, 175);
    });

    testWidgets('desktop width (>=1200): extent in [140, 280] range', (tester) async {
      late double extent;
      await pumpWithWidth(tester, 1400, (ctx) {
        extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, LibraryDensity.defaultValue);
      });
      // 140 + 140 * 0.5 = 210
      expect(extent, 210);
    });

    testWidgets('density 1 returns the compact (min) extent', (tester) async {
      late double extent;
      await pumpWithWidth(tester, 360, (ctx) {
        extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, 1);
      });
      // f = 0 -> 100
      expect(extent, 100);
    });

    testWidgets('density 5 returns the comfortable (max) extent', (tester) async {
      late double extent;
      await pumpWithWidth(tester, 360, (ctx) {
        extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, 5);
      });
      // f = 1 -> 200
      expect(extent, 200);
    });

    testWidgets('extent grows monotonically with density on a fixed width', (tester) async {
      final extents = <double>[];
      for (final d in [1, 2, 3, 4, 5]) {
        late double e;
        await pumpWithWidth(tester, 800, (ctx) {
          e = GridSizeCalculator.getMaxCrossAxisExtent(ctx, d);
        });
        extents.add(e);
      }
      for (var i = 1; i < extents.length; i++) {
        expect(
          extents[i],
          greaterThan(extents[i - 1]),
          reason: 'density $i should yield larger extent than density ${i - 1}',
        );
      }
    });
  });

  group('GridSizeCalculator.getCellWidth', () {
    testWidgets('cell width = availableWidth / column count', (tester) async {
      late double width;
      late double extent;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 800)),
          child: Builder(
            builder: (ctx) {
              extent = GridSizeCalculator.getMaxCrossAxisExtent(ctx, LibraryDensity.defaultValue);
              width = GridSizeCalculator.getCellWidth(800, ctx, LibraryDensity.defaultValue);
              return const SizedBox();
            },
          ),
        ),
      );
      // tablet path: 175 max extent -> ceil(800 / 175) = 5 columns -> 800 / 5 = 160
      expect(extent, 175);
      expect(width, 160);
    });

    testWidgets('cell width never exceeds available width', (tester) async {
      late double width;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(150, 800)),
          child: Builder(
            builder: (ctx) {
              width = GridSizeCalculator.getCellWidth(150, ctx, LibraryDensity.defaultValue);
              return const SizedBox();
            },
          ),
        ),
      );
      // On 150-wide mobile, max extent is 150, columns clamp to 1, cell = 150.
      expect(width, lessThanOrEqualTo(150));
    });
  });
}
