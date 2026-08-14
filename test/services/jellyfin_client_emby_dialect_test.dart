import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/bif_thumbnail_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

class _RequestCapture {
  _RequestCapture(this._respond);

  final http.Response Function(http.Request request) _respond;
  final List<String> log = [];
  final List<({String method, Uri url, String body})> requests = [];

  Future<http.Response> handle(http.Request request) async {
    log.add('${request.method} ${request.url.path}?${request.url.query}');
    requests.add((method: request.method, url: request.url, body: request.body));
    return _respond(request);
  }
}

MediaItem _item(MediaBackend backend, {MediaKind kind = MediaKind.movie}) =>
    testMediaItem(id: 'item-1', backend: backend, kind: kind, serverId: 'srv-1');

Future<void> _reportPlaybackTriple(JellyfinClient client, {String? playSessionId}) async {
  await client.reportPlaybackStarted(
    itemId: 'item-1',
    position: const Duration(seconds: 1),
    playSessionId: playSessionId,
  );
  await client.reportPlaybackProgress(
    itemId: 'item-1',
    position: const Duration(seconds: 2),
    duration: const Duration(minutes: 1),
    playSessionId: playSessionId,
  );
  await client.reportPlaybackStopped(
    itemId: 'item-1',
    position: const Duration(seconds: 3),
    playSessionId: playSessionId,
  );
}

Map<String, Object?> _chapterItem({List<Map<String, Object?>>? chapters}) => {
  'Id': 'item-1',
  'Name': 'Episode',
  'Type': 'Episode',
  'RunTimeTicks': 1200000000,
  'Chapters':
      chapters ??
      [
        {'Name': 'OP', 'StartPositionTicks': 100000000},
        {'Name': 'Episode', 'StartPositionTicks': 450000000},
        {'Name': 'ED', 'StartPositionTicks': 900000000},
      ],
};

