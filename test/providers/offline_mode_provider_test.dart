import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_auth_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  // OfflineModeProvider depends on a MultiServerManager. We instantiate one with
  // no connected servers — this exercises only the in-memory bookkeeping (id
  // maps + status stream) and never opens an HTTP socket. Network paths
  // (initialize/refresh's connectivity_plus call) are skipped: the
  // MissingPluginException in tests is already swallowed by the provider's
  // try/catch, so we don't drive `initialize()` here.
  setUp(resetSharedPreferencesForTest);

  group('OfflineModeProvider', () {
    test('with empty manager: hasServerConnection=false but isOffline stays false during warmup', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      // Until [MultiServerManager] emits its first status snapshot, we don't
      // actually know whether the binder will connect anything — treating an
      // empty manager as offline causes the cold-start UI to flash the
      // offline state for the few hundred ms it takes to come up. Stay
      // optimistic.
      expect(p.hasNetworkConnection, isTrue);
      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('reads online server IDs from the manager at construction', () {
      final manager = MultiServerManager();
      manager.updateServerStatus(ServerId('srv-1'), true);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isTrue);
      // Network is assumed up by default; both up → not offline.
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('all servers offline at construction → still warmup-optimistic until status emits', () {
      // updateServerStatus pushes to a broadcast controller — the provider
      // hasn't subscribed yet, so it never sees these events. After
      // construction `onlineServerIds` is empty (the same shape as a
      // fresh-cold-start manager), so we stay optimistic until the
      // provider's own listener catches an emission.
      final manager = MultiServerManager();
      manager.updateServerStatus(ServerId('srv-1'), false);
      manager.updateServerStatus(ServerId('srv-2'), false);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('dispose without initialize is safe (no subscriptions to cancel)', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      // Both subscriptions are null since initialize() was never called.
      // dispose must tolerate this without throwing.
      expect(p.dispose, returnsNormally);
      manager.dispose();
    });

    test('dispose marks provider as disposed; later notifies are no-ops', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      p.dispose();
      // After dispose, the disposable mixin guards against post-dispose notify.
      // We can't call private safeNotifyListeners, but `isDisposed` reflects state.
      expect(p.isDisposed, isTrue);

      manager.dispose();
    });

    test('OfflineModeSource interface contract: isOffline is exposed', () {
      final manager = MultiServerManager();
      manager.updateServerStatus(ServerId('srv'), true);
      final p = OfflineModeProvider(manager);

      // The provider implements OfflineModeSource — its isOffline getter is the
      // sole observable surface for downstream consumers.
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('warmup skipped when manager already has an online server at construction', () {
      // If the manager already has an online server when the provider is
      // built, we have ground truth — no need for the warmup window.
      // hasServerConnection reflects the manager's state and isOffline
      // is correctly false (network up + server up).
      final manager = MultiServerManager();
      manager.updateServerStatus(ServerId('srv'), true);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isTrue);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('auth-error-only visible servers do not collapse to generic offline', () async {
      final manager = MultiServerManager();
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection(),
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      manager.debugRegisterJellyfinClientForTesting(client, online: false);
      final multi = MultiServerProvider(manager, DataAggregationService(manager));
      final p = OfflineModeProvider(manager, multiServerProvider: multi);
      await p.initialize();

      manager.debugMarkAuthErrorForTesting(ServerId('jf-machine'));
      await Future<void>.delayed(Duration.zero);

      expect(multi.authErrorServerIds, contains('jf-machine'));
      expect(p.isOffline, isFalse);

      p.dispose();
      multi.dispose();
      manager.dispose();
    });

    test('expected but unreachable visible servers enter offline without live clients', () async {
      final manager = MultiServerManager();
      final multi = MultiServerProvider(manager, DataAggregationService(manager));
      final p = OfflineModeProvider(manager, multiServerProvider: multi);
      await p.initialize();
      manager.updateServerStatus(ServerId('plex-server'), false);
      await Future<void>.delayed(Duration.zero);
      expect(p.isOffline, isFalse);

      var notifications = 0;
      p.addListener(() => notifications++);

      multi.setExpectedVisibleServerIds({'plex-server'});
      multi.setVisibleServerIds(<String>{});
      await Future<void>.delayed(Duration.zero);

      expect(p.isOffline, isTrue);
      expect(notifications, 1);

      p.dispose();
      multi.dispose();
      manager.dispose();
    });

    test('expected but unreachable profile servers enter offline once visibility settles', () async {
      final manager = MultiServerManager();
      final multi = MultiServerProvider(manager, DataAggregationService(manager));
      final p = OfflineModeProvider(manager, multiServerProvider: multi);

      expect(p.isOffline, isFalse);

      var notifications = 0;
      p.addListener(() => notifications++);

      multi.setExpectedVisibleServerIds({'jf-machine'});
      await Future<void>.delayed(Duration.zero);

      expect(p.isOffline, isFalse);
      expect(notifications, 0);

      multi.setVisibleServerIds(<String>{});
      await Future<void>.delayed(Duration.zero);

      expect(p.isOffline, isTrue);
      expect(notifications, 1);

      p.dispose();
      multi.dispose();
      manager.dispose();
    });

    test('Plex auth errors without live clients stay out of generic offline', () async {
      final manager = MultiServerManager();
      final multi = MultiServerProvider(manager, DataAggregationService(manager));
      final p = OfflineModeProvider(manager, multiServerProvider: multi);
      await p.initialize();

      multi.setExpectedVisibleServerIds({'plex-server'});
      manager.markPlexConnectionAuthError(_plexConnection());
      await Future<void>.delayed(Duration.zero);

      expect(multi.authErrorServerIds, ['plex-server']);
      expect(multi.authErrorServers.single.displayName, 'Plex');
      expect(p.isOffline, isFalse);

      p.dispose();
      multi.dispose();
      manager.dispose();
    });
  });
}

PlexAccountConnection _plexConnection() {
  return PlexAccountConnection(
    id: 'plex-account',
    accountToken: 'account-token',
    clientIdentifier: 'client-id',
    accountLabel: 'Plex Account',
    servers: [
      PlexServer(
        name: 'Plex',
        clientIdentifier: 'plex-server',
        accessToken: 'server-token',
        connections: [
          PlexConnection(
            protocol: 'https',
            address: 'plex.example',
            port: 32400,
            uri: 'https://plex.example:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
        owned: true,
      ),
    ],
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

JellyfinConnection _jellyfinConnection() {
  return JellyfinConnection(
    id: 'jf-machine/user-a',
    baseUrl: 'https://jellyfin.example',
    serverName: 'Jellyfin',
    serverMachineId: 'jf-machine',
    userId: 'user-a',
    userName: 'User A',
    accessToken: 'token',
    deviceId: 'device',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
