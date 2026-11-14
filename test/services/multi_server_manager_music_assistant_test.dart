import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant_client.dart';

import '../music_assistant/fake_ma_server.dart';

/// The greeting id every [FakeMaServer] announces.
const _greetingServerId = 'fe2f5b6fd78e4608bb8b075a6c269fbf';

MusicAssistantConnection connection({
  String id = 'ma-row',
  String baseUrl = 'http://10.0.2.107:8095',
  String? serverId,
  String? accessToken,
}) => MusicAssistantConnection(
  id: id,
  displayName: 'Basement NAS',
  baseUrl: baseUrl,
  serverId: serverId,
  accessToken: accessToken,
  createdAt: DateTime.utc(2026),
);

void main() {
  /// A manager whose Music Assistant clients are backed by in-memory servers.
  /// [servers] collects them in creation order.
  ({MultiServerManager manager, List<FakeMaServer> servers}) managerWithFakeServers({bool reachable = true}) {
    final servers = <FakeMaServer>[];
    final manager = MultiServerManager(
      connectivityChanges: Stream<List<dynamic>>.empty().cast,
      musicAssistantClientFactory: (conn) async {
        final server = FakeMaServer();
        servers.add(server);
        return MusicAssistantClient.create(
          conn,
          api: MusicAssistantApi(
            channelFactory: reachable ? server.open : (_) async => throw const MaConnectionException('refused'),
            handshakeTimeout: const Duration(milliseconds: 200),
            autoReconnect: false,
          ),
        );
      },
    );
    return (manager: manager, servers: servers);
  }

  group('addMusicAssistantConnection', () {
    test('registers under the greeting server id, not the connection row id', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);

      final added = await harness.manager.addMusicAssistantConnection(connection());

      expect(added, isTrue);
      // The row id is only a placeholder until a handshake reveals the real id.
      expect(harness.manager.serverIds, [_greetingServerId]);
      expect(harness.manager.getClient(ServerId(_greetingServerId)), isA<MusicAssistantClient>());
      expect(harness.manager.isServerOnline(ServerId(_greetingServerId)), isTrue);
      expect(harness.manager.musicAssistantServerIdFor('ma-row'), _greetingServerId);
    });

    test('is a way to reach speakers, never a library', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);

      await harness.manager.addMusicAssistantConnection(connection());
      final id = ServerId(_greetingServerId);

      expect(harness.manager.isOutputOnly(id), isTrue);
      expect(harness.manager.isServerVisible(id), isFalse, reason: 'libraries, home and search filter on this');
      expect(harness.manager.onlineHandles(), isEmpty, reason: 'cross-server fan-outs must not reach it either');
      expect(harness.manager.getClient(id), isA<MusicAssistantClient>(), reason: 'the speaker picker still needs it');
    });

    test('persists the identity only the greeting reveals', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);
      final persisted = <MusicAssistantConnection>[];
      harness.manager.onMusicAssistantConnectionUpdated = persisted.add;

      await harness.manager.addMusicAssistantConnection(connection());

      // Without this the binder's expected-server set — computed before any
      // socket exists — would never contain the id actually registered.
      expect(persisted.single.serverId, _greetingServerId);
      expect(persisted.single.serverVersion, '2.6.3');
    });

    test('an unreachable server is registered offline rather than dropped', () async {
      final harness = managerWithFakeServers(reachable: false);
      addTearDown(harness.manager.dispose);

      final added = await harness.manager.addMusicAssistantConnection(connection(serverId: 'stored-id'));

      expect(added, isFalse);
      // Still registered, so the UI can show it greyed out and retry, exactly
      // as an unhealthy Jellyfin server is.
      expect(harness.manager.serverIds, ['stored-id']);
      expect(harness.manager.isServerOnline(ServerId('stored-id')), isFalse);
    });

    test('re-adding an unchanged connection keeps the live socket', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);

      await harness.manager.addMusicAssistantConnection(connection());
      final first = harness.manager.getClient(ServerId(_greetingServerId));
      await harness.manager.addMusicAssistantConnection(connection());

      expect(harness.servers, hasLength(1), reason: 'no second client was built');
      expect(harness.manager.getClient(ServerId(_greetingServerId)), same(first));
    });

    test('concurrent adds of the same connection build one client, not two', () async {
      // Startup rebinds twice. When both calls raced, each built a client, the
      // second replaced the first, and closing the first left every consumer
      // still holding it failing with "Client disposed" — surfaced to the user
      // as being unable to connect to the media server.
      final (:manager, :servers) = managerWithFakeServers();
      addTearDown(manager.dispose);

      final results = await Future.wait([
        manager.addMusicAssistantConnection(connection()),
        manager.addMusicAssistantConnection(connection()),
        manager.addMusicAssistantConnection(connection()),
      ]);

      expect(results, everyElement(isTrue));
      expect(servers, hasLength(1), reason: 'three concurrent adds must not build three sockets');

      final client = manager.getClient(ServerId(_greetingServerId));
      expect(client, isNotNull);
      expect(
        await (client! as MusicAssistantClient).checkHealth(),
        HealthStatus.online,
        reason: 'the surviving client must not have been disposed by a racing add',
      );
    });

    test('onlineHandles covers the servers that are bound, not merely marked online', () async {
      // Membership has to match `onlineClients`. A server marked online with no
      // client yet would enter a fan-out and come back permanently unbound,
      // which callers read as a disruption to retry — a skeleton that never
      // resolves and never errors, in place of a visible failure.
      final (:manager, :servers) = managerWithFakeServers();
      addTearDown(manager.dispose);
      await manager.addMusicAssistantConnection(connection());

      // The fixture must contain a server that is online but *not* bound,
      // otherwise `onlineServerIds` and `onlineClients.keys` are the same set
      // and the assertion passes against either — which is what a mutation
      // test showed the first version of this doing.
      manager.debugMarkServerOnlineForTesting('phantom');
      expect(manager.onlineServerIds, contains('phantom'));
      expect(manager.onlineClients.keys, isNot(contains('phantom')));

      expect(
        manager.onlineHandles().keys,
        isNot(contains('phantom')),
        reason:
            'a server with no client would come back permanently unbound, '
            'which callers read as a disruption to retry — a skeleton that never resolves',
      );
      expect(
        manager.onlineHandles().keys,
        manager.onlineClients.keys.where((id) => !manager.isOutputOnly(ServerId(id))),
      );
      // Bound and online, but only ever a way to reach speakers.
      expect(manager.onlineHandles({_greetingServerId}), isEmpty);
      expect(manager.onlineHandles(<String>{'someone-else'}), isEmpty);
    });

    test('a handle follows the client through a rebuild', () async {
      final (:manager, :servers) = managerWithFakeServers();
      addTearDown(manager.dispose);
      await manager.addMusicAssistantConnection(connection());

      final handle = manager.handleFor(_greetingServerId);
      final before = handle.client;
      expect(before, isNotNull);

      // A changed base URL is the one thing that forces a fresh socket.
      await manager.addMusicAssistantConnection(connection(baseUrl: 'http://10.0.2.108:8095'));

      expect(servers, hasLength(2), reason: 'the URL change should have built a second socket');
      expect(handle.client, isNotNull);
      expect(handle.client, isNot(same(before)), reason: 'the handle must resolve the replacement, not the corpse');
    });

    test('a changed URL rebuilds the client', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);

      await harness.manager.addMusicAssistantConnection(connection());
      final first = harness.manager.getClient(ServerId(_greetingServerId));
      await harness.manager.addMusicAssistantConnection(connection(baseUrl: 'http://10.0.2.200:8095'));

      // The socket URL, the image proxy and the flow stream are all derived
      // from baseUrl, so it cannot be swapped in place.
      expect(harness.servers, hasLength(2));
      expect(harness.manager.getClient(ServerId(_greetingServerId)), isNot(same(first)));
    });

    test('a connection that finally handshakes releases its placeholder id', () async {
      // One manager, one connection row, reachability flipping underneath it —
      // which is the real sequence. An earlier version of this test built a
      // second manager for the reachable half, so it exercised the fresh-add
      // path and never the reuse path that this scenario actually takes: the
      // connection is unchanged (same baseUrl, same token), so the re-add is a
      // reuse, and it was the reuse path that leaked the placeholder key.
      var reachable = false;
      final servers = <FakeMaServer>[];
      final manager = MultiServerManager(
        connectivityChanges: Stream<List<dynamic>>.empty().cast,
        musicAssistantClientFactory: (conn) async {
          final server = FakeMaServer();
          servers.add(server);
          return MusicAssistantClient.create(
            conn,
            api: MusicAssistantApi(
              channelFactory: reachable ? server.open : (_) async => throw const MaConnectionException('refused'),
              handshakeTimeout: const Duration(milliseconds: 200),
              autoReconnect: false,
            ),
          );
        },
      );
      addTearDown(manager.dispose);

      final conn = connection(serverId: 'placeholder');
      await manager.addMusicAssistantConnection(conn);
      expect(manager.serverIds, ['placeholder'], reason: 'registered under the row id while unreachable');

      // The server comes back. The connection row did not change, so this is a
      // reuse — but the client now answers the greeting id instead of the row
      // id, and it must move keys rather than occupy both.
      reachable = true;
      await manager.addMusicAssistantConnection(conn);

      expect(manager.serverIds, [_greetingServerId]);
      expect(manager.musicAssistantServerIdFor('ma-row'), _greetingServerId);
      expect(manager.getClient(ServerId(_greetingServerId)), isA<MusicAssistantClient>());
    });
  });

  group('manual reconnect', () {
    test('rebuilds the socket even while it still claims to be connected', () async {
      // The half-open case, which is the only case a user ever presses the
      // button in: the link died silently, so `onDone`/`onError` never fired,
      // `isConnected` is still true, and nothing can actually travel over the
      // socket. Gating the rebuild on `isConnected` made the button do
      // literally nothing here.
      final opened = <FakeMaServer>[];
      final api = MusicAssistantApi(
        channelFactory: (url) {
          final server = FakeMaServer(responder: (command, args) => command.endsWith('/count') ? 7 : <dynamic>[]);
          opened.add(server);
          return server.open(url);
        },
        handshakeTimeout: const Duration(milliseconds: 200),
        autoReconnect: false,
      );
      final manager = MultiServerManager(
        connectivityChanges: Stream<List<dynamic>>.empty().cast,
        musicAssistantClientFactory: (conn) => MusicAssistantClient.create(conn, api: api),
      );
      addTearDown(manager.dispose);

      await manager.addMusicAssistantConnection(connection());
      expect(opened, hasLength(1));
      expect(api.isConnected, isTrue);

      // Health goes offline without the socket noticing — exactly what a
      // half-open link looks like from the manager's side.
      manager.updateServerStatus(ServerId(_greetingServerId), false);
      expect(manager.offlineServerIds, [_greetingServerId]);

      await manager.reconnectOfflineServers();

      expect(opened, hasLength(2), reason: 'connect() must run regardless of what isConnected says');
      expect(manager.isServerOnline(ServerId(_greetingServerId)), isTrue);
    });

    test('the reconnect task outlives the transport deadlines it waits on', () {
      // The task does a handshake and then a health probe, in series. A budget
      // shorter than either one abandons the probe before it can answer, so the
      // reconnect updates nothing at all and reports success by silence.
      final api = MusicAssistantApi();
      final budget = MultiServerManager.musicAssistantReconnectTimeout(api);

      expect(budget, greaterThan(api.handshakeTimeout + api.requestTimeout));
    });
  });

  group('canReuseMusicAssistantClient', () {
    test('ignores the fields the handshake writes', () {
      // serverId/serverVersion are results of connecting, so comparing them
      // would rebuild the client on every rebind.
      expect(
        MultiServerManager.canReuseMusicAssistantClient(
          live: connection(serverId: _greetingServerId),
          incoming: connection(),
        ),
        isTrue,
      );
    });

    test('rejects a changed token', () {
      expect(
        MultiServerManager.canReuseMusicAssistantClient(
          live: connection(accessToken: 'a'),
          incoming: connection(accessToken: 'b'),
        ),
        isFalse,
      );
    });
  });

  group('removal', () {
    test('removeMusicAssistantConnection drops every registration', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);
      final conn = connection();
      await harness.manager.addMusicAssistantConnection(conn);

      harness.manager.removeMusicAssistantConnection(conn);

      expect(harness.manager.serverIds, isEmpty);
      expect(harness.manager.musicAssistantServerIdFor('ma-row'), isNull);
    });

    test('removal takes the graceful branch, so the socket outlives the unregister', () async {
      // MultiServerManager._closeClientGracefully only awaits ordered teardown
      // for a GracefullyCloseable; everything else gets the fire-and-forget
      // `close()`. MusicAssistantClient was the one of three implementations
      // that did not declare it, so the player was left registered on a server
      // whose socket had already gone — silent, still listed, and only
      // reclaimed minutes later by the server's own timeout.
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);
      final conn = connection();
      await harness.manager.addMusicAssistantConnection(conn);
      final client = harness.manager.getClient(ServerId(_greetingServerId))! as MusicAssistantClient;
      expect(client, isA<GracefullyCloseable>());

      harness.manager.removeMusicAssistantConnection(conn);
      await pumpEventQueue();

      expect(client.api.connectionState, MaConnectionState.disconnected);
    });

    test('the generic removeServer path leaves no stale bookkeeping behind', () async {
      final harness = managerWithFakeServers();
      addTearDown(harness.manager.dispose);
      await harness.manager.addMusicAssistantConnection(connection());

      // The profile binder tears servers down by id, not by connection.
      harness.manager.removeServer(ServerId(_greetingServerId));

      expect(harness.manager.serverIds, isEmpty);
      expect(harness.manager.musicAssistantServerIdFor('ma-row'), isNull);
    });
  });

  test('isOwnerOrAdmin is false: Music Assistant refuses every admin action', () async {
    final harness = managerWithFakeServers();
    addTearDown(harness.manager.dispose);
    await harness.manager.addMusicAssistantConnection(connection());

    expect(harness.manager.isOwnerOrAdmin(ServerId(_greetingServerId)), isFalse);
  });
}
