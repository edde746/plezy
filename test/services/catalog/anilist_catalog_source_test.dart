import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/anilist/anilist_media.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/trackers/fribb_mapping_row.dart';
import 'package:plezy/services/catalog/anilist_catalog_source.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/trackers/anilist/anilist_client.dart';
import 'package:plezy/services/trackers/fribb_mapping_store.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'access',
    refreshToken: null,
    expiresAt: now + 86400,
    scope: null,
    createdAt: now - 3600,
    username: 'alice',
  );
}

class _FakeFribb implements FribbMappingLookup {
  final List<FribbMappingRow> rows;

  _FakeFribb(this.rows);

  @override
  Future<List<FribbMappingRow>> lookup({int? tvdbId, int? tmdbId, String? imdbId}) async => [
    for (final row in rows)
      if ((tvdbId != null && row.tvdbId == tvdbId) ||
          (tmdbId != null && (row.tmdbIds?.contains(tmdbId) ?? false)) ||
          (imdbId != null && (row.imdbIds?.contains(imdbId) ?? false)))
        row,
  ];

  @override
  Future<FribbMappingRow?> lookupByMal(int malId) async => rows.where((row) => row.malId == malId).firstOrNull;
}

Map<String, dynamic> _media({
  required int id,
  int? idMal,
  String title = 'Attack on Titan',
  String format = 'TV',
  String status = 'RELEASING',
  bool isAdult = false,
}) => {
  'id': id,
  'idMal': ?idMal,
  'title': {'english': title, 'romaji': 'Shingeki no Kyojin', 'userPreferred': 'Preferred'},
  'format': format,
  'status': status,
  'episodes': 25,
  'duration': 24,
  'description': '<b>Humanity</b><br>fights &amp; survives.',
  'averageScore': 84,
  'season': 'SPRING',
  'seasonYear': 2013,
  'startDate': {'year': 2013},
  'genres': ['Action', 'Drama'],
  'isAdult': isAdult,
  'coverImage': {'extraLarge': 'https://img.anilist.co/poster/$id.jpg'},
  'bannerImage': 'https://img.anilist.co/banner/$id.jpg',
  'studios': {
    'nodes': [
      {'name': 'Wit Studio'},
    ],
  },
  'trailer': {'id': 'abc123', 'site': 'youtube'},
};

http.Response _data(Map<String, dynamic> data, {int status = 200, Map<String, String>? headers}) =>
    http.Response(json.encode({'data': data}), status, headers: {'content-type': 'application/json', ...?headers});

Map<String, dynamic> _requestBody(http.Request request) => json.decode(request.body) as Map<String, dynamic>;

