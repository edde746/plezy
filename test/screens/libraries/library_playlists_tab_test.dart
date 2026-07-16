import 'dart:convert';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/navigation/main_screen_scope.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/tabs/library_playlists_tab.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/card_inflation_budget.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

final _serverId = ServerId('playlist-server');
final _library = MediaLibrary(
  id: 'movies',
  backend: MediaBackend.plex,
  title: 'Movies',
  kind: MediaKind.movie,
  serverId: _serverId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    CardInflationBudget.reset();
    await SettingsService.getInstance();
  });

  testWidgets('grid lazily builds playlist cards and preserves focus navigation', (tester) async {
    final harness = _PlaylistHarness();
    addTearDown(harness.dispose);
    addTearDown(harness.rebuild.dispose);
    var backCalls = 0;
    var sidebarCalls = 0;

    await _pumpTab(tester, harness: harness, onBack: () => backCalls++, onSidebar: () => sidebarCalls++);

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
    expect(second.onNavigateUp, isNotNull);
    expect(second.onNavigateLeft, isNull);

    final firstColumnBelowTop = cards.firstWhere((card) => card.onNavigateUp == null && card.onNavigateLeft != null);
    expect((firstColumnBelowTop.item as MediaPlaylist).id, isNot('playlist-0'));

    first.onNavigateUp!();
    first.onBack!();
    first.onNavigateLeft!();
    expect(backCalls, 2);
    expect(sidebarCalls, 1);

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

    await _pumpTab(tester, harness: harness, onBack: () => backCalls++, onSidebar: () => sidebarCalls++);

    expect(find.byType(SliverList), findsOneWidget);
    final cards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(cards, isNotEmpty);
    expect(cards.length, lessThan(_PlaylistHarness.totalPlaylists));

    final first = _cardFor(cards, 0);
    final second = _cardFor(cards, 1);
    expect(first.disableScale, isTrue);
    expect(first.onNavigateUp, isNotNull);
    expect(first.onNavigateLeft, isNotNull);
    expect(second.onNavigateUp, isNull);
    expect(second.onNavigateLeft, isNotNull);

    first.onNavigateUp!();
    second.onNavigateLeft!();
    expect(backCalls, 1);
    expect(sidebarCalls, 1);
  });
}

FocusableMediaCard _cardFor(List<FocusableMediaCard> cards, int index) {
  return cards.singleWhere((card) => (card.item as MediaPlaylist).id == 'playlist-$index');
}

Future<void> _pumpTab(
  WidgetTester tester, {
  required _PlaylistHarness harness,
  required VoidCallback onBack,
  required VoidCallback onSidebar,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider<MultiServerProvider>.value(
      value: harness.provider,
      child: InputModeTracker(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: MainScreenFocusScope(
            focusSidebar: onSidebar,
            focusContent: () {},
            isSidebarFocused: false,
            sideNavigationWidth: 0,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: const SliverToBoxAdapter(child: SizedBox(height: 1)),
                  ),
                ],
                body: ValueListenableBuilder<int>(
                  valueListenable: harness.rebuild,
                  builder: (context, _, _) =>
                      LibraryPlaylistsTab(library: _library, suppressAutoFocus: true, onBack: onBack),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PlaylistHarness {
  static const totalPlaylists = 400;

  final requestStarts = <int>[];
  final rebuild = ValueNotifier(0);
  late final PlexClient client;
  late final AppDatabase database;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;

  _PlaylistHarness() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    client = PlexClient.forTesting(
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
            'playlistType': 'video',
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
    provider = MultiServerProvider(manager, DataAggregationService(manager));
  }

  Future<void> dispose() async {
    provider.dispose();
    manager.dispose();
    await database.close();
  }
}
