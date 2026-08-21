import 'dart:convert';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/tabs/library_playlists_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/card_inflation_budget.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/library_tab_scaffold.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

final _serverId = ServerId('playlist-server');
final _library = MediaLibrary(
  id: 'movies',
  backend: MediaBackend.plex,
  title: 'Movies',
  kind: MediaKind.movie,
  serverId: _serverId,
);
final _musicLibrary = MediaLibrary(
  id: 'music',
  backend: MediaBackend.plex,
  title: 'Music',
  kind: MediaKind.artist,
  serverId: _serverId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    CardInflationBudget.reset();
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('grid lazily builds playlist cards and preserves focus navigation', (tester) async {
    final harness = _PlaylistHarness();
    addTearDown(harness.dispose);
    addTearDown(harness.rebuild.dispose);
    var backCalls = 0;
    var sidebarCalls = 0;

    await _pumpTab(
      tester,
      harness: harness,
      library: _library,
      onBack: () => backCalls++,
      onSidebar: () => sidebarCalls++,
    );

    expect(find.byType(SliverGrid), findsOneWidget);
    final cards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(cards, isNotEmpty);
    expect(cards.length, lessThan(_PlaylistHarness.totalPlaylists));

    final first = _cardFor(cards, 0);
    final second = _cardFor(cards, 1);
    expect(first.focusNode, isNotNull);
    expect(first.onNavigateUp, isNotNull);
    expect(first.onNavigateLeft, isNotNull);
    expect(first.onBack, isNotNull);
    // Every card now carries explicit navigation; default directional
    // traversal is bypassed (it resets the NestedScrollView on UP).
    expect(second.onNavigateUp, isNotNull);
    expect(second.onNavigateLeft, isNotNull);

    // First row: UP and BACK hand off to the tab bar, first-column LEFT to
    // the sidebar. Second column's LEFT moves within the row instead.
    first.onNavigateUp!();
    first.onBack!();
    first.onNavigateLeft!();
    second.onNavigateLeft!();
    expect(backCalls, 2);
    expect(sidebarCalls, 1);

    // Below the top row, UP moves focus up a row rather than leaving the grid.
    final columns = cards.where((card) => identical(card.onNavigateUp, first.onNavigateUp)).length;
    final firstColumnBelowTop = _cardFor(cards, columns);
    expect(firstColumnBelowTop.onNavigateUp, isNotNull);
    firstColumnBelowTop.onNavigateUp!();
    expect(backCalls, 2);

    final firstWidget = tester.widget<FocusableMediaCard>(find.byKey(const Key('playlist-0')));
    harness.rebuild.value++;
    await tester.pump();
    final rebuiltFirstWidget = tester.widget<FocusableMediaCard>(find.byKey(const Key('playlist-0')));
    expect(identical(rebuiltFirstWidget, firstWidget), isTrue);

    final scrollableFinder = find.descendant(of: find.byType(LibraryPlaylistsTab), matching: find.byType(Scrollable));
    final scrollable = tester.state<ScrollableState>(scrollableFinder);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(harness.requestStarts, contains(200));
    final pagedCards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(pagedCards.length, lessThan(_PlaylistHarness.totalPlaylists));
    expect(
      pagedCards.map((card) => int.parse((card.item as MediaPlaylist).id.substring('playlist-'.length))),
      contains(greaterThanOrEqualTo(200)),
    );
  });

  testWidgets('list stays lazy without changing row navigation', (tester) async {
    await SettingsService.instance.write(SettingsService.viewMode, ViewMode.list);
    final harness = _PlaylistHarness();
    addTearDown(harness.dispose);
    addTearDown(harness.rebuild.dispose);
    var backCalls = 0;
    var sidebarCalls = 0;

    await _pumpTab(
      tester,
      harness: harness,
      library: _library,
      onBack: () => backCalls++,
      onSidebar: () => sidebarCalls++,
    );

    expect(find.byType(SliverList), findsOneWidget);
    final cards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(cards, isNotEmpty);
    expect(cards.length, lessThan(_PlaylistHarness.totalPlaylists));

    final first = _cardFor(cards, 0);
    final second = _cardFor(cards, 1);
    expect(first.disableScale, isTrue);
    expect(first.onNavigateUp, isNotNull);
    expect(first.onNavigateLeft, isNotNull);
    // Rows below the first navigate up explicitly; LEFT always reaches the
    // sidebar in the single-column list.
    expect(second.onNavigateUp, isNotNull);
    expect(second.onNavigateLeft, isNotNull);

    first.onNavigateUp!();
    second.onNavigateLeft!();
    second.onNavigateUp!();
    expect(backCalls, 1);
    expect(sidebarCalls, 1);
  });

  testWidgets('music library playlists use square grid geometry and square cards', (tester) async {
    final harness = _PlaylistHarness(playlistType: 'audio');
    addTearDown(harness.dispose);
    addTearDown(harness.rebuild.dispose);
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);

    await _pumpTab(tester, harness: harness, library: _musicLibrary, onBack: () {}, onSidebar: () {});

    final layout = tester.widget<MediaCardSliverLayout>(find.byType(MediaCardSliverLayout));
    expect(layout.shape, CardShape.square);
    expect(layout.fullBleedImage, isFalse);
    expect(
      tester
          .widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard))
          .every((card) => card.cardShapeOverride == CardShape.square),
      isTrue,
    );

    // Square grids keep their square gutter spacing even on TV full-card
    // layout (which is disabled for square shapes).
    final gridDelegate =
        tester.widget<SliverGrid>(find.byType(SliverGrid)).gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
    expect(gridDelegate.crossAxisSpacing, GridLayoutConstants.squareGridSpacing);
    expect(gridDelegate.mainAxisSpacing, GridLayoutConstants.squareGridSpacing);
  });
}

