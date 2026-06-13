import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/models/plex/plex_config.dart';
import 'package:vibe_stream/services/plex_api_cache.dart';
import 'package:vibe_stream/services/plex_auth_service.dart';
import 'package:vibe_stream/services/plex_client.dart';
import 'package:vibe_stream/services/multi_server_manager.dart';

void main() {
  // refreshTokensForProfile starts connectivity monitoring after a successful
  // bind, which touches platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshTokensForProfile emits per-server progress and a single status snapshot', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    addTearDown(db.close);

    final manager = MultiServerManager();
    addTearDown(manager.dispose);

    PlexClient buildClient(String serverId) => PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'http://$serverId:32400',
        token: 'old-token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
      ),
      serverId: ServerId(serverId),
      serverName: serverId,
      httpClient: MockClient((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'})),
    );

    // Both servers already registered and online — refreshTokensForProfile
    // takes the in-place token-rotation fast path for them.
    manager.debugRegisterClientForTesting(buildClient('srv-1'));
    manager.debugRegisterClientForTesting(buildClient('srv-2'));

    final progress = <({String serverId, bool online})>[];
    final statusEmissions = <Map<String, bool>>[];
    final progressSub = manager.connectProgressStream.listen(progress.add);
    final statusSub = manager.statusStream.listen(statusEmissions.add);
    addTearDown(progressSub.cancel);
    addTearDown(statusSub.cancel);

    final connection = PlexAccountConnection(
      id: 'plex.account',
      accountToken: 'account-token',
      clientIdentifier: 'client-id',
      accountLabel: 'Owner',
      servers: [_server('srv-1'), _server('srv-2')],
      createdAt: DateTime(2026, 1, 1),
    );

    final bound = await manager.refreshTokensForProfile(connection);
    // Let the broadcast stream deliver its pending events.
    await Future<void>.delayed(Duration.zero);

    expect(bound, {'srv-1', 'srv-2'});
    // One progress event per server, as each settles…
    expect(progress.map((p) => p.serverId).toSet(), {'srv-1', 'srv-2'});
    expect(progress.every((p) => p.online), isTrue);
    // …but the status snapshot keeps its one-emission-per-pass contract
    // (OfflineModeProvider treats the first emission as "first connect
    // pass finished").
    expect(statusEmissions, hasLength(1));
  });
}

PlexServer _server(String id) {
  return PlexServer(
    name: id,
    clientIdentifier: id,
    accessToken: 'new-token',
    connections: [
      PlexConnection(
        protocol: 'http',
        address: '192.168.1.10',
        port: 32400,
        uri: 'http://192.168.1.10:32400',
        local: true,
        relay: false,
        ipv6: false,
      ),
    ],
    owned: true,
    presence: true,
  );
}
