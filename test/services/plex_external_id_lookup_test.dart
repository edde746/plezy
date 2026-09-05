import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/external_ids.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

/// A `/library/all` page.
http.Response _metadata(List<Object> rows) => _json({
  'MediaContainer': {'Metadata': rows},
});

/// A `/hubs/search` answer: the hub of [type] plus the episode hub Plex
/// always adds to a `tv` search, so a lookup that read every hub would leak
/// episodes into the match list.
http.Response _hubs(List<Object> rows, {String type = 'movie'}) => _json({
  'MediaContainer': {
    'Hub': [
      {'type': type, 'hubIdentifier': type, 'Metadata': rows},
      {
        'type': 'episode',
        'hubIdentifier': 'episode',
        'Metadata': [
          {
            'ratingKey': 'stray-episode',
            'type': 'episode',
            'title': 'Pilot',
            'Guid': [
              {'id': 'tvdb://123'},
              {'id': 'tmdb://42'},
              {'id': 'imdb://tt12345'},
            ],
          },
        ],
      },
    ],
  },
});

bool _isTitleSearch(http.Request request) => request.url.path == '/hubs/search';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('searches the title through the hub search index and reads the legacy scalar guid', () async {
    late Uri requestUri;
    final client = testPlexClient(
      handler: (request) async {
        requestUri = request.url;
        return _hubs([
          {
            'ratingKey': 'legacy-movie',
            'type': 'movie',
            'title': 'Legacy Movie',
            'librarySectionID': 5,
            'librarySectionTitle': 'Legacy Movies',
            'guid': 'com.plexapp.agents.imdb://tt29768334?lang=en',
            'Guid': [
              {'id': 'tmdb://999'},
            ],
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(imdb: 'tt29768334'),
      kind: MediaKind.movie,
      titles: const ['Legacy Movie'],
    );

    expect(matches.map((match) => match.id), ['legacy-movie']);
    expect(matches.single.libraryId, '5');
    expect(matches.single.libraryTitle, 'Legacy Movies');
    expect(matches.single.serverId, 'server-1');
    expect(matches.single.serverName, 'Server');
    // #2098: `/library/all?title=` is a word-prefix substring match that
    // cannot find `[Oshi no Ko]` from `Oshi no Ko`; the search index can.
    expect(requestUri.path, '/hubs/search');
    expect(requestUri.queryParameters['query'], 'Legacy Movie');
    expect(requestUri.queryParameters['searchTypes'], 'movies');
    expect(requestUri.queryParameters['includeGuids'], '1');
    expect(requestUri.queryParameters['limit'], '50');
    expect(requestUri.queryParameters.containsKey('guid'), isFalse);
    expect(requestUri.queryParameters.containsKey('year'), isFalse, reason: 'the index ranks; no year window');
  });

  test('a show search reads the show hub only, never the episode hub', () async {
    late Uri requestUri;
    final client = testPlexClient(
      handler: (request) async {
        requestUri = request.url;
        return _hubs(type: 'show', [
          {
            'ratingKey': 'legacy-show',
            'type': 'show',
            'title': 'Legacy Show',
            'guid': 'com.plexapp.agents.hama://tvdb4-315500?lang=en',
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(tvdb: 315500, tmdb: 42),
      kind: MediaKind.show,
      titles: const ['Legacy Show'],
    );

    expect(matches.map((match) => match.id), ['legacy-show']);
    expect(requestUri.queryParameters['searchTypes'], 'tv');
  });

  test('returns both agent variants of one title, modern Guid match first', () async {
    final client = testPlexClient(
      handler: (request) async => _hubs([
        {
          'ratingKey': 'legacy-match',
          'type': 'movie',
          'title': 'Duplicate',
          'guid': 'com.plexapp.agents.imdb://tt12345',
        },
        {
          'ratingKey': 'modern-match',
          'type': 'movie',
          'title': 'Duplicate',
          'guid': 'plex://movie/modern',
          'Guid': [
            {'id': 'imdb://tt12345'},
          ],
        },
      ]),
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(imdb: 'tt12345'),
      kind: MediaKind.movie,
      titles: const ['Duplicate'],
    );

    // Two rating keys, so two library items — the modern-agent copy leads.
    expect(matches.map((match) => match.id), ['modern-match', 'legacy-match']);
  });

  test('does not match unsupported or malformed scalar GUIDs', () async {
    final client = testPlexClient(
      handler: (request) async => _hubs(type: 'show', [
        {'ratingKey': 'anidb', 'type': 'show', 'title': 'Unsupported', 'guid': 'com.plexapp.agents.hama://anidb-11905'},
        {'ratingKey': 'wrong-shape', 'type': 'show', 'title': 'Unsupported', 'guid': 315500},
      ]),
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(tvdb: 315500),
      kind: MediaKind.show,
      titles: const ['Unsupported'],
    );

    expect(matches, isEmpty);
  });

  test('searches every title candidate and unions their id-verified copies', () async {
    // #2098: a copy filed under another language's title is reachable only
    // through that title, so a title that hit must not stop its siblings —
    // and id verification keeps the wrong show out of every page.
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return switch (request.url.queryParameters['query']) {
          'Parent Show Season 2' => _hubs(type: 'show', const []),
          'Parent Show' => _hubs(type: 'show', [
            {
              'ratingKey': 'wrong-parent',
              'type': 'show',
              'title': 'Parent Show',
              'Guid': [
                {'id': 'tvdb://999'},
              ],
            },
            {
              'ratingKey': 'verified-parent',
              'type': 'show',
              'title': 'Parent Show',
              'Guid': [
                {'id': 'tvdb://123'},
              ],
            },
          ]),
          _ => _hubs(type: 'show', [
            {
              'ratingKey': 'romaji-parent',
              'type': 'show',
              'title': 'Oya Bangumi',
              'librarySectionTitle': 'Anime (romaji)',
              'Guid': [
                {'id': 'tvdb://123'},
              ],
            },
            {
              'ratingKey': 'verified-parent',
              'type': 'show',
              'title': 'Parent Show',
              'Guid': [
                {'id': 'tvdb://123'},
              ],
            },
          ]),
        };
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(tvdb: 123),
      kind: MediaKind.show,
      titles: const ['Parent Show Season 2', 'Parent Show', 'Oya Bangumi'],
    );

    expect(matches.map((match) => match.id), ['verified-parent', 'romaji-parent']);
    expect(requests.map((uri) => uri.queryParameters['query']), ['Parent Show Season 2', 'Parent Show', 'Oya Bangumi']);
  });

  test('uses an exact Plex guid without external ids or a title query', () async {
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return _metadata([
          {
            'ratingKey': 'exact-show',
            'type': 'show',
            'title': 'Exact Show',
            'guid': 'plex://show/5e01fc33932ff9001db3b242',
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(),
      kind: MediaKind.show,
      titles: const ['Never Searched'],
      plexGuid: 'plex://show/5e01fc33932ff9001db3b242',
    );

    expect(matches.map((match) => match.id), ['exact-show']);
    expect(requests, hasLength(1));
    expect(requests.single.path, '/library/all');
    expect(requests.single.queryParameters['guid'], 'plex://show/5e01fc33932ff9001db3b242');
    expect(requests.single.queryParameters['type'], '2');
    expect(requests.single.queryParameters['includeGuids'], '1');
    expect(requests.single.queryParameters.containsKey('query'), isFalse);
  });

  test('a guid-only lookup stops after the exact guid miss', () async {
    // Title searches verify candidates by external-id intersection, so with
    // no external ids they can never confirm anything — the guid miss must
    // be the lookup's only request (#1715).
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return _metadata(const []);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(),
      kind: MediaKind.movie,
      titles: const ['Night on the Galactic Railroad'],
      plexGuid: 'plex://movie/5d776b59ad5437001f79c6f8',
    );

    expect(matches, isEmpty);
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['guid'], 'plex://movie/5d776b59ad5437001f79c6f8');
  });

  test('an agreed season ref gates on the season hierarchy and nothing else', () async {
    final childRequests = <String>[];
    final extraRequests = <String>[];
    final client = testPlexClient(
      handler: (request) async {
        if (request.url.queryParameters.containsKey('includePreferences') || request.url.path.endsWith('/prefs')) {
          extraRequests.add(request.url.path);
        }
        if (request.url.path.endsWith('/children')) {
          childRequests.add(request.url.path);
          final parentId = request.url.pathSegments[2];
          return _json({
            'MediaContainer': {
              'totalSize': 1,
              'Metadata': [
                {
                  'ratingKey': '$parentId-season',
                  'type': 'season',
                  'title': 'Season',
                  'index': parentId == 'complete-show' ? 2 : 1,
                },
              ],
            },
          });
        }
        if (request.url.path.startsWith('/library/metadata/')) {
          return _json({'MediaContainer': <String, Object?>{}});
        }
        final complete = request.url.queryParameters['query'] == 'Complete Show';
        return _hubs(type: 'show', [
          {
            'ratingKey': complete ? 'complete-show' : 'incomplete-show',
            'type': 'show',
            'title': complete ? 'Complete Show' : 'Incomplete Show',
            'librarySectionID': 4,
            'Guid': [
              {'id': 'tvdb://${complete ? 101 : 100}'},
            ],
          },
        ]);
      },
    );
    addTearDown(client.close);

    final missing = await client.findByExternalIds(
      const ExternalIds(tvdb: 100),
      kind: MediaKind.show,
      titles: const ['Incomplete Show'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 2),
    );
    final present = await client.findByExternalIds(
      const ExternalIds(tvdb: 101),
      kind: MediaKind.show,
      titles: const ['Complete Show'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 2),
    );

    expect(missing, isEmpty);
    expect(present.map((match) => match.id), ['complete-show']);
    expect(childRequests, ['/library/metadata/incomplete-show/children', '/library/metadata/complete-show/children']);
    expect(extraRequests, isEmpty, reason: 'season ordering is a server setting the gate deliberately never reads');
  });

  test('a disagreeing season ref is left ungated rather than gated on a guess', () async {
    // TVDB says season 2, TMDB folds it into season 1. Which one this library
    // follows is a server setting no dataset supplies, and reading it costs
    // requests, so the match stands ungated.
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return _hubs(type: 'show', [
          {
            'ratingKey': 'ungated-show',
            'type': 'show',
            'title': 'Ungated Show',
            'librarySectionID': 9,
            'Guid': [
              {'id': 'tvdb://300'},
            ],
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(tvdb: 300),
      kind: MediaKind.show,
      titles: const ['Ungated Show'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 1),
    );

    expect(matches.map((match) => match.id), ['ungated-show']);
    expect(requests.map((uri) => uri.path), ['/hubs/search'], reason: 'no children, no preferences');
  });

  test('returns every library copy sharing one exact Plex guid', () async {
    // #1754: `/library/all` is server-wide, so a movie held by both a 4K
    // section and an HD section answers with two sibling entries. Taking
    // Metadata[0] is what hid the second copy from the Explore chooser.
    final client = testPlexClient(
      handler: (request) async => _metadata([
        {
          'ratingKey': 'hd-copy',
          'type': 'movie',
          'title': 'Dual Library',
          'guid': 'plex://movie/dual',
          'librarySectionID': 1,
          'librarySectionTitle': 'Movies',
          'Media': [
            {'id': 10, 'videoResolution': '1080', 'videoCodec': 'h264', 'container': 'mkv'},
          ],
        },
        {
          'ratingKey': 'uhd-copy',
          'type': 'movie',
          'title': 'Dual Library',
          'guid': 'plex://movie/dual',
          'librarySectionID': 2,
          'librarySectionTitle': '4K Movies',
          'Media': [
            {'id': 20, 'videoResolution': '4k', 'videoCodec': 'hevc', 'container': 'mkv'},
          ],
        },
      ]),
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(),
      kind: MediaKind.movie,
      titles: const [],
      plexGuid: 'plex://movie/dual',
    );

    expect(matches.map((match) => match.id), ['hd-copy', 'uhd-copy']);
    expect(matches.map((match) => match.libraryId), ['1', '2']);
    expect(matches.map((match) => match.libraryTitle), ['Movies', '4K Movies']);
    expect(matches.map((match) => match.mediaVersions?.single.videoResolution), ['1080', '4k']);
  });

  test('keeps searching by title after an exact guid hit so legacy-agent copies surface', () async {
    // A library still on a legacy agent carries `com.plexapp.agents.*` as its
    // primary guid, so the `guid=` filter cannot see it at all (#1754). The
    // copy the two passes agree on must still appear only once.
    final requests = <Uri>[];
    final modernCopy = {
      'ratingKey': 'modern-copy',
      'type': 'movie',
      'title': 'Mixed Agents',
      'guid': 'plex://movie/mixed',
      'librarySectionTitle': '4K Movies',
      'Guid': [
        {'id': 'imdb://tt777'},
      ],
    };
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        if (!_isTitleSearch(request)) return _metadata([modernCopy]);
        return _hubs([
          modernCopy,
          {
            'ratingKey': 'legacy-copy',
            'type': 'movie',
            'title': 'Mixed Agents',
            'guid': 'com.plexapp.agents.imdb://tt777?lang=en',
            'librarySectionTitle': 'Movies',
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(imdb: 'tt777'),
      kind: MediaKind.movie,
      titles: const ['Mixed Agents'],
      plexGuid: 'plex://movie/mixed',
    );

    expect(matches.map((match) => match.id), ['modern-copy', 'legacy-copy']);
    expect(requests.map((uri) => uri.path), ['/library/all', '/hubs/search']);
  });

  test('season-gates every candidate, not just the first', () async {
    final client = testPlexClient(
      handler: (request) async {
        if (request.url.path.endsWith('/children')) {
          final parentId = request.url.pathSegments[2];
          return _json({
            'MediaContainer': {
              'totalSize': 1,
              'Metadata': [
                {
                  'ratingKey': '$parentId-season',
                  'type': 'season',
                  'title': 'Season',
                  'index': parentId == 'full-copy' ? 2 : 1,
                },
              ],
            },
          });
        }
        if (request.url.path.startsWith('/library/metadata/')) {
          return _json({'MediaContainer': <String, Object?>{}});
        }
        return _hubs(type: 'show', [
          {
            'ratingKey': 'partial-copy',
            'type': 'show',
            'title': 'Split Show',
            'librarySectionTitle': 'Shows',
            'Guid': [
              {'id': 'tvdb://555'},
            ],
          },
          {
            'ratingKey': 'full-copy',
            'type': 'show',
            'title': 'Split Show',
            'librarySectionTitle': '4K Shows',
            'Guid': [
              {'id': 'tvdb://555'},
            ],
          },
        ]);
      },
    );
    addTearDown(client.close);

    final matches = await client.findByExternalIds(
      const ExternalIds(tvdb: 555),
      kind: MediaKind.show,
      titles: const ['Split Show'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 2),
    );

    expect(matches.map((match) => match.id), ['full-copy']);
  });

  test('a server that cannot answer fails the lookup without cascading through its endpoints', () async {
    // #2098: a slow or erroring server is not evidence the title is absent —
    // the caller must see a failure, not an empty page — and it is not a
    // dead endpoint either, so the lookup must not move the client onto the
    // next candidate the way a request left on the default policy would.
    final requestsByHost = <String, int>{};
    var exhausted = 0;
    final client = testPlexClient(
      baseUrl: 'https://primary.example.com',
      prioritizedEndpoints: const ['https://primary.example.com', 'https://secondary.example.com'],
      onAllEndpointsExhausted: () => exhausted++,
      handler: (request) async {
        requestsByHost.update(request.url.host, (count) => count + 1, ifAbsent: () => 1);
        return http.Response('busy', 503);
      },
    );
    addTearDown(client.close);

    await expectLater(
      client.findByExternalIds(const ExternalIds(tmdb: 42), kind: MediaKind.movie, titles: const ['Busy Movie']),
      throwsA(isA<MediaServerHttpException>()),
    );
    expect(requestsByHost, {'primary.example.com': 1});
    expect(exhausted, 0);
  });
}
