import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  group('PlatformDetector.isMobile', () {
    testWidgets('returns true for iOS platform', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isMobile(context), true);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for Android platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isMobile(context), true);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns false for macOS platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isMobile(context), false);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns false for Windows platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isMobile(context), false);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns false for Linux platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.linux),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isMobile(context), false);
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('PlatformDetector.isDesktop', () {
    testWidgets('returns false for iOS platform', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isDesktop(context), false);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns false for Android platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isDesktop(context), false);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for macOS platform', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isDesktop(context), true);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for Windows platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isDesktop(context), true);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for Linux platform', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.linux),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isDesktop(context), true);
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('PlatformDetector.isTablet', () {
    testWidgets('returns true for iPad (large screen iOS)',
        (WidgetTester tester) async {
      // iPad Pro 12.9" has approximately 2732x2048 pixels with devicePixelRatio ~2
      // Diagonal in inches: sqrt(1366^2 + 1024^2) / (2 * 160 / 2.54) ≈ 13.8 inches
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1366, 1024), // Logical pixels
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isTablet(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns true for Android tablet (large screen)',
        (WidgetTester tester) async {
      // Typical Android tablet: 10" screen
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 800),
              devicePixelRatio: 1.5,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isTablet(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for iPhone (small screen iOS)',
        (WidgetTester tester) async {
      // iPhone 12 Pro: 390x844 logical pixels
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isTablet(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for Android phone (small screen)',
        (WidgetTester tester) async {
      // Typical Android phone
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isTablet(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1920, 1080),
              devicePixelRatio: 1.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isTablet(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('PlatformDetector.isPhone', () {
    testWidgets('returns true for iPhone', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isPhone(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns true for Android phone', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isPhone(context), true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for iPad', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1366, 1024),
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isPhone(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for Android tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 800),
              devicePixelRatio: 1.5,
            ),
            child: Builder(
              builder: (context) {
                expect(PlatformDetector.isPhone(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns false for desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: Builder(
            builder: (context) {
              expect(PlatformDetector.isPhone(context), false);
              return Container();
            },
          ),
        ),
      );
    });
  });
}
