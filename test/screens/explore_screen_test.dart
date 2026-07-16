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
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

class _FakeCatalogSource implements CatalogSource {
  _FakeCatalogSource(this.id, this.displayName, this.itemId);

  @override
  final CatalogSourceId id;

  @override
  final String displayName;

  final int? itemId;
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
  void dispose() => _watchlistChanges.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  _FakeCatalogSourcesProvider(this.sources);

  final List<CatalogSource> sources;

  @override
  List<CatalogSource> get connectedSources => sources;
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
  final sources = _FakeCatalogSourcesProvider([trakt, mal]);
  final explore = ExploreProvider(sources);
  addTearDown(explore.dispose);
  addTearDown(sources.dispose);
  addTearDown(trakt.dispose);
  addTearDown(mal.dispose);

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
