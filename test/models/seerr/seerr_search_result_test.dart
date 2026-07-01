import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/seerr/seerr_media_info.dart';
import 'package:plezy/models/seerr/seerr_page.dart';
import 'package:plezy/models/seerr/seerr_search_result.dart';

void main() {
  group('SeerrSearchResult.fromJson', () {
    test('decodes a movie result with mediaInfo', () {
      final raw = {
        'id': 603,
        'mediaType': 'movie',
        'title': 'The Matrix',
        'overview': 'A hacker discovers ...',
        'posterPath': '/abc.jpg',
        'backdropPath': '/bg.jpg',
        'releaseDate': '1999-03-30',
        'voteAverage': 8.2,
        'mediaInfo': {'id': 1, 'tmdbId': 603, 'status': 5},
      };
      final r = SeerrSearchResult.fromJson(raw);
      expect(r, isA<SeerrMovieResult>());
      final movie = r as SeerrMovieResult;
      expect(movie.id, 603);
      expect(movie.title, 'The Matrix');
      expect(movie.voteAverage, 8.2);
      expect(movie.mediaInfo?.status, SeerrMediaStatus.available);
    });

    test('decodes a tv result', () {
      final r = SeerrSearchResult.fromJson({
        'id': 1396,
        'mediaType': 'tv',
        'name': 'Breaking Bad',
        'firstAirDate': '2008-01-20',
        'posterPath': '/p.jpg',
      });
      expect(r, isA<SeerrTvResult>());
      expect((r as SeerrTvResult).name, 'Breaking Bad');
    });

    test('decodes a person result', () {
      final r = SeerrSearchResult.fromJson({'id': 1100, 'mediaType': 'person', 'name': 'Brian Cox'});
      expect(r, isA<SeerrPersonResult>());
      expect((r as SeerrPersonResult).name, 'Brian Cox');
    });

    test('returns null for unknown mediaType', () {
      final r = SeerrSearchResult.fromJson({'id': 1, 'mediaType': 'collection'});
      expect(r, isNull);
    });

    test('SeerrPage skips unknown variants and parses mixed results', () {
      final raw = {
        'page': 1,
        'pages': 3,
        'totalResults': 60,
        'results': [
          {'id': 603, 'mediaType': 'movie', 'title': 'The Matrix'},
          {'id': 1396, 'mediaType': 'tv', 'name': 'Breaking Bad'},
          {'id': 999, 'mediaType': 'unsupported'},
          {'id': 1100, 'mediaType': 'person', 'name': 'Brian Cox'},
        ],
      };
      final page = SeerrPage<SeerrSearchResult>.fromJson(raw, (item) => SeerrSearchResult.fromJson(item));
      expect(page.page, 1);
      expect(page.pages, 3);
      expect(page.totalResults, 60);
      expect(page.results, hasLength(3));
      expect(page.results[0], isA<SeerrMovieResult>());
      expect(page.results[1], isA<SeerrTvResult>());
      expect(page.results[2], isA<SeerrPersonResult>());
      expect(page.hasMore, isTrue);
    });

    test('SeerrPage parses pageInfo-wrapped responses (request list shape)', () {
      final raw = {
        'pageInfo': {'page': 2, 'pages': 5, 'results': 100, 'pageSize': 20},
        'results': [],
      };
      final page = SeerrPage<dynamic>.fromJson(raw, (_) => null);
      expect(page.page, 2);
      expect(page.pages, 5);
      expect(page.totalResults, 100);
      expect(page.hasMore, isTrue);
    });

    test('SeerrPage parses discover responses with totalPages field', () {
      final raw = {
        'page': 1,
        'totalPages': 10,
        'totalResults': 200,
        'results': [],
      };
      final page = SeerrPage<dynamic>.fromJson(raw, (_) => null);
      expect(page.page, 1);
      expect(page.pages, 10);
      expect(page.totalResults, 200);
      expect(page.hasMore, isTrue);
    });
  });
}
