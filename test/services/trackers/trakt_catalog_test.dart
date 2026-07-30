import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trakt/trakt_catalog_entry.dart';
import 'package:plezy/models/trakt/trakt_catalog_media.dart';
import 'package:plezy/models/trakt/trakt_images.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_client.dart';
import 'package:plezy/services/trackers/trakt/trakt_constants.dart';

int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

TrackerSession _session() {
  final now = _now();
  return TrackerSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: now + 86400,
    scope: 'public',
    createdAt: now - 3600,
    username: 'alice',
  );
}

Map<String, dynamic> _movieJson({
  int trakt = 1,
  String? posterUrl = 'walter-r2.trakt.tv/images/movies/p.webp',
  bool withRecommenders = false,
}) {
  return {
    'title': 'The Matrix',
    'year': 1999,
    'ids': {'trakt': trakt, 'slug': 'the-matrix-1999', 'imdb': 'tt0133093', 'tmdb': 603},
    'overview': 'A hacker learns the truth.',
    'tagline': 'Welcome to the Real World.',
    'original_title': 'The Matrix',
    'released': '1999-03-31T00:00:00.000Z',
    'runtime': 136,
    'rating': 8.7,
    'votes': 42000,
    'genres': ['action', 'sci-fi'],
    'certification': 'R',
    'trailer': 'https://youtube.com/watch?v=m8e-FF8MsqU',
    'comment_count': 1234,
    'language': 'en',
    'languages': ['en'],
    'available_translations': ['es', 'fr'],
    'country': 'us',
    if (withRecommenders) ...{
      'favorited_by': [
        {'username': 'alice', 'name': 'Alice', 'notes': 'A forever favorite.'},
      ],
      'recommended_by': [
        {'username': 'bob', 'name': null, 'notes': 'The lobby scene.'},
      ],
    },
    'images': {
      'poster': [?posterUrl],
      'fanart': ['walter-r2.trakt.tv/images/movies/f.webp'],
      'logo': ['walter-r2.trakt.tv/images/movies/logo.webp'],
    },
  };
}

Map<String, dynamic> _showJson() {
  return {
    'title': 'Severance',
    'year': 2022,
    'ids': {'trakt': 2, 'slug': 'severance', 'imdb': 'tt11280740', 'tmdb': 95396, 'tvdb': 371980},
    'overview': 'Work-life balance, surgically.',
    'runtime': 50,
    'rating': 8.9,
    'first_aired': '2022-02-18T00:00:00.000Z',
    'airs': {'day': 'Friday', 'time': '09:30', 'timezone': 'America/New_York'},
    'images': <String, dynamic>{},
  };
}

TraktClient _client(Future<http.Response> Function(http.Request) handler, {List<http.Request>? requests}) {
  return TraktClient(
    _session(),
    onSessionInvalidated: () => fail('should not invalidate'),
    httpClient: MockClient((request) {
      requests?.add(request);
      return handler(request);
    }),
  );
}

