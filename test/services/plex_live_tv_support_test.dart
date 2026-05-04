import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(
    Future<http.Response> Function(http.Request request) handler, {
    String token = 'tok',
    String clientIdentifier = 'client',
    List<({String identifier, String gridEndpoint})> epgProviders = const [
      (identifier: 'provider-a', gridEndpoint: '/provider-a/grid'),
    ],
  }) {
    return PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: token,
        clientIdentifier: clientIdentifier,
        product: 'Plezy',
        version: '1',
        machineIdentifier: 'machine-1',
      ),
      serverId: 'machine-1',
      httpClient: MockClient(handler),
      epgProviders: epgProviders,
    );
  }

  http.Response jsonResponse(Map<String, dynamic> body, {Map<String, String>? headers}) {
    return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json', ...?headers});
  }

  test('favorite source follows requested lineup provider', () async {
    final client = makeClient(
      (_) async => http.Response('{}', 200),
      epgProviders: const [
        (identifier: 'provider-a', gridEndpoint: '/provider-a/grid'),
        (identifier: 'provider-b', gridEndpoint: '/provider-b/grid'),
      ],
    );
    addTearDown(client.close);

    expect(await client.liveTv.buildFavoriteChannelSource(lineup: 'provider-b'), 'server://machine-1/provider-b');
  });

  test('favorite store is account device scoped instead of token scoped', () {
    final a = makeClient(
      (_) async => http.Response('{}', 200),
      token: 'server-token-a',
      clientIdentifier: 'account-device',
    );
    final b = makeClient(
      (_) async => http.Response('{}', 200),
      token: 'server-token-b',
      clientIdentifier: 'account-device',
    );
    addTearDown(a.close);
    addTearDown(b.close);

    expect(a.liveTv.favoriteStoreKey, b.liveTv.favoriteStoreKey);
  });

  test('DVR list applies root channel mapping to each DVR and parses string numbers', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/livetv/dvrs');
      return jsonResponse({
        'MediaContainer': {
          'Dvr': [
            {'key': '1', 'uuid': 'dvr-1', 'tuners': '2', 'status': '1'},
          ],
          'ChannelMapping': [
            {'channelKey': 'ch-1', 'enabled': '1', 'lineupIdentifier': '001'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final dvrs = await client.liveTv.fetchDvrs();

    expect(dvrs, hasLength(1));
    expect(dvrs.single.tuners, 2);
    expect(dvrs.single.status, 1);
    expect(dvrs.single.channelMappings.single.channelKey, 'ch-1');
    expect(dvrs.single.channelMappings.single.enabled, isTrue);
  });

  test('createDvr sends repeated device and lineup query params and exposes activity id', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse(
        {
          'MediaContainer': {
            'Dvr': [
              {'key': '42', 'uuid': 'dvr-42'},
            ],
          },
        },
        headers: {'x-plex-activity': 'activity-1'},
      );
    });
    addTearDown(client.close);

    final result = await client.liveTv.createDvr(
      devices: const ['dev-a', 'dev-b'],
      lineups: const ['lineup-a', 'lineup-b'],
      language: 'eng',
    );

    expect(captured.url.path, '/livetv/dvrs');
    expect(captured.url.queryParametersAll['device'], ['dev-a', 'dev-b']);
    expect(captured.url.queryParametersAll['lineup'], ['lineup-a', 'lineup-b']);
    expect(captured.url.queryParameters['language'], 'eng');
    expect(result.activityUuid, 'activity-1');
    expect(result.value?.key, '42');
  });

  test('subscription template parses settings and URL-encoded enum labels', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/media/subscriptions/template');
      expect(request.url.queryParameters['guid'], 'plex://episode/1');
      return jsonResponse({
        'MediaContainer': {
          'SubscriptionTemplate': [
            {
              'MediaSubscription': [
                {
                  'key': '',
                  'type': 4,
                  'selected': '1',
                  'title': 'This Episode',
                  'parameters': 'hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1',
                  'Setting': [
                    {'id': 'startTimeslot', 'type': 'int', 'value': '-1', 'enumValues': ':Any|1715319000:12%3A30%20AM'},
                  ],
                },
              ],
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final templates = await client.liveTv.getSubscriptionTemplate('plex://episode/1');

    final subscription = templates.single.subscriptions.single;
    expect(subscription.selected, isTrue);
    expect(subscription.parameters, contains('hints%5Bguid%5D'));
    expect(subscription.settings.single.options.map((o) => o.label), ['Any', '12:30 AM']);
  });

  test('createRecordingRule preserves template parameters and all prefs as query params', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {'key': '18', 'type': 4, 'title': 'Episode'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final request = MediaSubscriptionCreateRequest.fromTemplate(
      const MediaSubscription(
        key: '',
        targetLibrarySectionID: 2,
        type: 4,
        parameters: 'hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1',
        settings: [
          SubscriptionSetting(id: 'oneShot', value: 'true', defaultValue: 'false', hidden: true),
          SubscriptionSetting(id: 'remoteMedia', value: 'false', defaultValue: 'false', hidden: true),
          SubscriptionSetting(id: 'startOffsetMinutes', value: '0', defaultValue: '0'),
        ],
      ),
      prefs: const {'startOffsetMinutes': 5},
    );

    final created = await client.liveTv.createRecordingRule(request);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/media/subscriptions');
    expect(captured.body, isEmpty);
    expect(captured.headers.containsKey('content-type'), isFalse);
    expect(captured.url.queryParameters['hints[guid]'], 'plex://episode/1');
    expect(captured.url.queryParameters['targetLibrarySectionID'], '2');
    expect(captured.url.queryParameters['type'], '4');
    expect(captured.url.queryParameters['prefs[oneShot]'], 'true');
    expect(captured.url.queryParameters['prefs[remoteMedia]'], 'false');
    expect(captured.url.queryParameters['prefs[startOffsetMinutes]'], '5');
    expect(created?.key, '18');
  });

  test('updateRecordingRule sends prefs as query params', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {'key': '18', 'type': 4, 'title': 'Episode'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final updated = await client.liveTv.updateRecordingRule('18', const {'startOffsetMinutes': 5});

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/media/subscriptions/18');
    expect(captured.body, isEmpty);
    expect(captured.url.queryParameters['prefs[startOffsetMinutes]'], '5');
    expect(updated?.key, '18');
  });

  test('cancelGrab deletes the operation key path', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({'MediaContainer': <String, dynamic>{}});
    });
    addTearDown(client.close);

    await client.liveTv.cancelGrab('/media/grabbers/operations/grab-1');

    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/media/grabbers/operations/grab-1');
  });

  test('scheduled recordings parse grab operation metadata', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/media/subscriptions/scheduled');
      return jsonResponse({
        'MediaContainer': {
          'MediaGrabOperation': [
            {
              'id': 'grab-1',
              'key': '/media/grabbers/operations/grab-1',
              'mediaSubscriptionID': '7',
              'status': 'scheduled',
              'percent': '42.5',
              'Metadata': {
                'title': 'Miracle on Dead Street',
                'grandparentTitle': 'Fresh Off the Boat',
                'type': 'episode',
                'Media': [
                  {'beginsAt': '1466060400', 'endsAt': '1466062200', 'channelIdentifier': '004'},
                ],
              },
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final operations = await client.liveTv.fetchScheduledRecordings();

    expect(operations.single.id, 'grab-1');
    expect(operations.single.operationKey, '/media/grabbers/operations/grab-1');
    expect(operations.single.mediaSubscriptionID, 7);
    expect(operations.single.percent, 42.5);
    expect(operations.single.program?.grandparentTitle, 'Fresh Off the Boat');
    expect(operations.single.program?.channelIdentifier, '004');
  });
}
