import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: ServerId('server-id'), handler: handler);

  test('void mutations surface non-success responses', () async {
    final client = makeClient((_) async => http.Response('rejected', 500));
    addTearDown(client.close);

    for (final mutation in <Future<void> Function()>[
      () => client.cancelActivity('activity-id'),
      () => client.removeFromOnDeck('item-id'),
      () => client.emptyLibraryTrash('library-id'),
    ]) {
      await expectLater(mutation(), throwsA(isA<MediaServerHttpException>()));
    }
  });

  test('nullable creation APIs reject non-success response bodies', () async {
    final client = makeClient((_) async => http.Response('rejected', 500));
    addTearDown(client.close);

    expect(await client.createCollectionFromUri(sectionId: '1', title: 'Collection', uri: 'server://items'), isNull);
    expect(await client.createPlayQueue(uri: 'server://items', type: 'video'), isNull);
  });

  test('play queue accepts numeric strings from Plex', () async {
    final client = makeClient(
      (_) async => http.Response(
        jsonEncode({
          'MediaContainer': {
            'playQueueID': '42',
            'playQueueSelectedItemID': '7',
            'playQueueSelectedItemOffset': '1',
            'playQueueTotalCount': '3',
            'playQueueVersion': '5',
            'size': '3',
            'Metadata': <dynamic>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final queue = await client.createPlayQueue(uri: 'server://items', type: 'video');

    expect(queue?.playQueueID, 42);
    expect(queue?.playQueueSelectedItemID, 7);
    expect(queue?.playQueueSelectedItemOffset, 1);
    expect(queue?.playQueueTotalCount, 3);
    expect(queue?.playQueueVersion, 5);
    expect(queue?.size, 3);
  });

  test('activities tolerate scalar drift and skip only malformed rows', () async {
    final client = makeClient(
      (_) async => http.Response(
        jsonEncode({
          'MediaContainer': {
            'Activity': [
              {
                'uuid': 'activity-1',
                'type': 'library.update',
                'title': 'Scanning',
                'subtitle': 'Movies',
                'progress': 25,
                'cancellable': false,
              },
              'not-an-activity',
              {'type': 'library.update', 'title': 'Missing identity'},
              {'uuid': 42, 'type': 7, 'title': true, 'subtitle': 99, 'progress': '75', 'cancellable': '1'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final activities = await client.getActivities();

    expect(activities, hasLength(2));
    expect(activities.first.uuid, 'activity-1');
    expect(activities.first.progress, 25);
    expect(activities.first.cancellable, isFalse);
    expect(activities.last.uuid, '42');
    expect(activities.last.type, '7');
    expect(activities.last.title, 'true');
    expect(activities.last.subtitle, '99');
    expect(activities.last.progress, 75);
    expect(activities.last.cancellable, isTrue);
  });

  test('metadata edit preserves locked fields and removed tag wire format', () async {
    http.Request? captured;
    final client = makeClient((request) async {
      captured = request;
      return http.Response('', 200);
    });
    addTearDown(client.close);

    final updated = await client.updateMetadata(
      sectionId: 1,
      ratingKey: 'item-id',
      typeNumber: 1,
      title: 'Renamed',
      tagChanges: {
        'genre': (current: ['Drama'], original: ['Drama', 'Science Fiction']),
      },
    );

    expect(updated, isTrue);
    expect(captured?.method, 'PUT');
    expect(captured?.url.path, '/library/sections/1/all');
    expect(captured?.url.queryParameters, containsPair('title.value', 'Renamed'));
    expect(captured?.url.queryParameters, containsPair('title.locked', '1'));
    expect(captured?.url.queryParameters, containsPair('genre[0].tag.tag', 'Drama'));
    expect(captured?.url.queryParameters, containsPair('genre[].tag.tag-', 'Science%20Fiction'));
    expect(captured?.url.queryParameters, containsPair('genre.locked', '1'));
  });

  test('cached child fetch rejects decodable HTTP error responses before caching', () async {
    for (final statusCode in [404, 500]) {
      final parentId = 'parent-$statusCode';
      final endpoint = '/library/metadata/$parentId/children';
      var requestCount = 0;
      final client = makeClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 1,
              'Metadata': [
                {'ratingKey': 'error-child', 'type': 'season', 'title': 'Must Not Parse'},
              ],
            },
          }),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      await expectLater(
        client.fetchChildren(parentId),
        throwsA(
          isA<MediaServerHttpException>()
              .having((error) => error.statusCode, 'statusCode', statusCode)
              .having((error) => error.requestUri?.path, 'request path', endpoint),
        ),
      );

      expect(requestCount, 1);
      expect(await PlexApiCache.instance.get(ServerId('server-id'), endpoint), isNull);
    }
  });

  test('HTTP failure falls back to the existing child cache without replacing it', () async {
    const parentId = 'cached-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final cachedResponse = {
      'MediaContainer': {
        'size': 1,
        'totalSize': 1,
        'Metadata': [
          {'ratingKey': 'cached-child', 'type': 'season', 'title': 'Cached Season'},
        ],
      },
    };
    await PlexApiCache.instance.put(ServerId('server-id'), endpoint, cachedResponse);
    var requestCount = 0;
    final client = makeClient((request) async {
      requestCount++;
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'size': 1,
            'totalSize': 1,
            'Metadata': [
              {'ratingKey': 'error-child', 'type': 'season', 'title': 'Must Not Replace Cache'},
            ],
          },
        }),
        500,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);

    expect(requestCount, 1);
    expect(children.map((child) => child.id), ['cached-child']);
    expect(children.single.title, 'Cached Season');
    expect(await PlexApiCache.instance.get(ServerId('server-id'), endpoint), cachedResponse);
  });

  test('successful child fetch parses and caches the response', () async {
    const parentId = 'fresh-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final responseData = {
      'MediaContainer': {
        'size': 1,
        'totalSize': 1,
        'Metadata': [
          {'ratingKey': 'fresh-child', 'type': 'season', 'title': 'Fresh Season'},
        ],
      },
    };
    var requestCount = 0;
    final client = makeClient((request) async {
      requestCount++;
      return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);

    expect(requestCount, 1);
    expect(children.map((child) => child.id), ['fresh-child']);
    expect(children.single.title, 'Fresh Season');
    expect(await PlexApiCache.instance.get(ServerId('server-id'), endpoint), responseData);
  });

  test('child retrieval walks every page and caches the combined result', () async {
    const parentId = 'paged-parent';
    const endpoint = '/library/metadata/$parentId/children';
    final requests = <Uri>[];
    final client = makeClient((request) async {
      requests.add(request.url);
      final start = int.parse(request.url.queryParameters['X-Plex-Container-Start']!);
      final metadata = start == 0
          ? [
              {'ratingKey': 'season-1', 'type': 'season', 'title': 'Season 1'},
              {'ratingKey': 'season-2', 'type': 'season', 'title': 'Season 2'},
            ]
          : [
              {'ratingKey': 'season-3', 'type': 'season', 'title': 'Season 3'},
            ];
      return http.Response(
        jsonEncode({
          'MediaContainer': {'size': metadata.length, 'totalSize': 3, 'Metadata': metadata},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final children = await client.fetchChildren(parentId);
    final cached = await PlexApiCache.instance.get(ServerId('server-id'), endpoint);
    final cachedContainer = cached!['MediaContainer'] as Map<String, dynamic>;
    final cachedMetadata = cachedContainer['Metadata'] as List<dynamic>;

    expect(children.map((child) => child.id), ['season-1', 'season-2', 'season-3']);
    expect(requests.map((uri) => uri.queryParameters['X-Plex-Container-Start']), ['0', '2']);
    expect(requests.every((uri) => uri.queryParameters['X-Plex-Container-Size'] == '200'), isTrue);
    expect(requests.every((uri) => uri.queryParameters['includeStreams'] == '1'), isTrue);
    expect(cachedContainer['size'], 3);
    expect(cachedContainer['totalSize'], 3);
    expect(cachedMetadata.map((item) => (item as Map<String, dynamic>)['ratingKey']), [
      'season-1',
      'season-2',
      'season-3',
    ]);
  });
}
