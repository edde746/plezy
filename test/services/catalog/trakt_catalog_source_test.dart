import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/catalog_item_ref.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/trakt_catalog_source.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trakt/trakt_client.dart';

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
      'type': 'movie',
      'movie': {
        'title': 'The Matrix',
        'year': 1999,
        'ids': {'trakt': 1, 'imdb': 'tt0133093', 'tmdb': 603},
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
      final page = await source.fetchRow(CatalogRowId.watchlist);

      expect(requests.single.url.path, '/sync/watchlist');
      expect(page.items, hasLength(2));
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

    test('fetchCast maps people to cast members with https-prefixed headshots', () async {
      handlers.add(
        (request) => http.Response(
          json.encode({
            'cast': [
              {
                'characters': ['Walter White'],
                'person': {
                  'name': 'Bryan Cranston',
                  'images': {
                    'headshot': ['media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp'],
                  },
                },
              },
              {
                'characters': <String>[],
                'person': {'name': 'Aaron Paul'},
              },
              {'characters': <String>[]}, // no person — skipped
            ],
            'crew': <String, dynamic>{},
          }),
          200,
        ),
      );

      final cast = await source.fetchCast(
        const CatalogItem(
          source: CatalogSourceId.trakt,
          kind: MediaKind.show,
          title: 'Breaking Bad',
          ids: CatalogItemIds(trakt: 1388, slug: 'breaking-bad'),
        ),
      );

      expect(requests.single.url.path, '/shows/1388/people');
      expect(cast, hasLength(2));
      expect(cast[0].name, 'Bryan Cranston');
      expect(cast[0].secondary, 'Walter White');
      expect(cast[0].imageUrl, 'https://media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp');
      expect(cast[1].imageUrl, isNull);
      expect(cast[1].secondary, isNull);
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

    test('fetchRelated hits /related and keeps the item kind', () async {
      handlers.add((request) {
        expect(request.url.path, '/shows/2/related');
        return http.Response(
          json.encode([
            {
              'title': 'Dark',
              'year': 2017,
              'ids': {'trakt': 5, 'tmdb': 70523},
            },
          ]),
          200,
        );
      });

      final item = CatalogItem(
        source: CatalogSourceId.trakt,
        kind: MediaKind.show,
        title: 'Severance',
        ids: const CatalogItemIds(trakt: 2),
      );
      final related = await source.fetchRelated(item);
      expect(related.single.title, 'Dark');
      expect(related.single.kind, MediaKind.show);
    });
  });
}
