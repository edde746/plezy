import 'dart:async';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/plex_catalog_source.dart';
import 'package:plezy/services/plex_discover_client.dart';
import 'package:plezy/utils/external_ids.dart';

const _session = PlexDiscoverSession(accessToken: 'profile-token', clientIdentifier: 'client-id');

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: const {'content-type': 'application/json'});

Map<String, Object?> _metadata({
  String ratingKey = 'plex-movie-1',
  String type = 'movie',
  String title = 'Inception',
}) => {
  'ratingKey': ratingKey,
  'guid': 'plex://$type/$ratingKey',
  'type': type,
  'title': title,
  'year': 2010,
  'summary': 'A dream within a dream.',
  'duration': 8880000,
  'rating': 8.7,
  'contentRating': 'PG-13',
  'thumb': 'https://metadata-static.plex.tv/poster.jpg',
  'art': 'https://metadata-static.plex.tv/art.jpg',
  'Genre': [
    {'tag': 'Science Fiction'},
  ],
  'Guid': [
    {'id': 'imdb://tt1375666'},
    {'id': 'tmdb://27205'},
  ],
};

void main() {
  group('PlexCatalogSource', () {
    test('watchlist uses offset paging and maps Plex metadata', () async {
      late http.Request captured;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            captured = request;
            return _json({
              'MediaContainer': {
                'offset': 25,
                'size': 1,
                'totalSize': 27,
                'Metadata': [_metadata()],
              },
            });
          }),
        ),
      );
      addTearDown(source.dispose);

      final page = await source.fetchRow(CatalogRowId.watchlist, page: 2, limit: 25);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/library/sections/watchlist/all');
      expect(captured.url.queryParameters['X-Plex-Container-Start'], '25');
      expect(captured.url.queryParameters['X-Plex-Container-Size'], '25');
      expect(captured.url.queryParameters['includeMeta'], '1');
      expect(captured.headers['X-Plex-Token'], 'profile-token');
      expect(captured.headers['X-Plex-Client-Identifier'], 'client-id');
      expect(page.hasMore, isTrue);

      final item = page.items.single;
      expect(item.source, CatalogSourceId.plex);
      expect(item.kind, MediaKind.movie);
      expect(item.title, 'Inception');
      expect(item.runtimeMinutes, 148);
      expect(item.ids.plex, 'plex-movie-1');
      expect(item.ids.imdb, 'tt1375666');
      expect(item.ids.tmdb, 27205);
      expect(item.genres, ['Science Fiction']);
    });

    test('recommendation hubs retain Plex titles and support View All paging', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/hubs/sections/watchlist') {
              return _json({
                'MediaContainer': {
                  'Hub': [
                    {
                      'hubIdentifier': 'because-watchlisted',
                      'key': '/hubs/sections/watchlist/because-watchlisted?source=watchlist',
                      'title': 'Because You Watchlisted Inception',
                      'totalSize': 4,
                      'more': 1,
                      'Metadata': [
                        _metadata(),
                        _metadata(ratingKey: 'plex-show-1', type: 'show', title: 'Severance'),
                        {'ratingKey': 'person-1', 'type': 'person', 'title': 'A Person'},
                      ],
                    },
                    {
                      'hubIdentifier': 'people-only',
                      'key': '/hubs/sections/watchlist/people-only',
                      'title': 'People',
                      'Metadata': [
                        {'ratingKey': 'person-2', 'type': 'person', 'title': 'Another Person'},
                      ],
                    },
                  ],
                },
              });
            }
            if (request.url.path == '/hubs/sections/watchlist/because-watchlisted') {
              return _json({
                'MediaContainer': {
                  'offset': 2,
                  'totalSize': 3,
                  'Metadata': [_metadata(ratingKey: 'plex-movie-2', title: 'Interstellar')],
                },
              });
            }
            return _json({'error': 'unexpected'}, 500);
          }),
        ),
      );
      addTearDown(source.dispose);

      final hubs = await source.fetchHubs(limit: 2);

      expect(requests.first.url.queryParameters, containsPair('count', '3'));
      expect(requests.first.url.queryParameters, containsPair('includeMeta', '1'));
      expect(hubs, hasLength(1));
      expect(hubs.single.id, 'because-watchlisted');
      expect(hubs.single.title, 'Because You Watchlisted Inception');
      expect(hubs.single.page.items.map((item) => item.title), ['Inception', 'Severance']);
      expect(hubs.single.page.hasMore, isTrue);

      final page = await source.fetchHub(hubs.single.id, page: 2, limit: 2);

      expect(requests.last.url.queryParameters, containsPair('source', 'watchlist'));
      expect(requests.last.url.queryParameters, containsPair('X-Plex-Container-Start', '2'));
      expect(requests.last.url.queryParameters, containsPair('X-Plex-Container-Size', '2'));
      expect(page.items.single.title, 'Interstellar');
      expect(page.hasMore, isFalse);
    });

    test('a vanished recommendation hub degrades to an empty page', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            return _json({'error': 'unexpected'}, 500);
          }),
        ),
      );
      addTearDown(source.dispose);

      final page = await source.fetchHub('no-longer-present');

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(requests, isEmpty);
    });
    test('search sends Plex universal-search values and deduplicates media', () async {
      late http.Request captured;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            captured = request;
            return _json({
              'MediaContainer': {
                'SearchResults': [
                  {
                    'SearchResult': [
                      {'Metadata': _metadata()},
                      {'Metadata': _metadata()},
                      {
                        'Metadata': {'ratingKey': 'person-1', 'type': 'person', 'title': 'A Person'},
                      },
                    ],
                  },
                ],
              },
            });
          }),
        ),
      );
      addTearDown(source.dispose);

      final results = await source.search(' Inception ', limit: 12);

      expect(captured.url.path, '/library/search');
      expect(captured.url.queryParameters, containsPair('query', 'Inception'));
      expect(captured.url.queryParameters, containsPair('limit', '12'));
      expect(captured.url.queryParameters, containsPair('searchTypes', 'movies,tv'));
      expect(captured.url.queryParameters, containsPair('searchProviders', 'discover'));
      expect(results, hasLength(1));
      expect(results.single.ids.plex, 'plex-movie-1');
    });

    test('watchlist snapshot and mutation use the advertised action endpoint', () async {
      var watchlisted = true;
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/library/sections/watchlist/all') {
              return _json({
                'MediaContainer': {
                  'totalSize': watchlisted ? 1 : 0,
                  'Metadata': watchlisted ? [_metadata()] : <Object>[],
                },
              });
            }
            expect(request.method, 'PUT');
            expect(request.url.path, '/actions/removeFromWatchlist');
            expect(request.url.queryParameters['ratingKey'], 'plex-movie-1');
            watchlisted = false;
            return _json(const <String, Object?>{});
          }),
        ),
      );
      addTearDown(source.dispose);
      const ids = CatalogItemIds(plex: 'plex-movie-1', imdb: 'tt1375666');

      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.movie, ids), isTrue);

      await source.removeFromWatchlist(MediaKind.movie, ids);
      expect(source.isOnWatchlist(MediaKind.movie, ids), isFalse);
      expect(requests, hasLength(2));
    });

    test('watchlist mutation resolves a missing Plex rating key from external ids', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/library/metadata/matches') {
              expect(request.url.queryParameters['guid'], 'imdb://tt1375666');
              return _json({
                'MediaContainer': {
                  'Metadata': [_metadata()],
                },
              });
            }
            expect(request.method, 'PUT');
            expect(request.url.path, '/actions/addToWatchlist');
            expect(request.url.queryParameters['ratingKey'], 'plex-movie-1');
            return _json(const <String, Object?>{});
          }),
        ),
      );
      addTearDown(source.dispose);

      await source.addToWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt1375666'));

      expect(requests.map((request) => request.url.path), ['/library/metadata/matches', '/actions/addToWatchlist']);
    });
    test('external-id matching enables cast and related detail flows', () async {
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            switch (request.url.path) {
              case '/library/metadata/matches':
                expect(request.url.queryParameters['guid'], 'imdb://tt1375666');
                return _json({
                  'MediaContainer': {
                    'Metadata': [_metadata(type: 'show')],
                  },
                });
              case '/library/metadata/plex-movie-1':
                return _json({
                  'MediaContainer': {
                    'Metadata': [
                      {
                        ..._metadata(type: 'show'),
                        'Role': [
                          {'tag': 'Ken Watanabe', 'role': 'Saito', 'thumb': 'https://images.plex.tv/ken.jpg'},
                        ],
                      },
                    ],
                  },
                });
              case '/library/metadata/plex-movie-1/related':
                return _json({
                  'MediaContainer': {
                    'Hub': [
                      {
                        'Metadata': [_metadata(ratingKey: 'related-1', title: 'Interstellar')],
                      },
                    ],
                  },
                });
            }
            return _json({'error': 'unexpected'}, 500);
          }),
        ),
      );
      addTearDown(source.dispose);

      final resolved = await source.resolveItemIds(MediaKind.show, const ExternalIds(imdb: 'tt1375666'));
      expect(resolved?.plex, 'plex-movie-1');
      expect(resolved?.imdb, 'tt1375666');

      const item = CatalogItem(
        source: CatalogSourceId.plex,
        kind: MediaKind.show,
        title: 'Inception',
        ids: CatalogItemIds(plex: 'plex-movie-1'),
      );
      final cast = await source.fetchCast(item);
      final related = await source.fetchRelated(item);

      expect(cast.single.name, 'Ken Watanabe');
      expect(cast.single.secondary, 'Saito');
      expect(related.single.title, 'Interstellar');
    });

    test('Discover requests have a bounded duration', () async {
      final response = Completer<http.Response>();
      final client = PlexDiscoverClient(
        _session,
        httpClient: MockClient((request) => response.future),
        requestTimeout: Duration.zero,
      );
      addTearDown(client.dispose);

      await expectLater(client.getWatchlist(), throwsA(isA<TimeoutException>()));
    });
  });
}
