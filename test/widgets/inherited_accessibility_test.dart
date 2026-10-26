import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_accessibility.dart';
import 'package:plezy/widgets/hero_hub_section.dart';
import 'package:plezy/widgets/horizontal_scroll_with_arrows.dart';
import 'package:plezy/widgets/music/equalizer_icon.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

Widget _shell(Widget child, {bool accessibleNavigation = false}) => InputModeTracker(
  child: MaterialApp(
    theme: monoTheme(MonoPalette.dark),
    home: MediaQuery(
      data: MediaQueryData(size: const Size(1280, 800), accessibleNavigation: accessibleNavigation),
      child: AppAccessibility(child: child),
    ),
  ),
);

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(false);
  });
  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('reduced motion stops the inherited now-playing animation when toggled', (tester) async {
    await tester.pumpWidget(_shell(const EqualizerIcon(animate: true, color: Colors.white)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await SettingsService.instance.write(SettingsService.reduceMotion, true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('horizontal library navigation jumps safely with zero-duration motion tokens', (tester) async {
    await SettingsService.instance.write(SettingsService.reduceMotion, true);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _shell(
        Scaffold(
          body: SizedBox(
            width: 400,
            height: 180,
            child: HorizontalScrollWithArrows(
              controller: controller,
              builder: (scroll) => ListView(
                controller: scroll,
                scrollDirection: Axis.horizontal,
                children: List.generate(8, (i) => SizedBox(width: 160, child: Text('Book $i'))),
              ),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(HorizontalScrollWithArrows)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.chevron_right_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.offset, greaterThan(0));
    expect(controller.position.isScrollingNotifier.value, isFalse);
    await mouse.removePointer();
  });

  for (final screenReader in [false, true]) {
    testWidgets('home hero stays still and keeps manual paging (screen reader: $screenReader)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await SettingsService.instance.write(SettingsService.reduceMotion, !screenReader);
      await tester.pumpWidget(
        _shell(
          Scaffold(
            body: HeroHubSection(
              hub: MediaHub(
                id: 'books',
                title: 'Books',
                type: 'movie',
                heroStyle: true,
                items: [
                  testMediaItem(id: 'one', title: 'First'),
                  testMediaItem(id: 'two', title: 'Second'),
                ],
              ),
              showBackdrop: false,
              onVerticalNavigation: (_) => false,
            ),
          ),
          accessibleNavigation: screenReader,
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester.widget<PageView>(find.byType(PageView)).controller!;
      await tester.pump(const Duration(seconds: 10));
      expect(controller.page, 0);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.page, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('shared sheets open and close immediately with reduced motion', (tester) async {
    await SettingsService.instance.write(SettingsService.reduceMotion, true);
    late OverlaySheetController sheets;
    await tester.pumpWidget(
      _shell(
        OverlaySheetHost(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                sheets = OverlaySheetController.of(context);
                return TextButton(
                  onPressed: () => sheets.show<void>(builder: (_) => const SizedBox(height: 200, child: Text('Sheet'))),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    final position = tester.getTopLeft(find.text('Sheet'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('Sheet')), position);
    sheets.close();
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling reduced motion during a sheet close still completes its result', (tester) async {
    late OverlaySheetController sheets;
    Future<String?>? result;
    await tester.pumpWidget(
      _shell(
        OverlaySheetHost(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                sheets = OverlaySheetController.of(context);
                return TextButton(
                  onPressed: () =>
                      result = sheets.show<String>(builder: (_) => const SizedBox(height: 200, child: Text('Sheet'))),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    sheets.close('closed');
    await tester.pump(const Duration(milliseconds: 50));
    await SettingsService.instance.write(SettingsService.reduceMotion, true);
    await tester.pumpAndSettle();
    expect(sheets.isOpen, isFalse);
    expect(await result, 'closed');
  });
}
