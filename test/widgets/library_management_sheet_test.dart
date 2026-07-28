import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/library_management_sheet.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/multi_server_fixtures.dart';

import '../test_helpers/prefs.dart';

const _qualifiedLibrary = MediaLibrary(
  id: 'shared-section',
  backend: MediaBackend.plex,
  title: 'Movies',
  kind: MediaKind.movie,
  serverId: 'server-a',
);

Future<({int Function() selects, int Function() backs})> _pumpLibraryManagementLauncher(
  WidgetTester tester, {
  MediaLibrary library = _qualifiedLibrary,
  MultiServerProvider? multiServerProvider,
}) async {
  final librariesProvider = LibrariesProvider();
  await librariesProvider.updateLibraryOrder([library]);
  addTearDown(librariesProvider.dispose);

  final hiddenLibrariesProvider = HiddenLibrariesProvider();
  await hiddenLibrariesProvider.ensureInitialized();
  addTearDown(hiddenLibrariesProvider.dispose);

  final fallbackManager = multiServerProvider == null ? MultiServerManager() : null;
  final effectiveMultiServerProvider = multiServerProvider ?? testMultiServerProvider(fallbackManager!);
  if (fallbackManager != null) {
    addTearDown(() {
      effectiveMultiServerProvider.dispose();
      fallbackManager.dispose();
    });
  }

  var underlyingSelects = 0;
  var underlyingBacks = 0;

  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: effectiveMultiServerProvider),
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

Future<void> _confirmLibraryAction(WidgetTester tester, String actionLabel) async {
  await tester.tap(find.text('Open library management'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(t.libraries.libraryOptions));
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabel));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.tap(find.text(t.common.confirm));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;

  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
    TvDetectionService.setForceTVSync(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
  tearDown(() => database.close());

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

  for (final action in ['scan', 'empty_trash']) {
    testWidgets('$action refuses an absent library owner while another Plex server is online', (tester) async {
      final harness = _LibraryActionHarness(includeOwner: false);
      addTearDown(harness.dispose);
      await _pumpLibraryManagementLauncher(tester, multiServerProvider: harness.provider);

      final label = action == 'scan' ? t.libraries.scanLibraryFiles : t.libraries.emptyTrash;
      await _confirmLibraryAction(tester, label);

      expect(harness.replacementRequests, isEmpty);
      expect(find.textContaining(t.errors.noClientAvailable), findsOneWidget);
    });

    testWidgets('$action reaches only the exact library owner with the original section id', (tester) async {
      final harness = _LibraryActionHarness(includeOwner: true);
      addTearDown(harness.dispose);
      await _pumpLibraryManagementLauncher(tester, multiServerProvider: harness.provider);

      final label = action == 'scan' ? t.libraries.scanLibraryFiles : t.libraries.emptyTrash;
      await _confirmLibraryAction(tester, label);

      expect(harness.replacementRequests, isEmpty);
      expect(harness.ownerRequests, hasLength(1));
      final expectedPath = action == 'scan'
          ? '/library/sections/shared-section/refresh'
          : '/library/sections/shared-section/emptyTrash';
      expect(harness.ownerRequests.single.url.path, expectedPath);
      final successMessage = action == 'scan'
          ? t.messages.libraryScanStarted(title: _qualifiedLibrary.title)
          : t.libraries.trashEmptied(title: _qualifiedLibrary.title);
      expect(find.text(successMessage), findsOneWidget);
    });
  }
}

class _LibraryActionHarness {
  final ownerRequests = <http.Request>[];
  final replacementRequests = <http.Request>[];
  late final MultiServerManager manager;
  late final MultiServerProvider provider;

  _LibraryActionHarness({required bool includeOwner}) {
    final replacement = testPlexClient(
      serverId: ServerId('server-b'),
      handler: (request) async {
        replacementRequests.add(request);
        return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
      },
    );
    manager = MultiServerManager()..debugRegisterClientForTesting(replacement);
    if (includeOwner) {
      final owner = testPlexClient(
        serverId: ServerId('server-a'),
        handler: (request) async {
          ownerRequests.add(request);
          return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
        },
      );
      manager.debugRegisterClientForTesting(owner);
    }
    provider = testMultiServerProvider(manager);
  }

  void dispose() {
    provider.dispose();
    manager.dispose();
  }
}
