import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfinConnection(String userId) => JellyfinConnection(
  id: 'jf-machine/$userId',
  baseUrl: 'https://jf.example.com',
  serverName: 'Shared JF',
  serverMachineId: 'jf-machine',
  userId: userId,
  userName: userId,
  accessToken: 'token-$userId',
  deviceId: 'device',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinClient _jellyfinClient(String userId) => JellyfinClient.forTesting(
  connection: _jellyfinConnection(userId),
  httpClient: MockClient((_) async => http.Response('{}', 200)),
);

// NOTE on coverage scope:
// [MultiServerManager.addServer] / `connectToAllServers` / `_createClientForServer`
// all instantiate a real `PlexClient` via `findBestWorkingConnection`, which
// performs live HTTP calls to a Plex Media Server. The manager does NOT expose
// a fake `PlexClient` factory, so per the task brief we don't fake the network
// here.
//
// The tests below cover the orchestration logic that DOESN'T require a network:
//   - construction & initial state
//   - `removeServer` (pure local-map mutation)
//   - `updateServerStatus` + status-stream emissions
//   - `disconnectAll` / `dispose` lifecycle (no connectivity sub started, so
//     this verifies the no-op path for the subscription cancel)
//
// What is NOT covered here (would need a fake PlexClient factory):
//   - `addServer` success path
//   - `connectToAllServers` outcome map
//   - `checkServerHealth` health-probe sweep
//   - `_reoptimizeServer` endpoint promotion
//   - `_onServerEndpointsExhausted` debounce → reconnect
//   - `startNetworkMonitoring` connectivity-listener path

void main() {
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // Initial state
  // ============================================================

  group('initial state', () {
    test('a freshly constructed manager has no servers, clients, or status', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(m.plexServers, isEmpty);
      expect(m.onlineClients, isEmpty);
    });

    test('getClient/getPlexServer return null for unknown ids', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.getClient('nope'), isNull);
      expect(m.getPlexServer('nope'), isNull);
      expect(m.isServerOnline('nope'), isFalse);
    });

    test('plexServers map is unmodifiable', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      // Map.unmodifiable rejects every mutating operation — clear() is the
      // simplest no-arg one to exercise the wrapper.
      expect(() => m.plexServers.clear(), throwsUnsupportedError);
    });
  });

  // ============================================================
  // updateServerStatus + status stream
  // ============================================================

  group('updateServerStatus + statusStream', () {
    test('emits a snapshot when status flips for a tracked server', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      // Pre-seed status (mirrors what addServer would do post-connect).
      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-2', false);
      m.updateServerStatus('srv-1', false); // change

      // Let the broadcast stream events drain.
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(3));
      expect(emitted[0], {'srv-1': true});
      expect(emitted[1], {'srv-1': true, 'srv-2': false});
      expect(emitted[2], {'srv-1': false, 'srv-2': false});
    });

    test('repeated identical status is debounced (no extra emission)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-1', true); // same value: no-op
      m.updateServerStatus('srv-1', true);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
      expect(emitted.first, {'srv-1': true});
    });

    test('online/offline server-id getters reflect updateServerStatus', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('a', true);
      m.updateServerStatus('b', false);
      m.updateServerStatus('c', true);

      expect(m.onlineServerIds.toSet(), {'a', 'c'});
      expect(m.offlineServerIds.toSet(), {'b'});
      expect(m.isServerOnline('a'), isTrue);
      expect(m.isServerOnline('b'), isFalse);
    });
  });

  group('refreshTokensForProfile', () {
    test('successful in-place Plex token refresh clears auth-error state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final m = MultiServerManager();
      addTearDown(m.dispose);

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: 'server-1',
        serverName: 'Plex',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      m.debugRegisterClientForTesting(client, online: true);
      m.debugMarkAuthErrorForTesting('server-1');

      final bound = await m.refreshTokensForProfile(
        PlexAccountConnection(
          id: 'account-1',
          accountToken: 'account-token',
          clientIdentifier: 'client-id',
          accountLabel: 'Account',
          servers: [
            PlexServer(
              name: 'Plex',
              clientIdentifier: 'server-1',
              accessToken: 'new-token',
              connections: const [],
              owned: true,
            ),
          ],
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      expect(bound, {'server-1'});
      expect(m.authErrorServerIds, isNot(contains('server-1')));
      expect(client.config.token, 'new-token');
    });
  });

  group('Jellyfin connection updates', () {
    test('persists refreshed admin status discovered during health checks', () async {
      final persisted = <JellyfinConnection>[];
      final persistStarted = Completer<void>();
      final allowPersist = Completer<void>();
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()
        ..onJellyfinConnectionUpdated = (connection) async {
          persistStarted.complete();
          await allowPersist.future;
          persisted.add(connection);
        };
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final healthFuture = m.checkServerHealth();
      await persistStarted.future;
      expect(persisted, isEmpty);
      allowPersist.complete();
      await healthFuture;

      expect(persisted, hasLength(1));
      expect(persisted.single.isAdministrator, isTrue);
    });

    test('health remains online when persisting refreshed admin status fails', () async {
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient(
          (_) async =>
              http.Response('{"Policy":{"IsAdministrator":true}}', 200, headers: {'content-type': 'application/json'}),
        ),
      );
      addTearDown(client.close);
      final m = MultiServerManager()
        ..onJellyfinConnectionUpdated = (_) async {
          throw Exception('disk full');
        };
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      await m.checkServerHealth();

      expect(m.isServerOnline('jf-machine'), isTrue);
      expect(m.isOwnerOrAdmin('jf-machine'), isTrue);
    });

    test('ignores stale admin-status persistence from a replaced Jellyfin client', () async {
      final persisted = <JellyfinConnection>[];
      final requestStarted = Completer<void>();
      final allowResponse = Completer<void>();
      final oldClient = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((_) async {
          requestStarted.complete();
          await allowResponse.future;
          return http.Response(
            '{"Policy":{"IsAdministrator":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final newClient = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(accessToken: 'new-token'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(oldClient.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(oldClient);
      final healthFuture = m.checkServerHealth();
      await requestStarted.future;
      m.debugRegisterJellyfinClientForTesting(newClient);
      allowResponse.complete();
      await healthFuture;

      expect(persisted, isEmpty);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), same(newClient));
    });

    test('ignores stale health status when active Jellyfin user changes mid-check', () async {
      final requestStarted = Completer<void>();
      final allowResponse = Completer<void>();
      final userA = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((_) async {
          requestStarted.complete();
          await allowResponse.future;
          return http.Response('', 403);
        }),
      );
      final userB = _jellyfinClient('user-b');
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(userA);
      final healthFuture = m.checkServerHealth();
      await requestStarted.future;
      m.debugRegisterJellyfinClientForTesting(userB, online: true);
      allowResponse.complete();
      await healthFuture;

      expect(m.getClient('jf-machine'), same(userB));
      expect(m.isServerOnline('jf-machine'), isTrue);
      expect(m.authErrorServerIds, isNot(contains('jf-machine')));
    });
  });

  // ============================================================
  // removeServer
  // ============================================================

  group('removeServer', () {
    test('removes a tracked server\'s status entry and emits a snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-2', true);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer('srv-1');
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isNot(contains('srv-1')));
      expect(emitted, isNotEmpty);
      expect(emitted.last, {'srv-2': true});
    });

    test('removing an unknown id still emits a snapshot (does not throw)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer('never-added');
      await Future<void>.delayed(Duration.zero);

      // Doesn't throw; state stays empty; one snapshot fires.
      expect(m.serverIds, isEmpty);
      expect(emitted, hasLength(1));
      expect(emitted.first, isEmpty);
    });

    test('removing a Jellyfin machine clears every scoped user client', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-a'));
      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-b'));

      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNotNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNotNull);

      m.removeServer('jf-machine');

      expect(m.getClient('jf-machine'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNull);
    });
  });

  // ============================================================
  // disconnectAll
  // ============================================================

  group('disconnectAll', () {
    test('clears all status and emits an empty snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('a', true);
      m.updateServerStatus('b', false);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.disconnectAll();
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(emitted.last, isEmpty);
    });

    test('clears inactive Jellyfin scoped clients', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-a'));
      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-b'));

      m.disconnectAll();

      expect(m.getClient('jf-machine'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNull);
    });
  });

  // ============================================================
  // dispose
  // ============================================================

  group('dispose', () {
    test('disposing without connectivity monitoring does not throw', () {
      final m = MultiServerManager();
      // No startNetworkMonitoring call → _connectivitySubscription is null.
      // dispose() must handle the null-subscription path cleanly.
      expect(m.dispose, returnsNormally);
    });

    test('dispose closes the status stream (existing subscribers get onDone)', () async {
      final m = MultiServerManager();
      var done = false;
      final sub = m.statusStream.listen((_) {}, onDone: () => done = true);
      m.dispose();
      // Allow the close event to propagate.
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      await sub.cancel();
    });
  });
}
