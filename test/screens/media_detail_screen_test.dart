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
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_stream.dart';
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
import 'package:plezy/widgets/fitted_metadata_line.dart';
import 'package:plezy/widgets/fitting_title_text.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_details_sheet.dart';
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
    // The block is activatable: select/tap opens the full details sheet
    // showing everything the fitted line and truncated summary omit (#2042).
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.widget<Semantics>(information).properties.onTap, isNotNull);

    // Visual content and the separate action row remain present.
    expect(find.text('Semantic Movie'), findsOneWidget);
    expect(find.text('One concise detail announcement.'), findsOneWidget);
    expect(find.byType(FocusableActionBar), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TV detail hero info block opens the full details sheet on select', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const summary =
        'A cybersecurity expert becomes a whistleblower after uncovering secrets about aliens, putting him on '
        'the run from a corporation. Meanwhile, a meteorologist tracks a storm that never ends, and every '
        'agency denies any connection between the two events.';
    const movie = MediaItem.plex(
      id: 'movie_details_sheet',
      kind: MediaKind.movie,
      title: 'Disclosure Day',
      summary: summary,
      year: 2026,
      contentRating: 'PG-13',
      durationMs: 8700000,
      genres: ['Science Fiction', 'Mystery', 'Action'],
      ratings: [
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 8.0),
        MediaRatingSource(source: 'rottenTomatoesAudience', value: 6.9),
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

    // The reveal autofocuses the play button for movies; UP from the action
    // row lands on the hero information block.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_detail_info');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final sheet = find.byType(MediaDetailsSheet);
    expect(sheet, findsOneWidget);
    // Full description, not the hero's line-capped copy.
    final sheetSummary = tester.widget<Text>(find.descendant(of: sheet, matching: find.text(summary)));
    expect(sheetSummary.maxLines, isNull);
    // Every rating badge and metadata field the fitted hero line may shed.
    expect(find.descendant(of: sheet, matching: find.text('80%')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('69%')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('7.4')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.textContaining('2026  •  PG-13  •  2h 25min')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Science Fiction  •  Mystery  •  Action')), findsOneWidget);

    // D-pad back closes the sheet and restores focus to the hero block.
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();
    expect(find.byType(MediaDetailsSheet), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_detail_info');
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

  testWidgets('TV detail metadata line keeps quality labels for the sheet and every field on screen', (tester) async {
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
    // Stream quality describes the file, not the title: off the hero line,
    // on the action row's playback status instead (#2217).
    final information = find.byKey(const ValueKey('tv_detail_information_semantics'));
    expect(find.descendant(of: information, matching: find.text('1080p')), findsNothing);
    expect(
      find.descendant(of: find.byKey(const ValueKey('detail_playback_tracks')), matching: find.text('1080p')),
      findsOneWidget,
    );

    // Desktop chip order: year, certification, runtime.
    final fieldXs = [
      for (final text in ['2017', 'PG-13', '1h 46min']) tester.getTopLeft(find.text(text)).dx,
    ];
    expect(fieldXs, orderedEquals([...fieldXs]..sort()));
    expect(tester.getBottomRight(find.text('1h 46min')).dx, lessThanOrEqualTo(1280));

    // The test font's 1 em/char advance roughly doubles text width, so at this
    // viewport most of the ratings slot legitimately gives way — shed as the
    // least useful part instead of shoving the quality label off the line. Any
    // score that does fit must sit fully on screen, never past the right edge.
    for (final rating in find.byType(SvgPicture).evaluate()) {
      expect(tester.getBottomRight(find.byWidget(rating.widget)).dx, lessThanOrEqualTo(1280));
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_detail_info');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(MediaDetailsSheet), findsOneWidget);
    expect(find.descendant(of: find.byType(MediaDetailsSheet), matching: find.textContaining('1080p')), findsOneWidget);
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

  testWidgets('TV detail exposes each season as its episode hub leading options item', (tester) async {
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

    // Every season hub surfaces its own season as the leading options item —
    // the D-pad path to mark a whole season watched/unwatched (#2156).
    final rail = tester.widget<TvBrowseRail>(find.byType(TvBrowseRail));
    expect(rail.leadingItemForHub, isNotNull);
    final seasonHubs = rail.hubs.where((hub) => hub.id.startsWith('detail_season_')).toList();
    expect(seasonHubs, hasLength(2));
    expect(rail.leadingItemForHub!(seasonHubs[0])?.id, season1.id);
    expect(rail.leadingItemForHub!(seasonHubs[1])?.id, season2.id);

    // Non-season hubs (flatten episodes, actors, extras, related) get none.
    const flattenHub = MediaHub(id: 'detail_episodes', title: 'Episodes', type: 'episode', items: <MediaItem>[]);
    expect(rail.leadingItemForHub!(flattenHub), isNull);
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
    expect(find.descendant(of: find.byType(MediaCard), matching: find.text('Episode 2')), findsNothing);

    season2Completer.complete([episode2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.descendant(of: find.byType(MediaCard), matching: find.text('Episode 2')), findsOneWidget);
  });

  testWidgets('TV detail hero, rail cards, and Play all follow the focused episode', (tester) async {
    final semantics = tester.ensureSemantics();
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
      summary: 'The show summary.',
      genres: ['Drama', 'Mystery'],
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
      title: 'The One Where the Title Matters',
      summary: 'The episode summary.',
      index: 1,
      durationMs: 1380000,
      parentId: season.id,
      parentIndex: season.index,
      grandparentId: show.id,
      grandparentTitle: show.title,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode2 = testMediaItem(
      id: 'episode_2',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.episode,
      title: 'The One After',
      index: 2,
      durationMs: 1500000,
      parentId: season.id,
      parentIndex: season.index,
      grandparentId: show.id,
      grandparentTitle: show.title,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season],
        season.id: [episode, episode2],
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

    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    final heroTitle = find.byKey(const ValueKey('tv_detail_episode_title'));
    final information = find.bySemanticsIdentifier('tv_detail_information');

    // The hero line is the readable copy of the title (#2217).
    expect(heroTitle, findsOneWidget);
    expect(tester.widget<Text>(heroTitle).data, 'The One Where the Title Matters');
    expect(find.text('The episode summary.'), findsOneWidget);
    // The title sits above the episode's metadata line, inside the block that
    // opens the details sheet.
    final metadataLine = find.byType(FittedMetadataLine);
    expect(tester.getBottomLeft(heroTitle).dy, lessThanOrEqualTo(tester.getTopLeft(metadataLine).dy));
    expect(
      find.descendant(of: find.byKey(const ValueKey('tv_detail_information_semantics')), matching: heroTitle),
      findsOneWidget,
    );
    expect(tester.getSemantics(information).label, contains('The Show, The One Where the Title Matters, S1 E1'));

    // Genres are the show's and never change while browsing: not a hero row.
    // They stay in the announcement because the sheet the block opens has them.
    expect(find.text('Drama  •  Mystery'), findsNothing);
    expect(tester.getSemantics(information).label, contains('Drama, Mystery'));

    // Rail cards sit inside their own show: the episode title is the headline
    // and the subtitle identifies it by number and runtime — no show name.
    final cards = find.byType(MediaCard);
    expect(find.descendant(of: cards, matching: find.text('The One Where the Title Matters')), findsOneWidget);
    expect(find.descendant(of: cards, matching: find.text('S1 E1 · 23min')), findsOneWidget);
    expect(find.descendant(of: cards, matching: find.text('The One After')), findsOneWidget);
    expect(find.descendant(of: cards, matching: find.text('S1 E2 · 25min')), findsOneWidget);
    expect(find.descendant(of: cards, matching: find.text('The Show')), findsNothing);

    // Play agrees with the hero: the focused episode, not a stale on-deck.
    expect(find.text('S1E1'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<Text>(heroTitle).data, 'The One After');
    expect(find.text('S1E2'), findsOneWidget);
    expect(find.text('S1E1'), findsNothing);
    semantics.dispose();
  });

  testWidgets('TV detail action row ends with the tracks Play will use, off the focus path', (tester) async {
    await SettingsService.getInstance();
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const streams = [
      MediaStream(id: '1', kind: MediaStreamKind.video, index: 0, codec: 'hevc'),
      MediaStream(
        id: '101',
        kind: MediaStreamKind.audio,
        index: 1,
        codec: 'truehd',
        languageCode: 'eng',
        channels: 8,
        selected: true,
      ),
      MediaStream(id: '102', kind: MediaStreamKind.audio, index: 2, codec: 'aac', languageCode: 'jpn', channels: 2),
      MediaStream(id: '201', kind: MediaStreamKind.subtitle, index: 3, codec: 'srt', languageCode: 'eng'),
    ];
    const version = MediaVersion(
      id: 'v1',
      videoResolution: '1080',
      videoCodec: 'hevc',
      parts: [MediaPart(id: 'p1', streams: streams)],
    );
    final show = testMediaItem(
      id: 'show_1',
      backend: MediaBackend.plex,
      kind: MediaKind.show,
      title: 'The Show',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final season = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.plex,
      kind: MediaKind.season,
      title: 'Season 1',
      index: 1,
      parentId: show.id,
      serverId: show.serverId,
      serverName: show.serverName,
    );
    final episode = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Pilot',
      index: 1,
      parentId: season.id,
      parentIndex: season.index,
      grandparentId: show.id,
      grandparentTitle: show.title,
      serverId: show.serverId,
      serverName: show.serverName,
      mediaVersions: const [version],
    );
    final client = _FakeMediaServerClient(
      show: show,
      childrenByParent: {
        show.id: [season],
        season.id: [episode],
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
              child: SizedBox(width: 1920, height: 1080, child: MediaDetailScreen(metadata: show)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The row's trailing status is the player's own ladder run over the
    // server rows: Plex-selected English audio, subtitles off (no row selected).
    final status = find.byKey(const ValueKey('detail_playback_tracks'));
    expect(status, findsOneWidget);
    expect(
      tester.widget<Semantics>(status).properties.label,
      'Audio & Subtitles: 1080p, HEVC, English · TrueHD · 7.1, Off',
    );
    expect(find.text('English · TrueHD · 7.1'), findsOneWidget);

    // Right-aligned at the row's far end, in the hero's own ink — not the
    // muted chip colour — and level with the buttons.
    final bar = tester.getRect(find.byType(FocusableActionBar));
    final row = tester.getRect(find.ancestor(of: status, matching: find.byType(Row)).first);
    final statusRect = tester.getRect(status);
    expect(statusRect.right, closeTo(row.right, 1));
    expect(statusRect.left, greaterThan(bar.right));
    expect(statusRect.center.dy, closeTo(bar.center.dy, 1));
    final ink = tester.widget<Text>(find.text('English · TrueHD · 7.1')).style!.color!;
    expect(ink.a, 1.0);

    // It is information, not a sixth button: RIGHT past the last action stays
    // on the last action.
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_more');
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

    expect(find.descendant(of: find.byType(MediaCard), matching: find.text('Episode 1')), findsOneWidget);
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
      ThemeData? theme,
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
              theme: theme ?? monoTheme(dark: true),
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

    testWidgets('phone hero title fallback uses the light theme foreground', (tester) async {
      // The hero scrim washes artwork toward the near-white light background;
      // the old hard-coded white title vanished into it on bright covers.
      final show = buildShow();
      final theme = monoTheme(dark: false);
      await pumpPhoneDetail(tester, singleSeasonClient(show), show, theme: theme);

      final heroTitle = tester.widget<FittingTitleText>(find.byType(FittingTitleText).first);
      expect(heroTitle.style?.color, theme.colorScheme.onSurface);
      final shadow = heroTitle.style?.shadows?.single;
      expect(shadow, isNotNull);
      expect(shadow!.color.computeLuminance(), greaterThan(0.5), reason: 'light theme halos with a light shadow');
    });

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

    testWidgets('returning from playback refreshes watch state without the full-screen loader', (tester) async {
      // The post-playback refresh used to re-run _loadFullMetadata, which
      // raises _isLoadingMetadata — build then swaps the whole detail subtree
      // for a spinner — and refetches seasons, episodes and extras.
      final show = buildShow();
      final season1 = buildSeason(show, 1);
      final episode1 = buildEpisode(show, season1, 1);
      final episode2 = buildEpisode(show, season1, 2);

      final client = _FakeMediaServerClient(
        show: show,
        childrenByParent: {
          show.id: [season1],
          season1.id: [episode1, episode2],
        },
      )..onDeckEpisode = episode1;
      final observer = _RecordingNavigatorObserver(popVideoPlayerImmediately: true);

      await pumpPhoneDetail(tester, client, show, observer: observer);

      expect(find.text('S1E1'), findsOneWidget, reason: 'play button targets the on-deck episode');
      expect(find.text('1. Episode S1E1'), findsOneWidget);
      final childrenCallsBeforePlayback = client.childrenPageCalls.length;
      observer.pushedRouteNames.clear();

      // The next fetchItemWithOnDeck — the post-playback refresh — reports
      // the following episode as on deck.
      client.onDeckEpisode = episode2;

      await tester.tap(
        find.descendant(of: find.byType(FocusableActionBar), matching: find.byIcon(Symbols.play_arrow_rounded)),
      );
      // Pump the push, the immediate pop, and the refresh round-trip one
      // frame at a time: the old full-reload path swapped in a loading
      // scaffold here and unmounted the episode list.
      for (var i = 0; i < 8; i++) {
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'playback return must not raise the full-screen loader',
        );
        expect(
          find.text('1. Episode S1E1'),
          findsOneWidget,
          reason: 'loaded episode rows must survive the playback return',
        );
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRouteNames, contains(kVideoPlayerRouteName));
      // Watch state did refresh: the play button now targets the next episode.
      expect(find.text('S1E2'), findsOneWidget);
      // The lightweight refresh fetches the item + on-deck only — no season
      // or episode page refetch, no early-paint (both are full-loader work).
      expect(client.childrenPageCalls.length, childrenCallsBeforePlayback);
      expect(client.earlyPaints, hasLength(1));
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

    testWidgets('hero chip strip sheds chips by usefulness instead of wrapping', (tester) async {
      // The hero metadata strip is a single run: when it cannot fit, chips
      // drop by usefulness — rating badges from the end first, then the
      // quality label, certification, and runtime — never by wrapping onto a
      // second run the height clip would hide. The interactive Rate chip and
      // the year go last and first, respectively.
      final movie =
          testMediaItem(
            id: 'chip_movie',
            backend: MediaBackend.jellyfin,
            kind: MediaKind.movie,
            title: 'Chip Movie',
            year: 2017,
            contentRating: 'PG-13',
            durationMs: 6360000,
            mediaVersions: [MediaVersion(id: 'v1', videoResolution: '1080')],
            serverId: 'server_1',
            serverName: 'Server',
          ).copyWith(
            // Unbranded sources render a star icon plus the bare value text, so
            // each badge is findable by its formatted value.
            ratings: const [
              MediaRatingSource(source: 'critic', value: 9.2),
              MediaRatingSource(source: 'simkl', value: 7.4),
              MediaRatingSource(source: 'mal', value: 6.4),
            ],
          );
      final client = _FakeMediaServerClient(show: movie, childrenByParent: const {});

      await pumpPhoneDetail(tester, client, movie);

      Future<void> resizeTo(double width) async {
        tester.view.physicalSize = Size(width, 2400);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }

      final rate = t.mediaMenu.rate;
      void expectChips({required List<String> present, required List<String> absent}) {
        // The info rows below the hero repeat some values (e.g. the content
        // rating), so scope every lookup to the strip: the Wrap carrying the
        // always-present Rate chip.
        final strip = find.ancestor(of: find.text(rate), matching: find.byType(Wrap)).first;
        Finder chip(String text) => find.descendant(of: strip, matching: find.text(text));
        for (final text in present) {
          expect(chip(text), findsOneWidget, reason: '"$text" should be on the strip');
        }
        for (final text in absent) {
          expect(chip(text), findsNothing, reason: '"$text" should have been dropped');
        }
        // Single run: every survivor sits on the same line as the always-kept
        // Rate chip.
        final rateDy = tester.getCenter(find.text(rate)).dy;
        for (final text in present) {
          expect(tester.getCenter(chip(text)).dy, moreOrLessEquals(rateDy, epsilon: 4));
        }
        expect(tester.takeException(), isNull);
      }

      // 1100 wide: everything fits (test font ~13px/char puts the full strip
      // near 740px against ~1068px of hero width).
      expectChips(present: ['2017', 'PG-13', '1h 46min', '1080p', '9.2', '7.4', '6.4', rate], absent: []);

      // The scores pill sheds badges from the end before anything else.
      await resizeTo(660);
      expectChips(present: ['2017', 'PG-13', '1h 46min', '1080p', '9.2', rate], absent: ['7.4', '6.4']);

      // Then the whole pill, the quality label, and the certification go —
      // never the runtime, year, or Rate.
      await resizeTo(420);
      expectChips(present: ['2017', '1h 46min', rate], absent: ['9.2', '7.4', '6.4', '1080p', 'PG-13']);

      // Down to the bone: the year and the interactive Rate chip survive.
      await resizeTo(320);
      expectChips(present: ['2017', rate], absent: ['1h 46min', '1080p', 'PG-13', '9.2']);
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

      expect(find.text('1. Episode S2E1'), findsOneWidget);
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

      expect(find.text('2. Episode S2E2'), findsOneWidget);
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
      expect(find.text('1. Episode S2E1'), findsOneWidget);
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
      expect(episodeRowWatched(tester, '1. Episode S1E1'), isFalse);

      await emit(tester, () => WatchStateNotifier().notifyWatched(item: show, isNowWatched: true));

      expect(episodeRowWatched(tester, '1. Episode S1E1'), isTrue);
      expect(episodeRowWatched(tester, '2. Episode S1E2'), isTrue);
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

      expect(episodeRowWatched(tester, '1. Episode S1E1'), isTrue);
      expect(episodeRowWatched(tester, '2. Episode S1E2'), isTrue);
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
      expect(episodeRowHasProgress(tester, '1. Episode S1E1'), isTrue);

      await emit(tester, () => WatchStateNotifier().notifyWatched(item: show, isNowWatched: true));
      expect(episodeRowHasProgress(tester, '1. Episode S1E1'), isFalse);
      expect(episodeRowWatched(tester, '1. Episode S1E1'), isTrue);

      // Round-trip through another season tab; the cached page restore must not
      // resurrect the dead progress offset.
      await tester.tap(find.text('Season 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Season 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(episodeRowHasProgress(tester, '1. Episode S1E1'), isFalse);
      expect(episodeRowWatched(tester, '1. Episode S1E1'), isTrue);
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
