import 'dart:async';
import 'package:plezy/media/ids.dart';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

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
  group('PlexConfig language headers', () {
    test('includes Plex language headers when configured', () {
      final config = PlexConfig(
        baseUrl: 'http://server:32400',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
        languageCode: 'fr',
      );

      expect(config.headers['Accept-Language'], 'fr');
      expect(config.headers['X-Plex-Language'], 'fr');
    });

    test('copyWith preserves language headers when refreshing the token', () {
      final config = PlexConfig(
        baseUrl: 'http://server:32400',
        token: 'old-token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
        languageCode: 'es',
      ).copyWith(token: 'new-token');

      expect(config.headers['X-Plex-Token'], 'new-token');
      expect(config.headers['Accept-Language'], 'es');
      expect(config.headers['X-Plex-Language'], 'es');
    });
  });

  group('PlexClient home hub retries', () {
    test('fetchGlobalHubs retries a first-attempt connection error', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => throw http.ClientException('connection reset on cold Plex start'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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

    test('fetchGlobalHubs does not replay a hub row that timed out', () async {
      // `Client.send` resolves on response headers, so a hub timeout usually
      // means the server is still working on the query. Replaying it made the
      // server start over on a shorter budget — the #1784 cold-start stall.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('server still building the hub'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      // `_fetchHubs` degrades a failed row to empty rather than sinking home.
      expect(await client.fetchGlobalHubs(limit: 12), isEmpty);
      expect(httpClient.requests, hasLength(1));
    });

    test('fetchGlobalHubs sends configured Plex language headers', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([(_) async => _jsonResponse(_globalHubsPayload())]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
          languageCode: 'fr',
        ),
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      await client.fetchGlobalHubs(limit: 12);

      expect(httpClient.requests.single.headers['Accept-Language'], 'fr');
      expect(httpClient.requests.single.headers['X-Plex-Language'], 'fr');
    });

    test('applyLanguageUpdate refreshes headers on the live HTTP client', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_globalHubsPayload()),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
          languageCode: 'en',
        ),
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      await client.fetchGlobalHubs(limit: 12);
      client.applyLanguageUpdate('fr');
      await client.fetchGlobalHubs(limit: 12);

      expect(httpClient.requests[0].headers['Accept-Language'], 'en');
      expect(httpClient.requests[0].headers['X-Plex-Language'], 'en');
      expect(httpClient.requests[1].headers['Accept-Language'], 'fr');
      expect(httpClient.requests[1].headers['X-Plex-Language'], 'fr');
    });

    test('fetchGlobalHubs retries a connection error without switching Plex endpoints', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      const primary = 'http://primary:32400';
      const fallback = 'http://fallback:32400';
      final httpClient = _SequenceClient([
        (_) async => throw http.ClientException('connection reset'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
        serverName: 'Server',
        httpClient: httpClient,
        prioritizedEndpoints: const [primary, fallback],
        // The candidate must validate for the cascade to reach the
        // authenticated retry whose failure this test pins.
        endpointProbeHttpClientFactory: () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': 'server-id'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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

    test('fetchLibraryHubs retries a connection error without switching Plex endpoints', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      const primary = 'http://primary:32400';
      const fallback = 'http://fallback:32400';
      final httpClient = _SequenceClient([
        (_) async => throw http.ClientException('connection reset'),
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
        serverId: ServerId('server-id'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
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

  group('PlexClient continue-watching logo backfill', () {
    test('episodes without an inherited logo get the show logo stamped', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_continueWatchingEpisodePayload()),
        (_) async => _jsonResponse(_showWithLogoPayload()),
      ]);
      final client = _continueWatchingTestClient(httpClient);
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: 10);

      expect(items.single.clearLogoPath, '/library/metadata/show-1/clearLogo/123');
      expect(httpClient.requests.map((r) => r.url.path), ['/hubs', '/library/metadata/show-1']);
    });

    test('movies and episodes with a logo cost no extra requests', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([(_) async => _jsonResponse(_continueWatchingWithLogosPayload())]);
      final client = _continueWatchingTestClient(httpClient);
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: 10);

      expect(items, hasLength(2));
      expect(items[0].clearLogoPath, '/library/metadata/movie-1/clearLogo/456');
      expect(items[1].clearLogoPath, '/library/metadata/show-2/clearLogo/789');
      expect(httpClient.requests.single.url.path, '/hubs');
    });

    test('a failed show lookup never fails the shelf', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_continueWatchingEpisodePayload()),
        (_) async => http.StreamedResponse(Stream.value(utf8.encode('Internal error')), 500),
      ]);
      final client = _continueWatchingTestClient(httpClient);
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: 10);

      expect(items.single.clearLogoPath, isNull);
      expect(httpClient.requests, hasLength(2));
    });

    test('two shows missing logos resolve in one bulk request', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => _jsonResponse(_continueWatchingTwoEpisodesPayload()),
        (_) async => _jsonResponse(_showsWithLogosPayload()),
      ]);
      final client = _continueWatchingTestClient(httpClient);
      addTearDown(client.close);

      final items = await client.fetchContinueWatching(count: 10);

      expect(items[0].clearLogoPath, '/library/metadata/show-1/clearLogo/123');
      expect(items[1].clearLogoPath, '/library/metadata/show-2/clearLogo/456');
      expect(httpClient.requests.map((r) => r.url.path), ['/hubs', '/library/metadata/show-1,show-2']);
    });
  });
}

