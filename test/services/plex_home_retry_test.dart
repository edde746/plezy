import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(http.BaseRequest request);

class _SequenceClient extends http.BaseClient {
  _SequenceClient(this._handlers);

  final List<_RequestHandler> _handlers;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    if (_handlers.isEmpty) {
      throw StateError('Unexpected request: ${request.url}');
    }
    return _handlers.removeAt(0)(request);
  }
}

void main() {
  group('PlexClient home hub retries', () {
    test('fetchGlobalHubs retries a transient first failure', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('cold Plex start'),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 12);

      expect(hubs, hasLength(1));
      expect(hubs.single.title, 'Recently Added Movies');
      expect(hubs.single.items.single.title, 'Movie A');
      expect(httpClient.requests, hasLength(2));
      expect(httpClient.requests.map((r) => r.url.path), everyElement('/hubs'));
      expect(httpClient.requests.map((r) => r.url.queryParameters['count']), everyElement('12'));
    });

    test('fetchGlobalHubs retries transient failures without switching Plex endpoints', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      const primary = 'http://primary:32400';
      const fallback = 'http://fallback:32400';
      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('queued behind cold handshakes'),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: primary,
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
        prioritizedEndpoints: const [primary, fallback],
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 12);

      expect(hubs, hasLength(1));
      expect(client.config.baseUrl, primary);
      expect(httpClient.requests.map((r) => r.url.origin), everyElement(primary));
    });

    test('resets live base URL after fallback endpoint is exhausted', () async {
      const primary = 'http://primary:32400';
      const fallback = 'http://fallback:32400';
      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('primary down'),
        (_) async => throw TimeoutException('fallback down'),
        (_) async => _jsonResponse({
          'MediaContainer': {'machineIdentifier': 'server-id'},
        }),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: primary,
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
        prioritizedEndpoints: const [primary, fallback],
      );
      addTearDown(client.close);

      await expectLater(client.getServerIdentity(), throwsA(isA<Object>()));

      expect(client.config.baseUrl, primary);
      expect(httpClient.requests.map((r) => r.url.origin), [primary, fallback]);

      await client.getServerIdentity();
      expect(httpClient.requests.map((r) => r.url.origin), [primary, fallback, primary]);
    });

    test('fetchGlobalHubs uses promoted hub endpoint advertised by media providers', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_mediaProvidersPayload()),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = await PlexClient.create(
        PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
        seedTranscoderVideoSupport: true,
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 12);

      expect(hubs, hasLength(1));
      expect(hubs.single.title, 'Recently Added Movies');
      expect(httpClient.requests.map((r) => r.url.path), ['/media/providers', '/hubs/promoted']);
      expect(httpClient.requests.last.url.queryParameters['count'], '12');
    });

    test('fetchContinueWatching uses advertised provider feature endpoint', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_mediaProvidersPayload()),
        (_) async => _jsonResponse(_continueWatchingPayload()),
      ]);
      final client = await PlexClient.create(
        PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
        seedTranscoderVideoSupport: true,
      );
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: 21);

      expect(items, hasLength(1));
      expect(items.single.title, 'Movie A');
      expect(httpClient.requests.map((r) => r.url.path), ['/media/providers', '/hubs/continueWatching']);
      expect(httpClient.requests.last.url.queryParameters['count'], '21');
      expect(httpClient.requests.last.url.queryParameters['includeGuids'], '1');
      expect(httpClient.requests.last.url.queryParameters.containsKey('identifier'), isFalse);
    });

    test('fetchContinueWatching omits count when uncapped', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([(_) async => _jsonResponse(_continueWatchingPayload())]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: null);

      expect(items, hasLength(1));
      expect(items.single.title, 'Movie A');
      expect(httpClient.requests.single.url.path, '/hubs');
      expect(httpClient.requests.single.url.queryParameters['identifier'], 'home.continue,home.ondeck');
      expect(httpClient.requests.single.url.queryParameters.containsKey('count'), isFalse);
      expect(httpClient.requests.single.url.queryParameters['includeGuids'], '1');
    });

    test('fetchLibraryHubs retries transient failures without switching Plex endpoints', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      const primary = 'http://primary:32400';
      const fallback = 'http://fallback:32400';
      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('queued behind image downloads'),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: primary,
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
        prioritizedEndpoints: const [primary, fallback],
      );
      addTearDown(client.close);

      final hubs = await client.fetchLibraryHubs('4', libraryName: 'Movies', limit: 12);

      expect(hubs, hasLength(1));
      expect(hubs.single.items.single.libraryId, '4');
      expect(hubs.single.items.single.libraryTitle, 'Movies');
      expect(client.config.baseUrl, primary);
      expect(httpClient.requests, hasLength(2));
      expect(httpClient.requests.map((r) => r.url.origin), everyElement(primary));
      expect(httpClient.requests.map((r) => r.url.path), everyElement('/hubs/sections/4'));
      expect(httpClient.requests.map((r) => r.url.queryParameters['count']), everyElement('12'));
    });
  });
}

Future<http.StreamedResponse> _jsonResponse(Map<String, dynamic> body) async {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _globalHubsPayload() => {
  'MediaContainer': {
    'Hub': [
      {
        'key': '/hubs/movie.recentlyAdded',
        'title': 'Recently Added Movies',
        'type': 'movie',
        'hubIdentifier': 'movie.recentlyAdded.1',
        'size': 1,
        'Metadata': [
          {'ratingKey': '1', 'type': 'movie', 'title': 'Movie A'},
        ],
      },
    ],
  },
};

Map<String, dynamic> _continueWatchingPayload() => {
  'MediaContainer': {
    'Hub': [
      {
        'key': '/hubs/home/continueWatching',
        'title': 'Continue Watching',
        'type': 'mixed',
        'hubIdentifier': 'home.continue',
        'size': 1,
        'more': false,
        'Metadata': [
          {'ratingKey': '1', 'type': 'movie', 'title': 'Movie A'},
        ],
      },
    ],
  },
};

Map<String, dynamic> _mediaProvidersPayload() => {
  'MediaContainer': {
    'MediaProvider': [
      {
        'identifier': 'com.plexapp.plugins.library',
        'Feature': [
          {
            'type': 'content',
            'Directory': [
              {'title': 'Home', 'hubKey': '/hubs'},
              {
                'id': '1',
                'key': '/library/sections/1',
                'hubKey': '/hubs/sections/1',
                'type': 'movie',
                'title': 'Movies',
              },
            ],
          },
          {'type': 'promoted', 'key': '/hubs/promoted'},
          {'type': 'continuewatching', 'key': '/hubs/continueWatching'},
        ],
      },
    ],
  },
};
