import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/sheets/subtitle_search_sheet.dart';

import '../test_helpers/theme.dart';

void main() {
  group('resolveSubtitleSearchLanguageCode', () {
    test('prefers saved language over system language', () {
      expect(resolveSubtitleSearchLanguageCode(savedLanguageCode: 'fr', systemLocale: const Locale('nl')), 'fr');
    });

    test('normalizes saved locale or three-letter language', () {
      expect(resolveSubtitleSearchLanguageCode(savedLanguageCode: 'pt_BR', systemLocale: const Locale('nl')), 'pt');
      expect(resolveSubtitleSearchLanguageCode(savedLanguageCode: 'eng', systemLocale: const Locale('nl')), 'en');
    });

    test('falls back to system language when saved language is invalid', () {
      expect(resolveSubtitleSearchLanguageCode(savedLanguageCode: 'zz', systemLocale: const Locale('nl')), 'nl');
    });

    test('falls back to English when saved and system languages are invalid', () {
      expect(resolveSubtitleSearchLanguageCode(savedLanguageCode: 'zz', systemLocale: const Locale('xx')), 'en');
    });
  });

  group('sheet geometry', () {
    setUp(() {
      LocaleSettings.setLocaleSync(AppLocale.en);
      // The 720 assertion below is the desktop-window ceiling, so pin both
      // gates it reads rather than inheriting the host OS.
      PlatformDetector.debugSetIsDesktopOSOverride(true);
      TvDetectionService.debugSetAppleTVOverride(false);
    });

    tearDown(() {
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      TvDetectionService.debugSetAppleTVOverride(null);
    });

    testWidgets('search body keeps a stable height so the focused field cannot slide', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpSearchSheet(tester);

      // No MultiServerProvider, so the search resolves to no client and the
      // results area is empty. A shrink-wrapping body would collapse here.
      final emptyHeight = _sheetHeight(tester);
      final fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
      expect(emptyHeight, 720, reason: 'search surface fills the windowed height ceiling');

      // Switching to the language picker and filtering it down to a couple of
      // matches must not move the geometry either.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), emptyHeight);

      await tester.enterText(find.byType(TextField), 'zulu');
      await tester.pumpAndSettle();
      expect(find.text('Zulu'), findsOneWidget);
      expect(_sheetHeight(tester), emptyHeight, reason: 'per-keystroke match count must not resize the sheet');
      expect(tester.getTopLeft(find.byType(TextField)).dy, fieldTop);
    });
  });
}

/// Height of the sheet box the host lays out, i.e. what the user sees.
double _sheetHeight(WidgetTester tester) {
  return tester.getSize(find.descendant(of: find.byType(OverlaySheetHost), matching: find.byType(AnimatedSize))).height;
}

Future<void> _pumpSearchSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: OverlaySheetHost(
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => OverlaySheetController.of(context).show<void>(
                builder: (_) => const SubtitleSearchSheet(ratingKey: '1', serverId: 'server'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
