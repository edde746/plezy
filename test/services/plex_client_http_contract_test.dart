import 'dart:convert';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  final publicServerId = ServerId('server-id');
  final defaultProfileScopeId = buildPlexProfileScopeId(serverId: publicServerId, profileId: 'test-profile');

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: publicServerId, profileScopeId: defaultProfileScopeId, handler: handler);

  group('Plex item lookup HTTP/cache contract', () {
    const jsonHeaders = {'content-type': 'application/json'};
    final apis = [(name: 'fetchItem', includeOnDeck: false), (name: 'fetchItemWithOnDeck', includeOnDeck: true)];

    String endpointFor(String id) => '/library/metadata/$id';

    Map<String, dynamic> itemResponse(String id, {String title = 'Cached item'}) => {
      'MediaContainer': {
        'librarySectionID': 7,
        'librarySectionTitle': 'Movies',
        'Metadata': [
          {'ratingKey': id, 'type': 'movie', 'title': title, 'summary': 'Cached summary'},
        ],
      },
    };

    http.Response jsonResponse(Object? body, int statusCode) =>
        http.Response(jsonEncode(body), statusCode, headers: jsonHeaders);

    Future<Map<String, dynamic>> seedItem(String id, {String title = 'Cached item'}) async {
      final response = itemResponse(id, title: title);
      await PlexApiCache.instance.put(defaultProfileScopeId.cacheServerId, endpointFor(id), response);
      return response;
    }

    Future<({MediaItem? item, MediaItem? onDeckEpisode})> lookup(
      PlexClient client,
      String id, {
      required bool includeOnDeck,
    }) async {
      if (includeOnDeck) {
        final result = await client.fetchItemWithOnDeck(id);
        return result;
      }
      return (item: await client.fetchItem(id), onDeckEpisode: null);
    }

    for (final api in apis) {
      for (final cacheState in [(name: 'uncached', seed: false), (name: 'cached', seed: true)]) {
        test('${api.name} maps a ${cacheState.name} HTTP 404 to no item', () async {
          final id = '${api.name}-${cacheState.name}-404';
          Map<String, dynamic>? seededResponse;
          if (cacheState.seed) {
            seededResponse = await seedItem(id);
          }
          var requestCount = 0;
          final client = makeClient((_) async {
            requestCount++;
            return jsonResponse({
              'MediaContainer': {
                'Metadata': [
                  {'ratingKey': 'must-not-parse', 'type': 'movie', 'title': 'Must Not Parse'},
                ],
              },
            }, 404);
          });
          addTearDown(client.close);

          final result = await lookup(client, id, includeOnDeck: api.includeOnDeck);

          expect(result.item, isNull);
          expect(result.onDeckEpisode, isNull);
          expect(requestCount, 1);
          final cached = await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpointFor(id));
          if (cacheState.seed) {
            expect(cached, seededResponse);
          } else {
            expect(cached, isNull);
          }
        });
      }

      for (final statusCode in [401, 403, 500]) {
        test('${api.name} propagates cached HTTP $statusCode instead of serving stale metadata', () async {
          final id = '${api.name}-cached-$statusCode';
          final seededResponse = await seedItem(id);
          var requestCount = 0;
          final client = makeClient((_) async {
            requestCount++;
            return jsonResponse(itemResponse('must-not-parse', title: 'Must Not Parse'), statusCode);
          });
          addTearDown(client.close);

          await expectLater(
            lookup(client, id, includeOnDeck: api.includeOnDeck),
            throwsA(
              isA<MediaServerHttpException>()
                  .having((error) => error.statusCode, 'statusCode', statusCode)
                  .having((error) => error.requestUri?.path, 'request path', endpointFor(id)),
            ),
          );

          expect(requestCount, 1);
          expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpointFor(id)), seededResponse);
        });
      }

      test('${api.name} serves cached metadata after a transient timeout', () async {
        final id = '${api.name}-cached-timeout';
        await seedItem(id);
        var requestCount = 0;
        final client = makeClient((_) {
          requestCount++;
          return Future<http.Response>.error(TimeoutException('item lookup timed out'));
        });
        addTearDown(client.close);

        final result = await lookup(client, id, includeOnDeck: api.includeOnDeck);

        expect(result.item, isNotNull);
        expect(result.item!.id, id);
        expect(result.item!.title, 'Cached item');
        expect(result.onDeckEpisode, isNull);
        expect(requestCount, 1);
      });

      test('${api.name} propagates a transient timeout when no cache row exists', () async {
        final id = '${api.name}-uncached-timeout';
        var requestCount = 0;
        final client = makeClient((_) {
          requestCount++;
          return Future<http.Response>.error(TimeoutException('item lookup timed out'));
        });
        addTearDown(client.close);

        await expectLater(
          lookup(client, id, includeOnDeck: api.includeOnDeck),
          throwsA(
            isA<MediaServerHttpException>()
                .having((error) => error.type, 'type', MediaServerHttpErrorType.connectionTimeout)
                .having((error) => error.isTransient, 'isTransient', isTrue),
          ),
        );

        expect(requestCount, 1);
      });

      test('${api.name} propagates cancellation despite cached metadata', () async {
        final id = '${api.name}-cached-cancelled';
        final seededResponse = await seedItem(id);
        var requestCount = 0;
        final client = makeClient((request) {
          requestCount++;
          return Future<http.Response>.error(http.RequestAbortedException(request.url));
        });
        addTearDown(client.close);

        await expectLater(
          lookup(client, id, includeOnDeck: api.includeOnDeck),
          throwsA(
            isA<MediaServerHttpException>()
                .having((error) => error.isCancellation, 'isCancellation', isTrue)
                .having((error) => error.requestUri?.path, 'request path', endpointFor(id)),
          ),
        );

        expect(requestCount, 1);
        expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpointFor(id)), seededResponse);
      });

      test('${api.name} propagates malformed JSON despite cached metadata', () async {
        final id = '${api.name}-cached-malformed-json';
        final seededResponse = await seedItem(id);
        var requestCount = 0;
        final client = makeClient((_) async {
          requestCount++;
          return http.Response('{', 200, headers: jsonHeaders);
        });
        addTearDown(client.close);

        await expectLater(
          lookup(client, id, includeOnDeck: api.includeOnDeck),
          throwsA(
            isA<MediaServerHttpException>()
                .having((error) => error.type, 'type', MediaServerHttpErrorType.unknown)
                .having((error) => error.statusCode, 'statusCode', 200),
          ),
        );

        expect(requestCount, 1);
        expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpointFor(id)), seededResponse);
      });

      test('${api.name} propagates a valid JSON payload rejected by the item DTO', () async {
        final id = '${api.name}-cached-unmappable';
        final seededResponse = await seedItem(id);
        var requestCount = 0;
        final client = makeClient((_) async {
          requestCount++;
          return jsonResponse({
            'MediaContainer': {
              'Metadata': [
                {'ratingKey': id, 'type': 'movie', 'title': 7},
              ],
            },
          }, 200);
        });
        addTearDown(client.close);

        await expectLater(lookup(client, id, includeOnDeck: api.includeOnDeck), throwsA(isA<TypeError>()));

        expect(requestCount, 1);
        expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpointFor(id)), seededResponse);

        client.setOfflineMode(true);
        final offlineResult = await lookup(client, id, includeOnDeck: api.includeOnDeck);
        expect(offlineResult.item?.id, id);
        expect(offlineResult.item?.title, 'Cached item');
        expect(requestCount, 1);
      });

      test('${api.name} uses profile-scoped cache without HTTP while explicitly offline', () async {
        final id = '${api.name}-offline';
        await seedItem(id);
        var requestCount = 0;
        final client = makeClient((_) async {
          requestCount++;
          return jsonResponse(const {'mustNotReachNetwork': true}, 500);
        });
        addTearDown(client.close);
        client.setOfflineMode(true);

        final result = await lookup(client, id, includeOnDeck: api.includeOnDeck);

        expect(result.item, isNotNull);
        expect(result.item!.id, id);
        expect(result.item!.title, 'Cached item');
        expect(result.onDeckEpisode, isNull);
        expect(requestCount, 0);
      });
    }
  });

  group('Plex mutation result families', () {
    test('void mutation completes on success and preserves status/transport failures', () async {
      final item = testMediaItem(
        id: 'item-id',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: 'server-id',
      );
      final success = makeClient((_) async => http.Response('', 200));
      addTearDown(success.close);
      await success.markWatched(item);

      for (final status in [400, 500]) {
        final failing = makeClient((_) async => http.Response('{}', status));
        addTearDown(failing.close);
        await expectLater(
          failing.markWatched(item),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }

      final timeout = makeClient((_) async => throw TimeoutException('timed out'));
      addTearDown(timeout.close);
      await expectLater(
        timeout.markWatched(item),
        throwsA(
          isA<MediaServerHttpException>().having(
            (error) => error.type,
            'type',
            MediaServerHttpErrorType.connectionTimeout,
          ),
        ),
      );
    });

    test('nullable collection creation throws request failures and reserves null for unusable metadata', () async {
      for (final status in [400, 500]) {
        final failing = makeClient((_) async => http.Response('{}', status));
        addTearDown(failing.close);
        await expectLater(
          failing.createCollection(libraryId: '1', title: 'Collection', items: const []),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }

      final timeout = makeClient((_) async => throw TimeoutException('timed out'));
      addTearDown(timeout.close);
      await expectLater(
        timeout.createCollection(libraryId: '1', title: 'Collection', items: const []),
        throwsA(isA<MediaServerHttpException>()),
      );

      final unusable = makeClient(
        (_) async => http.Response(
          jsonEncode({
            'MediaContainer': {'Metadata': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      addTearDown(unusable.close);
      expect(await unusable.createCollection(libraryId: '1', title: 'Collection', items: const []), isNull);

      final valid = makeClient(
        (_) async => http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {'ratingKey': 'collection-1'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      addTearDown(valid.close);
      expect(await valid.createCollection(libraryId: '1', title: 'Collection', items: const []), 'collection-1');
    });

    test('nullable playlist creation shares the request and accepted-null contract', () async {
      final valid = makeClient(
        (_) async => http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': 'playlist-1',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': 'Playlist',
                  'smart': false,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      addTearDown(valid.close);
      expect((await valid.createPlaylist(title: 'Playlist', items: const []))?.id, 'playlist-1');

      final unusable = makeClient(
        (_) async => http.Response(
          jsonEncode({
            'MediaContainer': {'Metadata': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      addTearDown(unusable.close);
      expect(await unusable.createPlaylist(title: 'Playlist', items: const []), isNull);

      final failing = makeClient((_) async => http.Response('{}', 500));
      addTearDown(failing.close);
      await expectLater(
        failing.createPlaylist(title: 'Playlist', items: const []),
        throwsA(isA<MediaServerHttpException>()),
      );
    });

    test('playlist move returns false only for local preconditions and throws request failures', () async {
      var requests = 0;
      final localOnly = makeClient((_) async {
        requests++;
        return http.Response('', 200);
      });
      addTearDown(localOnly.close);
      final generic = testMediaItem(
        id: 'item',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: 'server-id',
      );
      const missingEntry = PlexMediaItem(id: 'item', kind: MediaKind.movie);
      expect(
        await localOnly.movePlaylistItem(playlistId: 'playlist', item: generic, newIndex: 0, afterItem: null),
        isFalse,
      );
      expect(
        await localOnly.movePlaylistItem(playlistId: 'playlist', item: missingEntry, newIndex: 0, afterItem: null),
        isFalse,
      );
      expect(requests, 0);

      const validEntry = PlexMediaItem(id: 'item', kind: MediaKind.movie, playlistItemId: 7);
      final success = makeClient((_) async => http.Response('', 200));
      addTearDown(success.close);
      expect(
        await success.movePlaylistItem(playlistId: 'playlist', item: validEntry, newIndex: 0, afterItem: null),
        isTrue,
      );

      final failing = makeClient((_) async => http.Response('{}', 500));
      addTearDown(failing.close);
      await expectLater(
        failing.movePlaylistItem(playlistId: 'playlist', item: validEntry, newIndex: 0, afterItem: null),
        throwsA(isA<MediaServerHttpException>()),
      );
    });
  });

  test('play queue accepts numeric strings from Plex', () async {
    final client = makeClient(
      (_) async => http.Response(
        jsonEncode({
          'MediaContainer': {
            'playQueueID': '42',
            'playQueueSelectedItemID': '7',
            'playQueueTotalCount': '3',
            'playQueueVersion': '5',
            'size': '3',
            'Metadata': <dynamic>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final queue = await client.createPlayQueue(uri: 'server://items', type: 'video');

    expect(queue?.playQueueID, 42);
    expect(queue?.playQueueSelectedItemID, 7);
    expect(queue?.playQueueTotalCount, 3);
    expect(queue?.size, 3);
  });

  test('show play queue source URI honors the specials-ordering preference', () async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();

    final uris = <String?>[];
    final client = testPlexClient(
      serverId: publicServerId,
      profileScopeId: defaultProfileScopeId,
      config: testPlexConfig(machineIdentifier: 'machine-1'),
      handler: (request) async {
        uris.add(request.url.queryParameters['uri']);
        return http.Response(
          jsonEncode({
            'MediaContainer': {'playQueueID': '42', 'playQueueVersion': '5', 'Metadata': <dynamic>[]},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    addTearDown(client.close);

    // Default (respectServer) and explicit airDate: `/allLeaves` so Plex
    // orders the queue by aired episode order with Specials interleaved
    // (#1416).
    final serverOrder = await client.createShowPlayQueue(showRatingKey: 'show-1');
    expect(serverOrder, isNotNull);
    expect(uris.single, 'server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves');

    await SettingsService.instance.write(SettingsService.specialsOrdering, SpecialsOrdering.airDate);
    await client.createShowPlayQueue(showRatingKey: 'show-1');
    expect(uris.last, 'server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/allLeaves');

    // specialsLast: `/children` keeps the Specials folder out of the regular
    // run (#1952).
    await SettingsService.instance.write(SettingsService.specialsOrdering, SpecialsOrdering.specialsLast);
    final specialsApart = await client.createShowPlayQueue(showRatingKey: 'show-1');
    expect(specialsApart, isNotNull);
    expect(uris.last, 'server://machine-1/com.plexapp.plugins.library/library/metadata/show-1/children');
  });

  test('activities tolerate scalar drift and skip only malformed rows', () async {
    final client = makeClient(
      (_) async => http.Response(
        jsonEncode({
          'MediaContainer': {
            'Activity': [
              {
                'uuid': 'activity-1',
                'type': 'library.update',
                'title': 'Scanning',
                'subtitle': 'Movies',
                'progress': 25,
                'cancellable': false,
              },
              'not-an-activity',
              {'type': 'library.update', 'title': 'Missing identity'},
              {'uuid': 42, 'type': 7, 'title': true, 'subtitle': 99, 'progress': '75', 'cancellable': '1'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final activities = await client.getActivities();

    expect(activities, hasLength(2));
    expect(activities.first.uuid, 'activity-1');
    expect(activities.first.progress, 25);
    expect(activities.first.cancellable, isFalse);
    expect(activities.last.uuid, '42');
    expect(activities.last.type, '7');
    expect(activities.last.title, 'true');
    expect(activities.last.subtitle, '99');
    expect(activities.last.progress, 75);
    expect(activities.last.cancellable, isTrue);
  });

  test('activity fetch abort reaches transport and preserves cancellation identity', () async {
    final transport = _AbortAwareActivitiesClient();
    final client = testPlexClient(
      serverId: publicServerId,
      profileScopeId: defaultProfileScopeId,
      httpClient: transport,
      prioritizedEndpoints: const ['https://plex.example.com', 'https://plex-fallback.example.com'],
    );
    addTearDown(client.close);
    final abort = AbortController();

    final activities = client.getActivities(abort: abort);
    await transport.requestStarted.future;
    abort.abort();

    await expectLater(
      activities,
      throwsA(isA<MediaServerHttpException>().having((error) => error.isCancellation, 'isCancellation', isTrue)),
    );
    await expectLater(transport.abortObserved.future, completes);
    expect(transport.requestCount, 1);
  });

  group('Plex endpoint failover candidate validation', () {
    http.Response identity(String machineIdentifier) => http.Response(
      jsonEncode({
        'MediaContainer': {'machineIdentifier': machineIdentifier},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    test('validates the candidate unauthenticated before the authenticated retry and switches', () async {
      const primary = 'https://plex.example.com';
      const fallback = 'https://plex-fallback.example.com';
      final events = <String>[];
      final probeRequests = <http.Request>[];
      final client = testPlexClient(
        serverId: publicServerId,
        profileScopeId: defaultProfileScopeId,
        httpClient: MockClient((request) async {
          events.add('application:${request.url.host}');
          expect(request.headers['X-Plex-Token'], isNotNull);
          if (request.url.host == 'plex.example.com') {
            throw TimeoutException('primary down');
          }
          return identity('server-id');
        }),
        prioritizedEndpoints: const [primary, fallback],
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          probeRequests.add(request);
          events.add('probe:${request.url.host}');
          return identity('server-id');
        }),
      );
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'server-id');

      expect(events, [
        'application:plex.example.com',
        'probe:plex-fallback.example.com',
        'application:plex-fallback.example.com',
      ]);
      expect(probeRequests.single.url.path, '/identity');
      expect(probeRequests.single.headers.keys.map((name) => name.toLowerCase()), isNot(contains('x-plex-token')));
      expect(client.config.baseUrl, fallback);
    });

    test('wrong-machine candidate is skipped before one authenticated retry to a valid candidate', () async {
      final events = <String>[];
      var exhausted = 0;
      final client = testPlexClient(
        serverId: publicServerId,
        profileScopeId: defaultProfileScopeId,
        httpClient: MockClient((request) async {
          events.add('application:${request.url.host}');
          if (request.url.host == 'plex.example.com') {
            throw TimeoutException('primary down');
          }
          expect(request.url.host, 'valid.example.com');
          return identity('server-id');
        }),
        prioritizedEndpoints: const [
          'https://plex.example.com',
          'https://wrong-machine.example.com',
          'https://valid.example.com',
        ],
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          events.add('probe:${request.url.host}');
          return identity(request.url.host == 'wrong-machine.example.com' ? 'other-server' : 'server-id');
        }),
        onAllEndpointsExhausted: () => exhausted++,
      );
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'server-id');

      expect(events, [
        'application:plex.example.com',
        'probe:wrong-machine.example.com',
        'probe:valid.example.com',
        'application:valid.example.com',
      ]);
      expect(exhausted, 0);
      expect(client.config.baseUrl, 'https://valid.example.com');
    });

    test('unreachable candidate receives no authenticated request and the base URL stays put', () async {
      final events = <String>[];
      var exhausted = 0;
      final client = testPlexClient(
        serverId: publicServerId,
        profileScopeId: defaultProfileScopeId,
        httpClient: MockClient((request) async {
          events.add('application:${request.url.host}');
          expect(request.url.host, 'plex.example.com', reason: 'unvalidated candidates must not see the token');
          throw TimeoutException('primary down');
        }),
        prioritizedEndpoints: const ['https://plex.example.com', 'https://unreachable.example.com'],
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          events.add('probe:${request.url.host}');
          throw TimeoutException('probe unavailable');
        }),
        onAllEndpointsExhausted: () => exhausted++,
      );
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), isNull);

      expect(events, ['application:plex.example.com', 'probe:unreachable.example.com']);
      expect(exhausted, 1);
      expect(client.config.baseUrl, 'https://plex.example.com');
    });
  });

  test('metadata edit preserves locked fields and removed tag wire format', () async {
    http.Request? captured;
    final client = makeClient((request) async {
      captured = request;
      return http.Response('', 200);
    });
    addTearDown(client.close);

    final updated = await client.updateMetadata(
      sectionId: 1,
      ratingKey: 'item-id',
      typeNumber: 1,
      title: 'Renamed',
      tagChanges: {
        'genre': (current: ['Drama'], original: ['Drama', 'Science Fiction']),
      },
    );

    expect(updated, isTrue);
    expect(captured?.method, 'PUT');
    expect(captured?.url.path, '/library/sections/1/all');
    expect(captured?.url.queryParameters, containsPair('title.value', 'Renamed'));
    expect(captured?.url.queryParameters, containsPair('title.locked', '1'));
    expect(captured?.url.queryParameters, containsPair('genre[0].tag.tag', 'Drama'));
    expect(captured?.url.queryParameters, containsPair('genre[].tag.tag-', 'Science%20Fiction'));
    expect(captured?.url.queryParameters, containsPair('genre.locked', '1'));
  });

  test('lyrics parse Plex structured responses with singleton media shapes', () async {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      if (request.url.path == '/library/metadata/track-1') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': 'track-1',
                  'type': 'track',
                  'Media': {
                    'Part': {
                      'Stream': {
                        'id': '501',
                        'key': '/library/streams/501',
                        'streamType': '4',
                        'codec': 'lrc',
                        'format': 'lrc',
                      },
                    },
                  },
                },
              ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/library/streams/501') {
        return http.Response(
          '''
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="1">
  <Lyrics timed="1">
    <Line startOffset="500">
      <Span text="First line" />
    </Line>
    <Line startOffset="4000">
      <Span text="Second " />
      <Span text="line" />
    </Line>
  </Lyrics>
</MediaContainer>
''',
          200,
          headers: const {'content-type': 'application/xml'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final lyrics = await client.fetchLyrics(testMediaItem(id: 'track-1', kind: MediaKind.track));

    expect(lyrics, isNotNull);
    expect(lyrics!.synced, isTrue);
    expect(lyrics.lines.map((line) => line.text), ['First line', 'Second line']);
    expect(lyrics.lines.map((line) => line.startMs), [500, 4000]);
    expect(requests.map((request) => request.url.path), ['/library/metadata/track-1', '/library/streams/501']);
    expect(requests.last.url.queryParameters, containsPair('format', 'xml'));
    expect(requests.last.url.queryParameters, isNot(contains('includeInlineAttribution')));
    expect(requests.last.headers['accept'], 'application/xml');
  });

  test('lyrics refresh incomplete cached metadata and prefer LRC streams', () async {
    const metadataEndpoint = '/library/metadata/track-1';
    await PlexApiCache.instance.put(defaultProfileScopeId.cacheServerId, metadataEndpoint, {
      'MediaContainer': {
        'Metadata': [
          {'ratingKey': 'track-1', 'type': 'track'},
        ],
      },
    });
    final requestedPaths = <String>[];
    final client = makeClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path == metadataEndpoint) {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': 'track-1',
                  'type': 'track',
                  'Media': [
                    {
                      'Part': [
                        {
                          'Stream': [
                            {'id': 501, 'key': '/library/streams/501', 'streamType': 4, 'codec': 'txt'},
                            {'id': 502, 'key': '/library/streams/502', 'streamType': 4, 'codec': 'lrc'},
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/library/streams/502') {
        return http.Response('[00:01.00]Preferred timed line', 200, headers: const {'content-type': 'text/plain'});
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final lyrics = await client.fetchLyrics(testMediaItem(id: 'track-1', kind: MediaKind.track));

    expect(lyrics, isNotNull);
    expect(lyrics!.synced, isTrue);
    expect(lyrics.lines.single.text, 'Preferred timed line');
    expect(requestedPaths, [metadataEndpoint, '/library/streams/502']);
  });

  test('cached child fetch rejects decodable HTTP error responses before caching', () async {
    for (final statusCode in [404, 500]) {
      final parentId = 'parent-$statusCode';
      final endpoint = '/library/metadata/$parentId/children';
      var requestCount = 0;
      final client = makeClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 1,
              'Metadata': [
                {'ratingKey': 'error-child', 'type': 'season', 'title': 'Must Not Parse'},
              ],
            },
          }),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      await expectLater(
        client.fetchChildren(parentId),
        throwsA(
          isA<MediaServerHttpException>()
              .having((error) => error.statusCode, 'statusCode', statusCode)
              .having((error) => error.requestUri?.path, 'request path', endpoint),
        ),
      );

      expect(requestCount, 1);
      expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpoint), isNull);
    }
  });

  test('HTTP failure falls back to the existing child cache without replacing it', () async {
    const parentId = 'cached-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final cachedResponse = {
      'MediaContainer': {
        'size': 1,
        'totalSize': 1,
        'Metadata': [
          {'ratingKey': 'cached-child', 'type': 'season', 'title': 'Cached Season'},
        ],
      },
    };
    await PlexApiCache.instance.put(defaultProfileScopeId.cacheServerId, endpoint, cachedResponse);
    var requestCount = 0;
    final client = makeClient((request) async {
      requestCount++;
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'size': 1,
            'totalSize': 1,
            'Metadata': [
              {'ratingKey': 'error-child', 'type': 'season', 'title': 'Must Not Replace Cache'},
            ],
          },
        }),
        500,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);

    expect(requestCount, 1);
    expect(children.map((child) => child.id), ['cached-child']);
    expect(children.single.title, 'Cached Season');
    expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpoint), cachedResponse);
  });

  test('successful child fetch parses and caches the response', () async {
    const parentId = 'fresh-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final responseData = {
      'MediaContainer': {
        'size': 1,
        'totalSize': 1,
        'Metadata': [
          {'ratingKey': 'fresh-child', 'type': 'season', 'title': 'Fresh Season'},
        ],
      },
    };
    var requestCount = 0;
    final client = makeClient((request) async {
      requestCount++;
      return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);

    expect(requestCount, 1);
    expect(children.map((child) => child.id), ['fresh-child']);
    expect(children.single.title, 'Fresh Season');
    expect(await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpoint), responseData);
  });

  test('child retrieval walks every page and caches the combined result', () async {
    const parentId = 'paged-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final requests = <Uri>[];
    final client = makeClient((request) async {
      requests.add(request.url);
      final start = int.parse(request.url.queryParameters['X-Plex-Container-Start']!);
      final metadata = start == 0
          ? [
              {'ratingKey': 'season-1', 'type': 'season', 'title': 'Season 1'},
              {'ratingKey': 'season-2', 'type': 'season', 'title': 'Season 2'},
            ]
          : [
              {'ratingKey': 'season-3', 'type': 'season', 'title': 'Season 3'},
            ];
      return http.Response(
        jsonEncode({
          'MediaContainer': {'size': metadata.length, 'totalSize': 3, 'Metadata': metadata},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);
    final cached = await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, endpoint);
    final cachedContainer = cached!['MediaContainer'] as Map<String, dynamic>;
    final cachedMetadata = cachedContainer['Metadata'] as List<dynamic>;

    expect(children.map((child) => child.id), ['season-1', 'season-2', 'season-3']);
    expect(requests.map((uri) => uri.queryParameters['X-Plex-Container-Start']), ['0', '2']);
    expect(requests.every((uri) => uri.queryParameters['X-Plex-Container-Size'] == '200'), isTrue);
    expect(requests.every((uri) => uri.queryParameters['includeStreams'] == '1'), isTrue);
    expect(cachedContainer['size'], 3);
    expect(cachedContainer['totalSize'], 3);
    expect(cachedMetadata.map((item) => (item as Map<String, dynamic>)['ratingKey']), [
      'season-1',
      'season-2',
      'season-3',
    ]);
  });

  test('artist albums include every Plex release bucket and cache all pages', () async {
    const cacheKey = '/library/metadata/artist-1/children';
    final requests = <Uri>[];
    final client = makeClient((request) async {
      requests.add(request.url);
      final start = int.parse(request.url.queryParameters['X-Plex-Container-Start']!);
      final metadata = start == 0
          ? [
              {'ratingKey': 'album-lp', 'type': 'album', 'title': 'LP'},
              {'ratingKey': 'album-ep', 'type': 'album', 'title': 'EP'},
            ]
          : [
              {'ratingKey': 'album-single', 'type': 'album', 'title': 'Single'},
              {'ratingKey': 'album-compilation', 'type': 'album', 'title': 'Compilation'},
            ];
      return http.Response(
        jsonEncode({
          'MediaContainer': {'librarySectionID': 7, 'size': metadata.length, 'totalSize': 4, 'Metadata': metadata},
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final albums = await client.fetchArtistAlbums(
      testMediaItem(id: 'artist-1', kind: MediaKind.artist, libraryId: '7'),
    );
    final cached = await PlexApiCache.instance.get(defaultProfileScopeId.cacheServerId, cacheKey);
    final cachedContainer = cached!['MediaContainer'] as Map<String, dynamic>;
    final cachedMetadata = cachedContainer['Metadata'] as List<dynamic>;

    expect(albums.map((album) => album.id), ['album-lp', 'album-ep', 'album-single', 'album-compilation']);
    expect(requests, hasLength(2));
    expect(requests.every((uri) => uri.path == '/library/sections/7/all'), isTrue);
    expect(requests.every((uri) => uri.queryParameters['type'] == '9'), isTrue);
    expect(requests.every((uri) => uri.queryParameters['artist.id'] == 'artist-1'), isTrue);
    expect(requests.every((uri) => uri.queryParameters['sort'] == 'album.year:desc'), isTrue);
    expect(requests.map((uri) => uri.queryParameters['X-Plex-Container-Start']), ['0', '2']);
    expect(cachedMetadata.map((item) => (item as Map<String, dynamic>)['ratingKey']), [
      'album-lp',
      'album-ep',
      'album-single',
      'album-compilation',
    ]);
  });

  test('artist albums resolve a missing music section from artist metadata', () async {
    final requestedPaths = <String>[];
    final client = makeClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path == '/library/metadata/artist-1') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'librarySectionID': 7,
              'Metadata': [
                {'ratingKey': 'artist-1', 'type': 'artist', 'title': 'Artist'},
              ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/library/sections/7/all') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'librarySectionID': 7,
              'size': 1,
              'Metadata': [
                {'ratingKey': 'album-1', 'type': 'album', 'title': 'Album'},
              ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final albums = await client.fetchArtistAlbums(testMediaItem(id: 'artist-1', kind: MediaKind.artist));

    expect(requestedPaths, ['/library/metadata/artist-1', '/library/sections/7/all']);
    expect(albums.map((album) => album.id), ['album-1']);
  });

  test('profile transition isolates metadata and every direct cache-only bypass', () async {
    final scopeA = buildPlexProfileScopeId(serverId: publicServerId, profileId: 'profile-a');
    final scopeB = buildPlexProfileScopeId(serverId: publicServerId, profileId: 'profile-b');
    const metadataEndpoint = '/library/metadata/42';
    const bypassEndpoint = '/library/metadata/bypass';
    const tokenA = 'synthetic-token-a';
    const tokenB = 'synthetic-token-b';
    final requests = <({String path, String? token})>[];

    String? tokenFor(http.Request request) {
      for (final entry in request.headers.entries) {
        if (entry.key.toLowerCase() == 'x-plex-token') return entry.value;
      }
      return null;
    }

    Map<String, dynamic> metadataPayload(
      String ratingKey,
      String title, {
      required int markerId,
      required int audioTrackId,
    }) {
      return {
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': ratingKey,
              'type': 'movie',
              'title': title,
              'duration': 120000,
              'Marker': [
                {'id': markerId, 'type': 'intro', 'startTimeOffset': 1000, 'endTimeOffset': 2000},
              ],
              'Media': [
                {
                  'id': 1,
                  'videoResolution': '1080',
                  'Part': [
                    {
                      'id': 10,
                      'key': '/library/parts/10/file.mkv',
                      'Stream': [
                        {'id': audioTrackId, 'streamType': 2, 'codec': 'aac'},
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      };
    }

    final client = testPlexClient(
      token: tokenA,
      serverId: publicServerId,
      profileScopeId: scopeA,
      handler: (request) async {
        final token = tokenFor(request);
        requests.add((path: request.url.path, token: token));
        if (request.url.path == '/') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': publicServerId.value},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/media/providers') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {'MediaProvider': <Object>[]},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path == metadataEndpoint) {
          final payload = token == tokenA
              ? metadataPayload('42', 'Profile A network', markerId: 101, audioTrackId: 11)
              : metadataPayload('42', 'Profile B network', markerId: 202, audioTrackId: 22);
          return http.Response(jsonEncode(payload), 200, headers: const {'content-type': 'application/json'});
        }
        return http.Response('', 200);
      },
    );
    addTearDown(client.close);

    final itemA = await client.fetchItem('42');
    expect(itemA, isNotNull);
    expect(itemA!.title, 'Profile A network');
    expect(itemA.serverId, 'server-id');
    expect(itemA.globalKey, 'server-id:42');

    await client.applyProfileUpdate(newToken: tokenB, newProfileScopeId: scopeB);
    final itemB = await client.fetchItem('42');
    expect(itemB, isNotNull);
    expect(itemB!.title, 'Profile B network');
    expect(itemB.serverId, 'server-id');
    expect(itemB.globalKey, 'server-id:42');

    final cachedA = await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '42');
    final cachedB = await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '42');
    expect(cachedA?.title, 'Profile A network');
    expect(cachedB?.title, 'Profile B network');
    expect(requests.where((request) => request.path == metadataEndpoint).map((request) => request.token), [
      tokenA,
      tokenB,
    ]);
    expect(requests.where((request) => request.path == '/media/providers').map((request) => request.token), [tokenB]);

    await PlexApiCache.instance.put(
      scopeA.cacheServerId,
      bypassEndpoint,
      metadataPayload('bypass', 'Profile A bypass', markerId: 101, audioTrackId: 11),
    );
    await PlexApiCache.instance.put(
      scopeB.cacheServerId,
      bypassEndpoint,
      metadataPayload('bypass', 'Profile B bypass', markerId: 202, audioTrackId: 22),
    );

    final extras = await client.fetchPlaybackExtrasFromCacheOnly('bypass');
    final mediaSource = await client.fetchCachedMediaSourceInfo('bypass');
    expect(extras, isNotNull);
    expect(extras!.markers.single.id, 202);
    expect(mediaSource, isNotNull);
    expect(mediaSource!.audioTracks.single.id, 22);

    expect(
      await client.updateMetadata(sectionId: 1, ratingKey: 'bypass', typeNumber: 1, title: 'Profile B renamed'),
      isTrue,
    );
    expect(await PlexApiCache.instance.get(scopeB.cacheServerId, bypassEndpoint), isNull);
    expect(await PlexApiCache.instance.get(scopeA.cacheServerId, bypassEndpoint), isNotNull);
  });

  test('cache-first miss keeps the sending profile identity and cache scope together', () async {
    final scopeA = buildPlexProfileScopeId(serverId: publicServerId, profileId: 'profile-a');
    final scopeB = buildPlexProfileScopeId(serverId: publicServerId, profileId: 'profile-b');
    const tokenA = 'synthetic-token-a';
    const tokenB = 'synthetic-token-b';
    const endpoint = '/library/metadata/gated';
    final requests = <({String path, String? token})>[];

    String? tokenFor(http.Request request) {
      for (final entry in request.headers.entries) {
        if (entry.key.toLowerCase() == 'x-plex-token') return entry.value;
      }
      return null;
    }

    Map<String, dynamic> payload(String owner, int markerId) => {
      'MediaContainer': {
        'Metadata': [
          {
            'ratingKey': 'gated',
            'type': 'movie',
            'title': owner,
            'Marker': [
              {'id': markerId, 'type': 'intro', 'startTimeOffset': 1000, 'endTimeOffset': 2000},
            ],
          },
        ],
      },
    };

    final client = testPlexClient(
      token: tokenA,
      serverId: publicServerId,
      profileScopeId: scopeA,
      handler: (request) async {
        final token = tokenFor(request);
        requests.add((path: request.url.path, token: token));
        if (request.url.path == '/') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': publicServerId.value},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/media/providers') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {'MediaProvider': <Object>[]},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path == endpoint) {
          final response = token == tokenA ? payload('Profile A response', 101) : payload('Profile B response', 202);
          return http.Response(jsonEncode(response), 200, headers: const {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      },
    );
    addTearDown(client.close);

    final releaseCacheRead = Completer<void>();
    final transactionStarted = Completer<void>();
    final heldTransaction = db.transaction(() async {
      transactionStarted.complete();
      await releaseCacheRead.future;
    });
    await transactionStarted.future;

    final extrasFuture = client.getPlaybackExtras('gated');
    try {
      await client.applyProfileUpdate(newToken: tokenB, newProfileScopeId: scopeB);
    } finally {
      releaseCacheRead.complete();
    }
    await heldTransaction;

    final extras = await extrasFuture;
    expect(extras.markers.single.id, 101);
    expect(requests.where((request) => request.path == endpoint).map((request) => request.token), [tokenA]);
    expect(await PlexApiCache.instance.get(scopeA.cacheServerId, endpoint), payload('Profile A response', 101));
    expect(await PlexApiCache.instance.get(scopeB.cacheServerId, endpoint), isNull);
  });

  group('Plex timeline termination contract', () {
    // Response documented by the published PMS OpenAPI spec for /:/timeline
    // (`adminTerminatedSession` example): the server signals a terminated
    // session on the MediaContainer of the next timeline reply (#1916).
    Map<String, dynamic> terminatedBody({Object code = 2006}) => {
      'MediaContainer': {
        'size': 0,
        'terminationCode': code,
        'terminationText': 'Admin terminated playback with reason: Go Away',
      },
    };

    PlexClient timelineClient(Object? body, {void Function(http.Request request)? onRequest}) =>
        makeClient((request) async {
          expect(request.url.path, '/:/timeline');
          onRequest?.call(request);
          return http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});
        });

    test('progress and started reports throw on a terminated session', () async {
      final client = timelineClient(terminatedBody());
      addTearDown(client.close);

      await expectLater(
        client.reportPlaybackProgress(
          itemId: '42',
          position: const Duration(minutes: 2),
          duration: const Duration(minutes: 20),
          isPaused: true,
        ),
        throwsA(
          isA<PlaybackSessionTerminatedException>()
              .having((e) => e.code, 'code', 2006)
              .having((e) => e.reason, 'reason', 'Admin terminated playback with reason: Go Away'),
        ),
      );
      await expectLater(
        client.reportPlaybackStarted(itemId: '42', position: const Duration(minutes: 2)),
        throwsA(isA<PlaybackSessionTerminatedException>()),
      );
    });

    test('stopped report ignores termination: it is the cleanup call that clears the session', () async {
      String? reportedState;
      final client = timelineClient(
        terminatedBody(),
        onRequest: (request) => reportedState = request.url.queryParameters['state'],
      );
      addTearDown(client.close);

      await client.reportPlaybackStopped(itemId: '42', position: const Duration(minutes: 2));
      expect(reportedState, 'stopped');
    });

    test('tolerates a string terminationCode', () async {
      final client = timelineClient(terminatedBody(code: '2006'));
      addTearDown(client.close);

      await expectLater(
        client.reportPlaybackProgress(
          itemId: '42',
          position: const Duration(minutes: 2),
          duration: const Duration(minutes: 20),
        ),
        throwsA(isA<PlaybackSessionTerminatedException>().having((e) => e.code, 'code', 2006)),
      );
    });

    test('normal timeline reply does not throw', () async {
      final client = timelineClient({
        'MediaContainer': {'size': 0},
      });
      addTearDown(client.close);

      await client.reportPlaybackProgress(
        itemId: '42',
        position: const Duration(minutes: 2),
        duration: const Duration(minutes: 20),
        isPaused: true,
      );
    });
  });
}

class _AbortAwareActivitiesClient extends http.BaseClient {
  final requestStarted = Completer<void>();
  final abortObserved = Completer<void>();
  final _response = Completer<http.StreamedResponse>();
  var requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requestCount++;
    if (!requestStarted.isCompleted) {
      requestStarted.complete();
    }
    final abortTrigger = (request as http.Abortable).abortTrigger!;
    unawaited(
      abortTrigger.then((_) {
        if (!abortObserved.isCompleted) {
          abortObserved.complete();
        }
        if (!_response.isCompleted) {
          _response.completeError(http.RequestAbortedException(request.url));
        }
      }),
    );
    return _response.future;
  }
}
