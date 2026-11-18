import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/models/seerr/seerr_media.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/catalog/seerr_requests.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';

import '../../test_helpers/http_fixtures.dart';

const _me = 1;

SeerrCatalogSource _source(
  FutureOr<http.Response> Function(http.Request request) handler, {
  int permissions = SeerrPermission.request,
  SeerrProduct product = SeerrProduct.jellyseerr,
}) {
  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: _me,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      product: product,
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: MockClient((request) async {
      // Artwork stays on TMDB's CDN and the product is left as constructed.
      if (request.url.path == '/api/v1/settings/public') return jsonResponse({'message': 'Not Found'}, status: 404);
      return handler(request);
    }),
  );
  final source = SeerrCatalogSource(client);
  addTearDown(() {
    source.dispose();
    client.dispose();
  });
  return source;
}

Map<String, dynamic> _media({
  required int tmdbId,
  String type = 'movie',
  int status = 1,
  int status4k = 1,
  int? serviceId,
  int? serviceId4k,
}) => {
  'id': 1000 + tmdbId,
  'mediaType': type,
  'tmdbId': tmdbId,
  'status': status,
  'status4k': status4k,
  'serviceId': serviceId,
  'serviceId4k': serviceId4k,
};

Map<String, dynamic> _request({
  required int id,
  required int tmdbId,
  String type = 'movie',
  int status = 1,
  bool is4k = false,
  int requestedBy = _me,
  int mediaStatus = 1,
  int mediaStatus4k = 1,
  int? serviceId,
  int? serviceId4k,
  bool? canRemove,
  String createdAt = '2026-11-01T10:00:00.000Z',
}) => {
  'id': id,
  'status': status,
  'is4k': is4k,
  'type': type,
  'createdAt': createdAt,
  'media': _media(
    tmdbId: tmdbId,
    type: type,
    status: mediaStatus,
    status4k: mediaStatus4k,
    serviceId: serviceId,
    serviceId4k: serviceId4k,
  ),
  'requestedBy': {'id': requestedBy},
  'canRemove': ?canRemove,
};

http.Response _page(List<Map<String, dynamic>> results, {int page = 1, int pages = 1, int? total}) => jsonResponse({
  'pageInfo': {'page': page, 'pages': pages, 'pageSize': 20, 'results': total ?? results.length},
  'results': results,
});

/// A detail body for `/movie/{id}` or `/tv/{id}`, titled after its id.
http.Response _details(http.Request request) {
  final segments = request.url.pathSegments;
  final id = int.parse(segments.last);
  final isMovie = segments[segments.length - 2] == 'movie';
  return jsonResponse({
    'id': id,
    isMovie ? 'title' : 'name': 'Title $id',
    isMovie ? 'releaseDate' : 'firstAirDate': '2020-05-01',
    'posterPath': '/poster$id.jpg',
    'mediaInfo': _media(tmdbId: id, type: isMovie ? 'movie' : 'tv', status: 5),
  });
}

bool _isDetail(http.Request request) =>
    request.url.path.startsWith('/api/v1/movie/') || request.url.path.startsWith('/api/v1/tv/');