void main() {
  group('MediaBrowser user-scoped routes', () {
    test('Emby scopes current-user probes while Jellyfin keeps /Users/Me', () async {
      final embyRequests = _RequestCapture((_) => jsonResponse({'Configuration': <String, Object?>{}}));
      final jellyfinRequests = _RequestCapture((_) => jsonResponse({'Configuration': <String, Object?>{}}));
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      expect(await emby.checkHealth(), HealthStatus.online);
      expect(await emby.isHealthy(), isTrue);
      expect(await emby.fetchUserProfile(), isNotNull);
      expect(await jellyfin.checkHealth(), HealthStatus.online);
      expect(await jellyfin.isHealthy(), isTrue);
      expect(await jellyfin.fetchUserProfile(), isNotNull);

      expect(embyRequests.log, ['GET /Users/user-1?', 'GET /Users/user-1?', 'GET /Users/user-1?']);
      expect(jellyfinRequests.log, ['GET /Users/Me?', 'GET /Users/Me?', 'GET /Users/Me?']);
      expect(embyRequests.log, isNot(contains('GET /Users/Me?')));
      expect(embyRequests.requests.every((request) => request.body.isEmpty), isTrue);
      expect(jellyfinRequests.requests.every((request) => request.body.isEmpty), isTrue);
    });

    test('Emby scopes watched, favorite, and rating writes while Jellyfin keeps unprefixed routes', () async {
      final embyRequests = _RequestCapture((_) => http.Response('', 204));
      final jellyfinRequests = _RequestCapture((_) => http.Response('', 204));
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);
      final embyItem = _item(MediaBackend.emby);
      final jellyfinItem = _item(MediaBackend.jellyfin);

      await emby.markWatched(embyItem);
      await emby.markUnwatched(embyItem);
      await emby.setFavorite(embyItem, true);
      await emby.setFavorite(embyItem, false);
      await emby.rate(embyItem, 7);
      await emby.rate(embyItem, -1);
      await jellyfin.markWatched(jellyfinItem);
      await jellyfin.markUnwatched(jellyfinItem);
      await jellyfin.setFavorite(jellyfinItem, true);
      await jellyfin.setFavorite(jellyfinItem, false);
      await jellyfin.rate(jellyfinItem, 7);
      await jellyfin.rate(jellyfinItem, -1);

      expect(embyRequests.log, [
        'POST /Users/user-1/PlayedItems/item-1?userId=user-1',
        'DELETE /Users/user-1/PlayedItems/item-1?userId=user-1',
        'POST /Users/user-1/FavoriteItems/item-1?userId=user-1',
        'DELETE /Users/user-1/FavoriteItems/item-1?userId=user-1',
        'POST /Users/user-1/Items/item-1/Rating?userId=user-1&Likes=true',
        'DELETE /Users/user-1/Items/item-1/Rating?userId=user-1',
      ]);
      expect(jellyfinRequests.log, [
        'POST /UserPlayedItems/item-1?userId=user-1',
        'DELETE /UserPlayedItems/item-1?userId=user-1',
        'POST /UserFavoriteItems/item-1?userId=user-1',
        'DELETE /UserFavoriteItems/item-1?userId=user-1',
        'POST /UserItems/item-1/Rating?userId=user-1&Likes=true',
        'DELETE /UserItems/item-1/Rating?userId=user-1',
      ]);
      expect(embyRequests.requests.every((request) => request.body.isEmpty), isTrue);
      expect(jellyfinRequests.requests.every((request) => request.body.isEmpty), isTrue);
    });

    test('Emby reads Continue Watching from /Items while Jellyfin keeps /UserItems/Resume', () async {
      http.Response respond(http.Request request) => jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});

      final embyRequests = _RequestCapture(respond);
      final jellyfinRequests = _RequestCapture(respond);
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      expect(await emby.fetchContinueWatching(count: 1), isEmpty);
      expect(await jellyfin.fetchContinueWatching(count: 1), isEmpty);

      expect(
        embyRequests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        // Both Emby legs go to /Items: the resume leg because its dedicated route
        // cannot be filtered or paged there, and the Next Up leg because it is a
        // recency query over played episodes (which returns none here, so no
        // per-series query follows). See the resume-semantics and Next Up groups.
        ['GET /Items', 'GET /Items'],
        reason: embyRequests.log.join('\n'),
      );
      expect(
        embyRequests.requests.first.url.queryParameters['Filters'],
        'IsResumable',
        reason: 'the Emby resume leg lost its server-side filter',
      );
      expect(
        jellyfinRequests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        ['GET /UserItems/Resume', 'GET /Shows/NextUp'],
        reason: jellyfinRequests.log.join('\n'),
      );
      final embyResume = embyRequests.requests.first;
      final jellyfinResume = jellyfinRequests.requests.first;
      expect(embyResume.url.queryParameters, {
        'userId': 'user-1',
        // The server-side progress filter Emby's dedicated resume route lacks.
        'Filters': 'IsResumable',
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
        'Limit': '1',
        // Emby withholds these from list rows unless asked, so the hub field set
        // is widened for it and only for it.
        'Fields': 'Overview,ProductionYear,OfficialRating,PremiereDate,DateCreated,UserDataLastPlayedDate',
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        'EnableImageTypes': 'Primary,Backdrop,Logo',
        'ImageTypeLimit': '3',
      });
      expect(jellyfinResume.url.queryParameters, {
        'userId': 'user-1',
        'Limit': '1',
        // Jellyfin volunteers the row metadata and filters its own resume route,
        // so its request string is unchanged from before Emby existed.
        'Fields': 'Overview',
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        'EnableImageTypes': 'Primary,Backdrop,Logo',
        'ImageTypeLimit': '3',
      });
      expect(embyRequests.requests.every((request) => request.body.isEmpty), isTrue);
      expect(jellyfinRequests.requests.every((request) => request.body.isEmpty), isTrue);
    });

    test('an Emby resume row carries the played date it asked for', () async {
      final requests = _RequestCapture((request) {
        if (request.url.queryParameters['Filters'] == 'IsResumable') {
          return jsonResponse({
            'Items': [
              {
                'Id': 'movie-1',
                'Name': 'In Progress',
                'Type': 'Movie',
                'DateCreated': '2020-01-01T00:00:00.0000000Z',
                'UserData': {'LastPlayedDate': '2026-08-04T20:22:11.0000000Z', 'PlaybackPositionTicks': 2400000000},
              },
            ],
          });
        }
        return jsonResponse({'Items': <Object?>[]});
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final rows = await client.fetchContinueWatching(count: 1);

      expect(rows.single.lastViewedAt, DateTime.utc(2026, 8, 4, 20, 22, 11).millisecondsSinceEpoch ~/ 1000);
      expect(
        rows.single.recencySortKey,
        greaterThan(DateTime.utc(2020, 1, 2).millisecondsSinceEpoch ~/ 1000),
        reason: 'the resume row degraded to its addedAt',
      );
      final resume = requests.requests.firstWhere((request) => request.url.queryParameters.containsKey('Filters'));
      expect(resume.url.queryParameters['Fields'], contains('UserDataLastPlayedDate'));
    });

    test('Emby browse rows ask for the metadata Jellyfin volunteers', () async {
      // Measured on Emby 4.9.5: a list row omits ProductionYear,
      // OfficialRating and PremiereDate unless Fields names them, while
      // Jellyfin 10.11 returns all three in every row. Without the widened set
      // every Emby card loses its year and age-rating badge.
      final embyRequests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0}));
      final jellyfinRequests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0}));
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      await emby.fetchLibraryContent('lib-1', const LibraryQuery(limit: 5));
      await jellyfin.fetchLibraryContent('lib-1', const LibraryQuery(limit: 5));

      final embyFields = embyRequests.requests.last.url.queryParameters['Fields']!.split(',');
      final jellyfinFields = jellyfinRequests.requests.last.url.queryParameters['Fields']!.split(',');

      expect(embyFields, containsAll(<String>['ProductionYear', 'OfficialRating', 'PremiereDate', 'DateCreated']));
      // Jellyfin's request string must not gain them.
      expect(jellyfinFields, isNot(contains('ProductionYear')));
      expect(jellyfinFields, isNot(contains('OfficialRating')));
      // Everything the base set already carried survives on both.
      expect(embyFields, containsAll(jellyfinFields));
      // No duplicate entries when the base set already names one of them.
      expect(embyFields.toSet().length, embyFields.length, reason: 'duplicated field: $embyFields');
    });

    test('a field set that already names a withheld field is not duplicated', () async {
      final requests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0}));
      final emby = testEmbyClient(handler: requests.handle);
      addTearDown(emby.close);

      // The episode-queue set already carries PremiereDate.
      await emby.fetchClientSideEpisodeQueue('series-1');

      final fields = requests.requests.last.url.queryParameters['Fields']!.split(',');
      expect(fields.where((field) => field == 'PremiereDate').length, 1, reason: 'duplicated PremiereDate: $fields');
      expect(
        fields,
        containsAll(<String>['UserData', 'PremiereDate', 'ProductionYear', 'OfficialRating', 'DateCreated']),
      );
    });

    test('Emby scopes trailers and special features while Jellyfin keeps item routes', () async {
      final embyRequests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[]}));
      final jellyfinRequests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[]}));
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      expect(await emby.fetchExtras('item-1'), isEmpty);
      expect(await jellyfin.fetchExtras('item-1'), isEmpty);

      expect(embyRequests.log, [
        'GET /Users/user-1/Items/item-1/LocalTrailers?'
            'userId=user-1&EnableImageTypes=Primary%2CBackdrop%2CLogo&ImageTypeLimit=3',
        'GET /Users/user-1/Items/item-1/SpecialFeatures?'
            'userId=user-1&EnableImageTypes=Primary%2CBackdrop%2CLogo&ImageTypeLimit=3',
      ]);
      expect(jellyfinRequests.log, [
        'GET /Items/item-1/LocalTrailers?'
            'userId=user-1&EnableImageTypes=Primary%2CBackdrop%2CLogo&ImageTypeLimit=3',
        'GET /Items/item-1/SpecialFeatures?'
            'userId=user-1&EnableImageTypes=Primary%2CBackdrop%2CLogo&ImageTypeLimit=3',
      ]);
      expect(embyRequests.requests.every((request) => request.body.isEmpty), isTrue);
      expect(jellyfinRequests.requests.every((request) => request.body.isEmpty), isTrue);
    });
  });

  group('MediaBrowser row played dates', () {
    test('every Emby row set asks for the played date', () async {
      // A watched row with no played date makes the watch-state cache stamp
      // DateTime.now(), so this is not only about recency-ordered shelves: the
      // episode rows an offline sync walks need it too.
      final requests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[]}));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      await client.fetchLibraryContent('lib-1', const LibraryQuery(limit: 5));
      await client.fetchChildren('season-1');
      await client.fetchContinueWatching(count: 5);

      final withFields = requests.requests.where((request) => request.url.queryParameters.containsKey('Fields'));
      expect(withFields, isNotEmpty, reason: requests.log.join('\n'));
      for (final request in withFields) {
        expect(
          request.url.queryParameters['Fields'],
          contains('UserDataLastPlayedDate'),
          reason: 'row set without a played date: ${request.url.path}',
        );
      }
    });

    test('Jellyfin request strings stay free of the Emby-only token', () async {
      final requests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[]}));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await client.fetchLibraryContent('lib-1', const LibraryQuery(limit: 5));
      await client.fetchChildren('season-1');

      for (final request in requests.requests) {
        expect(request.url.query, isNot(contains('UserDataLastPlayedDate')));
      }
    });
  });

  group('MediaBrowser Next Up shelf', () {
    test('Emby rebuilds the shelf per series in last-played order', () async {
      // Emby only computes Next Up per series: unscoped /Shows/NextUp returns
      // nothing there under any parameter combination. The client therefore asks
      // /Items for recently played episodes and then queries each series.
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items') {
          return jsonResponse({
            'Items': [
              // Deliberately repeats series-b so the dedupe and ordering show.
              {'Id': 'ep-b1', 'SeriesId': 'series-b', 'Type': 'Episode'},
              {'Id': 'ep-a1', 'SeriesId': 'series-a', 'Type': 'Episode'},
              {'Id': 'ep-b0', 'SeriesId': 'series-b', 'Type': 'Episode'},
            ],
          });
        }
        final seriesId = request.url.queryParameters['SeriesId'];
        return jsonResponse({
          'Items': [
            {'Id': 'next-$seriesId', 'Name': 'Next of $seriesId', 'Type': 'Episode', 'SeriesId': seriesId},
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final rows = await client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 10);

      // Phase 1 asks for played episodes newest-first; phase 2 scopes per series.
      final recency = requests.requests.firstWhere((request) => request.url.path == '/Items');
      expect(recency.url.queryParameters['Filters'], 'IsPlayed');
      expect(recency.url.queryParameters['SortBy'], 'DatePlayed');
      expect(recency.url.queryParameters['SortOrder'], 'Descending');
      expect(recency.url.queryParameters['IncludeItemTypes'], 'Episode');

      final scoped = requests.requests
          .where((request) => request.url.path == '/Shows/NextUp')
          .map((request) => request.url.queryParameters['SeriesId'])
          .toList();
      expect(scoped, ['series-b', 'series-a'], reason: 'one scoped query per distinct series, in recency order');
      expect(scoped.every((id) => id != null), isTrue);

      // Rows keep the series recency order, not completion order.
      expect(rows.items.map((item) => item.id), ['next-series-b', 'next-series-a']);
      expect(rows.totalCount, 2);
    });

    test('a failed series lookup drops only that series', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items') {
          return jsonResponse({
            'Items': [
              {'Id': 'ep-a', 'SeriesId': 'series-a', 'Type': 'Episode'},
              {'Id': 'ep-b', 'SeriesId': 'series-b', 'Type': 'Episode'},
            ],
          });
        }
        if (request.url.queryParameters['SeriesId'] == 'series-a') {
          return jsonResponse({'Error': 'boom'}, status: 500);
        }
        return jsonResponse({
          'Items': [
            {'Id': 'next-series-b', 'Name': 'Survivor', 'Type': 'Episode', 'SeriesId': 'series-b'},
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final rows = await client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 10);

      expect(rows.items.map((item) => item.id), ['next-series-b']);
    });

    test('Emby with no played episodes issues no per-series query', () async {
      final requests = _RequestCapture((_) => jsonResponse({'Items': <Object?>[]}));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final rows = await client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 10);

      expect(rows.items, isEmpty);
      expect(requests.requests.where((request) => request.url.path == '/Shows/NextUp'), isEmpty);
    });

    test('paging the reconstructed shelf past its end keeps the total and adds no requests', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items' && request.url.queryParameters['Filters'] == 'IsPlayed') {
          return jsonResponse({
            'Items': [
              for (var i = 0; i < 3; i++) {'Id': 'ep-$i', 'SeriesId': 'series-$i', 'Type': 'Episode'},
            ],
          });
        }
        final seriesId = request.url.queryParameters['SeriesId'];
        return jsonResponse({
          'Items': [
            {'Id': 'next-$seriesId', 'Name': 'Next', 'Type': 'Episode', 'SeriesId': seriesId},
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final first = await client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 2);
      expect(first.items.map((item) => item.id), ['next-series-0', 'next-series-1']);
      expect(first.totalCount, 3);

      final beyond = await client.fetchMoreHubItemsPage('home.nextup', start: 99, size: 2);
      expect(beyond.items, isEmpty);
      expect(beyond.totalCount, 3, reason: 'total changed past the end of the shelf');
      expect(beyond.offset, 99);

      // Each page costs one recency query plus one query per distinct series —
      // never more, however far past the end the caller asks.
      final perPage = 1 + 3;
      expect(requests.requests, hasLength(perPage * 2), reason: requests.log.join('\n'));
    });

    test('Jellyfin keeps the single unscoped Next Up request', () async {
      final requests = _RequestCapture(
        (_) => jsonResponse({
          'Items': [
            {'Id': 'next-1', 'Name': 'Next', 'Type': 'Episode'},
          ],
          'TotalRecordCount': 1,
        }),
      );
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final rows = await client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 10);

      expect(requests.requests.map((request) => request.url.path).toList(), ['/Shows/NextUp']);
      expect(requests.requests.single.url.queryParameters.containsKey('SeriesId'), isFalse);
      expect(rows.items.map((item) => item.id), ['next-1']);
    });
  });

  group('MediaBrowser resume semantics', () {
    /// Emby's resume route also returns zero-position *next* episodes; Jellyfin's
    /// returns only genuinely started items.
    Map<String, Object?> resumePayload() => {
      'Items': [
        {
          'Id': 'movie-1',
          'Name': 'Half Watched Movie',
          'Type': 'Movie',
          'RunTimeTicks': 9000000000,
          'UserData': {'PlaybackPositionTicks': 2400000000, 'Played': false},
        },
        {
          'Id': 'ep-next',
          'Name': 'Next Episode',
          'Type': 'Episode',
          'RunTimeTicks': 9000000000,
          'UserData': {'PlaybackPositionTicks': 0, 'Played': false},
        },
      ],
      'TotalRecordCount': 2,
    };

    test('Emby reads resume from /Items with a server-side IsResumable filter', () async {
      // Emby's dedicated resume route returns every started series' next episode
      // alongside the genuinely in-progress items and sorts the latter LAST, so
      // it cannot be paged. /Items?Filters=IsResumable returns only real progress.
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items' && request.url.queryParameters['Filters'] == 'IsResumable') {
          return jsonResponse({
            'Items': [(resumePayload()['Items'] as List).first],
            'TotalRecordCount': 1,
          });
        }
        return jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 10);
      final continueHub = hubs.firstWhere((hub) => hub.id.endsWith('continue'));

      expect(continueHub.items.map((item) => item.id), ['movie-1']);
      // Never the resume route, which cannot be filtered or paged on Emby.
      expect(requests.requests.where((request) => request.url.path.endsWith('/Items/Resume')), isEmpty);
      final resumeRequest = requests.requests.firstWhere(
        (request) => request.url.queryParameters['Filters'] == 'IsResumable',
      );
      expect(resumeRequest.url.queryParameters['SortBy'], 'DatePlayed');
      expect(resumeRequest.url.queryParameters['SortOrder'], 'Descending');
    });

    test('Jellyfin keeps its dedicated resume route unfiltered', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/UserItems/Resume') return jsonResponse(resumePayload());
        return jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});
      });
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 10);
      final continueHub = hubs.firstWhere((hub) => hub.id.endsWith('continue'));

      // Jellyfin's route is already filtered server-side; the client must not
      // second-guess it, and its request shape must be unchanged.
      expect(continueHub.items.map((item) => item.id), ['movie-1', 'ep-next']);
      final resumeRequest = requests.requests.firstWhere((request) => request.url.path == '/UserItems/Resume');
      expect(resumeRequest.url.queryParameters.containsKey('Filters'), isFalse);
      expect(resumeRequest.url.queryParameters.containsKey('SortBy'), isFalse);
    });

    test('the paged Emby continue hub uses the same filtered route', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items' && request.url.queryParameters['Filters'] == 'IsResumable') {
          return jsonResponse({
            'Items': [(resumePayload()['Items'] as List).first],
            'TotalRecordCount': 1,
          });
        }
        return jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final page = await client.fetchMoreHubItemsPage('home.continue', start: 0, size: 10);

      expect(page.items.map((item) => item.id), ['movie-1']);
      expect(page.totalCount, 1, reason: 'server-side total lost');
      expect(requests.requests.single.url.queryParameters['StartIndex'], '0');
    });

    test('a reconstructed Emby Next Up preview honours the requested limit', () async {
      // 10 started series, preview asks for 3: the shelf must be sliced, not
      // returned at the series-lookup cap.
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items' && request.url.queryParameters['Filters'] == 'IsPlayed') {
          return jsonResponse({
            'Items': [
              for (var i = 0; i < 10; i++) {'Id': 'ep-$i', 'SeriesId': 'series-$i', 'Type': 'Episode'},
            ],
          });
        }
        final seriesId = request.url.queryParameters['SeriesId'];
        if (seriesId != null) {
          return jsonResponse({
            'Items': [
              {'Id': 'next-$seriesId', 'Name': 'Next', 'Type': 'Episode', 'SeriesId': seriesId},
            ],
          });
        }
        return jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 3);
      final nextUp = hubs.firstWhere((hub) => hub.id.endsWith('nextup'));

      expect(nextUp.items, hasLength(3), reason: 'preview ignored the requested limit');
      expect(nextUp.items.map((item) => item.id), ['next-series-0', 'next-series-1', 'next-series-2']);
    });

    test('the Emby recency probe never moves the active endpoint', () async {
      var exhausted = 0;
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Items' && request.url.queryParameters['Filters'] == 'IsPlayed') {
          return jsonResponse({'Error': 'boom'}, status: 500);
        }
        return jsonResponse({'Items': <Object?>[], 'TotalRecordCount': 0});
      });
      final client = testEmbyClient(
        connection: testEmbyConnection(baseUrls: const ['https://emby.example.com', 'https://fallback.example.com']),
        handler: requests.handle,
        onAllEndpointsExhausted: () => exhausted++,
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 5);

      // A failing best-effort shelf must degrade, not trigger failover.
      expect(hubs.where((hub) => hub.id.endsWith('nextup')), isEmpty);
      expect(exhausted, 0, reason: 'the recency probe escalated to endpoint exhaustion');
      expect(
        requests.requests.every((request) => request.url.host == 'emby.example.com'),
        isTrue,
        reason: 'the recency probe switched endpoints',
      );
    });
  });

  group('MediaBrowser Continue Watching ordering', () {
    Map<String, Object?> episodeRow(String id, String seriesId, String created) => {
      'Id': id,
      'Name': id,
      'Type': 'Episode',
      'SeriesId': seriesId,
      'SeriesName': seriesId,
      'DateCreated': created,
    };

    test('Emby stamps each reconstructed row with its series play date', () async {
      // A Next Up episode has never been played, so its own UserData carries no
      // date. Without the stamp the shelf's sort key falls back to when the
      // episode was added to the library — which is what `DateCreated` is here,
      // deliberately inverted against the recency order.
      final requests = _RequestCapture((request) {
        final query = request.url.queryParameters;
        if (query['Filters'] == 'IsResumable') return jsonResponse({'Items': <Object?>[]});
        if (query['Filters'] == 'IsPlayed') {
          return jsonResponse({
            'Items': [
              {
                'Id': 'played-recent',
                'SeriesId': 'series-recent',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': '2026-08-04T21:00:00.0000000Z'},
              },
              {
                'Id': 'played-older',
                'SeriesId': 'series-older',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': '2026-08-01T21:00:00.0000000Z'},
              },
            ],
          });
        }
        final seriesId = query['SeriesId']!;
        return jsonResponse({
          'Items': [
            {
              'Id': 'next-$seriesId',
              'Name': 'next-$seriesId',
              'Type': 'Episode',
              'SeriesId': seriesId,
              // Inverted against the play order.
              'DateCreated': seriesId == 'series-older'
                  ? '2030-01-01T00:00:00.0000000Z'
                  : '2020-01-01T00:00:00.0000000Z',
            },
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final shelf = await client.fetchContinueWatching(count: 10);

      expect(shelf.map((item) => item.id), ['next-series-recent', 'next-series-older']);
      expect(shelf.map((item) => item.lastViewedAt), [
        DateTime.utc(2026, 8, 4, 21).millisecondsSinceEpoch ~/ 1000,
        DateTime.utc(2026, 8, 1, 21).millisecondsSinceEpoch ~/ 1000,
      ], reason: 'rows were not stamped with their series play date');
      // The recency query must ask for the date, and the per-series enrichment
      // (ParentId + Fields=UserData) must never run: the stamp makes it redundant.
      final probe = requests.requests.firstWhere((request) => request.url.queryParameters['Filters'] == 'IsPlayed');
      expect(probe.url.queryParameters['Fields'], contains('UserDataLastPlayedDate'));
      expect(
        requests.requests.where((request) => request.url.queryParameters.containsKey('ParentId')),
        isEmpty,
        reason: 'redundant per-series enrichment ran on Emby',
      );
    });

    test('Jellyfin still enriches and re-sorts by recency', () async {
      final requests = _RequestCapture((request) {
        final query = request.url.queryParameters;
        if (request.url.path == '/UserItems/Resume') {
          return jsonResponse({'Items': <Object?>[]});
        }
        if (request.url.path == '/Shows/NextUp') {
          return jsonResponse({
            'Items': [
              episodeRow('ep-a', 'series-a', '2020-01-01T00:00:00.0000000Z'),
              episodeRow('ep-b', 'series-b', '2020-01-01T00:00:00.0000000Z'),
            ],
          });
        }
        // The per-series enrichment: series-b was played more recently.
        final parentId = query['ParentId'];
        return jsonResponse({
          'Items': [
            {
              'Id': 'played-$parentId',
              'Type': 'Episode',
              'UserData': {
                'LastPlayedDate': parentId == 'series-b'
                    ? '2026-08-04T21:00:00.0000000Z'
                    : '2026-08-01T21:00:00.0000000Z',
              },
            },
          ],
        });
      });
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final shelf = await client.fetchContinueWatching(count: 10);

      // series-b enriched to the newer date, so it must lead.
      expect(shelf.map((item) => item.id), ['ep-b', 'ep-a']);
      expect(
        requests.requests.where((request) => request.url.queryParameters.containsKey('ParentId')),
        isNotEmpty,
        reason: 'Jellyfin lost its recency enrichment',
      );
    });
  });

  group('MediaBrowser Next Up budget', () {
    test('a stalled pass is bounded by one whole-pass wall clock', () async {
      // Per-request timeouts cannot bound this: MediaServerHttpClient applies
      // each to the connect and receive phases independently, and the probe and
      // the per-series lookups would otherwise bound separately and add up. One
      // timer covers the whole pass, probe included.
      final stalled = Completer<void>();
      addTearDown(() {
        if (!stalled.isCompleted) stalled.complete();
      });
      final client = testEmbyClient(
        handler: (request) async {
          if (request.url.queryParameters['Filters'] == 'IsResumable') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'movie-1', 'Name': 'In Progress', 'Type': 'Movie'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          // Both the recency probe and every per-series lookup hang.
          await stalled.future;
          return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);

      final sw = Stopwatch()..start();
      final shelf = await client.fetchContinueWatching(count: 10);
      sw.stop();

      expect(shelf.map((item) => item.id), ['movie-1'], reason: 'the resume leg was sunk by the stalled pass');
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 6)),
        reason: 'the pass ran past its whole-pass budget (${sw.elapsed})',
      );
    });
  });

  group('MediaBrowser Next Up stamping', () {
    test('a repeated series keeps its newest play and odd dtos still map', () async {
      final requests = _RequestCapture((request) {
        if (request.url.queryParameters['Filters'] == 'IsResumable') {
          return jsonResponse({'Items': <Object?>[]});
        }
        if (request.url.queryParameters['Filters'] == 'IsPlayed') {
          return jsonResponse({
            'Items': [
              // Newest first, and the same series binged twice: the first row is
              // the one that decides its rank.
              {
                'Id': 'ep-new',
                'SeriesId': 'series-a',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': '2026-08-04T21:00:00.0000000Z'},
              },
              {
                'Id': 'ep-old',
                'SeriesId': 'series-a',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': '2020-01-01T00:00:00.0000000Z'},
              },
              // A played episode the server gave no date for at all.
              {'Id': 'ep-undated', 'SeriesId': 'series-b', 'Type': 'Episode'},
            ],
          });
        }
        final seriesId = request.url.queryParameters['SeriesId'];
        return jsonResponse({
          'Items': [
            {
              'Id': 'next-$seriesId',
              'Name': 'next-$seriesId',
              'Type': 'Episode',
              'SeriesId': seriesId,
              'DateCreated': '2021-05-06T00:00:00.0000000Z',
              // Carries its own UserData, which the stamp must preserve.
              'UserData': {'PlaybackPositionTicks': 30000000, 'Played': false},
            },
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final shelf = await client.fetchContinueWatching(count: 10);

      expect(shelf.map((item) => item.id), ['next-series-a', 'next-series-b']);
      // series-a takes the newer of its two plays, not the last one seen.
      expect(shelf.first.lastViewedAt, DateTime.utc(2026, 8, 4, 21).millisecondsSinceEpoch ~/ 1000);
      // The row's own UserData survived the stamp.
      expect(shelf.first.viewOffsetMs, 3000);
      // An undated series degrades to its addedAt rather than being dropped.
      expect(shelf.last.lastViewedAt, isNull);
      expect(shelf.last.addedAt, isNotNull);
      // One request per distinct series, not per played episode.
      expect(requests.requests.where((request) => request.url.path == '/Shows/NextUp'), hasLength(2));
    });
  });

  group('MediaBrowser Next Up wall clock', () {
    test('a response that stalls between phases still lands inside the budget', () async {
      // MediaServerHttpClient times the connect and receive phases
      // independently, so headers just under the per-request timeout followed by
      // a stalled body outlive it. Only racing the probe against the pass
      // deadline bounds this.
      final stalledBody = StreamController<List<int>>();
      addTearDown(stalledBody.close);
      final client = testEmbyClient(
        httpClient: MockClient.streaming((request, _) async {
          Map<String, String> query() => request.url.queryParameters;
          if (query()['Filters'] == 'IsResumable') {
            final body = utf8.encode(
              jsonEncode({
                'Items': [
                  {'Id': 'movie-1', 'Name': 'In Progress', 'Type': 'Movie'},
                ],
              }),
            );
            return http.StreamedResponse(Stream.value(body), 200, headers: {'content-type': 'application/json'});
          }
          if (query()['Filters'] == 'IsPlayed') {
            // Headers under the 3s per-request timeout, then a body that never
            // arrives: 2.5s + 3s receive would be 5.5s unraced.
            await Future<void>.delayed(const Duration(milliseconds: 2500));
            return http.StreamedResponse(stalledBody.stream, 200, headers: {'content-type': 'application/json'});
          }
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"Items":[]}')),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);

      final sw = Stopwatch()..start();
      final shelf = await client.fetchContinueWatching(count: 10);
      sw.stop();

      expect(shelf.map((item) => item.id), ['movie-1']);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 4800)),
        reason: 'the stalled probe outlived the pass deadline (${sw.elapsed})',
      );
    });
  });

  group('MediaBrowser Next Up cutoff', () {
    test('Emby drops series last played before the cutoff Jellyfin enforces', () async {
      // Emby's /Shows/NextUp ignores NextUpDateCutoff, so the window has to be
      // applied to the recency scan instead.
      final requests = _RequestCapture((request) {
        if (request.url.queryParameters['Filters'] == 'IsResumable') {
          return jsonResponse({'Items': <Object?>[]});
        }
        if (request.url.queryParameters['Filters'] == 'IsPlayed') {
          return jsonResponse({
            'Items': [
              {
                'Id': 'ep-recent',
                'SeriesId': 'series-recent',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': DateTime.now().toUtc().toIso8601String()},
              },
              {
                'Id': 'ep-abandoned',
                'SeriesId': 'series-abandoned',
                'Type': 'Episode',
                'UserData': {'LastPlayedDate': '2019-01-01T00:00:00.0000000Z'},
              },
              // No date at all: kept, because only the server can withhold it.
              {'Id': 'ep-undated', 'SeriesId': 'series-undated', 'Type': 'Episode'},
            ],
          });
        }
        final seriesId = request.url.queryParameters['SeriesId'];
        return jsonResponse({
          'Items': [
            {'Id': 'next-$seriesId', 'Type': 'Episode', 'SeriesId': seriesId},
          ],
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final shelf = await client.fetchContinueWatching(count: 10);

      expect(shelf.map((item) => item.id), ['next-series-recent', 'next-series-undated']);
      // The abandoned series must not even cost a per-series request.
      expect(
        requests.requests.where((request) => request.url.queryParameters['SeriesId'] == 'series-abandoned'),
        isEmpty,
        reason: 'queried a series outside the cutoff',
      );
    });
  });

  group('MediaBrowser Next Up cancellation', () {
    test('a caller cancellation is disruption, not an empty shelf', () async {
      // The pass swallows its *own* deadline so the shelf degrades gracefully.
      // A cancellation the caller asked for must still propagate, so a paged
      // caller can tell "disrupted" from "the user has nothing to watch next".
      final abort = AbortController();
      final client = testEmbyClient(
        handler: (request) async {
          if (request.url.queryParameters['Filters'] == 'IsPlayed') {
            abort.abort();
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);

      await expectLater(
        client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 5, abort: abort),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
    });

    test('a cancellation reported as a timeout is still a cancellation', () async {
      // The transport may honour the abort as an ordinary timeout, which
      // `_safeFetchItemsArray` treats as best-effort empty. The caller's abort
      // must still win over publishing an empty shelf.
      final abort = AbortController();
      final client = testEmbyClient(
        handler: (request) async {
          if (request.url.queryParameters['Filters'] == 'IsPlayed') {
            abort.abort();
            // Resolve as an ordinary empty response, never as a cancellation.
            return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
          }
          return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);

      await expectLater(
        client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 5, abort: abort),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
    });

    test('a cancellation during the per-series phase is not a partial page', () async {
      // The per-series loop breaks on either abort. A partial shelf must not be
      // published as though those series had no next episode.
      final abort = AbortController();
      final client = testEmbyClient(
        handler: (request) async {
          if (request.url.queryParameters['Filters'] == 'IsPlayed') {
            return http.Response(
              jsonEncode({
                'Items': [
                  for (var i = 0; i < 12; i++) {'Id': 'ep-$i', 'SeriesId': 'series-$i', 'Type': 'Episode'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Shows/NextUp') {
            // Cancel once the first batch has produced rows, so the loop breaks
            // with a non-empty partial result.
            abort.abort();
            final seriesId = request.url.queryParameters['SeriesId'];
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'next-$seriesId', 'Type': 'Episode', 'SeriesId': seriesId},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);

      await expectLater(
        client.fetchMoreHubItemsPage('home.nextup', start: 0, size: 5, abort: abort),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
    });
  });

  group('MediaBrowser library filter facets', () {
    test('Emby reassembles all four filter facets from its per-facet routes', () async {
      final requests = _RequestCapture((request) {
        final names = switch (request.url.path) {
          '/Genres' => ['Drama', 'Action'],
          // Emby serves the ratings facet here, NOT at /Items/OfficialRatings
          // (which 404s) — the wrong spelling once made this facet look absent.
          '/OfficialRatings' => ['R', 'PG-13'],
          '/Tags' => ['Holiday', 'Archive'],
          '/Years' => ['1999', '2024', '2010'],
          _ => <String>[],
        };
        return jsonResponse({
          'Items': names.map((name) => {'Name': name}).toList(),
          'TotalRecordCount': names.length,
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('lib-1', libraryKind: MediaKind.movie);

      expect(requests.log.toSet(), {
        'GET /Genres?UserId=user-1&ParentId=lib-1&Recursive=true',
        'GET /OfficialRatings?UserId=user-1&ParentId=lib-1&Recursive=true',
        'GET /Tags?UserId=user-1&ParentId=lib-1&Recursive=true',
        'GET /Years?UserId=user-1&ParentId=lib-1&Recursive=true',
      });
      expect(requests.requests, hasLength(4), reason: requests.log.join('\n'));
      expect(requests.requests.where((request) => request.url.path == '/Items/Filters'), isEmpty);
      for (final request in requests.requests) {
        expect(request.method, 'GET');
        expect(request.url.queryParameters, {'UserId': 'user-1', 'ParentId': 'lib-1', 'Recursive': 'true'});
        expect(request.body, isEmpty);
      }
      expect(result.cachedValues['genre']!.map((value) => value.key).toList(), ['Action', 'Drama']);
      expect(result.cachedValues['contentRating']!.map((value) => value.key).toList(), ['PG-13', 'R']);
      expect(result.cachedValues['tag']!.map((value) => value.key).toList(), ['Archive', 'Holiday']);
      expect(result.cachedValues['year']!.map((value) => value.key).toList(), ['2024', '2010', '1999']);
      expect(result.filters.map((filter) => filter.filter), contains('contentRating'));
    });

    test('Emby preserves successful filter facets when one facet fails', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Tags') {
          return jsonResponse({'Error': 'tags failed'}, status: 500);
        }
        final names = switch (request.url.path) {
          '/Genres' => ['Action'],
          '/OfficialRatings' => ['PG'],
          _ => ['2024'],
        };
        return jsonResponse({
          'Items': names.map((name) => {'Name': name}).toList(),
          'TotalRecordCount': names.length,
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('lib-1', libraryKind: MediaKind.movie);

      expect(requests.requests, hasLength(4), reason: requests.log.join('\n'));
      expect(result.cachedValues['genre']!.map((value) => value.key).toList(), ['Action']);
      expect(result.cachedValues['contentRating']!.map((value) => value.key).toList(), ['PG']);
      expect(result.cachedValues['year']!.map((value) => value.key).toList(), ['2024']);
      expect(result.cachedValues['tag'] ?? const [], isEmpty);
    });

    test('Jellyfin keeps the single aggregate filter request', () async {
      final requests = _RequestCapture(
        (_) => jsonResponse({
          'Genres': ['Action'],
          'OfficialRatings': ['PG'],
          'Tags': ['Archive'],
          'Years': [2024],
        }),
      );
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('lib-1', libraryKind: MediaKind.movie);

      expect(requests.log, ['GET /Items/Filters?userId=user-1&ParentId=lib-1']);
      expect(requests.requests.single.url.queryParameters, {'userId': 'user-1', 'ParentId': 'lib-1'});
      expect(
        requests.requests.where(
          (request) => const {'/Genres', '/OfficialRatings', '/Tags', '/Years'}.contains(request.url.path),
        ),
        isEmpty,
      );
      expect(result.cachedValues['contentRating']!.map((value) => value.key).toList(), ['PG']);
    });
  });

  group('MediaBrowser playback session identity', () {
    test('Emby synthesizes one item-derived PlaySessionId for a replay triple', () async {
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      await _reportPlaybackTriple(client);

      expect(requests.log, [
        'POST /Sessions/Playing?',
        'POST /Sessions/Playing/Progress?',
        'POST /Sessions/Playing/Stopped?',
      ]);
      final bodies = requests.requests.map((request) => jsonDecode(request.body) as Map<String, dynamic>).toList();
      expect(bodies.map((body) => body['PlaySessionId']).toList(), [
        'plezy-replay-item-1',
        'plezy-replay-item-1',
        'plezy-replay-item-1',
      ]);
      expect(bodies.every((body) => body['ItemId'] == 'item-1'), isTrue);
    });

    test('Emby preserves an explicit PlaySessionId across the replay triple', () async {
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      await _reportPlaybackTriple(client, playSessionId: 'caller-session');

      expect(requests.log, [
        'POST /Sessions/Playing?',
        'POST /Sessions/Playing/Progress?',
        'POST /Sessions/Playing/Stopped?',
      ]);
      final bodies = requests.requests.map((request) => jsonDecode(request.body) as Map<String, dynamic>);
      expect(bodies.map((body) => body['PlaySessionId']).toList(), [
        'caller-session',
        'caller-session',
        'caller-session',
      ]);
    });

    test('Jellyfin keeps PlaySessionId absent when the caller supplies none', () async {
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await _reportPlaybackTriple(client);

      expect(requests.log, [
        'POST /Sessions/Playing?',
        'POST /Sessions/Playing/Progress?',
        'POST /Sessions/Playing/Stopped?',
      ]);
      final bodies = requests.requests.map((request) => jsonDecode(request.body) as Map<String, dynamic>).toList();
      expect(bodies, [
        {
          'ItemId': 'item-1',
          'PositionTicks': 10000000,
          'CanSeek': true,
          'IsPaused': false,
          'IsMuted': false,
          'PlayMethod': 'DirectPlay',
          'RepeatMode': 'RepeatNone',
          'PlaybackOrder': 'Default',
        },
        {
          'ItemId': 'item-1',
          'PositionTicks': 20000000,
          'CanSeek': true,
          'IsPaused': false,
          'IsMuted': false,
          'PlayMethod': 'DirectPlay',
          'RepeatMode': 'RepeatNone',
          'PlaybackOrder': 'Default',
        },
        {'ItemId': 'item-1', 'PositionTicks': 30000000, 'Failed': false},
      ]);
      expect(bodies.every((body) => !body.containsKey('PlaySessionId')), isTrue);
    });
  });

  group('MediaBrowser playlist dialect', () {
    test('Emby omits MediaTypes and labels untyped playlists with the requested type', () async {
      var responseIndex = 0;
      final requests = _RequestCapture((_) {
        responseIndex++;
        return jsonResponse({
          'Items': [
            {'Id': 'playlist-$responseIndex', 'Name': 'Playlist $responseIndex', 'Type': 'Playlist'},
          ],
          'TotalRecordCount': 1,
        });
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final video = await client.fetchPlaylistsPage(playlistType: 'video');
      final audio = await client.fetchPlaylistsPage(playlistType: 'audio');

      expect(
        requests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        ['GET /Items', 'GET /Items'],
        reason: requests.log.join('\n'),
      );
      for (final request in requests.requests) {
        expect(request.url.queryParameters, {
          'userId': 'user-1',
          'IncludeItemTypes': 'Playlist',
          'Recursive': 'true',
          'StartIndex': '0',
          'Limit': '200',
          'Fields': 'Overview,DateCreated,DateLastSaved,DateModified,ChildCount,Tags',
          'EnableImageTypes': 'Primary,Backdrop,Logo',
          'ImageTypeLimit': '3',
        });
        expect(request.url.queryParameters.containsKey('MediaTypes'), isFalse);
        expect(request.body, isEmpty);
      }
      expect(video.items.single.playlistType, 'video');
      expect(audio.items.single.playlistType, 'audio');
    });

    test('an Emby playlist timestamp comes from DateModified, which must be requested', () async {
      // Emby leaves DateLastSaved null on playlists and, unlike the detail
      // route, its list route honours `Fields` strictly — so the mapper's
      // fallback is dead unless DateModified is in the request.
      final requests = _RequestCapture(
        (request) => jsonResponse({
          'Items': [
            {
              'Id': 'pl-1',
              'Name': 'Road Trip',
              'DateCreated': '2026-01-01T00:00:00.0000000Z',
              'DateModified': '2026-02-03T04:05:06.0000000Z',
            },
          ],
          'TotalRecordCount': 1,
        }),
      );
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final page = await client.fetchPlaylistsPage(playlistType: 'video');

      expect(requests.requests.single.url.queryParameters['Fields'], contains('DateModified'));
      expect(page.items.single.updatedAt, DateTime.utc(2026, 2, 3, 4, 5, 6).millisecondsSinceEpoch ~/ 1000);
      expect(page.items.single.addedAt, DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000);
    });

    test('Jellyfin keeps MediaTypes and lets the DTO media type win over the requested label', () async {
      final requests = _RequestCapture((request) {
        final requestedType = request.url.queryParameters['MediaTypes'];
        return jsonResponse({
          'Items': [
            {
              'Id': 'playlist-${requestedType!.toLowerCase()}',
              'Name': '$requestedType Playlist',
              'Type': 'Playlist',
              'MediaType': requestedType == 'Video' ? 'Audio' : 'Video',
            },
          ],
          'TotalRecordCount': 1,
        });
      });
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final video = await client.fetchPlaylistsPage(playlistType: 'video');
      final audio = await client.fetchPlaylistsPage(playlistType: 'audio');

      expect(
        requests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        ['GET /Items', 'GET /Items'],
        reason: requests.log.join('\n'),
      );
      expect(requests.requests.map((request) => request.url.queryParameters['MediaTypes']).toList(), [
        'Video',
        'Audio',
      ]);
      for (final request in requests.requests) {
        expect(request.url.queryParameters['IncludeItemTypes'], 'Playlist');
        expect(request.body, isEmpty);
      }
      expect(video.items.single.playlistType, 'audio');
      expect(audio.items.single.playlistType, 'video');
    });
  });

  group('MediaBrowser Continue Watching removal', () {
    test('Emby hides an item from Continue Watching through the user-scoped route', () async {
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      await client.removeFromContinueWatching(testMediaItem(id: 'item-1', backend: MediaBackend.emby));

      // Emby 4.9.5 answers this 200 and keeps UserData.PlaybackPositionTicks,
      // which is why the capability is advertised rather than throwing.
      expect(requests.log, ['POST /Users/user-1/Items/item-1/HideFromResume?Hide=true']);
      expect(client.capabilities.continueWatchingRemoval, isTrue);
    });

    test('Jellyfin still refuses Continue Watching removal without a request', () async {
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      // Jellyfin 10.11 404s on both HideFromResume spellings, so the operation
      // must stay unsupported and issue nothing.
      await expectLater(
        client.removeFromContinueWatching(testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin)),
        throwsA(isA<UnsupportedError>()),
      );
      expect(requests.log, isEmpty);
      expect(client.capabilities.continueWatchingRemoval, isFalse);
    });
  });

  group('MediaBrowser mark-watched clears a surviving resume position', () {
    // Continue Watching membership on this API is `PlaybackPositionTicks > 0`
    // alone, so a played item that keeps a position is pinned to the shelf
    // forever. markWatched must assert that postcondition, not assume it
    // (#1812).
    http.Response Function(http.Request) respondWithPosition(int ticks) {
      return (request) {
        if (request.url.path.endsWith('/UserData')) return http.Response('', 204);
        return jsonResponse({'ItemId': 'item-1', 'Played': true, 'PlaybackPositionTicks': ticks});
      };
    }

    test('Jellyfin clears it through the unprefixed user-data route', () async {
      final requests = _RequestCapture(respondWithPosition(12000000000));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await client.markWatched(_item(MediaBackend.jellyfin));

      expect(requests.log, [
        'POST /UserPlayedItems/item-1?userId=user-1',
        'POST /UserItems/item-1/UserData?userId=user-1',
      ]);
      expect(jsonDecode(requests.requests.last.body), {'PlaybackPositionTicks': 0});
    });

    test('Emby clears it through the user-scoped user-data route', () async {
      final requests = _RequestCapture(respondWithPosition(12000000000));
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      await client.markWatched(_item(MediaBackend.emby));

      expect(requests.log, [
        'POST /Users/user-1/PlayedItems/item-1?userId=user-1',
        'POST /Users/user-1/Items/item-1/UserData?userId=user-1',
      ]);
      expect(jsonDecode(requests.requests.last.body), {'PlaybackPositionTicks': 0});
    });

    test('a mark that already zeroed the position issues no follow-up write', () async {
      // The normal case. A second request on every mark would double the cost
      // of the app's most common watch-state write.
      final requests = _RequestCapture(respondWithPosition(0));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await client.markWatched(_item(MediaBackend.jellyfin));

      expect(requests.log, ['POST /UserPlayedItems/item-1?userId=user-1']);
    });

    test('a body without UserData is left alone', () async {
      // Older servers answer the played toggle with 204 and no DTO; there is
      // nothing to assert against, so do not guess.
      final requests = _RequestCapture((_) => http.Response('', 204));
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await client.markWatched(_item(MediaBackend.jellyfin));

      expect(requests.log, ['POST /UserPlayedItems/item-1?userId=user-1']);
    });

    test('a failed clear surfaces as MediaServerHttpException', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path.endsWith('/UserData')) return http.Response('nope', 500);
        return jsonResponse({'ItemId': 'item-1', 'Played': true, 'PlaybackPositionTicks': 12000000000});
      });
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      await expectLater(client.markWatched(_item(MediaBackend.jellyfin)), throwsA(isA<MediaServerHttpException>()));
    });
  });

  group('MediaBrowser name-pair item fields', () {
    test('Emby item tags and genres survive the browse path via the name-pair arrays', () async {
      // Real Emby DTO shape: the plain arrays are absent, the name-pair
      // siblings carry the values. Reading only `Tags` dropped every label.
      final client = testEmbyClient(
        handler: (_) async => jsonResponse({
          'Id': '7330',
          'Name': 'Movie 001',
          'Type': 'Movie',
          'Genres': <String>[],
          'GenreItems': [
            {'Name': 'Action', 'Id': 3},
            {'Name': 'Science Fiction', 'Id': 4},
          ],
          'TagItems': [
            {'Name': 'smoke-label', 'Id': 7},
          ],
        }),
      );
      addTearDown(client.close);

      final item = (await client.fetchItem('7330'))!;

      expect(item.labels, ['smoke-label']);
      expect(item.genres, ['Action', 'Science Fiction']);
      expect(item.backend, MediaBackend.emby);
    });

    test('Jellyfin keeps reading the plain arrays and ignores absent name pairs', () async {
      final client = testJellyfinClient(
        handler: (_) async => jsonResponse({
          'Id': 'item-1',
          'Name': 'Movie',
          'Type': 'Movie',
          'Genres': ['Drama'],
          'Tags': ['archive'],
        }),
      );
      addTearDown(client.close);

      final item = (await client.fetchItem('item-1'))!;

      expect(item.genres, ['Drama']);
      expect(item.labels, ['archive']);
    });

    test('the plain array wins when a server sends both', () async {
      final client = testEmbyClient(
        handler: (_) async => jsonResponse({
          'Id': '1',
          'Name': 'Both',
          'Type': 'Movie',
          'Tags': ['plain'],
          'TagItems': [
            {'Name': 'pair'},
          ],
        }),
      );
      addTearDown(client.close);

      expect((await client.fetchItem('1'))!.labels, ['plain']);
    });
  });

  group('MediaBrowser feature gates', () {
    test('Emby returns no lyrics without a request while Jellyfin keeps its lyrics route', () async {
      final embyRequests = _RequestCapture((_) => http.Response('harmful request', 500));
      final jellyfinRequests = _RequestCapture(
        (_) => jsonResponse({
          'Lyrics': [
            {'Text': 'Line one'},
          ],
        }),
      );
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      expect(await emby.fetchLyrics(_item(MediaBackend.emby, kind: MediaKind.track)), isNull);
      final lyrics = await jellyfin.fetchLyrics(_item(MediaBackend.jellyfin, kind: MediaKind.track));

      expect(embyRequests.log, isEmpty);
      expect(jellyfinRequests.log, ['GET /Audio/item-1/Lyrics?']);
      expect(lyrics, isNotNull);
      expect(lyrics!.lines.map((line) => line.text).toList(), ['Line one']);
    });

    test('Emby derives playback markers from chapters without requesting media segments', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Users/user-1/Items/item-1') {
          return jsonResponse(_chapterItem());
        }
        return http.Response('unexpected ${request.url}', 500);
      });
      final client = testEmbyClient(handler: requests.handle);
      addTearDown(client.close);

      final extras = await client.fetchPlaybackExtras('item-1');

      expect(
        requests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        ['GET /Users/user-1/Items/item-1'],
        reason: requests.log.join('\n'),
      );
      expect(requests.requests.where((request) => request.url.path == '/MediaSegments/item-1'), isEmpty);
      expect(extras.markers.map((marker) => marker.type).toList(), ['intro', 'credits']);
      expect(extras.markers.first.startTimeOffset, 10000);
      expect(extras.markers.first.endTimeOffset, 45000);
      expect(extras.markers.last.startTimeOffset, 90000);
      expect(extras.markers.last.endTimeOffset, 120000);
    });

    test('Jellyfin keeps requesting native media segments for playback markers', () async {
      final requests = _RequestCapture((request) {
        if (request.url.path == '/Users/user-1/Items/item-1') {
          return jsonResponse(_chapterItem(chapters: const []));
        }
        if (request.url.path == '/MediaSegments/item-1') {
          return jsonResponse({
            'Items': [
              {'Type': 'Intro', 'StartTicks': 50000000, 'EndTicks': 450000000},
            ],
          });
        }
        return http.Response('unexpected ${request.url}', 500);
      });
      final client = testJellyfinClient(handler: requests.handle);
      addTearDown(client.close);

      final extras = await client.fetchPlaybackExtras('item-1');

      expect(
        requests.requests.map((request) => '${request.method} ${request.url.path}').toList(),
        ['GET /Users/user-1/Items/item-1', 'GET /MediaSegments/item-1'],
        reason: requests.log.join('\n'),
      );
      expect(requests.requests.last.url.query, isEmpty);
      expect(extras.markers.map((marker) => marker.type).toList(), ['intro']);
      expect(extras.markers.single.startTimeOffset, 5000);
      expect(extras.markers.single.endTimeOffset, 45000);
    });

    test('Emby and Jellyfin both expose scrub thumbnails without network traffic', () {
      final embyRequests = _RequestCapture((_) => http.Response('unexpected', 500));
      final jellyfinRequests = _RequestCapture((_) => http.Response('unexpected', 500));
      final emby = testEmbyClient(handler: embyRequests.handle);
      final jellyfin = testJellyfinClient(handler: jellyfinRequests.handle);
      addTearDown(emby.close);
      addTearDown(jellyfin.close);

      // Reading the capability is pure metadata — Emby previews ride the BIF
      // transport now, but neither dialect touches the network to say so.
      expect(emby.capabilities.scrubThumbnails, isTrue);
      expect(jellyfin.capabilities.scrubThumbnails, isTrue);
      expect(embyRequests.log, isEmpty);
      expect(jellyfinRequests.log, isEmpty);
    });
  });

  group('MediaBrowser artwork upload', () {
    // Both dialects reject a raw binary body with HTTP 500 — Emby 4.9.5 says
    // `The input is not a valid Base-64 string`, Jellyfin 10.11 answers a bare
    // `Error processing request.` — and both accept the base64 form with 204.
    for (final (label, build)
        in <(String, JellyfinClient Function({Future<http.Response> Function(http.Request)? handler}))>[
          ('Emby', testEmbyClient),
          ('Jellyfin', testJellyfinClient),
        ]) {
      test('$label receives artwork as base64 text, not raw bytes', () async {
        final requests = _RequestCapture((_) => http.Response('', 204));
        final client = build(handler: requests.handle);
        addTearDown(client.close);

        const bytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
        final ok = await client.uploadItemImage(
          'item-1',
          imageType: 'Primary',
          bytes: bytes,
          contentType: 'image/jpeg',
        );

        expect(ok, isTrue);
        expect(requests.log, ['POST /Items/item-1/Images/Primary?']);
        final sent = requests.requests.single;
        expect(sent.body, base64Encode(bytes));
        // The capture keeps method/url/body; the Content-Type header shape is
        // asserted by the live path, not reachable through this record.
        // The decoded payload must still be the original image.
        expect(base64Decode(sent.body), bytes);
      });
    }
  });

  group('Emby scrub preview BIF transport', () {
    final mediaInfo = MediaSourceInfo(
      videoUrl: '',
      audioTracks: <MediaAudioTrack>[],
      subtitleTracks: <MediaSubtitleTrack>[],
      chapters: <MediaChapter>[],
    );
    test('fetches /Videos/{id}/index.bif?Width=320 and parses Roku BIF bytes', () async {
      final bif = _bifWith(imageBytes: const [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0xFF, 0xD9]);
      late http.Request sent;
      final client = testEmbyClient(
        handler: (request) async {
          sent = request;
          return http.Response.bytes(bif, 200);
        },
      );
      addTearDown(client.close);

      final service = await client.createScrubPreviewSource(item: _item(MediaBackend.emby), mediaSource: mediaInfo);
      addTearDown(() => service?.dispose());

      expect(service, isA<BifThumbnailService>());
      expect(service!.isAvailable, isTrue);
      expect(service.getFrame(Duration.zero), isNotNull);

      expect(sent.method, 'GET');
      expect(sent.url.path, '/Videos/item-1/index.bif');
      expect(sent.url.queryParameters, {'Width': '320'});
      // Auth rides the MediaBrowser headers, not a query token.
      expect(sent.url.queryParameters.containsKey('api_key'), isFalse);
      expect(sent.headers['X-Emby-Token'], 'token');
    });

    test('a header-only BIF (extraction never ran) keeps the service unavailable', () async {
      // Emby's measured 4.9.5 answer for an item without previews: 72 bytes,
      // valid magic, zero frames.
      final client = testEmbyClient(handler: (_) async => http.Response.bytes(_bifWith(imageBytes: const []), 200));
      addTearDown(client.close);

      final service = await client.createScrubPreviewSource(item: _item(MediaBackend.emby), mediaSource: mediaInfo);
      addTearDown(() => service?.dispose());

      expect(service, isA<BifThumbnailService>());
      expect(service!.isAvailable, isFalse);
      expect(service.getFrame(Duration.zero), isNull);
    });

    test('a failed download leaves the service unavailable without throwing', () async {
      final client = testEmbyClient(handler: (_) async => http.Response('', 404));
      addTearDown(client.close);

      final service = await client.createScrubPreviewSource(item: _item(MediaBackend.emby), mediaSource: mediaInfo);
      addTearDown(() => service?.dispose());

      expect(service, isA<BifThumbnailService>());
      expect(service!.isAvailable, isFalse);
    });
  });
}

/// Minimal Roku BIF: 64-byte header, one index entry and sentinel, then
/// [imageBytes] as the (optional) single frame. Timestamps are milliseconds.
Uint8List _bifWith({required List<int> imageBytes}) {
  final imageCount = imageBytes.isEmpty ? 0 : 1;
  final indexBytes = (imageCount + 1) * 8;
  final buf = Uint8List(64 + indexBytes + imageBytes.length);
  final view = ByteData.sublistView(buf);
  const magic = [0x89, 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < magic.length; i++) {
    buf[i] = magic[i];
  }
  view.setUint32(12, imageCount, Endian.little);
  view.setUint32(16, 1000, Endian.little);
  if (imageCount > 0) {
    view.setUint32(64, 0, Endian.little);
    view.setUint32(68, 64 + indexBytes, Endian.little);
  }
  // Sentinel entry: timestamp 0xFFFFFFFF, offset = end of data.
  view.setUint32(64 + imageCount * 8, 0xFFFFFFFF, Endian.little);
  view.setUint32(64 + imageCount * 8 + 4, 64 + indexBytes + imageBytes.length, Endian.little);
  buf.setRange(64 + indexBytes, 64 + indexBytes + imageBytes.length, imageBytes);
  return buf;
}
