import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/exceptions/media_server_exceptions.dart';
import 'package:vibe_stream/services/jellyfin_api_cache.dart';
import 'package:vibe_stream/services/jellyfin_client.dart';

JellyfinConnection _conn({String baseUrl = 'https://jf.example.com', List<String>? baseUrls}) => JellyfinConnection(
  id: 'srv-1/user-1',
  baseUrl: baseUrl,
  baseUrls: baseUrls,
  serverName: 'Home',
  serverMachineId: 'srv-1',
  userId: 'user-1',
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinClient _withMock(MockClient mock) => JellyfinClient.forTesting(connection: _conn(), httpClient: mock);

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
  });
  tearDown(() async {
    await db.close();
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
    test('switches to the fallback URL after a transient GET failure', () async {
      final requests = <Uri>[];
      final client = JellyfinClient.forTesting(
        connection: _conn(
          baseUrl: 'https://primary.example.com',
          baseUrls: const ['https://primary.example.com', 'https://fallback.example.com'],
        ),
        httpClient: MockClient((req) async {
          requests.add(req.url);
          if (req.url.host == 'primary.example.com') {
            throw TimeoutException('primary down');
          }
          return http.Response(jsonEncode({'Id': 'srv-1'}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);

      expect(await client.getMachineIdentifier(), 'srv-1');
      expect(requests.map((uri) => uri.host), ['primary.example.com', 'fallback.example.com']);
      expect(client.connection.baseUrl, 'https://fallback.example.com');
      expect(client.connection.baseUrls, ['https://fallback.example.com', 'https://primary.example.com']);
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
      );
      addTearDown(client.close);

      await client.getMachineIdentifier();

      expect(requests.map((uri) => uri.host), ['primary.example.com', 'fallback.example.com']);
      expect(client.connection.baseUrl, 'https://primary.example.com');

      expect(await client.getMachineIdentifier(), 'srv-1');
      expect(requests.map((uri) => uri.host), ['primary.example.com', 'fallback.example.com', 'primary.example.com']);
    });
  });
}
