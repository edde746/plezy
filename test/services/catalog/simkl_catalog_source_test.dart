import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/simkl/simkl_trending_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/simkl_catalog_source.dart';
import 'package:plezy/services/trackers/simkl/simkl_client.dart';
import 'package:plezy/services/trackers/simkl/simkl_constants.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'access',
    refreshToken: null,
    expiresAt: now + 86400,
    createdAt: now - 3600,
    username: 'alice',
  );
}

http.Response _json(Object? body, {int status = 200, Map<String, String>? headers}) =>
    http.Response(json.encode(body), status, headers: {'content-type': 'application/json', ...?headers});

Map<String, dynamic> _trending({required int simkl, String title = 'Inception', String? animeType}) => {
  'title': title,
  'title_romaji': animeType == null ? null : 'Inception no Yume',
  'alt_titles': [
    {'name': title},
    {'name': 'Le rêve'},
  ],
  'url': '/${animeType == null ? 'movies' : 'anime'}/$simkl/inception',
  'poster': '12/posterhash',
  'fanart': '34/fanarthash',
  'release_date': '07/16/2010',
  'rank': 7,
  'drop_rate': '2.5%',
  'watched': 321,
  'plan_to_watch': 654,
  'runtime': '2h 37m',
  'status': 'ended',
  'overview': 'Dreams within dreams.',
  'genres': ['Action', 'Science Fiction'],
  'trailer': 'YoHD9XEInc0',
  'country': 'us',
  'original_language': 'en',
  'dvd_date': '12/03/2010',
  'theater': '07/15/2010',
  'total_episodes': animeType == null ? null : 12,
  'anime_type': ?animeType,
  'ids': {'simkl_id': simkl, 'slug': 'inception', 'imdb': 'tt1375666', 'tmdb': '27205', 'tvdb': '123'},
  'ratings': {
    'simkl': {'rating': 8.8, 'votes': 1234},
    if (animeType == null) 'imdb': {'rating': 8.7, 'votes': 2345} else 'mal': {'rating': 8.6, 'votes': 3456},
  },
};

Map<String, dynamic> _best(int simkl, {int? watched}) => {
  'title': 'Best $simkl',
  'year': 2020,
  'watched': ?watched,
  'ids': {'simkl': simkl},
};

Map<String, dynamic> _allItemsBody() => {
  'movies': [
    {
      'status': 'plantowatch',
      'movie': {
        'title': 'Inception',
        'year': 2010,
        'poster': '12/posterhash',
        'runtime': 148,
        'ids': {'simkl': 1, 'imdb': 'tt1375666', 'tmdb': '27205'},
      },
    },
  ],
  'shows': [
    {
      'status': 'plantowatch',
      'added_to_watchlist_at': '2025-04-03T02:01:00Z',
      'user_rating': 9,
      'not_aired_episodes_count': 4,
      'total_episodes_count': 62,
      'show': {
        'title': 'Breaking Bad',
        'year': 2008,
        'poster': '97/showhash',
        'ids': {'simkl': 2, 'tvdb': '81189'},
      },
    },
  ],
  'anime': [
    {
      'status': 'plantowatch',
      'anime_type': 'movie',
      'show': {
        'title': 'Your Name.',
        'year': 2016,
        'poster': '55/animehash',
        'ids': {'simkl': 3, 'mal': '32281', 'anilist': '21519'},
      },
    },
  ],
};

