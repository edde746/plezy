import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

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

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: ServerId('plex-1'), serverName: 'Plex', handler: handler);

  test('search defaults to 100 movie, TV, music, and personal-media candidates', () async {
    final captured = <Uri>[];
    final client = makeClient((request) async {
      captured.add(request.url);
      if (request.url.path == '/library/search') {
        return _json({
          'MediaContainer': {
            'SearchResult': [
              {
                'score': 90,
                'Metadata': {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'The Movie'},
              },
            ],
          },
        });
      }
      return http.Response('unexpected request', 500);
    });
    addTearDown(client.close);

    final results = await client.searchItems('the');

    expect(results.map((item) => item.id), ['movie-1']);
    expect(captured, hasLength(1));
    expect(captured.single.path, '/library/search');
    expect(captured.single.queryParameters['limit'], '100');
    expect(captured.single.queryParameters['X-Plex-Container-Size'], '100');
    expect(captured.single.queryParameters['searchTypes'], 'movies,tv,music,otherVideos');
  });

  test('personal media rows are kept as movies', () async {
    // PMS answers `otherVideos` with `type: movie, subtype: clip` rows whose
    // guid names the Personal Media agent instead of a metadata provider.
    final client = makeClient((request) async {
      if (request.url.path != '/library/search') return http.Response('unexpected request', 500);
      return _json({
        'MediaContainer': {
          'SearchResult': [
            {
              'score': 0.53,
              'Metadata': {
                'ratingKey': '8964',
                'guid': 'tv.plex.agents.none://8964',
                'type': 'movie',
                'subtype': 'clip',
                'title': '2004 Family',
                'librarySectionTitle': 'Home Videos',
              },
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final results = await client.searchItems('2004');

    expect(results.map((item) => item.id), ['8964']);
  });

  test('search rows carry their library so hidden libraries can be filtered', () async {
    final client = makeClient((request) async {
      if (request.url.path != '/library/search') return http.Response('unexpected request', 500);
      return _json({
        'MediaContainer': {
          'SearchResult': [
            {
              'score': 90,
              'Metadata': {
                'ratingKey': 'movie-1',
                'type': 'movie',
                'title': 'The Movie',
                'librarySectionID': 2,
                'librarySectionTitle': 'Movies',
              },
            },
            // Older/edge responses name the section only by key.
            {
              'score': 80,
              'Metadata': {
                'ratingKey': 'show-1',
                'type': 'show',
                'title': 'The Show',
                'librarySectionKey': '/library/sections/7',
              },
            },
            // Shared/external media has no local section at all.
            {
              'score': 70,
              'Metadata': {'ratingKey': 'shared-1', 'type': 'movie', 'title': 'The Shared Movie'},
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final results = await client.searchItems('the');

    expect(results.map((item) => item.id), ['movie-1', 'show-1', 'shared-1']);
    expect(results.map((item) => item.libraryId), ['2', '7', null]);
    expect(results.map((item) => item.libraryGlobalKey), ['plex-1:2', 'plex-1:7', null]);
  });

  test('saturated mixed search supplements omitted media categories and deduplicates results', () async {
    final captured = <Uri>[];
    final primaryResults = <Map<String, Object>>[
      for (var index = 0; index < 99; index++)
        {
          'score': 90,
          'Metadata': {'ratingKey': 'movie-$index', 'type': 'movie', 'title': 'Target Movie $index'},
        },
      {
        'score': 10,
        'Metadata': {'ratingKey': 'collection-1', 'type': 'collection', 'title': 'Target Collection'},
      },
    ];
    final client = makeClient((request) async {
      captured.add(request.url);
      final searchTypes = request.url.queryParameters['searchTypes'];
      final searchResults = switch (searchTypes) {
        'movies,tv,music,otherVideos' => primaryResults,
        'tv' => [
          {
            'score': 100,
            'Metadata': {'ratingKey': 'show-1', 'type': 'show', 'title': 'Target'},
          },
          {
            'score': 90,
            'Metadata': {'ratingKey': 'movie-0', 'type': 'movie', 'title': 'Target Movie 0'},
          },
        ],
        'music' => [
          {
            'score': 100,
            'Metadata': {'ratingKey': 'artist-1', 'type': 'artist', 'title': 'Target'},
          },
        ],
        'otherVideos' => [
          {
            'score': 100,
            'Metadata': {
              'ratingKey': 'home-1',
              'guid': 'tv.plex.agents.none://home-1',
              'type': 'movie',
              'title': 'Target Home Video',
            },
          },
        ],
        _ => <Map<String, Object>>[],
      };
      return _json({
        'MediaContainer': {'SearchResult': searchResults},
      });
    });
    addTearDown(client.close);

    final results = await client.searchItems('Target');
    final ids = results.map((item) => item.id).toList();

    expect(captured.map((uri) => uri.queryParameters['searchTypes']).toSet(), {
      'movies,tv,music,otherVideos',
      'tv',
      'music',
      'otherVideos',
    });
    expect(ids.where((id) => id == 'movie-0'), hasLength(1));
    expect(ids, containsAll(['show-1', 'artist-1', 'home-1']));
    expect(ids, hasLength(102));
  });

  test('saturated personal-media results still fetch the movies category', () async {
    final captured = <String?>[];
    final client = makeClient((request) async {
      final searchTypes = request.url.queryParameters['searchTypes'];
      captured.add(searchTypes);
      final searchResults = switch (searchTypes) {
        'movies,tv,music,otherVideos' => [
          for (var index = 0; index < 100; index++)
            {
              'score': 90,
              'Metadata': {
                'ratingKey': 'home-$index',
                'guid': 'tv.plex.agents.none://home-$index',
                'type': 'movie',
                'title': 'Target Clip $index',
              },
            },
        ],
        'movies' => [
          {
            'score': 100,
            'Metadata': {'ratingKey': 'movie-1', 'guid': 'plex://movie/1', 'type': 'movie', 'title': 'Target'},
          },
        ],
        _ => <Map<String, Object>>[],
      };
      return _json({
        'MediaContainer': {'SearchResult': searchResults},
      });
    });
    addTearDown(client.close);

    final results = await client.searchItems('Target');

    expect(captured.toSet(), {'movies,tv,music,otherVideos', 'movies', 'tv', 'music'});
    expect(results.map((item) => item.id), contains('movie-1'));
    expect(results, hasLength(101));
  });

  test('supplemental category failure keeps saturated primary results', () async {
    final capturedSearchTypes = <String?>[];
    final primaryResults = <Map<String, Object>>[
      for (var index = 0; index < 99; index++)
        {
          'score': 90,
          'Metadata': {'ratingKey': 'movie-$index', 'type': 'movie', 'title': 'Target Movie $index'},
        },
      {
        'score': 80,
        'Metadata': {'ratingKey': 'artist-1', 'type': 'artist', 'title': 'Target Artist'},
      },
    ];
    final client = makeClient((request) async {
      final searchTypes = request.url.queryParameters['searchTypes'];
      capturedSearchTypes.add(searchTypes);
      if (searchTypes == 'movies,tv,music,otherVideos') {
        return _json({
          'MediaContainer': {'SearchResult': primaryResults},
        });
      }
      return http.Response('temporary failure', 500);
    });
    addTearDown(client.close);

    final results = await client.searchItems('Target');

    expect(capturedSearchTypes, ['movies,tv,music,otherVideos', 'tv', 'otherVideos']);
    expect(results, hasLength(100));
    expect(results.map((item) => item.id), containsAll(['movie-0', 'artist-1']));
  });
}
