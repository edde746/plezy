import 'dart:async';
import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

JellyfinConnection _conn() => testJellyfinConnection(
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

/// Minimal client with independently configurable library and search outcomes.
class _LibrariesClient implements MediaServerClient {
  _LibrariesClient(
    this.serverId, {
    this.error,
    this.libraries = const [],
    this.searchError,
    this.searchResults = const [],
  });

  @override
  final ServerId serverId;

  @override
  final String serverName = 'Server';

  final Object? error;
  final List<MediaLibrary> libraries;
  final Object? searchError;
  final List<MediaItem> searchResults;
  Set<String>? lastExcludedLibraryIds;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    if (error != null) throw error!;
    return libraries;
  }

  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    lastExcludedLibraryIds = excludedLibraryIds;
    abort?.throwIfAborted();
    if (searchError != null) throw searchError!;
    return searchResults;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Per-library hub client whose fetches are held open individually, so a test
/// can observe exactly when the fan-out starts each library.
class _GatedHubsClient implements MediaServerClient {
  _GatedHubsClient(this.libraries);

  final List<MediaLibrary> libraries;
  final started = <String>[];
  final _gates = <String, Completer<List<MediaHub>>>{};

  void complete(String libraryId) {
    _gates[libraryId]!.complete([
      MediaHub(
        id: '$libraryId.recent',
        title: libraryId,
        type: 'mixed',
        items: const [],
        size: 0,
        libraryId: libraryId,
      ),
    ]);
  }

  @override
  ServerId get serverId => ServerId('server-1');

  @override
  String get serverName => 'Server';

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => libraries;

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    String? libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) {
    started.add(libraryId);
    return (_gates[libraryId] = Completer<List<MediaHub>>()).future;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Covers the remaining cross-server [DataAggregationService] fan-out surface;
/// single-server calls now go through the per-server client context.
void main() {
  late AppDatabase db;
  late MultiServerManager manager;
  late DataAggregationService service;

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    manager = MultiServerManager();
    service = DataAggregationService(manager);
  });

  tearDown(() async {
    manager.dispose();
    await db.close();
  });

  for (final backend in ['plex', 'jellyfin', 'emby']) {
    test('$backend offline expected-server misses expire and reveal copies after recovery', () async {
      var requests = 0;
      Future<http.Response> respond(http.Request request) async {
        requests++;
        if (backend == 'plex') {
          return _json({
            'MediaContainer': {
              'Metadata': request.url.path == '/library/all'
                  ? [
                      {
                        'ratingKey': 'recovered',
                        'type': 'movie',
                        'title': 'Recovered Movie',
                        'guid': 'com.plexapp.agents.themoviedb://42?lang=en',
                      },
                    ]
                  : <Object>[],
              'Hub': <Object>[],
            },
          });
        }
        return request.url.path.endsWith('/Ancestors')
            ? _json(<Object>[])
            : _json({
                'Items': [
                  {
                    'Id': 'recovered',
                    'Type': 'Movie',
                    'Name': 'Recovered Movie',
                    'ProviderIds': {'Tmdb': '42'},
                  },
                ],
              });
      }

      final MediaServerClient client = switch (backend) {
        'plex' => testPlexClient(serverId: ServerId(backend), handler: respond),
        'emby' => testEmbyClient(
          connection: testEmbyConnection(machineId: backend),
          handler: respond,
        ),
        _ => testJellyfinClient(
          connection: testJellyfinConnection(machineId: backend),
          handler: respond,
        ),
      };
      manager.debugRegisterClientForTesting(client, online: false);
      final multiServer = MultiServerProvider(manager, service)
        ..setExpectedVisibleServerIds({backend})
        ..setVisibleServerIds({});
      var now = DateTime.utc(2026, 7, 28);
      final matcher = CatalogLibraryMatcher.withClock(multiServer, () => now);
      addTearDown(() {
        matcher.dispose();
        multiServer.dispose();
      });
      const item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.movie,
        title: 'Recovered Movie',
        ids: CatalogItemIds(tmdb: 42),
      );

      final offline = await matcher.match(item);
      expect(offline.items, isEmpty);
      expect(offline.succeededServerIds, isEmpty);
      expect(offline.unqueriedServerIds, {backend});
      manager.debugRegisterClientForTesting(client);
      now = now.add(CatalogLibraryMatcher.negativeTtl - const Duration(seconds: 1));
      expect((await matcher.match(item)).unqueriedServerIds, {backend});
      expect(requests, 0);

      now = now.add(const Duration(seconds: 1));
      final recovered = await matcher.match(item);
      expect(recovered.items.single.id, 'recovered');
      expect(recovered.items.single.serverId, backend);
      expect(recovered.succeededServerIds, {backend});
      expect(recovered.unqueriedServerIds, isEmpty);
    });
  }

  group('external-id query coverage', () {
    for (final query in [
      (
        name: 'Plex-only guid',
        ids: const ExternalIds(),
        titles: const ['Night on the Galactic Railroad'],
        plexGuid: 'plex://movie/5d776b59ad5437001f79c6f8',
        succeeded: {'plex'},
        plexPaths: ['/library/all'],
        mediaBrowserPaths: <String>[],
      ),
      (
        name: 'external id without title',
        ids: const ExternalIds(tmdb: 34523),
        titles: const <String>[],
        plexGuid: null,
        succeeded: {'plex'},
        plexPaths: ['/library/all'],
        mediaBrowserPaths: <String>[],
      ),
      (
        name: 'external id and native title',
        ids: const ExternalIds(tmdb: 34523),
        titles: const ['銀河鉄道の夜'],
        plexGuid: null,
        succeeded: {'plex', 'jellyfin', 'emby'},
        plexPaths: ['/library/all', '/hubs/search'],
        mediaBrowserPaths: ['/Items'],
      ),
      (
        name: 'title without a verifiable identity',
        ids: const ExternalIds(),
        titles: const ['Night on the Galactic Railroad'],
        plexGuid: null,
        succeeded: <String>{},
        plexPaths: <String>[],
        mediaBrowserPaths: <String>[],
      ),
    ]) {
      test('${query.name} counts only executed backend lookups as successful misses', () async {
        final requests = <String, List<String>>{'plex': [], 'jellyfin': [], 'emby': []};
        final plex = testPlexClient(
          serverId: ServerId('plex'),
          handler: (request) async {
            requests['plex']!.add(request.url.path);
            return _json({
              'MediaContainer': {'Metadata': <Object>[], 'Hub': <Object>[]},
            });
          },
        );
        final jellyfin = testJellyfinClient(
          connection: testJellyfinConnection(machineId: 'jellyfin'),
          handler: (request) async {
            requests['jellyfin']!.add(request.url.path);
            return _json({'Items': <Object>[]});
          },
        );
        final emby = testEmbyClient(
          connection: testEmbyConnection(machineId: 'emby'),
          handler: (request) async {
            requests['emby']!.add(request.url.path);
            return _json({'Items': <Object>[]});
          },
        );
        for (final client in <MediaServerClient>[plex, jellyfin, emby]) {
          manager.debugRegisterClientForTesting(client);
        }

        final result = await service.findByExternalIdsAcrossServers(
          query.ids,
          kind: MediaKind.movie,
          serverIds: {'plex', 'jellyfin', 'emby'},
          titles: query.titles,
          plexGuid: query.plexGuid,
        );

        expect(result.items, isEmpty);
        expect(result.succeededServerIds, query.succeeded);
        expect(result.unqueriedServerIds, {'plex', 'jellyfin', 'emby'}.difference(query.succeeded));
        expect(result.failedServerIds, isEmpty);
        expect(result.cancelledServerIds, isEmpty);
        expect(requests['plex'], query.plexPaths);
        expect(requests['jellyfin'], query.mediaBrowserPaths);
        expect(requests['emby'], query.mediaBrowserPaths);
      });
    }

    test('unsupported media kinds are unqueried, not successful empty answers', () async {
      Future<http.Response> unexpected(http.Request request) async => fail('Unexpected lookup: ${request.url}');
      final clients = <MediaServerClient>[
        testPlexClient(serverId: ServerId('plex'), handler: unexpected),
        testJellyfinClient(
          connection: testJellyfinConnection(machineId: 'jellyfin'),
          handler: unexpected,
        ),
        testEmbyClient(
          connection: testEmbyConnection(machineId: 'emby'),
          handler: unexpected,
        ),
      ];
      for (final client in clients) {
        manager.debugRegisterClientForTesting(client);
      }
      final result = await service.findByExternalIdsAcrossServers(
        const ExternalIds(tmdb: 42),
        kind: MediaKind.episode,
        titles: const ['Pilot'],
        serverIds: {'plex', 'jellyfin', 'emby'},
      );
      expect(result.items, isEmpty);
      expect(result.succeededServerIds, isEmpty);
      expect(result.unqueriedServerIds, {'plex', 'jellyfin', 'emby'});
      expect(result.failedServerIds, isEmpty);
      expect(result.cancelledServerIds, isEmpty);
    });

    test('cancellation, HTTP failure and unavailable clients remain distinct from successful misses', () async {
      manager.debugRegisterClientForTesting(
        testPlexClient(serverId: ServerId('cancelled'), handler: (_) async => throw http.RequestAbortedException()),
      );
      manager.debugRegisterClientForTesting(
        testJellyfinClient(
          connection: testJellyfinConnection(machineId: 'failed'),
          handler: (_) async => http.Response('Unauthorized', 401),
        ),
      );
      manager.debugRegisterClientForTesting(
        testEmbyClient(
          connection: testEmbyConnection(machineId: 'miss'),
          handler: (_) async => _json({'Items': <Object>[]}),
        ),
      );

      final result = await service.findByExternalIdsAcrossServers(
        const ExternalIds(tmdb: 34523),
        kind: MediaKind.movie,
        titles: const ['Night on the Galactic Railroad'],
        serverIds: {'cancelled', 'failed', 'miss', 'clientless'},
      );

      expect(result.items, isEmpty);
      expect(result.succeededServerIds, {'miss'});
      expect(result.failedServerIds, {'failed'});
      expect(result.cancelledServerIds, {'cancelled'});
      expect(result.unqueriedServerIds, {'clientless'});
    });
  });

  group('DataAggregationService cross-server aggregation', () {
    test('getMediaLibrariesFromAllServers returns empty when no clients connected', () async {
      final result = await service.getMediaLibrariesFromAllServers();
      expect(result.libraries, isEmpty);
      expect(result.succeededServerIds, isEmpty);
    });
    test('per-library hub fan-out refills a free slot instead of waiting for the batch', () async {
      // Old shape: batches of three separated by `Future.wait`, so the 4th
      // library could not start until ALL of the first three had answered and
      // one slow row stalled every row queued behind it (#1784). A sliding
      // window keeps the same peak concurrency with no head-of-line blocking.
      final client = _GatedHubsClient([
        for (var i = 1; i <= 4; i++)
          MediaLibrary(
            id: 'lib-$i',
            backend: MediaBackend.jellyfin,
            title: 'Library $i',
            kind: MediaKind.movie,
            serverId: ServerId('server-1'),
          ),
      ]);
      manager.debugRegisterClientForTesting(client);

      final pending = service.getHubsFromAllServers(useGlobalHubs: false, includePlaybackHubs: false);
      await pumpEventQueue();

      expect(client.started, ['lib-1', 'lib-2', 'lib-3'], reason: 'concurrency stays at 3');

      // Free exactly one slot. The 4th library must take it immediately, while
      // its two batch-mates are still in flight.
      client.complete('lib-1');
      await pumpEventQueue();

      expect(client.started, ['lib-1', 'lib-2', 'lib-3', 'lib-4']);

      // Finish out of order — hub order must still follow library order.
      client.complete('lib-4');
      client.complete('lib-3');
      client.complete('lib-2');

      final result = await pending;
      expect(result.hubs.map((hub) => hub.libraryId), ['lib-1', 'lib-2', 'lib-3', 'lib-4']);
    });

    test('searchAcrossServers and getOnDeckFromAllServers return empty when no clients', () async {
      final search = await service.searchAcrossServers('hello');
      expect(search.items, isEmpty);
      expect(search.candidates, isEmpty);
      expect(search.succeededServerIds, isEmpty);
      expect(search.cancelledServerIds, isEmpty);
      expect(search.failedServerIds, isEmpty);
      final onDeck = await service.getOnDeckFromAllServers();
      expect(onDeck.items, isEmpty);
      expect(onDeck.succeededServerIds, isEmpty);
    });

    test('classifies cancelled per-server failures apart from settled ones', () async {
      // A cancelled fetch (our own client torn down mid-request) says nothing
      // about the server's content; consumers use cancelledServerIds to keep
      // a disrupted pass from being committed as authoritative. A settled
      // failure (server down) lands in neither set.
      manager.debugRegisterClientForTesting(
        _LibrariesClient(
          ServerId('ok'),
          libraries: [MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: ServerId('ok'))],
        ),
      );
      manager.debugRegisterClientForTesting(
        _LibrariesClient(
          ServerId('torn-down'),
          error: MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'HTTP client is closing'),
        ),
      );
      manager.debugRegisterClientForTesting(
        _LibrariesClient(
          ServerId('down'),
          error: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused'),
        ),
      );

      final result = await service.getMediaLibrariesFromAllServers();

      expect(result.libraries.map((l) => l.title), ['Movies']);
      expect(result.succeededServerIds, {'ok'});
      expect(result.cancelledServerIds, {'torn-down'});
    });

    test('search classifies successful, cancelled, and failed servers independently', () async {
      final item = testMediaItem(
        id: 'show-1',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        title: 'Target',
        serverId: 'ok',
      );
      manager.debugRegisterClientForTesting(_LibrariesClient(ServerId('ok'), searchResults: [item]));
      manager.debugRegisterClientForTesting(
        _LibrariesClient(
          ServerId('cancelled'),
          searchError: MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'superseded search'),
        ),
      );
      manager.debugRegisterClientForTesting(
        _LibrariesClient(
          ServerId('failed'),
          searchError: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused'),
        ),
      );

      final result = await service.searchAcrossServers('Target');

      expect(result.items.map((item) => item.id), ['show-1']);
      expect(result.succeededServerIds, {'ok'});
      expect(result.cancelledServerIds, {'cancelled'});
      expect(result.failedServerIds, {'failed'});
    });

    test('searchAcrossServers drops hidden-library results and keeps unattributed ones', () async {
      final visible = testMediaItem(
        id: 'visible-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target',
        serverId: 'plex',
        libraryId: '1',
      );
      final hidden = testMediaItem(
        id: 'hidden-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target',
        serverId: 'plex',
        libraryId: '2',
      );
      // Plex search asks for external media, and shared rows carry no local
      // section. The user cannot have hidden a library that isn't theirs, so
      // an unattributed row must survive the filter.
      final unattributed = testMediaItem(
        id: 'shared-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target',
        serverId: 'plex',
      );
      manager.debugRegisterClientForTesting(
        _LibrariesClient(ServerId('plex'), searchResults: [visible, hidden, unattributed]),
      );

      final result = await service.searchAcrossServers('Target', hiddenLibraryKeys: {'plex:2'});

      expect(result.items.map((item) => item.id), unorderedEquals(['visible-1', 'shared-1']));
      expect(result.succeededServerIds, {'plex'});
    });

    test('hidden-library results are dropped before the ranking limit is spent', () async {
      // The hidden row is the exact-title match, so it outranks the visible
      // one. Filtering after ranking would let it consume the single slot and
      // return nothing at all.
      final hidden = testMediaItem(
        id: 'hidden-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target',
        serverId: 'plex',
        libraryId: '2',
      );
      final visible = testMediaItem(
        id: 'visible-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target Sequel',
        serverId: 'plex',
        libraryId: '1',
      );
      manager.debugRegisterClientForTesting(_LibrariesClient(ServerId('plex'), searchResults: [hidden, visible]));

      final result = await service.searchAcrossServers('Target', limit: 1, hiddenLibraryKeys: {'plex:2'});

      expect(result.items.map((item) => item.id), ['visible-1']);
    });

    test('candidates keeps rows the ranked limit dropped, minus hidden ones', () async {
      // The search screen's kind filter re-ranks `candidates`, so a kind
      // crowded out of the trimmed `items` must still be present there — but
      // a hidden library's rows must not be.
      final movie = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Target',
        serverId: 'plex',
        libraryId: '1',
      );
      final episode = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Target Sequel',
        serverId: 'plex',
        libraryId: '1',
      );
      final hidden = testMediaItem(
        id: 'hidden-1',
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: 'Target',
        serverId: 'plex',
        libraryId: '2',
      );
      manager.debugRegisterClientForTesting(
        _LibrariesClient(ServerId('plex'), searchResults: [movie, episode, hidden]),
      );

      final result = await service.searchAcrossServers('Target', limit: 1, hiddenLibraryKeys: {'plex:2'});

      expect(result.items.map((item) => item.id), ['movie-1']);
      expect(result.candidates.map((item) => item.id), unorderedEquals(['movie-1', 'episode-1']));
    });

    test('each server is told only about its own hidden libraries', () async {
      // Global keys are cross-server; a backend that scopes its search needs
      // the bare library ids it actually owns, and none of its neighbour's.
      final alpha = _LibrariesClient(ServerId('alpha'));
      final beta = _LibrariesClient(ServerId('beta'));
      manager.debugRegisterClientForTesting(alpha);
      manager.debugRegisterClientForTesting(beta);

      await service.searchAcrossServers('Target', hiddenLibraryKeys: {'alpha:1', 'alpha:9', 'beta:1'});

      expect(alpha.lastExcludedLibraryIds, {'1', '9'});
      expect(beta.lastExcludedLibraryIds, {'1'});
    });

    test('no hidden libraries passes an empty exclusion set', () async {
      final client = _LibrariesClient(ServerId('alpha'));
      manager.debugRegisterClientForTesting(client);

      await service.searchAcrossServers('Target');

      expect(client.lastExcludedLibraryIds, isEmpty);
    });

    test('searchAcrossServers overfetches and ranks before trimming across backends', () async {
      final plexRequests = <Uri>[];
      final jellyfinRequests = <Uri>[];

      final plexClient = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          plexRequests.add(req.url);
          if (req.url.path == '/library/search') {
            return _json({
              'MediaContainer': {
                'SearchResult': [
                  {
                    'score': 100,
                    'Metadata': {'ratingKey': 'plex-movie', 'type': 'movie', 'title': 'Spider Man Returns'},
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(plexClient.close);
      manager.debugRegisterClientForTesting(plexClient);

      final jellyfinClient = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          jellyfinRequests.add(req.url);
          if (req.url.path == '/Users/user-1/Views') {
            return _json({
              'Items': [
                {'Id': 'shows', 'Name': 'Shows', 'CollectionType': 'tvshows'},
              ],
            });
          }
          if (req.url.path == '/Items') {
            return _json({
              'Items': [
                {'Id': 'jf-show', 'Type': 'Series', 'Name': 'Spider‑Man'},
              ],
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(jellyfinClient.close);
      manager.debugRegisterJellyfinClientForTesting(jellyfinClient);

      final results = await service.searchAcrossServers('Spider Man', limit: 1);

      expect(results.items.map((item) => item.id), ['jf-show']);
      // The winning hit carries the library it was found in — a scoped
      // request per visible library is the only way a Jellyfin search row
      // ever learns its library (#1970).
      expect(results.items.single.libraryId, 'shows');
      expect(results.items.single.libraryTitle, 'Shows');
      expect(plexRequests.single.queryParameters['query'], 'Spider Man');
      expect(plexRequests.single.queryParameters['limit'], '100');
      expect(plexRequests.single.queryParameters['searchTypes'], 'movies,tv,music,otherVideos');
      // Jellyfin search is always library-scoped: each visible library gets
      // its own /Items request with the full candidate budget, and a video
      // library issues no /Artists leg.
      final jfItemsRequest = jellyfinRequests.singleWhere((url) => url.path == '/Items');
      expect(jfItemsRequest.queryParameters['Limit'], '100');
      expect(jfItemsRequest.queryParameters['SearchTerm'], 'Spider Man');
      expect(jfItemsRequest.queryParameters['ParentId'], 'shows');
      expect(jellyfinRequests.where((url) => url.path == '/Artists'), isEmpty);
    });

    test('getOnDeckFromAllServers forwards preview limit to clients', () async {
      final captured = <Uri>[];

      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 1,
                    'Metadata': [
                      {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'Movie 1'},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getOnDeckFromAllServers(limit: 21);

      expect(result.items.map((item) => item.id), ['movie-1']);
      expect(result.succeededServerIds, {'plex-1'});
      expect(captured.single.path, '/hubs');
      expect(captured.single.queryParameters['count'], '21');
    });

    test('getOnDeckFromAllServers filters hidden Plex continue-watching libraries', () async {
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 2,
                    'Metadata': [
                      {
                        'ratingKey': 'movie-visible',
                        'type': 'movie',
                        'title': 'Visible Movie',
                        'lastViewedAt': 100,
                        'librarySectionID': 1,
                      },
                      {
                        'ratingKey': 'movie-hidden',
                        'type': 'movie',
                        'title': 'Hidden Movie',
                        'lastViewedAt': 200,
                        'librarySectionID': 2,
                      },
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getOnDeckFromAllServers(limit: 10, hiddenLibraryKeys: {'plex-1:2'});

      expect(result.items.map((item) => item.id), ['movie-visible']);
      expect(result.succeededServerIds, {'plex-1'});
    });

    test('getOnDeckFromAllServers hides duplicate show entries by stable show ids', () async {
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 2,
                    'Metadata': [
                      {
                        'ratingKey': 'old-episode',
                        'type': 'episode',
                        'title': 'Episode 1',
                        'grandparentRatingKey': 'old-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'plex://episode/shared-episode-1',
                        'lastViewedAt': 100,
                        'librarySectionID': 1,
                      },
                      {
                        'ratingKey': 'new-episode',
                        'type': 'episode',
                        'title': 'Episode 2',
                        'grandparentRatingKey': 'new-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'plex://episode/shared-episode-2',
                        'lastViewedAt': 200,
                        'librarySectionID': 2,
                      },
                    ],
                  },
                ],
              },
            });
          }
          if (req.url.path == '/library/metadata/old-show' || req.url.path == '/library/metadata/new-show') {
            return _json({
              'MediaContainer': {
                'Metadata': [
                  {
                    'ratingKey': req.url.pathSegments.last,
                    'type': 'show',
                    'title': 'Shared Show',
                    'Guid': [
                      {'id': 'tvdb://12345'},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getOnDeckFromAllServers(limit: 10);

      expect(result.items.map((item) => item.id), ['new-episode']);
      expect(result.succeededServerIds, {'plex-1'});
    });

    test('getOnDeckFromAllServers prefers the locally last-played duplicate sibling', () async {
      // Two libraries carry the same show (1080p + 4K, matched by tvdb id);
      // the server syncs watch state so lastViewedAt favours neither
      // reliably. The locally recorded play must decide the surviving card —
      // and it must keep the winner in the group's original shelf slot,
      // ahead of the unrelated movie sorted between the two episodes (#1492).
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 3,
                    'Metadata': [
                      {
                        'ratingKey': 'hd-episode',
                        'type': 'episode',
                        'title': 'Episode 1',
                        'grandparentRatingKey': 'hd-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'plex://episode/shared-episode-hd',
                        'lastViewedAt': 200,
                        'librarySectionID': 1,
                      },
                      {'ratingKey': 'movie-between', 'type': 'movie', 'title': 'Unrelated Movie', 'lastViewedAt': 150},
                      {
                        'ratingKey': 'uhd-episode',
                        'type': 'episode',
                        'title': 'Episode 1',
                        'grandparentRatingKey': 'uhd-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'plex://episode/shared-episode-uhd',
                        'lastViewedAt': 100,
                        'librarySectionID': 2,
                      },
                    ],
                  },
                ],
              },
            });
          }
          if (req.url.path == '/library/metadata/hd-show' || req.url.path == '/library/metadata/uhd-show') {
            return _json({
              'MediaContainer': {
                'Metadata': [
                  {
                    'ratingKey': req.url.pathSegments.last,
                    'type': 'show',
                    'title': 'Shared Show',
                    'Guid': [
                      {'id': 'tvdb://12345'},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      // The user last played something in the 4K library's show tree.
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.localLastPlayedAt, {'plex-1:uhd-show': 999999});

      final result = await service.getOnDeckFromAllServers(limit: 10);

      // uhd-episode wins the duplicate group and takes the group's slot
      // (before the movie); without local history hd-episode (newest
      // lastViewedAt) would have survived.
      expect(result.items.map((item) => item.id), ['uhd-episode', 'movie-between']);
    });

    test('getOnDeckFromAllServers prefers a duplicate recorded by item key', () async {
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 2,
                    'Metadata': [
                      {
                        'ratingKey': 'movie-hd',
                        'type': 'movie',
                        'title': 'Shared Movie',
                        'guid': 'plex://movie/shared-movie',
                        'lastViewedAt': 200,
                        'librarySectionID': 1,
                      },
                      {
                        'ratingKey': 'movie-uhd',
                        'type': 'movie',
                        'title': 'Shared Movie',
                        'guid': 'plex://movie/shared-movie',
                        'lastViewedAt': 100,
                        'librarySectionID': 2,
                      },
                    ],
                  },
                ],
              },
            });
          }
          if (req.url.path == '/library/metadata/movie-hd' || req.url.path == '/library/metadata/movie-uhd') {
            return _json({
              'MediaContainer': {
                'Metadata': [
                  {
                    'ratingKey': req.url.pathSegments.last,
                    'type': 'movie',
                    'title': 'Shared Movie',
                    'Guid': [
                      {'id': 'tmdb://777'},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.localLastPlayedAt, {'plex-1:movie-uhd': 999999});

      final result = await service.getOnDeckFromAllServers(limit: 10);

      expect(result.items.map((item) => item.id), ['movie-uhd']);
    });

    test('getOnDeckFromAllServers keeps duplicate titles without stable ids', () async {
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        httpClient: MockClient((req) async {
          if (req.url.path == '/hubs') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/continueWatching',
                    'title': 'Continue Watching',
                    'type': 'mixed',
                    'hubIdentifier': 'home.continue',
                    'size': 2,
                    'Metadata': [
                      {
                        'ratingKey': 'old-unmatched',
                        'type': 'episode',
                        'title': 'Episode 1',
                        'grandparentRatingKey': 'old-unmatched-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'com.plexapp.agents.none://old-unmatched',
                        'lastViewedAt': 100,
                      },
                      {
                        'ratingKey': 'new-unmatched',
                        'type': 'episode',
                        'title': 'Episode 2',
                        'grandparentRatingKey': 'new-unmatched-show',
                        'grandparentTitle': 'Shared Show',
                        'guid': 'com.plexapp.agents.none://new-unmatched',
                        'lastViewedAt': 200,
                      },
                    ],
                  },
                ],
              },
            });
          }
          if (req.url.path == '/library/metadata/old-unmatched-show' ||
              req.url.path == '/library/metadata/new-unmatched-show') {
            return _json({
              'MediaContainer': {
                'Metadata': [
                  {'ratingKey': req.url.pathSegments.last, 'type': 'show', 'title': 'Shared Show'},
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getOnDeckFromAllServers(limit: 10);

      expect(result.items.map((item) => item.id), ['new-unmatched', 'old-unmatched']);
      expect(result.succeededServerIds, {'plex-1'});
    });

    test('per-library hubs skip playback rows and fetch in bounded batches', () async {
      final captured = <Uri>[];
      var activeLatest = 0;
      var maxActiveLatest = 0;

      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/Users/user-1/Views') {
            return _json({
              'Items': [
                {'Id': 'lib-1', 'Name': 'Lib 1', 'CollectionType': 'movies'},
                {'Id': 'lib-2', 'Name': 'Lib 2', 'CollectionType': 'movies'},
                {'Id': 'lib-3', 'Name': 'Lib 3', 'CollectionType': 'tvshows'},
                {'Id': 'lib-4', 'Name': 'Lib 4', 'CollectionType': 'tvshows'},
              ],
            });
          }
          if (req.url.path == '/Users/user-1/Items/Latest') {
            activeLatest++;
            if (activeLatest > maxActiveLatest) maxActiveLatest = activeLatest;
            try {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              final parentId = req.url.queryParameters['ParentId']!;
              return _json({
                'Items': [
                  {'Id': 'item-$parentId', 'Type': 'Movie', 'Name': 'Latest $parentId'},
                ],
              });
            } finally {
              activeLatest--;
            }
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterJellyfinClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: false, includePlaybackHubs: false);
      final hubs = result.hubs;

      expect(result.succeededServerIds, {'srv-1'});
      expect(hubs.map((h) => h.identifier), [
        'library.lib-1.recent',
        'library.lib-2.recent',
        'library.lib-3.recent',
        'library.lib-4.recent',
      ]);
      expect(hubs.map((h) => h.items.single.id), ['item-lib-1', 'item-lib-2', 'item-lib-3', 'item-lib-4']);
      expect(maxActiveLatest, lessThanOrEqualTo(3));
      expect(captured.where((uri) => uri.path == '/UserItems/Resume' || uri.path == '/Shows/NextUp'), isEmpty);
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['ParentId']),
        ['lib-1', 'lib-2', 'lib-3', 'lib-4'],
      );
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['Limit']),
        everyElement(defaultHubPreviewLimit.toString()),
      );
    });

    test('global home layout falls back to per-library hubs for Jellyfin', () async {
      final captured = <Uri>[];

      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/Users/user-1/Views') {
            return _json({
              'Items': [
                {'Id': 'movies', 'Name': 'Movies', 'CollectionType': 'movies'},
                {'Id': 'shows', 'Name': 'Shows', 'CollectionType': 'tvshows'},
              ],
            });
          }
          if (req.url.path == '/Users/user-1/Items/Latest') {
            final parentId = req.url.queryParameters['ParentId'];
            return switch (parentId) {
              'movies' => _json({
                'Items': [
                  {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Latest Movie'},
                ],
              }),
              'shows' => _json({
                'Items': [
                  {'Id': 'show-1', 'Type': 'Series', 'Name': 'Latest Show'},
                ],
              }),
              _ => http.Response('mixed latest should not be requested', 500),
            };
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterJellyfinClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: true, includePlaybackHubs: false);
      final hubs = result.hubs;

      expect(result.succeededServerIds, {'srv-1'});
      expect(hubs.map((h) => h.identifier), ['library.movies.recent', 'library.shows.recent']);
      expect(hubs.map((h) => h.items.single.id), ['movie-1', 'show-1']);
      expect(captured.where((uri) => uri.path == '/Users/user-1/Views'), hasLength(1));
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['ParentId']),
        ['movies', 'shows'],
      );
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['Limit']),
        everyElement(defaultHubPreviewLimit.toString()),
      );
    });

    test('per-library home rows include clip and music libraries and skip photo (#1476)', () async {
      final captured = <Uri>[];

      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/Users/user-1/Views') {
            return _json({
              'Items': [
                {'Id': 'movies', 'Name': 'Movies', 'CollectionType': 'movies'},
                {'Id': 'mv', 'Name': 'Music Videos', 'CollectionType': 'musicvideos'},
                {'Id': 'home-vids', 'Name': 'Home Videos', 'CollectionType': 'homevideos'},
                {'Id': 'music', 'Name': 'Music', 'CollectionType': 'music'},
                {'Id': 'photos', 'Name': 'Photos', 'CollectionType': 'photos'},
              ],
            });
          }
          if (req.url.path == '/Users/user-1/Items/Latest') {
            final parentId = req.url.queryParameters['ParentId'];
            return switch (parentId) {
              'movies' => _json({
                'Items': [
                  {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Latest Movie'},
                ],
              }),
              'mv' => _json({
                'Items': [
                  {'Id': 'mv-1', 'Type': 'MusicVideo', 'Name': 'Latest Music Video'},
                ],
              }),
              'home-vids' => _json({
                'Items': [
                  {'Id': 'vid-1', 'Type': 'Video', 'Name': 'Latest Home Video'},
                ],
              }),
              'music' => _json({
                'Items': [
                  {'Id': 'album-1', 'Type': 'MusicAlbum', 'Name': 'Latest Album'},
                ],
              }),
              _ => http.Response('latest should not be requested for $parentId', 500),
            };
          }
          // Music library's played-track rows — empty so only the Latest
          // Albums hub survives.
          if (req.url.path == '/Items' && req.url.queryParameters['Filters'] == 'IsPlayed') {
            return _json({'Items': const <Object>[]});
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterJellyfinClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: true, includePlaybackHubs: false);
      final hubs = result.hubs;

      expect(result.succeededServerIds, {'srv-1'});
      expect(hubs.map((h) => h.identifier), [
        'library.movies.recent',
        'library.mv.recent',
        'library.home-vids.recent',
        'library.music.latestalbums',
      ]);
      expect(hubs[1].items.single.kind, MediaKind.clip);
      expect(hubs[3].items.single.kind, MediaKind.album);
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['ParentId']),
        ['movies', 'mv', 'home-vids', 'music'],
      );
      expect(
        captured.where((uri) => uri.path == '/Items' && uri.queryParameters['Filters'] == 'IsPlayed'),
        isEmpty,
        reason: 'the home screen excludes playback-derived music rows',
      );
      // Music Latest returns album FOLDER dtos — count/user-data fields would
      // each cost a recursive per-album COUNT query (#1552).
      final musicLatest = captured.singleWhere(
        (uri) => uri.path == '/Users/user-1/Items/Latest' && uri.queryParameters['ParentId'] == 'music',
      );
      expect(musicLatest.queryParameters['Fields'], 'PremiereDate,OriginalTitle,SortName,DateCreated');
      expect(musicLatest.queryParameters['EnableUserData'], 'false');
      // Video Latest rows carry the same risk: `/Items/Latest` groups a TV
      // library by series, so the rows are Series FOLDER dtos and the count
      // fields cost a per-row COUNT each (#1784). Watch state survives via
      // UserData.UnplayedItemCount, so the hub row set asks for neither.
      final movieLatest = captured.singleWhere(
        (uri) => uri.path == '/Users/user-1/Items/Latest' && uri.queryParameters['ParentId'] == 'movies',
      );
      expect(movieLatest.queryParameters['Fields'], 'Overview,DateCreated');
      expect(movieLatest.queryParameters.containsKey('EnableUserData'), isFalse);
    });

    test('music library recommendations retain recently and most-played rows', () async {
      final captured = <Uri>[];
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/Users/user-1/Items/Latest') {
            return _json([
              {'Id': 'album-1', 'Type': 'MusicAlbum', 'Name': 'Latest Album'},
            ]);
          }
          if (req.url.path == '/Items' && req.url.queryParameters['Filters'] == 'IsPlayed') {
            final sortBy = req.url.queryParameters['SortBy'];
            return _json({
              'Items': [
                {
                  'Id': sortBy == 'DatePlayed' ? 'recent-track' : 'most-played-track',
                  'Type': 'Audio',
                  'Name': sortBy == 'DatePlayed' ? 'Recent Track' : 'Most Played Track',
                },
              ],
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);

      final hubs = await client.fetchLibraryHubs(
        'music',
        libraryName: 'Music',
        libraryKind: MediaKind.artist,
        includePlaybackHubs: true,
      );

      expect(hubs.map((hub) => hub.identifier), [
        'library.music.latestalbums',
        'library.music.recentlyplayed',
        'library.music.mostplayed',
      ]);
      final playedQueries = captured
          .where((uri) => uri.path == '/Items' && uri.queryParameters['Filters'] == 'IsPlayed')
          .toList();
      expect(playedQueries.map((uri) => uri.queryParameters['SortBy']), ['DatePlayed', 'PlayCount']);
      // Audio LEAF dtos: UserData stays (cheap, drives play state); the
      // folder count fields and Overview are dropped.
      expect(playedQueries.map((uri) => uri.queryParameters['Fields']).toSet(), {
        'UserData,PremiereDate,OriginalTitle,SortName',
      });
    });

    test('Plex home layout keeps promoted hubs instead of splitting by preview libraries', () async {
      final captured = <Uri>[];

      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        promotedHubKey: '/hubs/promoted',
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/library/sections') {
            return _json({
              'MediaContainer': {
                'Directory': [
                  {'key': '2', 'type': 'show', 'title': 'TV Shows'},
                ],
              },
            });
          }
          if (req.url.path == '/hubs/promoted') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/recentlyAdded?type=2',
                    'title': 'Recently Added TV',
                    'type': 'mixed',
                    'hubIdentifier': 'home.television.recent',
                    'size': 7,
                    'more': true,
                    'Metadata': [
                      for (var i = 1; i <= 7; i++)
                        {
                          'ratingKey': 'show-$i',
                          'type': 'show',
                          'title': 'Show $i',
                          'librarySectionID': i,
                          'librarySectionTitle': 'Library $i',
                        },
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: true, includePlaybackHubs: false);
      final hubs = result.hubs;

      expect(result.succeededServerIds, {'plex-1'});
      expect(hubs, hasLength(1));
      expect(hubs.single.title, 'Recently Added TV');
      expect(hubs.single.identifier, 'home.television.recent');
      expect(hubs.single.libraryId, isNull);
      expect(hubs.single.items, hasLength(7));
      // Library prefetch (music detection) + the promoted hubs — no
      // per-library hub calls without a music section.
      expect(captured.map((uri) => uri.path), ['/library/sections', '/hubs/promoted']);
      expect(
        captured.singleWhere((uri) => uri.path == '/hubs/promoted').queryParameters['count'],
        defaultHubPreviewLimit.toString(),
      );
    });

    test('Plex home layout appends music library hubs the promoted endpoint excludes', () async {
      final captured = <Uri>[];

      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        promotedHubKey: '/hubs/promoted',
        httpClient: MockClient((req) async {
          captured.add(req.url);
          if (req.url.path == '/library/sections') {
            return _json({
              'MediaContainer': {
                'Directory': [
                  {'key': '1', 'type': 'movie', 'title': 'Movies'},
                  {'key': '9', 'type': 'artist', 'title': 'Music'},
                ],
              },
            });
          }
          if (req.url.path == '/hubs/promoted') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/hubs/home/recentlyAdded?type=1',
                    'title': 'Recently Added Movies',
                    'type': 'movie',
                    'hubIdentifier': 'home.movies.recent',
                    'size': 1,
                    'Metadata': [
                      {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'Movie', 'librarySectionID': 1},
                    ],
                  },
                ],
              },
            });
          }
          if (req.url.path == '/hubs/sections/9') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/library/sections/9/recentlyAdded',
                    'title': 'Recently Added Music',
                    'type': 'album',
                    'hubIdentifier': 'music.recent',
                    'size': 1,
                    'Metadata': [
                      {'ratingKey': 'album-1', 'type': 'album', 'title': 'Album', 'librarySectionID': 9},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: true, includePlaybackHubs: false);
      final hubs = result.hubs;

      expect(result.succeededServerIds, {'plex-1'});
      expect(hubs.map((h) => h.identifier), ['home.movies.recent', 'music.recent']);
      expect(hubs[1].items.single.kind, MediaKind.album);
      // Only the music section gets a per-library hub call — the movie
      // library's rows already came from the promoted endpoint.
      expect(captured.where((uri) => uri.path.startsWith('/hubs/sections/')).map((uri) => uri.path), [
        '/hubs/sections/9',
      ]);
    });

    test('Plex server with a failed global leg is not marked succeeded by the optional music append', () async {
      // /hubs/promoted failures are recorded in diagnostics and returned as []
      // (never thrown), so only the success accounting separates "promoted
      // hubs are gone" from "promoted hubs are empty". Counting the optional
      // music leg as server success let DiscoverProvider replace every cached
      // movie/TV home row with the lone music row.
      final client = testPlexClient(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: ServerId('plex-1'),
        serverName: 'Plex',
        promotedHubKey: '/hubs/promoted',
        httpClient: MockClient((req) async {
          if (req.url.path == '/library/sections') {
            return _json({
              'MediaContainer': {
                'Directory': [
                  {'key': '1', 'type': 'movie', 'title': 'Movies'},
                  {'key': '9', 'type': 'artist', 'title': 'Music'},
                ],
              },
            });
          }
          if (req.url.path == '/hubs/promoted') {
            return http.Response('server error', 500);
          }
          if (req.url.path == '/hubs/sections/9') {
            return _json({
              'MediaContainer': {
                'Hub': [
                  {
                    'key': '/library/sections/9/recentlyAdded',
                    'title': 'Recently Added Music',
                    'type': 'album',
                    'hubIdentifier': 'music.recent',
                    'size': 1,
                    'Metadata': [
                      {'ratingKey': 'album-1', 'type': 'album', 'title': 'Album', 'librarySectionID': 9},
                    ],
                  },
                ],
              },
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(client.close);
      manager.debugRegisterClientForTesting(client);

      final result = await service.getHubsFromAllServers(useGlobalHubs: true, includePlaybackHubs: false);

      expect(result.succeededServerIds, isEmpty, reason: 'the optional music leg must not vouch for the server');
      expect(result.failedServerIds, {'plex-1'});
      // The music rows that did arrive are still delivered.
      expect(result.hubs.map((h) => h.identifier), ['music.recent']);
    });
  });
}
