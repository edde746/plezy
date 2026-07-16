import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
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

Map<String, dynamic> _node({
  required int id,
  required String title,
  String? en,
  String mediaType = 'tv',
  String status = 'finished_airing',
}) => {
  'id': id,
  'title': title,
  if (en != null) 'alternative_titles': {'en': en},
  'media_type': mediaType,
  'main_picture': {'large': 'https://cdn.myanimelist.net/images/anime/$id.jpg'},
  'status': status,
  'num_episodes': 25,
  'num_scoring_users': 2326268,
  'studios': [
    {'id': 858, 'name': 'Wit Studio'},
  ],
};

Map<String, dynamic> _pageBody(List<Map<String, dynamic>> nodes, {bool hasMore = false}) => {
  'data': [
    for (final node in nodes) {'node': node},
  ],
  'paging': {if (hasMore) 'next': 'https://api.myanimelist.net/v2/whatever?offset=2'},
};

void main() {
  // Attack on Titan: split-cour show — one Fribb row per season, same tvdb id.
  const aotSeason1 = FribbMappingRow(malId: 16498, tvdbId: 267440, tvdbSeason: 1, imdbIds: ['tt2560140']);
  const aotSeason3 = FribbMappingRow(malId: 35760, tvdbId: 267440, tvdbSeason: 3, imdbIds: ['tt2560140']);
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
                _node(id: 16498, title: 'Shingeki no Kyojin', en: 'Attack on Titan'),
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
      expect(request.url.queryParameters['fields'], contains('alternative_titles'));

      expect(page.items, hasLength(2));
      final show = page.items[0];
      expect(show.kind, MediaKind.show);
      expect(show.title, 'Attack on Titan');
      expect(show.ids.mal, 16498);
      expect(show.ids.tvdb, 267440);
      expect(show.ids.imdb, 'tt2560140');
      expect(show.source, CatalogSourceId.mal);

      // List-endpoint metadata flows through to the item.
      expect(show.airStatus, CatalogAirStatus.ended);
      expect(show.episodeCount, 25);
      expect(show.votes, 2326268);
      expect(show.network, 'Wit Studio');

      final movie = page.items[1];
      expect(movie.kind, MediaKind.movie);
      expect(movie.ids.mal, 32281);
      expect(movie.ids.tmdb, 372058);
      expect(movie.posterUrl, 'https://cdn.myanimelist.net/images/anime/32281.jpg');
      // finished_airing on a movie is noise, and movies have no episode chip.
      expect(movie.airStatus, isNull);
      expect(movie.episodeCount, isNull);
    });

    test('fetchCast maps MAL characters with joined names and roles', () async {
      handlers.add(
        (request) => http.Response(
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
                'node': {'id': 99}, // nameless — skipped
                'role': 'Supporting',
              },
            ],
            'paging': <String, dynamic>{},
          }),
          200,
        ),
      );

      final cast = await source.fetchCast(
        const CatalogItem(
          source: CatalogSourceId.mal,
          kind: MediaKind.show,
          title: 'Fullmetal Alchemist: Brotherhood',
          ids: CatalogItemIds(mal: 5114),
        ),
      );

      final request = requests.single;
      expect(request.url.path, '/v2/anime/5114/characters');
      expect(request.url.queryParameters['fields'], contains('first_name'));
      expect(cast, hasLength(2));
      expect(cast[0].name, 'Edward Elric');
      expect(cast[0].secondary, 'Main');
      expect(cast[0].imageUrl, 'https://cdn.myanimelist.net/images/characters/9/72533.jpg');
      expect(cast[1].name, 'Winry');
    });

    test('fetchRow(airingAnime) hits the ranking endpoint and pages by offset', () async {
      handlers.add((request) => http.Response(json.encode(_pageBody([], hasMore: true)), 200));
      final page = await source.fetchRow(CatalogRowId.airingAnime, page: 3, limit: 50);

      final request = requests.single;
      expect(request.url.path, '/v2/anime/ranking');
      expect(request.url.queryParameters['ranking_type'], 'airing');
      expect(request.url.queryParameters['limit'], '50');
      expect(request.url.queryParameters['offset'], '100');
      expect(page.hasMore, isTrue);
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

    test('fetchRelated reads the nested recommendations field and enriches via Fribb', () async {
      handlers.add((request) {
        expect(request.url.path, '/v2/anime/16498');
        expect(request.url.queryParameters['fields'], startsWith('recommendations{'));
        return http.Response(
          json.encode({
            'id': 16498,
            'recommendations': [
              {
                'node': _node(id: 32281, title: 'Kimi no Na wa.', en: 'Your Name.', mediaType: 'movie'),
                'num_recommendations': 42,
              },
            ],
          }),
          200,
        );
      });

      final item = CatalogItem(
        source: CatalogSourceId.mal,
        kind: MediaKind.show,
        title: 'Attack on Titan',
        ids: const CatalogItemIds(mal: 16498),
      );
      final related = await source.fetchRelated(item);
      expect(related.single.title, 'Your Name.');
      expect(related.single.kind, MediaKind.movie);
      expect(related.single.ids.tmdb, 372058);
    });

    test('fetchRelated without a mal id returns empty without a request', () async {
      final item = CatalogItem(
        source: CatalogSourceId.mal,
        kind: MediaKind.show,
        title: 'Unknown',
        ids: const CatalogItemIds(tmdb: 1),
      );
      expect(await source.fetchRelated(item), isEmpty);
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