FocusableMediaCard _cardFor(List<FocusableMediaCard> cards, int index) {
  return cards.singleWhere((card) => (card.item as MediaPlaylist).id == 'playlist-$index');
}

Future<void> _pumpTab(
  WidgetTester tester, {
  required _PlaylistHarness harness,
  required MediaLibrary library,
  required VoidCallback onBack,
  required VoidCallback onSidebar,
}) async {
  await pumpLibraryTab(
    tester,
    provider: harness.provider,
    tab: ValueListenableBuilder<int>(
      valueListenable: harness.rebuild,
      builder: (context, _, _) => LibraryPlaylistsTab(library: library, suppressAutoFocus: true, onBack: onBack),
    ),
    size: const Size(800, 600),
    focusSidebar: onSidebar,
  );
  await tester.pumpAndSettle();
}

class _PlaylistHarness {
  static const totalPlaylists = 400;

  final String playlistType;
  final requestStarts = <int>[];
  final rebuild = ValueNotifier(0);
  late final PlexClient client;
  late final AppDatabase database;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;

  _PlaylistHarness({this.playlistType = 'video'}) {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    client = testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
      ),
      serverId: _serverId,
      httpClient: MockClient((request) async {
        if (request.url.path != '/playlists') return http.Response('not found', 404);
        final start = int.tryParse(request.url.queryParameters['X-Plex-Container-Start'] ?? '') ?? 0;
        final size = int.tryParse(request.url.queryParameters['X-Plex-Container-Size'] ?? '') ?? 200;
        requestStarts.add(start);
        final end = min(start + size, totalPlaylists);
        final metadata = List.generate(end - start, (offset) {
          final index = start + offset;
          return {
            'ratingKey': 'playlist-$index',
            'type': 'playlist',
            'playlistType': playlistType,
            'title': 'Playlist $index',
            'smart': false,
          };
        });
        return http.Response(
          jsonEncode({
            'MediaContainer': {'size': metadata.length, 'totalSize': totalPlaylists, 'Metadata': metadata},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
    provider = testMultiServerProvider(manager);
  }

  Future<void> dispose() async {
    provider.dispose();
    manager.dispose();
    await database.close();
  }
}
