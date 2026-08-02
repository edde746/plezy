import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
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
Map<String, Object?> _placeholderHub(String id, String title, {String type = 'mixed', String? style}) => {
  'hubIdentifier': id,
  'key': '/hubs/sections/home/${id.split('.').last}?source=home',
  'title': title,
  'type': type,
  'style': ?style,
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
      expect(captured.url.queryParameters['includeGuids'], '1');
      expect(captured.url.queryParameters['includeMeta'], '1');
      expect(captured.headers['X-Plex-Token'], 'profile-token');
      expect(captured.headers['X-Plex-Client-Identifier'], 'client-id');
      expect(page.hasMore, isTrue);
      expect(page.totalResults, 27);

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

    test('maps every attributed score and leaves absent optional metadata null', () async {
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient(
            (_) async => jsonResponse({
              'MediaContainer': {
                'totalSize': 2,
                'Metadata': [
                  {
                    ..._metadata(),
                    'rating': 9.4,
                    'ratingImage': 'rottentomatoes://image.rating.ripe',
                    'audienceRating': 9.7,
                    'audienceRatingImage': 'rottentomatoes://image.rating.upright',
                    'imdbRatingCount': 250858,
                    'Rating': [
                      {'image': 'imdb://image.rating', 'type': 'audience', 'value': 8.5},
                      {'image': 'rottentomatoes://image.rating.ripe', 'type': 'critic', 'value': 94},
                      {'image': 'rottentomatoes://image.rating.upright', 'type': 'audience', 'value': 9.7},
                      {'image': 'themoviedb://image.rating', 'type': 'audience', 'value': 8},
                    ],
                    'originallyAvailableAt': '2010-07-16',
                    'originalTitle': 'Origine',
                    'tagline': 'Your mind is the scene of the crime.',
                    'banner': 'https://metadata-static.plex.tv/banner.jpg',
                    'budget': 160000000,
                    'revenue': '839000000',
                  },
                  {
                    // Distinct external ids: the mapper dedupes on identity,
                    // and reusing the default imdb/tmdb would collapse this
                    // row into the scored one above.
                    ..._metadata(ratingKey: 'plex-movie-2', title: 'No Score', imdb: 'tt0000002', tmdb: 2),
                    'rating': null,
                  },
                ],
              },
            }),
          ),
        ),
      );
      addTearDown(source.dispose);

      final page = await source.fetchRow(CatalogRowId.watchlist);
      final item = page.items.first;
      final ratings = {for (final rating in item.ratings!) rating.source: (value: rating.value, votes: rating.votes)};

      expect(item.rating, 9.4);
      expect(ratings, {
        'rottenTomatoesCritic': (value: 9.4, votes: null),
        'rottenTomatoesAudience': (value: 9.7, votes: null),
        'imdb': (value: 8.5, votes: 250858),
        'tmdb': (value: 8.0, votes: null),
      });
      expect(item.releaseDate, DateTime(2010, 7, 16));
      expect(item.originalTitle, 'Origine');
      expect(item.tagline, 'Your mind is the scene of the crime.');
      expect(item.bannerUrl, 'https://metadata-static.plex.tv/banner.jpg');
      expect(item.budget, 160000000);
      expect(item.revenue, 839000000);

      final absent = page.items.last;
      expect(absent.rating, isNull);
      expect(absent.ratings, isNull);
      expect(absent.releaseDate, isNull);
      expect(absent.playState, isNull);
      expect(absent.posterVariants, isNull);
      expect(absent.backdropVariants, isNull);
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
                      _placeholderHub('home.trending-plex', 'Trending on Plex', style: 'shelf'),
                      _placeholderHub('home.genres', 'Browse by Genre', type: 'directory'),
                      _placeholderHub('home.new-trailers', 'New Trailers', type: 'clip'),
                      _placeholderHub('home.people', 'People'),
                      _placeholderHub('home.platforms', 'Available On', style: 'availabilityPlatforms'),
                      _placeholderHub('home.chris-nolan', 'The Films of Sir Christopher Nolan'),
                    ],
                  },
                });
              case '/hubs/sections/home/trending-plex':
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [
                      _metadata(),
                      {
                        ..._metadata(ratingKey: 'plex-show-1', type: 'show', title: 'Severance'),
                        'isContinuingSeries': true,
                        'nextEpisodeOriginallyAvailableAt': '2026-08-04',
                      },
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
              case '/hubs/sections/home/platforms':
                return jsonResponse({
                  'MediaContainer': {
                    'Metadata': [
                      {
                        ..._metadata(ratingKey: 'platform-1', title: 'A Platform Title'),
                        'viewCount': 2,
                        'viewOffset': 12345,
                        'viewedLeafCount': 7,
                      },
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
        '/hubs/sections/home/platforms',
        '/hubs/sections/home/chris-nolan',
      ]);
      final shelfRequest = requests.singleWhere((request) => request.url.path == '/hubs/sections/home/trending-plex');
      final platformRequest = requests.singleWhere((request) => request.url.path == '/hubs/sections/home/platforms');
      expect(shelfRequest.url.queryParameters, containsPair('limit', '3'));
      expect(shelfRequest.url.queryParameters, containsPair('includeMeta', '1'));
      expect(shelfRequest.url.queryParameters, containsPair('includeUserState', '1'));
      expect(shelfRequest.url.queryParameters, containsPair('source', 'home'));
      expect(shelfRequest.url.queryParameters, containsPair('excludeElements', 'Media,Image'));
      expect(platformRequest.url.queryParameters, containsPair('excludeElements', 'Media,Image'));

      // The people-only shelf maps to nothing and drops out. Explicit styles
      // survive, while an absent hint remains null instead of becoming shelf.
      expect(hubs.map((hub) => hub.id), ['home.trending-plex', 'home.platforms', 'home.chris-nolan']);
      expect(hubs.map((hub) => hub.style), [CatalogHubStyle.shelf, CatalogHubStyle.availabilityPlatforms, null]);
      expect(hubs.first.title, 'Trending on Plex');
      expect(hubs.first.page.items.map((item) => item.title), ['Inception', 'Severance']);
      expect(hubs.first.page.hasMore, isTrue);
      final show = hubs.first.page.items.last;
      expect(show.airStatus, CatalogAirStatus.airing);
      expect(show.nextEpisode?.airsAt, DateTime(2026, 8, 4));
      expect(show.endDate, isNull);

      final platformItem = hubs[1].page.items.single;
      expect(platformItem.playState?.viewCount, 2);
      expect(platformItem.playState?.viewOffsetMs, 12345);
      expect(platformItem.playState?.viewedLeafCount, 7);
      expect(hubs.last.page.items.single.title, 'The Prestige');
      expect(hubs.last.page.hasMore, isFalse);
    });

    test('source forwards the explicit hub Image opt-in', () async {
      final requests = <http.Request>[];
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/hubs/sections/home') {
              return jsonResponse({
                'MediaContainer': {
                  'Hub': [_placeholderHub('home.spotlight', 'Spotlight')],
                },
              });
            }
            return jsonResponse({
              'MediaContainer': {
                'Metadata': [_metadata()],
              },
            });
          }),
        ),
        includeImageVariants: true,
      );
      addTearDown(source.dispose);

      await source.fetchHubs();

      expect(requests.last.url.queryParameters, containsPair('includeUserState', '1'));
      expect(requests.last.url.queryParameters, containsPair('excludeElements', 'Media'));
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
                      {'score': 0.91, 'Metadata': _metadata()},
                      {'score': 0.42, 'Metadata': _metadata()},
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
      expect(results.single.relevance, 0.91);
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
      // The snapshot page must stay under Discover's container-size cap
      // (#1715: 500 was rejected outright).
      expect(requests.first.url.queryParameters['X-Plex-Container-Size'], '100');
    });

    test('an oversized watchlist page refetches as chunks when Discover rejects it', () async {
      final requests = <http.Request>[];
      final client = PlexDiscoverClient(
        _session,
        httpClient: MockClient((request) async {
          requests.add(request);
          final size = int.parse(request.url.queryParameters['X-Plex-Container-Size']!);
          if (size > 25) {
            return jsonResponse({
              'Error': {'message': 'Invalid value provided for x-plex-container-size!'},
            }, status: 400);
          }
          final start = int.parse(request.url.queryParameters['X-Plex-Container-Start']!);
          const total = 180;
          final count = (total - start).clamp(0, size);
          return jsonResponse({
            'MediaContainer': {
              'totalSize': total,
              'Metadata': [
                for (var i = 0; i < count; i++)
                  {'ratingKey': 'rk-${start + i}', 'type': 'movie', 'title': 'Movie ${start + i}'},
              ],
            },
          });
        }),
      );
      addTearDown(client.dispose);

      final page = await client.getWatchlist(page: 2, limit: 100);

      // The rejected request, then the same range in proven-size chunks:
      // the caller's offset math survives the cap drift.
      expect(
        requests.map(
          (request) => (
            request.url.queryParameters['X-Plex-Container-Start'],
            request.url.queryParameters['X-Plex-Container-Size'],
          ),
        ),
        [('100', '100'), ('100', '25'), ('125', '25'), ('150', '25'), ('175', '25')],
      );
      expect(page.items, hasLength(80));
      expect(page.items.first['ratingKey'], 'rk-100');
      expect(page.items.last['ratingKey'], 'rk-179');
      expect(page.hasMore, isFalse);
      expect(page.totalResults, 180);
    });

    test('other Discover rejections surface instead of chunking', () async {
      var requestCount = 0;
      final client = PlexDiscoverClient(
        _session,
        httpClient: MockClient((request) async {
          requestCount++;
          return jsonResponse({
            'Error': {'message': 'Maintenance'},
          }, status: 400);
        }),
      );
      addTearDown(client.dispose);

      await expectLater(client.getWatchlist(limit: 100), throwsA(isA<PlexDiscoverException>()));
      expect(requestCount, 1);
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
    test('external-id matching and fetchDetail return enriched item, cast, and related', () async {
      final requests = <http.Request>[];
      final metadataResponse = Completer<http.Response>();
      var relatedRequested = false;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) {
            requests.add(request);
            switch (request.url.path) {
              case '/library/metadata/matches':
                expect(request.url.queryParameters['guid'], 'imdb://tt1375666');
                return Future.value(
                  jsonResponse({
                    'MediaContainer': {
                      'Metadata': [_metadata(type: 'show')],
                    },
                  }),
                );
              case '/library/metadata/plex-movie-1':
                return metadataResponse.future;
              case '/library/metadata/plex-movie-1/related':
                relatedRequested = true;
                return Future.value(
                  jsonResponse({
                    'MediaContainer': {
                      'Hub': [
                        {
                          'Metadata': [_metadata(ratingKey: 'related-1', title: 'Interstellar')],
                        },
                      ],
                    },
                  }),
                );
            }
            return Future.value(jsonResponse({'error': 'unexpected'}, status: 500));
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
        overview: 'Row overview.',
        ids: CatalogItemIds(plex: 'plex-movie-1'),
        relevance: 0.73,
      );
      final detailFuture = source.fetchDetail(item);
      await Future<void>.delayed(Duration.zero);
      expect(relatedRequested, isTrue, reason: 'metadata and related requests must start concurrently');

      metadataResponse.complete(
        jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {
                ..._metadata(type: 'show'),
                'summary': 'Short summary.',
                'Summary': [
                  {'type': 'default', 'tag': 'A complete and much longer summary from detail metadata.'},
                ],
                'Role': [
                  {'tag': 'Ken Watanabe', 'role': 'Saito', 'thumb': 'https://images.plex.tv/ken.jpg'},
                ],
                'Director': [
                  {'tag': 'Christopher Nolan'},
                ],
                'Writer': [
                  {'tag': 'Jonathan Nolan'},
                ],
                'Producer': [
                  {'tag': 'Emma Thomas'},
                ],
                'Country': [
                  {'tag': 'United Kingdom'},
                  {'tag': 'United States of America'},
                ],
                'Studio': [
                  {'tag': 'Warner Bros.'},
                ],
                'Genre': [
                  {'tag': 'Science Fiction'},
                  {'tag': 'Thriller'},
                ],
                'Rating': [
                  {'image': 'imdb://image.rating', 'type': 'audience', 'value': 8.5},
                ],
                'imdbRatingCount': 250858,
                'CommonSenseMedia': [
                  {
                    'oneLiner': 'Complex themes and sustained peril.',
                    'AgeRating': [
                      {'age': 15, 'rating': 5, 'type': 'official'},
                    ],
                  },
                ],
                'originallyAvailableAt': '2010-07-16',
                'originalTitle': 'Origine',
                'tagline': 'Your mind is the scene of the crime.',
                'isContinuingSeries': false,
                'lastEpisodeOriginallyAvailableAt': '2010-12-01',
                'thumb': null,
                'art': null,
                'banner': null,
                'Image': [
                  {
                    'type': 'clearLogoWide',
                    'alt': 'Inception',
                    'url': 'https://metadata-static.plex.tv/inception-logo.png',
                  },
                  {
                    'type': 'coverPoster',
                    'alt': 'Inception',
                    'url': 'https://metadata-static.plex.tv/inception-poster.jpg',
                  },
                  {
                    'type': 'background',
                    'alt': 'Inception',
                    'url': 'https://metadata-static.plex.tv/inception-background.jpg',
                  },
                  {'type': 'banner', 'alt': 'Inception', 'url': 'https://assets.fanart.tv/inception-banner.jpg'},
                ],
              },
            ],
          },
        }),
      );
      final detail = await detailFuture;

      expect(detail.item.overview, 'A complete and much longer summary from detail metadata.');
      expect(detail.item.relevance, 0.73);
      expect(detail.item.genres, ['Science Fiction', 'Thriller']);
      expect(detail.item.studios, ['Warner Bros.']);
      expect(detail.item.countries, ['GB', 'US']);
      expect(
        {for (final credit in detail.item.credits!) credit.role: credit.name},
        {
          CatalogCreditRole.director: 'Christopher Nolan',
          CatalogCreditRole.writer: 'Jonathan Nolan',
          CatalogCreditRole.producer: 'Emma Thomas',
        },
      );
      expect(detail.item.contentAdvisory, '15+ · Complex themes and sustained peril.');
      expect(detail.item.releaseDate, DateTime(2010, 7, 16));
      expect(detail.item.endDate, DateTime(2010, 12, 1));
      expect(detail.item.airStatus, CatalogAirStatus.ended);
      expect(detail.item.originalTitle, 'Origine');
      expect(detail.item.tagline, 'Your mind is the scene of the crime.');
      expect(detail.item.logoUrl, 'https://metadata-static.plex.tv/inception-logo.png');
      expect(detail.item.posterUrl, 'https://metadata-static.plex.tv/inception-poster.jpg');
      expect(detail.item.backdropUrl, 'https://metadata-static.plex.tv/inception-background.jpg');
      expect(detail.item.bannerUrl, 'https://assets.fanart.tv/inception-banner.jpg');
      expect(detail.item.posterVariants, isNull);
      expect(detail.item.backdropVariants, isNull);
      expect(
        detail.item.ratings,
        contains(
          isA<MediaRatingSource>()
              .having((rating) => rating.source, 'source', 'imdb')
              .having((rating) => rating.value, 'value', 8.5)
              .having((rating) => rating.votes, 'votes', 250858),
        ),
      );
      expect(detail.cast.single.name, 'Ken Watanabe');
      expect(detail.cast.single.secondary, 'Saito');
      expect(detail.related.single.title, 'Interstellar');
      expect(requests.where((request) => request.url.path == '/library/metadata/plex-movie-1'), hasLength(1));
      expect(requests.where((request) => request.url.path == '/library/metadata/plex-movie-1/related'), hasLength(1));
    });

    test('fetchDetail keeps enrichment and cast when the related call fails', () async {
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/related')) {
              return jsonResponse({'error': 'related unavailable'}, status: 503);
            }
            return jsonResponse({
              'MediaContainer': {
                'Metadata': [
                  {
                    ..._metadata(),
                    'summary': 'Detailed overview.',
                    'Director': [
                      {'tag': 'Christopher Nolan'},
                    ],
                    'Role': [
                      {'tag': 'Ken Watanabe', 'role': 'Saito'},
                    ],
                  },
                ],
              },
            });
          }),
        ),
      );
      addTearDown(source.dispose);
      const item = CatalogItem(
        source: CatalogSourceId.plex,
        kind: MediaKind.movie,
        title: 'Inception',
        ids: CatalogItemIds(plex: 'plex-movie-1'),
      );

      final detail = await source.fetchDetail(item);

      expect(detail.item.overview, 'Detailed overview.');
      expect(detail.item.credits?.single.name, 'Christopher Nolan');
      expect(detail.cast.single.name, 'Ken Watanabe');
      expect(detail.related, isEmpty);
    });

    test('fetchDetail without a Plex rating key returns the row without requests', () async {
      var requested = false;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((_) async {
            requested = true;
            return jsonResponse({'error': 'unexpected'}, status: 500);
          }),
        ),
      );
      addTearDown(source.dispose);
      const item = CatalogItem(
        source: CatalogSourceId.plex,
        kind: MediaKind.movie,
        title: 'Inception',
        ids: CatalogItemIds(imdb: 'tt1375666'),
      );

      final detail = await source.fetchDetail(item);

      expect(identical(detail.item, item), isTrue);
      expect(detail.cast, isEmpty);
      expect(detail.related, isEmpty);
      expect(requested, isFalse);
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
