import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/mixins/tab_visibility_aware.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/discover_screen.dart';
import 'package:plezy/screens/main_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/watch_together.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:plezy/widgets/tv_spotlight_background.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(true);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('TV tab focus returns to discover browse rail instead of reload action', (tester) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.libraryDensity, LibraryDensity.max);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final item = MediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 1',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final hub = MediaHub(id: 'hub_1', title: 'Recommended', type: 'movie', items: [item], size: 1);
    final client = _FakeMediaServerClient(hubs: [hub]);
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final hiddenLibrariesProvider = HiddenLibrariesProvider();
    final librariesProvider = LibrariesProvider();
    final watchTogetherProvider = WatchTogetherProvider();
    final companionRemoteProvider = CompanionRemoteProvider();

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final profileRegistry = _FakeProfileRegistry(db);
    final connectionRegistry = _FakeConnectionRegistry(db);
    final profileConnectionRegistry = _FakeProfileConnectionRegistry(db);
    final storage = await StorageService.getInstance();
    final plexHome = PlexHomeService(
      connections: connectionRegistry,
      profileConnections: profileConnectionRegistry,
      storage: storage,
      plexHomeUserFetcher: (_) async => const [],
    );
    final activeProfileProvider = ActiveProfileProvider(
      registry: profileRegistry,
      plexHome: plexHome,
      connections: connectionRegistry,
      storage: storage,
    );
    final discoverProvider = DiscoverProvider(
      multiServerProvider,
      hiddenLibrariesProvider,
      librariesProvider,
      isProfileBinding: () => activeProfileProvider.isBinding,
    );
    final discoverKey = GlobalKey<State<DiscoverScreen>>();
    const targetSidebarOffset = SideNavigationRailState.expandedWidth;
    const currentForegroundLeft = 120.0;
    const foregroundWidth = 1280 - SideNavigationRailState.tvCollapsedWidth;

    addTearDown(() async {
      discoverProvider.dispose();
      activeProfileProvider.dispose();
      companionRemoteProvider.dispose();
      watchTogetherProvider.dispose();
      librariesProvider.dispose();
      hiddenLibrariesProvider.dispose();
      multiServerProvider.dispose();
      await plexHome.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
            ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
            ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogetherProvider),
            ChangeNotifierProvider<CompanionRemoteProvider>.value(value: companionRemoteProvider),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfileProvider),
            ChangeNotifierProvider<DiscoverProvider>.value(value: discoverProvider),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: MainScreenFocusScope(
              focusSidebar: () {},
              focusContent: () {},
              isSidebarFocused: false,
              sideNavigationWidth: targetSidebarOffset,
              reservedSideNavigationWidth: SideNavigationRailState.tvCollapsedWidth,
              foregroundLeft: currentForegroundLeft,
              foregroundWidth: foregroundWidth,
              viewportWidth: 1280,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: foregroundWidth,
                  height: 720,
                  child: DiscoverScreen(key: discoverKey),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(TvBrowseRail), findsOneWidget);

    final scale = TvLayoutConstants.scaleForSize(const Size(1280, 720));
    final spotlightLeft = (24 * scale).clamp(18.0, 40.0).toDouble();
    final spotlightBackground = tester.widget<TvSpotlightBackground>(find.byType(TvSpotlightBackground));
    expect(spotlightBackground.contentLeft, closeTo(spotlightLeft + currentForegroundLeft, 0.001));

    final railHeight = TvBrowseRailLayout.estimateHeight(
      size: const Size(foregroundWidth, 720),
      hubs: [hub],
      density: LibraryDensity.max,
      episodePosterMode: settings.read(SettingsService.episodePosterMode),
      fullCardLayout: settings.read(SettingsService.tvFullCardLayout),
      tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
    );
    final minimumSpotlightBottom = railHeight + (8 * scale);
    final baseSpotlightBottom = (720 * 0.48).clamp(160.0, 820.0).toDouble();
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (720 - ((720 * 0.075).clamp(64.0 * scale, 120.0 * scale)) - (96 * scale))
        .clamp(0.0, double.infinity)
        .toDouble();
    final expectedSpotlightBottom = desiredSpotlightBottom > maxSpotlightBottom
        ? maxSpotlightBottom
        : desiredSpotlightBottom;
    expect(spotlightBackground.contentBottom, closeTo(expectedSpotlightBottom, 0.001));

    // The rail no longer receives the bleed via constructor (a per-flip param
    // would rebuild the whole rail); its bleed layer reads the scope's
    // sideNavigationWidth itself. Assert the rendered bleed position instead.
    final browseRail = tester.widget<TvBrowseRail>(find.byType(TvBrowseRail));
    expect(browseRail.backgroundBleedLeft, isNull);
    final railBleedPositions = tester
        .widgetList<Positioned>(find.descendant(of: find.byType(TvBrowseRail), matching: find.byType(Positioned)))
        .where((p) => p.left == -targetSidebarOffset);
    expect(railBleedPositions, isNotEmpty, reason: 'rail bleed layer positions at -sideNavigationWidth');

    final backgroundPosition = tester.widget<Positioned>(
      find.ancestor(of: find.byType(TvSpotlightBackground), matching: find.byType(Positioned)).first,
    );
    expect(backgroundPosition.left, -currentForegroundLeft);
    expect(backgroundPosition.width, 1280);

    tester.state<FocusableActionBarState>(find.byType(FocusableActionBar)).requestFocusOnFirst();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    tester.state<FocusableActionBarState>(find.byType(FocusableActionBar)).requestFocusOnFirst();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    (discoverKey.currentState! as FocusableTab).focusActiveTabIfReady();
    (discoverKey.currentState! as TabVisibilityAware).onTabHidden();
    await tester.pump();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    (discoverKey.currentState! as TabVisibilityAware).onTabShown();
    (discoverKey.currentState! as FocusableTab).focusActiveTabIfReady();
    await tester.pump();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
  });
}

class _FakeMediaServerClient implements MediaServerClient {
  final List<MediaHub> hubs;

  _FakeMediaServerClient({required this.hubs});

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20}) async => const [];

  @override
  Future<List<MediaHub>> fetchGlobalHubs({int limit = defaultHubPreviewLimit, bool includePlaybackHubs = true}) async =>
      hubs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileRegistry extends ProfileRegistry {
  _FakeProfileRegistry(super.db);

  @override
  Stream<List<Profile>> watchProfiles() => Stream.value(const []);

  @override
  Future<List<Profile>> list() async => const [];
}

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(const []);

  @override
  Future<List<Connection>> list() async => const [];
}

class _FakeProfileConnectionRegistry extends ProfileConnectionRegistry {
  _FakeProfileConnectionRegistry(super.db);

  @override
  Stream<List<ProfileConnection>> watchAll() => Stream.value(const []);
}
