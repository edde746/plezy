import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

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
      expect(plexRequests.single.queryParameters['searchTypes'], 'movies,tv');
      expect(jellyfinRequests.single.queryParameters['Limit'], '100');
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
      expect(captured.map((uri) => uri.path), ['/hubs/promoted']);
      expect(captured.single.queryParameters['count'], defaultHubPreviewLimit.toString());
    });
  });
}
