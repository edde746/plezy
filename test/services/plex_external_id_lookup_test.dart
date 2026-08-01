import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/external_ids.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('falls back to an official legacy scalar guid without changing the request contract', () async {
    late Uri requestUri;
    final client = testPlexClient(
      handler: (request) async {
        requestUri = request.url;
        return _json({
          'MediaContainer': {
            'Metadata': [
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
            ],
          },
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(imdb: 'tt29768334'),
      kind: MediaKind.movie,
      titles: const ['Legacy Movie'],
    );

    expect(match?.id, 'legacy-movie');
    expect(match?.libraryId, '5');
    expect(match?.libraryTitle, 'Legacy Movies');
    expect(match?.serverId, 'server-1');
    expect(match?.serverName, 'Server');
    expect(requestUri.path, '/library/all');
    expect(requestUri.queryParameters['title'], 'Legacy Movie');
    expect(requestUri.queryParameters['type'], '1');
    expect(requestUri.queryParameters['includeGuids'], '1');
    expect(requestUri.queryParameters['X-Plex-Container-Size'], '20');
    expect(requestUri.queryParameters.containsKey('guid'), isFalse);
  });

  test('matches a HAMA show guid', () async {
    final client = testPlexClient(
      handler: (request) async => _json({
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': 'legacy-show',
              'type': 'show',
              'title': 'Legacy Show',
              'guid': 'com.plexapp.agents.hama://tvdb4-315500?lang=en',
            },
          ],
        },
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tvdb: 315500),
      kind: MediaKind.show,
      titles: const ['Legacy Show'],
    );

    expect(match?.id, 'legacy-show');
  });

  test('prefers a modern Guid match over an earlier legacy candidate', () async {
    final client = testPlexClient(
      handler: (request) async => _json({
        'MediaContainer': {
          'Metadata': [
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
          ],
        },
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(imdb: 'tt12345'),
      kind: MediaKind.movie,
      titles: const ['Duplicate'],
    );

    expect(match?.id, 'modern-match');
  });

  test('prefers an unfiltered modern match over a year-filtered legacy candidate', () async {
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        final isFiltered = request.url.queryParameters.containsKey('year');
        return _json({
          'MediaContainer': {
            'Metadata': [
              if (isFiltered)
                {
                  'ratingKey': 'filtered-legacy',
                  'type': 'movie',
                  'title': 'Missing Year',
                  'guid': 'com.plexapp.agents.themoviedb://42',
                }
              else
                {
                  'ratingKey': 'unfiltered-modern',
                  'type': 'movie',
                  'title': 'Missing Year',
                  'guid': 'plex://movie/modern',
                  'Guid': [
                    {'id': 'tmdb://42'},
                  ],
                },
            ],
          },
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tmdb: 42),
      kind: MediaKind.movie,
      titles: const ['Missing Year'],
      year: 2024,
    );

    expect(match?.id, 'unfiltered-modern');
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters['year'], '2023,2024,2025');
    expect(requests.last.queryParameters.containsKey('year'), isFalse);
  });

  test('does not match unsupported or malformed scalar GUIDs', () async {
    final client = testPlexClient(
      handler: (request) async => _json({
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': 'anidb',
              'type': 'show',
              'title': 'Unsupported',
              'guid': 'com.plexapp.agents.hama://anidb-11905',
            },
            {'ratingKey': 'wrong-shape', 'type': 'show', 'title': 'Unsupported', 'guid': 315500},
          ],
        },
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tvdb: 315500),
      kind: MediaKind.show,
      titles: const ['Unsupported'],
    );

    expect(match, isNull);
  });

  test('tries broader title candidates in order and still verifies external ids', () async {
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        if (request.url.queryParameters['title'] == 'Parent Show Season 2') {
          return _json({
            'MediaContainer': {'Metadata': <Object>[]},
          });
        }
        return _json({
          'MediaContainer': {
            'Metadata': [
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
            ],
          },
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tvdb: 123),
      kind: MediaKind.show,
      titles: const ['Parent Show Season 2', 'Parent Show'],
    );

    expect(match?.id, 'verified-parent');
    expect(requests.map((uri) => uri.queryParameters['title']), ['Parent Show Season 2', 'Parent Show']);
    expect(requests.first.queryParameters['X-Plex-Container-Size'], '20');
    expect(requests.last.queryParameters['X-Plex-Container-Size'], '50');
  });

  test('uses an exact Plex guid without external ids or a title query', () async {
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return _json({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': 'exact-show',
                'type': 'show',
                'title': 'Exact Show',
                'guid': 'plex://show/5e01fc33932ff9001db3b242',
              },
            ],
          },
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(),
      kind: MediaKind.show,
      titles: const ['Never Searched'],
      plexGuid: 'plex://show/5e01fc33932ff9001db3b242',
    );

    expect(match?.id, 'exact-show');
    expect(requests, hasLength(1));
    expect(requests.single.path, '/library/all');
    expect(requests.single.queryParameters['guid'], 'plex://show/5e01fc33932ff9001db3b242');
    expect(requests.single.queryParameters['type'], '2');
    expect(requests.single.queryParameters['includeGuids'], '1');
    expect(requests.single.queryParameters.containsKey('title'), isFalse);
  });

  test('a guid-only lookup stops after the exact guid miss', () async {
    // Title attempts verify candidates by external-id intersection, so with
    // no external ids they can never confirm anything — the guid miss must
    // be the lookup's only request (#1715).
    final requests = <Uri>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request.url);
        return _json({
          'MediaContainer': {'Metadata': <Object>[]},
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(),
      kind: MediaKind.movie,
      titles: const ['Night on the Galactic Railroad'],
      plexGuid: 'plex://movie/5d776b59ad5437001f79c6f8',
    );

    expect(match, isNull);
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['guid'], 'plex://movie/5d776b59ad5437001f79c6f8');
    expect(requests.single.queryParameters.containsKey('title'), isFalse);
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
        final complete = request.url.queryParameters['title'] == 'Complete Show';
        return _json({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': complete ? 'complete-show' : 'incomplete-show',
                'type': 'show',
                'title': complete ? 'Complete Show' : 'Incomplete Show',
                'librarySectionID': 4,
                'Guid': [
                  {'id': 'tvdb://${complete ? 101 : 100}'},
                ],
              },
            ],
          },
        });
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

    expect(missing, isNull);
    expect(present?.id, 'complete-show');
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
        return _json({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': 'ungated-show',
                'type': 'show',
                'title': 'Ungated Show',
                'librarySectionID': 9,
                'Guid': [
                  {'id': 'tvdb://300'},
                ],
              },
            ],
          },
        });
      },
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tvdb: 300),
      kind: MediaKind.show,
      titles: const ['Ungated Show'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 1),
    );

    expect(match?.id, 'ungated-show');
    expect(requests.map((uri) => uri.path), ['/library/all'], reason: 'no children, no preferences');
  });
}
