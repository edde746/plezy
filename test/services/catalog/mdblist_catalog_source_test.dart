import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/mdblist_catalog_source.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_client.dart';
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
  });
}
