import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/catalog_item_ref.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/trakt_catalog_source.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_client.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: now + 86400,
    scope: 'public',
    createdAt: now - 3600,
    username: 'alice',
  );
}

Map<String, dynamic> _watchlistBody() => {
  'entries': [
    {
      'rank': 1,
      'listed_at': '2026-01-03T12:34:56.000Z',
      'type': 'movie',
      'movie': {
        'title': 'The Matrix',
        'year': 1999,
        'ids': {'trakt': 1, 'imdb': 'tt0133093', 'tmdb': 603},
        'trailer': 'https://youtube.com/watch?v=m8e-FF8MsqU',
        'released': '1999-03-31T00:00:00.000Z',
      },
    },
    {
      'rank': 2,
      'type': 'show',
      'show': {
        'title': 'Severance',
        'year': 2022,
        'ids': {'trakt': 2, 'imdb': 'tt11280740', 'tmdb': 95396, 'tvdb': 371980},
        'status': 'returning series',
        'network': 'Apple TV+',
        'aired_episodes': 19,
        'votes': 7294,
        'rating': 8.5,
        'comment_count': 432,
        'tagline': 'Your innie has a life of its own.',
        'original_title': 'Severance',
        'first_aired': '2022-02-18T00:00:00.000Z',
        'language': 'en',
        'languages': ['en'],
        'available_translations': ['es', 'fr'],
        'country': 'us',
        'airs': {'day': 'Tuesday', 'time': '21:00', 'timezone': 'America/New_York'},
        'images': {
          'logo': ['walter-r2.trakt.tv/images/shows/logos/severance.webp'],
        },
      },
    },
    // Episode entries are not Explore rows and must be skipped.
    {
      'rank': 3,
      'type': 'episode',
      'episode': {
        'title': 'Pilot',
        'ids': {'trakt': 99},
      },
    },
  ],
};

