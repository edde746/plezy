import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/focus/locked_hub_controller.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/animated_dim_scrim.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/rasterized_gradient.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TvBrowseRailLayout', () {
    test('density changes card width', () {
      final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
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
      final episode = testMediaItem(
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
      final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final episode = testMediaItem(
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
      final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
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
      final episode = testMediaItem(
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
      final episode = testMediaItem(
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

    test('grid spacing widens the rail gap and narrows cards; full card rails keep their own gutter', () {
      // #2226: the TV home rail follows the grid-spacing setting like the
      // library grid. Full-card rails already carry a scale-derived gutter,
      // mirroring how full-bleed grids ignore the setting.
      final hub = MediaHub(
        id: 'movies',
        title: 'Movies',
        type: 'movie',
        items: [testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie')],
        size: 1,
      );
      const scale = 0.85;
      TvBrowseRailLayoutMetrics metrics(GridSpacing spacing, {bool fullCardLayout = false}) =>
          TvBrowseRailLayout.metricsForHub(
            hub: hub,
            availableWidth: 1040,
            density: LibraryDensity.defaultValue,
            episodePosterMode: EpisodePosterMode.seriesPoster,
            scale: scale,
            fullCardLayout: fullCardLayout,
            gridSpacing: spacing,
          );

      final tight = metrics(GridSpacing.tight);
      final spacious = metrics(GridSpacing.spacious);
      expect(tight.itemGap, 0);
      expect(spacious.itemGap, closeTo(GridSpacing.spacious.gridGap * scale, 0.001));
      expect(spacious.cardWidth, lessThan(tight.cardWidth));
      expect(spacious.height, lessThan(tight.height));

      final fullTight = metrics(GridSpacing.tight, fullCardLayout: true);
      final fullSpacious = metrics(GridSpacing.spacious, fullCardLayout: true);
      expect(fullSpacious.itemGap, fullTight.itemGap);
      expect(fullSpacious.cardWidth, fullTight.cardWidth);

      // Height reservations follow the same metrics.
      final tightEstimate = TvBrowseRailLayout.estimateHeight(
        size: const Size(1280, 720),
        hubs: [hub],
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.seriesPoster,
      );
      final spaciousEstimate = TvBrowseRailLayout.estimateHeight(
        size: const Size(1280, 720),
        hubs: [hub],
        density: LibraryDensity.defaultValue,
        episodePosterMode: EpisodePosterMode.seriesPoster,
        gridSpacing: GridSpacing.spacious,
      );
      expect(spaciousEstimate, lessThan(tightEstimate));
    });

    test('compact wide poster scale makes clips match compact episode thumbnails', () {
      final episode = testMediaItem(
        id: 'episode_1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode 1',
        thumbPath: '/episode-thumb',
      );
      final clip = testMediaItem(
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
      final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
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

  late HubFocusMemory focusMemory;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    focusMemory = HubFocusMemory();
    await SettingsService.getInstance();
  });

  testWidgets('semantic selection proxy stays fixed while animated rail selection changes', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final items = [
      testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'First Movie'),
      testMediaItem(id: 'movie_2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Second Movie'),
    ];
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: items, size: items.length);
    String? activatedItemId;

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Builder(
              // The semantic selection proxy is gated on accessibleNavigation:
              // it only exists while an accessibility service is attached.
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
                child: Scaffold(
                  body: SizedBox(
                    width: 1280,
                    height: 720,
                    child: TvBrowseRail(
                      focusMemory: focusMemory,
                      hubs: [hub],
                      autofocus: true,
                      iconForHub: (_, _) => Icons.movie_rounded,
                      onActivateItem: (_, item) {
                        activatedItemId = item.id;
                        return true;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final proxy = find.bySemanticsIdentifier('tv_browse_rail_selection');
    expect(proxy, findsOneWidget);
    final initialRect = tester.getRect(proxy);
    final initialNode = tester.getSemantics(proxy);
    expect(initialNode.label, contains('Movies'));
    expect(initialNode.label, contains('First Movie'));
    expect(initialNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.widget<Semantics>(proxy).properties.onTap, isNotNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    final movedNode = tester.getSemantics(proxy);
    expect(movedNode.label, contains('Second Movie'));
    expect(tester.getRect(proxy), initialRect);
    expect(tester.hasRunningAnimations, isTrue);

    tester.widget<Semantics>(find.byKey(const ValueKey('tv_browse_rail_semantic_proxy'))).properties.onTap!();
    await tester.pump();
    expect(activatedItemId, 'movie_2');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    semantics.dispose();
  });

  testWidgets('low-end snapshot optimization preserves vertical scroll animation', (tester) async {
    DevicePerformance.debugReset(autoReduced: true);
    addTearDown(DevicePerformance.debugReset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final hubs = List.generate(6, (hubIndex) {
      final item = testMediaItem(
        id: 'movie_$hubIndex',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie $hubIndex',
      );
      return MediaHub(id: 'hub_$hubIndex', title: 'Hub $hubIndex', type: 'movie', items: [item], size: 1);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Builder(
              // The semantic selection proxy is gated on accessibleNavigation:
              // it only exists while an accessibility service is attached.
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
                child: Scaffold(
                  body: SizedBox(
                    width: 1280,
                    height: 720,
                    child: TvBrowseRail(
                      focusMemory: focusMemory,
                      hubs: hubs,
                      autofocus: true,
                      iconForHub: (_, _) => Icons.movie_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    final position = _verticalRailPosition(tester);
    final initialOffset = position.pixels;
    tester.widget<Semantics>(find.byKey(const ValueKey('tv_browse_rail_semantic_proxy'))).properties.onScrollDown!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40)); // partway through the 150 ms D-pad glide
    final animatedOffset = position.pixels;
    expect(animatedOffset, greaterThan(initialOffset));
    expect(tester.hasRunningAnimations, isTrue);

    final snapshots = tester.widgetList<SnapshotWidget>(find.byType(SnapshotWidget));
    expect(snapshots, isNotEmpty);
    expect(snapshots.every((widget) => widget.controller.allowSnapshotting), isTrue);
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(animatedOffset));
    expect(snapshots.every((widget) => widget.controller.allowSnapshotting), isFalse);
  });

  testWidgets('active hub header uses theme foreground in light mode', (tester) async {
    final serverManager = MultiServerManager();
    final theme = monoTheme(dark: false);
    final episode = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
    );
    final hub = MediaHub(id: 'season_1', title: 'Season 1', type: 'episode', items: [episode], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(focusMemory: focusMemory, hubs: [hub], iconForHub: (_, _) => Icons.tv_rounded),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final headerText = tester.widget<Text>(find.text('Season 1'));
    expect(headerText.style?.color, theme.colorScheme.onSurface);
  });

  testWidgets('two hubs sharing a backend id across servers do not collide on card GlobalKeys', (tester) async {
    final serverManager = MultiServerManager();
    // Multi-server aggregation: two servers return a hub with the SAME backend
    // id ('recently_added'). Per-card GlobalKeys must be qualified by serverId,
    // or both rows hand the same GlobalKey<MediaCardState> to different cards
    // and finalizeTree throws "Duplicate GlobalKey".
    MediaHub hubFor(String serverId) => MediaHub(
      id: 'recently_added',
      title: 'Recently Added ($serverId)',
      type: 'movie',
      serverId: serverId,
      size: 2,
      items: [
        testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'A', serverId: serverId),
        testMediaItem(id: 'movie_2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'B', serverId: serverId),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: [hubFor('serverA'), hubFor('serverB')],
                iconForHub: (_, _) => Icons.movie_rounded,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('full card layout hides media text and overlays actor text when enabled', (tester) async {
    await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, true);

    final serverManager = MultiServerManager();
    final movie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Hidden Movie',
    );
    final actor = testMediaItem(
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(focusMemory: focusMemory, hubs: [hub], iconForHub: (_, _) => Icons.movie_rounded),
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
    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
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
    final firstMovie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 1',
    );
    final secondMovie = testMediaItem(
      id: 'movie_2',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 2',
    );
    final firstHub = MediaHub(id: 'movies_1', title: 'Movies 1', type: 'movie', items: [firstMovie], size: 1);
    final secondHub = MediaHub(id: 'movies_2', title: 'Movies 2', type: 'movie', items: [secondMovie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
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

  testWidgets('glow stays hidden while the rail animates an UP hub move, returns after settling', (tester) async {
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
    final firstMovie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 1',
    );
    final secondMovie = testMediaItem(
      id: 'movie_2',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 2',
    );
    final firstHub = MediaHub(id: 'movies_1', title: 'Movies 1', type: 'movie', items: [firstMovie], size: 1);
    final secondHub = MediaHub(id: 'movies_2', title: 'Movies 2', type: 'movie', items: [secondMovie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
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

    // Move DOWN and settle so the second hub's card carries a visible glow.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(CompositedTransformFollower), findsOneWidget);

    // Move UP: focus flips to the first hub's card immediately, but the glow
    // must stay hidden for the whole vertical scroll — otherwise it paints
    // (via the root overlay, unclipped by the rail viewport) over the artwork
    // above while the target row is still offscreen.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 40)); // partway through the 150 ms D-pad glide

    // Hidden means either the portal is gone or its fade opacity is held at 0
    // (any surviving follower is the old card's overlay fading out to 0).
    final midScrollOpacities = find
        .descendant(of: find.byType(CompositedTransformFollower), matching: find.byType(AnimatedOpacity))
        .evaluate()
        .map((element) => (element.widget as AnimatedOpacity).opacity);
    expect(midScrollOpacities.every((opacity) => opacity == 0.0), isTrue);

    // Once the scroll settles the glow fades back in on the focused card.
    await tester.pumpAndSettle();
    final settledFollower = find.byType(CompositedTransformFollower);
    expect(settledFollower, findsOneWidget);
    final settledOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(of: settledFollower, matching: find.byType(AnimatedOpacity)),
    );
    expect(settledOpacity.opacity, 1.0);
  });

  testWidgets('detailed card focus border hugs the poster, captions outside', (tester) async {
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
    final movie = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Visible Movie',
      year: 2024,
    );
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
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

    // The border is drawn inside MediaCard around the poster only (#1278);
    // the title/year captions render below it, outside the focus rect.
    final focusDecoration = find.descendant(
      of: find.ancestor(of: find.text('Visible Movie'), matching: find.byType(MediaCard)),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer || widget.foregroundDecoration is! BoxDecoration) return false;
        return (widget.foregroundDecoration as BoxDecoration).border is Border;
      }),
    );

    expect(focusDecoration, findsOneWidget);
    expect(find.text('2024'), findsOneWidget);

    final focusRect = tester.getRect(focusDecoration);
    final titleRect = tester.getRect(find.text('Visible Movie'));
    final subtitleRect = tester.getRect(find.text('2024'));
    expect(focusRect.bottom, lessThanOrEqualTo(titleRect.top));
    expect(focusRect.bottom, lessThanOrEqualTo(subtitleRect.top));
    // Still a tight ring: the poster fills the card width above the captions.
    expect(focusRect.top, lessThan(titleRect.top));
  });

  testWidgets('view all item renders as a full card matching the hub card footprint', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final serverManager = MultiServerManager();
    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 2, more: true);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
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
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final viewAllText = find.text('View All');
    final card = find.ancestor(of: viewAllText, matching: find.byType(AnimatedContainer));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final scale = TvBrowseRailLayout.scaleForSize(size);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: size.width - TvBrowseRailLayout.horizontalInsetForScale(scale),
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.seriesPoster,
      scale: scale,
    );

    expect(viewAllText, findsOneWidget);
    expect(card, findsOneWidget);
    final cardWidget = tester.widget<AnimatedContainer>(card);
    final decoration = cardWidget.decoration as BoxDecoration;
    final cardSize = tester.getSize(card);

    // Focused action card: primary border and glow, sized like a media card.
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotNull);
    expect(cardSize.width, closeTo(metrics.cardWidth, 0.001));
    expect(cardSize.height, closeTo(metrics.posterHeight, 0.001));
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
    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 2);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
    var trailing = TvRailTrailing.loading;
    var activations = 0;
    late StateSetter setParentState;

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
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
                    focusMemory: focusMemory,
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

  testWidgets('focused rail dims only inactive hub artwork', (tester) async {
    final serverManager = MultiServerManager();
    final firstItem = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 1');
    final secondItem = testMediaItem(
      id: 'movie_2',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 2',
    );
    final firstHub = MediaHub(id: 'hub_1', title: 'First Hub', type: 'movie', items: [firstItem], size: 1);
    final secondHub = MediaHub(id: 'hub_2', title: 'Second Hub', type: 'movie', items: [secondItem], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: [firstHub, secondHub],
                iconForHub: (_, _) => Icons.movie_rounded,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');

    final scrims = tester.widgetList<AnimatedDimScrim>(find.byType(AnimatedDimScrim)).toList();
    expect(scrims, hasLength(1));
    expect(scrims.single.alpha, 0.4);
    expect(scrims.single.dimmed, isFalse);

    List<MediaCard> cards() => tester.widgetList<MediaCard>(find.byType(MediaCard)).toList();
    MediaCard cardFor(MediaItem item) => cards().singleWhere((card) => card.item == item);

    final firstArtworkDim = cardFor(firstItem).artworkDim!;
    final secondArtworkDim = cardFor(secondItem).artworkDim!;
    expect(firstArtworkDim.value, 0);
    expect(secondArtworkDim.value, closeTo(0.3, 0.001));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);

    expect(firstArtworkDim.value, closeTo(0.3, 0.001));
    expect(secondArtworkDim.value, 0);
  });

  testWidgets('selects preferred hub when hubs are inserted asynchronously', (tester) async {
    final activeHubIds = <String>[];

    Widget buildRail(List<MediaHub> hubs, {String? initialHubId, String? initialItemId, bool autofocus = false}) {
      final serverManager = MultiServerManager();
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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

  testWidgets('keeps the user selection when a preferred hub arrives after item navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final recentItems = [
      testMediaItem(id: 'recent_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Recently Added 1'),
      testMediaItem(id: 'recent_2', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Recently Added 2'),
    ];
    final continueItem = testMediaItem(
      id: 'continue_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Continue Watching',
    );
    final recentHub = MediaHub(
      id: 'recently_added',
      title: 'Recently Added',
      type: 'movie',
      items: recentItems,
      size: recentItems.length,
    );
    final continueHub = MediaHub(
      id: 'continue_watching',
      title: 'Continue Watching',
      type: 'mixed',
      items: [continueItem],
      size: 1,
    );
    final focusedSelections = <(String, String)>[];

    Widget buildRail(List<MediaHub> hubs) {
      return ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  key: const ValueKey('rail'),
                  hubs: hubs,
                  initialHubId: continueHub.id,
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  onFocusedHubItemChanged: (hub, item) => focusedSelections.add((hub.id, item.id)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail([recentHub]));
    await tester.pump();
    expect(focusedSelections.last, (recentHub.id, recentItems.first.id));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedSelections.last, (recentHub.id, recentItems.last.id));

    await tester.pumpWidget(buildRail([continueHub, recentHub]));
    await tester.pumpAndSettle();

    expect(focusedSelections.last, (recentHub.id, recentItems.last.id));
  });

  testWidgets('selects preferred item when active hub items are populated asynchronously', (tester) async {
    final focusedItemIds = <String>[];

    Widget buildRail(List<MediaHub> hubs, {String? initialItemId}) {
      final serverManager = MultiServerManager();
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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

    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
    );
    final episode2 = testMediaItem(
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
          testMediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    List<MediaItem> episodeItems() => List.generate(
      12,
      (index) => testMediaItem(
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
    // Seed remembered focus under the rail's server-qualified hub key (mirrors
    // _TvBrowseRailState._hubKey: '<serverId>:<id>'), so the multi-server keying
    // resolves it the same way the rail does.
    focusMemory.setForHub('${episodeHub.serverId ?? ''}:${episodeHub.id}', 5);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 700,
                  height: 720,
                  child: TvBrowseRail(
                    focusMemory: focusMemory,
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
    final tallItem = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie 1');
    final wideItem = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      thumbPath: '/episode_1',
    );
    final activeItem = testMediaItem(
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
      return testMediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: id, thumbPath: '/$id');
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
      return testMediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: id, thumbPath: '/$id');
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 1280,
                  height: 720,
                  child: TvBrowseRail(
                    focusMemory: focusMemory,
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

  testWidgets('uses per-hub item focus instead of the owner last-column hint', (tester) async {
    List<MediaItem> movieItems() => List.generate(
      8,
      (index) =>
          testMediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    List<MediaItem> episodeItems() => List.generate(
      8,
      (index) => testMediaItem(
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setParentState) {
                return SizedBox(
                  width: 700,
                  height: 720,
                  child: TvBrowseRail(
                    focusMemory: focusMemory,
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

  testWidgets('repeated detail hub ids restore only within their browse owner', (tester) async {
    final episodeItems = [
      for (var index = 0; index < 12; index++)
        testMediaItem(
          id: 'episode_$index',
          backend: MediaBackend.plex,
          kind: MediaKind.episode,
          title: 'Episode $index',
          thumbPath: '/episode_$index',
        ),
    ];
    final extraItems = [
      for (var index = 0; index < 3; index++)
        testMediaItem(id: 'extra_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Extra $index'),
    ];
    final episodeHub = MediaHub(
      id: 'detail_episodes',
      title: 'Episodes',
      type: 'episode',
      items: episodeItems,
      size: episodeItems.length,
    );
    final extrasHub = MediaHub(
      id: 'detail_extras',
      title: 'Extras',
      type: 'movie',
      items: extraItems,
      size: extraItems.length,
    );
    final focused = <String>[];

    Future<void> mount(HubFocusMemory owner, List<MediaHub> hubs) async {
      final serverManager = MultiServerManager();
      await tester.pumpWidget(
        ChangeNotifierProvider<MultiServerProvider>(
          create: (_) => testMultiServerProvider(serverManager),
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 700,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: owner,
                  hubs: hubs,
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  onFocusedHubItemChanged: (hub, item) => focused.add('${hub.id}:${item.id}'),
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
    }

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pumpAndSettle();
    }

    await mount(focusMemory, [episodeHub, extrasHub]);
    for (var index = 0; index < 5; index++) {
      await press(LogicalKeyboardKey.arrowRight);
    }
    expect(focused.last, 'detail_episodes:episode_5');
    expect(_activeRailPosition(tester).pixels, greaterThan(0));

    await press(LogicalKeyboardKey.arrowDown);
    expect(focused.last, 'detail_extras:extra_0');
    await press(LogicalKeyboardKey.arrowUp);
    expect(focused.last, 'detail_episodes:episode_5');
    expect(_activeRailPosition(tester).pixels, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final freshOwner = HubFocusMemory();
    await mount(freshOwner, [extrasHub, episodeHub]);
    await press(LogicalKeyboardKey.arrowDown);

    expect(focused.last, 'detail_episodes:episode_0');
    expect(_activeRailPosition(tester).pixels, 0);
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
      (index) => testMediaItem(
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
    );
    expect(position.pixels, closeTo(expectedOffset, 0.1));
  });

  group('D-pad step scroll glide', () {
    Future<ScrollPosition> pumpRailAndPressRight(WidgetTester tester) async {
      await SettingsService.instanceOrNull!.write(SettingsService.tvFullCardLayout, false);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final items = List.generate(
        12,
        (index) =>
            testMediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
      );
      final hub = MediaHub(id: 'hub', title: 'Hub', type: 'movie', items: items, size: items.length);
      final serverManager = MultiServerManager();
      await tester.pumpWidget(
        ChangeNotifierProvider<MultiServerProvider>(
          create: (_) => testMultiServerProvider(serverManager),
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
                  autofocus: true,
                  iconForHub: (_, _) => Icons.movie_rounded,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
      await tester.pump();

      // Step far enough for the row to have to scroll at all.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      return _activeRailPosition(tester);
    }

    testWidgets('settles within 150 ms on D-pad platforms', (tester) async {
      final position = await pumpRailAndPressRight(tester);
      final start = position.pixels;
      await tester.pump(const Duration(milliseconds: 160));
      final settled = position.pixels;
      expect(settled, greaterThan(start));
      await tester.pumpAndSettle();
      expect(position.pixels, settled);
    });

    testWidgets('keeps the measured native glide on Apple TV', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
      final position = await pumpRailAndPressRight(tester);
      final start = position.pixels;
      await tester.pump(const Duration(milliseconds: 160));
      final midway = position.pixels;
      expect(midway, greaterThan(start));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(midway));
    });
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
      (index) => testMediaItem(
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
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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
    );
    expect(position.pixels, closeTo(expectedOffset, 0.1));
  });

  testWidgets('resets long-press state when context menu focus receives select key up', (tester) async {
    final menuFocusNode = FocusNode(debugLabel: 'context_menu_probe');
    addTearDown(menuFocusNode.dispose);
    addTearDown(SelectKeyUpSuppressor.clearSuppression);

    var activations = 0;
    final person = testMediaItem(id: 'person_1', backend: MediaBackend.plex, kind: MediaKind.unknown, title: 'Person');
    final hub = MediaHub(id: 'people', title: 'People', type: 'person', items: [person], size: 1);
    final serverManager = MultiServerManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox(
                  width: 1280,
                  height: 720,
                  child: TvBrowseRail(
                    focusMemory: focusMemory,
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

  testWidgets('does not autofocus unless requested', (tester) async {
    FocusManager.instance.primaryFocus?.unfocus();

    Widget buildRail({required bool autofocus}) {
      final serverManager = MultiServerManager();
      final item = testMediaItem(id: 'item_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
      final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);
      return ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: [hub],
                autofocus: autofocus,
                iconForHub: (_, _) => Icons.tv_rounded,
              ),
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
    final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
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
                    child: TvBrowseRail(
                      focusMemory: focusMemory,
                      hubs: [hub],
                      iconForHub: (_, _) => Icons.movie_rounded,
                    ),
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
    final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final hub = MediaHub(id: 'hub_1', title: 'Hub', type: 'movie', items: [item], size: 1);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => testMultiServerProvider(serverManager),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1060,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
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

    final gradient = find.byType(RasterizedGradient);
    final backgroundPosition = tester.widget<Positioned>(
      find.ancestor(of: gradient.first, matching: find.byType(Positioned)).first,
    );

    expect(backgroundPosition.left, -SideNavigationRailState.expandedWidth);
    expect(backgroundPosition.width, 1280);
  });

  testWidgets('background bleed updates do not renotify rail focus', (tester) async {
    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final focusedItemIds = <String>[];
    final activeHubIds = <String>[];
    final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
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
                focusMemory: focusMemory,
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

  testWidgets('selection follows the played item when continue watching reorders', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final movieA = testMediaItem(id: 'movie_a', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie A');
    final movieB = testMediaItem(id: 'movie_b', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie B');
    final movieC = testMediaItem(id: 'movie_c', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie C');
    MediaHub continueHub(List<MediaItem> items) =>
        MediaHub(id: 'continue_watching', title: 'Continue Watching', type: 'mixed', items: items, size: items.length);
    final focusedItemIds = <String>[];

    Widget buildRail(List<MediaHub> hubs) {
      return ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  key: const ValueKey('rail'),
                  hubs: hubs,
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildRail([
        continueHub([movieA, movieB, movieC]),
      ]),
    );
    await tester.pump();

    // Focus the second item, mirroring the user picking it before playback.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedItemIds.last, movieB.id);

    // Playback progress moved the played item to the front (#1987).
    await tester.pumpWidget(
      buildRail([
        continueHub([movieB, movieA, movieC]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(focusedItemIds.last, movieB.id);
  });

  testWidgets('selection follows the series when a finished episode is replaced by the next one', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final movie = testMediaItem(id: 'movie_a', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie A');
    final episode1 = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      grandparentId: 'show_1',
      title: 'S01E01',
    );
    final episode2 = testMediaItem(
      id: 'episode_2',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      grandparentId: 'show_1',
      title: 'S01E02',
    );
    MediaHub continueHub(List<MediaItem> items) =>
        MediaHub(id: 'continue_watching', title: 'Continue Watching', type: 'mixed', items: items, size: items.length);
    final focusedItemIds = <String>[];

    Widget buildRail(List<MediaHub> hubs) {
      return ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  key: const ValueKey('rail'),
                  hubs: hubs,
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildRail([
        continueHub([movie, episode1]),
      ]),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedItemIds.last, episode1.id);

    // Finishing the episode replaced it with the show's next episode at the
    // front of the row.
    await tester.pumpWidget(
      buildRail([
        continueHub([episode2, movie]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(focusedItemIds.last, episode2.id);
  });

  // The horizontal rail uses a constant `itemExtent` (SliverFixedExtentList),
  // which is what makes sliver layout math O(1) per realized child instead of
  // O(n). That only holds while the leading/trailing action slots occupy
  // card-sized cells, so pin both halves of the contract.
  test('rail layout uses one uniform extent for media and trailing cells', () {
    final items = List.generate(
      12,
      (index) =>
          testMediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: items, size: items.length, more: true);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: 1280,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: 1.0,
    );
    final expectedExtent = metrics.cardWidth + metrics.itemGap;

    // Every index, including the trailing "View All" cell at items.length.
    for (var index = 0; index <= items.length; index++) {
      expect(
        TvBrowseRailLayout.itemExtentForIndex(index: index, metrics: metrics),
        expectedExtent,
        reason: 'index $index must use the uniform extent',
      );
    }

    final expectedMax = ((metrics.railEdgePadding * 2) + ((items.length + 1) * expectedExtent) - 1280).clamp(
      0.0,
      double.infinity,
    );
    expect(
      TvBrowseRailLayout.estimatedMaxScrollExtent(hub: hub, metrics: metrics, viewportWidth: 1280, hasTrailing: true),
      closeTo(expectedMax, 0.001),
    );
  });

  test('rail centers a mid-row cell and clamps the trailing cell to the end', () {
    final items = List.generate(
      12,
      (index) =>
          testMediaItem(id: 'movie_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie $index'),
    );
    final hub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: items, size: items.length, more: true);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: 1280,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: 1.0,
    );
    final extent = metrics.cardWidth + metrics.itemGap;
    final maxScrollExtent = TvBrowseRailLayout.estimatedMaxScrollExtent(
      hub: hub,
      metrics: metrics,
      viewportWidth: 1280,
      hasTrailing: true,
    );

    expect(
      TvBrowseRailLayout.scrollOffsetForIndex(
        hub: hub,
        index: 4,
        metrics: metrics,
        viewportWidth: 1280,
        maxScrollExtent: maxScrollExtent,
        hasTrailing: true,
      ),
      closeTo((metrics.railEdgePadding + (4.5 * extent) - 640).clamp(0.0, maxScrollExtent), 0.001),
    );

    // The trailing cell stays reachable and lands at the end of the row.
    expect(
      TvBrowseRailLayout.scrollOffsetForIndex(
        hub: hub,
        index: items.length,
        metrics: metrics,
        viewportWidth: 1280,
        maxScrollExtent: maxScrollExtent,
        hasTrailing: true,
      ),
      maxScrollExtent,
    );

    // An index past the end clamps instead of overscrolling.
    expect(
      TvBrowseRailLayout.scrollOffsetForIndex(
        hub: hub,
        index: 999,
        metrics: metrics,
        viewportWidth: 1280,
        maxScrollExtent: maxScrollExtent,
        hasTrailing: true,
      ),
      maxScrollExtent,
    );
  });

  // Leading-slot geometry: the options card lives in the negative-offset
  // region before the row's scroll anchor. Slot extents stay uniform, the
  // scrollable [0, max] range is untouched, and media cells keep the exact
  // offsets they have without a leading slot — the card never pushes content.
  test('leading options card lives before the anchor without shifting media cells', () {
    final items = List.generate(
      8,
      (index) => testMediaItem(
        id: 'episode_$index',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode $index',
        thumbPath: '/episode-thumb',
      ),
    );
    final hub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: items, size: items.length);
    TvBrowseRailLayoutMetrics metricsFor({required bool hasLeading}) => TvBrowseRailLayout.metricsForHub(
      hub: hub,
      availableWidth: 1280,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: 1.0,
      hasLeading: hasLeading,
    );
    final base = metricsFor(hasLeading: false);
    final leading = metricsFor(hasLeading: true);

    expect(base.hasLeading, isFalse);
    expect(leading.hasLeading, isTrue);
    expect(leading.cardWidth, base.cardWidth);
    expect(leading.height, base.height);

    // Uniform slot extents for every hub, leading or not.
    expect(TvBrowseRailLayout.itemExtentForIndex(index: 0, metrics: leading), leading.cardWidth + leading.itemGap);
    expect(TvBrowseRailLayout.itemExtentForIndex(index: 0, metrics: base), base.cardWidth + base.itemGap);

    // The card sits before the anchor: negative min extent, unchanged max.
    expect(TvBrowseRailLayout.minScrollExtentFor(base), 0);
    expect(
      TvBrowseRailLayout.minScrollExtentFor(leading),
      closeTo(-(leading.railEdgePadding + leading.cardWidth), 0.001),
    );
    final baseMax = TvBrowseRailLayout.estimatedMaxScrollExtent(
      hub: hub,
      metrics: base,
      viewportWidth: 640,
      hasTrailing: false,
    );
    final leadingMax = TvBrowseRailLayout.estimatedMaxScrollExtent(
      hub: hub,
      metrics: leading,
      viewportWidth: 640,
      hasTrailing: false,
    );
    expect(leadingMax, closeTo(baseMax, 0.001));

    double offsetFor({required TvBrowseRailLayoutMetrics metrics, required int index}) =>
        TvBrowseRailLayout.scrollOffsetForIndex(
          hub: hub,
          index: index,
          metrics: metrics,
          viewportWidth: 640,
          maxScrollExtent: double.infinity,
          hasTrailing: false,
        );
    // Slot i+1 with a leading card targets exactly what slot i targets
    // without one, and the first media slot rests at offset 0.
    expect(offsetFor(metrics: leading, index: 4), closeTo(offsetFor(metrics: base, index: 3), 0.001));
    expect(offsetFor(metrics: leading, index: 1), 0);
    // Focusing the options card scrolls to the negative region that reveals it.
    expect(offsetFor(metrics: leading, index: 0), TvBrowseRailLayout.minScrollExtentFor(leading));
  });

  testWidgets('leading options slot keeps default focus on the first item and opens its context menu', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    LocaleSettings.setLocaleSync(AppLocale.en);
    // Apple TV skips the download entries, keeping the menu free of the
    // DownloadProvider dependency (same trick as media_context_menu_test).
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final stack = await ProfileStack.create(db: db, withStorage: false);
    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(() async {
      await stack.dispose();
      multiServerProvider.dispose();
      await db.close();
    });

    final season = testMediaItem(
      id: 'season_1',
      backend: MediaBackend.plex,
      kind: MediaKind.season,
      title: 'Season 1',
      parentId: 'show_1',
    );
    final episodes = [
      for (var i = 1; i <= 2; i++)
        testMediaItem(
          id: 'episode_$i',
          backend: MediaBackend.plex,
          kind: MediaKind.episode,
          title: 'Episode $i',
          parentId: season.id,
          grandparentId: 'show_1',
        ),
    ];
    final hub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: episodes, size: 2);
    final focusedItemIds = <String>[];
    var sidebarRequests = 0;
    String? activatedItemId;

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  leadingItemForHub: (h) => h.id == hub.id ? season : null,
                  onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
                  onNavigateToSidebar: () => sidebarRequests++,
                  onActivateItem: (_, item) {
                    activatedItemId = item.id;
                    return true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Default focus is the first episode — the options slot adds no step to
    // normal playback.
    expect(focusedItemIds.last, 'episode_1');

    // LEFT moves onto the options slot instead of exiting to the sidebar.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(sidebarRequests, 0);

    // Select opens the season's context menu instead of activating an item.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activatedItemId, isNull);
    expect(find.text(t.mediaMenu.markAsWatched), findsOneWidget);

    // Dismiss the menu; RIGHT returns to the first episode.
    await tester.tapAt(const Offset(640, 20));
    await tester.pumpAndSettle();
    tester.state<TvBrowseRailState>(find.byType(TvBrowseRail)).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedItemIds.last, 'episode_1');

    // From the options slot, LEFT exits to the sidebar as before.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(sidebarRequests, 1);
  });

  testWidgets('initial item id resolves past the leading slot', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final season = testMediaItem(id: 'season_1', backend: MediaBackend.plex, kind: MediaKind.season, title: 'Season 1');
    final episodes = [
      for (var i = 1; i <= 3; i++)
        testMediaItem(id: 'episode_$i', backend: MediaBackend.plex, kind: MediaKind.episode, title: 'Episode $i'),
    ];
    final hub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: episodes, size: 3);
    final focusedItemIds = <String>[];

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: [hub],
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                leadingItemForHub: (h) => h.id == hub.id ? season : null,
                initialHubId: hub.id,
                initialItemId: 'episode_2',
                onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusedItemIds.last, 'episode_2');
  });

  testWidgets('empty hub leading focus advances to the first item when episodes arrive', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final season = testMediaItem(id: 'season_1', backend: MediaBackend.plex, kind: MediaKind.season, title: 'Season 1');
    final episode = testMediaItem(
      id: 'episode_1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
    );
    final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
    MediaHub seasonHub(List<MediaItem> items) =>
        MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: items, size: 1);
    final focusedItemIds = <String>[];

    Widget buildRail(List<MediaHub> hubs) {
      return ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: hubs,
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                leadingItemForHub: (h) => h.id == 'detail_season_0' ? season : null,
                onFocusedItemChanged: (item) => focusedItemIds.add(item.id),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRail([movieHub, seasonHub(const [])]));
    await tester.pump();
    expect(focusedItemIds.last, 'movie_1');

    // DOWN lands on the options slot only because the season hub has no
    // episodes yet — nothing else is focusable there.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedItemIds.last, 'movie_1');

    // When the episodes load in, focus advances off the options slot so the
    // hub behaves exactly like it does when its first page was already there.
    await tester.pumpWidget(
      buildRail([
        movieHub,
        seasonHub([episode]),
      ]),
    );
    await tester.pumpAndSettle();
    expect(focusedItemIds.last, 'episode_1');
  });

  testWidgets('leading options card stays off-screen until focused', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    LocaleSettings.setLocaleSync(AppLocale.en);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final season = testMediaItem(id: 'season_1', backend: MediaBackend.plex, kind: MediaKind.season, title: 'Season 1');
    // Deliberately few episodes: even a row too short to scroll right must
    // hide the options card at rest and still be able to reveal it.
    final episodes = [
      for (var i = 1; i <= 2; i++)
        testMediaItem(id: 'episode_$i', backend: MediaBackend.plex, kind: MediaKind.episode, title: 'Episode $i'),
    ];
    final hub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: episodes, size: 2);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: multiServerProvider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: TvBrowseRail(
                  focusMemory: focusMemory,
                  hubs: [hub],
                  autofocus: true,
                  iconForHub: (_, _) => Icons.tv_rounded,
                  leadingItemForHub: (h) => h.id == hub.id ? season : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final rowPosition = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .map((state) => state.position)
        .singleWhere(
          (position) => axisDirectionToAxis(position.axisDirection) == Axis.horizontal && position.minScrollExtent < 0,
        );

    // At rest the row anchors on episode 1; the options card lives in the
    // negative region left of the rail and never pushes content right.
    expect(rowPosition.pixels, 0);
    final railRect = tester.getRect(find.byType(TvBrowseRail));
    final optionsFinder = find.text(t.common.options, skipOffstage: false);
    expect(tester.getRect(optionsFinder).right, lessThanOrEqualTo(railRect.left + 1));

    // LEFT focuses the options card and scrolls it into view.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(rowPosition.pixels, closeTo(rowPosition.minScrollExtent, 0.5));
    expect(tester.getRect(optionsFinder).left, greaterThanOrEqualTo(railRect.left));

    // RIGHT returns to episode 1 and the card slides back off-screen.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(rowPosition.pixels, 0);
  });

  testWidgets('inactive empty hub rests anchored instead of revealing its options card', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final serverManager = MultiServerManager();
    final multiServerProvider = testMultiServerProvider(serverManager);
    addTearDown(multiServerProvider.dispose);

    final movie = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');
    final season = testMediaItem(id: 'season_1', backend: MediaBackend.plex, kind: MediaKind.season, title: 'Season 1');
    final movieHub = MediaHub(id: 'movies', title: 'Movies', type: 'movie', items: [movie], size: 1);
    // A not-yet-fetched season hub: its only slot is the options card, which
    // is exactly the shape that used to seed the row's scroll position in the
    // revealed (negative) region while the hub sat inactive below the fold.
    const seasonHub = MediaHub(id: 'detail_season_0', title: 'Season 1', type: 'episode', items: <MediaItem>[]);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>.value(
        value: multiServerProvider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: TvBrowseRail(
                focusMemory: focusMemory,
                hubs: [movieHub, seasonHub],
                autofocus: true,
                iconForHub: (_, _) => Icons.tv_rounded,
                leadingItemForHub: (h) => h.id == seasonHub.id ? season : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final inactiveRow = tester
        .stateList<ScrollableState>(find.byType(Scrollable, skipOffstage: false))
        .map((state) => state.position)
        .singleWhere(
          (position) => axisDirectionToAxis(position.axisDirection) == Axis.horizontal && position.minScrollExtent < 0,
        );
    expect(inactiveRow.pixels, 0);
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
