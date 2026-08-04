import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/anilist/anilist_media.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/catalog/catalog_cast_member.dart';
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
  Future<List<FribbMappingRow>> lookup({int? anidbId, int? tvdbId, int? tmdbId, String? imdbId}) async => [
    for (final row in rows)
      if ((anidbId != null && row.anidbId == anidbId) ||
          (tvdbId != null && row.tvdbId == tvdbId) ||
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
  'title': {'english': title, 'romaji': 'Shingeki no Kyojin', 'native': '進撃の巨人', 'userPreferred': 'Preferred'},
  'synonyms': ['The Advancing Giants', 'Preferred'],
  'format': format,
  'status': status,
  'episodes': 25,
  'duration': 24,
  'description': '<b>Humanity</b><br>fights &amp; survives.',
  'averageScore': 84,
  'meanScore': 82,
  'popularity': 812345,
  'favourites': 54321,
  'trending': 987,
  'season': 'SPRING',
  'seasonYear': 2013,
  'startDate': {'year': 2013, 'month': 4, 'day': 7},
  'endDate': {'year': 2013, 'month': 9, 'day': 29},
  'genres': ['Action', 'Drama'],
  'isAdult': isAdult,
  'source': 'MANGA',
  'countryOfOrigin': 'JP',
  'coverImage': {'extraLarge': 'https://img.anilist.co/poster/$id.jpg', 'color': '#D88932'},
  'bannerImage': 'https://img.anilist.co/banner/$id.jpg',
  'studios': {
    'nodes': [
      {'name': 'Wit Studio'},
      {'name': 'Production I.G'},
    ],
  },
  'trailer': {'id': 'abc123', 'site': 'youtube'},
  'nextAiringEpisode': {'episode': 8, 'airingAt': 2000000000, 'timeUntilAiring': 86400},
  'rankings': [
    {'rank': 1, 'type': 'POPULAR', 'format': 'TV', 'allTime': true, 'context': 'Most Popular All Time'},
    {
      'rank': 3,
      'type': 'RATED',
      'format': 'TV',
      'year': 2013,
      'season': 'SPRING',
      'allTime': false,
      'context': 'Highest Rated Spring 2013',
    },
  ],
};

Map<String, dynamic> _characters() => {
  'edges': [
    {
      'role': 'MAIN',
      'node': {
        'name': {'full': 'Mikasa Ackerman'},
        'image': {'large': 'https://img.anilist.co/mikasa.jpg'},
      },
    },
  ],
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
    tmdbSeason: 2,
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
    test('parses requested fields and honors the user-preferred title', () {
      final media = AnilistMedia.fromJson(_media(id: 1, idMal: 16498)..['characters'] = _characters());

      expect(media.displayTitle, 'Preferred');
      expect(media.alternateTitles, ['Attack on Titan', 'Shingeki no Kyojin', 'The Advancing Giants']);
      expect(media.description, 'Humanity\nfights & survives.');
      expect(media.year, 2013);
      expect(media.releaseDate, DateTime.utc(2013, 4, 7));
      expect(media.finalEpisodeDate, DateTime.utc(2013, 9, 29));
      expect(media.posterUrl, 'https://img.anilist.co/poster/1.jpg');
      expect(media.backdropUrl, 'https://img.anilist.co/banner/1.jpg');
      expect(media.rating, 8.4);
      expect(media.meanRating, 8.2);
      expect(media.runtimeMinutes, 24);
      expect(media.network, 'Wit Studio');
      expect(media.mainStudios, ['Wit Studio', 'Production I.G']);
      expect(media.trailerUrl, 'https://www.youtube.com/watch?v=abc123');
      expect(media.isMovie, isFalse);
      expect(media.characters?.single.name, 'Mikasa Ackerman');
      expect(media.characters?.single.role, 'MAIN');
      expect(media.characters?.single.imageUrl, 'https://img.anilist.co/mikasa.jpg');
    });

    test('title fallbacks and missing optional metadata remain nullable', () {
      final media = AnilistMedia.fromJson({
        'id': 1,
        'title': {'english': 'English', 'romaji': 'Romaji', 'userPreferred': ' '},
        'streamingEpisodes': <Map<String, dynamic>>[],
      });

      expect(media.displayTitle, 'English');
      expect(media.alternateTitles, ['Romaji']);
      expect(media.nextAiringEpisode, isNull);
      expect(media.rankings, isNull);
      expect(media.mainStudios, isNull);
      expect(media.coverImageColor, isNull);
      expect(media.streamingEpisodes, isNull);
      expect(media.releaseDate, isNull);
      expect(media.finalEpisodeDate, isNull);
      expect(media.characters, isNull);
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

    test('trending row maps rich metadata while clamping the page size', () async {
      responder = (request) {
        final body = _requestBody(request);
        final variables = body['variables'] as Map<String, dynamic>;
        expect((body['query'] as String), contains('isAdult: false'));
        expect(variables['sort'], ['TRENDING_DESC']);
        expect(variables['perPage'], 50);
        return _data({
          'Page': {
            'pageInfo': {'hasNextPage': true},
            'media': [_media(id: 16498, idMal: 16498)..['characters'] = _characters()],
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
      expect(item.title, 'Preferred');
      expect(item.originalTitle, '進撃の巨人');
      expect(item.altTitles, ['Attack on Titan', 'Shingeki no Kyojin', '進撃の巨人', 'The Advancing Giants']);
      expect(item.format, CatalogFormat.tv);
      expect(item.studios, ['Wit Studio', 'Production I.G']);
      expect(item.network, 'Wit Studio');
      expect(item.broadcastSeason?.name, CatalogSeasonName.spring);
      expect(item.broadcastSeason?.year, 2013);
      expect(item.accentColor, '#d88932');
      expect(item.releaseDate, DateTime.utc(2013, 4, 7));
      expect(item.endDate, DateTime.utc(2013, 9, 29));
      expect(item.sourceMaterial, CatalogSourceMaterial.manga);
      expect(item.countries, ['JP']);
      expect(item.ratings?.single.source, 'anilist');
      expect(item.ratings?.single.value, 8.2);
      expect(item.audience?.listed, 812345);
      expect(item.audience?.favorited, 54321);
      expect(item.audience?.trendingActivity, 987);
      expect(item.nextEpisode?.episode, 8);
      expect(item.nextEpisode?.airsAt, DateTime.fromMillisecondsSinceEpoch(2000000000000, isUtc: true));
      expect(item.ranks, hasLength(2));
      expect(item.ranks?[0].scope, CatalogRankScope.popular);
      expect(item.ranks?[0].allTime, isTrue);
      expect(item.ranks?[0].year, isNull);
      expect(item.ranks?[1].scope, CatalogRankScope.rated);
      expect(item.ranks?[1].allTime, isFalse);
      expect(item.ranks?[1].year, 2013);
      expect(item.ranks?[1].season, CatalogSeasonName.spring);
      expect(item.cast, hasLength(1));
      expect(item.cast?.single.name, 'Mikasa Ackerman');
      expect(item.cast?.single.secondary, 'MAIN');
      expect(item.cast?.single.imageUrl, 'https://img.anilist.co/mikasa.jpg');
    });

    test('sequel entries preserve alternate-title order and both Fribb season numbers', () async {
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        expect(query, contains('native'));
        expect(query, contains('synonyms'));
        final sequel = _media(id: 35760, idMal: 35760, title: 'Attack on Titan Season 3');
        sequel['title'] = {
          'english': 'Attack on Titan Season 3',
          'userPreferred': 'Preferred Season 3',
          'romaji': 'Shingeki no Kyojin Season 3',
          'native': '進撃の巨人 Season 3',
        };
        sequel['synonyms'] = ['', 'Attack on Titan Season 3', 'AoT 3'];
        return _data({
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'media': [sequel],
          },
        });
      };

      final item = (await source.fetchRow(CatalogRowId.trendingAnime)).items.single;

      // The display title is now `userPreferred` (AniList honours the viewer's
      // title-language setting). The English title stays in `altTitles`, so the
      // reverse library lookup still has it to match on.
      expect(item.title, 'Preferred Season 3');
      expect(item.altTitles, ['Attack on Titan Season 3', 'Shingeki no Kyojin Season 3', '進撃の巨人 Season 3', 'AoT 3']);
      expect(item.season, const ExternalSeasonRef(tvdb: 3, tmdb: 2));
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

    test('row and detail documents select metadata on the deliberate request path', () async {
      responder = (request) {
        final query = _requestBody(request)['query'] as String;
        if (query.contains('Page(')) {
          return _data({
            'Page': {
              'pageInfo': {'hasNextPage': false},
              'media': <Map<String, dynamic>>[],
            },
          });
        }
        return _data({'Media': <String, dynamic>{}});
      };

      await client.getTrendingAnime();
      final rowQuery = _requestBody(requests.single)['query'] as String;
      expect(rowQuery, contains('nextAiringEpisode {'));
      expect(rowQuery, contains('rankings {'));
      expect(rowQuery, contains('episode'));
      expect(rowQuery, contains('airingAt'));
      expect(rowQuery, contains('timeUntilAiring'));
      expect(rowQuery, contains('rank'));
      expect(rowQuery, contains('type'));
      expect(rowQuery, contains('format'));
      expect(rowQuery, contains('year'));
      expect(rowQuery, contains('season'));
      expect(rowQuery, contains('allTime'));
      expect(rowQuery, contains('context'));
      expect(rowQuery, contains('meanScore'));
      expect(rowQuery, contains('popularity'));
      expect(rowQuery, contains('favourites'));
      expect(rowQuery, contains('trending'));
      expect(rowQuery, contains('native'));
      expect(rowQuery, contains('synonyms'));
      expect(rowQuery, contains('source'));
      expect(rowQuery, contains('countryOfOrigin'));
      expect(rowQuery, contains('endDate {'));
      expect(rowQuery, contains('color'));
      expect(rowQuery, contains('month'));
      expect(rowQuery, contains('day'));
      expect(rowQuery, isNot(contains('externalLinks {')));
      expect(rowQuery, isNot(contains('streamingEpisodes {')));
      expect(rowQuery, contains('characters('));
      expect(rowQuery, contains('perPage: 6'));
      expect(rowQuery, contains('sort: [ROLE, RELEVANCE]'));
      expect(rowQuery, contains('role'));
      expect(rowQuery, contains('full'));
      expect(rowQuery, contains('large'));
      expect(rowQuery, contains('medium'));
      expect(rowQuery, isNot(contains('voiceActors')));
      expect(rowQuery, isNot(contains('mediaConnection')));
      expect(rowQuery, isNot(contains('relations(')));
      expect(rowQuery, isNot(contains('staff(')));
      expect(rowQuery, isNot(contains('tags {')));

      requests.clear();
      await client.getAnimeDetail(16498, castLimit: 200, relatedLimit: 0);
      final detailBody = _requestBody(requests.single);
      final detailQuery = detailBody['query'] as String;
      final variables = detailBody['variables'] as Map<String, dynamic>;
      expect(detailQuery, contains('tags {'));
      expect(detailQuery, contains('externalLinks {'));
      expect(detailQuery, contains('streamingEpisodes {'));
      expect(detailQuery, contains('name'));
      expect(detailQuery, contains('rank'));
      expect(detailQuery, contains('isMediaSpoiler'));
      expect(detailQuery, contains('site'));
      expect(detailQuery, contains('url'));
      expect(detailQuery, contains('title'));
      expect(detailQuery, contains('thumbnail'));
      expect(detailQuery, contains('staff(page: 1, perPage: \$staffPerPage)'));
      expect(detailQuery, contains('characters(page: 1, perPage: \$castPerPage, sort: [ROLE, RELEVANCE])'));
      expect(detailQuery, contains('recommendations(page: 1, perPage: \$relatedPerPage)'));
      expect(detailQuery, contains('relations(page: 1, perPage: \$relatedPerPage)'));
      expect(detailQuery, contains('relationType(version: 2)'));
      expect(variables['castPerPage'], 50);
      expect(variables['relatedPerPage'], 1);
      expect(variables['staffPerPage'], 8);
    });

    test('unsupported rows throw instead of silently returning empty', () {
      expect(() => source.fetchRow(CatalogRowId.recommendedMovies), throwsA(isA<ArgumentError>()));
    });

    test('one-character search requests AniList while whitespace-only does not', () async {
      final empty = await source.search('   ');
      expect(empty, isEmpty);
      expect(requests, isEmpty);

      final results = await source.search(' a ');
      expect(requests, hasLength(1));
      expect(results.single.cast, isNull);
      final body = _requestBody(requests.single);
      final variables = body['variables'] as Map<String, dynamic>;
      expect(variables['search'], 'a');
      expect(body['query'] as String, isNot(contains('characters(')));
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

    test('fetchDetail without cached cast requests live characters with the consolidated detail', () async {
      responder = (request) {
        final media = _media(id: 16498, idMal: 16498)
          ..addAll({
            'tags': [
              {'name': 'Military', 'rank': 88, 'isMediaSpoiler': false},
              {'name': 'Hidden Identity', 'rank': 72, 'isMediaSpoiler': true},
            ],
            'externalLinks': [
              {'site': 'AniList', 'url': 'https://anilist.co/anime/16498'},
              {'site': 'Unsafe', 'url': 'file:///tmp/not-opened'},
            ],
            'streamingEpisodes': [
              {
                'title': 'Episode 1',
                'thumbnail': 'https://img.example/episode-1.jpg',
                'url': 'https://crunchyroll.example/episode-1',
                'site': 'Crunchyroll',
              },
            ],
            'staff': {
              'edges': [
                {
                  'role': 'Director',
                  'node': {
                    'name': {'full': 'Tetsuro Araki'},
                  },
                },
                {
                  'role': 'Series Composition',
                  'node': {
                    'name': {'full': 'Yasuko Kobayashi'},
                  },
                },
                {
                  'role': 'Music',
                  'node': {
                    'name': {'full': 'Hiroyuki Sawano'},
                  },
                },
                {
                  'role': 'Character Design',
                  'node': {
                    'name': {'full': 'Kyoji Asano'},
                  },
                },
              ],
            },
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
            'recommendations': {
              'nodes': [
                {'mediaRecommendation': _media(id: 21519, idMal: 32281, title: 'Your Name.', format: 'MOVIE')},
                {'mediaRecommendation': _media(id: 999, title: 'Adult', isAdult: true)},
              ],
            },
            'relations': {
              'edges': [
                {'relationType': 'SEQUEL', 'node': _media(id: 35760, idMal: 35760, title: 'Attack on Titan Season 3')},
                {'relationType': 'SOURCE', 'node': _media(id: 1000, title: 'Attack on Titan Manga')},
              ],
            },
          });
        return _data({'Media': media});
      };
      const item = CatalogItem(
        source: CatalogSourceId.anilist,
        kind: MediaKind.show,
        title: 'Row title',
        ids: CatalogItemIds(anilist: 16498),
        ranks: [CatalogRank(rank: 99, scope: CatalogRankScope.trending)],
      );

      final detail = await source.fetchDetail(item);

      expect(requests, hasLength(1));
      expect(detail.item.title, 'Preferred');
      expect(detail.item.ranks?.single.rank, 99);
      expect(detail.cast.single.name, 'Mikasa Ackerman');
      expect(detail.cast.single.secondary, 'MAIN');
      final detailBody = _requestBody(requests.single);
      final detailQuery = detailBody['query'] as String;
      final detailVariables = detailBody['variables'] as Map<String, dynamic>;
      expect(detailQuery, contains('characters(page: 1, perPage: \$castPerPage, sort: [ROLE, RELEVANCE])'));
      expect(detailVariables['castPerPage'], 20);
      expect(detail.related, hasLength(1));
      expect(detail.related.single.kind, MediaKind.movie);
      expect(detail.related.single.ids.tmdb, 372058);
      expect(detail.relations, hasLength(2));
      expect(detail.relations[0].type, CatalogRelationType.sequel);
      expect(detail.relations[0].items.single.ids.anilist, 35760);
      expect(detail.relations[1].type, CatalogRelationType.other);
      expect(detail.relations[1].items.single.ids.anilist, 1000);
      expect(detail.item.credits?.map((credit) => credit.role), [
        CatalogCreditRole.director,
        CatalogCreditRole.writer,
        CatalogCreditRole.composer,
      ]);
      expect(detail.item.tags, hasLength(2));
      expect(detail.item.tags?[1].isSpoiler, isTrue);
      expect(detail.item.links, hasLength(2));
      expect(detail.item.links?[0].label, 'AniList');
      expect(detail.item.links?[0].isStreaming, isFalse);
      expect(detail.item.links?[1].label, 'Crunchyroll');
      expect(detail.item.links?[1].isStreaming, isTrue);
    });

    test('fetchDetail serves cached row cast without selecting characters', () async {
      responder = (request) {
        final body = _requestBody(request);
        expect(body['query'] as String, isNot(contains('characters(')));
        final variables = body['variables'] as Map<String, dynamic>;
        expect(variables.containsKey('castPerPage'), isFalse);
        return _data({
          'Media': {
            'id': 16498,
            'title': {'userPreferred': 'Attack on Titan'},
          },
        });
      };
      const item = CatalogItem(
        source: CatalogSourceId.anilist,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        ids: CatalogItemIds(anilist: 16498),
        cast: [
          CatalogCastMember(name: 'Mikasa Ackerman', secondary: 'MAIN', imageUrl: 'https://img.anilist.co/mikasa.jpg'),
        ],
      );

      final detail = await source.fetchDetail(item);

      expect(requests, hasLength(1));
      expect(detail.cast, hasLength(1));
      expect(detail.cast.single.name, 'Mikasa Ackerman');
      expect(detail.cast.single.secondary, 'MAIN');
      expect(detail.cast.single.imageUrl, 'https://img.anilist.co/mikasa.jpg');
    });

    test('fetchDetail treats absent and empty optional collections as normal', () async {
      responder = (_) => _data({
        'Media': {
          'id': 16498,
          'title': {'userPreferred': 'Attack on Titan'},
          'externalLinks': <Map<String, dynamic>>[],
          'streamingEpisodes': <Map<String, dynamic>>[],
        },
      });
      const item = CatalogItem(
        source: CatalogSourceId.anilist,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        ids: CatalogItemIds(anilist: 16498),
      );

      final detail = await source.fetchDetail(item);

      expect(detail.item.links, isNull);
      expect(detail.item.tags, isNull);
      expect(detail.item.credits, isNull);
      expect(detail.cast, isEmpty);
      expect(detail.related, isEmpty);
      expect(detail.relations, isEmpty);
      expect(requests, hasLength(1));
    });

    test('fetchDetail needs no request when the item has no AniList id', () async {
      const item = CatalogItem(
        source: CatalogSourceId.anilist,
        kind: MediaKind.show,
        title: 'Unmapped',
        ids: CatalogItemIds(mal: 1),
      );

      final detail = await source.fetchDetail(item);

      expect(detail.item, same(item));
      expect(detail.cast, isEmpty);
      expect(detail.related, isEmpty);
      expect(detail.relations, isEmpty);
      expect(requests, isEmpty);
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
