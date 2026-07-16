import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/library_management_sheet.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

Future<({int Function() selects, int Function() backs})> _pumpLibraryManagementLauncher(WidgetTester tester) async {
  final librariesProvider = LibrariesProvider();
  await librariesProvider.updateLibraryOrder([
    const MediaLibrary(id: 'movies', backend: MediaBackend.plex, title: 'Movies', kind: MediaKind.movie),
  ]);
  addTearDown(librariesProvider.dispose);

  final hiddenLibrariesProvider = HiddenLibrariesProvider();
  await hiddenLibrariesProvider.ensureInitialized();
  addTearDown(hiddenLibrariesProvider.dispose);

  var underlyingSelects = 0;
  var underlyingBacks = 0;

  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Focus(
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent && event.logicalKey.isSelectKey) underlyingSelects++;
                if (event is KeyDownEvent && event.logicalKey.isBackKey) underlyingBacks++;
                return KeyEventResult.ignored;
              },
              child: OverlaySheetHost(
                child: Scaffold(
                  body: Center(
                    child: Builder(
                      builder: (context) => ElevatedButton(
                        autofocus: true,
                        onPressed: () => showLibraryManagementSheet(context),
                        child: const Text('Open library management'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (selects: () => underlyingSelects, backs: () => underlyingBacks);
}

Future<void> _openScanConfirmation(WidgetTester tester) async {
  // Switch from the desktop pointer default to keyboard mode, then activate the
  // focused launcher using the same key path as a keyboard/remote user.
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();

  expect(find.text(t.libraries.manageLibraries), findsOneWidget);

  // The sheet owns one focus node for its virtual row/column navigation. Move
  // from the row to its options column and open the real AppMenuSheet.
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();

  expect(find.text(t.libraries.scanLibraryFiles), findsOneWidget);

  // The hosted menu focuses its first entry in keyboard mode. Selecting it
  // must close the whole hosted sheet before presenting the confirmation.
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text(t.libraries.manageLibraries), findsNothing);
  expect(find.text(t.libraries.scanLibraryFiles), findsNothing);
  expect(OverlaySheetController.openSheetCount.value, 0);

  final dialogElement = tester.element(find.byType(AlertDialog));
  final primaryFocusContext = FocusManager.instance.primaryFocus?.context;
  var dialogOwnsPrimaryFocus = false;
  primaryFocusContext?.visitAncestorElements((element) {
    if (identical(element, dialogElement)) {
      dialogOwnsPrimaryFocus = true;
      return false;
    }
    return true;
  });
  expect(dialogOwnsPrimaryFocus, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
    TvDetectionService.setForceTVSync(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  for (final interaction in [
    (name: 'Enter', key: LogicalKeyboardKey.enter),
    (name: 'Back', key: LogicalKeyboardKey.escape),
  ]) {
    testWidgets('${interaction.name} is handled by confirmation after the hosted action sheet closes', (tester) async {
      final underlyingActions = await _pumpLibraryManagementLauncher(tester);
      await _openScanConfirmation(tester);

      // Ignore launcher/menu navigation. From this point onward, neither key
      // may reach the underlying page while the modal confirmation has focus.
      final selectsBeforeDialogAction = underlyingActions.selects();
      final backsBeforeDialogAction = underlyingActions.backs();

      await tester.sendKeyEvent(interaction.key);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Open library management'), findsOneWidget);
      expect(underlyingActions.selects(), selectsBeforeDialogAction);
      expect(underlyingActions.backs(), backsBeforeDialogAction);
      expect(OverlaySheetController.openSheetCount.value, 0);
    });
  }
}
