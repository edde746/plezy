import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_glow_overlay.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  test('full bleed grid delegates use image aspect ratios', () {
    expect(MediaGridDelegate.aspectRatioFor(fullBleedImage: true), GridLayoutConstants.fullCardPosterAspectRatio);
    expect(
      MediaGridDelegate.aspectRatioFor(useWideAspectRatio: true, fullBleedImage: true),
      GridLayoutConstants.episodeThumbnailAspectRatio,
    );
    expect(MediaGridDelegate.aspectRatioFor(useWideAspectRatio: true), GridLayoutConstants.episodeGridCellAspectRatio);
  });

  testWidgets('full bleed grid delegates use scaled gutters', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    late SliverGridDelegateWithMaxCrossAxisExtent delegate;
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            delegate = MediaGridGeometry.resolve(
              context: context,
              crossAxisExtent: 1280,
              density: LibraryDensity.defaultValue,
              fullBleedImage: true,
            ).delegate;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(delegate.crossAxisSpacing, greaterThan(0));
    expect(delegate.mainAxisSpacing, delegate.crossAxisSpacing);
    expect(delegate.crossAxisSpacing, GridLayoutConstants.fullCardGridSpacingForScale(0.85));
  });

  testWidgets('full bleed grid media cards hide text when constrained by a grid cell', (tester) async {
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Hidden Movie',
      year: 2024,
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 300,
          child: MediaCard(item: item, forceGridMode: true, fullBleedImage: true, isOffline: true),
        ),
      ),
    );

    expect(find.text('Hidden Movie'), findsNothing);
    expect(find.text('2024'), findsNothing);
    expect(tester.getSize(find.byType(InkWell)), const Size(200, 300));
  });

  testWidgets('standard grid media cards still show text', (tester) async {
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Visible Movie',
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
      ),
    );

    expect(find.text('Visible Movie'), findsOneWidget);
  });

  testWidgets('catalog grid metadata leads with the rating and omits certification', (tester) async {
    // Measured on a Pixel 7: at shelf width the full list composition renders
    // `PG-13 • 2006 • 2h 10mi…` and ellipsizes the rating away — the one value
    // this line exists to surface. The grid therefore leads with the rating
    // and drops certification, votes and genres; the list keeps them.
    final item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Catalog Movie',
      year: 2024,
      runtimeMinutes: 125,
      rating: 8.6,
      votes: 12345,
      genres: const ['Drama', 'Mystery'],
      certification: 'PG-13',
      ids: const CatalogItemIds(tmdb: 1),
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(item));

    final metadata = tester.widget<Text>(
      find.byWidgetPredicate((widget) => widget is Text && (widget.data?.contains('8.6★') ?? false)),
    );
    expect(metadata.maxLines, 1);
    expect(metadata.overflow, TextOverflow.ellipsis);
    expect(metadata.data, '8.6★ • 2024 • 2h 5min');
    expect(metadata.data, isNot(contains('PG-13')), reason: 'certification is detail/search only');
    expect(metadata.data, isNot(contains('Drama')), reason: 'genres do not fit a shelf caption');
    expect(metadata.data, isNot(contains('(')), reason: 'vote counts do not fit a shelf caption');
  });

  testWidgets('plain library grid metadata remains year only', (tester) async {
    final item = testMediaItem(
      id: 'library-movie',
      kind: MediaKind.movie,
      title: 'Library Movie',
      year: 2024,
      contentRating: 'PG-13',
      durationMs: const Duration(minutes: 125).inMilliseconds,
      rating: 8.6,
      genres: const ['Drama'],
    );

    await tester.pumpWidget(_catalogGridHarness(item));

    expect(find.text('2024'), findsOneWidget);
    expect(find.textContaining('PG-13'), findsNothing);
    expect(find.textContaining('2h 5m'), findsNothing);
    expect(find.textContaining('8.6★'), findsNothing);
    expect(find.textContaining('Drama'), findsNothing);
  });

  testWidgets('seasonal rank badge names its season instead of claiming all-time rank', (tester) async {
    final item = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'Seasonal Show',
      ids: const CatalogItemIds(anilist: 1),
      ranks: const [
        CatalogRank(
          rank: 3,
          scope: CatalogRankScope.popular,
          allTime: false,
          year: 2026,
          season: CatalogSeasonName.summer,
        ),
      ],
    ).toMediaItem();
    final season = t.explore.season.withYear(season: t.explore.season.summer, year: 2026);

    await tester.pumpWidget(_catalogGridHarness(item));

    expect(find.text(t.explore.badge.rankSeasonal(n: 3, season: season)), findsOneWidget);
    expect(find.text(t.explore.badge.rankPopular(n: 3)), findsNothing);
  });

  testWidgets('windowed viewers render only when their period is present', (tester) async {
    final withoutPeriod = CatalogItem(
      source: CatalogSourceId.simkl,
      kind: MediaKind.show,
      title: 'No Viewer Window',
      ids: const CatalogItemIds(simkl: 1),
      audience: const CatalogAudience(viewers: 37),
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(withoutPeriod, key: const ValueKey('viewer-card')));
    expect(find.textContaining('37'), findsNothing);

    final withPeriod = CatalogItem(
      source: CatalogSourceId.simkl,
      kind: MediaKind.show,
      title: 'Viewer Window',
      ids: const CatalogItemIds(simkl: 1),
      audience: const CatalogAudience(viewers: 37, viewersPeriod: CatalogAudiencePeriod.week),
    ).toMediaItem();
    await tester.pumpWidget(_catalogGridHarness(withPeriod, key: const ValueKey('viewer-card')));

    expect(find.text(t.explore.stats.viewersWeek(n: '37')), findsOneWidget);
  });

  testWidgets('HD availability and pending 4K request render as independent badges', (tester) async {
    final item = CatalogItem(
      source: CatalogSourceId.seerr,
      kind: MediaKind.movie,
      title: 'Server Movie',
      ids: const CatalogItemIds(tmdb: 1),
      serverState: const CatalogServerState(
        availability: CatalogAvailability.available,
        request4k: CatalogRequestState.pending,
      ),
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(item));

    expect(find.text(t.explore.badge.available), findsOneWidget);
    expect(find.text(t.explore.badge.pendingApproval), findsOneWidget);
  });

  testWidgets('catalog poster badges are capped at three by priority', (tester) async {
    final item = CatalogItem(
      source: CatalogSourceId.seerr,
      kind: MediaKind.show,
      title: 'Busy Show',
      ids: const CatalogItemIds(tmdb: 1),
      isAdult: true,
      serverState: const CatalogServerState(
        availability: CatalogAvailability.available,
        request4k: CatalogRequestState.pending,
      ),
      nextEpisode: CatalogNextEpisode(airsAt: DateTime.now().add(const Duration(days: 1)), episode: 4),
      ranks: const [CatalogRank(rank: 2, scope: CatalogRankScope.popular)],
      audience: const CatalogAudience(watchingNow: 200),
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(item));

    final badgeTexts = find.descendant(of: find.byKey(const Key('catalog-badges')), matching: find.byType(Text));
    expect(badgeTexts, findsNWidgets(3));
    expect(find.text(t.explore.badge.available), findsOneWidget);
    expect(find.text(t.explore.badge.pendingApproval), findsOneWidget);
    expect(find.text(t.explore.badge.adult), findsOneWidget);
    expect(find.text(t.explore.badge.rankPopular(n: 2)), findsNothing);
  });

  testWidgets('catalog item is rehydrated once across rebuilds of the same item identity', (tester) async {
    final catalog = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Cached Catalog Movie',
      ids: const CatalogItemIds(tmdb: 1),
      ranks: const [CatalogRank(rank: 1, scope: CatalogRankScope.trending)],
    );
    final rawCatalog = _ReadCountingMap(catalog.toJson());
    final mediaItem = testMediaItem(
      id: 'catalog:cached',
      kind: MediaKind.movie,
      title: catalog.title,
      raw: {CatalogItem.rawKey: rawCatalog},
    );
    const cardKey = ValueKey('cached-catalog-card');

    await tester.pumpWidget(_catalogGridHarness(mediaItem, key: cardKey));
    final readsAfterFirstBuild = rawCatalog.reads;
    expect(readsAfterFirstBuild, greaterThan(0));

    await tester.pumpWidget(_catalogGridHarness(mediaItem, key: cardKey));
    expect(rawCatalog.reads, readsAfterFirstBuild);
  });

  testWidgets('catalog poster selection covers the card width at device pixel ratio', (tester) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = CatalogItem(
      source: CatalogSourceId.seerr,
      kind: MediaKind.movie,
      title: 'Sharp Poster',
      ids: const CatalogItemIds(tmdb: 1),
      posterUrl: 'https://example.com/default.jpg',
      posterVariants: const {200: 'https://example.com/200.jpg', 500: 'https://example.com/500.jpg'},
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(item, width: 150));

    final image = tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage));
    expect(image.imagePath, 'https://example.com/500.jpg');
  });

  testWidgets('recommendation badge prefers a user count and falls back to viewer percentage', (tester) async {
    final withCount = CatalogItem(
      source: CatalogSourceId.simkl,
      kind: MediaKind.movie,
      title: 'Counted Recommendation',
      ids: const CatalogItemIds(simkl: 1),
      recommendationCount: 19,
      recommendationPercent: 0.42,
    ).toMediaItem();

    await tester.pumpWidget(_catalogGridHarness(withCount, key: const ValueKey('recommendation-card')));
    expect(find.text(t.explore.detail.recommendedByUsers(n: 19)), findsOneWidget);
    expect(find.text(t.explore.detail.recommendedByPercent(percent: '42%')), findsNothing);

    final withPercent = CatalogItem(
      source: CatalogSourceId.simkl,
      kind: MediaKind.movie,
      title: 'Percentage Recommendation',
      ids: const CatalogItemIds(simkl: 2),
      recommendationPercent: 0.42,
    ).toMediaItem();
    await tester.pumpWidget(_catalogGridHarness(withPercent, key: const ValueKey('recommendation-card')));

    expect(find.text(t.explore.detail.recommendedByPercent(percent: '42%')), findsOneWidget);
  });

  testWidgets('full bleed flag does not hide list media card text', (tester) async {
    final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'List Movie');

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 420,
          height: 160,
          child: MediaCard(item: item, forceListMode: true, fullBleedImage: true, isOffline: true),
        ),
      ),
    );

    expect(find.text('List Movie'), findsOneWidget);
  });

  testWidgets('catalog list metadata keeps certification, votes and genres', (tester) async {
    // The counterpart to the grid contract above: search uses the list card,
    // which is wide enough for the full composition and must not be trimmed
    // by the grid's compact mode.
    final item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Catalog Movie',
      year: 2024,
      runtimeMinutes: 125,
      rating: 8.6,
      votes: 12345,
      genres: const ['Drama', 'Mystery'],
      certification: 'PG-13',
      ids: const CatalogItemIds(tmdb: 1),
    ).toMediaItem();

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 420, height: 160, child: MediaCard(item: item, forceListMode: true, isOffline: true)),
      ),
    );

    final metadata = tester.widget<Text>(
      find.byWidgetPredicate((widget) => widget is Text && (widget.data?.contains('8.6★') ?? false)),
    );
    expect(metadata.data, startsWith('PG-13 • 2024 • 2h 5m'));
    expect(metadata.data, contains('8.6★ (12.3K)'));
    expect(metadata.data, contains('Drama, Mystery'));
  });

  testWidgets('full bleed focusable media card lifts the glow into an overlay above siblings', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode(debugLabel: 'full_bleed_card');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));

    // Unfocused: the overlay glow (and its leader) is not mounted.
    expect(find.byType(CompositedTransformTarget), findsNothing);
    expect(find.byType(CompositedTransformFollower), findsNothing);

    focusNode.requestFocus();
    await tester.pump(); // focus change mounts the overlay portal + leader
    await tester.pump(); // leaderSize resolves, glow fades in
    await tester.pump(const Duration(milliseconds: 200));

    // The glow now follows the card from the overlay, so it paints above siblings.
    expect(find.byType(FocusGlowOverlay), findsOneWidget);
    expect(find.byType(CompositedTransformTarget), findsOneWidget);
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CompositedTransformFollower), matching: find.byType(CustomPaint)),
      findsOneWidget,
    );

    // The crisp focus border stays in-card as a foreground decoration; the glow
    // is no longer in the background decoration.
    final borderContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(FocusGlowOverlay), matching: find.byType(AnimatedContainer)).first,
    );
    expect(borderContainer.decoration, isNull);
    final border = (borderContainer.foregroundDecoration as BoxDecoration).border as Border;
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);

    // The glow itself is two shadows.
    expect(FocusTheme.focusGlowShadows(const Color(0xFFFFFFFF)), hasLength(2));
  });

  testWidgets('non full bleed card does not use the overlay glow', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: false));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(find.byType(FocusGlowOverlay), findsNothing);
    expect(find.byType(CompositedTransformFollower), findsNothing);
  });

  testWidgets('overlay glow fades out and unmounts when focus is lost', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CompositedTransformFollower), findsOneWidget);

    focusNode.unfocus();
    await tester.pump(); // begin fade-out
    await tester.pump(const Duration(milliseconds: 300)); // fade completes -> hide
    await tester.pump(); // rebuild drops the gated-out leader/portal
    expect(find.byType(CompositedTransformFollower), findsNothing);
  });

  testWidgets('touch mode shows no overlay glow on a full bleed card', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false); // pointer mode
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompositedTransformFollower), findsNothing);
  });
  testWidgets('grid and list cards expose card and detail actions without decorative semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final item = testMediaItem(
      id: 'semantic_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Decorative Episode Title',
      summary: 'Decorative episode summary',
      parentId: 'season_2',
      parentIndex: 2,
      index: 3,
      grandparentId: 'show_1',
      grandparentTitle: 'Semantic Series',
    );

    for (final forceGridMode in [true, false]) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: forceGridMode ? 200 : 420,
            height: forceGridMode ? 330 : 180,
            child: MediaCard(item: item, forceGridMode: forceGridMode, forceListMode: !forceGridMode, isOffline: true),
          ),
        ),
      );

      final cardData = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
      expect(cardData.flagsCollection.isButton, isTrue);
      expect(cardData.hasAction(ui.SemanticsAction.tap), isTrue);

      for (final detailLabel in ['Semantic Series', 'S2']) {
        final detailData = tester.getSemantics(find.bySemanticsLabel(detailLabel)).getSemanticsData();
        expect(detailData.flagsCollection.isButton, isTrue);
        expect(detailData.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(detailData.hint, t.mediaMenu.viewDetails);
      }

      expect(find.bySemanticsLabel(RegExp('Decorative Episode Title|Decorative episode summary')), findsNothing);
    }

    semantics.dispose();
  });

  testWidgets('movie and season title links remain distinct semantic actions', (tester) async {
    final semantics = tester.ensureSemantics();
    final scenarios = [
      (
        item: testMediaItem(
          id: 'linked_movie',
          kind: MediaKind.movie,
          title: 'Linked Movie',
          summary: 'Movie decorative summary',
        ),
        forceGridMode: true,
        detailLabel: 'Linked Movie',
        decorativeLabel: 'Movie decorative summary',
      ),
      (
        item: testMediaItem(
          id: 'linked_season',
          kind: MediaKind.season,
          title: 'Season Two',
          parentId: 'linked_show',
          parentTitle: 'Linked Series',
          summary: 'Season decorative summary',
        ),
        forceGridMode: false,
        detailLabel: 'Linked Series',
        decorativeLabel: 'Season Two',
      ),
    ];

    for (final scenario in scenarios) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: scenario.forceGridMode ? 200 : 420,
            height: scenario.forceGridMode ? 330 : 180,
            child: MediaCard(
              item: scenario.item,
              forceGridMode: scenario.forceGridMode,
              forceListMode: !scenario.forceGridMode,
              isOffline: true,
            ),
          ),
        ),
      );

      expect(
        tester
            .getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(scenario.item)))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      final detail = tester.getSemantics(find.bySemanticsLabel(scenario.detailLabel)).getSemanticsData();
      expect(detail.flagsCollection.isButton, isTrue);
      expect(detail.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(detail.hint, t.mediaMenu.viewDetails);
      expect(find.bySemanticsLabel(scenario.decorativeLabel), findsNothing);
    }

    semantics.dispose();
  });

  testWidgets('TV cards keep focus semantics only for accessible navigation', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode(debugLabel: 'semantic_card');
    addTearDown(focusNode.dispose);
    final item = testMediaItem(id: 'focus_semantic_movie', kind: MediaKind.movie, title: 'Focus Semantic Movie');

    Widget card({required bool accessibleNavigation}) => _TestApp(
      child: MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessibleNavigation),
        child: SizedBox(
          width: 200,
          height: 330,
          child: FocusableMediaCard(item: item, focusNode: focusNode, isOffline: true),
        ),
      ),
    );
    bool hasFocusedSemantics() {
      final nodes = <SemanticsNode>[];
      void collect(SemanticsNode node) {
        nodes.add(node);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
      return nodes.any((node) => node.getSemanticsData().flagsCollection.isFocused == ui.Tristate.isTrue);
    }

    await tester.pumpWidget(card(accessibleNavigation: false));
    focusNode.requestFocus();
    await tester.pump();

    final cardData = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
    expect(cardData.flagsCollection.isButton, isTrue);
    expect(cardData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(hasFocusedSemantics(), isFalse);

    await tester.pumpWidget(card(accessibleNavigation: true));
    focusNode.requestFocus();
    await tester.pump();

    expect(hasFocusedSemantics(), isTrue);
    semantics.dispose();
  });

  testWidgets('TV cards collapse pointer-only detail semantics without a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final item = testMediaItem(
      id: 'tv_semantic_movie',
      kind: MediaKind.movie,
      title: 'TV Semantic Movie',
      summary: 'TV decorative summary',
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
      ),
    );

    final card = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
    expect(card.flagsCollection.isButton, isTrue);
    expect(card.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('TV Semantic Movie'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('TV decorative summary')), findsNothing);
    semantics.dispose();
  });

  testWidgets('TV cards preserve detail semantics for accessible navigation', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final item = testMediaItem(id: 'tv_accessible_movie', kind: MediaKind.movie, title: 'Accessible TV Movie');

    await tester.pumpWidget(
      _TestApp(
        child: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
        ),
      ),
    );

    final detail = tester.getSemantics(find.bySemanticsLabel('Accessible TV Movie')).getSemanticsData();
    expect(detail.flagsCollection.isButton, isTrue);
    expect(detail.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('custom card actions keep detail-link semantics disabled in grid and list modes', (tester) async {
    final semantics = tester.ensureSemantics();
    final item = testMediaItem(
      id: 'semantic_movie',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Semantic Movie',
      summary: 'Decorative movie summary',
    );
    var tapCount = 0;

    for (final forceGridMode in [true, false]) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: forceGridMode ? 200 : 420,
            height: forceGridMode ? 330 : 180,
            child: MediaCard(
              item: item,
              forceGridMode: forceGridMode,
              forceListMode: !forceGridMode,
              isOffline: true,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      final card = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item)));
      expect(card.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('Custom Semantic Movie'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Decorative movie summary')), findsNothing);

      card.owner!.performAction(card.id, ui.SemanticsAction.tap);
      expect(tapCount, forceGridMode ? 1 : 2);
    }

    semantics.dispose();
  });

  testWidgets('custom tap owns pointer and programmatic activation', (tester) async {
    final item = testMediaItem(
      id: 'custom_tap',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Tap Movie',
    );
    final cardKey = GlobalKey<MediaCardState>();
    var tapCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 330,
          child: MediaCard(key: cardKey, item: item, forceGridMode: true, isOffline: true, onTap: () => tapCount++),
        ),
      ),
    );

    await tester.tap(find.text('Custom Tap Movie'));
    expect(tapCount, 1);

    cardKey.currentState!.handleTap();
    expect(tapCount, 2);
  });

  testWidgets('custom long press owns pointer and programmatic activation', (tester) async {
    final item = testMediaItem(
      id: 'custom_long_press',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Long Press Movie',
    );
    final cardKey = GlobalKey<MediaCardState>();
    var longPressCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 330,
          child: MediaCard(
            key: cardKey,
            item: item,
            forceGridMode: true,
            isOffline: true,
            onLongPress: () => longPressCount++,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Custom Long Press Movie'));
    expect(longPressCount, 1);

    cardKey.currentState!.showContextMenu();
    expect(longPressCount, 2);
  });
}

Widget _fullCardHarness({required FocusNode focusNode, required bool fullBleed}) {
  final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Focused Movie');
  return InputModeTracker(
    child: _TestApp(
      child: SizedBox(
        width: 200,
        height: 300,
        child: FocusableMediaCard(item: item, fullBleedImage: fullBleed, focusNode: focusNode, isOffline: true),
      ),
    ),
  );
}

Widget _catalogGridHarness(MediaItem item, {Key? key, double width = 220}) {
  return _TestApp(
    child: SizedBox(
      width: width,
      height: 330,
      child: MediaCard(
        key: key,
        item: item,
        width: width,
        height: 280,
        forceGridMode: true,
        isOffline: true,
        onTap: () {},
      ),
    ),
  );
}

class _ReadCountingMap extends MapBase<String, Object?> {
  final Map<String, Object?> _values;
  int reads = 0;

  _ReadCountingMap(this._values);

  @override
  Object? operator [](Object? key) {
    reads++;
    return _values[key];
  }

  @override
  void operator []=(String key, Object? value) {
    _values[key] = value;
  }

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  @override
  Object? remove(Object? key) => _values.remove(key);
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
