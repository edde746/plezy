import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/mdblist_catalog_source.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_client.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: now + 86400,
    createdAt: now - 3600,
    username: 'alice',
  );
}

Map<String, dynamic> _watchlistBody() => {
  'movies': [
    {
      'id': 603,
      'title': 'The Matrix',
      'imdb_id': 'tt0133093',
      'release_year': 1999,
      'watchlist_at': '2026-01-03T12:34:56Z',
      'description': 'A hacker discovers the truth.',
      'genres': ['action', 'science-fiction'],
      'poster': 'https://image.tmdb.org/matrix.jpg',
      'ids': {'imdb': 'tt0133093', 'tmdb': 603},
    },
  ],
  'shows': [
    {
      'id': 95396,
      'title': 'Severance',
      'imdb_id': 'tt11280740',
      'tvdb_id': 371980,
      'release_year': 2022,
      'ids': {'imdb': 'tt11280740', 'tmdb': 95396, 'tvdb': 371980},
    },
  ],
  'pagination': {'total_movies': 1, 'total_shows': 1, 'has_more': false},
};

/// `GET /imdb/movie/tt0111161` as recorded in lzblack/douban-rankings' test fixtures (MIT), trimmed.
Map<String, dynamic> _shawshankBody() => {
  'title': 'The Shawshank Redemption',
  'year': 1994,
  'score': 89,
  'ratings': [
    {'source': 'imdb', 'value': 9.3, 'score': 93, 'votes': 3207270, 'url': 43},
    {'source': 'metacritic', 'value': 82, 'score': 82, 'votes': 22, 'url': '/the-shawshank-redemption'},
    {'source': 'metacriticuser', 'value': 9.3, 'score': 93, 'votes': 2198, 'url': null},
    {'source': 'trakt', 'value': 91, 'score': 91, 'votes': 43118, 'url': null},
    {'source': 'tomatoes', 'value': 89, 'score': 89, 'votes': 147, 'url': '/m/shawshank_redemption', 'fresh': 1},
    {'source': 'popcorn', 'value': 98, 'score': 98, 'votes': 53439, 'url': '/m/shawshank_redemption'},
    {'source': 'tmdb', 'value': 87, 'score': 87, 'votes': 30786, 'url': null},
    {'source': 'letterboxd', 'value': 4.6, 'score': 92, 'votes': 2908116, 'url': '/film/the-shawshank-redemption/'},
    {'source': 'rogerebert', 'value': 3.5, 'score': null, 'votes': null, 'url': 'the-shawshank-redemption-1994'},
    {'source': 'myanimelist', 'value': null, 'score': null, 'votes': null, 'url': null},
  ],
};

Matcher _rating(String source, double value, {int? votes}) => isA<MediaRatingSource>()
    .having((rating) => rating.source, 'source', source)
    .having((rating) => rating.value, 'value', closeTo(value, 1e-9))
    .having((rating) => rating.votes, 'votes', votes);