void main() {
  const season1 = FribbMappingRow(
    anilistId: 16498,
    malId: 16498,
    tvdbId: 267440,
    tvdbSeason: 1,
    imdbIds: ['tt2560140'],
  );
  const season3 = FribbMappingRow(
    anilistId: 35760,
    malId: 35760,
    tvdbId: 267440,
    tvdbSeason: 3,
    imdbIds: ['tt2560140'],
  );
  const movie = FribbMappingRow(
    anilistId: 21519,
    malId: 32281,
    tmdbIds: [372058],
    imdbIds: ['tt5311514'],
    type: 'MOVIE',
  );

  group('AnilistMedia', () {
    test('parses requested fields and strips AniList HTML', () {
      final media = AnilistMedia.fromJson(_media(id: 1, idMal: 16498));

      expect(media.displayTitle, 'Attack on Titan');
      expect(media.description, 'Humanity\nfights & survives.');
      expect(media.year, 2013);
      expect(media.posterUrl, 'https://img.anilist.co/poster/1.jpg');
      expect(media.backdropUrl, 'https://img.anilist.co/banner/1.jpg');
      expect(media.rating, 8.4);
      expect(media.runtimeMinutes, 24);
      expect(media.network, 'Wit Studio');
      expect(media.trailerUrl, 'https://www.youtube.com/watch?v=abc123');
      expect(media.isMovie, isFalse);
    });

    test('stripHtml handles line breaks, tags, entities, and empty input', () {
      expect(
        AnilistMedia.stripHtml('<i>A &quot;title&quot;</i><br />B &lt; C &gt; D&nbsp;&#39;x&#39;'),
        'A "title"\nB < C > D \'x\'',
      );
      expect(AnilistMedia.stripHtml('<b></b>'), isNull);
      expect(AnilistMedia.stripHtml(null), isNull);
    });
  });

  group('AnilistCatalogSource', () {
    late List<http.Request> requests;
    late FutureOr<http.Response> Function(http.Request request) responder;
    late AnilistClient client;
    late AnilistCatalogSource source;

    setUp(() {
      requests = [];
      responder = (request) {
        final body = _requestBody(request);
        final query = body['query'] as String;
        if (query.contains('Viewer { id }')) {
          return _data({
            'Viewer': {'id': 7},
          });
        }
        if (query.contains('MediaListCollection')) {
          return _data({
            'MediaListCollection': {
              'hasNextChunk': false,
              'lists': [
                {
                  'isCustomList': false,
                  'entries': [
                    {'media': _media(id: 16498, idMal: 16498)},
                  ],
                },
              ],
            },
          });
        }
        return _data({
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'media': [_media(id: 16498, idMal: 16498)],
          },
        });
      };
      client = AnilistClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) async {
          requests.add(request);
          return responder(request);
        }),
      );
      source = AnilistCatalogSource(client, fribb: _FakeFribb(const [season1, season3, movie]));
    });

    tearDown(() {
      source.dispose();
      client.dispose();
    });

    test('trending query clamps page size and enriches every external id', () async {
      responder = (request) {
        final body = _requestBody(request);
        final variables = body['variables'] as Map<String, dynamic>;
        expect((body['query'] as String), contains('isAdult: false'));
        expect(variables['sort'], ['TRENDING_DESC']);
        expect(variables['perPage'], 50);
        return _data({
          'Page': {
            'pageInfo': {'hasNextPage': true},
            'media': [_media(id: 16498, idMal: 16498)],
          },
        });
      };

      final page = await source.fetchRow(CatalogRowId.trendingAnime, limit: 500);

      expect(page.hasMore, isTrue);
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.source, CatalogSourceId.anilist);
      expect(item.ids.anilist, 16498);
      expect(item.ids.mal, 16498);
      expect(item.ids.tvdb, 267440);
      expect(item.ids.imdb, 'tt2560140');
      expect(item.overview, 'Humanity\nfights & survives.');
      expect(item.airStatus, CatalogAirStatus.airing);
      expect(item.episodeCount, 25);
    });

    test('seasonal client sends season and year variables', () async {
      responder = (request) {
        final variables = _requestBody(request)['variables'] as Map<String, dynamic>;
        expect(variables['season'], 'SPRING');
        expect(variables['seasonYear'], 2026);
        expect(variables['sort'], ['POPULARITY_DESC']);
        return _data({
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'media': <Map<String, dynamic>>[],
          },
        });
      };

      final page = await client.getSeasonalAnime('SPRING', 2026);
      expect(page.items, isEmpty);
    });

    test('currentAnimeSeason handles December rollover and season boundaries', () {
      expect(AnilistCatalogSource.currentAnimeSeason(DateTime(2025, 12, 1)), (season: 'WINTER', year: 2026));
      expect(AnilistCatalogSource.currentAnimeSeason(DateTime(2026, 1, 1)), (season: 'WINTER', year: 2026));
      expect(AnilistCatalogSource.currentAnimeSeason(DateTime(2026, 4, 1)), (season: 'SPRING', year: 2026));
      expect(AnilistCatalogSource.currentAnimeSeason(DateTime(2026, 7, 1)), (season: 'SUMMER', year: 2026));
      expect(AnilistCatalogSource.currentAnimeSeason(DateTime(2026, 10, 1)), (season: 'FALL', year: 2026));
    });

    test('planning row caches viewer id, skips custom lists, and deduplicates media', () async {
      var viewerRequests = 0;
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        if (query.contains('Viewer { id }')) {
          viewerRequests++;
          return _data({
            'Viewer': {'id': 7},
          });
        }
        expect(query, contains('status: PLANNING'));
        return _data({
          'MediaListCollection': {
            'hasNextChunk': true,
            'lists': [
              {
                'isCustomList': false,
                'entries': [
                  {'media': _media(id: 16498, idMal: 16498)},
                  {'media': _media(id: 16498, idMal: 16498)},
                ],
              },
              {
                'isCustomList': true,
                'entries': [
                  {'media': _media(id: 999, idMal: 999)},
                ],
              },
            ],
          },
        });
      };

      final first = await source.fetchRow(CatalogRowId.watchlist);
      final second = await source.fetchRow(CatalogRowId.watchlist);

      expect(viewerRequests, 1);
      expect(first.items.map((item) => item.ids.anilist), [16498]);
      expect(first.hasMore, isTrue);
      expect(second.items, hasLength(1));
    });

    test('planning ids query sends a valid GraphQL field selection', () async {
      await client.getPlanningIdsPage(7);

      final query = _requestBody(requests.single)['query'] as String;
      expect(query, contains('id idMal'));
      expect(query, isNot(contains(r'id\nidMal')));
    });

    test('unsupported rows throw instead of silently returning empty', () {
      expect(() => source.fetchRow(CatalogRowId.recommendedMovies), throwsA(isA<ArgumentError>()));
    });

    test('one-character search requests AniList while whitespace-only does not', () async {
      final empty = await source.search('   ');
      expect(empty, isEmpty);
      expect(requests, isEmpty);

      await source.search(' a ');
      expect(requests, hasLength(1));
      final variables = _requestBody(requests.single)['variables'] as Map<String, dynamic>;
      expect(variables['search'], 'a');
    });

    test('watchlist snapshot matches the MAL identity form alone', () async {
      await source.ensureWatchlistLoaded();

      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)), isTrue);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(anilist: 999)), isFalse);
    });

    test('resolveItemIds prefers season one for shows and movie rows for movies', () async {
      final showIds = await source.resolveItemIds(MediaKind.show, const ExternalIds(tvdb: 267440, imdb: 'tt2560140'));
      final movieIds = await source.resolveItemIds(MediaKind.movie, const ExternalIds(tmdb: 372058, imdb: 'tt5311514'));

      expect(showIds?.anilist, 16498);
      expect(showIds?.mal, 16498);
      expect(movieIds?.anilist, 21519);
      expect(movieIds?.mal, 32281);
    });

    test('resolveItemIds returns null when the matching row lacks AniList id', () async {
      final noAniListSource = AnilistCatalogSource(
        client,
        fribb: _FakeFribb(const [FribbMappingRow(malId: 1, tvdbId: 2)]),
      );
      addTearDown(noAniListSource.dispose);

      expect(await noAniListSource.resolveItemIds(MediaKind.show, const ExternalIds(tvdb: 2)), isNull);
    });

    test('add writes PLANNING without a progress field', () async {
      responder = (request) {
        final body = _requestBody(request);
        final query = body['query'] as String;
        final variables = body['variables'] as Map<String, dynamic>;
        expect(query, contains('SaveMediaListEntry'));
        expect(query, isNot(contains('progress')));
        expect(variables, {'mediaId': 16498, 'status': 'PLANNING'});
        return _data({
          'SaveMediaListEntry': {'id': 1},
        });
      };

      await source.addToWatchlist(MediaKind.show, const CatalogItemIds(anilist: 16498));
      expect(requests, hasLength(1));
    });

    test('remove is a no-op when the media-list entry is already absent', () async {
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        expect(query, contains('mediaListEntry'));
        return _data({
          'Media': {'mediaListEntry': null},
        });
      };

      await source.removeFromWatchlist(MediaKind.show, const CatalogItemIds(anilist: 16498));
      expect(requests, hasLength(1));
    });

    test('failed mutation restores optimistic watchlist membership', () async {
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        if (query.contains('Viewer { id }')) {
          return _data({
            'Viewer': {'id': 7},
          });
        }
        if (query.contains('MediaListCollection')) {
          return _data({
            'MediaListCollection': {
              'hasNextChunk': false,
              'lists': [
                {
                  'isCustomList': false,
                  'entries': [
                    {
                      'media': {'id': 16498, 'idMal': 16498},
                    },
                  ],
                },
              ],
            },
          });
        }
        if (query.contains('mediaListEntry')) {
          return _data({
            'Media': {
              'mediaListEntry': {'id': 99},
            },
          });
        }
        return http.Response('failed', 500);
      };
      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(anilist: 16498)), isTrue);

      await expectLater(
        source.removeFromWatchlist(MediaKind.show, const CatalogItemIds(anilist: 16498)),
        throwsA(isA<TrackerApiException>()),
      );
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(anilist: 16498)), isTrue);
    });

    test('cast and related map characters and enriched recommendations', () async {
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        if (query.contains('characters(')) {
          return _data({
            'Media': {
              'characters': {
                'edges': [
                  {
                    'role': 'MAIN',
                    'node': {
                      'name': {'full': 'Mikasa Ackerman'},
                      'image': {'large': 'https://img.anilist.co/mikasa.jpg'},
                    },
                  },
                ],
              },
            },
          });
        }
        return _data({
          'Media': {
            'recommendations': {
              'nodes': [
                {'mediaRecommendation': _media(id: 21519, idMal: 32281, title: 'Your Name.', format: 'MOVIE')},
                {'mediaRecommendation': _media(id: 999, title: 'Adult', isAdult: true)},
              ],
            },
          },
        });
      };
      const item = CatalogItem(
        source: CatalogSourceId.anilist,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        ids: CatalogItemIds(anilist: 16498),
      );

      final cast = await source.fetchCast(item);
      final related = await source.fetchRelated(item);

      expect(cast.single.name, 'Mikasa Ackerman');
      expect(cast.single.secondary, 'MAIN');
      expect(related, hasLength(1));
      expect(related.single.kind, MediaKind.movie);
      expect(related.single.ids.tmdb, 372058);
    });
  });

  group('AnilistClient 429 handling', () {
    test('throws the shared rate-limit exception without blocking or retrying', () async {
      var calls = 0;
      final client = AnilistClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) async {
          calls++;
          return http.Response('limited', 429, headers: {'retry-after': '60'});
        }),
      );
      addTearDown(client.dispose);

      await expectLater(
        client.getViewerId(),
        throwsA(
          isA<TrackerRateLimitException>()
              .having((error) => error.service, 'service', TrackerService.anilist)
              .having((error) => error.retryAfterSeconds, 'retryAfterSeconds', 60),
        ),
      );
      expect(calls, 1);
    });
  });
}
