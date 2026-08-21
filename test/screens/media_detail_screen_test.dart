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
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/screens/media_detail_screen.dart';

import '../test_helpers/paged_fakes.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/widgets/collapsible_text.dart';
import 'package:plezy/widgets/cycling_media_backdrop.dart';
import 'package:plezy/widgets/episode_card.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_navigation.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';

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

  testWidgets('wide non-TV hero lets a logo-less title use the full width', (tester) async {
    // Non-TV (iPad/desktop) hero: without a clear logo the fallback title used
    // to be boxed at the logo's 400px width cap, so a long title clipped early
    // on a wide display even with room to spare (#1796). It should now lay out
    // wider than that cap.
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const title = 'The Surprisingly Long Movie Title That Needs Two Whole Lines';
    final movie = testMediaItem(
      id: 'wide_movie',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: title,
      serverId: 'server_1',
      serverName: 'Server',
    );

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

    final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});
    final multiServerProvider = testMultiServer(clients: [client]).provider;
    final watchStateOverlay = WatchStateStore();

    addTearDown(() async {
      watchStateOverlay.dispose();
      downloadProvider.dispose();
      downloadManager.dispose();
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
            home: withProfileNavigationScope(child: MediaDetailScreen(metadata: movie)),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(title), findsWidgets);
    // Old logo width cap was 400 (desiredLogoWidth in _buildHeroHeaderContent).
    expect(tester.getSize(find.text(title).first).width, greaterThan(400));
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
    // The year follows the title directly: the line leads with it instead of
    // the redundant "Movie" type label.
    expect(node.label, contains('Semantic Movie, 2025'));
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

  testWidgets('TV detail metadata line shows every rating source the item carries', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Multi Source Movie',
      summary: 'The TV detail metadata line should badge each attributed score.',
      rating: 6.2,
      ratings: [
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 6.2),
        MediaRatingSource(source: 'rottenTomatoesAudience', value: 8.7),
        MediaRatingSource(source: 'imdb', value: 7.4),
      ],
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
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(3));
    expect(find.textContaining('★ 6.2', findRichText: true), findsNothing);
    // The redundant type label no longer opens the line.
    expect(find.text('Movie'), findsNothing);
  });

  testWidgets('TV detail metadata line still renders a single available rating', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // What a hub listing yields when the server sent only the audience scalar.
    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Audience Rating Movie',
      summary: 'The TV detail metadata line should use the available audience source badge.',
      ratings: [MediaRatingSource(source: 'rottenTomatoesAudience', value: 8.7)],
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

  testWidgets('TV detail metadata line keeps quality labels visible beside a full set of scores', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The #1893 shape: a Plex detail response with all four attributed scores
    // used to push the quality labels past the right edge of the line.
    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'Quality Movie',
      summary: 'The quality labels stay visible next to the scores.',
      year: 2017,
      contentRating: 'PG-13',
      durationMs: 6360000,
      mediaVersions: [MediaVersion(id: 'v1', videoResolution: '1080')],
      ratings: [
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.2),
        MediaRatingSource(source: 'rottenTomatoesAudience', value: 8.1),
        MediaRatingSource(source: 'imdb', value: 7.4),
        MediaRatingSource(source: 'tmdb', value: 6.4),
      ],
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

    // Year opens the line; the type label is gone.
    expect(find.text('Movie'), findsNothing);
    expect(find.text('2017'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);

    // The quality label sits fully on screen. Under the old clip-at-the-edge
    // line the widget still existed but was painted past the right edge.
    expect(tester.getBottomRight(find.text('1080p')).dx, lessThanOrEqualTo(1280));

    // Desktop chip order: year, certification, runtime, quality.
    final fieldXs = [
      for (final text in ['2017', 'PG-13', '1h 46min', '1080p']) tester.getTopLeft(find.text(text)).dx,
    ];
    expect(fieldXs, orderedEquals([...fieldXs]..sort()));

    // The test font's 1 em/char advance roughly doubles text width, so at this
    // viewport the whole ratings slot legitimately gives way — dropped as the
    // least useful part instead of shoving the quality label off the line.
    expect(find.byType(SvgPicture), findsNothing);
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
    final provider = testMultiServer(clients: [client]).provider;

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
  testWidgets('TV detail reveal still waits for the supplemental sections', (tester) async {
    // Counterpart to the test above: the early paint does NOT move the TV
    // reveal. `_isTvDetailReadyToReveal` additionally requires extras, related
    // hubs, seasons and the first episode page, and those deliberately start
    // only once the on-deck lookup settles — starting them at the early paint
    // measured worse, because they contend with it rather than overlap.
    // Pinned so the phone/desktop win is never restated as an all-platform one.
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentIndex: season1.index,
      parentId: season1.id,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );

    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season1],
        season1.id: [episode1],
      },
    )..onDeckGate = Completer<void>();
    final provider = testMultiServer(clients: [client]).provider;

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

    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));

    // Target the reveal gate specifically: the detail tree also builds a
    // scroll-linked app-bar scrim whose opacity is 0 at rest, so matching on
    // AnimatedOpacity by type would pass no matter what the gate does.
    double revealOpacity() => tester.widget<AnimatedOpacity>(find.byKey(tvDetailRevealGateKey)).opacity;

    // The item was published early and the metadata phase is over...
    expect(client.earlyPaints, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // ...yet TV shows nothing but the backdrop, because the reveal gate also
    // waits on extras, related hubs, seasons and the first episode page — none
    // of which have started, since they run after the on-deck lookup settles.
    expect(revealOpacity(), 0, reason: 'the early paint must not be claimed as a TV win');

    // Let the held lookup finish so teardown is not left holding a suspended
    // future and a client mid-request.
    client.onDeckGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
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
    final provider = testMultiServer(clients: [client]).provider;

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
    final provider = testMultiServer(clients: [client]).provider;

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
    final provider = testMultiServer(clients: [client]).provider;

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

  testWidgets('TV detail episode activation bypasses the open-details preference', (tester) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.episodeAction, EpisodeAction.details);
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'Episode 1',
      index: 1,
      parentId: season.id,
      parentIndex: season.index,
      grandparentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season],
        season.id: [episode],
      },
    );
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    JellyfinApiCache.initialize(database);
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final multiServerProvider = testMultiServerProvider(manager);
    final offlineWatch = OfflineWatchSyncService(database: database, serverManager: manager);
    final downloadManager = DownloadManagerService(
      database: database,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    )..recoveryFuture = Future<void>.value();
    final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
    await downloadProvider.ensureInitialized();
    addTearDown(() async {
      downloadProvider.dispose();
      downloadManager.dispose();
      offlineWatch.dispose();
      multiServerProvider.dispose();
      manager.dispose();
      await database.close();
    });

    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingNavigatorObserver(popVideoPlayerImmediately: true);
    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
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

    expect(find.text('Episode 1'), findsOneWidget);
    observer.pushedRouteNames.clear();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(observer.pushedRouteNames, contains(kVideoPlayerRouteName));
  });

  group('phone layout', () {
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
      NavigatorObserver? observer,
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

      // testMultiServer disposes the manager as well as its provider;
      // MultiServerProvider does not own the manager, and manager.dispose() is
      // what closes its status/progress controllers and the registered client.
      final multi = testMultiServer(clients: [client]);
      final multiServerProvider = multi.provider;
      final watchStateOverlay = WatchStateStore();
      final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);

      addTearDown(() async {
        watchStateOverlay.dispose();
        offlineWatch.dispose();
        downloadProvider.dispose();
        downloadManager.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
              ChangeNotifierProvider<WatchStateStore>.value(value: watchStateOverlay),
              ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
            ],
            child: MaterialApp(
              navigatorObservers: [?observer],
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

    testWidgets('paints the item before the on-deck lookup settles', (tester) async {
      // Jellyfin needs a second round trip for on-deck; the phone/desktop
      // layout must not wait for it. Scoped to non-TV deliberately: on TV the
      // foreground stays at opacity 0 until `_isTvDetailReadyToReveal` is
      // satisfied, which this change does not move (see the TV counterpart).
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      MediaItem episode(int number, {required int viewCount}) => testMediaItem(
        id: 'episode_$number',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        title: 'Episode $number',
        index: number,
        parentIndex: season1.index,
        parentId: season1.id,
        grandparentId: show.id,
        serverId: show.serverId,
        serverName: show.serverName,
        viewCount: viewCount,
      );

      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1],
          season1.id: [episode(1, viewCount: 1), episode(2, viewCount: 0)],
        },
      )..onDeckGate = Completer<void>();

      await pumpPhoneDetail(tester, client, show);

      // On-deck is still in flight, but the item has landed.
      expect(client.earlyPaints, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'painted without waiting for on-deck');

      // Settling with no on-deck must not drop the episode-derived fallback
      // that `_ensureFallbackOnDeckEpisode` supplies.
      client.onDeckGate!.complete();
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('S1E2'), findsOneWidget, reason: 'fallback survives a settled empty on-deck');
      expect(find.text('S1E1'), findsNothing);
    });

    testWidgets('shows directors when they are the only additional info', (tester) async {
      final movie = testMediaItem(
        id: 'director_only',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Director-only metadata',
        directors: ['Jane Director'],
        serverId: 'server_1',
        serverName: 'Server',
      );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});

      await pumpPhoneDetail(tester, client, movie);

      expect(find.text('Director'), findsOneWidget);
      expect(find.text('Jane Director'), findsOneWidget);
    });

    testWidgets('omits the director row for an empty list', (tester) async {
      final movie = testMediaItem(
        id: 'no_directors',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'No directors',
        studio: 'Example Studio',
        directors: const [],
        serverId: 'server_1',
        serverName: 'Server',
      );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});

      await pumpPhoneDetail(tester, client, movie);

      expect(find.text('Example Studio'), findsOneWidget);
      expect(find.text('Director'), findsNothing);
    });

    testWidgets('movie with multiple versions gets a split segment that plays the picked version', (tester) async {
      // Issue #1881: the split Play chevron makes multiple versions visible
      // on the detail screen and runs the existing Play Version flow.
      final versions = [MediaVersion(id: 'v1', videoResolution: '1080'), MediaVersion(id: 'v2', videoResolution: '4k')];
      final movie = testMediaItem(
        id: 'multi_version',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Multi Version',
        serverId: 'server_1',
        serverName: 'Server',
        mediaVersions: versions,
      );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});
      final observer = _RecordingNavigatorObserver(popVideoPlayerImmediately: true);

      await pumpPhoneDetail(tester, client, movie, observer: observer);

      final chevron = find.descendant(
        of: find.byType(FocusableActionBar),
        matching: find.byIcon(Symbols.keyboard_arrow_down_rounded),
      );
      expect(chevron, findsOneWidget);

      await tester.tap(chevron);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The existing version picker, listing every version. Scoped to the
      // dialog: the hero's quality chip also renders the resolution label.
      Finder inDialog(String text) => find.descendant(of: find.byType(Dialog), matching: find.text(text));
      expect(inDialog(t.mediaMenu.playVersion), findsOneWidget);
      expect(inDialog(versions[0].displayLabel), findsOneWidget);
      expect(inDialog(versions[1].displayLabel), findsOneWidget);

      await tester.tap(inDialog(versions[1].displayLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Jellyfin can transcode, so the quality picker follows; keep Original.
      await tester.tap(inDialog(t.videoControls.qualityOriginal));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRouteNames, contains(kVideoPlayerRouteName));
      // The pick is remembered so Continue Watching / plain Play resume it.
      final saved = await savedMediaVersionPreferenceFor(movie);
      expect(saved?.index, 1);
    });

    testWidgets('single-version movie keeps the plain play button', (tester) async {
      final movie = testMediaItem(
        id: 'single_version',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Single Version',
        serverId: 'server_1',
        serverName: 'Server',
        mediaVersions: [MediaVersion(id: 'v1', videoResolution: '1080')],
      );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});

      await pumpPhoneDetail(tester, client, movie);

      expect(
        find.descendant(
          of: find.byType(FocusableActionBar),
          matching: find.byIcon(Symbols.keyboard_arrow_down_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('portrait phone hero shows square art instead of the cropped backdrop', (tester) async {
      final movie = testMediaItem(
        id: 'square_hero',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Square hero',
        artPath: '/library/metadata/square_hero/art',
        backgroundSquarePath: '/library/metadata/square_hero/squareBg',
        serverId: 'server_1',
        serverName: 'Server',
      );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});

      await pumpPhoneDetail(tester, client, movie);

      final backdrop = find.byType(CyclingMediaBackdrop);
      expect(backdrop, findsOneWidget);
      // A fallback is reached only once every rotating path has failed, so the
      // square background has to be in the rotation set. Listed behind a
      // servable wide backdrop it would never be shown at all.
      final widget = tester.widget<CyclingMediaBackdrop>(backdrop);
      expect(widget.imagePaths, ['/library/metadata/square_hero/squareBg']);
      expect(widget.fallbackImagePaths, contains('/library/metadata/square_hero/art'));
      expect(client.thumbnailPaths.first, '/library/metadata/square_hero/squareBg');
    });

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
  final thumbnailPaths = <String?>[];

  /// On-deck episode returned by the next [fetchItemWithOnDeck]; mutate between
  /// loads to model the series being finished.
  MediaItem? onDeckEpisode;

  /// Held open to keep the on-deck half of a load in flight while the item half
  /// has already been published.
  Completer<void>? onDeckGate;

  /// Items handed to `onItemReady` — i.e. painted before on-deck settled.
  final earlyPaints = <MediaItem>[];

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
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async {
    // Mirrors the Jellyfin shape: the item is known first, on-deck needs a
    // second round trip.
    if (onItemReady != null) {
      earlyPaints.add(show);
      onItemReady(show);
    }
    final gate = onDeckGate;
    if (gate != null) await gate.future;
    return (item: show, onDeckEpisode: onDeckEpisode);
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (show.id == id) return show;
    for (final items in childrenByParent.values) {
      for (final item in items) {
        if (item.id == id) return item;
      }
    }
    return null;
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
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    thumbnailPaths.add(path);
    return '';
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  _RecordingNavigatorObserver({this.popVideoPlayerImmediately = false});

  final bool popVideoPlayerImmediately;
  final pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushedRouteNames.add(route.settings.name);
    if (popVideoPlayerImmediately && route.settings.name == kVideoPlayerRouteName) {
      scheduleMicrotask(() => navigator?.pop());
    }
  }
}