void main() {
  group('MdblistCatalogSource', () {
    late List<http.Request> requests;
    late List<http.Response Function(http.Request)> handlers;
    late MdblistClient client;
    late MdblistCatalogSource source;

    setUp(() {
      requests = [];
      handlers = [];
      client = MdblistClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (handlers.isNotEmpty) return handlers.removeAt(0)(request);
          return http.Response(json.encode(_watchlistBody()), 200);
        }),
      );
      source = MdblistCatalogSource(client);
    });

    tearDown(() {
      source.dispose();
      client.dispose();
    });

    test('maps the authenticated watchlist and uses offset pagination', () async {
      final page = await source.fetchRow(CatalogRowId.watchlist, page: 2, limit: 25);

      final request = requests.single;
      expect(request.url.path, '/watchlist/items');
      expect(request.url.queryParameters['offset'], '25');
      expect(request.url.queryParameters['append_to_response'], 'genres,poster,description');
      expect(page.totalResults, 2);
      expect(page.hasMore, isFalse);
      expect(page.items, hasLength(2));

      final movie = page.items.first;
      expect(movie.source, CatalogSourceId.mdblist);
      expect(movie.kind, MediaKind.movie);
      expect(movie.ids.imdb, 'tt0133093');
      expect(movie.ids.tmdb, 603);
      expect(movie.overview, 'A hacker discovers the truth.');
      expect(movie.genres, ['action', 'science-fiction']);
      expect(movie.posterUrl, 'https://image.tmdb.org/matrix.jpg');
      expect(movie.addedAt, DateTime.utc(2026, 1, 3, 12, 34, 56));
      expect(page.items.last.kind, MediaKind.show);
    });

    test('loads membership and sends add and remove requests', () async {
      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isTrue);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(imdb: 'tt11280740')), isTrue);

      requests.clear();
      handlers.add((_) => http.Response('{}', 200));
      await source.addToWatchlist(MediaKind.show, const CatalogItemIds(imdb: 'tt0903747', tmdb: 1396));
      expect(requests.single.url.path, '/watchlist/items/add');
      expect(json.decode(requests.single.body), {
        'shows': [
          {'imdb': 'tt0903747', 'tmdb': 1396},
        ],
      });

      requests.clear();
      handlers.add((_) => http.Response('{}', 200));
      await source.removeFromWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt0133093', tmdb: 603));
      expect(requests.single.url.path, '/watchlist/items/remove');
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isFalse);
    });

    test('search maps movies and shows and ignores unsupported media', () async {
      handlers.add(
        (_) => http.Response(
          json.encode({
            'search': [
              {
                'title': 'Jaws',
                'year': 1975,
                'score': 86,
                'type': 'movie',
                'ids': {'imdbid': 'tt0073195', 'tmdbid': 578},
              },
              {
                'title': 'Unsupported episode',
                'type': 'episode',
                'ids': {'tmdbid': 1},
              },
            ],
          }),
          200,
        ),
      );

      final results = await source.search('  jaws  ');

      expect(requests.single.url.path, '/search/any');
      expect(requests.single.url.queryParameters['query'], 'jaws');
      expect(results, hasLength(1));
      expect(results.single.title, 'Jaws');
      expect(results.single.ids.imdb, 'tt0073195');
      expect(results.single.rating, 8.6);
    });

    test('community ratings read every mapped source off its own scale and drop the rest', () async {
      handlers.add((_) => http.Response(json.encode(_shawshankBody()), 200));

      final ratings = await source.fetchCommunityRatings(
        MediaKind.movie,
        const CatalogItemIds(imdb: 'tt0111161', tmdb: 278),
      );

      expect(requests.single.url.path, '/imdb/movie/tt0111161');
      expect(ratings, [
        _rating('imdb', 9.3, votes: 3207270),
        _rating('metacritic', 8.2, votes: 22),
        _rating('trakt', 9.1, votes: 43118),
        _rating('rottenTomatoesCritic', 8.9, votes: 147),
        _rating('rottenTomatoesAudience', 9.8, votes: 53439),
        _rating('tmdb', 8.7, votes: 30786),
        _rating('letterboxd', 9.2, votes: 2908116),
      ]);
    });

    test('community ratings look up by TMDB, then a show\'s TVDB, then MAL id and accept numeric strings', () async {
      Map<String, dynamic> body(String source, Object value, Object votes) => {
        'ratings': [
          {'source': source, 'value': value, 'votes': votes},
        ],
      };
      handlers
        ..add((_) => http.Response(json.encode(body('tmdb', '84', '21000')), 200))
        ..add((_) => http.Response(json.encode(body('tomatoesaudience', 96, 250000)), 200))
        ..add((_) => http.Response(json.encode(body('myanimelist', '8.62', 3700000)), 200));

      final byTmdb = await source.fetchCommunityRatings(MediaKind.show, const CatalogItemIds(tmdb: 1396, tvdb: 81189));
      final byTvdb = await source.fetchCommunityRatings(MediaKind.show, const CatalogItemIds(tvdb: 81189, mal: 21));
      final byMal = await source.fetchCommunityRatings(MediaKind.movie, const CatalogItemIds(tvdb: 81189, mal: 21));

      expect(requests.map((request) => request.url.path), ['/tmdb/show/1396', '/tvdb/show/81189', '/mal/any/21']);
      expect(byTmdb, [_rating('tmdb', 8.4, votes: 21000)]);
      expect(byTvdb, [_rating('rottenTomatoesAudience', 9.6, votes: 250000)]);
      expect(byMal, [_rating('mal', 8.62, votes: 3700000)]);
    });

    test('community ratings are empty for a title MDBList does not know', () async {
      handlers.add((_) => http.Response('{"error":"Not found"}', 404));

      expect(await source.fetchCommunityRatings(MediaKind.movie, const CatalogItemIds(tmdb: 1)), isEmpty);
      expect(requests.single.url.path, '/tmdb/movie/1');
    });

    test('community ratings need a movie or show with an id MDBList can look up', () async {
      expect(await source.fetchCommunityRatings(MediaKind.season, const CatalogItemIds(imdb: 'tt0903747')), isEmpty);
      expect(await source.fetchCommunityRatings(MediaKind.movie, const CatalogItemIds(trakt: 1, simkl: 2)), isEmpty);
      expect(requests, isEmpty);
    });

    test('community ratings propagate a failure other than 404', () async {
      handlers.add((_) => http.Response('oops', 503));

      await expectLater(
        source.fetchCommunityRatings(MediaKind.movie, const CatalogItemIds(imdb: 'tt0111161')),
        throwsA(isA<TrackerApiException>().having((error) => error.statusCode, 'statusCode', 503)),
      );
    });
  });
}