SeerrRequest _parsed(Map<String, dynamic> json) => SeerrRequest.fromJson(json);

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('My requests shelf', () {
    test('asks for the signed-in user\'s requests and maps them to a shelf, newest first', () async {
      final listQueries = <Map<String, String>>[];
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          listQueries.add(request.url.queryParameters);
          return _page([
            _request(id: 3, tmdbId: 30, type: 'tv', status: 2, mediaStatus: 3, createdAt: '2026-11-03T08:00:00.000Z'),
            _request(id: 2, tmdbId: 20, status: 1),
            _request(id: 1, tmdbId: 10, status: 5, mediaStatus: 5),
          ], total: 3);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      expect(source, isA<CatalogHubSource>());
      final hubs = await source.fetchHubs();

      expect(listQueries.single, {'take': '25', 'skip': '0', 'filter': 'all', 'sort': 'added', 'requestedBy': '$_me'});
      final hub = hubs.single;
      expect(hub.id, SeerrRequests.hubId);
      expect(hub.title, t.seerr.requests.myRequests);
      expect(hub.page.totalResults, 3);
      expect(hub.page.hasMore, isTrue, reason: 'keeps the View All affordance that opens the full list');

      final items = hub.page.items;
      expect(items.map((i) => i.title), ['Title 30', 'Title 20', 'Title 10']);
      expect(items.map((i) => i.kind), [MediaKind.show, MediaKind.movie, MediaKind.movie]);
      expect(items.map((i) => i.ids.tmdb), [30, 20, 10]);
      expect(items.every((i) => i.source == CatalogSourceId.seerr), isTrue);
      expect(items.first.posterUrl, 'https://image.tmdb.org/t/p/w600_and_h900_bestv2/poster30.jpg');
      expect(items.first.addedAt, DateTime.parse('2026-11-03T08:00:00.000Z'));

      // The badge comes from the request, not from the cached detail body
      // (which says "available" for every title here).
      expect(items[0].serverState?.request, CatalogRequestState.processing);
      expect(items[0].serverState?.availability, isNull);
      expect(items[1].serverState?.request, CatalogRequestState.pending);
      expect(items[2].serverState?.request, isNull);
      expect(items[2].serverState?.availability, CatalogAvailability.available);
    });

    test('several requests for one title share a card, regular and 4K in their own slots', () async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          return _page([
            _request(id: 2, tmdbId: 10, is4k: true, status: 1),
            _request(id: 1, tmdbId: 10, status: 2, mediaStatus: 5),
          ]);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      final item = (await source.fetchHubs()).single.page.items.single;

      expect(item.serverState?.request4k, CatalogRequestState.pending);
      expect(item.serverState?.availability, CatalogAvailability.available);
      expect(item.serverState?.request, isNull);
    });

    test('no requests means no shelf', () async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') return _page(const []);
        fail('unexpected ${request.url}');
      });
      expect(await source.fetchHubs(), isEmpty);
    });

    test('a failed list load throws, so Explore keeps the shelf it had', () async {
      final source = _source((request) => jsonResponse({'message': 'boom'}, status: 500));
      await expectLater(source.fetchHubs(), throwsA(isA<SeerrApiException>()));
    });

    test('fetchHub pages by offset and refuses hubs it does not own', () async {
      final skips = <String?>[];
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          skips.add(request.url.queryParameters['skip']);
          return _page([_request(id: 9, tmdbId: 90)], page: 2, pages: 2, total: 26);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      final page = await source.fetchHub(SeerrRequests.hubId, page: 2, limit: 25);

      expect(skips, ['25']);
      expect(page.hasMore, isFalse);
      expect(page.totalResults, 26);
      expect(page.items.single.title, 'Title 90');
      expect(() => source.fetchHub('somebody.else'), throwsArgumentError);
    });
  });

  group('View All grid', () {
    test('reads page after page under the filter and gives a title requested on two pages one card', () async {
      final queries = <Map<String, String>>[];
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          queries.add(request.url.queryParameters);
          return request.url.queryParameters['skip'] == '0'
              ? _page([_request(id: 3, tmdbId: 10), _request(id: 2, tmdbId: 20)], pages: 2, total: 3)
              : _page([_request(id: 1, tmdbId: 10, is4k: true, status: 3)], page: 2, pages: 2, total: 3);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      final titles = await source.requests.fetchAllTitles(filter: SeerrRequestFilter.pending, pageSize: 2);

      expect(
        [for (final query in queries) (query['skip'], query['take'], query['filter'])],
        [('0', '2', 'pending'), ('2', '2', 'pending')],
      );
      expect(titles.map((item) => item.title), ['Title 10', 'Title 20']);
      expect(titles.first.serverState?.request, CatalogRequestState.pending);
      expect(titles.first.serverState?.request4k, CatalogRequestState.declined);
    });

    test('stops at the page cap, and at a page that is empty yet claims more', () async {
      var calls = 0;
      var emptyFrom = 99;
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          calls++;
          return _page(
            [if (calls < emptyFrom) _request(id: calls, tmdbId: calls)],
            page: calls,
            pages: 50,
          );
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      expect(await source.requests.fetchAllTitles(pageSize: 1, maxPages: 3), hasLength(3));
      expect(calls, 3);

      calls = 0;
      emptyFrom = 2;
      expect(await source.requests.fetchAllTitles(pageSize: 1, maxPages: 3), hasLength(1));
      expect(calls, 2);
    });

    test('a later shelf load keeps what the grid learned beyond the shelf, so those cards keep their menus', () async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          return request.url.queryParameters['take'] == '1'
              ? _page([_request(id: 2, tmdbId: 20)], pages: 2, total: 2)
              : _page([_request(id: 2, tmdbId: 20), _request(id: 1, tmdbId: 10)]);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      await source.requests.fetchAllTitles();
      await source.fetchHubs(limit: 1);

      expect(source.requests.known(MediaKind.movie, 20)?.requests.single.id, 2);
      expect(source.requests.known(MediaKind.movie, 10)?.requests.single.id, 1);
    });
  });

  group('title lookups', () {
    test('run at most four at a time, once per title, and are reused by later loads', () async {
      var inFlight = 0;
      var peak = 0;
      final detailCalls = <String>[];
      final source = _source((request) async {
        if (request.url.path == '/api/v1/request') {
          return _page([
            for (var i = 1; i <= 10; i++) _request(id: i, tmdbId: 100 + i),
            // A second request for an already listed title must not add a lookup.
            _request(id: 11, tmdbId: 101, is4k: true),
          ]);
        }
        if (_isDetail(request)) {
          detailCalls.add(request.url.path);
          inFlight++;
          if (inFlight > peak) peak = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          return _details(request);
        }
        fail('unexpected ${request.url}');
      });

      final first = await source.requests.fetchMine(take: 25);

      expect(first.entries, hasLength(11));
      expect(first.entries.every((e) => e.item != null), isTrue);
      expect(detailCalls, hasLength(10));
      expect(detailCalls.toSet(), hasLength(10));
      expect(peak, SeerrRequests.maxConcurrentLookups);

      final second = await source.requests.fetchMine(take: 25);

      expect(second.entries.map((e) => e.item?.title), first.entries.map((e) => e.item?.title));
      expect(detailCalls, hasLength(10), reason: 'titles come from the session cache');
    });

    test('a short page still looks its titles up side by side', () async {
      var inFlight = 0;
      var peak = 0;
      final source = _source((request) async {
        if (request.url.path == '/api/v1/request') {
          return _page([for (var i = 1; i <= 4; i++) _request(id: i, tmdbId: 100 + i)]);
        }
        if (_isDetail(request)) {
          inFlight++;
          if (inFlight > peak) peak = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          return _details(request);
        }
        fail('unexpected ${request.url}');
      });

      await source.requests.fetchMine();

      expect(peak, 4);
    });

    test('a failed lookup keeps the request listed without a title, and is retried next time', () async {
      var failing = true;
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          return _page([_request(id: 1, tmdbId: 10), _request(id: 2, tmdbId: 20)]);
        }
        if (request.url.path == '/api/v1/movie/20' && failing) {
          return jsonResponse({'message': 'TMDB down'}, status: 500);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      final page = await source.requests.fetchMine();

      expect(page.entries.map((e) => e.request.id), [1, 2]);
      expect(page.entries.first.item?.title, 'Title 10');
      expect(page.entries.last.item, isNull);
      expect(SeerrRequests.rowItems(page.entries).map((i) => i.title), ['Title 10'], reason: 'nothing to draw');

      failing = false;
      final retried = await source.requests.fetchMine();
      expect(retried.entries.last.item?.title, 'Title 20');
    });

    test('requests without a usable title reference are dropped but still count toward the offset', () async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          return _page([
            _request(id: 1, tmdbId: 10),
            {'id': 2, 'status': 1, 'type': 'movie', 'media': null},
            {'id': 3, 'status': 1, 'type': 'book', 'media': _media(tmdbId: 30)},
          ]);
        }
        if (_isDetail(request)) return _details(request);
        fail('unexpected ${request.url}');
      });

      final page = await source.requests.fetchMine();

      expect(page.entries.map((e) => e.request.id), [1]);
      expect(page.fetched, 3);
    });

    test('a detail load through the source records what Seerr holds for the title', () async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/movie/10') {
          return jsonResponse({
            'id': 10,
            'title': 'Title 10',
            'mediaInfo': {
              ..._media(tmdbId: 10, status: 3, serviceId: 0),
              'requests': [_request(id: 5, tmdbId: 10, status: 2)..remove('media')],
            },
          });
        }
        if (request.url.path == '/api/v1/movie/10/recommendations') return jsonResponse({'results': <Object>[]});
        fail('unexpected ${request.url}');
      });
      expect(source.requests.known(MediaKind.movie, 10), isNull);

      await source.fetchDetail(
        const CatalogItem(
          source: CatalogSourceId.seerr,
          kind: MediaKind.movie,
          title: 'Title 10',
          ids: CatalogItemIds(tmdb: 10),
        ),
      );

      final known = source.requests.known(MediaKind.movie, 10);
      expect(known?.media?.id, 1010);
      expect(known?.media?.serviceId, 0);
      expect(known?.requests.single.id, 5);
    });
  });

  group('badges', () {
    SeerrRequestBadge badge({required int status, int mediaStatus = 1, int mediaStatus4k = 1, bool is4k = false}) =>
        SeerrRequests.badgeFor(
          _parsed(
            _request(
              id: 1,
              tmdbId: 1,
              status: status,
              is4k: is4k,
              mediaStatus: mediaStatus,
              mediaStatus4k: mediaStatus4k,
            ),
          ),
          SeerrProduct.jellyseerr,
        );

    test('follow the approval state until approved, then the variant\'s media state', () {
      expect(badge(status: 1), SeerrRequestBadge.pending);
      expect(badge(status: 3), SeerrRequestBadge.declined);
      expect(badge(status: 4), SeerrRequestBadge.failed);
      expect(badge(status: 2), SeerrRequestBadge.approved);
      expect(badge(status: 2, mediaStatus: 2), SeerrRequestBadge.approved);
      expect(badge(status: 2, mediaStatus: 3), SeerrRequestBadge.processing);
      expect(badge(status: 2, mediaStatus: 4), SeerrRequestBadge.partiallyAvailable);
      expect(badge(status: 2, mediaStatus: 5), SeerrRequestBadge.available);
      expect(badge(status: 5), SeerrRequestBadge.available);
      expect(badge(status: 5, mediaStatus: 4), SeerrRequestBadge.partiallyAvailable);
    });

    test('a 4K request reads the 4K media state', () {
      expect(badge(status: 2, is4k: true, mediaStatus: 5, mediaStatus4k: 3), SeerrRequestBadge.processing);
      expect(badge(status: 2, is4k: false, mediaStatus: 5, mediaStatus4k: 3), SeerrRequestBadge.available);
    });
  });

  group('what to offer', () {
    SeerrRequests requests({required int permissions}) =>
        _source((request) => fail('no HTTP expected'), permissions: permissions).requests;

    test('deleting a request: managers always, others only their own while pending', () {
      final user = requests(permissions: SeerrPermission.request);
      expect(user.canManage, isFalse);
      expect(user.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 1))), isTrue);
      expect(user.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 2))), isFalse);
      expect(user.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 3))), isFalse);
      expect(user.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 1, requestedBy: 99))), isFalse);

      for (final permissions in [SeerrPermission.manageRequests, SeerrPermission.admin]) {
        final manager = requests(permissions: permissions);
        expect(manager.canManage, isTrue);
        expect(manager.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 2, requestedBy: 99))), isTrue);
        expect(manager.canDeleteRequest(_parsed(_request(id: 1, tmdbId: 1, status: 5))), isTrue);
      }
    });

    test('complete removal: managers only, and only variants Seerr sent to Sonarr/Radarr', () {
      SeerrTitleRequests title(Map<String, dynamic> request) {
        final parsed = _parsed(request);
        return SeerrTitleRequests(media: parsed.media, requests: [parsed]);
      }

      final manager = requests(permissions: SeerrPermission.manageRequests);
      final user = requests(permissions: SeerrPermission.request);

      final inRadarr = title(_request(id: 1, tmdbId: 1, status: 2, serviceId: 0));
      expect(manager.removableVariants(inRadarr), {false});
      expect(user.removableVariants(inRadarr), isEmpty);

      // A pending request reached no instance: nothing on disk to remove, and
      // the file endpoint would fall back to the default instance.
      expect(manager.removableVariants(title(_request(id: 1, tmdbId: 1, status: 1))), isEmpty);

      expect(manager.removableVariants(title(_request(id: 1, tmdbId: 1, is4k: true, status: 2, serviceId4k: 1))), {
        true,
      });
      expect(manager.removableVariants(title(_request(id: 1, tmdbId: 1, status: 2, serviceId: 0, serviceId4k: 1))), {
        false,
        true,
      });

      // Seerr's own verdict: the instance behind the request is gone.
      expect(
        manager.removableVariants(title(_request(id: 1, tmdbId: 1, status: 2, serviceId: 0, canRemove: false))),
        isEmpty,
      );
      expect(manager.removableVariants(title(_request(id: 1, tmdbId: 1, status: 2, serviceId: 0, canRemove: true))), {
        false,
      });

      expect(manager.removableVariants(const SeerrTitleRequests()), isEmpty);
      expect(
        manager.removableVariants(const SeerrTitleRequests(media: SeerrMediaInfo(serviceId: 0))),
        isEmpty,
        reason: 'no Seerr media id to address',
      );
    });
  });

  group('mutations', () {
    test('deleteRequest withdraws the request, forgets what was known and notifies', () async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/v1/request' && request.method == 'GET') {
          return _page([_request(id: 7, tmdbId: 10)]);
        }
        if (_isDetail(request)) return _details(request);
        if (request.method == 'DELETE') return http.Response('', 204);
        fail('unexpected ${request.url}');
      });
      final requests = source.requests;
      final page = await requests.fetchMine();
      expect(requests.known(MediaKind.movie, 10)?.requests.single.id, 7);
      var notified = 0;
      requests.addListener(() => notified++);
      calls.clear();

      await requests.deleteRequest(page.entries.single.request);

      expect(calls, ['DELETE /api/v1/request/7']);
      expect(notified, 1);
      expect(requests.known(MediaKind.movie, 10), isNull);
    });

    test('removeCompletely deletes the files of each variant, then the Seerr record', () async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}?${request.url.query}');
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);
      var notified = 0;
      source.requests.addListener(() => notified++);

      await source.requests.removeCompletely(mediaId: 55, variants: {true, false});

      expect(calls, [
        'DELETE /api/v1/media/55/file?is4k=false',
        'DELETE /api/v1/media/55/file?is4k=true',
        'DELETE /api/v1/media/55?',
      ]);
      expect(notified, 1);
    });

    test('removeCompletely touches only the variants it was given', () async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}?${request.url.query}');
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);

      await source.requests.removeCompletely(mediaId: 55, variants: {true});

      expect(calls, ['DELETE /api/v1/media/55/file?is4k=true', 'DELETE /api/v1/media/55?']);
    });

    test('a media record that is already gone (404 on the files) still gets cleared', () async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/file')) return jsonResponse({'message': 'Media not found'}, status: 404);
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);

      await source.requests.removeCompletely(mediaId: 55, variants: {false});

      expect(calls, ['DELETE /api/v1/media/55/file', 'DELETE /api/v1/media/55']);
    });

    test('a refused file removal keeps the Seerr record, and listeners still re-read', () async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return jsonResponse({'message': 'No Radarr server configured to delete media files'}, status: 409);
      }, permissions: SeerrPermission.manageRequests);
      var notified = 0;
      source.requests.addListener(() => notified++);

      await expectLater(
        source.requests.removeCompletely(mediaId: 55, variants: {false, true}),
        throwsA(isA<SeerrApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );

      expect(calls, ['DELETE /api/v1/media/55/file'], reason: 'neither the 4K files nor the record are touched');
      expect(notified, 1);
    });
  });

  test('withServerState replaces or drops the server state and keeps the rest', () {
    const item = CatalogItem(
      source: CatalogSourceId.seerr,
      kind: MediaKind.movie,
      title: 'Kept',
      year: 2020,
      ids: CatalogItemIds(tmdb: 10, imdb: 'tt1'),
      posterUrl: 'https://image.tmdb.org/t/p/w500/p.jpg',
      serverState: CatalogServerState(request: CatalogRequestState.pending),
    );

    final dropped = SeerrRequests.withServerState(item, null);
    expect(dropped.serverState, isNull);
    expect(dropped.title, 'Kept');
    expect(dropped.year, 2020);
    expect(dropped.ids.imdb, 'tt1');
    expect(dropped.posterUrl, item.posterUrl);

    final replaced = SeerrRequests.withServerState(
      item,
      const CatalogServerState(availability: CatalogAvailability.available),
    );
    expect(replaced.serverState?.availability, CatalogAvailability.available);
    expect(replaced.serverState?.request, isNull);
  });
}
