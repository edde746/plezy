import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(defaultLayout.useWideLayout, isFalse);
      expect(forcedLayout.useWideLayout, isTrue);
      expect(forcedLayout.posterHeight, lessThan(defaultLayout.posterHeight));
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

      expect(posterMetrics.height, greaterThan(wideMetrics.height));
      expect(maxHeight, posterMetrics.height);
      expect(
        TvBrowseRailLayout.estimateHeight(
          size: size,
          hubs: [wideHub, posterHub],
          density: LibraryDensity.max,
          episodePosterMode: EpisodePosterMode.episodeThumbnail,
        ),
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
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    HubFocusMemory.clear();
    await SettingsService.getInstance();
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
    HubFocusMemory.setForHub(episodeHub.id, 5);

    await tester.pumpWidget(
      ChangeNotifierProvider<MultiServerProvider>(
        create: (_) => MultiServerProvider(serverManager, DataAggregationService(serverManager)),
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              height: 720,
              child: TvBrowseRail(
                hubs: [movieHub, episodeHub],
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);

    final position = _activeRailPosition(tester);
    final scale = TvBrowseRailLayout.scaleForSize(tester.view.physicalSize / tester.view.devicePixelRatio);
    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: episodeHub,
      availableWidth: position.viewportDimension,
      density: LibraryDensity.defaultValue,
      episodePosterMode: EpisodePosterMode.episodeThumbnail,
      scale: scale,
    );
    final itemExtent = metrics.cardWidth + metrics.itemGap;
    final targetCenter = metrics.railEdgePadding + (5 * itemExtent) + (itemExtent / 2);
    final expectedOffset = (targetCenter - (position.viewportDimension / 2)).clamp(0.0, position.maxScrollExtent);

    expect(position.pixels, closeTo(expectedOffset, 0.1));
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
}

ScrollPosition _activeRailPosition(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .map((state) => state.position)
      .where((position) => position.maxScrollExtent > 0)
      .reduce((a, b) => a.maxScrollExtent > b.maxScrollExtent ? a : b);
}