void main() {
  group('TraktCatalogSource', () {
    late List<http.Request> requests;
    late List<http.Response Function(http.Request)> handlers;
    late TraktClient client;
    late TraktCatalogSource source;

    setUp(() {
      requests = [];
      handlers = [];
      client = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (handlers.isNotEmpty) return handlers.removeAt(0)(request);
          return http.Response(json.encode(_watchlistBody()['entries']), 200);
        }),
      );
      source = TraktCatalogSource(client);
    });

    tearDown(() {
      source.dispose();
      client.dispose();
    });

    test('fetchRow(watchlist) maps mixed entries and skips non-movie/show types', () async {
      handlers.add(
        (request) =>
            http.Response(json.encode(_watchlistBody()['entries']), 200, headers: {'x-pagination-item-count': '3'}),
      );
      final page = await source.fetchRow(CatalogRowId.watchlist);

      expect(requests.single.url.path, '/sync/watchlist');
      expect(page.items, hasLength(2));
      expect(page.totalResults, 3);
      expect(page.items[0].kind, MediaKind.movie);
      expect(page.items[0].identityKey, 'movie/imdb:tt0133093');
      expect(page.items[1].kind, MediaKind.show);

      // extended=full metadata flows through to the item.
      final show = page.items[1];
      expect(show.airStatus, CatalogAirStatus.airing);
      expect(show.network, 'Apple TV+');
      expect(show.episodeCount, 19);
      expect(show.votes, 7294);
      expect(show.rating, 8.5);
      expect(show.audience?.comments, 432);
      expect(show.broadcast?.weekday, DateTime.tuesday);
      expect(show.broadcast?.time, '21:00');
      expect(show.broadcast?.timezone, 'America/New_York');
      expect(show.tagline, 'Your innie has a life of its own.');
      expect(show.originalTitle, 'Severance');
      expect(show.releaseDate, DateTime.utc(2022, 2, 18));
      expect(show.languages, ['en', 'es', 'fr']);
      expect(show.logoUrl, 'https://walter-r2.trakt.tv/images/shows/logos/severance.webp');
      expect(show.countries, ['US']);
      expect(page.items[0].trailerUrl, 'https://youtube.com/watch?v=m8e-FF8MsqU');
      expect(page.items[0].releaseDate, DateTime.utc(1999, 3, 31));
      expect(page.items[1].addedAt, isNull);
      expect(page.items[0].addedAt, DateTime.utc(2026, 1, 3, 12, 34, 56));
      expect(page.items[0].audience, isNull);
      expect(page.items[0].broadcast, isNull);
      expect(page.items[0].airStatus, isNull);

      final rendered = page.items[0].toMediaItem();
      expect(rendered.serverId, isNull);
      expect(rendered.title, 'The Matrix');
      expect(rendered.isCatalogItem, isTrue);
      final roundTripped = rendered.catalogItem;
      expect(roundTripped?.title, 'The Matrix');
      expect(roundTripped?.ids.imdb, 'tt0133093');
      expect(roundTripped?.kind, MediaKind.movie);
    });

    test('membership matches on any shared id form after snapshot load', () async {
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isNull);

      var notified = 0;
      source.watchlistChanges.addListener(() => notified++);
      await source.ensureWatchlistLoaded();

      expect(notified, 1);
      // Query by tmdb only — snapshot entry also carries imdb/trakt.
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isTrue);
      // Same tmdb id under the other kind must not match.
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(tmdb: 603)), isFalse);
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(imdb: 'tt11280740')), isTrue);
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt9999999')), isFalse);
    });

    test('addToWatchlist is optimistic and posts a typed ids body', () async {
      await source.ensureWatchlistLoaded();
      requests.clear();

      handlers.add((request) => http.Response('{"added":{"shows":1}}', 201));
      await source.addToWatchlist(MediaKind.show, const CatalogItemIds(imdb: 'tt0903747', tmdb: 1396));

      final request = requests.single;
      expect(request.url.path, '/sync/watchlist');
      expect(json.decode(request.body), {
        'shows': [
          {
            'ids': {'imdb': 'tt0903747', 'tmdb': 1396},
          },
        ],
      });
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(tmdb: 1396)), isTrue);
    });

    test('fetchDetail appends bounded guest stars and maps cast metadata, crew, and related titles', () async {
      http.Response detailResponse(http.Request request) {
        if (request.url.path == '/shows/1388/people') {
          return http.Response(
            json.encode({
              'cast': [
                {
                  'characters': ['Walter White', 'Heisenberg'],
                  'episode_count': 62,
                  'person': {
                    'name': 'Bryan Cranston',
                    'images': {
                      'headshot': ['media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp'],
                    },
                  },
                },
              ],
              'guest_stars': [
                {
                  'characters': ['Tuco Salamanca'],
                  'episode_count': 4,
                  'person': {'name': 'Raymond Cruz'},
                },
                {
                  'characters': ['Gale Boetticher'],
                  'episode_count': 7,
                  'person': {'name': 'David Costabile'},
                },
              ],
              'crew': {
                'directing': [
                  {
                    'jobs': ['Director'],
                    'person': {'name': 'Vince Gilligan'},
                  },
                ],
                'writing': [
                  {
                    'jobs': ['Writer', 'Screenplay'],
                    'person': {'name': 'Peter Gould'},
                  },
                ],
                'production': [
                  {
                    'jobs': ['Executive Producer'],
                    'person': {'name': 'Mark Johnson'},
                  },
                ],
              },
            }),
            200,
          );
        }
        expect(request.url.path, '/shows/1388/related');
        return http.Response(
          json.encode([
            {
              'title': 'Better Call Saul',
              'year': 2015,
              'ids': {'trakt': 5},
            },
          ]),
          200,
        );
      }

      handlers
        ..add(detailResponse)
        ..add(detailResponse);
      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.show,
        title: 'Breaking Bad',
        tagline: 'All bad things must come to an end.',
        ids: const CatalogItemIds(trakt: 1388, slug: 'breaking-bad'),
      );
      final detail = await source.fetchDetail(item, castLimit: 2, relatedLimit: 7);

      expect(requests.map((request) => request.url.path).toSet(), {'/shows/1388/people', '/shows/1388/related'});
      final peopleRequest = requests.singleWhere((request) => request.url.path.endsWith('/people'));
      expect(peopleRequest.url.queryParameters['extended'], 'full,images,guest_stars');
      final relatedRequest = requests.singleWhere((request) => request.url.path.endsWith('/related'));
      expect(relatedRequest.url.queryParameters['limit'], '7');
      expect(detail.cast, hasLength(2));
      expect(detail.cast[0].name, 'Bryan Cranston');
      expect(detail.cast[0].secondary, 'Walter White, Heisenberg · 62 eps');
      expect(detail.cast[0].imageUrl, 'https://media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp');
      expect(detail.cast[1].name, 'Raymond Cruz');
      expect(detail.cast[1].secondary, 'Tuco Salamanca · 4 eps');
      expect(detail.item.tagline, item.tagline);
      expect(detail.item.credits, [
        isA<CatalogCredit>()
            .having((credit) => credit.name, 'name', 'Vince Gilligan')
            .having((credit) => credit.role, 'role', CatalogCreditRole.director),
        isA<CatalogCredit>()
            .having((credit) => credit.name, 'name', 'Peter Gould')
            .having((credit) => credit.role, 'role', CatalogCreditRole.writer),
        isA<CatalogCredit>()
            .having((credit) => credit.name, 'name', 'Mark Johnson')
            .having((credit) => credit.role, 'role', CatalogCreditRole.producer),
      ]);
      expect(detail.related.single.title, 'Better Call Saul');
      expect(detail.related.single.kind, MediaKind.show);
    });

    test('trending watchers reach audience and pagination count reaches totalResults', () async {
      handlers.add(
        (request) => http.Response(
          json.encode([
            {
              'watchers': 120,
              'movie': {
                'title': 'The Matrix',
                'ids': {'trakt': 1},
              },
            },
          ]),
          200,
          headers: {'x-pagination-item-count': '987'},
        ),
      );

      final page = await source.fetchRow(CatalogRowId.trendingMovies);

      expect(page.items.single.audience?.watchingNow, 120);
      expect(page.items.single.recommenders, isNull);
      expect(page.totalResults, 987);
    });

    test('recommendation users and their notes reach row-only provenance', () async {
      handlers.add(
        (request) => http.Response(
          json.encode([
            {
              'title': 'The Matrix',
              'ids': {'trakt': 1},
              'favorited_by': [
                {'username': 'alice', 'name': 'Alice', 'notes': 'A forever favorite.'},
              ],
              'recommended_by': [
                {'username': 'bob', 'name': null, 'notes': 'The lobby scene.'},
              ],
            },
          ]),
          200,
        ),
      );

      final page = await source.fetchRow(CatalogRowId.recommendedMovies);

      expect(page.items.single.recommendationCount, isNull);
      expect(page.items.single.recommenders, [
        isA<CatalogRecommender>()
            .having((recommender) => recommender.username, 'username', 'alice')
            .having((recommender) => recommender.name, 'name', 'Alice')
            .having((recommender) => recommender.note, 'note', 'A forever favorite.')
            .having((recommender) => recommender.reason, 'reason', CatalogRecommendationReason.favorited),
        isA<CatalogRecommender>()
            .having((recommender) => recommender.username, 'username', 'bob')
            .having((recommender) => recommender.note, 'note', 'The lobby scene.')
            .having((recommender) => recommender.reason, 'reason', CatalogRecommendationReason.recommended),
      ]);
    });

    test('weekday mapping covers every Trakt day name and rejects unknown values', () {
      expect(TraktCatalogSource.weekdayFor('Monday'), DateTime.monday);
      expect(TraktCatalogSource.weekdayFor('Tuesday'), DateTime.tuesday);
      expect(TraktCatalogSource.weekdayFor('Wednesday'), DateTime.wednesday);
      expect(TraktCatalogSource.weekdayFor('Thursday'), DateTime.thursday);
      expect(TraktCatalogSource.weekdayFor('Friday'), DateTime.friday);
      expect(TraktCatalogSource.weekdayFor('Saturday'), DateTime.saturday);
      expect(TraktCatalogSource.weekdayFor('Sunday'), DateTime.sunday);
      expect(TraktCatalogSource.weekdayFor('Someday'), isNull);
    });

    test('air status normalization covers the Trakt vocabulary', () {
      expect(TraktCatalogSource.airStatusFor('returning series'), CatalogAirStatus.airing);
      expect(TraktCatalogSource.airStatusFor('continuing'), CatalogAirStatus.airing);
      expect(TraktCatalogSource.airStatusFor('ended'), CatalogAirStatus.ended);
      expect(TraktCatalogSource.airStatusFor('canceled'), CatalogAirStatus.canceled);
      expect(TraktCatalogSource.airStatusFor('in production'), CatalogAirStatus.upcoming);
      expect(TraktCatalogSource.airStatusFor('post production'), CatalogAirStatus.upcoming);
      expect(TraktCatalogSource.airStatusFor('released'), isNull);
      expect(TraktCatalogSource.airStatusFor(null), isNull);
    });

    test('remove with a subset of id forms drops the sibling keys too', () async {
      await source.ensureWatchlistLoaded();
      handlers.add((request) => http.Response('{"deleted":{"movies":1}}', 200));

      // Media-detail path: ids come from server externals — no trakt/slug.
      await source.removeFromWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt0133093', tmdb: 603));

      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isFalse);
      // The sibling trakt id the mutation didn't carry must be gone as well.
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(trakt: 1)), isFalse);
      // The other entry is untouched.
      expect(source.isOnWatchlist(MediaKind.show, const CatalogItemIds(imdb: 'tt11280740')), isTrue);
    });

    test('snapshot load failure is swallowed; membership stays unknown and retries', () async {
      handlers.add((request) => http.Response('oops', 500));

      await source.ensureWatchlistLoaded(); // must not throw
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isNull);

      // Next call retries (default handler serves the snapshot).
      await source.ensureWatchlistLoaded();
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(tmdb: 603)), isTrue);
    });

    test('failed mutation reverts the optimistic snapshot flip', () async {
      await source.ensureWatchlistLoaded();

      var notified = 0;
      source.watchlistChanges.addListener(() => notified++);
      handlers.add((request) => http.Response('oops', 500));

      await expectLater(
        source.removeFromWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt0133093')),
        throwsA(anything),
      );

      expect(notified, 2); // optimistic flip + revert
      expect(source.isOnWatchlist(MediaKind.movie, const CatalogItemIds(imdb: 'tt0133093')), isTrue);
    });

    test('search hits /search/movie,show and maps the typed wrappers', () async {
      handlers.add((request) {
        expect(request.url.path, '/search/movie,show');
        expect(request.url.queryParameters['query'], 'blade runner');
        return http.Response(
          json.encode([
            {
              'type': 'movie',
              'score': 100.0,
              'movie': {
                'title': 'Blade Runner',
                'year': 1982,
                'ids': {'trakt': 3, 'imdb': 'tt0083658'},
              },
            },
            {
              'type': 'show',
              'score': 50.0,
              'show': {
                'title': 'Blade Runner: Black Lotus',
                'year': 2021,
                'ids': {'trakt': 4, 'tmdb': 93830},
              },
            },
          ]),
          200,
        );
      });

      final items = await source.search('blade runner');
      expect(items, hasLength(2));
      expect(items[0].kind, MediaKind.movie);
      expect(items[0].title, 'Blade Runner');
      expect(items[1].kind, MediaKind.show);
    });

    test('search with a blank query returns empty without a request', () async {
      expect(await source.search('   '), isEmpty);
      expect(requests, isEmpty);
    });

    test('fetchDetail starts people and related concurrently and isolates related failure', () async {
      final peopleStarted = Completer<void>();
      final relatedStarted = Completer<void>();
      final peopleResponse = Completer<http.Response>();
      final relatedResponse = Completer<http.Response>();
      final concurrentClient = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('should not invalidate'),
        httpClient: MockClient((request) {
          if (request.url.path.endsWith('/people')) {
            peopleStarted.complete();
            return peopleResponse.future;
          }
          if (request.url.path.endsWith('/related')) {
            relatedStarted.complete();
            return relatedResponse.future;
          }
          return Future.value(http.Response('not found', 404));
        }),
      );
      final concurrentSource = TraktCatalogSource(concurrentClient);
      addTearDown(() {
        concurrentSource.dispose();
        concurrentClient.dispose();
      });
      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.show,
        title: 'Severance',
        ids: const CatalogItemIds(trakt: 2),
      );

      final detailFuture = concurrentSource.fetchDetail(item);
      await Future.wait([peopleStarted.future, relatedStarted.future]).timeout(const Duration(seconds: 1));
      peopleResponse.complete(
        http.Response(
          json.encode({
            'cast': [
              {
                'characters': ['Mark Scout'],
                'person': {'name': 'Adam Scott'},
              },
            ],
            'crew': {
              'directing': [
                {
                  'jobs': ['Director'],
                  'person': {'name': 'Ben Stiller'},
                },
              ],
            },
          }),
          200,
        ),
      );
      relatedResponse.complete(http.Response('upstream failure', 500));

      final detail = await detailFuture;
      expect(detail.cast.single.name, 'Adam Scott');
      expect(detail.item.credits?.single.name, 'Ben Stiller');
      expect(detail.item.credits?.single.role, CatalogCreditRole.director);
      expect(detail.related, isEmpty);
    });
  });
}
