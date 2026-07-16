import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/utils/external_ids.dart';

SeerrCatalogSource _source(MockClient mock) {
  final client = SeerrClient(
    const SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 1,
      permissions: 2,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: mock,
  );
  final source = SeerrCatalogSource(client);
  addTearDown(() {
    source.dispose();
    client.dispose();
  });
  return source;
}

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  group('SeerrCatalogSource', () {
    test('trending row keeps movies and shows, drops people, maps TMDB images', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/discover/trending');
          return _json({
            'page': 1,
            'totalPages': 3,
            'results': [
              {
                'id': 603,
                'mediaType': 'movie',
                'title': 'The Matrix',
                'releaseDate': '1999-03-30',
                'posterPath': '/matrix.jpg',
                'backdropPath': '/matrix-backdrop.jpg',
                'voteAverage': 8.2,
                'voteCount': 26000,
              },
              {'id': 9, 'mediaType': 'person', 'name': 'Keanu Reeves'},
              {'id': 1396, 'mediaType': 'tv', 'name': 'Breaking Bad', 'firstAirDate': '2008-01-20'},
            ],
          });
        }),
      );

      final page = await source.fetchRow(CatalogRowId.trending);
      expect(page.hasMore, isTrue);
      expect(page.items, hasLength(2));

      final matrix = page.items.first;
      expect(matrix.source, CatalogSourceId.seerr);
      expect(matrix.kind, MediaKind.movie);
      expect(matrix.title, 'The Matrix');
      expect(matrix.year, 1999);
      expect(matrix.rating, 8.2);
      expect(matrix.votes, 26000);
      expect(matrix.ids.tmdb, 603);
      expect(matrix.posterUrl, 'https://image.tmdb.org/t/p/w600_and_h900_bestv2/matrix.jpg');
      expect(matrix.backdropUrl, 'https://image.tmdb.org/t/p/w1920_and_h800_multi_faces/matrix-backdrop.jpg');

      expect(page.items.last.kind, MediaKind.show);
      expect(page.items.last.title, 'Breaking Bad');
    });

    test('single-type rows hit their endpoint and coerce the kind', () async {
      final paths = <String>[];
      final source = _source(
        MockClient((request) async {
          paths.add('${request.url.path}?${request.url.query}');
          return _json({
            'page': 2,
            'totalPages': 2,
            'results': [
              {'id': 335984, 'title': 'Blade Runner 2049', 'releaseDate': '2017-10-04'},
            ],
          });
        }),
      );

      final page = await source.fetchRow(CatalogRowId.upcomingMovies, page: 2);
      expect(paths.single, '/api/v1/discover/movies/upcoming?page=2');
      expect(page.items.single.kind, MediaKind.movie);
      expect(page.hasMore, isFalse);
    });

    test('rows Seerr does not serve throw', () {
      final source = _source(MockClient((request) async => _json({})));
      expect(() => source.fetchRow(CatalogRowId.watchlist), throwsArgumentError);
      expect(() => source.fetchRow(CatalogRowId.suggestedAnime), throwsArgumentError);
    });

    test('resolveItemIds needs a tmdb id', () async {
      final source = _source(MockClient((request) async => _json({})));
      final resolved = await source.resolveItemIds(MediaKind.movie, const ExternalIds(tmdb: 603, imdb: 'tt0133093'));
      expect(resolved?.tmdb, 603);
      expect(resolved?.imdb, 'tt0133093');
      expect(await source.resolveItemIds(MediaKind.movie, const ExternalIds(imdb: 'tt0133093')), isNull);
    });

    test('fetchCast reads credits off the detail endpoint', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/tv/1396');
          return _json({
            'id': 1396,
            'name': 'Breaking Bad',
            'credits': {
              'cast': [
                {'name': 'Bryan Cranston', 'character': 'Walter White', 'profilePath': '/bc.jpg'},
                {'name': '', 'character': 'nobody'},
                {'name': 'Aaron Paul', 'character': 'Jesse Pinkman'},
              ],
            },
          });
        }),
      );

      final item = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.show,
        title: 'Breaking Bad',
        ids: const CatalogItemIds(tmdb: 1396),
      );
      final cast = await source.fetchCast(item);
      expect(cast, hasLength(2));
      expect(cast.first.name, 'Bryan Cranston');
      expect(cast.first.secondary, 'Walter White');
      expect(cast.first.imageUrl, 'https://image.tmdb.org/t/p/w300/bc.jpg');
      expect(cast.last.imageUrl, isNull);
    });

    test('search proxies /search and filters persons', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/search');
          expect(request.url.queryParameters['query'], 'the matrix');
          return _json({
            'page': 1,
            'totalPages': 1,
            'results': [
              {'id': 603, 'mediaType': 'movie', 'title': 'The Matrix', 'releaseDate': '1999-03-30'},
              {'id': 6384, 'mediaType': 'person', 'name': 'Keanu Reeves'},
            ],
          });
        }),
      );
      final items = await source.search('the matrix');
      expect(items.single.title, 'The Matrix');
      expect(items.single.ids.tmdb, 603);
    });

    test('fetchRelated proxies the recommendations endpoint and coerces the kind', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/movie/603/recommendations');
          return _json({
            'page': 1,
            'totalPages': 1,
            'results': [
              {'id': 604, 'title': 'The Matrix Reloaded', 'releaseDate': '2003-05-15'},
            ],
          });
        }),
      );
      final item = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.movie,
        title: 'The Matrix',
        ids: const CatalogItemIds(tmdb: 603),
      );
      final related = await source.fetchRelated(item);
      expect(related.single.title, 'The Matrix Reloaded');
      expect(related.single.kind, MediaKind.movie);
    });

    test('canRequest honors the per-kind permission split', () {
      // permissions: 2 = ADMIN in the fixture session → everything allowed.
      final source = _source(MockClient((request) async => _json({})));
      expect(source.canRequest(MediaKind.movie), isTrue);
      expect(source.canRequest(MediaKind.show), isTrue);
    });

    test('has no watchlist: membership unknown, mutations unsupported', () async {
      final source = _source(MockClient((request) async => _json({})));
      expect(source.supportsWatchlist, isFalse);
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isNull);
      expect(() => source.addToWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), throwsUnsupportedError);
    });
  });
}
