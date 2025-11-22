import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/grid_size_calculator.dart';
import 'package:plezy/services/settings_service.dart';

void main() {
  group('GridSizeCalculator.getMaxCrossAxisExtent', () {
    testWidgets('returns desktop comfortable size for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.comfortable,
                );
                expect(result, 280);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns desktop compact size for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.compact,
                );
                expect(result, 200);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns desktop normal size for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.normal,
                );
                expect(result, 240);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns tablet comfortable size for medium screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.comfortable,
                );
                expect(result, 240);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns tablet compact size for medium screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.compact,
                );
                expect(result, 170);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns tablet normal size for medium screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.normal,
                );
                expect(result, 200);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns mobile comfortable size for small screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.comfortable,
                );
                expect(result, 200);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns mobile compact size for small screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.compact,
                );
                expect(result, 140);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns mobile normal size for small screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.normal,
                );
                expect(result, 170);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('handles exact breakpoint at 1200px',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.comfortable,
                );
                // At exactly 1200, should be tablet (not greater than desktop breakpoint)
                expect(result, 240);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('handles exact breakpoint at 600px',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(600, 800)),
            child: Builder(
              builder: (context) {
                final result = GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  LibraryDensity.comfortable,
                );
                // At exactly 600, should be mobile (not greater than tablet breakpoint)
                expect(result, 200);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('GridSizeCalculator screen type detection', () {
    testWidgets('isDesktop returns true for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isDesktop(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isDesktop returns false for medium screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isDesktop(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for medium screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isTablet(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns false for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isTablet(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns false for small screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isTablet(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isMobile returns true for small screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isMobile(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isMobile returns false for large screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1400, 900)),
            child: Builder(
              builder: (context) {
                expect(GridSizeCalculator.isMobile(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });
}
