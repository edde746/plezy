import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/locked_hub_controller.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TvBrowseRailLayout', () {
    test('density changes card width', () {
      final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final hub = MediaHub(id: 'hub_1', title: 'Movies', type: 'movie', items: [item], size: 1);

      final compact = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.min,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        scale: 0.85,
      );
      final comfortable = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        scale: 0.85,
      );

      expect(comfortable.cardWidth, greaterThan(compact.cardWidth));
      expect(comfortable.posterWidth, greaterThan(compact.posterWidth));
    });

    test('detail episode hubs can force episode thumbnails', () {
      final episode = MediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
        grandparentThumbPath: '/show-poster',
      );
      final hub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: [episode], size: 1);

      final defaultLayout = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        scale: 0.85,
      );
      final forcedLayout = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: 0.85,
      );
      final compactForcedLayout = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: 0.85,
        widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      );

      expect(defaultLayout.useWideLayout, isFalse);
      expect(forcedLayout.useWideLayout, isTrue);
      expect(forcedLayout.posterHeight, lessThan(defaultLayout.posterHeight));
      expect(compactForcedLayout.useWideLayout, isTrue);
      expect(compactForcedLayout.cardWidth, lessThan(forcedLayout.cardWidth));
      expect(compactForcedLayout.posterHeight, lessThan(forcedLayout.posterHeight));
    });

    test('estimated rail height is stable across mixed hub heights', () {
      final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final episode = MediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
      );
      final posterHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
      final wideHub = MediaHub(id: 'episodes', title: 'Episodes', type: 'episode', items: [episode], size: 1);

      const size = Size(1280, 720);
      final scale = TvBrowseRailLayout.scaleForSize(size);
      final availableWidth = size.width - TvBrowseRailLayout.horizontalInsetForScale(scale);
      final posterMetrics = TvBrowseRailLayout.metricsForHub(
        hub: posterHub,
        availableWidth: availableWidth,
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: scale,
      );
      final wideMetrics = TvBrowseRailLayout.metricsForHub(
        hub: wideHub,
        availableWidth: availableWidth,
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: scale,
      );

      final maxHeight = TvBrowseRailLayout.maxActiveRailHeight(
        hubs: [wideHub, posterHub],
        availableWidth: availableWidth,
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: scale,
      );

      final estimate = TvBrowseRailLayout.estimateHeight(
        size: size,
        hubs: [wideHub, posterHub],
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
      );
      final posterSectionHeight = TvBrowseRailLayout.hubSectionHeightFor(
        scale: scale,
        activeRailHeight: posterMetrics.height,
      );
      final expectedPosterEstimate =
          TvBrowseRailLayout.railTopPaddingForScale(scale) +
          TvBrowseRailLayout.viewportHeightFor(hubCount: 2, scale: scale, sectionHeight: posterSectionHeight) +
          TvBrowseRailLayout.railBottomPaddingForScale(scale);

      expect(posterMetrics.height, greaterThan(wideMetrics.height));
      expect(maxHeight, posterMetrics.height);
      expect(estimate, closeTo(expectedPosterEstimate, 0.001));
      expect(
        estimate,
        TvBrowseRailLayout.estimateHeight(
          size: size,
          hubs: [posterHub, wideHub],
          density: LibraryDensity.max,
          episodePosterMode: EpisodePosterMode.episodeThumbnail,
        ),
      );
    });

    test('compact tall poster scale reduces browse rail height', () {
      final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

      const size = Size(1280, 720);
      final defaultHeight = TvBrowseRailLayout.estimateHeight(
        size: size,
        hubs: [hub],
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.seriesPoster,
      );
      final compactHeight = TvBrowseRailLayout.estimateHeight(
        size: size,
        hubs: [hub],
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
      );

      expect(compactHeight, lessThan(defaultHeight));
    });

    test('empty episode thumbnail hubs reserve thumbnail row height', () {
      final episode = MediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
      );
      const emptyHub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: <MediaItem>[]);
      final loadedHub = MediaHub(id: emptyHub.id, title: emptyHub.title, type: emptyHub.type, items: [episode]);
      const size = Size(1280, 720);
      final scale = TvBrowseRailLayout.scaleForSize(size);
      final availableWidth = size.width - TvBrowseRailLayout.horizontalInsetForScale(scale);

      final emptyMetrics = TvBrowseRailLayout.metricsForHub(
        hub: emptyHub,
        availableWidth: availableWidth,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: scale,
        tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
        widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      );
      final loadedMetrics = TvBrowseRailLayout.metricsForHub(
        hub: loadedHub,
        availableWidth: availableWidth,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: scale,
        tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
        widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      );

      expect(emptyMetrics.useWideLayout, isTrue);
      expect(emptyMetrics.posterHeight, closeTo(loadedMetrics.posterHeight, 0.001));
      expect(emptyMetrics.height, closeTo(loadedMetrics.height, 0.001));
    });

    test('full card layout removes label reserve and preserves episode poster mode', () {
      final episode = MediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
        grandparentThumbPath: '/show-poster',
      );
      final hub = MediaHub(id: 'episodes', title: 'Episodes', type: 'episode', items: [episode], size: 1);

      final detailed = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: 0.85,
      );
      final full = TvBrowseRailLayout.metricsForHub(
        hub: hub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: 0.85,
        fullCardLayout: true,
      );

      expect(full.height, lessThan(detailed.height));
      expect(full.useWideLayout, isTrue);
      expect(detailed.itemGap, 0);
      expect(full.itemGap, closeTo(12 * 0.85, 0.001));
      expect(full.posterHeight, closeTo(full.posterWidth * 9 / 16, 0.001));
    });

    test('compact wide poster scale makes clips match compact episode thumbnails', () {
      final episode = MediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
      );
      final clip = MediaItem(
        id: 'clip_1',
        backend: MediaBackend.plex,
        kind: MediaKind.clip,
        title: 'Trailer',
        thumbPath: '/trailer-thumb',
      );
      final episodeHub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: [episode], size: 1);
      final clipHub = MediaHub(id: 'detail_extras', title: 'Extras', type: 'clip', items: [clip], size: 1);

      final episodeMetrics = TvBrowseRailLayout.metricsForHub(
        hub: episodeHub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.episodeThumbnail,
        scale: 0.85,
        widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      );
      final clipMetrics = TvBrowseRailLayout.metricsForHub(
        hub: clipHub,
        availableWidth: 1040,
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        scale: 0.85,
        widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      );

      expect(clipMetrics.useWideLayout, isTrue);
      expect(clipMetrics.cardWidth, closeTo(episodeMetrics.cardWidth, 0.001));
      expect(clipMetrics.posterHeight, closeTo(episodeMetrics.posterHeight, 0.001));
    });

    test('multi-hub estimate reserves next hub peek height', () {
      final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
      final showHub = MediaHub(id: 'shows', title: 'Shows', type: 'show', items: [movie], size: 1);

      const size = Size(1280, 720);
      final scale = TvBrowseRailLayout.scaleForSize(size);
      final singleHubHeight = TvBrowseRailLayout.estimateHeight(
        size: size,
        hubs: [movieHub],
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.seriesPoster,
      );
      final multiHubHeight = TvBrowseRailLayout.estimateHeight(
        size: size,
        hubs: [movieHub, showHub],
        density: LibraryDensity.max,
        episodePosterMode: EpisodePosterMode.seriesPoster,
      );

      expect(multiHubHeight - singleHubHeight, closeTo(TvBrowseRailLayout.nextHubPeekHeightForScale(scale), 0.001));
    });
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    HubFocusMemory.clear();
    await SettingsService.getInstance();
  });

  testWidgets('active hub header uses theme foreground in light mode', (tester) async {
    final serverManager = MultiServerManager();
    final theme = monoTheme(dark: false);
    final episode = MediaItem(id: 'episode_1', backend: MediaBackend.plex, kind: MediaKind.episode, title: 'Episode 1');
    final hub = MediaHub(id: 'season_1', title: 'Season 1', type: 'episode', items: [episode], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(hubs: [hub], iconForHub: (_, _) => Icons.tv_rounded),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final headerText = tester.widget<Text>(find.text('Season 1'));
    expect(headerText.style?.color, theme.colorScheme.onSurface);
  });

  testWidgets('full card layout hides media text and overlays actor text when enabled', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, true);

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Hidden Movie');
    final actor = MediaItem(
      id: 'actor_1',
      backend: MediaBackend.plex,
      kind: MediaKind.unknown,
      title: 'Actor Name',
      parentTitle: 'Character Name',
    );
    final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
    final actorHub = MediaHub(id: 'actors', title: 'Cast', type: 'person', items: [actor], size: 1);

    Widget rail(MediaHub hub) {
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(hubs: [hub], iconForHub: (_, _) => Icons.movie_rounded),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(rail(movieHub));
    await tester.pump();
    expect(find.text('Hidden Movie'), findsNothing);

    await tester.pumpWidget(rail(actorHub));
    await tester.pump();
    expect(find.text('Actor Name'), findsOneWidget);
    expect(find.text('Character Name'), findsOneWidget);
  });

  testWidgets('full card focus adds outside ring, local glow, and card image scale', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, true);

    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(hubs: [hub], autofocus: true, iconForHub: (_, _) => Icons.movie_rounded),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: 1280 - TvBrowseRailLayout.horizontalInsetForScale(scale),
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.seriesPoster,
      scale: scale,
      fullCardLayout: true,
    );

    // The focused card mounts a leader (CompositedTransformTarget); scope to it
    // so we measure the focused card's in-card border container.
    final cardFinder = find
        .descendant(of: find.byType(CompositedTransformTarget), matching: find.byType(AnimatedContainer))
        .first;
    final borderContainer = tester.widget<AnimatedContainer>(cardFinder);
    final border = (borderContainer.foregroundDecoration as BoxDecoration).border as Border;
    final cardSize = tester.getSize(cardFinder);
    final focusScale = tester.widget<AnimatedScale>(
      find.ancestor(of: cardFinder, matching: find.byType(AnimatedScale)).first,
    );

    // The border stays in-card; the glow now renders in an overlay that follows
    // the focused card so it paints above siblings on all sides.
    expect(borderContainer.decoration, isNull);
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(CompositedTransformTarget), findsOneWidget);
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CompositedTransformFollower), matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
    expect(focusScale.scale, closeTo(1.03, 0.0001));
    expect(cardSize.width, closeTo(metrics.cardWidth, 0.001));
    expect(cardSize.height, closeTo(metrics.posterHeight, 0.001));
  });

  testWidgets('vertical hub viewport keeps top clipping while switching hubs', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, true);

    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final firstMovie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 1');
    final secondMovie = MediaItem(id: 'movie_2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 2');
    final firstHub = MediaHub(id: 'movies_1', title: 'Movies 1', type: 'movie', items: [firstMovie], size: 1);
    final secondHub = MediaHub(id: 'movies_2', title: 'Movies 2', type: 'movie', items: [secondMovie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  hubs: [firstHub, secondHub],
                  autofocus: true,
                  iconForHub: (_, _) => Icons.movie_rounded,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final expectedLeftOverflow = TvBrowseRailLayout.horizontalInsetForScale(scale);
    final verticalViewportClip = tester
        .widgetList<ClipRect>(
          find.ancestor(of: find.byKey(const ValueKey('tv_browse_rail_vertical')), matching: find.byType(ClipRect)),
        )
        .singleWhere((widget) => widget.clipper != null);
    final clipRectSize = tester.getSize(find.byWidget(verticalViewportClip));
    final clip = verticalViewportClip.clipper!.getClip(clipRectSize);

    // The vertical viewport keeps a tight top/bottom clip (the glow is no longer
    // clipped here — it renders in the overlay); only the left background bleed
    // extends beyond the viewport.
    expect(clip.left, closeTo(-expectedLeftOverflow, 0.001));
    expect(clip.top, 0);
    expect(clip.bottom, closeTo(clipRectSize.height, 0.001));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    // The newly focused hub's card still carries the overlay glow.
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
  });

  testWidgets('detailed card layout can still show media text', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, false);

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Visible Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(hubs: [hub], iconForHub: (_, _) => Icons.movie_rounded),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Visible Movie'), findsOneWidget);
  });

  testWidgets('detailed card focus ring wraps card content height', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, false);
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = MediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Visible Movie',
      year: 2024,
    );
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(hubs: [hub], autofocus: true, iconForHub: (_, _) => Icons.movie_rounded),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final focusDecoration = find.ancestor(
      of: find.text('Visible Movie'),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer || widget.decoration is! BoxDecoration) return false;
        return (widget.decoration as BoxDecoration).border is Border && widget.foregroundDecoration == null;
      }),
    );

    expect(focusDecoration, findsOneWidget);
    expect(find.text('2024'), findsOneWidget);

    final focusRect = tester.getRect(focusDecoration);
    final subtitleRect = tester.getRect(find.text('2024'));
    expect(focusRect.bottom - subtitleRect.bottom, lessThan(8));
  });

  testWidgets('view all item uses compact pill focus style', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 2, more: true);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(hubs: [hub], autofocus: true, iconForHub: (_, _) => Icons.movie_rounded),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final viewAllText = find.text('View All');
    final pill = find.ancestor(of: viewAllText, matching: find.byType(AnimatedContainer));
    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);

    expect(viewAllText, findsOneWidget);
    expect(pill, findsOneWidget);
    final pillWidget = tester.widget<AnimatedContainer>(pill);
    final decoration = pillWidget.decoration as BoxDecoration;
    final pillSize = tester.getSize(pill);

    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotNull);
    expect(pillSize.width, closeTo(TvBrowseRailLayout.viewAllItemWidthForScale(scale), 0.001));
    expect(pillSize.width, lessThan(132 * scale));
    expect(pillSize.height, closeTo(TvBrowseRailLayout.viewAllPillHeightForScale(scale), 0.001));
  });

  testWidgets('loading trailing item keeps visible focus style', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 2);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                autofocus: true,
                iconForHub: (_, _) => Icons.movie_rounded,
                trailingForHub: (_) => TvRailTrailing.loading,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    final spinner = find.byType(CircularProgressIndicator);
    final pill = find.ancestor(of: spinner, matching: find.byType(AnimatedContainer));
    final decoration = tester.widget<AnimatedContainer>(pill).decoration as BoxDecoration;

    expect(spinner, findsOneWidget);
    expect(decoration.boxShadow, isNotNull);
  });

  testWidgets('clamps focused trailing item when trailing state disappears', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
    var trailing = TvRailTrailing.loading;
    var activations = 0;
    late StateSetter setParentState;

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setParentState = setState;
                return SizedBox(
                  width: 1280,
                  height: 720,
                  child: TvBrowseRail(
                    hubs: [hub],
                    autofocus: true,
                    iconForHub: (_, _) => Icons.movie_rounded,
                    trailingForHub: (_) => trailing,
                    onActivateItem: (_, _) {
                      activations++;
                      return Future.value(true);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    setParentState(() => trailing = TvRailTrailing.none);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('inactive hub contents render at reduced opacity', (tester) async {
    final serverManager = MultiServerManager();
    final firstItem = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 1');
    final secondItem = MediaItem(id: 'movie_2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 2');
    final firstHub = MediaHub(id: 'hub_1', title: 'First Hub', type: 'movie', items: [firstItem], size: 1);
    final secondHub = MediaHub(id: 'hub_2', title: 'Second Hub', type: 'movie', items: [secondItem], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(hubs: [firstHub, secondHub], iconForHub: (_, _) => Icons.movie_rounded),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final opacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).map((widget) => widget.opacity);
    expect(opacities, contains(0.7));
  });

  testWidgets('selects preferred hub when hubs are inserted asynchronously', (tester) async {
    final activeHubIds = <String>[];

    Widget buildRail(List<MediaHub> hubs, {String? initialHubId, String? initialItemId, bool autofocus = false}) {
      final serverManager = MultiServerManager();
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: hubs,
                initialHubId: initialHubId,
                initialItemId: initialItemId,
                autofocus: autofocus,
                iconForHub: (_, _) => Icons.tv_rounded,
                onActiveHubChanged: (hub, _) => activeHubIds.add(hub.id),
              ),
            ),
          ),
        ),
      );
    }

    const castHub = MediaHub(id: 'detail_actors', title: 'Cast', type: 'person', items: <MediaItem>[]);
    const preferredSeason = MediaHub(id: 'detail_season_1', title: 'Season 2', type: 'episode', items: <MediaItem>[]);

    await tester.pumpWidget(buildRail(const [castHub]));
    await tester.pump();

    await tester.pumpWidget(buildRail(const [preferredSeason, castHub], initialHubId: preferredSeason.id));
    await tester.pump();

    expect(activeHubIds, containsAllInOrder(['detail_actors', 'detail_season_1']));
    expect(activeHubIds.last, 'detail_season_1');
  });

  testWidgets('selects preferred hub after an earlier update could not find it', (tester) async {
    final activeHubIds = <String>[];

    Widget buildRail(List<MediaHub> hubs, {String? initialHubId}) {
      final serverManager = MultiServerManager();
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: hubs,
                initialHubId: initialHubId,
                iconForHub: (_, _) => Icons.tv_rounded,
                onActiveHubChanged: (hub, _) => activeHubIds.add(hub.id),
              ),
            ),
          ),
        ),
      );
    }

    const castHub = MediaHub(id: 'detail_actors', title: 'Cast', type: 'person', items: <MediaItem>[]);
    const episodesHub = MediaHub(id: 'detail_episodes', title: 'Episodes', type: 'episode', items: <MediaItem>[]);

    await tester.pumpWidget(buildRail(const [castHub]));
    await tester.pump();

    await tester.pumpWidget(buildRail(const [castHub], initialHubId: episodesHub.id));
    await tester.pump();

    await tester.pumpWidget(buildRail(const [episodesHub, castHub], initialHubId: episodesHub.id));
    await tester.pump();

    expect(activeHubIds, containsAllInOrder(['detail_actors', 'detail_episodes']));
    expect(activeHubIds.last, 'detail_episodes');
  });

  testWidgets('selects preferred item when active hub items are populated asynchronously', (tester) async {
    final focusedItemIds = <String>[];

    Widget buildRail(List<MediaHub> hubs, {String? initialItemId}) {
      final serverManager = MultiServerManager();
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: hubs,
                initialItemId: initialItemId,
                iconForHub: (_, _) => Icons.tv_rounded,
                onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
              ),
            ),
          ),
        ),
      );
    }

    final episode1 = MediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
    );
    final episode2 = MediaItem(
      id: 'episode_2',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 2',
    );
    const emptySeason = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: <MediaItem>[]);
    final loadedSeason = MediaHub(
      id: emptySeason.id,
      title: emptySeason.title,
      type: emptySeason.type,
      items: [episode1, episode2],
      size: 2,
    );

    await tester.pumpWidget(buildRail(const [emptySeason], initialItemId: episode2.id));
    await tester.pump();

    await tester.pumpWidget(buildRail([loadedSeason], initialItemId: episode2.id));
    await tester.pump();

    expect(focusedItemIds.last, episode2.id);
  });

  testWidgets('scrolls remembered item after switching hubs', (tester) async {
    List<MediaItem> movieItems() => List.generate(
      12,
      (index) =>
          MediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    List<MediaItem> episodeItems() => List.generate(
      12,
      (index) => MediaItem(
        id: 'episode_$index',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode $index',
        thumbPath: '/episode_$index',
      ),
    );

    final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: movieItems(), size: 12);
    final episodeHub = MediaHub(id: 'episodes', title: 'Episodes', type: 'episode', items: episodeItems(), size: 12);
    final serverManager = MultiServerManager();
    final activeHubIds = <String>[];
    var parentRebuilds = 0;
    HubFocusMemory.setForHub(episodeHub.id, 5);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 700,
                  height: 720,
                  child: TvBrowseRail(
                    hubs: [movieHub, episodeHub],
                    autofocus: true,
                    iconForHub: (_, _) => Icons.tv_rounded,
                    onActiveHubChanged: (hub, _) {
                      activeHubIds.add(hub.id);
                      setParentState(() => parentRebuilds++);
                    },
                    episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final fullCardLayout = SettingsService.instanceOrNull!.read(SettingsService.tvFullCardLayout);
    final availableWidth = 700 - TvBrowseRailLayout.horizontalInsetForScale(scale);
    final movieMetrics = TvBrowseRailLayout.metricsForHub(
      hub: movieHub,
      availableWidth: availableWidth,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
      fullCardLayout: fullCardLayout,
    );
    final expectedVerticalOffset = TvBrowseRailLayout.hubSectionHeightFor(
      scale: scale,
      activeRailHeight: movieMetrics.height,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));

    final midAnimationPosition = _verticalRailPosition(tester).pixels;
    expect(midAnimationPosition, greaterThan(0));
    expect(midAnimationPosition, lessThan(expectedVerticalOffset));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    final position = _activeRailPosition(tester);
    final verticalPosition = _verticalRailPosition(tester);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: episodeHub,
      availableWidth: position.viewportDimension,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
      fullCardLayout: fullCardLayout,
    );
    final expectedOffset = TvBrowseRailLayout.scrollOffsetForIndex(
      hub: episodeHub,
      index: 5,
      metrics: metrics,
      viewportWidth: position.viewportDimension,
      maxScrollExtent: position.maxScrollExtent,
      scale: scale,
    );

    expect(activeHubIds.last, episodeHub.id);
    expect(parentRebuilds, greaterThan(0));
    expect(position.pixels, closeTo(expectedOffset, 0.1));
    expect(verticalPosition.pixels, closeTo(expectedVerticalOffset, 0.1));
  });

  testWidgets('realigns active hub after preceding hub height changes', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final tallItem = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 1');
    final wideItem = MediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      thumbPath: '/episode_1',
    );
    final activeItem = MediaItem(
      id: 'episode_2',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 2',
      thumbPath: '/episode_2',
    );
    final firstHubTall = MediaHub(id: 'dynamic', title: 'Dynamic', type: 'movie', items: [tallItem], size: 1);
    final firstHubWide = MediaHub(id: 'dynamic', title: 'Dynamic', type: 'episode', items: [wideItem], size: 1);
    final activeHub = MediaHub(id: 'active', title: 'Active', type: 'episode', items: [activeItem], size: 1);

    Widget buildRail(List<MediaHub> hubs) {
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: hubs,
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail([firstHubTall, activeHub]));
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.pumpWidget(buildRail([firstHubWide, activeHub]));
    await tester.pumpAndSettle();

    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final availableWidth = 1280 - TvBrowseRailLayout.horizontalInsetForScale(scale);
    final firstWideMetrics = TvBrowseRailLayout.metricsForHub(
      hub: firstHubWide,
      availableWidth: availableWidth,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
    );
    final expectedVerticalOffset = TvBrowseRailLayout.hubSectionHeightFor(
      scale: scale,
      activeRailHeight: firstWideMetrics.height,
    );

    expect(_verticalRailPosition(tester).pixels, closeTo(expectedVerticalOffset, 0.1));
  });

  testWidgets('does not realign active hub when a background hub updates', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    MediaItem episode(String id) {
      return MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: id, thumbPath: '/$id');
    }

    final serverManager = MultiServerManager();
    final firstHub = MediaHub(id: 'first', title: 'First', type: 'episode', items: [episode('episode_1')], size: 1);
    final activeHub = MediaHub(id: 'active', title: 'Active', type: 'episode', items: [episode('episode_2')], size: 1);
    final backgroundInitialHub = MediaHub(
      id: 'background',
      title: 'Background',
      type: 'episode',
      items: [episode('episode_3')],
      size: 1,
    );
    final backgroundUpdatedHub = MediaHub(
      id: backgroundInitialHub.id,
      title: backgroundInitialHub.title,
      type: backgroundInitialHub.type,
      items: [episode('episode_3'), episode('episode_4')],
      size: 2,
    );

    Widget buildRail({required bool backgroundLoaded}) {
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: [firstHub, activeHub, backgroundLoaded ? backgroundUpdatedHub : backgroundInitialHub],
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail(backgroundLoaded: false));
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_verticalRailPosition(tester).pixels, greaterThan(0));

    _verticalRailPosition(tester).jumpTo(0);
    await tester.pump();

    await tester.pumpWidget(buildRail(backgroundLoaded: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(_verticalRailPosition(tester).pixels, 0);
  });

  testWidgets('keeps vertical navigation smooth when active hub updates during scroll', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    MediaItem episode(String id) {
      return MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: id, thumbPath: '/$id');
    }

    final serverManager = MultiServerManager();
    final firstHub = MediaHub(id: 'first', title: 'First', type: 'episode', items: [episode('episode_1')], size: 1);
    final middleInitialHub = MediaHub(
      id: 'middle',
      title: 'Middle',
      type: 'episode',
      items: [episode('episode_2')],
      size: 1,
    );
    final middleUpdatedHub = MediaHub(
      id: middleInitialHub.id,
      title: middleInitialHub.title,
      type: middleInitialHub.type,
      items: [episode('episode_2'), episode('episode_3')],
      size: 2,
    );
    final lastHub = MediaHub(id: 'last', title: 'Last', type: 'episode', items: [episode('episode_4')], size: 1);
    var updateMiddleOnFocus = false;
    var middleLoaded = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 1280,
                  height: 720,
                  child: TvBrowseRail(
                    hubs: [firstHub, middleLoaded ? middleUpdatedHub : middleInitialHub, lastHub],
                    autofocus: true,
                    iconForHub: (_, _) => Icons.tv_rounded,
                    episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
                    onActiveHubChanged: (hub, _) {
                      if (updateMiddleOnFocus && hub.id == middleInitialHub.id && !middleLoaded) {
                        setParentState(() => middleLoaded = true);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    for (var i = 0; i < 2; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }

    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final availableWidth = 1280 - TvBrowseRailLayout.horizontalInsetForScale(scale);
    final firstMetrics = TvBrowseRailLayout.metricsForHub(
      hub: firstHub,
      availableWidth: availableWidth,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
    );
    final middleTargetOffset = TvBrowseRailLayout.hubSectionHeightFor(
      scale: scale,
      activeRailHeight: firstMetrics.height,
    );
    final startOffset = _verticalRailPosition(tester).pixels;
    expect(startOffset, greaterThan(middleTargetOffset));

    updateMiddleOnFocus = true;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 80));

    expect(middleLoaded, isTrue);
    final midAnimationOffset = _verticalRailPosition(tester).pixels;
    expect(midAnimationOffset, greaterThan(middleTargetOffset + 0.5));
    expect(midAnimationOffset, lessThan(startOffset - 0.5));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_verticalRailPosition(tester).pixels, closeTo(middleTargetOffset, 0.1));
  });

  testWidgets('uses per-hub item focus instead of global column hint', (tester) async {
    List<MediaItem> movieItems() => List.generate(
      8,
      (index) =>
          MediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    List<MediaItem> episodeItems() => List.generate(
      8,
      (index) => MediaItem(
        id: 'episode_$index',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode $index',
        thumbPath: '/episode_$index',
      ),
    );
    final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: movieItems(), size: 8);
    final episodeHub = MediaHub(id: 'episodes', title: 'Episodes', type: 'episode', items: episodeItems(), size: 8);
    final focused = <String>[];
    final serverManager = MultiServerManager();

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pump();
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 700,
                  height: 720,
                  child: TvBrowseRail(
                    hubs: [movieHub, episodeHub],
                    autofocus: true,
                    iconForHub: (_, _) => Icons.tv_rounded,
                    onActiveHubChanged: (_, _) => setParentState(() {}),
                    onFocusedHubItemChanged: (hub, item) => focused.add('${hub.id}:${item.id}'),
                    episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await press(LogicalKeyboardKey.arrowRight);
    }
    expect(focused.last, 'movies:movie_5');

    await press(LogicalKeyboardKey.arrowDown);
    expect(focused.last, 'episodes:episode_0');

    await press(LogicalKeyboardKey.arrowUp);
    expect(focused.last, 'movies:movie_5');
  });

  testWidgets('keeps late episode thumbnails visible in long TV rows', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, false);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    Future<void> pressRight() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 16));
    }

    final episodes = List.generate(
      153,
      (index) => MediaItem(
        id: 'episode_${index + 1}',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode ${index + 1}',
        parentIndex: 11,
        index: index + 1,
        thumbPath: '/episode_${index + 1}',
      ),
    );
    final hub = MediaHub(id: 'detail_season_11', title: 'Season 11', type: 'episode', items: episodes, size: 153);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    for (var i = 0; i < 117; i++) {
      await pressRight();
    }
    await tester.pumpAndSettle();

    final targetTitle = find.text('Episode 118');
    expect(targetTitle, findsOneWidget);
    final railRect = tester.getRect(find.byType(TvBrowseRail));
    final targetRect = tester.getRect(targetTitle);
    expect(targetRect.left, greaterThanOrEqualTo(railRect.left - 0.5));
    expect(targetRect.right, lessThanOrEqualTo(railRect.right + 0.5));

    final position = _activeRailPosition(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final scale = TvBrowseRailLayout.scaleForSize(size);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: size.width - TvBrowseRailLayout.horizontalInsetForScale(scale),
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
    );
    final expectedOffset = TvBrowseRailLayout.scrollOffsetForIndex(
      hub: hub,
      index: 117,
      metrics: metrics,
      viewportWidth: position.viewportDimension,
      maxScrollExtent: position.maxScrollExtent,
      scale: scale,
    );
    expect(position.pixels, closeTo(expectedOffset, 0.1));
  });

  testWidgets('keeps late episode thumbnails visible during rapid key repeat', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, false);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final focusedItemIds = <String>[];
    const episodeCount = 500;
    const targetIndex = 419;
    final episodes = List.generate(
      episodeCount,
      (index) => MediaItem(
        id: 'episode_${index + 1}',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode ${index + 1}',
        parentIndex: 11,
        index: index + 1,
        thumbPath: '/episode_${index + 1}',
      ),
    );
    final hub = MediaHub(
      id: 'detail_season_11',
      title: 'Season 11',
      type: 'episode',
      items: episodes,
      size: episodeCount,
    );
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
                episodePosterModeForHub: (_) => EpisodePosterMode.episodeThumbnail,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    for (var i = 0; i < targetIndex - 1; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(focusedItemIds.last, 'episode_${targetIndex + 1}');
    final targetTitle = find.text('Episode ${targetIndex + 1}');
    expect(targetTitle, findsOneWidget);
    final railRect = tester.getRect(find.byType(TvBrowseRail));
    final targetRect = tester.getRect(targetTitle);
    expect(targetRect.left, greaterThanOrEqualTo(railRect.left - 0.5));
    expect(targetRect.right, lessThanOrEqualTo(railRect.right + 0.5));

    final position = _activeRailPosition(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final scale = TvBrowseRailLayout.scaleForSize(size);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: size.width - TvBrowseRailLayout.horizontalInsetForScale(scale),
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
    );
    final expectedOffset = TvBrowseRailLayout.scrollOffsetForIndex(
      hub: hub,
      index: targetIndex,
      metrics: metrics,
      viewportWidth: position.viewportDimension,
      maxScrollExtent: position.maxScrollExtent,
      scale: scale,
    );
    expect(position.pixels, closeTo(expectedOffset, 0.1));
  });

  testWidgets('resets long-press state when context menu focus receives select key up', (tester) async {
    final menuFocusNode = FocusNode(debugLabel: 'context_menu_probe');
    addTearDown(menuFocusNode.dispose);
    addTearDown(SelectKeyUpSuppressor.clearSuppression);

    var activations = 0;
    final person = MediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox(
                  width: 1280,
                  height: 720,
                  child: TvBrowseRail(
                    hubs: [hub],
                    iconForHub: (_, _) => Icons.person_rounded,
                    onActivateItem: (_, _) {
                      activations++;
                      return Future.value(true);
                    },
                  ),
                ),
                Focus(
                  focusNode: menuFocusNode,
                  onKeyEvent: (_, event) {
                    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) return KeyEventResult.handled;
                    return KeyEventResult.ignored;
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final railState = tester.state<TvBrowseRailState>(find.byType(TvBrowseRail));
    railState.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 501));

    menuFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    railState.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('suppresses transferred select activation until key up', (tester) async {
    var activations = 0;
    final person = MediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                iconForHub: (_, _) => Icons.person_rounded,
                onActivateItem: (_, _) {
                  activations++;
                  return Future.value(true);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final railState = tester.state<TvBrowseRailState>(find.byType(TvBrowseRail));
    railState.requestFocus();
    railState.suppressSelectUntilKeyUp();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('without a gesture signal, suppression clears on the legacy safety timeout', (tester) async {
    var activations = 0;
    final person = MediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                iconForHub: (_, _) => Icons.person_rounded,
                onActivateItem: (_, _) {
                  activations++;
                  return Future.value(true);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final railState = tester.state<TvBrowseRailState>(find.byType(TvBrowseRail));
    railState.requestFocus();
    railState.suppressSelectUntilKeyUp();
    await tester.pump();

    // With no touch gesture, suppression must not outlive the short safety
    // timeout — a select after it elapses activates normally.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
  });

  testWidgets('an active touch gesture holds select suppression past the legacy window', (tester) async {
    var activations = 0;
    final gesture = ValueNotifier<bool>(true);
    addTearDown(gesture.dispose);
    final person = MediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                iconForHub: (_, _) => Icons.person_rounded,
                selectSuppressionGestureSignal: gesture,
                onActivateItem: (_, _) {
                  activations++;
                  return Future.value(true);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final railState = tester.state<TvBrowseRailState>(find.byType(TvBrowseRail));
    railState.requestFocus();
    railState.suppressSelectUntilKeyUp();
    await tester.pump();

    // Well past the legacy 220ms window, finger still down (gesture active): the
    // stray same-gesture select (#1281) is still ignored.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 0);

    // Once cleared, deliberate selects work again.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
  });

  testWidgets('ending the gesture clears select suppression before the backstop', (tester) async {
    var activations = 0;
    final gesture = ValueNotifier<bool>(true);
    addTearDown(gesture.dispose);
    final person = MediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                iconForHub: (_, _) => Icons.person_rounded,
                selectSuppressionGestureSignal: gesture,
                onActivateItem: (_, _) {
                  activations++;
                  return Future.value(true);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final railState = tester.state<TvBrowseRailState>(find.byType(TvBrowseRail));
    railState.requestFocus();
    railState.suppressSelectUntilKeyUp();
    await tester.pump();

    // Suppression holds while the gesture is active, past the legacy window.
    await tester.pump(const Duration(milliseconds: 1000));
    // Finger lifts -> gesture ends -> suppression clears immediately, well before
    // the safety backstop.
    gesture.value = false;
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
  });

  testWidgets('does not autofocus unless requested', (tester) async {
    FocusManager.instance.primaryFocus?.unfocus();

    Widget buildRail({required bool autofocus}) {
      final serverManager = MultiServerManager();
      final item = MediaItem(id: 'item_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(hubs: [hub], autofocus: autofocus, iconForHub: (_, _) => Icons.tv_rounded),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail(autofocus: false));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('tv_browse_rail'));

    await tester.pumpWidget(buildRail(autofocus: true));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
  });

  testWidgets('lays out when bottom-positioned in a stack', (tester) async {
    final serverManager = MultiServerManager();
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 896,
              height: 540,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TvBrowseRail(hubs: [hub], iconForHub: (_, _) => Icons.movie_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('background gradient stays full bleed beside pushed foreground', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1060,
              height: 720,
              child: TvBrowseRail(
                hubs: [hub],
                iconForHub: (_, _) => Icons.movie_rounded,
                backgroundBleedLeft: SideNavigationRailState.expandedWidth,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gradient = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient is LinearGradient,
    );
    final backgroundPosition = tester.widget<Positioned>(
      find.ancestor(of: gradient.first, matching: find.byType(Positioned)).first,
    );

    expect(backgroundPosition.left, -SideNavigationRailState.expandedWidth);
    expect(backgroundPosition.width, 1280);
  });

  testWidgets('background bleed updates do not renotify rail focus', (tester) async {
    final serverManager = MultiServerManager();
    final multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    addTearDown(multiServerProvider.dispose);

    final focusedItemIds = <String>[];
    final activeHubIds = <String>[];
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);

    Widget buildRail(double backgroundBleedLeft) {
      return ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                key: const ValueKey('rail'),
                hubs: [hub],
                iconForHub: (_, _) => Icons.movie_rounded,
                backgroundBleedLeft: backgroundBleedLeft,
                onFocusedItemChanged: (focused) => focusedItemIds.add(focused.id),
                onActiveHubChanged: (active, _) => activeHubIds.add(active.id),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail(0));
    await tester.pump();
    focusedItemIds.clear();
    activeHubIds.clear();

    await tester.pumpWidget(buildRail(SideNavigationRailState.expandedWidth));
    await tester.pump();

    expect(focusedItemIds, isEmpty);
    expect(activeHubIds, isEmpty);
  });
}

ScrollPosition _activeRailPosition(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .map((state) => state.position)
      .where((position) => axisDirectionToAxis(position.axisDirection) == Axis.horizontal)
      .where((position) => position.maxScrollExtent > 0)
      .reduce((a, b) => a.maxScrollExtent > b.maxScrollExtent ? a : b);
}

ScrollPosition _verticalRailPosition(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey('tv_browse_rail_vertical')),
    matching: find.byType(Scrollable),
  );
  return tester
      .stateList<ScrollableState>(scrollable)
      .map((state) => state.position)
      .singleWhere((position) => axisDirectionToAxis(position.axisDirection) == Axis.vertical);
}
