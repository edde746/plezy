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
      title: 'Legacy Movie',
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
      title: 'Legacy Show',
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
      title: 'Duplicate',
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
      title: 'Missing Year',
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
      title: 'Unsupported',
    );

    expect(match, isNull);
  });
}
