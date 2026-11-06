import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/mdblist_catalog_source.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_client.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

Map<String, dynamic> media(int id, {String kind = 'movie', String? imdb}) => {
  // Batch `id` is an internal record ID, not the requested TMDB ID.
  'id': id + 9000, 'type': kind, 'title': 'Title $id',
  'ids': {'tmdb': id, 'imdb': ?imdb},
  'description': 'Full description', 'poster': 'https://image.tmdb.org/t/p/original/poster.jpg',
  'backdrop': 'https://image.tmdb.org/t/p/w1280/backdrop.jpg',
  'runtime': kind == 'show' ? 328 : 96,
  'genres': [
    {'id': 1, 'title': 'Drama'},
  ],
  'released': '2026-04-24',
  'ratings': [
    {'source': 'letterboxd', 'value': 8.6, 'score': 86, 'votes': 10},
  ],
};

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

void main() {
  late MdblistClient client;
  late MdblistCatalogSource source;
  late List<http.Request> requests;
  MdblistCatalogSource setup(FutureOr<http.Response> Function(http.Request) handle) {
    requests = [];
    client = MdblistClient(
      const TrackerSession(accessToken: 'test-only', createdAt: 0),
      onSessionInvalidated: () => fail('Unexpected session invalidation'),
      httpClient: MockClient((request) async {
        requests.add(request);
        return handle(request);
      }),
    );
    source = MdblistCatalogSource(client);
    addTearDown(() {
      source.dispose();
      client.dispose();
    });
    return source;
  }

  test('batch search preserves order, kind and IDs; restores rich fields and attributed ratings', () async {
    setup((request) {
      if (request.method == 'GET') {
        return jsonResponse({
          'search': [
            {
              'title': 'First movie',
              'type': 'movie',
              'ids': {'tmdbid': 20},
            },
            {
              'title': 'Second movie',
              'type': 'movie',
              'ids': {'tmdbid': 10},
            },
            {
              'title': 'Show',
              'type': 'show',
              'ids': {'tmdbid': 10},
            },
          ],
        });
      }
      expect(jsonDecode(request.body)['ids'], request.url.path.contains('movie') ? [20, 10] : [10]);
      return jsonResponse(request.url.path.contains('movie') ? [media(10), media(20)] : [media(10, kind: 'show')]);
    });
    final results = await source.search('Title');
    expect(requests.length, 3);
    expect(results.map((x) => x.ids.tmdb), [20, 10, 10]);
    expect(results.map((x) => x.kind), [MediaKind.movie, MediaKind.movie, MediaKind.show]);
    final item = results.first;
    expect(item.source, CatalogSourceId.mdblist);
    expect(item.overview, 'Full description');
    expect(item.posterUrl, contains('poster.jpg'));
    expect(item.backdropUrl, contains('backdrop.jpg'));
    expect(item.genres, ['Drama']);
    expect(item.runtimeMinutes, 96);
    expect(item.releaseDate, DateTime(2026, 4, 24));
    expect(item.ratings!.single.value, 8.6);
    expect(results.last.runtimeMinutes, isNull, reason: 'Series duration is not episode runtime');
  });

  test('movie and show trailers survive batch enrichment and full detail retrieval', () async {
    setup((request) {
      if (request.url.path == '/search/any') {
        return jsonResponse({
          'search': [
            for (final kind in ['movie', 'show'])
              {
                'title': kind,
                'type': kind,
                'ids': {'tmdb': 10},
              },
          ],
        });
      }
      final kind = request.url.path.contains('/show') ? 'show' : 'movie';
      final body = {...media(10, kind: kind), 'trailer': 'https://www.youtube.com/watch?v=trailer'};
      return jsonResponse(request.method == 'POST' ? [body] : body);
    });
    for (final item in await source.search('Title')) {
      expect(item.trailerUrl, 'https://www.youtube.com/watch?v=trailer');
      expect((await source.fetchDetail(item)).item.trailerUrl, item.trailerUrl);
    }
    expect(requests, hasLength(5), reason: 'Trailer mapping needs no additional API requests');
  });

  test('available series status is normalized; unknown and released status stay absent', () async {
    final statuses = <String?, CatalogAirStatus?>{
      'Ended': CatalogAirStatus.ended,
      'Returning Series': CatalogAirStatus.airing,
      'continuing': CatalogAirStatus.airing,
      'Canceled': CatalogAirStatus.canceled,
      'Cancelled': CatalogAirStatus.canceled,
      ' In Production ': CatalogAirStatus.upcoming,
      'Post Production': CatalogAirStatus.upcoming,
      'Planned': CatalogAirStatus.upcoming,
      'Upcoming': CatalogAirStatus.upcoming,
      'Pilot': CatalogAirStatus.upcoming,
      'Rumored': CatalogAirStatus.upcoming,
      'Released': null,
      'unrecognized': null,
      null: null,
    };
    setup((request) {
      final id = int.parse(request.url.pathSegments.last);
      return jsonResponse({...media(id, kind: 'show'), 'status': statuses.keys.elementAt(id - 1)});
    });
    var id = 0;
    for (final entry in statuses.entries) {
      final item = CatalogItem(
        source: CatalogSourceId.mdblist,
        kind: MediaKind.show,
        title: 'Show',
        ids: CatalogItemIds(tmdb: ++id),
      );
      expect((await source.fetchDetail(item)).item.airStatus, entry.value, reason: '${entry.key}');
    }
  });

  test('provider aggregate zero and calendar release date remain distinct from community scores', () async {
    setup(
      (request) =>
          jsonResponse({...media(10, kind: 'show'), 'score': 0, 'score_average': 72, 'released': '2026-06-11'}),
    );
    final item = CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: MediaKind.show,
      title: 'Show',
      ids: const CatalogItemIds(tmdb: 10),
    );
    final detail = await source.fetchDetail(item);
    expect(detail.item.rating, 0, reason: 'Do not silently substitute score_average or a different provider');
    expect(detail.item.ratings!.single.value, 8.6);
    expect(detail.item.releaseDate, DateTime(2026, 6, 11));
    expect(detail.item.runtimeMinutes, isNull, reason: 'A series total is not an episode runtime');
    expect(detail.item.trailerUrl, isNull);
    expect(detail.item.airStatus, isNull);
  });

  test('missing and conflicting identities retain original results; no internal-ID fallback', () async {
    setup(
      (request) => request.method == 'GET'
          ? jsonResponse({
              'search': [
                {
                  'title': 'Original',
                  'type': 'movie',
                  'ids': {'tmdbid': 10, 'imdbid': 'tt0000010'},
                },
                {
                  'title': 'Missing',
                  'type': 'movie',
                  'ids': {'tmdbid': 20},
                },
              ],
            })
          : jsonResponse([
              media(10, imdb: 'tt9999999'),
              {'id': 20, 'type': 'movie', 'title': 'Wrong internal ID'},
              media(20, kind: 'show'),
            ]),
    );
    expect((await source.search('Title')).map((x) => x.title), ['Original', 'Missing']);
  });

  test('search hydration failure leaves usable results and deduplicates lookup IDs', () async {
    setup((request) {
      if (request.method == 'GET') {
        return jsonResponse({
          'search': [
            for (var i = 0; i < 2; i++)
              {
                'title': 'Original',
                'type': 'movie',
                'ids': {'tmdbid': 10},
              },
          ],
        });
      }
      expect(jsonDecode(request.body)['ids'], [10]);
      return jsonResponse({'error': 'limited'}, 429);
    });
    expect(await source.search('Title'), hasLength(2));
  });

  test('detail upgrades batch cache, preserves row context and shares full response with ratings', () async {
    setup((request) {
      if (request.url.path == '/search/any') {
        return jsonResponse({
          'search': [
            {
              'title': 'Original',
              'type': 'movie',
              'ids': {'tmdbid': 10, 'imdbid': 'tt0000010'},
            },
          ],
        });
      }
      if (request.method == 'POST') {
        return jsonResponse([media(10, imdb: 'tt0000010')]);
      }
      expect(request.url.queryParameters['append_to_response'], 'recommendations');
      return jsonResponse({
        ...media(10, imdb: 'tt0000010'),
        'recommendations': [
          {
            'id': 20,
            'mediatype': 'movie',
            'title': 'Related',
            'ids': {'tmdb': 20},
          },
        ],
      });
    });
    final item = (await source.search('Title')).single;
    expect((await source.fetchCommunityRatings(item.kind, item.ids)).single.value, 8.6);
    expect(requests.length, 2, reason: 'Batch metadata already includes community ratings');
    final detail = await source.fetchDetail(item);
    expect(detail.item.ids.tmdb, 10);
    expect(detail.item.source, CatalogSourceId.mdblist);
    expect(detail.related.single.ids.tmdb, 20);
    expect(detail.cast, isEmpty);
    await source.fetchDetail(item);
    await source.fetchCommunityRatings(item.kind, item.ids);
    expect(requests.length, 3);
  });

  test('detail identity mismatch and 404 keep the opening item', () async {
    var count = 0;
    setup((_) => ++count == 1 ? jsonResponse(media(99)) : jsonResponse({}, 404));
    const item = CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: MediaKind.movie,
      title: 'Original',
      ids: CatalogItemIds(tmdb: 10),
    );
    expect((await source.fetchDetail(item)).item, same(item));
    const other = CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: MediaKind.movie,
      title: 'Missing',
      ids: CatalogItemIds(tmdb: 20),
    );
    expect((await source.fetchDetail(other)).item, same(other));
  });

  test('cache expires and concurrent identical lookups coalesce', () async {
    var now = DateTime.utc(2026);
    setup((_) => jsonResponse(media(10)));
    await withClock(Clock(() => now), () async {
      await Future.wait([client.getMediaInfo('tmdb', 'movie', '10'), client.getMediaInfo('tmdb', 'movie', '10')]);
      expect(requests.length, 1);
      now = now.add(const Duration(hours: 2));
      await client.getMediaInfo('tmdb', 'movie', '10');
      expect(requests.length, 2);
    });
  });

  test('lookup batches enforce API ceiling before network I/O', () async {
    setup((_) => jsonResponse([]));
    await expectLater(client.getMediaInfoBatch('tmdb', 'movie', []), throwsArgumentError);
    await expectLater(client.getMediaInfoBatch('tmdb', 'movie', List.generate(201, (i) => i)), throwsArgumentError);
    expect(requests, isEmpty);
    await client.getMediaInfoBatch('tmdb', 'movie', List.generate(200, (i) => i + 1));
    expect(requests, hasLength(1));
  });

  test('large search groups split at 200 and reuse cached metadata on another search', () async {
    setup((request) {
      if (request.method == 'GET') {
        return jsonResponse({
          'search': [for (var id = 1; id <= 201; id++) media(id)],
        });
      }
      final ids = (jsonDecode(request.body)['ids'] as List).cast<int>();
      expect(ids.length, lessThanOrEqualTo(200));
      return jsonResponse(ids.reversed.map(media).toList());
    });
    expect((await source.search('Title', limit: 201)).map((x) => x.ids.tmdb), List.generate(201, (i) => i + 1));
    expect(requests.where((r) => r.method == 'POST').length, 2);
    await source.search('Title', limit: 201);
    expect(requests.where((r) => r.method == 'POST').length, 2);
  });

  test('failed metadata requests are retried and never cached', () async {
    var count = 0;
    setup((_) => ++count == 1 ? jsonResponse({}, 503) : jsonResponse(media(10)));
    await expectLater(client.getMediaInfo('tmdb', 'movie', '10'), throwsA(isA<TrackerApiException>()));
    expect((await client.getMediaInfo('tmdb', 'movie', '10'))!.data['ids']['tmdb'], 10);
    expect(requests.length, 2);
  });

  test('IMDb and TVDB-only results use supported batch identifiers', () async {
    setup((request) {
      if (request.method == 'GET') {
        return jsonResponse({
          'search': [
            {
              'title': 'Movie',
              'type': 'movie',
              'ids': {'imdb': 'tt0000010'},
            },
            {
              'title': 'Show',
              'type': 'show',
              'ids': {'tvdb': 20},
            },
          ],
        });
      }
      if (request.url.path == '/imdb/movie/') {
        expect(jsonDecode(request.body)['ids'], ['tt0000010']);
        return jsonResponse([media(10, imdb: 'tt0000010')]);
      }
      expect(request.url.path, '/tvdb/show/');
      expect(jsonDecode(request.body)['ids'], [20]);
      return jsonResponse([
        {
          ...media(20, kind: 'show'),
          'ids': {'tvdb': 20, 'tmdb': 30},
        },
      ]);
    });
    final results = await source.search('Title');
    expect(results.map((x) => x.ids.tmdb), [10, 30]);
    expect(results.last.ids.tvdb, 20);
  });

  test('single-title native rating fallback and partial metadata preserve row fields', () async {
    setup(
      (_) => jsonResponse({
        'title': 'Movie',
        'type': 'movie',
        'ids': {'tmdb': 10},
        'ratings': [
          {'source': 'letterboxd', 'value': 4.3, 'votes': 50},
          {'source': 'imdb', 'value': 0, 'votes': 0},
        ],
      }),
    );
    const item = CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: MediaKind.movie,
      title: 'Movie',
      ids: CatalogItemIds(tmdb: 10),
      genres: ['Drama'],
      overview: 'Existing',
      posterUrl: 'https://example.org/poster.jpg',
    );
    final detail = await source.fetchDetail(item);
    expect(detail.item.genres, ['Drama']);
    expect(detail.item.overview, 'Existing');
    expect(detail.item.posterUrl, item.posterUrl);
    expect(detail.item.ratings!.single.value, 8.6);
    expect(detail.related, isEmpty);
  });
}
