import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/plex_catalog_source.dart';
import 'package:plezy/services/plex_discover_client.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/http_fixtures.dart';

const _session = PlexDiscoverSession(accessToken: 'profile-token', clientIdentifier: 'client-id');

Map<String, Object?> _metadata({
  String ratingKey = 'plex-movie-1',
  String type = 'movie',
  String title = 'Inception',
  String imdb = 'tt1375666',
  int tmdb = 27205,
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
    {'id': 'imdb://$imdb'},
    {'id': 'tmdb://$tmdb'},
  ],
};

/// Discover answers `/hubs/sections/<section>` with placeholders only — the
/// shelf identity, never its items.
Map<String, Object?> _placeholderHub(String id, String title, {String type = 'mixed'}) => {
  'hubIdentifier': id,
  'key': '/hubs/sections/home/${id.split('.').last}?source=home',
  'title': title,
  'type': type,
  'placeholder': true,
  'size': 0,
  'more': true,
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
            return jsonResponse({
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

    test('home shelves are hydrated from their placeholder keys', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            switch (request.url.path) {
              case '/hubs/sections/home':
                // Discover answers the section listing with placeholders: no
                // hub carries Metadata, so each shelf needs its own request.
                return jsonResponse({
                  'MediaContainer': {
                    'Hub': [
                      _placeholderHub('home.trending-plex', 'Trending on Plex'),
                      _placeholderHub('home.genres', 'Browse by Genre', type: 'directory'),
                      _placeholderHub('home.new-trailers', 'New Trailers', type: 'clip'),
                      _placeholderHub('home.people', 'People'),
                      _placeholderHub('home.chris-nolan', 'The Films of Sir Christopher Nolan'),
                    ],
                  },
                });
              case '/hubs/sections/home/trending-plex':
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [
                      _metadata(),
                      _metadata(ratingKey: 'plex-show-1', type: 'show', title: 'Severance'),
                      _metadata(ratingKey: 'plex-movie-2', title: 'Interstellar'),
                    ],
                  },
                });
              case '/hubs/sections/home/people':
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [
                      {'ratingKey': 'person-1', 'type': 'person', 'title': 'A Person'},
                    ],
                  },
                });
              case '/hubs/sections/home/chris-nolan':
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [_metadata(ratingKey: 'plex-movie-3', title: 'The Prestige')],
                  },
                });
            }
            return jsonResponse({'error': 'unexpected'}, status: 500);
          }),
        ),
      );
      addTearDown(source.dispose);

      final hubs = await source.fetchHubs(limit: 2);

      // Browse-category and trailer shelves cannot produce a catalog item, so
      // they never cost a hydration request.
      expect(requests.map((request) => request.url.path), [
        '/hubs/sections/home',
        '/hubs/sections/home/trending-plex',
        '/hubs/sections/home/people',
        '/hubs/sections/home/chris-nolan',
      ]);
      expect(requests[1].url.queryParameters, containsPair('limit', '3'));
      expect(requests[1].url.queryParameters, containsPair('includeMeta', '1'));
      expect(requests[1].url.queryParameters, containsPair('source', 'home'));

      // The people-only shelf maps to nothing and drops out; provider order
      // and titles survive for the rest.
      expect(hubs.map((hub) => hub.id), ['home.trending-plex', 'home.chris-nolan']);
      expect(hubs.first.title, 'Trending on Plex');
      expect(hubs.first.page.items.map((item) => item.title), ['Inception', 'Severance']);
      expect(hubs.first.page.hasMore, isTrue);
      expect(hubs.last.page.items.single.title, 'The Prestige');
      expect(hubs.last.page.hasMore, isFalse);
    });

    test('View All takes a shelf in one request because Discover ignores offsets', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/hubs/sections/home') {
              return jsonResponse({
                'MediaContainer': {
                  'Hub': [_placeholderHub('home.trending-plex', 'Trending on Plex')],
                },
              });
            }
            return jsonResponse({
              'MediaContainer': {
                'Metadata': [
                  _metadata(),
                  _metadata(ratingKey: 'plex-movie-2', title: 'Interstellar', imdb: 'tt0816692', tmdb: 157336),
                ],
              },
            });
          }),
        ),
      );
      addTearDown(source.dispose);

      await source.fetchHubs(limit: 1);
      requests.clear();

      final page = await source.fetchHub('home.trending-plex', limit: 100);

      expect(requests.single.url.queryParameters, containsPair('limit', '100'));
      expect(requests.single.url.queryParameters.containsKey('X-Plex-Container-Start'), isFalse);
      expect(page.items.map((item) => item.title), ['Inception', 'Interstellar']);
      expect(page.hasMore, isFalse);

      // A second page would replay the same items, so it is never requested.
      requests.clear();
      final beyond = await source.fetchHub('home.trending-plex', page: 2, limit: 100);
      expect(beyond.items, isEmpty);
      expect(requests, isEmpty);
    });

    test('one failing shelf degrades, an entirely failing listing surfaces the error', () async {
      var failEverything = false;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            if (request.url.path == '/hubs/sections/home') {
              return jsonResponse({
                'MediaContainer': {
                  'Hub': [
                    _placeholderHub('home.trending-plex', 'Trending on Plex'),
                    _placeholderHub('home.retired', 'Retired'),
                  ],
                },
              });
            }
            if (failEverything || request.url.path == '/hubs/sections/home/retired') {
              return jsonResponse({'error': 'gone'}, status: 500);
            }
            return jsonResponse({
              'MediaContainer': {
                'Metadata': [_metadata()],
              },
            });
          }),
        ),
      );
      addTearDown(source.dispose);

      final hubs = await source.fetchHubs(limit: 25);
      expect(hubs.map((hub) => hub.id), ['home.trending-plex']);

      failEverything = true;
      await expectLater(source.fetchHubs(limit: 25), throwsA(isA<PlexDiscoverException>()));
    });

    test('a vanished home shelf degrades to an empty page', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            return jsonResponse({'error': 'unexpected'}, status: 500);
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
            return jsonResponse({
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
              return jsonResponse({
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
            return jsonResponse(const <String, Object?>{});
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
              return jsonResponse({
                'MediaContainer': {
                  'Metadata': [_metadata()],
                },
              });
            }
            expect(request.method, 'PUT');
            expect(request.url.path, '/actions/addToWatchlist');
            expect(request.url.queryParameters['ratingKey'], 'plex-movie-1');
            return jsonResponse(const <String, Object?>{});
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
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [_metadata(type: 'show')],
                  },
                });
              case '/library/metadata/plex-movie-1':
                return jsonResponse({
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
                return jsonResponse({
                  'MediaContainer': {
                    'Hub': [
                      {
                        'Metadata': [_metadata(ratingKey: 'related-1', title: 'Interstellar')],
                      },
                    ],
                  },
                });
            }
            return jsonResponse({'error': 'unexpected'}, status: 500);
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
