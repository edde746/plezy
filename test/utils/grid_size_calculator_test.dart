import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart' show LibraryDensity;
import 'package:plezy/utils/grid_size_calculator.dart';
import 'package:plezy/utils/layout_constants.dart';

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
      // The formula adds crossAxisSpacing to both sides, and that constant is
      // currently 0. If it ever becomes non-zero, this test forces a rethink.
      expect(GridLayoutConstants.crossAxisSpacing, 0);
      // Identity-ish: extent = max -> 1 column.
      expect(GridSizeCalculator.getColumnCount(200, 200), 1);
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