void main() {
  group('TraktImages', () {
    test('prefixes protocol-less CDN URLs with https', () {
      final images = TraktImages.fromJson({
        'poster': ['walter-r2.trakt.tv/images/movies/p.webp'],
      });
      expect(images.primaryPoster, 'https://walter-r2.trakt.tv/images/movies/p.webp');
      expect(images.primaryLogo, isNull);
    });

    test('keeps absolute URLs and falls back fanart -> thumb for backdrop', () {
      final images = TraktImages.fromJson({
        'poster': ['https://example.com/p.webp'],
        'thumb': ['walter-r2.trakt.tv/t.webp'],
      });
      expect(images.primaryPoster, 'https://example.com/p.webp');
      expect(images.primaryBackdrop, 'https://walter-r2.trakt.tv/t.webp');
      expect(images.primaryLogo, isNull);
    });

    test('returns null for missing or empty image arrays', () {
      final images = TraktImages.fromJson({'poster': <String>[]});
      expect(images.primaryPoster, isNull);
      expect(images.primaryBackdrop, isNull);
    });
  });

  group('TraktClient catalog', () {
    test('getWatchlist parses wrapped entries and sends extended=full,images', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async {
        return http.Response(
          json.encode([
            {'rank': 1, 'listed_at': '2026-01-01T00:00:00.000Z', 'type': 'movie', 'movie': _movieJson()},
            {'rank': 2, 'listed_at': '2026-01-02T00:00:00.000Z', 'type': 'show', 'show': _showJson()},
          ]),
          200,
          headers: {'x-pagination-page': '1', 'x-pagination-page-count': '3', 'x-pagination-item-count': '250'},
        );
      });

      final page = await client.getWatchlist(type: TraktCatalogType.movies);

      final request = requests.single;
      expect(request.url.path, '/sync/watchlist/movies/added');
      expect(request.url.queryParameters['extended'], 'full,images');
      expect(request.headers['Authorization'], 'Bearer access');

      expect(page.items, hasLength(2));
      expect(page.items[0].isShow, isFalse);
      expect(page.items[0].media?.title, 'The Matrix');
      expect(page.items[0].media?.ids.imdb, 'tt0133093');
      expect(page.items[0].media?.images?.primaryPoster, 'https://walter-r2.trakt.tv/images/movies/p.webp');
      expect(page.items[1].isShow, isTrue);
      expect(page.items[1].media?.ids.tvdb, 371980);
      expect(page.items[1].media?.images?.primaryPoster, isNull);
      expect(page.page, 1);
      expect(page.pageCount, 3);
      expect(page.itemCount, 250);
      expect(page.hasMore, isTrue);

      client.dispose();
    });

    test('getWatchlist defaults to a single page when pagination headers are absent', () async {
      final client = _client((request) async => http.Response(json.encode([]), 200));

      final page = await client.getWatchlist(type: TraktCatalogType.shows);

      expect(page.items, isEmpty);
      expect(page.page, 1);
      expect(page.pageCount, 1);
      expect(page.hasMore, isFalse);
      expect(page.itemCount, isNull);

      client.dispose();
    });

    test('getTrending parses watcher-wrapped entries', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async {
        return http.Response(
          json.encode([
            {'watchers': 120, 'movie': _movieJson()},
          ]),
          200,
        );
      });

      final page = await client.getTrending(TraktCatalogType.movies, page: 2, limit: 10);

      expect(requests.single.url.path, '/movies/trending');
      expect(requests.single.url.queryParameters['page'], '2');
      expect(requests.single.url.queryParameters['limit'], '10');
      expect(page.items.single.watchers, 120);
      expect(page.items.single.media?.title, 'The Matrix');
      expect(page.itemCount, isNull);

      client.dispose();
    });

    test('getPopular parses bare media objects', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async {
        return http.Response(json.encode([_showJson()]), 200);
      });

      final page = await client.getPopular(TraktCatalogType.shows);

      expect(requests.single.url.path, '/shows/popular');
      expect(page.items.single, isA<TraktCatalogMedia>());
      expect(page.items.single.title, 'Severance');
      expect(page.items.single.firstAired, '2022-02-18T00:00:00.000Z');
      expect(page.items.single.airs?.day, 'Friday');
      expect(page.items.single.airs?.time, '09:30');
      expect(page.items.single.airs?.timezone, 'America/New_York');
      expect(page.items.single.commentCount, isNull);

      client.dispose();
    });

    test('getRecommended passes ignore flags and parses bare media', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async {
        return http.Response(json.encode([_movieJson()]), 200);
      });

      final items = await client.getRecommended(TraktCatalogType.movies, limit: 15);

      final request = requests.single;
      expect(request.url.path, '/recommendations/movies');
      expect(request.url.queryParameters['limit'], '15');
      expect(request.url.queryParameters['ignore_collected'], 'false');
      expect(request.url.queryParameters['ignore_watchlisted'], 'true');
      expect(items.single.title, 'The Matrix');

      client.dispose();
    });

    test('getRecommended parses recommendation provenance without reducing it to a count', () async {
      final client = _client((request) async {
        return http.Response(json.encode([_movieJson(withRecommenders: true)]), 200);
      });

      final items = await client.getRecommended(TraktCatalogType.movies, limit: 15);

      final item = items.single;
      expect(item.favoritedBy?.single.username, 'alice');
      expect(item.favoritedBy?.single.name, 'Alice');
      expect(item.favoritedBy?.single.notes, 'A forever favorite.');
      expect(item.recommendedBy?.single.username, 'bob');
      expect(item.recommendedBy?.single.notes, 'The lobby scene.');

      client.dispose();
    });

    test('getPeople widens show people for guest stars and parses cast and crew metadata', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async {
        return http.Response(
          json.encode({
            'cast': [
              {
                'characters': ['Mark Scout', 'Mark S.'],
                'episode_count': 19,
                'person': {'name': 'Adam Scott'},
              },
            ],
            'guest_stars': [
              {
                'characters': ['June'],
                'episode_count': 1,
                'person': {'name': 'Guest Actor'},
              },
            ],
            'crew': {
              'directing': [
                {
                  'jobs': ['Director'],
                  'person': {'name': 'Ben Stiller'},
                },
              ],
              'production': [
                {
                  'job': 'Executive Producer',
                  'person': {'name': 'Jackie Cohn'},
                },
              ],
            },
          }),
          200,
        );
      });

      final people = await client.getPeople(TraktCatalogType.shows, 'severance');

      expect(requests.single.url.path, '/shows/severance/people');
      expect(requests.single.url.queryParameters['extended'], 'full,images,guest_stars');
      expect(people.cast.single.characters, ['Mark Scout', 'Mark S.']);
      expect(people.cast.single.episodeCount, 19);
      expect(people.guestStars.single.person?.name, 'Guest Actor');
      expect(people.crew, hasLength(2));
      expect(people.crew.first.jobs, ['Director']);
      expect(people.crew.last.job, 'Executive Producer');

      client.dispose();
    });

    test('addToWatchlist accepts 201 and posts the ids body untouched', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async => http.Response('{"added":{"movies":1}}', 201));

      final body = {
        'movies': [
          {
            'ids': {'imdb': 'tt0133093'},
          },
        ],
      };
      await client.addToWatchlist(body);

      expect(requests.single.url.path, '/sync/watchlist');
      expect(json.decode(requests.single.body), body);

      client.dispose();
    });

    test('removeFromWatchlist posts to the remove endpoint', () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests, (request) async => http.Response('{"deleted":{"shows":1}}', 200));

      await client.removeFromWatchlist(const {'shows': []});

      expect(requests.single.url.path, '/sync/watchlist/remove');

      client.dispose();
    });

    test('malformed entries are skipped instead of throwing', () async {
      final client = _client((request) async {
        return http.Response(json.encode(['not-a-map', 42]), 200);
      });

      final page = await client.getTrending(TraktCatalogType.shows);
      expect(page.items, isEmpty);

      client.dispose();
    });

    test('entry without movie or show yields null media', () {
      final entry = TraktCatalogEntry.fromJson(const {'rank': 1, 'type': 'movie'});
      expect(entry.media, isNull);
    });
  });
}
