import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/screens/explore_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/catalog_source_logo.dart';
import 'package:plezy/widgets/search_input_field.dart';
import 'package:plezy/widgets/fitting_title_text.dart';
import 'package:plezy/widgets/optimized_media_image.dart' show ClearLogoImage;
import 'package:plezy/widgets/tv_spotlight_background.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

class _FakeCatalogSource implements CatalogSource, CatalogHubSource {
  _FakeCatalogSource(
    this.id,
    this.displayName,
    this.itemId, {
    this.providerHubTitle,
    this.providerHubStyle,
    this.rowItem,
    this.rowTotalResults,
  });

  @override
  final CatalogSourceId id;

  @override
  final String displayName;

  final int? itemId;
  final String? providerHubTitle;
  final CatalogHubStyle? providerHubStyle;
  final CatalogItem? rowItem;
  final int? rowTotalResults;
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();

  /// Search bookkeeping: [searchTitles] overrides the single default hit so a
  /// suite can assert the empty-result state.
  final searchQueries = <String>[];
  List<String>? searchTitles;
  bool searchFails = false;

  @override
  List<CatalogRowId> get supportedRows => const [CatalogRowId.popularMovies];

  @override
  bool get supportsWatchlist => false;

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final item =
        rowItem ??
        (itemId == null
            ? null
            : CatalogItem(
                source: id,
                kind: MediaKind.movie,
                title: '$displayName Movie',
                ids: CatalogItemIds(tmdb: itemId),
              ));
    return CatalogPage(
      items: [?item],
      hasMore: rowTotalResults != null && rowTotalResults! > 1,
      totalResults: rowTotalResults,
    );
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    searchQueries.add(query);
    if (searchFails) throw Exception('search boom');
    return [
      for (final title in searchTitles ?? ['$displayName search: $query'])
        CatalogItem(
          source: id,
          kind: MediaKind.movie,
          title: title,
          ids: CatalogItemIds(slug: title),
        ),
    ];
  }

  @override
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final title = providerHubTitle;
    if (title == null) return const [];
    return [
      CatalogHub(
        id: 'plex-recommendation',
        title: title,
        style: providerHubStyle,
        page: CatalogPage(
          items: [
            CatalogItem(
              source: id,
              kind: MediaKind.show,
              title: 'Plex Recommendation',
              ids: const CatalogItemIds(plex: 'plex-recommendation'),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25}) async => const CatalogPage(items: []);

  @override
  void dispose() => _watchlistChanges.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  _FakeCatalogSourcesProvider(this.sources);

  final List<CatalogSource> sources;
  CatalogSourceId? _activeId;

  @override
  List<CatalogSource> get connectedSources => sources;

  @override
  CatalogSource? get activeSource {
    for (final source in sources) {
      if (source.id == _activeId) return source;
    }
    return sources.isEmpty ? null : sources.first;
  }

  @override
  Future<void> setActiveSource(CatalogSourceId id) async {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }
}

Future<_FakeCatalogSourcesProvider> _pumpExplore(
  WidgetTester tester, {
  int? traktItemId = 1,
  int? malItemId = 2,
  bool? tv,
  CatalogItem? traktItem,
  int? traktTotalResults,
  CatalogHubStyle? plexHubStyle,
}) async {
  if (tv != null) TvDetectionService.debugSetAppleTVOverride(tv);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final trakt = _FakeCatalogSource(
    CatalogSourceId.trakt,
    'Trakt',
    traktItemId,
    rowItem: traktItem,
    rowTotalResults: traktTotalResults,
  );
  final mal = _FakeCatalogSource(CatalogSourceId.mal, 'MyAnimeList', malItemId);
  final anilist = _FakeCatalogSource(CatalogSourceId.anilist, 'AniList', 3);
  final simkl = _FakeCatalogSource(CatalogSourceId.simkl, 'Simkl', 4);
  final plex = _FakeCatalogSource(
    CatalogSourceId.plex,
    'Plex',
    5,
    providerHubTitle: 'Trending on Plex',
    providerHubStyle: plexHubStyle,
  );
  final seerr = _FakeCatalogSource(CatalogSourceId.seerr, 'Seerr', 6);
  final sources = _FakeCatalogSourcesProvider([trakt, mal, anilist, simkl, plex, seerr]);
  final explore = ExploreProvider(sources);
  addTearDown(explore.dispose);
  addTearDown(sources.dispose);
  addTearDown(trakt.dispose);
  addTearDown(mal.dispose);
  addTearDown(anilist.dispose);
  addTearDown(simkl.dispose);
  addTearDown(plex.dispose);
  addTearDown(seerr.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
          ChangeNotifierProvider<ExploreProvider>.value(value: explore),
        ],
        child: MaterialApp(theme: monoTheme(dark: true), home: const ExploreScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sources;
}

_FakeCatalogSource _fakeSource(_FakeCatalogSourcesProvider sources, CatalogSourceId id) =>
    sources.sources.firstWhere((source) => source.id == id) as _FakeCatalogSource;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    // The spotlight countdown formats dates; `main.dart` does this at startup.
    await initializeDateFormatting('en');
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('TV source switcher is reachable from the browse rail and changes source', (tester) async {
    final sources = await _pumpExplore(tester);
    tester.state<ExploreScreenState>(find.byType(ExploreScreen)).focusActiveTabIfReady();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
    expect(find.byTooltip(t.explore.selectSource), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ExploreSourceSwitcher');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('MyAnimeList'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(sources.activeSource?.id, CatalogSourceId.mal);
    expect(find.text('MyAnimeList'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
  });

  testWidgets('source switcher announces the active source as its value', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false);
    final semantics = tester.ensureSemantics();
    final sources = await _pumpExplore(tester);

    var finder = find.bySemanticsLabel(t.explore.selectSource);
    expect(finder, findsOneWidget);
    final node = tester.getSemantics(finder);
    var data = node.getSemanticsData();
    expect(data.value, 'Trakt');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MyAnimeList'));
    await tester.pumpAndSettle();

    expect(sources.activeSource?.id, CatalogSourceId.mal);
    finder = find.bySemanticsLabel(t.explore.selectSource);
    expect(finder, findsOneWidget);
    data = tester.getSemantics(finder).getSemanticsData();
    expect(data.value, 'MyAnimeList');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('source switcher exposes every catalog source with its brand logo', (tester) async {
    final sources = await _pumpExplore(tester);
    tester.state<ExploreScreenState>(find.byType(ExploreScreen)).focusActiveTabIfReady();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    for (final name in ['Trakt', 'MyAnimeList', 'AniList', 'Simkl', 'Plex', 'Seerr']) {
      expect(find.text(name), findsAtLeast(1));
    }
    expect(find.byType(CatalogSourceLogo), findsAtLeast(6));

    await tester.tap(find.text('AniList'));
    await tester.pumpAndSettle();
    expect(sources.activeSource?.id, CatalogSourceId.anilist);
    expect(find.text('AniList'), findsOneWidget);
    expect(find.text('AniList Movie'), findsAtLeast(1));
  });

  testWidgets('a null-style Plex provider hub keeps the existing Explore shelf', (tester) async {
    final sources = await _pumpExplore(tester);

    await sources.setActiveSource(CatalogSourceId.plex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Trending on Plex'), findsOneWidget);
    expect(find.text('Plex Recommendation'), findsAtLeast(1));
  });

  testWidgets('an explicit shelf-style Plex hub keeps the existing Explore shelf', (tester) async {
    final sources = await _pumpExplore(tester, plexHubStyle: CatalogHubStyle.shelf);

    await sources.setActiveSource(CatalogSourceId.plex);
    await tester.pumpAndSettle();

    expect(find.text('Trending on Plex'), findsOneWidget);
    expect(find.text('Plex Recommendation'), findsAtLeast(1));
  });

  testWidgets('an availability-platforms hub is not rendered as a title shelf', (tester) async {
    final sources = await _pumpExplore(tester, tv: false, plexHubStyle: CatalogHubStyle.availabilityPlatforms);

    await sources.setActiveSource(CatalogSourceId.plex);
    await tester.pumpAndSettle();

    expect(find.text('Plex Movie'), findsAtLeast(1));
    expect(find.text('Trending on Plex'), findsNothing);
    expect(find.text('Plex Recommendation'), findsNothing);
  });

  testWidgets('a provider total result count reaches the existing shelf header', (tester) async {
    await _pumpExplore(tester, tv: false, traktTotalResults: 87);

    expect(find.text(t.explore.totalResults(n: 87)), findsOneWidget);
  });

  group('TV catalog spotlight', () {
    testWidgets('prefers logo and banner art, applies the accent tint, and shows the next episode', (tester) async {
      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.show,
        title: 'Logo Series',
        ids: const CatalogItemIds(tmdb: 101),
        logoUrl: 'https://images.example/logo.png',
        bannerUrl: 'https://images.example/banner.jpg',
        backdropUrl: 'https://images.example/default.jpg',
        backdropVariants: const {1920: 'https://images.example/backdrop-1920.jpg'},
        accentColor: '#336699',
        nextEpisode: CatalogNextEpisode(episode: 8, airsAt: DateTime.now().add(const Duration(days: 2))),
      );

      await _pumpExplore(tester, traktItem: item);

      final spotlightFinder = find.byType(TvSpotlightBackground);
      final spotlight = tester.widget<TvSpotlightBackground>(spotlightFinder);
      expect(spotlight.item?.clearLogoPath, 'https://images.example/logo.png');
      expect(spotlight.item?.artPath, 'https://images.example/banner.jpg');
      expect(find.descendant(of: spotlightFinder, matching: find.byType(ClearLogoImage)), findsOneWidget);
      // Scoped to the spotlight: the shelf card underneath renders its own
      // countdown badge from the same item, so an unscoped finder matches two.
      expect(
        find.descendant(
          of: spotlightFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && (widget.data?.startsWith('Ep 8 in ') ?? false),
          ),
        ),
        findsOneWidget,
      );

      final baseColor = monoTheme(dark: true).scaffoldBackgroundColor;
      final expectedTint = Color.alphaBlend(const Color(0xff336699).withValues(alpha: 0.18), baseColor);
      expect(Theme.of(tester.element(spotlightFinder)).scaffoldBackgroundColor, expectedTint);
    });

    testWidgets('falls back to the plain text title when a catalog logo is absent', (tester) async {
      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.movie,
        title: 'Plain Title',
        ids: const CatalogItemIds(tmdb: 102),
        backdropUrl: 'https://images.example/backdrop.jpg',
      );

      await _pumpExplore(tester, traktItem: item);

      final spotlightFinder = find.byType(TvSpotlightBackground);
      final spotlight = tester.widget<TvSpotlightBackground>(spotlightFinder);
      expect(spotlight.item?.clearLogoPath, isNull);
      expect(find.descendant(of: spotlightFinder, matching: find.byType(FittingTitleText)), findsOneWidget);
      expect(find.descendant(of: spotlightFinder, matching: find.text('Plain Title')), findsOneWidget);
    });

    testWidgets('selects backdrop variants from logical width and device pixel ratio', (tester) async {
      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.movie,
        title: 'Variant Movie',
        ids: const CatalogItemIds(tmdb: 103),
        backdropUrl: 'https://images.example/default.jpg',
        backdropVariants: const {
          900: 'https://images.example/backdrop-900.jpg',
          1500: 'https://images.example/backdrop-1500.jpg',
          2500: 'https://images.example/backdrop-2500.jpg',
        },
      );

      await _pumpExplore(tester, traktItem: item);
      String? selectedBackdrop() =>
          tester.widget<TvSpotlightBackground>(find.byType(TvSpotlightBackground)).item?.artPath;

      tester.view.physicalSize = const Size(800, 720);
      await tester.pump();
      expect(selectedBackdrop(), 'https://images.example/backdrop-900.jpg');

      tester.view.physicalSize = const Size(1200, 720);
      await tester.pump();
      expect(selectedBackdrop(), 'https://images.example/backdrop-1500.jpg');

      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(2400, 1440);
      await tester.pump();
      expect(selectedBackdrop(), 'https://images.example/backdrop-2500.jpg');
    });
  });

  testWidgets('TV source switcher remains focused when the active source has no rows', (tester) async {
    final sources = await _pumpExplore(tester, traktItemId: null);

    tester.state<ExploreScreenState>(find.byType(ExploreScreen)).focusActiveTabIfReady();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ExploreSourceSwitcher');
    expect(find.byTooltip(t.explore.selectSource), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(sources.activeSource?.id, CatalogSourceId.mal);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_browse_rail');
  });

  group('inline search', () {
    testWidgets('results replace the shelves while the query is live and the shelves return on clear', (tester) async {
      final sources = await _pumpExplore(tester, tv: false);
      final trakt = _fakeSource(sources, CatalogSourceId.trakt);

      expect(find.text(t.explore.searchHint(source: 'Trakt')), findsOneWidget);
      // The pushed search route is TV-only now; the inline field replaces it.
      expect(find.byTooltip(t.common.search), findsNothing);
      expect(find.text(t.explore.rows.popularMovies), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'incep');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(trakt.searchQueries, ['incep']);
      expect(find.text(t.explore.rows.popularMovies), findsNothing);
      expect(find.text('Trakt search: incep'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Trakt search: incep'), findsNothing);
      expect(find.text(t.explore.rows.popularMovies), findsOneWidget);
    });

    testWidgets('a query with no hits keeps the shelves hidden behind the empty state', (tester) async {
      final sources = await _pumpExplore(tester, tv: false);
      _fakeSource(sources, CatalogSourceId.trakt).searchTitles = const [];

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text(t.explore.searchEmpty(query: 'zzz')), findsOneWidget);
      expect(find.text(t.explore.rows.popularMovies), findsNothing);
    });

    testWidgets('a failed search shows the failure state and recovers on the next query', (tester) async {
      final sources = await _pumpExplore(tester, tv: false);
      final trakt = _fakeSource(sources, CatalogSourceId.trakt)..searchFails = true;

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text(t.explore.searchFailed), findsOneWidget);

      trakt.searchFails = false;
      await tester.enterText(find.byType(TextField), 'abcd');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text(t.explore.searchFailed), findsNothing);
      expect(find.text('Trakt search: abcd'), findsOneWidget);
    });

    testWidgets('switching source re-runs the live query against the new source', (tester) async {
      final sources = await _pumpExplore(tester, tv: false);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Trakt search: abc'), findsOneWidget);

      await sources.setActiveSource(CatalogSourceId.mal);
      await tester.pumpAndSettle();

      expect(_fakeSource(sources, CatalogSourceId.mal).searchQueries, ['abc']);
      expect(find.text('MyAnimeList search: abc'), findsOneWidget);
      expect(find.text('Trakt search: abc'), findsNothing);
    });

    testWidgets('the field sits between the app bar and the first shelf at phone width', (tester) async {
      await _pumpExplore(tester, tv: false);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();

      final title = tester.getRect(find.text('Trakt'));
      final field = tester.getRect(find.byType(SearchInputField));
      final shelf = tester.getRect(find.text(t.explore.rows.popularMovies));

      expect(field.top, greaterThan(title.bottom));
      expect(field.bottom, lessThan(shelf.top));
      expect(field.width, lessThanOrEqualTo(390));
    });
  });
}