Map<String, dynamic> _detailBody() => {
  'title': 'One Piece',
  'year': 1999,
  'type': 'anime',
  'anime_type': 'tv',
  'poster': '15/detailposter',
  'fanart': '87/detailfanart',
  'first_aired': '1999-10-20T14:15:00Z',
  'last_aired': null,
  'airs': {'day': 'Sunday', 'time': '11:15 PM', 'timezone': 'Asia/Tokyo'},
  'runtime': 25,
  'certification': 'PG-13',
  'overview': 'The full detail overview.',
  'genres': ['Action', 'Adventure'],
  'country': 'jp',
  'total_episodes': 1176,
  'status': 'airing',
  'network': 'Fuji TV',
  'season_name_year': 'Fall 1999',
  'studios': [
    {'id': 74, 'name': 'Toei Animation'},
  ],
  'ratings': {
    'simkl': {'rating': 8.9, 'votes': 8037},
    'imdb': {'rating': 8.3, 'votes': 15720},
    'mal': {'rating': 8.7, 'votes': 1548013},
  },
  'trailers': [
    {'youtube': 'tnj5YOZpCyo', 'size': 1080},
  ],
  'ids': {'simkl': 3, 'mal': 21, 'anilist': 21},
  'users_recommendations': [
    {
      'title': 'Fairy Tail',
      'year': 2009,
      'poster': '64/related',
      'type': 'anime',
      'anime_type': 'tv',
      'users_percent': '19%',
      'users_count': 76,
      'ids': {'simkl': 4},
    },
  ],
};

