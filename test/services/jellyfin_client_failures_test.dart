import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

JellyfinConnection _conn({String baseUrl = 'https://jf.example.com', List<String>? baseUrls}) => testJellyfinConnection(
  baseUrl: baseUrl,
  baseUrls: baseUrls,
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinClient _withMock(MockClient mock) => testJellyfinClient(connection: _conn(), httpClient: mock);

class _AbortAwareClient extends http.BaseClient {
  final requestStarted = Completer<void>();
  final _response = Completer<http.StreamedResponse>();
  Uri? _requestUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _requestUri = request.url;
    if (!requestStarted.isCompleted) requestStarted.complete();
    return _response.future;
  }

  @override
  void close() {
    if (!_response.isCompleted) {
      _response.completeError(http.RequestAbortedException(_requestUri));
    }
  }
}

/// Failure-path coverage for the Jellyfin HTTP layer.
///
/// The original test suite covered the 200-OK happy paths and a single 404
/// (handled inside `fetchItem`). Anything else — auth rejection, server
/// errors, malformed JSON — was untested. These cases are the exact shapes
/// that surface in the field when a Jellyfin server is mid-update or the
/// access token has been revoked, so they're worth pinning.
void main() {
  // fetchChildren writes through `JellyfinApiCache.instance` on a
  // successful 200, so the singleton needs to exist for tests that exercise
  // that path. fetchItem's failure paths short-circuit before any cache
  // write but we initialise unconditionally for symmetry.
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    setLoggerLevel(false);
  });
  tearDown(() async {
    await db.close();
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    setLoggerLevel(true);
  });

  group('JellyfinClient.fetchItem failure modes', () {
    test('404 returns null (item not on server)', () async {
      final client = _withMock(MockClient((_) async => http.Response('', 404)));
      expect(await client.fetchItem('missing'), isNull);
      client.close();
    });

    // Auth and server errors must throw — silently returning null on a
    // revoked token would let the UI render stale cached state and report
    // "no metadata" instead of "you're signed out". 404 is the only
    // non-2xx that's still allowed to collapse to null (item genuinely
    // doesn't exist on the server).
    test('401 throws MediaServerHttpException', () async {
      final client = _withMock(MockClient((_) async => http.Response('Unauthorized', 401)));
      await expectLater(client.fetchItem('any'), throwsA(isA<MediaServerHttpException>()));
      client.close();
    });

    test('403 throws MediaServerHttpException', () async {
      final client = _withMock(MockClient((_) async => http.Response('Forbidden', 403)));
      await expectLater(client.fetchItem('any'), throwsA(isA<MediaServerHttpException>()));
      client.close();
    });

    test('500 throws MediaServerHttpException', () async {
      final client = _withMock(MockClient((_) async => http.Response('Internal error', 500)));
      await expectLater(client.fetchItem('any'), throwsA(isA<MediaServerHttpException>()));
      client.close();
    });

    test('200 with malformed JSON returns null without throwing', () async {
      // The HTTP wrapper falls back to raw text when JSON decoding fails;
      // `fetchItem` then sees a non-Map payload and returns null. Confirms
      // the parser doesn't blow up the caller on a server that suddenly
      // returns HTML (e.g. a reverse proxy 200 page).
      final client = _withMock(
        MockClient((_) async => http.Response('<html>oops</html>', 200, headers: {'content-type': 'text/html'})),
      );
      expect(await client.fetchItem('any'), isNull);
      client.close();
    });

    test('200 with empty body returns null', () async {
      final client = _withMock(MockClient((_) async => http.Response('', 200)));
      expect(await client.fetchItem('any'), isNull);
      client.close();
    });
  });

  group('JellyfinClient.fetchChildren failure modes', () {
    test('any /Seasons failure (incl. 500) falls through to /Items, which propagates', () async {
      // The current implementation catches *every* MediaServerHttpException
      // from /Shows/{id}/Seasons and falls through to /Items. The /Items
      // call's failure is what the caller sees. This pins that contract:
      // both endpoints are reached, and the error from /Items wins.
      var seasonsHit = false;
      var itemsHit = false;
      final client = _withMock(
        MockClient((req) async {
          if (req.url.path.endsWith('/Seasons')) {
            seasonsHit = true;
            return http.Response('boom', 500);
          }
          if (req.url.path == '/Items') {
            itemsHit = true;
            return http.Response('boom', 500);
          }
          return http.Response('unexpected', 500);
        }),
      );
      await expectLater(client.fetchChildren('parent'), throwsA(isA<MediaServerHttpException>()));
      expect(seasonsHit, isTrue);
      expect(itemsHit, isTrue);
      client.close();
    });

    test('404 on /Seasons falls through to /Items (non-series item)', () async {
      var seenItems = false;
      final client = _withMock(
        MockClient((req) async {
          if (req.url.path.endsWith('/Seasons')) {
            return http.Response('not found', 404);
          }
          seenItems = req.url.path == '/Items';
          return http.Response('{"Items": []}', 200, headers: {'content-type': 'application/json'});
        }),
      );
      final children = await client.fetchChildren('parent');
      expect(children, isEmpty);
      expect(seenItems, isTrue);
      client.close();
    });
  });

  group('JellyfinClient endpoint failover', () {
    http.Response publicInfo([String id = 'srv-1']) => http.Response(
      jsonEncode({'Id': id, 'ServerName': 'Home', 'Version': '10.9.0'}),
      200,
      headers: {'content-type': 'application/json'},
    );

    test('validates publicly before authenticated fallback and persists one promotion', () async {
      const primary = 'https://primary-client-canary.invalid/primary-private-base';
      const fallback = 'https://fallback-client-canary.invalid/fallback-private-base';
      final events = <String>[];
      final applicationRequests = <http.Request>[];
      final probeRequests = <http.Request>[];
      final persisted = <JellyfinConnection>[];
      final client = JellyfinClient.forTesting(
        connection: _conn(baseUrl: primary, baseUrls: const [primary, fallback]),
        httpClient: MockClient((request) async {
          applicationRequests.add(request);
          events.add('application:${request.url.host}');
          expect(request.headers['X-Emby-Token'], 'tok-abc');
          if (request.url.host == 'primary-client-canary.invalid') {
            throw TimeoutException('primary down');
          }
          return http.Response(jsonEncode({'Id': 'srv-1'}), 200, headers: {'content-type': 'application/json'});
        }),
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          probeRequests.add(request);
          events.add('probe:${request.url.host}');
          return publicInfo();
        }),
      );
      client.onConnectionUpdated = persisted.add;
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'srv-1');

      expect(events, [
        'application:primary-client-canary.invalid',
        'probe:fallback-client-canary.invalid',
        'application:fallback-client-canary.invalid',
      ]);
      expect(applicationRequests, hasLength(2));
      expect(probeRequests, hasLength(1));
      expect(probeRequests.single.headers.keys.map((name) => name.toLowerCase()), isNot(contains('authorization')));
      expect(probeRequests.single.headers.keys.map((name) => name.toLowerCase()), isNot(contains('x-emby-token')));
      expect(client.connection.baseUrl, fallback);
      expect(client.connection.baseUrls, [fallback, primary]);
      expect(persisted, hasLength(1));
      expect(persisted.single.baseUrl, fallback);

      final storedFields = MemoryLogOutput.getLogs().expand<String>(
        (entry) => [entry.message, if (entry.error != null) entry.error.toString()],
      );
      for (final field in storedFields) {
        expect(field, isNot(contains('primary-client-canary.invalid')));
        expect(field, isNot(contains('primary-private-base')));
        expect(field, isNot(contains('fallback-client-canary.invalid')));
        expect(field, isNot(contains('fallback-private-base')));
      }
    });

    test('wrong-machine fallback is skipped before one authenticated retry to a valid fallback', () async {
      final events = <String>[];
      final applicationRequests = <http.Request>[];
      final persisted = <JellyfinConnection>[];
      var exhausted = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const [
            'https://primary.example.com',
            'https://wrong-machine.example.com',
            'https://valid.example.com',
          ],
        ),
        httpClient: MockClient((request) async {
          applicationRequests.add(request);
          events.add('application:${request.url.host}');
          if (request.url.host == 'primary.example.com') {
            throw TimeoutException('primary down');
          }
          expect(request.url.host, 'valid.example.com');
          return http.Response(jsonEncode({'Id': 'srv-1'}), 200, headers: {'content-type': 'application/json'});
        }),
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          events.add('probe:${request.url.host}');
          expect(request.headers.keys.map((name) => name.toLowerCase()), isNot(contains('x-emby-token')));
          return publicInfo(request.url.host == 'wrong-machine.example.com' ? 'srv-other' : 'srv-1');
        }),
        onAllEndpointsExhausted: () => exhausted++,
      );
      client.onConnectionUpdated = persisted.add;
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'srv-1');

      expect(events, [
        'application:primary.example.com',
        'probe:wrong-machine.example.com',
        'probe:valid.example.com',
        'application:valid.example.com',
      ]);
      expect(applicationRequests, hasLength(2));
      expect(exhausted, 0);
      expect(persisted, hasLength(1));
      expect(persisted.single.baseUrl, 'https://valid.example.com');
      expect(client.connection.baseUrl, 'https://valid.example.com');
    });

    test('unreachable fallback receives no authenticated application request', () async {
      final events = <String>[];
      final persisted = <JellyfinConnection>[];
      var exhausted = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const ['https://primary.example.com', 'https://unreachable.example.com'],
        ),
        httpClient: MockClient((request) async {
          events.add('application:${request.url.host}');
          throw TimeoutException('primary down');
        }),
        endpointProbeHttpClientFactory: () => MockClient((request) async {
          events.add('probe:${request.url.host}');
          expect(request.headers.keys.map((name) => name.toLowerCase()), isNot(contains('x-emby-token')));
          throw TimeoutException('probe unavailable');
        }),
        onAllEndpointsExhausted: () => exhausted++,
      );
      client.onConnectionUpdated = persisted.add;
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'srv-1');

      expect(events, ['application:primary.example.com', 'probe:unreachable.example.com']);
      expect(exhausted, 1);
      expect(persisted, isEmpty);
      expect(client.connection.baseUrl, 'https://primary.example.com');
    });

    test('hub surfaces retry transient failures without hopping endpoints', () async {
      final attemptsByPath = <String, int>{};
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const ['https://primary.example.com', 'https://fallback.example.com'],
        ),
        httpClient: MockClient((req) async {
          expect(req.url.host, 'primary.example.com', reason: 'retry-wrapped hub fetches must not fail over');
          final attempt = attemptsByPath.update(req.url.path, (n) => n + 1, ifAbsent: () => 1);
          if (attempt == 1) throw TimeoutException('slow row');
          return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);

      final items = await client.fetchContinueWatching();

      expect(items, isEmpty);
      expect(attemptsByPath.values, everyElement(2));
      expect(client.connection.baseUrl, 'https://primary.example.com');
    });

    test('exhausting every endpoint fires onAllEndpointsExhausted', () async {
      var exhausted = 0;
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const ['https://primary.example.com', 'https://fallback.example.com'],
        ),
        httpClient: MockClient((req) async => throw TimeoutException('endpoint down')),
        endpointProbeHttpClientFactory: () => MockClient((_) async => publicInfo()),
        onAllEndpointsExhausted: () => exhausted++,
      );
      addTearDown(client.close);

      await client.getMachineIdentifier();

      expect(exhausted, 1);
    });

    test('resets live base URL after fallback endpoint is exhausted', () async {
      final requests = <Uri>[];
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const ['https://primary.example.com', 'https://fallback.example.com'],
        ),
        httpClient: MockClient((req) async {
          requests.add(req.url);
          if (requests.length <= 2) {
            throw TimeoutException('endpoint down');
          }
          return http.Response(jsonEncode({'Id': 'srv-1'}), 200, headers: {'content-type': 'application/json'});
        }),
        endpointProbeHttpClientFactory: () => MockClient((_) async => publicInfo()),
      );
      addTearDown(client.close);

      await client.getMachineIdentifier();

      expect(requests.map((uri) => uri.host), ['primary.example.com', 'fallback.example.com']);
      expect(client.connection.baseUrl, 'https://primary.example.com');

      expect(await client.getMachineIdentifier(), 'srv-1');
      expect(requests.map((uri) => uri.host), ['primary.example.com', 'fallback.example.com', 'primary.example.com']);
    });
  });

  group('cancellation vs treat-as-empty', () {
    // The hub/next-up fetch helpers swallow per-endpoint failures into empty
    // lists so one broken endpoint doesn't sink a whole row. A *cancelled*
    // request is different: it means our own client was torn down mid-fetch
    // and says nothing about the server's content, so it must propagate —
    // otherwise a disrupted server counts as "succeeded with partial data"
    // and aborted sign-in fetches flash an empty home screen.
    MediaServerHttpException cancelled() =>
        MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'HTTP client is closing');

    test('fetchContinueWatching propagates a cancelled NextUp sub-fetch', () async {
      final client = _withMock(
        MockClient((req) async {
          if (req.url.path == '/Shows/NextUp') throw cancelled();
          return http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);

      await expectLater(
        client.fetchContinueWatching(),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
    });

    test('fetchContinueWatching still treats a NextUp server error as empty', () async {
      final client = _withMock(
        MockClient((req) async {
          if (req.url.path == '/Shows/NextUp') return http.Response('Internal error', 500);
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'ep-1', 'Type': 'Episode', 'Name': 'Resume Me'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);

      final items = await client.fetchContinueWatching();

      expect(items.map((i) => i.id), ['ep-1']);
    });

    test('fetchMoreHubItems propagates a cancellation and swallows server errors', () async {
      final cancelledClient = _withMock(MockClient((_) async => throw cancelled()));
      addTearDown(cancelledClient.close);
      await expectLater(
        cancelledClient.fetchMoreHubItems('home.nextup'),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );

      final failingClient = _withMock(MockClient((_) async => http.Response('Internal error', 500)));
      addTearDown(failingClient.close);
      expect(await failingClient.fetchMoreHubItems('home.nextup'), isEmpty);
    });
  });

  group('JellyfinClient.getPlaybackInfo failure contract', () {
    test('preserves 401, 403, and 500 status failures', () async {
      for (final status in [401, 403, 500]) {
        final client = _withMock(
          MockClient(
            (_) async =>
                http.Response(jsonEncode({'error': 'redacted'}), status, headers: {'content-type': 'application/json'}),
          ),
        );
        addTearDown(client.close);

        await expectLater(
          client.getPlaybackInfo('item-1'),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }
    });

    test('preserves timeout classifications', () async {
      final timeoutClient = _withMock(MockClient((_) async => throw TimeoutException('timed out')));
      addTearDown(timeoutClient.close);
      await expectLater(
        timeoutClient.getPlaybackInfo('item-1'),
        throwsA(
          isA<MediaServerHttpException>().having(
            (error) => error.type,
            'type',
            MediaServerHttpErrorType.connectionTimeout,
          ),
        ),
      );

      final receiveTimeoutClient = _withMock(
        MockClient(
          (_) async =>
              throw MediaServerHttpException(type: MediaServerHttpErrorType.receiveTimeout, message: 'timed out'),
        ),
      );
      addTearDown(receiveTimeoutClient.close);
      await expectLater(
        receiveTimeoutClient.getPlaybackInfo('item-1'),
        throwsA(
          isA<MediaServerHttpException>().having(
            (error) => error.type,
            'type',
            MediaServerHttpErrorType.receiveTimeout,
          ),
        ),
      );
    });

    test('client close preserves real in-flight cancellation', () async {
      final transport = _AbortAwareClient();
      final client = testJellyfinClient(connection: _conn(), httpClient: transport);

      final playbackInfo = client.getPlaybackInfo('item-1');
      await transport.requestStarted.future;
      client.close();

      await expectLater(
        playbackInfo,
        throwsA(isA<MediaServerHttpException>().having((error) => error.isCancellation, 'isCancellation', isTrue)),
      );
    });

    test('rejects invalid JSON and malformed successful shapes without retaining payload', () async {
      final responses = <http.Response>[
        http.Response('{', 200, headers: {'content-type': 'application/json'}),
        http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'}),
        http.Response(jsonEncode({'unrelated': 'payload-canary'}), 200, headers: {'content-type': 'application/json'}),
        http.Response(
          jsonEncode({'MediaSources': 'payload-canary'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ];

      for (final response in responses) {
        final client = _withMock(MockClient((_) async => response));
        addTearDown(client.close);
        await expectLater(client.getPlaybackInfo('item-1'), throwsA(isA<MediaServerHttpException>()));
      }

      for (final body in [
        <String, dynamic>{'unrelated': 'payload-canary'},
        <String, dynamic>{'MediaSources': 'payload-canary'},
      ]) {
        final client = _withMock(
          MockClient((_) async => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'})),
        );
        addTearDown(client.close);
        try {
          await client.getPlaybackInfo('item-1');
          fail('Malformed PlaybackInfo must throw');
        } on MediaServerHttpException catch (error) {
          expect(error.statusCode, 200);
          expect(error.responseData, isNull);
          expect(error.requestUri, isNull);
          expect(error.toString(), isNot(contains('payload-canary')));
        }
      }
    });

    test('accepts a successful empty source list', () async {
      final client = _withMock(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'MediaSources': []}), 200, headers: {'content-type': 'application/json'}),
        ),
      );
      addTearDown(client.close);

      expect(await client.getPlaybackInfo('item-1'), {'MediaSources': []});
    });
  });

  group('Jellyfin mutation result families', () {
    final item = testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-1');

    test('void mutation completes on success and preserves status/transport failures', () async {
      final success = _withMock(MockClient((_) async => http.Response('', 204)));
      addTearDown(success.close);
      await success.markWatched(item);

      for (final status in [400, 500]) {
        final failing = _withMock(MockClient((_) async => http.Response('{}', status)));
        addTearDown(failing.close);
        await expectLater(
          failing.markWatched(item),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }

      final timeout = _withMock(MockClient((_) async => throw TimeoutException('timed out')));
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

    test('nullable playlist creation returns entity/null and throws request failures', () async {
      final valid = _withMock(
        MockClient((request) async {
          if (request.url.path == '/Playlists') {
            return http.Response(jsonEncode({'Id': 'playlist-1'}), 200, headers: {'content-type': 'application/json'});
          }
          if (request.url.path == '/Users/user-1/Items/playlist-1') {
            return http.Response(
              jsonEncode({'Id': 'playlist-1', 'Name': 'Playlist', 'Type': 'Playlist', 'MediaType': 'Video'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(valid.close);
      expect((await valid.createPlaylist(title: 'Playlist', items: const []))?.id, 'playlist-1');

      final unusable = _withMock(
        MockClient((_) async => http.Response(jsonEncode({}), 200, headers: {'content-type': 'application/json'})),
      );
      addTearDown(unusable.close);
      expect(await unusable.createPlaylist(title: 'Playlist', items: const []), isNull);

      for (final status in [400, 500]) {
        final failing = _withMock(MockClient((_) async => http.Response('{}', status)));
        addTearDown(failing.close);
        await expectLater(
          failing.createPlaylist(title: 'Playlist', items: const []),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }
      final timeout = _withMock(MockClient((_) async => throw TimeoutException('timed out')));
      addTearDown(timeout.close);
      await expectLater(
        timeout.createPlaylist(title: 'Playlist', items: const []),
        throwsA(isA<MediaServerHttpException>()),
      );
    });

    test('nullable collection creation returns id/null and throws request failures', () async {
      final valid = _withMock(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'Id': 'collection-1'}), 200, headers: {'content-type': 'application/json'}),
        ),
      );
      addTearDown(valid.close);
      expect(
        await valid.createCollection(libraryId: 'library-1', title: 'Collection', items: const []),
        'collection-1',
      );

      final unusable = _withMock(
        MockClient((_) async => http.Response(jsonEncode({}), 200, headers: {'content-type': 'application/json'})),
      );
      addTearDown(unusable.close);
      expect(await unusable.createCollection(libraryId: 'library-1', title: 'Collection', items: const []), isNull);

      for (final status in [400, 500]) {
        final failing = _withMock(MockClient((_) async => http.Response('{}', status)));
        addTearDown(failing.close);
        await expectLater(
          failing.createCollection(libraryId: 'library-1', title: 'Collection', items: const []),
          throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
        );
      }
      final timeout = _withMock(MockClient((_) async => throw TimeoutException('timed out')));
      addTearDown(timeout.close);
      await expectLater(
        timeout.createCollection(libraryId: 'library-1', title: 'Collection', items: const []),
        throwsA(isA<MediaServerHttpException>()),
      );
    });

    test('playlist move returns false only for local preconditions and throws request failures', () async {
      var requests = 0;
      final localOnly = _withMock(
        MockClient((_) async {
          requests++;
          return http.Response('', 204);
        }),
      );
      addTearDown(localOnly.close);
      const wrongBackend = PlexMediaItem(id: 'item-1', kind: MediaKind.movie);
      const missingEntry = JellyfinMediaItem(id: 'item-1', kind: MediaKind.movie);
      expect(
        await localOnly.movePlaylistItem(playlistId: 'playlist', item: wrongBackend, newIndex: 0, afterItem: null),
        isFalse,
      );
      expect(
        await localOnly.movePlaylistItem(playlistId: 'playlist', item: missingEntry, newIndex: 0, afterItem: null),
        isFalse,
      );
      expect(requests, 0);

      const validEntry = JellyfinMediaItem(id: 'item-1', kind: MediaKind.movie, playlistItemId: 'entry-1');
      final success = _withMock(MockClient((_) async => http.Response('', 204)));
      addTearDown(success.close);
      expect(
        await success.movePlaylistItem(playlistId: 'playlist', item: validEntry, newIndex: 0, afterItem: null),
        isTrue,
      );

      final failing = _withMock(MockClient((_) async => http.Response('{}', 500)));
      addTearDown(failing.close);
      await expectLater(
        failing.movePlaylistItem(playlistId: 'playlist', item: validEntry, newIndex: 0, afterItem: null),
        throwsA(isA<MediaServerHttpException>()),
      );
    });
  });
}
