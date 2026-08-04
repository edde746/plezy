import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/trackers/fribb_mapping_row.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/mal_catalog_source.dart';
import 'package:plezy/services/trackers/fribb_mapping_store.dart';
import 'package:plezy/services/trackers/mal/mal_client.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'access',
    refreshToken: 'refresh',
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

Map<String, dynamic> _node({
  required int id,
  required String title,
  String? en,
  String? ja,
  List<String>? synonyms,
  String mediaType = 'tv',
  String status = 'finished_airing',
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'title': title,
  if (en != null || ja != null || synonyms != null) 'alternative_titles': {'en': ?en, 'ja': ?ja, 'synonyms': ?synonyms},
  'media_type': mediaType,
  'main_picture': {'large': 'https://cdn.myanimelist.net/images/anime/$id.jpg'},
  'status': status,
  'num_episodes': 25,
  'num_scoring_users': 2326268,
  'studios': [
    {'id': 858, 'name': 'Wit Studio'},
  ],
  ...extra,
};

Map<String, dynamic> _pageBody(
  List<Map<String, dynamic>> nodes, {
  bool hasMore = false,
  List<int?> rankingRanks = const [],
}) => {
  'data': [
    for (var i = 0; i < nodes.length; i++)
      {
        'node': nodes[i],
        if (i < rankingRanks.length && rankingRanks[i] != null) 'ranking': {'rank': rankingRanks[i]},
      },
  ],
  'paging': {if (hasMore) 'next': 'https://api.myanimelist.net/v2/whatever?offset=2'},
};

const _expectedCatalogFields =
    'id,title,main_picture,alternative_titles,start_date,synopsis,mean,'
    'genres,media_type,rating,num_episodes,average_episode_duration,start_season,'
    'status,studios,num_scoring_users,broadcast,popularity,num_list_users,rank,'
    'nsfw,source,end_date';
const _expectedDetailFields =
    '$_expectedCatalogFields,recommendations{$_expectedCatalogFields},'
    'related_anime{$_expectedCatalogFields},statistics,background';

void main() {
  // Attack on Titan: split-cour show — one Fribb row per season, same tvdb id.
  const aotSeason1 = FribbMappingRow(
    malId: 16498,
    anilistId: 16498,
    simklId: 43665,
    tvdbId: 267440,
    tvdbSeason: 1,
    imdbIds: ['tt2560140'],
  );
  const aotSeason3 = FribbMappingRow(
    malId: 35760,
    tvdbId: 267440,
    tvdbSeason: 3,
    tmdbSeason: 2,
    imdbIds: ['tt2560140'],
  );
  // An anime movie.
  const yourName = FribbMappingRow(malId: 32281, tmdbIds: [372058], imdbIds: ['tt5311514'], type: 'MOVIE');

  group('MalCatalogSource', () {
    late List<http.Request> requests;
    late List<http.Response Function(http.Request)> handlers;
    late MalClient client;
    late MalCatalogSource source;

    setUp(() {
      requests = [];
      handlers = [];
      client = MalClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (handlers.isNotEmpty) return handlers.removeAt(0)(request);
          return http.Response(
            json.encode(
              _pageBody([
                _node(
                  id: 16498,
                  title: 'Shingeki no Kyojin',
                  en: 'Attack on Titan',
                  ja: '進撃の巨人',
                  synonyms: const ['AoT'],
                  extra: const {
                    'start_season': {'year': 2013, 'season': 'spring'},
                    'broadcast': {'day_of_the_week': 'sunday', 'start_time': '23:30'},
                    'popularity': 1,
                    'num_list_users': 4100000,
                    'rank': 2,
                    'nsfw': 'black',
                    'source': 'manga',
                    'end_date': '2021-04-19',
                  },
                ),
                _node(id: 32281, title: 'Kimi no Na wa.', en: 'Your Name.', mediaType: 'movie'),
              ]),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      source = MalCatalogSource(client, fribb: _FakeFribb(const [aotSeason1, aotSeason3, yourName]));
    });

    tearDown(() {
      source.dispose();
      client.dispose();
    });

    test('fetchRow(watchlist) requests Plan to Watch and enriches ids via Fribb', () async {
      final page = await source.fetchRow(CatalogRowId.watchlist);

      final request = requests.single;
      expect(request.url.path, '/v2/users/@me/animelist');
      expect(request.url.queryParameters['status'], 'plan_to_watch');
      expect(request.url.queryParameters['fields'], _expectedCatalogFields);

      expect(page.items, hasLength(2));
      final show = page.items[0];
      expect(show.kind, MediaKind.show);
      expect(show.title, 'Attack on Titan');
      expect(show.ids.mal, 16498);
      expect(show.ids.tvdb, 267440);
      expect(show.ids.imdb, 'tt2560140');
      expect(show.ids.anilist, 16498);
      expect(show.ids.simkl, 43665);
      expect(show.source, CatalogSourceId.mal);

      // List-endpoint metadata flows through to the item.
      expect(show.airStatus, CatalogAirStatus.ended);
      expect(show.episodeCount, 25);
      expect(show.votes, 2326268);
      expect(show.network, 'Wit Studio');
      expect(show.originalTitle, 'Shingeki no Kyojin');
      expect(show.altTitles, ['Shingeki no Kyojin', '進撃の巨人', 'AoT']);
      expect(show.broadcastSeason?.name, CatalogSeasonName.spring);
      expect(show.broadcastSeason?.year, 2013);
      expect(show.broadcast?.weekday, DateTime.sunday);
      expect(show.broadcast?.time, '23:30');
      expect(show.broadcast?.timezone, 'Asia/Tokyo');
      expect(show.isAdult, isTrue);
      expect(show.sourceMaterial, CatalogSourceMaterial.manga);
      expect(show.endDate, DateTime(2021, 4, 19));
      expect(show.audience?.listed, 4100000);
      expect(show.ranks, hasLength(2));
      expect(show.ranks?[0].scope, CatalogRankScope.popular);
      expect(show.ranks?[0].rank, 1);
      expect(show.ranks?[1].scope, CatalogRankScope.rated);
      expect(show.ranks?[1].rank, 2);

      final movie = page.items[1];
      expect(movie.kind, MediaKind.movie);
      expect(movie.ids.mal, 32281);
      expect(movie.ids.tmdb, 372058);
      expect(movie.posterUrl, 'https://cdn.myanimelist.net/images/anime/32281.jpg');
      // finished_airing on a movie is noise, and movies have no episode chip.
      expect(movie.airStatus, isNull);
      expect(movie.episodeCount, isNull);
      expect(movie.season, isNull);
      expect(movie.broadcast, isNull);
      expect(movie.isAdult, isNull);
      expect(movie.sourceMaterial, isNull);
      expect(movie.endDate, isNull);
      expect(movie.ranks, isNull);
      expect(movie.audience, isNull);
    });

    test('sequel entries preserve alternate-title order and both Fribb season numbers', () async {
      handlers.add(
        (request) => http.Response(
          json.encode(
            _pageBody([
              _node(
                id: 35760,
                title: 'Shingeki no Kyojin Season 3',
                en: 'Attack on Titan Season 3',
                ja: '進撃の巨人 Season 3',
                synonyms: ['', 'Attack on Titan Season 3', 'AoT 3'],
              ),
            ]),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final item = (await source.fetchRow(CatalogRowId.watchlist)).items.single;

      expect(item.title, 'Attack on Titan Season 3');
      expect(item.altTitles, ['Shingeki no Kyojin Season 3', '進撃の巨人 Season 3', 'AoT 3']);
      expect(item.season, const ExternalSeasonRef(tvdb: 3, tmdb: 2));
    });

    test('ranking sidecars map to the scope implied by each row', () async {
      handlers.add(
        (request) => http.Response(
          json.encode(
            _pageBody([_node(id: 16498, title: 'Shingeki no Kyojin')], hasMore: true, rankingRanks: const [12]),
          ),
          200,
        ),
      );
      handlers.add(
        (request) => http.Response(
          json.encode(
            _pageBody(
              [_node(id: 32281, title: 'Kimi no Na wa.', mediaType: 'movie')],
              rankingRanks: const [7],
            ),
          ),
          200,
        ),
      );

      final airing = await source.fetchRow(CatalogRowId.airingAnime, page: 3, limit: 50);
      final popular = await source.fetchRow(CatalogRowId.popularAnime);

      expect(requests[0].url.path, '/v2/anime/ranking');
      expect(requests[0].url.queryParameters['ranking_type'], 'airing');
      expect(requests[0].url.queryParameters['limit'], '50');
      expect(requests[0].url.queryParameters['offset'], '100');
      expect(requests[0].url.queryParameters['fields'], _expectedCatalogFields);
      expect(airing.hasMore, isTrue);
      expect(airing.items.single.ranks, hasLength(1));
      expect(airing.items.single.ranks?.single.rank, 12);
      expect(airing.items.single.ranks?.single.scope, CatalogRankScope.airing);
      expect(airing.items.single.ranks?.single.allTime, isTrue);

      expect(requests[1].url.queryParameters['ranking_type'], 'bypopularity');
      expect(popular.items.single.ranks, hasLength(1));
      expect(popular.items.single.ranks?.single.rank, 7);
      expect(popular.items.single.ranks?.single.scope, CatalogRankScope.popular);
      expect(popular.items.single.ranks?.single.allTime, isTrue);
    });

    test('fetchRow throws on rows MAL does not serve', () {
      expect(() => source.fetchRow(CatalogRowId.trendingMovies), throwsArgumentError);
    });

    test('membership is keyed by MAL id, ignoring kind', () async {
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)), isNull);

      var notified = 0;
      source.watchlistChanges.addListener(() => notified++);
      await source.ensureWatchlistLoaded();

      expect(notified, 1);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)), isTrue);
      // A library item stored under the other kind still matches its entry.
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(mal: 16498)), isTrue);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 99999)), isFalse);
      // External-only ids can't check membership without a resolved MAL id.
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(tvdb: 267440)), isFalse);
    });

    test('resolveItemIds prefers the season-1 row for shows and MOVIE rows for movies', () async {
      final show = await source.resolveItemIds(MediaKind.show, const ExternalIds(tvdb: 267440));
      expect(show?.mal, 16498);
      expect(show?.tvdb, 267440);

      final movie = await source.resolveItemIds(MediaKind.movie, const ExternalIds(tmdb: 372058));
      expect(movie?.mal, 32281);

      // Non-anime items resolve to null, hiding the watchlist action.
      expect(await source.resolveItemIds(MediaKind.movie, const ExternalIds(tmdb: 603)), isNull);
      expect(await source.resolveItemIds(MediaKind.show, const ExternalIds()), isNull);
    });

    test('addToWatchlist PUTs plan_to_watch optimistically', () async {
      await source.ensureWatchlistLoaded();
      requests.clear();

      handlers.add((request) => http.Response('{"status":"plan_to_watch"}', 200));
      await source.addToWatchlist(MediaKind.show, const CatalogItemIds(mal: 40028));

      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.url.path, '/v2/anime/40028/my_list_status');
      expect(request.bodyFields, {'status': 'plan_to_watch'});
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 40028)), isTrue);
    });

    test('addToWatchlist resolves a MAL id from external ids when missing', () async {
      await source.ensureWatchlistLoaded();
      requests.clear();

      handlers.add((request) => http.Response('{"status":"plan_to_watch"}', 200));
      await source.addToWatchlist(MediaKind.show, const CatalogItemIds(tvdb: 267440));

      expect(requests.single.url.path, '/v2/anime/16498/my_list_status');
    });

    test('mutating an unmappable item throws without a request', () async {
      await expectLater(source.addToWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), throwsStateError);
      expect(requests, isEmpty);
    });

    test('removeFromWatchlist DELETEs and treats 404 as success', () async {
      await source.ensureWatchlistLoaded();
      requests.clear();

      handlers.add((request) => http.Response('', 404));
      await source.removeFromWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498));

      expect(requests.single.method, 'DELETE');
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)), isFalse);
    });

    test('failed mutation reverts the optimistic snapshot flip', () async {
      await source.ensureWatchlistLoaded();

      var notified = 0;
      source.watchlistChanges.addListener(() => notified++);
      handlers.add((request) => http.Response('oops', 500));

      await expectLater(
        source.removeFromWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)),
        throwsA(anything),
      );

      expect(notified, 2); // optimistic flip + revert
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(mal: 16498)), isTrue);
    });

    test('search queries /anime and enriches via Fribb like rows', () async {
      handlers.add((request) {
        expect(request.url.path, '/v2/anime');
        expect(request.url.queryParameters['q'], 'attack on titan');
        return http.Response(json.encode(_pageBody([_node(id: 16498, title: 'Shingeki no Kyojin')])), 200);
      });

      final items = await source.search('attack on titan');
      expect(items, hasLength(1));
      expect(items.single.ids.mal, 16498);
      expect(items.single.ids.tvdb, 267440);
    });

    test('search under three characters returns empty without a request', () async {
      expect(await source.search('86'), isEmpty);
      expect(requests, isEmpty);
    });

    test('fetchDetail uses two requests and maps enrichment, cast, recommendations, and relations', () async {
      http.Response respond(http.Request request) {
        if (request.url.path.endsWith('/characters')) {
          return http.Response(
            json.encode({
              'data': [
                {
                  'node': {
                    'id': 11,
                    'first_name': 'Edward',
                    'last_name': 'Elric',
                    'main_picture': {'medium': 'https://cdn.myanimelist.net/images/characters/9/72533.jpg'},
                  },
                  'role': 'Main',
                },
                {
                  'node': {'id': 63, 'first_name': '', 'last_name': 'Winry'},
                  'role': 'Supporting',
                },
                {
                  'node': {'id': 99},
                  'role': 'Supporting',
                },
              ],
              'paging': <String, dynamic>{},
            }),
            200,
          );
        }
        return http.Response(
          json.encode({
            ..._node(
              id: 16498,
              title: 'Shingeki no Kyojin',
              en: 'Attack on Titan',
              extra: const {'synopsis': 'Full detail synopsis', 'num_list_users': 4100000},
            ),
            'recommendations': [
              {
                'node': _node(id: 32281, title: 'Kimi no Na wa.', en: 'Your Name.', mediaType: 'movie'),
                'num_recommendations': 42,
              },
            ],
            'related_anime': [
              {
                'node': _node(id: 35760, title: 'Shingeki no Kyojin Season 3'),
                'relation_type': 'sequel',
                'relation_type_formatted': 'Sequel',
              },
            ],
            'statistics': {
              'num_list_users': 4100000,
              'status': {
                'watching': '120000',
                'completed': '3500000',
                'on_hold': '40000',
                'dropped': '90000',
                'plan_to_watch': '350000',
              },
            },
            'background': 'Created from the original manga.',
          }),
          200,
        );
      }

      handlers
        ..add(respond)
        ..add(respond);
      const item = CatalogItem(
        source: CatalogSourceId.mal,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        overview: 'Row synopsis',
        ids: CatalogItemIds(mal: 16498),
        ranks: [CatalogRank(rank: 12, scope: CatalogRankScope.airing)],
      );

      final detail = await source.fetchDetail(item);

      expect(requests, hasLength(2));
      final detailRequest = requests.singleWhere((request) => request.url.path == '/v2/anime/16498');
      final castRequest = requests.singleWhere((request) => request.url.path.endsWith('/characters'));
      expect(detailRequest.url.queryParameters['fields'], _expectedDetailFields);
      expect(castRequest.url.queryParameters['limit'], '20');
      expect(castRequest.url.queryParameters['fields'], contains('first_name'));

      expect(detail.item.overview, 'Full detail synopsis');
      expect(detail.item.ranks?.single.rank, 12);
      expect(detail.item.audience?.listed, 4100000);
      expect(detail.item.audience?.watching, 120000);
      expect(detail.item.audience?.completed, 3500000);
      expect(detail.item.audience?.onHold, 40000);
      expect(detail.item.audience?.dropped, 90000);
      expect(detail.item.audience?.planning, 350000);
      expect(detail.item.background, 'Created from the original manga.');
      expect(detail.item.posterVariants, isNull);

      expect(detail.cast, hasLength(2));
      expect(detail.cast[0].name, 'Edward Elric');
      expect(detail.cast[0].secondary, 'Main');
      expect(detail.cast[0].imageUrl, 'https://cdn.myanimelist.net/images/characters/9/72533.jpg');
      expect(detail.cast[1].name, 'Winry');

      expect(detail.related, hasLength(1));
      expect(detail.related.single.title, 'Your Name.');
      expect(detail.related.single.kind, MediaKind.movie);
      expect(detail.related.single.ids.tmdb, 372058);
      expect(detail.related.single.recommendationCount, 42);

      expect(detail.relations, hasLength(1));
      expect(detail.relations.single.type, CatalogRelationType.sequel);
      expect(detail.relations.single.items.single.ids.mal, 35760);
      expect(detail.relations.single.items.single.title, 'Shingeki no Kyojin Season 3');
    });

    test('fetchDetail normalizes a blank background to null', () async {
      http.Response respond(http.Request request) {
        if (request.url.path.endsWith('/characters')) {
          return http.Response(json.encode({'data': <Object>[], 'paging': <String, dynamic>{}}), 200);
        }
        return http.Response(
          json.encode({..._node(id: 16498, title: 'Shingeki no Kyojin'), 'background': ' \n\t '}),
          200,
        );
      }

      handlers
        ..add(respond)
        ..add(respond);
      const item = CatalogItem(
        source: CatalogSourceId.mal,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        ids: CatalogItemIds(mal: 16498),
      );

      final detail = await source.fetchDetail(item);

      expect(detail.item.background, isNull);
      expect(detail.item.posterVariants, isNull);
    });

    test('fetchDetail without a mal id returns the unchanged item without a request', () async {
      const item = CatalogItem(
        source: CatalogSourceId.mal,
        kind: MediaKind.show,
        title: 'Unknown',
        ids: CatalogItemIds(tmdb: 1),
      );

      final detail = await source.fetchDetail(item);

      expect(identical(detail.item, item), isTrue);
      expect(detail.cast, isEmpty);
      expect(detail.related, isEmpty);
      expect(detail.relations, isEmpty);
      expect(requests, isEmpty);
    });
  });

  group('parseFribbIndex byMal', () {
    test('indexes rows by mal_id for reverse lookup', () {
      final index = parseFribbIndex(
        json.encode([
          {'mal_id': 16498, 'tvdb_id': 267440},
          {
            'mal_id': 32281,
            'imdb_id': ['tt5311514'],
          },
          {'anidb_id': 1}, // no mal id — must not appear
        ]),
      );

      expect(index.byMal[16498]?.tvdbId, 267440);
      expect(index.byMal[32281]?.imdbIds, ['tt5311514']);
      expect(index.byMal, hasLength(2));
    });
  });
}
