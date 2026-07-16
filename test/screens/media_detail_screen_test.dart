import 'dart:async';
import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/screens/media_detail_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';

import '../test_helpers/paged_fakes.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/widgets/collapsible_text.dart';
import 'package:plezy/widgets/episode_card.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_navigation.dart';
import '../test_helpers/media_items.dart';

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

  testWidgets('TV detail scales fallback title to fit logo bounds', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const title = 'The Surprisingly Long Movie Title That Needs Two Whole Lines';
    final movie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: title,
      summary: 'A compact viewport should make the fallback title shrink before it can overlap the detail text.',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final titleText = tester.widget<Text>(find.text(title));
    final baseFontSize = 56 * TvLayoutConstants.scaleForSize(const Size(800, 480));
    expect(titleText.style?.fontSize, isNotNull);
    expect(titleText.style!.fontSize!, lessThan(baseFontSize));
  });

  testWidgets('TV detail exposes hero information as one semantic node', (tester) async {
    final semantics = tester.ensureSemantics();
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = testMediaItem(
      id: 'semantic_movie',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Semantic Movie',
      summary: 'One concise detail announcement.',
      year: 2025,
      genres: ['Drama', 'Mystery'],
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final information = find.bySemanticsIdentifier('tv_detail_information');
    expect(information, findsOneWidget);
    final node = tester.getSemantics(information);
    expect(node.label, contains('Semantic Movie'));
    expect(node.label, contains('Movie'));
    expect(node.label, contains('2025'));
    expect(node.label, contains('Drama, Mystery'));
    expect(node.label, contains('One concise detail announcement.'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(tester.widget<Semantics>(information).properties.onTap, isNull);

    // Visual content and the separate action row remain present.
    expect(find.text('Semantic Movie'), findsOneWidget);
    expect(find.text('One concise detail announcement.'), findsOneWidget);
    expect(find.byType(FocusableActionBar), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TV detail reveals without waiting for directional input', (tester) async {
    await SettingsService.getInstance();

    final movie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Idle Reveal Movie',
      summary: 'The detail foreground should appear without needing a D-pad frame.',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );

    final revealGate = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.duration == const Duration(milliseconds: 160),
      description: 'TV detail reveal AnimatedOpacity',
    );
    expect(revealGate, findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(revealGate).opacity, 0);

    await tester.pump();

    expect(tester.widget<AnimatedOpacity>(revealGate).opacity, 1);
  });

  testWidgets('TV detail shows Rotten Tomatoes rating badge in metadata line', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Rotten Tomatoes Movie',
      summary: 'The TV detail metadata line should use the rating source badge.',
      rating: 6.2,
      ratingImage: 'rottentomatoes://image.rating.ripe',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('62%'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.textContaining('★ 6.2', findRichText: true), findsNothing);
  });

  testWidgets('TV detail falls back to Rotten Tomatoes audience rating in metadata line', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Audience Rating Movie',
      summary: 'The TV detail metadata line should use the available audience source badge.',
      audienceRating: 8.7,
      audienceRatingImage: 'rottentomatoes://image.rating.upright',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('87%'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('TV detail defaults to first regular season when specials precede it', (tester) async {
    await SettingsService.getInstance();

    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final specials = testMediaItem(
      id: 'season_0',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Specials',
      index: 0,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season1 = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final specialEpisode = testMediaItem(
      id: 'episode_special_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Special 1',
      index: 1,
      parentId: specials.id,
      parentIndex: specials.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season1.id,
      parentIndex: season1.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    final descendantsCompleter = Completer<List<MediaItem>>();
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [specials, season1],
        specials.id: [specialEpisode],
        season1.id: [episode1],
      },
      pendingPlayableDescendants: descendantsCompleter.future,
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: SizedBox(width: 1280, height: 720, child: MediaDetailScreen(metadata: show)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Specials'), findsNothing);
    expect(find.text('S1E1'), findsOneWidget);
  });

  testWidgets('TV detail summary uses light theme foreground color', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const summary = 'Light theme detail text should stay readable.';
    final movie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Readable Movie',
      summary: summary,
    );
    final theme = monoTheme(dark: false);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: theme,
          home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final summaryText = tester.widget<Text>(find.text(summary));
    expect(summaryText.style?.color, theme.colorScheme.onSurface.withValues(alpha: 0.78));
  });

  testWidgets('TV detail shows every season tab and prefetches adjacent first page', (tester) async {
    await SettingsService.getInstance();

    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season1 = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season2 = testMediaItem(
      id: 'season_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 2',
      index: 2,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season1.id,
      parentIndex: season1.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode2 = testMediaItem(
      id: 'episode_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 2',
      index: 1,
      parentId: season2.id,
      parentIndex: season2.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1, season2],
        season1.id: [episode1],
        season2.id: [episode2],
      },
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: SizedBox(width: 1280, height: 720, child: MediaDetailScreen(metadata: show)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Every season tab is derived from the season list, so both appear
    // immediately. TV warms only the selected first page plus the adjacent first
    // page; it still does not walk the whole show or load page 2+.
    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
    expect(client.childrenPageCalls.map((call) => call.parentId), containsAll([season1.id, season2.id]));
    expect(client.childrenPageCalls.every((call) => call.start == 0 && call.size == 200), isTrue);
  });

  testWidgets('TV detail keeps every season tab when a season episode load fails', (tester) async {
    await SettingsService.getInstance();

    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season1 = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season2 = testMediaItem(
      id: 'season_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 2',
      index: 2,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season1.id,
      parentIndex: season1.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode2 = testMediaItem(
      id: 'episode_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 2',
      index: 1,
      parentId: season2.id,
      parentIndex: season2.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1, season2],
        season1.id: [episode1],
        season2.id: [episode2],
      },
      childrenPageErrors: {season1.id: Exception('season cache failed')},
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: SizedBox(width: 1280, height: 720, child: MediaDetailScreen(metadata: show)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
  });

  testWidgets('TV detail completes adjacent prefetch after focus moves to that season', (tester) async {
    await SettingsService.getInstance();

    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season1 = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season2 = testMediaItem(
      id: 'season_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 2',
      index: 2,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season1.id,
      parentIndex: season1.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode2 = testMediaItem(
      id: 'episode_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 2',
      index: 1,
      parentId: season2.id,
      parentIndex: season2.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final season2Completer = Completer<List<MediaItem>>();
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1, season2],
        season1.id: [episode1],
      },
      childrenPageFutures: {season2.id: season2Completer.future},
    );
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: withProfileNavigationScope(
              child: SizedBox(width: 1280, height: 720, child: MediaDetailScreen(metadata: show)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('Episode 2'), findsNothing);

    season2Completer.complete([episode2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Episode 2'), findsOneWidget);
  });

  group('watch state freshness (phone layout)', () {
    MediaItem buildShow({String? summary}) => testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      summary: summary,
      leafCount: 4,
      viewedLeafCount: 0,
      serverId: 'server_1',
      serverName: 'Server',
    );

    MediaItem buildSeason(MediaItem show, int index) => testMediaItem(
      id: 'season_$index',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season $index',
      index: index,
      leafCount: 2,
      viewedLeafCount: 0,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    MediaItem buildEpisode(MediaItem show, MediaItem season, int index) => testMediaItem(
      id: '${season.id}_episode_$index',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode S${season.index}E$index',
      index: index,
      durationMs: 30 * 60 * 1000,
      parentId: season.id,
      parentIndex: season.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    Future<void> pumpPhoneDetail(
      WidgetTester tester,
      _FakeMediaServerClient client,
      MediaItem show, {
      String? initialSeasonId,
      int? initialSeasonIndex,
      String? initialEpisodeId,
    }) async {
      TvDetectionService.debugSetAppleTVOverride(false);
      await SettingsService.getInstance();
      tester.view.physicalSize = const Size(1100, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      final downloadManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
      );
      downloadManager.recoveryFuture = Future<void>.value();
      final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await downloadProvider.ensureInitialized();

      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      final watchStateOverlay = WatchStateStore();

      addTearDown(() async {
        watchStateOverlay.dispose();
        downloadProvider.dispose();
        downloadManager.dispose();
        multiServerProvider.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
              ChangeNotifierProvider<WatchStateStore>.value(value: watchStateOverlay),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: withProfileNavigationScope(
                child: MediaDetailScreen(
                  metadata: show,
                  initialSeasonId: initialSeasonId,
                  initialSeasonIndex: initialSeasonIndex,
                  initialEpisodeId: initialEpisodeId,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder episodeCardFor(String title) => find.ancestor(of: find.text(title), matching: find.byType(EpisodeCard));

    bool episodeRowWatched(WidgetTester tester, String title) {
      final card = episodeCardFor(title);
      expect(card, findsOneWidget, reason: 'episode row "$title" should be visible');
      return tester.any(find.descendant(of: card, matching: find.byIcon(Symbols.check_rounded)));
    }

    bool episodeRowHasProgress(WidgetTester tester, String title) {
      final card = episodeCardFor(title);
      expect(card, findsOneWidget, reason: 'episode row "$title" should be visible');
      return tester.any(find.descendant(of: card, matching: find.byType(LinearProgressIndicator)));
    }

    Future<void> emit(WidgetTester tester, void Function() send) async {
      send();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    _FakeMediaServerClient singleSeasonClient(MediaItem show) {
      final season = buildSeason(show, 1);
      return _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season],
          season.id: [buildEpisode(show, season, 1)],
        },
      );
    }

    FocusNode overviewFocusNode(WidgetTester tester) {
      final overviewFocus = find.byWidgetPredicate(
        (widget) => widget is Focus && widget.focusNode?.debugLabel == 'overview',
        description: 'overview focus widget',
      );
      expect(overviewFocus, findsOneWidget);
      return tester.widget<Focus>(overviewFocus).focusNode!;
    }

    testWidgets('overflowing overview DOWN reaches the first real section', (tester) async {
      const summary =
          'A deliberately extensive overview repeats enough concrete detail to exceed the collapsed line limit. '
          'It describes the setting, the characters, the central conflict, and the consequences in full. '
          'A second passage adds more background, more context, and more narrative detail for the viewer. '
          'A third passage ensures the overview remains overflowing even across a wide phone test viewport. '
          'Finally, another complete passage keeps the text beyond four generous lines without relying on font timing.';
      final show = buildShow(summary: summary);

      await pumpPhoneDetail(tester, singleSeasonClient(show), show);

      final overviewText = tester.widget<Text>(
        find.descendant(of: find.byType(CollapsibleText), matching: find.byType(Text)).first,
      );
      expect(overviewText.textSpan, isNotNull);
      expect(overviewText.textSpan!.toPlainText(), isNot(summary));

      final overviewNode = overviewFocusNode(tester);
      overviewNode.requestFocus();
      await tester.pump();
      expect(overviewNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'first_episode');
    });

    testWidgets('short overview accepts focus and preserves DOWN then episode UP navigation', (tester) async {
      const summary = 'A short overview.';
      final show = buildShow(summary: summary);

      await pumpPhoneDetail(tester, singleSeasonClient(show), show);

      expect(find.text(summary), findsOneWidget);
      final overviewNode = overviewFocusNode(tester);
      expect(overviewNode.context, isNotNull);
      overviewNode.requestFocus();
      await tester.pump();
      expect(overviewNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'first_episode');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'overview');
    });

    testWidgets('phone detail focuses requested season tab', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final season2 = buildSeason(show, 2);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, season2],
          season1.id: [buildEpisode(show, season1, 1)],
          season2.id: [buildEpisode(show, season2, 1)],
        },
      );

      await pumpPhoneDetail(tester, client, show, initialSeasonId: season2.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Episode S2E1'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'season_tab_1');
    });

    testWidgets('phone detail focuses requested episode row', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final season2 = buildSeason(show, 2);
      final episode2 = buildEpisode(show, season2, 2);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, season2],
          season1.id: [buildEpisode(show, season1, 1)],
          season2.id: [buildEpisode(show, season2, 1), episode2, buildEpisode(show, season2, 3)],
        },
      );

      await pumpPhoneDetail(
        tester,
        client,
        show,
        initialSeasonId: season2.id,
        initialSeasonIndex: season2.index,
        initialEpisodeId: episode2.id,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Episode S2E2'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'initial_episode');
    });

    testWidgets('phone detail keeps the first-episode role node when it is the target', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final season2 = buildSeason(show, 2);
      final episode1 = buildEpisode(show, season2, 1);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, season2],
          season1.id: [buildEpisode(show, season1, 1)],
          season2.id: [episode1, buildEpisode(show, season2, 2), buildEpisode(show, season2, 3)],
        },
      );

      await pumpPhoneDetail(
        tester,
        client,
        show,
        initialSeasonId: season2.id,
        initialSeasonIndex: season2.index,
        initialEpisodeId: episode1.id,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The first row keeps _firstEpisodeFocusNode (so season-tab DOWN keeps
      // working) and the initial focus lands on that node instead.
      expect(find.text('Episode S2E1'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'first_episode');
    });

    testWidgets('container mark overrides an older per-episode patch', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final episode1 = buildEpisode(show, season1, 1);
      final episode2 = buildEpisode(show, season1, 2);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, buildSeason(show, 2)],
          season1.id: [episode1, episode2],
        },
      );

      await pumpPhoneDetail(tester, client, show);

      // Seed a session patch for one episode (e.g. user toggled it earlier).
      await emit(tester, () => WatchStateNotifier().notifyWatched(item: episode1, isNowWatched: false));
      expect(episodeRowWatched(tester, 'Episode S1E1'), isFalse);

      await emit(tester, () => WatchStateNotifier().notifyWatched(item: show, isNowWatched: true));

      expect(episodeRowWatched(tester, 'Episode S1E1'), isTrue);
      expect(episodeRowWatched(tester, 'Episode S1E2'), isTrue);
    });

    testWidgets('marking a season watched flips its episode rows', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final season2 = buildSeason(show, 2);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, season2],
          season1.id: [buildEpisode(show, season1, 1), buildEpisode(show, season1, 2)],
          season2.id: [buildEpisode(show, season2, 1)],
        },
      );

      await pumpPhoneDetail(tester, client, show);

      await emit(tester, () => WatchStateNotifier().notifyWatched(item: season1, isNowWatched: true));

      expect(episodeRowWatched(tester, 'Episode S1E1'), isTrue);
      expect(episodeRowWatched(tester, 'Episode S1E2'), isTrue);
    });

    testWidgets('container mark clears progress, including after a season tab round-trip', (tester) async {
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final season2 = buildSeason(show, 2);
      final episode1 = buildEpisode(show, season1, 1);
      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1, season2],
          season1.id: [episode1, buildEpisode(show, season1, 2)],
          season2.id: [buildEpisode(show, season2, 1)],
        },
      );

      await pumpPhoneDetail(tester, client, show);

      // Played partway earlier in the session.
      await emit(
        tester,
        () => WatchStateNotifier().notifyProgress(item: episode1, viewOffset: 600000, duration: 1800000),
      );
      expect(episodeRowHasProgress(tester, 'Episode S1E1'), isTrue);

      await emit(tester, () => WatchStateNotifier().notifyWatched(item: show, isNowWatched: true));
      expect(episodeRowHasProgress(tester, 'Episode S1E1'), isFalse);
      expect(episodeRowWatched(tester, 'Episode S1E1'), isTrue);

      // Round-trip through another season tab; the cached page restore must not
      // resurrect the dead progress offset.
      await tester.tap(find.text('Season 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Season 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(episodeRowHasProgress(tester, 'Episode S1E1'), isFalse);
      expect(episodeRowWatched(tester, 'Episode S1E1'), isTrue);
    });
  });
}

class _FakeMediaServerClient implements MediaServerClient {
  final MediaItem show;
  final Map<String, List<MediaItem>> childrenByParent;
  final Map<String, Future<List<MediaItem>>> childrenPageFutures;
  final Map<String, Object> childrenPageErrors;
  final Future<List<MediaItem>>? pendingPlayableDescendants;
  final childrenPageCalls = <({String parentId, int? start, int? size})>[];

  _FakeMediaServerClient({
    required this.show,
    required this.childrenByParent,
    this.childrenPageFutures = const {},
    this.childrenPageErrors = const {},
    this.pendingPlayableDescendants,
  });

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async {
    return (item: show, onDeckEpisode: null);
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    return childrenByParent[parentId] ?? const [];
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    childrenPageCalls.add((parentId: parentId, start: start, size: size));
    final error = childrenPageErrors[parentId];
    if (error != null) throw error;
    final all =
        await (childrenPageFutures[parentId] ?? Future.value(childrenByParent[parentId] ?? const <MediaItem>[]));
    return fakeLibraryPage(all, start: start, size: size);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final items = await pendingPlayableDescendants!;
    return LibraryPage(items: items, totalCount: items.length, offset: start ?? 0);
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
