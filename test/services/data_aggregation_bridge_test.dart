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
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _conn() => JellyfinConnection(
  id: 'srv-1/user-1',
  baseUrl: 'https://jf.example.com',
  serverName: 'Home',
  serverMachineId: 'srv-1',
  userId: 'user-1',
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

/// Minimal client whose `fetchLibraries` either returns canned libraries or
/// throws [error] — enough surface to exercise the fan-out's per-server
/// failure classification without a real backend.
class _LibrariesClient implements MediaServerClient {
  _LibrariesClient(this.serverId, {this.error, this.libraries = const []});

  @override
  final ServerId serverId;

  @override
  final String serverName = 'Server';

  final Object? error;
  final List<MediaLibrary> libraries;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    if (error != null) throw error!;
    return libraries;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Smoke tests for the surviving cross-server aggregation surface on
/// [DataAggregationService]. Single-server passthroughs were removed in
/// favour of `context.tryGetMediaClientForServer(...).<method>()`; what's
/// left here is the multi-client fan-out, which is testable without a
/// real backend by simply asserting the empty-state behaviour.
void main() {
  late AppDatabase db;
  late MultiServerManager manager;
  late DataAggregationService service;

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    manager = MultiServerManager();
    service = DataAggregationService(manager);
  });

  tearDown(() async {
    manager.dispose();
    await db.close();
  });

  group('DataAggregationService cross-server aggregation', () {
    test('getMediaLibrariesFromAllServers returns empty when no clients connected', () async {
      final result = await service.getMediaLibrariesFromAllServers();
      expect(result.libraries, isEmpty);
      expect(result.succeededServerIds, isEmpty);
    });

    test('searchAcrossServers and getOnDeckFromAllServers return empty when no clients', () async {
      expect(await service.searchAcrossServers('hello'), isEmpty);
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

    test('searchAcrossServers overfetches and ranks before trimming across backends', () async {
      final plexRequests = <Uri>[];
      final jellyfinRequests = <Uri>[];

      final plexClient = PlexClient.forTesting(
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
                    'Metadata': {'ratingKey': 'plex-movie', 'type': 'movie', 'title': 'The Boys in the Boat'},
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
          if (req.url.path == '/Items') {
            return _json({
              'Items': [
                {'Id': 'jf-show', 'Type': 'Series', 'Name': 'The Boys'},
              ],
            });
          }
          return http.Response('unexpected request', 500);
        }),
      );
      addTearDown(jellyfinClient.close);
      manager.debugRegisterJellyfinClientForTesting(jellyfinClient);

      final results = await service.searchAcrossServers('The Boys', limit: 1);

      expect(results.map((item) => item.id), ['jf-show']);
      expect(plexRequests.single.queryParameters['limit'], '100');
      expect(plexRequests.single.queryParameters['searchTypes'], 'movies,tv,music');
      // Jellyfin search fans out to /Items plus a best-effort /Artists call
      // (500 above → treated as empty).
      final jfItemsRequest = jellyfinRequests.singleWhere((url) => url.path == '/Items');
      expect(jfItemsRequest.queryParameters['Limit'], '100');
      final jfArtistsRequest = jellyfinRequests.singleWhere((url) => url.path == '/Artists');
      expect(jfArtistsRequest.queryParameters['searchTerm'], 'The Boys');
    });

    test('getOnDeckFromAllServers forwards preview limit to clients', () async {
      final captured = <Uri>[];

      final client = PlexClient.forTesting(
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
      final client = PlexClient.forTesting(
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
      final client = PlexClient.forTesting(
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
      final client = PlexClient.forTesting(
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
      final client = PlexClient.forTesting(
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
      final client = PlexClient.forTesting(
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
                  {'Id': 'item-$parentId', 'Type': 'Movie', 'Name': 'Latest $parentId', 'ParentLibraryId': parentId},
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
                  {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Latest Movie', 'ParentLibraryId': 'movies'},
                ],
              }),
              'shows' => _json({
                'Items': [
                  {'Id': 'show-1', 'Type': 'Series', 'Name': 'Latest Show', 'ParentLibraryId': 'shows'},
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
                  {'Id': 'movie-1', 'Type': 'Movie', 'Name': 'Latest Movie', 'ParentLibraryId': 'movies'},
                ],
              }),
              'mv' => _json({
                'Items': [
                  {'Id': 'mv-1', 'Type': 'MusicVideo', 'Name': 'Latest Music Video', 'ParentLibraryId': 'mv'},
                ],
              }),
              'home-vids' => _json({
                'Items': [
                  {'Id': 'vid-1', 'Type': 'Video', 'Name': 'Latest Home Video', 'ParentLibraryId': 'home-vids'},
                ],
              }),
              'music' => _json({
                'Items': [
                  {'Id': 'album-1', 'Type': 'MusicAlbum', 'Name': 'Latest Album', 'ParentLibraryId': 'music'},
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
        'library.music.recent',
      ]);
      expect(hubs[1].items.single.kind, MediaKind.clip);
      expect(hubs[3].items.single.kind, MediaKind.album);
      expect(
        captured.where((uri) => uri.path == '/Users/user-1/Items/Latest').map((uri) => uri.queryParameters['ParentId']),
        ['movies', 'mv', 'home-vids', 'music'],
      );
    });

    test('Plex home layout keeps promoted hubs instead of splitting by preview libraries', () async {
      final captured = <Uri>[];

      final client = PlexClient.forTesting(
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

      final client = PlexClient.forTesting(
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
  });
}
