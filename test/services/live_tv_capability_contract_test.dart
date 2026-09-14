import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/multi_server_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  PlexClient plexClient(http.Client httpClient) => testPlexClient(
    config: testPlexConfig(token: 'plex-token', clientIdentifier: 'plex-device', machineIdentifier: 'plex-machine'),
    serverId: ServerId('plex-machine'),
    httpClient: httpClient,
  );

  JellyfinClient jellyfinClient(http.Client httpClient) => testJellyfinClient(
    connection: testJellyfinConnection(
      machineId: 'jellyfin-machine',
      userId: 'user-1',
      baseUrl: 'https://jellyfin.example.com',
      serverName: 'Jellyfin',
      accessToken: 'jellyfin-token',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    httpClient: httpClient,
  );

  http.Response jsonResponse(Map<String, dynamic> body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  test('Plex exposes one centralized Live TV DVR adapter', () async {
    final requests = <Uri>[];
    final client = plexClient(
      MockClient((request) async {
        requests.add(request.url);
        return jsonResponse({
          'MediaContainer': {
            'Dvr': [
              {'key': 'dvr-1', 'uuid': 'dvr-1'},
            ],
          },
        });
      }),
    );
    addTearDown(client.close);

    expect(client.capabilities.liveTvDvr, isTrue);
    expect(client.liveTv.dvr, same(client));
    expect(client.liveTvDvr, same(client));
    expect((await client.liveTvDvr!.fetchDvrs()).single.key, 'dvr-1');
    expect(requests.single.path, '/livetv/dvrs');
  });

  test('Jellyfin exposes a DVR adapter that preserves the synthesized server identity', () async {
    final client = jellyfinClient(MockClient((_) async => fail('DVR adapter access must not issue a request')));
    addTearDown(client.close);

    expect(client.capabilities.liveTv, isTrue);
    expect(client.capabilities.liveTvDvr, isTrue);
    final dvr = client.liveTvDvr;
    expect(dvr, isNotNull);
    // No Plex-style rule re-evaluation on MediaBrowser; the bolt action hides.
    expect(dvr!.supportsRuleProcessing, isFalse);
    // Empty on purpose: a non-empty list would replace the synthesized
    // `dvrKey: backend.id` identity that channels/favorites/playback key off.
    expect(await dvr.fetchDvrs(), isEmpty);
  });

  test('availability call site gates DVR requests and still includes Jellyfin', () async {
    final plexRequests = <Uri>[];
    final plex = plexClient(
      MockClient((request) async {
        plexRequests.add(request.url);
        if (request.url.path != '/livetv/dvrs') fail('Unexpected Plex request: ${request.url}');
        return jsonResponse({
          'MediaContainer': {
            'Dvr': [
              {'key': 'dvr-1', 'uuid': 'dvr-1'},
            ],
          },
        });
      }),
    );
    final jellyfinRequests = <Uri>[];
    final jellyfin = jellyfinClient(
      MockClient((request) async {
        jellyfinRequests.add(request.url);
        if (request.url.path != '/LiveTv/Channels') fail('Jellyfin DVR endpoint was not gated: ${request.url}');
        return jsonResponse({'TotalRecordCount': 1, 'Items': const []});
      }),
    );
    final manager = MultiServerManager();
    manager.debugRegisterClientForTesting(plex);
    manager.debugRegisterJellyfinClientForTesting(jellyfin);
    final provider = testMultiServerProvider(manager);
    addTearDown(() {
      provider.dispose();
      manager.dispose();
    });

    await provider.checkLiveTvAvailability();

    expect(plexRequests.map((uri) => uri.path), ['/livetv/dvrs']);
    expect(jellyfinRequests.map((uri) => uri.path), ['/LiveTv/Channels']);
    expect(
      provider.liveTvServers.map((server) => (server.serverId, server.dvrKey)),
      containsAll([('plex-machine', 'dvr-1'), ('jellyfin-machine', 'jellyfin')]),
    );
  });
}
