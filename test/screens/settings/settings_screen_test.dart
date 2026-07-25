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
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/providers/trakt_account_provider.dart';
import 'package:plezy/screens/settings/settings_screen.dart';
import 'package:plezy/services/donation_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/file_picker_service.dart';
import 'package:plezy/services/settings_export_service.dart';
import 'package:plezy/services/settings_service.dart';
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

  testWidgets('migrated rows retain compact mobile navigation geometry and activation', (tester) async {
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
        isVisible: UpdateService.isUpdateCheckEnabled && UpdateService.useNativeUpdater,
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

      expect(focusable.dense, isTrue, reason: '${row.title} must use the shared compact mobile density');
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

  testWidgets('special download and generic update rows retain rich content at standard density', (tester) async {
    final harness = await _pumpSettingsScreen(tester);
    addTearDown(() => harness.dispose(tester));

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
      expect(materialDownloadTile.dense, isFalse);
      expect(materialDownloadTile.visualDensity, VisualDensity.standard);
      expect(downloadTile.dense, isFalse);
      expect(downloadTile.visualDensity, VisualDensity.standard);
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

    if (!UpdateService.isUpdateCheckEnabled) {
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
    expect(updateTile.dense, isFalse);
    expect(materialUpdateTile.dense, isFalse);
    expect(materialUpdateTile.visualDensity, VisualDensity.standard);
    expect(updateTile.visualDensity, VisualDensity.standard);
    expect(updateTile.trailing, isA<AppIcon>());
    expect(updateTile.onTap, isNotNull);
    expect(find.descendant(of: updateTileFinder, matching: find.byType(LoadingIndicatorBox)), findsNothing);

    // The generic updater deliberately remains a FocusableListTile: unlike a
    // SettingNavigationTile, its trailing slot can be replaced by the progress
    // indicator and its callback disabled while a request is in flight.
    expect(materialUpdateTile.focusNode, isNotNull);
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
    required this.theme,
    required this.trakt,
    required this.trackers,
    required this.trackerHttpClients,
    required this.seerr,
    required this.downloadManager,
    required this.downloadProvider,
    required this.locationEvents,
  });

  final AppDatabase database;
  final PlexHomeService plexHome;
  final ActiveProfileProvider activeProfile;
  final LibrariesProvider libraries;
  final ThemeProvider theme;
  final TraktAccountProvider trakt;
  final TrackersProvider trackers;
  final List<FakeHttpClient> trackerHttpClients;
  final SeerrAccountProvider seerr;
  final DownloadManagerService downloadManager;
  final DownloadProvider downloadProvider;
  final List<String> locationEvents;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    downloadProvider.dispose();
    downloadManager.dispose();
    libraries.dispose();
    theme.dispose();
    trakt.dispose();
    trackers.dispose();
    seerr.dispose();
    activeProfile.dispose();
    await plexHome.dispose();
    await database.close();
    expect(trackerHttpClients, hasLength(5));
    expect(trackerHttpClients.toSet(), hasLength(5));
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
  final activeProfile = ActiveProfileProvider(registry: profiles, plexHome: plexHome, connections: connections);
  final libraries = LibrariesProvider();
  final theme = ThemeProvider();
  final trackerHttpClients = <FakeHttpClient>[];
  FakeHttpClient trackerHttpClientFactory() {
    final client = FakeHttpClient(HttpStatus.ok, const <int>[]);
    trackerHttpClients.add(client);
    return client;
  }

  final trakt = TraktAccountProvider(httpClientFactory: trackerHttpClientFactory);
  final trackers = TrackersProvider(httpClientFactory: trackerHttpClientFactory);
  final seerr = SeerrAccountProvider();
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
    theme: theme,
    trakt: trakt,
    trackers: trackers,
    trackerHttpClients: trackerHttpClients,
    seerr: seerr,
    downloadManager: downloadManager,
    downloadProvider: downloadProvider,
    locationEvents: locationEvents,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
          ChangeNotifierProvider<LibrariesProvider>.value(value: libraries),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<TraktAccountProvider>.value(value: trakt),
          ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
          ChangeNotifierProvider<SeerrAccountProvider>.value(value: seerr),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
          home: SettingsScreen(
            downloadDirectoryWritableChecker: writableChecker ?? (_) async => true,
            settingsExporter: settingsExporter,
            settingsImporter: settingsImporter,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return harness;
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