void main() {
  group('Simkl models', () {
    test('parses runtime strings and rejects malformed values', () {
      expect(SimklTrendingItem.fromJson(_trending(simkl: 1)).runtimeMinutes, 157);
      expect(SimklTrendingItem.fromJson({..._trending(simkl: 1), 'runtime': '45m'}).runtimeMinutes, 45);
      expect(SimklTrendingItem.fromJson({..._trending(simkl: 1), 'runtime': 'unknown'}).runtimeMinutes, isNull);
    });
  });

  group('SimklCatalogSource', () {
    late List<http.Request> requests;
    late FutureOr<http.Response> Function(http.Request request) responder;
    late SimklClient client;
    late SimklCatalogSource source;
    late int invalidations;

    setUp(() {
      requests = [];
      invalidations = 0;
      responder = (request) => _json([]);
      client = SimklClient(
        _session(),
        onSessionInvalidated: () => invalidations++,
        httpClient: MockClient((request) async {
          requests.add(request);
          return responder(request);
        }),
      );
      source = SimklCatalogSource(client);
    });

    tearDown(() {
      source.dispose();
      client.dispose();
    });

    test('trending uses CDN, coerces ids, builds images, and serves page two from cache', () async {
      responder = (request) => _json([_trending(simkl: 1), _trending(simkl: 2, title: 'Second')]);

      final first = await source.fetchRow(CatalogRowId.trendingMovies, limit: 1);
      final second = await source.fetchRow(CatalogRowId.trendingMovies, page: 2, limit: 1);

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.url.host, 'data.simkl.in');
      expect(request.url.path, '/discover/trending/movies/week_100.json');
      expect(request.url.queryParameters['client_id'], SimklConstants.clientId);
      expect(request.url.queryParameters['app-name'], SimklConstants.appName);
      expect(request.url.queryParameters['app-version'], SimklConstants.appVersion);
      expect(request.headers, isNot(contains('authorization')));
      expect(request.headers['user-agent'], '${SimklConstants.appName}/${SimklConstants.appVersion}');

      expect(first.hasMore, isTrue);
      expect(first.items.single.ids.simkl, 1);
      expect(first.items.single.ids.tmdb, 27205);
      expect(first.items.single.year, 2010);
      expect(first.items.single.runtimeMinutes, 157);
      expect(first.items.single.posterUrl, 'https://simkl.in/posters/12/posterhash_m.webp');
      expect(first.items.single.backdropUrl, 'https://simkl.in/fanart/34/fanarthash_medium.webp');
      final item = first.items.single;
      expect(item.posterVariants, containsPair(170, 'https://simkl.in/posters/12/posterhash_c.webp'));
      expect(item.posterVariants, containsPair(340, item.posterUrl));
      expect(item.backdropVariants, containsPair(960, 'https://simkl.in/fanart/34/fanarthash_mobile.webp'));
      expect(item.backdropVariants, containsPair(1920, item.backdropUrl));
      expect(item.ratings?.map((rating) => rating.source), ['simkl', 'imdb']);
      expect(item.ratings?.map((rating) => rating.votes), [1234, 2345]);
      expect(item.audience?.viewers, 321);
      expect(item.audience?.viewersPeriod, CatalogAudiencePeriod.week);
      expect(item.audience?.planning, 654);
      expect(item.audience?.dropRate, 0.025);
      expect(item.ranks?.single.scope, CatalogRankScope.trending);
      expect(item.ranks?.single.allTime, isFalse);
      expect(item.releaseDate, DateTime(2010, 7, 15));
      expect(item.physicalReleaseDate, DateTime(2010, 12, 3));
      expect(item.countries, ['US']);
      expect(item.languages, ['en']);
      expect(item.links?.single.url, 'https://simkl.com/movies/1/inception');
      expect(second.items.single.title, 'Second');
      expect(second.hasMore, isFalse);
    });

    test('CDN 401 does not invalidate the authenticated Simkl session', () async {
      responder = (request) => http.Response('denied', 401);

      await expectLater(source.fetchRow(CatalogRowId.trendingMovies), throwsA(isA<TrackerApiException>()));
      expect(invalidations, 0);
    });

    test('anime_type movie maps a trending anime to MediaKind.movie', () async {
      responder = (request) => _json([_trending(simkl: 3, animeType: 'movie')]);

      final page = await source.fetchRow(CatalogRowId.trendingAnime);
      expect(page.items.single.kind, MediaKind.movie);
      expect(page.items.single.episodeCount, isNull);
    });

    test('best TV uses watched endpoint and tolerates a literal null body', () async {
      responder = (request) {
        expect(request.url.path, '/tv/best/watched');
        return http.Response('null', 200, headers: {'content-type': 'application/json'});
      };

      final page = await source.fetchRow(CatalogRowId.popularShows);
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('best watched counts are monthly viewers', () async {
      responder = (request) => _json([_best(1, watched: 987)]);

      final page = await source.fetchRow(CatalogRowId.popularShows);

      expect(page.items.single.audience?.viewers, 987);
      expect(page.items.single.audience?.viewersPeriod, CatalogAudiencePeriod.month);
    });

    test('best rows expose all cached pages without refetching', () async {
      responder = (request) {
        expect(request.url.path, '/tv/best/watched');
        return _json([for (var i = 1; i <= 60; i++) _best(i)]);
      };

      final first = await source.fetchRow(CatalogRowId.popularShows, limit: 25);
      final second = await source.fetchRow(CatalogRowId.popularShows, page: 2, limit: 25);
      final third = await source.fetchRow(CatalogRowId.popularShows, page: 3, limit: 25);

      expect(requests, hasLength(1));
      expect(first.items, hasLength(25));
      expect(first.hasMore, isTrue);
      expect(second.items, hasLength(25));
      expect(second.hasMore, isTrue);
      expect(third.items, hasLength(10));
      expect(third.hasMore, isFalse);
    });

    test('watchlist row maps full entries and reuses its warm cache', () async {
      responder = (request) {
        expect(request.url.path, '/sync/all-items/all/plantowatch');
        expect(request.url.queryParameters['extended'], 'full');
        expect(request.headers['authorization'], 'Bearer access');
        return _json(_allItemsBody());
      };

      final first = await source.fetchRow(CatalogRowId.watchlist, limit: 10);
      final second = await source.fetchRow(CatalogRowId.watchlist, limit: 10);
      expect(requests, hasLength(1));
      expect(first.items, hasLength(3));
      final movie = first.items.first;
      expect(movie.kind, MediaKind.movie);
      expect(movie.ids.simkl, 1);
      expect(movie.ids.tmdb, 27205);
      expect(movie.runtimeMinutes, 148);
      expect(first.items.last.kind, MediaKind.movie);
      expect(first.items.last.ids.anilist, 21519);
      final show = first.items[1];
      expect(show.addedAt, DateTime.parse('2025-04-03T02:01:00Z'));
      expect(show.userRating, 9);
      expect(show.unairedEpisodeCount, 4);
      expect(second.items, hasLength(3));
    });

    test('absent optional row fields stay absent', () async {
      responder = (request) => _json([
        {
          'title': 'Sparse',
          'ids': {'simkl_id': 99},
        },
      ]);

      final page = await source.fetchRow(CatalogRowId.trendingMovies);
      final item = page.items.single;

      expect(item.ratings, isNull);
      expect(item.audience, isNull);
      expect(item.ranks, isNull);
      expect(item.posterUrl, isNull);
      expect(item.posterVariants, isNull);
      expect(item.backdropVariants, isNull);
      expect(item.originalTitle, isNull);
      expect(item.altTitles, isEmpty);
      expect(item.links, isNull);
    });

    test('watchlist row and membership snapshot share one full-library download', () async {
      responder = (request) {
        expect(request.url.queryParameters['extended'], 'full');
        return _json(_allItemsBody());
      };

      await source.fetchRow(CatalogRowId.watchlist);
      await source.ensureWatchlistLoaded();

      expect(requests, hasLength(1));
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 27205)), isTrue);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(tmdb: 27205)), isFalse);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(tvdb: 81189)), isTrue);
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 3)), isTrue);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(simkl: 3)), isTrue);
    });

    test('add uses per-item plantowatch and remove uses history/remove with bare ids', () async {
      final bodies = <Map<String, dynamic>>[];
      responder = (request) {
        bodies.add(json.decode(request.body) as Map<String, dynamic>);
        return _json({
          'added': <String, dynamic>{},
          'not_found': <String, dynamic>{},
        }, status: request.url.path == '/sync/add-to-list' ? 201 : 200);
      };
      const ids = CatalogItemIds(simkl: 1, slug: 'response-only', imdb: 'tt1375666', tmdb: 27205);

      await source.addToWatchlist(MediaKind.movie, ids);
      await source.removeFromWatchlist(MediaKind.movie, ids);

      expect(requests.map((request) => request.url.path), ['/sync/add-to-list', '/sync/history/remove']);
      final added = (bodies.first['movies'] as List).single as Map<String, dynamic>;
      expect(added['to'], 'plantowatch');
      expect(added['ids'], {'simkl': 1, 'imdb': 'tt1375666', 'tmdb': 27205});
      final removed = (bodies.last['movies'] as List).single as Map<String, dynamic>;
      expect(removed.keys, ['ids']);
    });

    test('successful mutations invalidate the shared watchlist payload', () async {
      var allItemsRequests = 0;
      responder = (request) {
        if (request.url.path == '/sync/all-items/all/plantowatch') {
          allItemsRequests++;
          return _json(_allItemsBody());
        }
        return _json(const <String, Object?>{}, status: 201);
      };

      await source.fetchRow(CatalogRowId.watchlist);
      await source.addToWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 4));
      await source.fetchRow(CatalogRowId.watchlist);

      expect(allItemsRequests, 2);
    });

    test('failed mutation restores optimistic membership', () async {
      var loadingSnapshot = true;
      responder = (request) {
        if (loadingSnapshot) return _json(_allItemsBody());
        return http.Response('failed', 500);
      };
      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 1)), isTrue);

      loadingSnapshot = false;
      await expectLater(
        source.removeFromWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 1)),
        throwsA(isA<TrackerApiException>()),
      );
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 1)), isTrue);
    });

    test('snapshot errors are swallowed and membership remains unknown', () async {
      responder = (request) => http.Response('failed', 500);

      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(simkl: 1)), isNull);
    });

    test('search fans out across movie, TV, and anime and merges mapped results', () async {
      responder = (request) {
        expect(request.url.queryParameters['q'], 'cowboy');
        expect(request.url.queryParameters['extended'], 'full');
        final (endpoint, type, animeType) = switch (request.url.path) {
          '/search/movie' => ('movies', 'Movie', null),
          '/search/tv' => ('tv', 'Show', null),
          '/search/anime' => ('anime', 'Anime Movie', 'movie'),
          _ => throw StateError('unexpected path ${request.url.path}'),
        };
        return _json(
          [
            {
              'title': type,
              'year': 2020,
              'endpoint_type': endpoint,
              'type': ?animeType,
              'poster': '1/hash',
              'ids': {'simkl_id': endpoint.hashCode.abs()},
              'ratings': {
                'simkl': {'rating': 8.0, 'votes': 10},
              },
            },
          ],
          headers: {'x-pagination-page': '1', 'x-pagination-page-count': '1', 'x-pagination-item-count': '1'},
        );
      };

      final results = await source.search(' cowboy ', limit: 30);

      expect(requests.map((request) => request.url.path).toSet(), {'/search/movie', '/search/tv', '/search/anime'});
      expect(results.map((item) => item.title), ['Movie', 'Show', 'Anime Movie']);
      expect(results.map((item) => item.kind), [MediaKind.movie, MediaKind.show, MediaKind.movie]);
    });

    test('fetchDetail without a Simkl id returns the row unchanged without a request', () async {
      const item = CatalogItem(
        source: CatalogSourceId.simkl,
        kind: MediaKind.movie,
        title: 'Inception',
        ids: CatalogItemIds(imdb: 'tt1375666'),
      );

      final detail = await source.fetchDetail(item);

      expect(detail.item, same(item));
      expect(detail.cast, isEmpty);
      expect(detail.related, isEmpty);
      expect(detail.relations, isEmpty);
      expect(requests, isEmpty);
    });

    test('fetchDetail uses one request for an enriched item and recommendations', () async {
      responder = (request) {
        if (request.url.host == 'data.simkl.in') {
          return _json([_trending(simkl: 3, animeType: 'tv')]);
        }
        expect(request.url.path, '/anime/3');
        expect(request.url.queryParameters, isNot(contains('extended')));
        return _json(_detailBody());
      };
      final row = await source.fetchRow(CatalogRowId.trendingAnime);
      final item = row.items.single;
      requests.clear();

      final detail = await source.fetchDetail(item);

      expect(requests, hasLength(1));
      expect(detail.cast, isEmpty);
      expect(detail.relations, isEmpty);
      expect(detail.item.title, 'One Piece');
      expect(detail.item.overview, 'The full detail overview.');
      expect(detail.item.certification, 'PG-13');
      expect(detail.item.runtimeMinutes, 25);
      expect(detail.item.ratings?.map((rating) => rating.source), ['simkl', 'imdb', 'mal']);
      expect(detail.item.ranks, same(item.ranks));
      expect(detail.item.posterVariants, containsPair(170, 'https://simkl.in/posters/15/detailposter_c.webp'));
      expect(detail.item.backdropVariants, containsPair(960, 'https://simkl.in/fanart/87/detailfanart_mobile.webp'));
      expect(detail.item.trailerUrl, 'https://www.youtube.com/watch?v=tnj5YOZpCyo');
      expect(detail.item.broadcast?.weekday, DateTime.sunday);
      expect(detail.item.broadcast?.time, '23:15');
      expect(detail.item.countries, ['JP']);
      expect(detail.item.studios, ['Toei Animation']);
      expect(detail.related, hasLength(1));
      expect(detail.related.single.title, 'Fairy Tail');
      expect(detail.related.single.recommendationCount, 76);
      expect(detail.related.single.recommendationPercent, 0.19);
      expect(detail.related.single.posterVariants, isNotNull);
    });
  });
}
