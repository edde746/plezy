import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/http_fixtures.dart';

SeerrCatalogSource _source(MockClient mock, {SeerrProduct product = SeerrProduct.unknown}) {
  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 1,
      permissions: 2,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      product: product,
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

void main() {
  group('SeerrCatalogSource', () {
    test('trending maps row metadata, total results, and the responsive TMDB image ladders', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/discover/trending');
          return jsonResponse({
            'page': 1,
            'totalPages': 3,
            'totalResults': 41,
            'results': [
              {
                'id': 603,
                'mediaType': 'movie',
                'title': 'The Matrix',
                'originalTitle': 'Matrix, The',
                'originalLanguage': 'en',
                'releaseDate': '1999-03-30',
                'posterPath': '/matrix.jpg',
                'backdropPath': '/matrix-backdrop.jpg',
                'voteAverage': 8.2,
                'voteCount': 26000,
                'popularity': 42.5,
                'adult': false,
              },
              {'id': 9, 'mediaType': 'person', 'name': 'Keanu Reeves'},
              {
                'id': 1396,
                'mediaType': 'tv',
                'name': 'Breaking Bad',
                'firstAirDate': '2008-01-20',
                'originCountry': ['us', 'GB'],
              },
            ],
          });
        }),
      );

      final page = await source.fetchRow(CatalogRowId.trending);
      expect(page.hasMore, isTrue);
      expect(page.totalResults, 41);
      expect(page.items, hasLength(2));

      final matrix = page.items.first;
      expect(matrix.source, CatalogSourceId.seerr);
      expect(matrix.kind, MediaKind.movie);
      expect(matrix.title, 'The Matrix');
      expect(matrix.year, 1999);
      expect(matrix.releaseDate, DateTime(1999, 3, 30));
      expect(matrix.rating, 8.2);
      expect(matrix.votes, 26000);
      expect(matrix.ids.tmdb, 603);
      expect(matrix.originalTitle, 'Matrix, The');
      expect(matrix.languages, ['en']);
      expect(matrix.isAdult, isFalse);
      expect(matrix.posterUrl, 'https://image.tmdb.org/t/p/w600_and_h900_bestv2/matrix.jpg');
      expect(matrix.backdropUrl, 'https://image.tmdb.org/t/p/w1920_and_h800_multi_faces/matrix-backdrop.jpg');
      expect(matrix.posterVariants?.keys, [92, 154, 185, 342, 500, 600, 780]);
      expect(matrix.posterVariants?[342], 'https://image.tmdb.org/t/p/w342/matrix.jpg');
      expect(matrix.posterVariants?[600], matrix.posterUrl);
      expect(matrix.backdropVariants?.keys, [300, 780, 1280, 1920]);
      expect(matrix.backdropVariants?[1920], matrix.backdropUrl);

      expect(page.items.last.kind, MediaKind.show);
      expect(page.items.last.title, 'Breaking Bad');
      expect(page.items.last.countries, ['US', 'GB']);
      expect(page.items.last.posterVariants, isNull);
      expect(page.items.last.serverState, isNull);
    });

    test('maps availability and request state independently with explicit pending semantics', () async {
      final source = _source(
        MockClient(
          (request) async => jsonResponse({
            'page': 1,
            'totalPages': 1,
            'results': [
              {
                'id': 1,
                'mediaType': 'movie',
                'title': 'Available',
                'mediaInfo': {'status': 5},
              },
              {
                'id': 2,
                'mediaType': 'tv',
                'name': 'Partial',
                'mediaInfo': {
                  'status': 4,
                  'seasons': [
                    {'seasonNumber': 0, 'status': 5},
                    {'seasonNumber': 1, 'status': 5},
                    {'seasonNumber': 2, 'status': 4},
                    {'seasonNumber': 3, 'status': 1},
                  ],
                },
              },
              {
                'id': 3,
                'mediaType': 'movie',
                'title': 'HD available, 4K pending',
                'mediaInfo': {
                  'status': 5,
                  'status4k': 2,
                  'requests': [
                    {'id': 31, 'status': 1, 'is4k': true},
                  ],
                },
              },
              {
                'id': 4,
                'mediaType': 'movie',
                'title': 'Requested',
                'mediaInfo': {'status': 2},
              },
              {
                'id': 5,
                'mediaType': 'movie',
                'title': 'Pending approval',
                'mediaInfo': {
                  'status': 1,
                  'requests': [
                    {'id': 51, 'status': 1, 'is4k': false},
                  ],
                },
              },
              {
                'id': 6,
                'mediaType': 'movie',
                'title': 'Declined',
                'mediaInfo': {
                  'status': 1,
                  'requests': [
                    {'id': 61, 'status': 3, 'is4k': false},
                  ],
                },
              },
              {
                'id': 7,
                'mediaType': 'movie',
                'title': 'Processing',
                'mediaInfo': {
                  'status': 3,
                  'requests': [
                    {'id': 71, 'status': 2, 'is4k': false},
                  ],
                },
              },
              {
                'id': 8,
                'mediaType': 'movie',
                'title': 'Failed',
                'mediaInfo': {
                  'status': 1,
                  'requests': [
                    {'id': 81, 'status': 4, 'is4k': false},
                  ],
                },
              },
              {
                'id': 9,
                'mediaType': 'movie',
                'title': 'Completed',
                'mediaInfo': {
                  'status': 5,
                  'requests': [
                    {'id': 91, 'status': 5, 'is4k': false},
                  ],
                },
              },
            ],
          }),
        ),
      );

      final page = await source.fetchRow(CatalogRowId.trending);
      final byTitle = {for (final item in page.items) item.title: item.serverState};

      expect(byTitle['Available']?.availability, CatalogAvailability.available);
      expect(byTitle['Available']?.request, isNull);

      expect(byTitle['Partial']?.availability, CatalogAvailability.partiallyAvailable);
      expect(byTitle['Partial']?.availableSeasons, 1);
      expect(byTitle['Partial']?.totalSeasons, 3);

      final pending4k = byTitle['HD available, 4K pending'];
      expect(pending4k?.availability, CatalogAvailability.available);
      expect(pending4k?.availability4k, CatalogAvailability.unavailable);
      expect(pending4k?.request, isNull);
      expect(pending4k?.request4k, CatalogRequestState.pending);

      // MediaInfo.status=2 is acquisition-pipeline "pending", not approval
      // pending. Only requests[].status=1 maps to CatalogRequestState.pending.
      expect(byTitle['Requested']?.availability, CatalogAvailability.unavailable);
      expect(byTitle['Requested']?.request, CatalogRequestState.approved);
      expect(byTitle['Pending approval']?.availability, isNull);
      expect(byTitle['Pending approval']?.request, CatalogRequestState.pending);
      expect(byTitle['Declined']?.request, CatalogRequestState.declined);
      expect(byTitle['Processing']?.availability, CatalogAvailability.unavailable);
      expect(byTitle['Processing']?.request, CatalogRequestState.processing);
      // A failed arr push surfaces as failed so the user can re-request.
      expect(byTitle['Failed']?.request, CatalogRequestState.failed);
      // A completed request adds no active state; availability tells the story.
      expect(byTitle['Completed']?.availability, CatalogAvailability.available);
      expect(byTitle['Completed']?.request, isNull);
    });

    test('a failed request overrides stale pipeline media status only when nothing live backs it', () async {
      final source = _source(
        MockClient(
          (request) async => jsonResponse({
            'page': 1,
            'totalPages': 1,
            'results': [
              // Seerr marks the request Failed on arr-push failure but can
              // leave the media status Processing; with no live request the
              // stale status must not hide the failure.
              {
                'id': 1,
                'mediaType': 'movie',
                'title': 'Failed, stale processing',
                'mediaInfo': {
                  'status': 3,
                  'requests': [
                    {'id': 11, 'status': 4, 'is4k': false},
                  ],
                },
              },
              {
                'id': 2,
                'mediaType': 'movie',
                'title': 'Failed, stale queue',
                'mediaInfo': {
                  'status': 2,
                  'requests': [
                    {'id': 21, 'status': 4, 'is4k': false},
                  ],
                },
              },
              // A live approved re-request backs the Processing status, so
              // the old failure stays hidden behind the active pipeline.
              {
                'id': 3,
                'mediaType': 'movie',
                'title': 'Failed, live retry',
                'mediaInfo': {
                  'status': 3,
                  'requests': [
                    {'id': 31, 'status': 4, 'is4k': false},
                    {'id': 32, 'status': 2, 'is4k': false},
                  ],
                },
              },
              // Waiting-for-approval still outranks everything, failed included.
              {
                'id': 4,
                'mediaType': 'movie',
                'title': 'Failed, pending approval',
                'mediaInfo': {
                  'status': 3,
                  'requests': [
                    {'id': 41, 'status': 4, 'is4k': false},
                    {'id': 42, 'status': 1, 'is4k': false},
                  ],
                },
              },
            ],
          }),
        ),
      );

      final page = await source.fetchRow(CatalogRowId.trending);
      final byTitle = {for (final item in page.items) item.title: item.serverState};

      expect(byTitle['Failed, stale processing']?.request, CatalogRequestState.failed);
      // Availability still reflects the wire status; only the request state
      // re-opens the request flow.
      expect(byTitle['Failed, stale processing']?.availability, CatalogAvailability.unavailable);
      expect(byTitle['Failed, stale queue']?.request, CatalogRequestState.failed);
      expect(byTitle['Failed, live retry']?.request, CatalogRequestState.processing);
      expect(byTitle['Failed, pending approval']?.request, CatalogRequestState.pending);
    });

    test('decodes MediaStatus codes 6/7 per product; unknown products stay non-available', () async {
      MockClient mock() => MockClient(
        (request) async => jsonResponse({
          'page': 1,
          'totalPages': 1,
          'results': [
            {
              'id': 1,
              'mediaType': 'movie',
              'title': 'Six',
              'mediaInfo': {'status': 6},
            },
            {
              'id': 2,
              'mediaType': 'movie',
              'title': 'Seven',
              'mediaInfo': {'status': 7},
            },
          ],
        }),
      );

      Future<Map<String, CatalogServerState?>> fetch(SeerrProduct product) async {
        final page = await _source(mock(), product: product).fetchRow(CatalogRowId.trending);
        return {for (final item in page.items) item.title: item.serverState};
      }

      // Overseerr: 6=DELETED; 7 has no meaning, so no server state at all.
      final overseerr = await fetch(SeerrProduct.overseerr);
      expect(overseerr['Six']?.availability, CatalogAvailability.unavailable);
      expect(overseerr['Seven'], isNull);

      // Jellyseerr: 6=BLOCKLISTED, 7=DELETED — neither is available.
      final jellyseerr = await fetch(SeerrProduct.jellyseerr);
      expect(jellyseerr['Six']?.availability, CatalogAvailability.unavailable);
      expect(jellyseerr['Seven']?.availability, CatalogAvailability.unavailable);

      // Legacy sessions without the discriminator treat both conservatively.
      final unknown = await fetch(SeerrProduct.unknown);
      expect(unknown['Six']?.availability, CatalogAvailability.unavailable);
      expect(unknown['Seven']?.availability, CatalogAvailability.unavailable);
    });

    test('preserves full dates and retains the coarse year fallback for malformed input', () async {
      final source = _source(
        MockClient(
          (request) async => jsonResponse({
            'page': 1,
            'totalPages': 1,
            'results': [
              {'id': 1, 'title': 'Valid', 'releaseDate': '2027-04-09'},
              {'id': 2, 'title': 'Malformed', 'releaseDate': '2028-not-a-date'},
              {'id': 3, 'title': 'Empty', 'releaseDate': ''},
            ],
          }),
        ),
      );

      final page = await source.fetchRow(CatalogRowId.upcomingMovies);
      expect(page.items[0].releaseDate, DateTime(2027, 4, 9));
      expect(page.items[0].year, 2027);
      expect(page.items[1].releaseDate, isNull);
      expect(page.items[1].year, 2028);
      expect(page.items[2].releaseDate, isNull);
      expect(page.items[2].year, isNull);
    });

    test('single-type rows hit their endpoint and coerce the kind', () async {
      late Uri uri;
      final source = _source(
        MockClient((request) async {
          uri = request.url;
          return jsonResponse({
            'page': 2,
            'totalPages': 2,
            'results': [
              {'id': 335984, 'title': 'Blade Runner 2049', 'releaseDate': '2017-10-04'},
            ],
          });
        }),
      );

      final page = await source.fetchRow(CatalogRowId.upcomingMovies, page: 2);
      expect(uri.path, '/api/v1/discover/movies/upcoming');
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['language'], isNotEmpty);
      expect(page.items.single.kind, MediaKind.movie);
      expect(page.hasMore, isFalse);
      expect(page.totalResults, isNull);
    });

    test('rows Seerr does not serve throw', () {
      final source = _source(MockClient((request) async => jsonResponse({})));
      expect(() => source.fetchRow(CatalogRowId.watchlist), throwsArgumentError);
      expect(() => source.fetchRow(CatalogRowId.suggestedAnime), throwsArgumentError);
    });

    test('resolveItemIds needs a tmdb id', () async {
      final source = _source(MockClient((request) async => jsonResponse({})));
      final resolved = await source.resolveItemIds(MediaKind.movie, const ExternalIds(tmdb: 603, imdb: 'tt0133093'));
      expect(resolved?.tmdb, 603);
      expect(resolved?.imdb, 'tt0133093');
      expect(await source.resolveItemIds(MediaKind.movie, const ExternalIds(imdb: 'tt0133093')), isNull);
    });

    test('fetchDetail runs both GETs concurrently and enriches TV metadata, cast, and recommendations', () async {
      final started = <String>{};
      final bothStarted = Completer<void>();
      final source = _source(
        MockClient((request) async {
          started.add(request.url.path);
          if (!bothStarted.isCompleted && started.length == 2) bothStarted.complete();
          await bothStarted.future;

          if (request.url.path == '/api/v1/tv/1396/recommendations') {
            return jsonResponse({
              'page': 1,
              'totalPages': 1,
              'results': [
                {'id': 60059, 'name': 'Better Call Saul', 'firstAirDate': '2015-02-08'},
              ],
            });
          }
          expect(request.url.path, '/api/v1/tv/1396');
          return jsonResponse({
            'id': 1396,
            'name': 'Breaking Bad',
            'originalName': 'Breaking Bad Original',
            'originalLanguage': 'en',
            'languages': ['en', 'es'],
            'originCountry': ['gb'],
            'firstAirDate': '2008-01-20',
            'lastAirDate': '2013-09-29',
            'episodeRunTime': [47],
            'numberOfEpisodes': 62,
            'genres': [
              {'id': 18, 'name': 'Drama'},
              {'id': 80, 'name': 'Crime'},
            ],
            'networks': [
              {'id': 174, 'name': 'AMC'},
            ],
            'productionCompanies': [
              {'id': 11073, 'name': 'Sony Pictures Television'},
            ],
            'productionCountries': [
              {'iso_3166_1': 'us', 'name': 'United States of America'},
            ],
            'status': 'Ended',
            'tagline': 'All bad things must come to an end.',
            'contentRatings': {
              'results': [
                {'iso_3166_1': 'US', 'rating': 'TV-14'},
              ],
            },
            'externalIds': {'imdbId': 'tt0903747', 'tvdbId': 81189},
            'createdBy': [
              {'id': 1, 'name': 'Vince Gilligan'},
            ],
            'keywords': [
              {'id': 1, 'name': 'new mexico'},
            ],
            'credits': {
              'cast': [
                {'name': 'Bryan Cranston', 'character': 'Walter White', 'profilePath': '/bc.jpg'},
                {'name': '', 'character': 'nobody'},
                {'name': 'Aaron Paul', 'character': 'Jesse Pinkman'},
              ],
              'crew': [
                {'name': 'Michelle MacLaren', 'job': 'Director', 'department': 'Directing'},
              ],
            },
          });
        }),
      );

      final rowItem = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.show,
        title: 'Row title',
        ids: const CatalogItemIds(tmdb: 1396),
      );
      final detail = await source.fetchDetail(rowItem);

      expect(started, {'/api/v1/tv/1396', '/api/v1/tv/1396/recommendations'});
      expect(detail.item.title, 'Breaking Bad');
      expect(detail.item.runtimeMinutes, 47);
      expect(detail.item.genres, ['Drama', 'Crime']);
      expect(detail.item.certification, 'TV-14');
      expect(detail.item.airStatus, CatalogAirStatus.ended);
      expect(detail.item.episodeCount, 62);
      expect(detail.item.network, 'AMC');
      expect(detail.item.ids.imdb, 'tt0903747');
      expect(detail.item.ids.tvdb, 81189);
      expect(detail.item.releaseDate, DateTime(2008, 1, 20));
      expect(detail.item.endDate, DateTime(2013, 9, 29));
      expect(detail.item.originalTitle, 'Breaking Bad Original');
      expect(detail.item.tagline, 'All bad things must come to an end.');
      expect(detail.item.studios, ['Sony Pictures Television']);
      expect(detail.item.countries, ['GB', 'US']);
      expect(detail.item.languages, ['en', 'es']);
      expect(detail.item.credits?.map((credit) => credit.name), containsAll(['Vince Gilligan', 'Michelle MacLaren']));
      expect(detail.item.tags?.single.name, 'new mexico');

      expect(detail.cast, hasLength(2));
      expect(detail.cast.first.name, 'Bryan Cranston');
      expect(detail.cast.first.secondary, 'Walter White');
      expect(detail.cast.first.imageUrl, 'https://image.tmdb.org/t/p/w300/bc.jpg');
      expect(detail.cast.last.imageUrl, isNull);
      expect(detail.related.single.title, 'Better Call Saul');
      expect(detail.related.single.kind, MediaKind.show);
    });

    test('search proxies /search and filters persons', () async {
      final source = _source(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/search');
          expect(request.url.queryParameters['query'], 'the matrix');
          return jsonResponse({
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

    test('fetchDetail keeps movie enrichment when recommendations fail', () async {
      final source = _source(
        MockClient((request) async {
          if (request.url.path == '/api/v1/movie/603/recommendations') {
            return jsonResponse({'message': 'recommendations unavailable'}, status: 500);
          }
          expect(request.url.path, '/api/v1/movie/603');
          return jsonResponse({
            'id': 603,
            'imdbId': 'tt0133093',
            'title': 'The Matrix',
            'originalTitle': 'The Matrix Original',
            'originalLanguage': 'en',
            'releaseDate': '1999-03-30',
            'runtime': 136,
            'adult': true,
            'budget': 63000000,
            'revenue': 466000000,
            'genres': [
              {'id': 28, 'name': 'Action'},
              {'id': 878, 'name': 'Science Fiction'},
            ],
            'productionCompanies': [
              {'id': 79, 'name': 'Village Roadshow Pictures'},
            ],
            'productionCountries': [
              {'name': 'United States of America'},
            ],
            'spokenLanguages': [
              {'iso_639_1': 'en', 'name': 'English'},
            ],
            'status': 'Released',
            'tagline': 'Welcome to the Real World.',
            'releases': {
              'results': [
                {
                  'iso_3166_1': 'CA',
                  'release_dates': [
                    {'certification': '14A'},
                  ],
                },
                {
                  'iso_3166_1': 'US',
                  'release_dates': [
                    {'certification': 'R'},
                  ],
                },
              ],
            },
            'relatedVideos': [
              {'site': 'YouTube', 'key': 'clip', 'type': 'Clip'},
              {'site': 'YouTube', 'key': 'm8e-FF8MsqU', 'type': 'Trailer'},
            ],
            'credits': {
              'crew': [
                {'name': 'Lana Wachowski', 'job': 'Director', 'department': 'Directing'},
              ],
            },
          });
        }),
      );
      final item = CatalogItem(
        source: CatalogSourceId.seerr,
        kind: MediaKind.movie,
        title: 'Row title',
        ids: const CatalogItemIds(tmdb: 603),
      );

      final detail = await source.fetchDetail(item);
      expect(detail.related, isEmpty);
      expect(detail.item.title, 'The Matrix');
      expect(detail.item.runtimeMinutes, 136);
      expect(detail.item.certification, 'R');
      expect(detail.item.trailerUrl, 'https://www.youtube.com/watch?v=m8e-FF8MsqU');
      expect(detail.item.airStatus, isNull);
      expect(detail.item.ids.imdb, 'tt0133093');
      expect(detail.item.isAdult, isTrue);
      expect(detail.item.budget, 63000000);
      expect(detail.item.revenue, 466000000);
      expect(detail.item.studios, ['Village Roadshow Pictures']);
      expect(detail.item.countries, ['US']);
      expect(detail.item.languages, ['en']);
      expect(detail.item.credits?.single.role, CatalogCreditRole.director);
    });

    test('fetchDetail keeps recommendations when the detail GET fails', () async {
      final source = _source(
        MockClient((request) async {
          if (request.url.path == '/api/v1/movie/603') {
            return jsonResponse({'message': 'detail unavailable'}, status: 500);
          }
          expect(request.url.path, '/api/v1/movie/603/recommendations');
          return jsonResponse({
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

      final detail = await source.fetchDetail(item);
      expect(detail.item, same(item));
      expect(detail.cast, isEmpty);
      expect(detail.related.single.title, 'The Matrix Reloaded');
      expect(detail.related.single.kind, MediaKind.movie);
    });

    test('canRequest honors the per-kind permission split', () {
      // permissions: 2 = ADMIN in the fixture session → everything allowed.
      final source = _source(MockClient((request) async => jsonResponse({})));
      expect(source.canRequest(MediaKind.movie), isTrue);
      expect(source.canRequest(MediaKind.show), isTrue);
    });

    test('has no watchlist: membership unknown, mutations unsupported', () async {
      final source = _source(MockClient((request) async => jsonResponse({})));
      expect(source.supportsWatchlist, isFalse);
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isNull);
      expect(() => source.addToWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), throwsUnsupportedError);
    });

    test('an untranslated locale degrades to the original title instead of blanking', () async {
      // TMDB answers `language=` for a title it has no translation of with an
      // empty string, not a missing field. Sending the app locale must not
      // turn a populated row into a blank one.
      final source = _source(
        MockClient((request) async {
          return jsonResponse({
            'page': 1,
            'totalPages': 1,
            'totalResults': 1,
            'results': [
              {
                'id': 603,
                'mediaType': 'movie',
                'title': '',
                'originalTitle': 'The Matrix',
                'overview': '',
                'releaseDate': '1999-03-30',
              },
            ],
          });
        }),
      );

      final item = (await source.fetchRow(CatalogRowId.trending)).items.single;
      expect(item.title, 'The Matrix');
      expect(item.overview, isNull, reason: 'a blank overview must not render as an empty block');
    });
  });
}
