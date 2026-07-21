import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/screens/explore_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/catalog_source_logo.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

class _FakeCatalogSource implements CatalogSource, CatalogHubSource {
  _FakeCatalogSource(this.id, this.displayName, this.itemId, {this.providerHubTitle});

  @override
  final CatalogSourceId id;

  @override
  final String displayName;

  final int? itemId;
  final String? providerHubTitle;
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();

  @override
  List<CatalogRowId> get supportedRows => const [CatalogRowId.popularMovies];

  @override
  bool get supportsWatchlist => false;

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    return CatalogPage(
      items: [
        if (itemId case final itemId?)
          CatalogItem(
            source: id,
            kind: MediaKind.movie,
            title: '$displayName Movie',
            ids: CatalogItemIds(tmdb: itemId),
          ),
      ],
    );
  }

  @override
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final title = providerHubTitle;
    if (title == null) return const [];
    return [
      CatalogHub(
        id: 'plex-recommendation',
        title: title,
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
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final trakt = _FakeCatalogSource(CatalogSourceId.trakt, 'Trakt', traktItemId);
  final mal = _FakeCatalogSource(CatalogSourceId.mal, 'MyAnimeList', malItemId);
  final anilist = _FakeCatalogSource(CatalogSourceId.anilist, 'AniList', 3);
  final simkl = _FakeCatalogSource(CatalogSourceId.simkl, 'Simkl', 4);
  final plex = _FakeCatalogSource(
    CatalogSourceId.plex,
    'Plex',
    5,
    providerHubTitle: 'Because You Watchlisted Inception',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
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

  testWidgets('Plex provider-defined recommendation hub renders as an Explore shelf', (tester) async {
    final sources = await _pumpExplore(tester);

    await sources.setActiveSource(CatalogSourceId.plex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Because You Watchlisted Inception'), findsOneWidget);
    expect(find.text('Plex Recommendation'), findsAtLeast(1));
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
}
