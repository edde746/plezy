import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_cast_member.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/catalog_item_detail_screen.dart';
import 'package:plezy/screens/catalog_search_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

/// Only the members the search screen touches; everything else throws.
class _FakeSearchSource implements CatalogSource {
  final queries = <String>[];
  bool failNext = false;

  @override
  CatalogSourceId get id => CatalogSourceId.trakt;

  @override
  String get displayName => 'Trakt';

  @override
  bool get supportsWatchlist => false;

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    queries.add(query);
    if (failNext) {
      failNext = false;
      throw Exception('boom');
    }
    return [
      CatalogItem(source: id, kind: MediaKind.movie, title: 'result: $query', ids: const CatalogItemIds(tmdb: 1)),
    ];
  }

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async => const [];

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async => const [];

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _FakeSearchSource source) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: CatalogSearchScreen(source: source),
      ),
    ),
  );
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
  });

  testWidgets('reverting to the last-searched query cancels the pending debounce', (tester) async {
    final source = _FakeSearchSource();
    await _pump(tester, source);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(source.queries, ['abc']);
    expect(_state(tester).searchResults.single.title, 'result: abc');

    // Type ahead, then revert to the shown query before the debounce fires:
    // the armed 'abcd' search must never run.
    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(source.queries, ['abc']);
    expect(_state(tester).searchResults.single.title, 'result: abc');
  });

  testWidgets('failed search shows the failure state and recovers on retry', (tester) async {
    final source = _FakeSearchSource()..failNext = true;
    await _pump(tester, source);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text(t.explore.searchFailed), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(_state(tester).searchResults.single.title, 'result: abcd');
    expect(find.text(t.explore.searchFailed), findsNothing);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('catalog result menu uses the adaptive sheet and dispatches on ${platform.name}', (tester) async {
      final source = _FakeSearchSource();
      await _pumpMenuSearch(tester, source, platform: platform);
      await _searchForMenuResult(tester);

      final card = find.byType(MediaCard);
      expect(card, findsOneWidget);
      tester.state<MediaCardState>(card).showContextMenu();
      await tester.pumpAndSettle();

      expect(_adaptiveMenuSheet(), findsOneWidget);
      expect(_appMenuList(), findsOneWidget);

      await tester.tap(find.text(t.mediaMenu.viewDetails));
      await tester.pumpAndSettle();

      expect(_adaptiveMenuSheet(), findsNothing);
      expect(find.byType(CatalogItemDetailScreen), findsOneWidget);
    });
  }

  testWidgets('catalog result menu uses an anchored desktop popup and dispatches its result', (tester) async {
    final source = _FakeSearchSource();
    await _pumpMenuSearch(tester, source, platform: TargetPlatform.macOS);
    await _searchForMenuResult(tester);

    final card = find.byType(MediaCard);
    expect(card, findsOneWidget);
    final cardRect = tester.getRect(card);
    tester.state<MediaCardState>(card).showContextMenu();
    await tester.pumpAndSettle();

    expect(_adaptiveMenuSheet(), findsNothing);
    expect(_appMenuList(), findsOneWidget);
    final menuRect = tester.getRect(_appMenuList());
    expect(menuRect.left, closeTo(cardRect.left, 0.01));
    expect(menuRect.top, closeTo(cardRect.bottom + 4, 0.01));

    await tester.tap(find.text(t.mediaMenu.viewDetails));
    await tester.pumpAndSettle();

    expect(_appMenuList(), findsNothing);
    expect(find.byType(CatalogItemDetailScreen), findsOneWidget);
  });
}

dynamic _state(WidgetTester tester) => tester.state<State<CatalogSearchScreen>>(find.byType(CatalogSearchScreen));

class _FakeCatalogSourcesProvider extends CatalogSourcesProvider {
  _FakeCatalogSourcesProvider(this.source);

  final CatalogSource source;

  @override
  List<CatalogSource> get connectedSources => [source];
}

class _FakeCatalogLibraryMatcher extends CatalogLibraryMatcher {
  _FakeCatalogLibraryMatcher(super.multiServer);

  @override
  Future<List<MediaItem>> match(CatalogItem item) async => const [];
}

Future<void> _pumpMenuSearch(WidgetTester tester, _FakeSearchSource source, {required TargetPlatform platform}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = platform == TargetPlatform.iOS || platform == TargetPlatform.android
      ? const Size(390, 844)
      : const Size(1280, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final sources = _FakeCatalogSourcesProvider(source);
  final manager = MultiServerManager();
  final multiServer = MultiServerProvider(manager, DataAggregationService(manager));
  final matcher = _FakeCatalogLibraryMatcher(multiServer);
  addTearDown(manager.dispose);
  addTearDown(multiServer.dispose);
  addTearDown(sources.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          Provider<CatalogLibraryMatcher>.value(value: matcher),
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: platform),
          home: CatalogSearchScreen(source: source),
        ),
      ),
    ),
  );
}

Future<void> _searchForMenuResult(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'menu');
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  expect(find.text('result: menu'), findsOneWidget);
}

Finder _adaptiveMenuSheet() => find.byWidgetPredicate((widget) => widget is AppMenuSheet<Object?>);

Finder _appMenuList() => find.byWidgetPredicate((widget) => widget is AppMenuList<Object?>);
