import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/screens/settings/settings_screen.dart';
import 'package:plezy/services/background_work_diagnostics_service.dart';
import 'package:plezy/services/donation_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/file_picker_service.dart';
import 'package:plezy/services/settings_export_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/update_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late _FakeDirectoryPicker directoryPicker;
  late Directory temporaryDirectory;

  setUpAll(() {
    originalPathProvider = PathProviderPlatform.instance;
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    temporaryDirectory = await Directory.systemTemp.createTemp('plezy_settings_screen_test_');
    PathProviderPlatform.instance = FakePathProvider(temporaryDirectory);
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    directoryPicker = _FakeDirectoryPicker();
    FilePickerService.setDelegateForTesting(directoryPicker);
    await SettingsService.getInstance();
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    DownloadStorageService.resetForTesting();
    FilePickerService.setDelegateForTesting(null);
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = originalPathProvider;
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  testWidgets('system back closes Manage Libraries without popping pushed settings', (tester) async {
    final harness = await _pumpSettingsScreen(tester, pushSettingsRoute: true);
    addTearDown(() => harness.dispose(tester));
    unawaited(
      harness.libraries.updateLibraryOrder([
        const MediaLibrary(
          id: 'maestro-movies',
          backend: MediaBackend.jellyfin,
          title: 'Maestro Movies',
          kind: MediaKind.movie,
        ),
      ]),
    );
    await _pumpUi(tester);

    await tester.tap(find.text(t.libraries.manageLibraries));
    await _pumpUi(tester);
    expect(find.text('Maestro Movies'), findsOneWidget);

    // Android can dispatch one physical Back through both the focused key
    // path and Navigator.popRoute. The old modal fallback consumed one path
    // and let the other pop Settings itself.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await _pumpUi(tester);

    expect(find.text('Maestro Movies'), findsNothing, reason: 'system back dismisses the sheet');
    expect(find.text(t.settings.services), findsOneWidget, reason: 'the settings route remains current');
    expect(find.text('Settings launcher'), findsNothing, reason: 'system back must not pop the settings route');
  });

  testWidgets('migrated rows retain the shared compact row geometry and activation', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    final rows = <_MigratedRow>[
      _MigratedRow(
        title: t.settings.supportDeveloper,
        focusLabel: 'settings_donate',
        isVisible: DonationService.isEnabled,
      ),
      _MigratedRow(title: t.settings.watchTogetherRelay, focusLabel: 'settings_watch_together_relay'),
      _MigratedRow(title: t.settings.clearImageCache, focusLabel: 'settings_clear_image_cache'),
      _MigratedRow(title: t.settings.resetSettings, focusLabel: 'settings_reset_settings'),
      const _MigratedRow(title: 'Test Sentry', isVisible: kDebugMode),
      const _MigratedRow(title: 'Test ANR', isVisible: kDebugMode),
      _MigratedRow(title: t.settings.exportSettings, focusLabel: 'settings_export_settings'),
      _MigratedRow(title: t.settings.importSettings, focusLabel: 'settings_import_settings'),
      _MigratedRow(
        title: t.settings.checkForUpdates,
        focusLabel: 'settings_check_for_updates',
        isVisible: UpdateService.isUpdateCheckAvailable && UpdateService.useNativeUpdater,
        hasSubtitle: false,
      ),
    ];

    final referenceHeight = tester.getSize(_focusableTileFor(t.settings.viewLogs)).height;

    for (final row in rows) {
      final navigationTile = _navigationTileFor(row.title);
      if (!row.isVisible) {
        expect(navigationTile, findsNothing, reason: '${row.title} must honor its production gate');
        continue;
      }

      expect(navigationTile, findsOneWidget, reason: '${row.title} must use SettingNavigationTile');
      final focusableFinder = _focusableTileWithin(navigationTile);
      final focusable = tester.widget<FocusableListTile>(focusableFinder);
      final materialTile = tester.widget<ListTile>(
        find.descendant(of: focusableFinder, matching: find.byType(ListTile)),
      );

      expect(focusable.dense, isTrue, reason: '${row.title} must use the shared compact row density');
      expect(focusable.visualDensity, const VisualDensity(vertical: -3));
      expect(materialTile.dense, isTrue);
      expect(materialTile.visualDensity, const VisualDensity(vertical: -3));
      expect(focusable.onTap, isNotNull, reason: '${row.title} must remain pointer activatable');
      expect(materialTile.onTap, isNotNull);
      expect(materialTile.focusNode, isNotNull, reason: '${row.title} must remain D-pad focusable');
      expect(materialTile.focusNode!.canRequestFocus, isTrue);
      final pointerRegions = tester.widgetList<MouseRegion>(
        find.descendant(of: focusableFinder, matching: find.byType(MouseRegion)),
      );
      expect(pointerRegions.any((region) => region.cursor == SystemMouseCursors.click), isTrue);

      if (row.focusLabel != null) {
        expect(focusable.focusNode?.debugLabel, row.focusLabel);
        expect(materialTile.focusNode, same(focusable.focusNode));
      } else {
        expect(focusable.focusNode, isNull, reason: '${row.title} intentionally uses the tile-owned focus node');
      }

      if (row.hasSubtitle) {
        // Subtitle rows occupy the same vertical space as an existing standard
        // SettingNavigationTile in this screen.
        expect(tester.getSize(focusableFinder).height, referenceHeight);
      }
    }

    // Exercise both input paths against real callbacks rather than merely
    // checking that callbacks are non-null.
    final relayMaterialTile = tester.widget<ListTile>(
      find.descendant(of: _focusableTileFor(t.settings.watchTogetherRelay), matching: find.byType(ListTile)),
    );
    relayMaterialTile.focusNode!.requestFocus();
    await tester.pump();
    expect(relayMaterialTile.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpUi(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.watchTogetherRelay), findsWidgets);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await _pumpUi(tester);

    await tester.tap(find.text(t.settings.clearImageCache));
    await _pumpUi(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.clearImageCache), findsWidgets);
  });

  testWidgets('special download and generic update rows keep rich content on the shared compact row', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    expect(find.text(t.settings.plexDownloadQuality), findsOneWidget);
    expect(
      find.text(t.settings.plexDownloadQualityDescription(quality: t.videoControls.qualityOriginal)),
      findsOneWidget,
    );

    if (Platform.isIOS) {
      expect(find.text(t.settings.downloadLocationDefault), findsNothing);
    } else {
      final downloadTileFinder = _focusableTileFor(t.settings.downloadLocationDefault);
      final materialDownloadTile = tester.widget<ListTile>(
        find.descendant(of: downloadTileFinder, matching: find.byType(ListTile)),
      );
      final downloadTile = tester.widget<FocusableListTile>(downloadTileFinder);
      final subtitle = downloadTile.subtitle! as Text;

      expect(_navigationTileFor(t.settings.downloadLocationDefault), findsNothing);
      expect(materialDownloadTile.dense, isTrue);
      expect(materialDownloadTile.visualDensity, const VisualDensity(vertical: -3));
      expect(downloadTile.dense, isTrue);
      expect(downloadTile.visualDensity, const VisualDensity(vertical: -3));
      expect(downloadTile.leading, isA<AppIcon>());
      expect(downloadTile.trailing, isA<AppIcon>());
      expect(subtitle.maxLines, 2);
      expect(subtitle.overflow, TextOverflow.ellipsis);
      expect(downloadTile.onTap, isNotNull);

      await tester.tap(find.text(t.settings.downloadLocationDefault));
      await _pumpUi(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t.settings.downloadLocationDescription), findsOneWidget);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await _pumpUi(tester);
    }

    if (!UpdateService.isUpdateCheckAvailable) {
      expect(find.text(t.settings.checkForUpdates), findsNothing);
      return;
    }

    if (UpdateService.useNativeUpdater) {
      expect(_navigationTileFor(t.settings.checkForUpdates), findsOneWidget);
      return;
    }

    final updateTileFinder = _focusableTileFor(t.settings.checkForUpdates);
    final materialUpdateTile = tester.widget<ListTile>(
      find.descendant(of: updateTileFinder, matching: find.byType(ListTile)),
    );
    final updateTile = tester.widget<FocusableListTile>(updateTileFinder);

    expect(_navigationTileFor(t.settings.checkForUpdates), findsNothing);
    expect(updateTile.dense, isTrue);
    expect(materialUpdateTile.dense, isTrue);
    expect(materialUpdateTile.visualDensity, const VisualDensity(vertical: -3));
    expect(updateTile.visualDensity, const VisualDensity(vertical: -3));
    expect(updateTile.trailing, isA<AppIcon>());
    expect(updateTile.onTap, isNotNull);
    expect(find.descendant(of: updateTileFinder, matching: find.byType(LoadingIndicatorBox)), findsNothing);

    // The generic updater deliberately remains a FocusableListTile: unlike a
    // SettingNavigationTile, its trailing slot can be replaced by the progress
    // indicator and its callback disabled while a request is in flight.
    expect(materialUpdateTile.focusNode, isNotNull);
  });

  testWidgets('background downloads tile renders and opens the injected blocked status', (tester) async {
    const channel = MethodChannel('com.plezy/device.settings-background-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'getBackgroundWorkSignals' => {
          'verdict': 'blocked',
          'reasons': ['background_restricted'],
        },
        'openBackgroundSettings' => true,
        _ => null,
      };
    });
    final diagnostics = BackgroundWorkDiagnosticsService.forTesting(channel: channel);
    await diagnostics.refresh();
    final harness = await _pumpSettingsScreen(tester, backgroundWorkDiagnosticsService: diagnostics);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      await harness.dispose(tester);
      diagnostics.dispose();
    });

    expect(find.text(t.downloads.backgroundWarning.statusTile), findsOneWidget);
    expect(find.text(t.downloads.backgroundWarning.statusBlocked), findsOneWidget);

    await tester.tap(find.text(t.downloads.backgroundWarning.statusTile));
    await _pumpUi(tester);

    expect(find.text(t.downloads.backgroundWarning.sheetTitle), findsOneWidget);
  });

  testWidgets('unprobed background diagnostics stay unknown instead of claiming success', (tester) async {
    final diagnostics = BackgroundWorkDiagnosticsService.forTesting();
    final harness = await _pumpSettingsScreen(tester, backgroundWorkDiagnosticsService: diagnostics);
    addTearDown(() async {
      await harness.dispose(tester);
      diagnostics.dispose();
    });

    expect(find.text(t.downloads.backgroundWarning.statusUnknown), findsOneWidget);
    expect(find.text(t.downloads.backgroundWarning.statusOk), findsNothing);
  });

  testWidgets('background downloads tile is absent when diagnostics are unsupported', (tester) async {
    final diagnostics = BackgroundWorkDiagnosticsService.forTesting(supported: false);
    final harness = await _pumpSettingsScreen(tester, backgroundWorkDiagnosticsService: diagnostics);
    addTearDown(() async {
      await harness.dispose(tester);
      diagnostics.dispose();
    });

    expect(find.text(t.downloads.backgroundWarning.statusTile), findsNothing);
  });

  testWidgets('relay dialog rejects invalid bases without persisting them', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.watchTogetherRelay));
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField), 'ws://opaque-user@relay.example.test/path?wrong=route');
    await tester.tap(find.text(t.common.save));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.watchTogetherRelayInvalid), findsOneWidget);
    expect(SettingsService.instance.read(SettingsService.customRelayUrl), isNull);
  });

  testWidgets('relay dialog saves and reopens the canonical base', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.watchTogetherRelay));
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField), '  HTTP://Relay.Example.Test:8080/prefix///  ');
    await tester.tap(find.text(t.common.save));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(SettingsService.instance.read(SettingsService.customRelayUrl), 'http://relay.example.test:8080/prefix');

    await tester.tap(find.text(t.settings.watchTogetherRelay));
    await _pumpUi(tester);
    expect(find.widgetWithText(TextField, 'http://relay.example.test:8080/prefix'), findsOneWidget);
  });

  testWidgets('folder replacement uses the provider coordinator', (tester) async {
    final selectedDirectory = Directory('${temporaryDirectory.path}/selected-downloads');
    directoryPicker.directoryPath = selectedDirectory.path;
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await _pumpUi(tester);

    expect(harness.locationEvents, ['path:${selectedDirectory.path}', 'type:file', 'refresh']);
    expect(SettingsService.instance.read(SettingsService.customDownloadPath), selectedDirectory.path);
  });

  testWidgets('download location reset uses the provider coordinator', (tester) async {
    await SettingsService.instance.write(
      SettingsService.customDownloadPath,
      '${temporaryDirectory.path}/old-downloads',
    );
    await SettingsService.instance.write(SettingsService.customDownloadPathType, 'file');
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.downloadLocationCustom));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.resetToDefault));
    await _pumpUi(tester);

    expect(harness.locationEvents, ['path:null', 'type:null', 'refresh']);
    expect(SettingsService.instance.read(SettingsService.customDownloadPath), isNull);
  });

  testWidgets('Reset All resets download location through the provider first', (tester) async {
    await SettingsService.instance.write(
      SettingsService.customDownloadPath,
      '${temporaryDirectory.path}/old-downloads',
    );
    await SettingsService.instance.write(SettingsService.customDownloadPathType, 'file');
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.resetSettings));
    await _pumpUi(tester);
    await tester.tap(find.text(t.common.reset));
    await _pumpUi(tester);

    expect(harness.locationEvents.take(3), ['path:null', 'type:null', 'refresh']);
    expect(SettingsService.instance.read(SettingsService.customDownloadPath), isNull);
    expect(find.text(t.settings.resetSettingsSuccess), findsOneWidget);
  });

  testWidgets('cancelled directory picker remains silent and leaves the dialog retryable', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.saveFailed), findsNothing);
    expect(find.text(t.settings.downloadLocationChanged), findsNothing);
    expect(harness.locationEvents, isEmpty);
  });

  testWidgets('directory picker platform failure uses shared settings feedback', (tester) async {
    directoryPicker.directoryError = PlatformException(code: 'picker_failed');
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.saveFailed), findsOneWidget);
    expect(harness.locationEvents, isEmpty);
  });

  testWidgets('directory filesystem failure uses shared settings feedback', (tester) async {
    directoryPicker.directoryPath = '${temporaryDirectory.path}/selected-downloads';
    final harness = await _pumpSettingsScreen(
      tester,
      writableChecker: (_) async => throw const FileSystemException('writable check failed'),
    );
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.saveFailed), findsOneWidget);
    expect(harness.locationEvents, isEmpty);
  });

  testWidgets('late directory picker completion does not use a disposed context', (tester) async {
    directoryPicker.directoryGate = Completer<String?>();
    final harness = await _pumpSettingsScreen(tester);

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await tester.pump();
    await harness.dispose(tester);

    directoryPicker.directoryGate!.complete('${temporaryDirectory.path}/late-downloads');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(harness.locationEvents, isEmpty);
  });

  testWidgets('late directory picker failure does not use a disposed context', (tester) async {
    directoryPicker.directoryGate = Completer<String?>();
    final harness = await _pumpSettingsScreen(tester);

    await tester.tap(find.text(t.settings.downloadLocationDefault));
    await _pumpUi(tester);
    await tester.tap(find.text(t.settings.selectFolder));
    await tester.pump();
    await harness.dispose(tester);

    directoryPicker.directoryGate!.completeError(PlatformException(code: 'late_picker_failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(harness.locationEvents, isEmpty);
  });

  testWidgets('late settings export failure does not use a disposed context', (tester) async {
    final exportGate = Completer<String?>();
    final harness = await _pumpSettingsScreen(tester, settingsExporter: () => exportGate.future);

    await tester.tap(find.text(t.settings.exportSettings));
    await tester.pump();
    await harness.dispose(tester);

    exportGate.completeError(PlatformException(code: 'late_export_failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('late settings import failure does not use a disposed context', (tester) async {
    final importGate = Completer<ImportResult?>();
    final harness = await _pumpSettingsScreen(tester, settingsImporter: () => importGate.future);

    await tester.tap(find.text(t.settings.importSettings));
    await _pumpUi(tester);
    await tester.tap(find.widgetWithText(DialogActionButton, t.settings.importSettings));
    await tester.pump();
    await harness.dispose(tester);

    importGate.completeError(PlatformException(code: 'late_import_failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('settings export platform failure uses shared settings feedback', (tester) async {
    final harness = await _pumpSettingsScreen(
      tester,
      settingsExporter: () async => throw PlatformException(code: 'save_failed'),
    );
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.exportSettings));
    await _pumpUi(tester);

    expect(find.text(t.settings.saveFailed), findsOneWidget);
    expect(find.text(t.settings.exportSettingsSuccess), findsNothing);
  });

  testWidgets('settings import platform failure uses shared settings feedback', (tester) async {
    final harness = await _pumpSettingsScreen(
      tester,
      settingsImporter: () async => throw PlatformException(code: 'pick_failed'),
    );
    addTearDown(() => harness.dispose(tester));

    await tester.tap(find.text(t.settings.importSettings));
    await _pumpUi(tester);
    await tester.tap(find.widgetWithText(DialogActionButton, t.settings.importSettings));
    await _pumpUi(tester);

    expect(find.text(t.settings.saveFailed), findsOneWidget);
    expect(find.text(t.settings.importSettingsSuccess), findsNothing);
  });
}

Finder _navigationTileFor(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SettingNavigationTile));

Finder _focusableTileFor(String title) => find.ancestor(of: find.text(title), matching: find.byType(FocusableListTile));
Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _focusableTileWithin(Finder navigationTile) =>
    find.descendant(of: navigationTile, matching: find.byType(FocusableListTile));

class _MigratedRow {
  const _MigratedRow({required this.title, this.focusLabel, this.isVisible = true, this.hasSubtitle = true});

  final String title;
  final String? focusLabel;
  final bool isVisible;
  final bool hasSubtitle;
}

class _SettingsHarness {
  _SettingsHarness({
    required this.database,
    required this.plexHome,
    required this.activeProfile,
    required this.libraries,
    required this.hiddenLibraries,
    required this.theme,
    required this.trackers,
    required this.trackerHttpClients,
    required this.seerr,
    required this.downloadManager,
    required this.downloadProvider,
    required this.locationEvents,
    required this.accountPreferences,
  });

  final AppDatabase database;
  final PlexHomeService plexHome;
  final ActiveProfileProvider activeProfile;
  final LibrariesProvider libraries;
  final HiddenLibrariesProvider hiddenLibraries;
  final ThemeProvider theme;
  final TrackersProvider trackers;
  final List<FakeHttpClient> trackerHttpClients;
  final SeerrAccountProvider seerr;
  final DownloadManagerService downloadManager;
  final DownloadProvider downloadProvider;
  final List<String> locationEvents;
  final AccountPreferencesController accountPreferences;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    downloadProvider.dispose();
    downloadManager.dispose();
    hiddenLibraries.dispose();
    libraries.dispose();
    theme.dispose();
    trackers.dispose();
    seerr.dispose();
    activeProfile.dispose();
    accountPreferences.dispose();
    await plexHome.dispose();
    await database.close();
    expect(trackerHttpClients, hasLength(6));
    expect(trackerHttpClients.toSet(), hasLength(6));
    for (final client in trackerHttpClients) {
      expect(client.closeCount, 1);
    }
  }
}

Future<_SettingsHarness> _pumpSettingsScreen(
  WidgetTester tester, {
  Future<bool> Function(Directory directory)? writableChecker,
  Future<String?> Function()? settingsExporter,
  Future<ImportResult?> Function()? settingsImporter,
  BackgroundWorkDiagnosticsService? backgroundWorkDiagnosticsService,
  bool pushSettingsRoute = false,
}) async {
  tester.view.physicalSize = const Size(1800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final connections = ConnectionRegistry(database);
  final profileConnections = ProfileConnectionRegistry(database);
  final profiles = ProfileRegistry(database);
  final plexHome = PlexHomeService(
    connections: connections,
    profileConnections: profileConnections,
    plexHomeUserFetcher: (_) async => const [],
  );
  final activeProfile = ActiveProfileProvider(
    registry: profiles,
    plexHome: plexHome,
    connections: connections,
    profileConnections: profileConnections,
  );
  final libraries = LibrariesProvider();
  final hiddenLibraries = HiddenLibrariesProvider(storageService: _FakeHiddenLibrariesStorage());
  await hiddenLibraries.ensureInitialized();
  final theme = ThemeProvider();
  final trackerHttpClients = <FakeHttpClient>[];
  FakeHttpClient trackerHttpClientFactory() {
    final client = FakeHttpClient(HttpStatus.ok, const <int>[]);
    trackerHttpClients.add(client);
    return client;
  }

  final trackers = TrackersProvider(httpClientFactory: trackerHttpClientFactory);
  final seerr = SeerrAccountProvider();
  // Left unattached: with no registries wired it resolves no accounts, so the
  // Account preferences row stays hidden and these tests keep their existing
  // section list.
  final accountPreferences = AccountPreferencesController();
  final settingsService = SettingsService.instance;
  final storageService = DownloadStorageService.instance;
  await tester.runAsync(() => storageService.initialize(settingsService));
  final locationEvents = <String>[];
  final downloadManager = DownloadManagerService(
    database: database,
    storageService: storageService,
    clientResolver: (_, {clientScopeId}) => null,
    downloadsSupportedOverride: false,
    downloadLocationReader: () => (
      path: settingsService.read(SettingsService.customDownloadPath),
      type: settingsService.read(SettingsService.customDownloadPathType),
    ),
    downloadPathWriter: (value) async {
      locationEvents.add('path:$value');
      await settingsService.write(SettingsService.customDownloadPath, value);
    },
    downloadPathTypeWriter: (value) async {
      locationEvents.add('type:$value');
      await settingsService.write(SettingsService.customDownloadPathType, value);
    },
    downloadStorageRefresher: () async {
      locationEvents.add('refresh');
    },
  )..recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
  final harness = _SettingsHarness(
    database: database,
    plexHome: plexHome,
    activeProfile: activeProfile,
    libraries: libraries,
    hiddenLibraries: hiddenLibraries,
    theme: theme,
    trackers: trackers,
    trackerHttpClients: trackerHttpClients,
    seerr: seerr,
    downloadManager: downloadManager,
    downloadProvider: downloadProvider,
    locationEvents: locationEvents,
    accountPreferences: accountPreferences,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
          ChangeNotifierProvider<LibrariesProvider>.value(value: libraries),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibraries),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
          ChangeNotifierProvider<SeerrAccountProvider>.value(value: seerr),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
          ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
          home: pushSettingsRoute
              ? Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SettingsScreen(
                              downloadDirectoryWritableChecker: writableChecker ?? (_) async => true,
                              settingsExporter: settingsExporter,
                              settingsImporter: settingsImporter,
                              backgroundWorkDiagnosticsService: backgroundWorkDiagnosticsService,
                            ),
                          ),
                        ),
                        child: const Text('Settings launcher'),
                      ),
                    ),
                  ),
                )
              : SettingsScreen(
                  downloadDirectoryWritableChecker: writableChecker ?? (_) async => true,
                  settingsExporter: settingsExporter,
                  settingsImporter: settingsImporter,
                  backgroundWorkDiagnosticsService: backgroundWorkDiagnosticsService,
                ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (pushSettingsRoute) {
    await tester.tap(find.text('Settings launcher'));
    await _pumpUi(tester);
  }
  return harness;
}

class _FakeHiddenLibrariesStorage implements StorageService {
  @override
  Set<String> getHiddenLibraries() => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDirectoryPicker implements FilePickerDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  String? directoryPath;
  Object? directoryError;
  Completer<String?>? directoryGate;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
  }) async {
    final gate = directoryGate;
    if (gate != null) return gate.future;
    final error = directoryError;
    if (error != null) throw error;
    return directoryPath;
  }
}
