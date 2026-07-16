import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/models/catalog/catalog_cast_member.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/catalog_item_detail_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

class _FakeCatalogSource implements CatalogSource {
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();

  @override
  CatalogSourceId get id => CatalogSourceId.trakt;

  @override
  String get displayName => 'Trakt';

  @override
  bool get supportsWatchlist => true;

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async => const [
    CatalogCastMember(name: 'First Actor', secondary: 'Lead'),
    CatalogCastMember(name: 'Second Actor', secondary: 'Support'),
  ];

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async => const [
    CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Related Movie',
      ids: CatalogItemIds(tmdb: 2),
    ),
  ];

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => false;

  @override
  void dispose() => _watchlistChanges.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  final CatalogSource source;

  _FakeCatalogSourcesProvider(this.source);

  @override
  List<CatalogSource> get connectedSources => [source];
}

class _FakeCatalogLibraryMatcher extends CatalogLibraryMatcher {
  _FakeCatalogLibraryMatcher(super.multiServer, this.matches);

  final List<MediaItem> matches;

  @override
  Future<List<MediaItem>> match(CatalogItem item) async => matches;
}

const _item = CatalogItem(
  source: CatalogSourceId.trakt,
  kind: MediaKind.movie,
  title: 'Catalog Movie',
  overview: 'Overview',
  ids: CatalogItemIds(tmdb: 1),
);

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeCatalogSource source, {
  List<MediaItem> matches = const [],
  bool pushedRoute = false,
}) async {
  final sources = _FakeCatalogSourcesProvider(source);
  final serverManager = MultiServerManager();
  final multiServer = MultiServerProvider(serverManager, DataAggregationService(serverManager));
  final matcher = _FakeCatalogLibraryMatcher(multiServer, matches);
  addTearDown(sources.dispose);
  addTearDown(source.dispose);
  addTearDown(serverManager.dispose);
  addTearDown(multiServer.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          Provider<CatalogLibraryMatcher>.value(value: matcher),
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: pushedRoute
              ? Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => const CatalogItemDetailScreen(item: _item))),
                      child: const Text('Open catalog'),
                    ),
                  ),
                )
              : const CatalogItemDetailScreen(item: _item),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (pushedRoute) {
    await tester.tap(find.text('Open catalog'));
    await tester.pumpAndSettle();
  }
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

  testWidgets('D-pad traverses from actions through cast and back from recommendations', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpDetail(tester, _FakeCatalogSource());
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');
    expect(
      tester.widget<SingleChildScrollView>(find.byKey(const Key('catalog_detail_scroll'))).controller!.offset,
      greaterThan(0),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, startsWith('hub_catalog-related:'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');
    expect(tester.widget<SingleChildScrollView>(find.byKey(const Key('catalog_detail_scroll'))).controller!.offset, 0);
  });

  testWidgets('D-pad includes every library match between actions and cast', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final matches = [
      testMediaItem(id: 'match_1', libraryTitle: 'Movies', serverName: 'Living Room'),
      testMediaItem(id: 'match_2', libraryTitle: 'Favorites', serverName: 'Bedroom'),
    ];
    await _pumpDetail(tester, _FakeCatalogSource(), matches: matches);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_cast_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog_library_match_1');
  });

  testWidgets('TV Back closes a hosted sheet without popping the catalog route', (tester) async {
    await _pumpDetail(tester, _FakeCatalogSource(), pushedRoute: true);

    final sheetResult = OverlaySheetController.showAdaptive<void>(
      tester.element(find.byType(FocusableActionBar)),
      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('Hosted request sheet'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hosted request sheet'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);
    // Android TV can dispatch route Back for the same remote press. Deliver
    // that duplicate in the same key sequence, before the coordinator's
    // one-frame ownership marker is cleared.
    await tester.binding.handlePopRoute();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text('Hosted request sheet'), findsNothing);
    expect(find.byType(CatalogItemDetailScreen), findsOneWidget);
    await expectLater(sheetResult, completion(isNull));

    // A later, independent system Back still pops the catalog route.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CatalogItemDetailScreen), findsNothing);
  });

  testWidgets('recommendation posters use compact grid-equivalent TV sizing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpDetail(tester, _FakeCatalogSource());

    expect(tester.getSize(find.byType(MediaCard).first).width, lessThan(210));
  });
}
