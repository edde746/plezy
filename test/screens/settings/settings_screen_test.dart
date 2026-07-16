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
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/providers/trakt_account_provider.dart';
import 'package:plezy/screens/settings/settings_screen.dart';
import 'package:plezy/services/donation_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/update_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
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
    await SettingsService.getInstance();
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    DownloadStorageService.resetForTesting();
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
      _MigratedRow(title: t.settings.clearCache, focusLabel: 'settings_clear_cache'),
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
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.watchTogetherRelay), findsWidgets);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.settings.clearCache));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.clearCache), findsWidgets);
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
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t.settings.downloadLocationDescription), findsOneWidget);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
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
}

Finder _navigationTileFor(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SettingNavigationTile));

Finder _focusableTileFor(String title) => find.ancestor(of: find.text(title), matching: find.byType(FocusableListTile));

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
    required this.seerr,
  });

  final AppDatabase database;
  final PlexHomeService plexHome;
  final ActiveProfileProvider activeProfile;
  final LibrariesProvider libraries;
  final ThemeProvider theme;
  final TraktAccountProvider trakt;
  final TrackersProvider trackers;
  final SeerrAccountProvider seerr;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    libraries.dispose();
    theme.dispose();
    trakt.dispose();
    trackers.dispose();
    seerr.dispose();
    activeProfile.dispose();
    await plexHome.dispose();
    await database.close();
  }
}

Future<_SettingsHarness> _pumpSettingsScreen(WidgetTester tester) async {
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
  final trakt = TraktAccountProvider();
  final trackers = TrackersProvider();
  final seerr = SeerrAccountProvider();
  final harness = _SettingsHarness(
    database: database,
    plexHome: plexHome,
    activeProfile: activeProfile,
    libraries: libraries,
    theme: theme,
    trakt: trakt,
    trackers: trackers,
    seerr: seerr,
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
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
          home: const SettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}