PlexClient _continueWatchingTestClient(http.BaseClient httpClient) => PlexClient.forTesting(
  config: PlexConfig(
    baseUrl: 'http://server:32400',
    token: 'token',
    clientIdentifier: 'client-id',
    product: 'Plezy',
    version: 'test',
  ),
  serverId: ServerId('server-id'),
  profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'test-profile'),
  serverName: 'Server',
  httpClient: httpClient,
);

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

/// One episode row without any logo imagery — the pre-1.43 hub shape that
/// omits the show's inherited `clearLogo` image.
Map<String, dynamic> _continueWatchingEpisodePayload() => {
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
          {
            'ratingKey': 'ep-1',
            'type': 'episode',
            'title': 'Episode 1',
            'grandparentRatingKey': 'show-1',
            'grandparentTitle': 'Show 1',
          },
        ],
      },
    ],
  },
};

/// A movie and an episode that both carry their own `clearLogo` imagery.
Map<String, dynamic> _continueWatchingWithLogosPayload() => {
  'MediaContainer': {
    'Hub': [
      {
        'key': '/hubs/home/continueWatching',
        'title': 'Continue Watching',
        'type': 'mixed',
        'hubIdentifier': 'home.continue',
        'size': 2,
        'more': false,
        'Metadata': [
          {
            'ratingKey': 'movie-1',
            'type': 'movie',
            'title': 'Movie A',
            'Image': [
              {'type': 'clearLogo', 'url': '/library/metadata/movie-1/clearLogo/456'},
            ],
          },
          {
            'ratingKey': 'ep-2',
            'type': 'episode',
            'title': 'Episode 2',
            'grandparentRatingKey': 'show-2',
            'Image': [
              {'type': 'clearLogo', 'url': '/library/metadata/show-2/clearLogo/789'},
            ],
          },
        ],
      },
    ],
  },
};

Map<String, dynamic> _showWithLogoPayload() => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'show-1',
        'type': 'show',
        'title': 'Show 1',
        'Image': [
          {'type': 'clearLogo', 'url': '/library/metadata/show-1/clearLogo/123'},
        ],
      },
    ],
  },
};

/// Two episodes from different shows, both missing any logo imagery.
Map<String, dynamic> _continueWatchingTwoEpisodesPayload() => {
  'MediaContainer': {
    'Hub': [
      {
        'key': '/hubs/home/continueWatching',
        'title': 'Continue Watching',
        'type': 'mixed',
        'hubIdentifier': 'home.continue',
        'size': 2,
        'more': false,
        'Metadata': [
          {
            'ratingKey': 'ep-1',
            'type': 'episode',
            'title': 'Episode 1',
            'grandparentRatingKey': 'show-1',
            'grandparentTitle': 'Show 1',
          },
          {
            'ratingKey': 'ep-3',
            'type': 'episode',
            'title': 'Episode 3',
            'grandparentRatingKey': 'show-2',
            'grandparentTitle': 'Show 2',
          },
        ],
      },
    ],
  },
};

Map<String, dynamic> _showsWithLogosPayload() => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'show-1',
        'type': 'show',
        'title': 'Show 1',
        'Image': [
          {'type': 'clearLogo', 'url': '/library/metadata/show-1/clearLogo/123'},
        ],
      },
      {
        'ratingKey': 'show-2',
        'type': 'show',
        'title': 'Show 2',
        'Image': [
          {'type': 'clearLogo', 'url': '/library/metadata/show-2/clearLogo/456'},
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
