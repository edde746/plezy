import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/tabs/library_collections_tab.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/card_inflation_budget.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/library_tab_scaffold.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

final _serverId = ServerId('collection-server');
final _jellyfinServerId = ServerId('jellyfin-collection-server');
final _musicLibrary = MediaLibrary(
  id: 'music',
  backend: MediaBackend.plex,
  title: 'Music',
  kind: MediaKind.artist,
  serverId: _serverId,
);
final _jellyfinMusicLibrary = MediaLibrary(
  id: 'music-library',
  backend: MediaBackend.jellyfin,
  title: 'Music',
  kind: MediaKind.artist,
  serverId: _jellyfinServerId,
);
final _movieLibrary = MediaLibrary(
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
    TvDetectionService.debugSetAppleTVOverride(false);
    await SettingsService.getInstance();
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('music library collections use square grid geometry and square cards', (tester) async {
    final harness = _CollectionHarness.plex();
    addTearDown(harness.dispose);
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);

    await _pumpTab(tester, harness: harness, library: _musicLibrary);

    final layout = tester.widget<MediaCardSliverLayout>(find.byType(MediaCardSliverLayout));
    expect(layout.shape, CardShape.square);
    expect(layout.fullBleedImage, isFalse);
    expect(tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard)).cardShapeOverride, CardShape.square);
  });

  testWidgets('Jellyfin video collections keep poster geometry when opened from a music library', (tester) async {
    final harness = _CollectionHarness.jellyfin();
    addTearDown(harness.dispose);
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);

    await _pumpTab(tester, harness: harness, library: _jellyfinMusicLibrary);

    final layout = tester.widget<MediaCardSliverLayout>(find.byType(MediaCardSliverLayout));
    expect(layout.shape, isNull);
    expect(layout.fullBleedImage, isTrue);
    expect(tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard)).cardShapeOverride, isNull);
  });

  group('D-pad grid navigation', () {
    testWidgets('UP moves one row up without resetting the scroll position', (tester) async {
      final harness = _CollectionHarness.plexMovies(collectionCount: 60);
      addTearDown(harness.dispose);

      await _pumpTab(tester, harness: harness, library: _movieLibrary);
      final columns = await _enterGridAndFocusFirstCard(tester);

      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(_primaryFocusLabel(), 'paginated_grid_item_${4 * columns}');

      final scrollable = Scrollable.of(FocusManager.instance.primaryFocus!.context!);
      final pixelsBeforeUp = scrollable.position.pixels;
      expect(pixelsBeforeUp, greaterThan(0));

      // Regression #1977: default directional traversal ran
      // Scrollable.ensureVisible through the NestedScrollView coordinator,
      // which reset the inner position to 0 and bounced focus to the header.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(_primaryFocusLabel(), 'paginated_grid_item_${3 * columns}');
      expect(scrollable.position.pixels, greaterThan(0));
    });

    testWidgets('UP from the first row hands focus to onBack', (tester) async {
      final harness = _CollectionHarness.plexMovies(collectionCount: 60);
      addTearDown(harness.dispose);
      var backCalls = 0;

      await _pumpTab(tester, harness: harness, library: _movieLibrary, onBack: () => backCalls++);
      await _enterGridAndFocusFirstCard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(backCalls, 1);
    });

    testWidgets('LEFT and RIGHT move within a row; first column LEFT reaches the sidebar', (tester) async {
      final harness = _CollectionHarness.plexMovies(collectionCount: 60);
      addTearDown(harness.dispose);
      var sidebarCalls = 0;

      await _pumpTab(tester, harness: harness, library: _movieLibrary, focusSidebar: () => sidebarCalls++);
      await _enterGridAndFocusFirstCard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_primaryFocusLabel(), 'paginated_grid_item_1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(_primaryFocusLabel(), 'collections_first_item');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(sidebarCalls, 1);
    });
  });
}

Future<void> _pumpTab(
  WidgetTester tester, {
  required _CollectionHarness harness,
  required MediaLibrary library,
  VoidCallback? onBack,
  VoidCallback? focusSidebar,
}) async {
  await pumpLibraryTab(
    tester,
    provider: harness.provider,
    tab: LibraryCollectionsTab(library: library, suppressAutoFocus: true, onBack: onBack ?? () {}),
    size: const Size(800, 600),
    focusSidebar: focusSidebar,
  );
  await tester.pumpAndSettle();
}

String? _primaryFocusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

/// Switches to keyboard input mode, focuses the first card, and returns the
/// grid's column count (cards sharing the first realized row's dy).
Future<int> _enterGridAndFocusFirstCard(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();

  final cards = find.byType(FocusableMediaCard);
  final firstRowDy = tester.getTopLeft(cards.first).dy;
  var columns = 0;
  for (final element in cards.evaluate()) {
    if (tester.getTopLeft(find.byWidget(element.widget)).dy == firstRowDy) columns++;
  }

  tester.widget<FocusableMediaCard>(cards.first).focusNode!.requestFocus();
  await tester.pumpAndSettle();
  expect(_primaryFocusLabel(), 'collections_first_item');
  return columns;
}

class _CollectionHarness {
  final AppDatabase database;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;

  _CollectionHarness._({required this.database, required MediaServerClient client}) {
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
    provider = testMultiServerProvider(manager);
  }

  factory _CollectionHarness.plex() {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    final client = testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
      ),
      serverId: _serverId,
      httpClient: MockClient((request) async {
        if (request.url.path != '/library/sections/music/collections') {
          return http.Response('not found', 404);
        }
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 1,
              'Metadata': [
                {'ratingKey': 'collection-1', 'type': 'collection', 'title': 'Music Collection', 'childCount': 4},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    return _CollectionHarness._(database: database, client: client);
  }

  /// Movie library with [collectionCount] collections, served as one page.
  factory _CollectionHarness.plexMovies({required int collectionCount}) {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    final client = testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
      ),
      serverId: _serverId,
      httpClient: MockClient((request) async {
        if (request.url.path != '/library/sections/movies/collections') {
          return http.Response('not found', 404);
        }
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': collectionCount,
              'totalSize': collectionCount,
              'Metadata': [
                for (var i = 0; i < collectionCount; i++)
                  {'ratingKey': 'collection-$i', 'type': 'collection', 'title': 'Collection $i', 'childCount': 2},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    return _CollectionHarness._(database: database, client: client);
  }

  factory _CollectionHarness.jellyfin() {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(database);
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(machineId: _jellyfinServerId),
      httpClient: MockClient((request) async {
        if (request.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'boxsets-root', 'Name': 'Collections', 'CollectionType': 'boxsets'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/Items') {
          return http.Response(
            jsonEncode({
              'TotalRecordCount': 1,
              'Items': [
                {
                  'Id': 'video-collection-1',
                  'Name': 'Movie Collection',
                  'Type': 'BoxSet',
                  'MediaType': 'Video',
                  'ParentId': 'boxsets-root',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
    );
    return _CollectionHarness._(database: database, client: client);
  }

  Future<void> dispose() async {
    provider.dispose();
    manager.dispose();
    await database.close();
  }
}
