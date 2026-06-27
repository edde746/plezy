import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/providers/watchlist_provider.dart';
import 'package:plezy/screens/media_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/profile_navigation.dart';

/// Minimal fake [MediaServerClient] that returns a single movie item.
class _FakeMovieClient implements MediaServerClient {
  final MediaItem _movie;

  _FakeMovieClient(this._movie);

  @override
  ServerId get serverId => ServerId(_movie.serverId!);

  @override
  String? get serverName => 'TestServer';

  @override
  MediaBackend get backend => _movie.backend;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id,
  ) async {
    return (item: _movie, onDeckEpisode: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const serverId = 'srv-1';
  const movieId = 'movie-1';
  const profileId = 'profile-test';

  MediaItem movie() => MediaItem(
    id: movieId,
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: serverId,
    title: 'Test Movie',
  );

  // ── Full integration: pump with full provider tree (phone mode) ──

  testWidgets('bookmark toggle renders, flips icon, and responds to tap', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view.physicalSize = const Size(1100, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      TvDetectionService.debugSetAppleTVOverride(null);
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);

    final watchlistProvider = WatchlistProvider(database: db);
    watchlistProvider.setActiveProfileId(profileId);

    final downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadManager.recoveryFuture = Future<void>.value();
    final downloadProvider =
        DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    final manager = MultiServerManager();
    manager.debugRegisterClientForTesting(_FakeMovieClient(movie()));

    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final watchStateOverlay = WatchStateStore();

    addTearDown(() async {
      watchStateOverlay.dispose();
      if (!watchlistProvider.isDisposed) watchlistProvider.dispose();
      downloadProvider.dispose();
      multiServerProvider.dispose();
      await db.close();
    });

    final metadata = movie();

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<WatchlistProvider>.value(value: watchlistProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<WatchStateStore>.value(value: watchStateOverlay),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: MediaDetailScreen(metadata: metadata),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // TEST 1 — bookmark button renders
    expect(find.byIcon(Symbols.bookmark), findsOneWidget);

    // TEST 2 — icon flips to filled when bookmarked
    await watchlistProvider.toggleBookmark(metadata);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Symbols.bookmark_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.bookmark), findsNothing);

    // TEST 3 — icon flips back to outlined when unbookmarked
    await watchlistProvider.toggleBookmark(metadata);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Symbols.bookmark), findsOneWidget);
    expect(find.byIcon(Symbols.bookmark_rounded), findsNothing);

    // TEST 4 — tap adds to watchlist + shows snackbar
    await tester.tap(find.byIcon(Symbols.bookmark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(watchlistProvider.isBookmarked(metadata.globalKey), isTrue);
    expect(find.text('Added to watchlist'), findsOneWidget);
  });

  testWidgets('tap removes from watchlist and shows removal snackbar', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view.physicalSize = const Size(1100, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      TvDetectionService.debugSetAppleTVOverride(null);
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);

    final watchlistProvider = WatchlistProvider(database: db);
    watchlistProvider.setActiveProfileId(profileId);

    final downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadManager.recoveryFuture = Future<void>.value();
    final downloadProvider =
        DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    final manager = MultiServerManager();
    manager.debugRegisterClientForTesting(_FakeMovieClient(movie()));

    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final watchStateOverlay = WatchStateStore();

    addTearDown(() async {
      watchStateOverlay.dispose();
      if (!watchlistProvider.isDisposed) watchlistProvider.dispose();
      downloadProvider.dispose();
      multiServerProvider.dispose();
      await db.close();
    });

    final metadata = movie();

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<WatchlistProvider>.value(value: watchlistProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<WatchStateStore>.value(value: watchStateOverlay),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: MediaDetailScreen(metadata: metadata),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Bookmark first so we can test removal
    await watchlistProvider.toggleBookmark(metadata);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the filled bookmark icon to remove
    await tester.tap(find.byIcon(Symbols.bookmark_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(watchlistProvider.isBookmarked(metadata.globalKey), isFalse);
    expect(find.text('Removed from watchlist'), findsOneWidget);
  });

  testWidgets('bookmark toggle is always visible (not gated by offline)', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view.physicalSize = const Size(1100, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      TvDetectionService.debugSetAppleTVOverride(null);
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);

    final watchlistProvider = WatchlistProvider(database: db);
    watchlistProvider.setActiveProfileId(profileId);

    final downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadManager.recoveryFuture = Future<void>.value();
    final downloadProvider =
        DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    final manager = MultiServerManager();
    manager.debugRegisterClientForTesting(_FakeMovieClient(movie()));

    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final watchStateOverlay = WatchStateStore();

    addTearDown(() async {
      watchStateOverlay.dispose();
      if (!watchlistProvider.isDisposed) watchlistProvider.dispose();
      downloadProvider.dispose();
      multiServerProvider.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<WatchlistProvider>.value(value: watchlistProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<WatchStateStore>.value(value: watchStateOverlay),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: MediaDetailScreen(metadata: movie()),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Bookmark icon should be visible regardless of connectivity
    expect(find.byIcon(Symbols.bookmark), findsOneWidget);
  });
}
