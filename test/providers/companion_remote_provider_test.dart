import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/plex/plex_home.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/lan_discovery_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetSharedPreferencesForTest);

  group('CompanionRemoteProvider — initial state', () {
    test('discoverHosts returns null when crypto is not ready', () {
      final p = CompanionRemoteProvider();
      expect(p.discoverHosts(), isNull);
      p.dispose();
    });

    test('sendCommand is a no-op when not connected (no throw)', () {
      final p = CompanionRemoteProvider();
      // Not connected → cannot send. Must log a warning but not throw.
      expect(() => p.sendCommand(RemoteCommandType.ping), returnsNormally);
      p.dispose();
    });

    test('startHostServer no-ops when crypto is not ready', () async {
      final p = CompanionRemoteProvider();
      // Without crypto context, this method must early-return without
      // creating a peer service or session.
      await p.startHostServer();
      expect(p.session, isNull);
      expect(p.isHostServerRunning, isFalse);
      p.dispose();
    });
  });

  group('CompanionRemoteProvider — dispose hygiene', () {
    test('cancelReconnect on a fresh provider does not throw', () {
      final p = CompanionRemoteProvider();
      // No timer, no session — copyWith on null _session is a no-op so
      // status remains disconnected.
      expect(p.cancelReconnect, returnsNormally);
      expect(p.status, RemoteSessionStatus.disconnected);
      p.dispose();
    });

    test('stopDiscovery on a fresh provider is a no-op', () {
      final p = CompanionRemoteProvider();
      expect(p.stopDiscovery, returnsNormally);
      p.dispose();
    });

    test('leaveSession on a fresh provider does not throw', () async {
      final p = CompanionRemoteProvider();
      await p.leaveSession();
      expect(p.session, isNull);
      p.dispose();
    });

    test('safeNotifyListeners no-ops after dispose (deviceInfo race)', () async {
      // The constructor kicks off an async _initializeDeviceInfo() that calls
      // safeNotifyListeners() on completion. Disposing before that microtask
      // resolves must not throw — the disposable mixin should swallow it.
      final p = CompanionRemoteProvider();
      p.dispose();
      // Yield so any pending device-info callbacks complete.
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('CompanionRemoteProvider — reconnect ownership', () {
    test('newest overlapping connect owns the session and disposes the stale candidate once', () async {
      final firstJoinGate = Completer<void>();
      final firstDisposalGate = Completer<void>();
      final first = _FakeCompanionRemotePeerService(joinGate: firstJoinGate, disconnectGate: firstDisposalGate);
      final second = _FakeCompanionRemotePeerService();
      final factory = _FakePeerFactory([first, second]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);

      final olderConnect = harness.provider.connectToManualHost('192.0.2.20:48634');
      await first.joinStarted.future;
      final newerConnect = harness.provider.connectToManualHost('192.0.2.21:48634');
      await first.disconnectStarted.future;
      firstJoinGate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(first.disposeCalls, 1);

      firstDisposalGate.complete();
      await second.joinStarted.future;
      await newerConnect;

      harness.provider.sendCommand(RemoteCommandType.playPause);
      expect(harness.provider.status, RemoteSessionStatus.connected);
      expect(second.sentCommands.single.type, RemoteCommandType.playPause);

      await olderConnect;

      expect(harness.provider.status, RemoteSessionStatus.connected);
      expect(first.disposeCalls, 1);
      expect(first.disconnectCalls, 1);
      expect(first.hasListeners, isFalse);
      expect(second.disposeCalls, 0);
      expect(factory.created, 2);
    });

    test('replacement disconnect reconnects while intentional predecessor teardown is blocked', () async {
      final predecessorDisposalGate = Completer<void>();
      final predecessor = _FakeCompanionRemotePeerService(disconnectGate: predecessorDisposalGate);
      final replacement = _FakeCompanionRemotePeerService();
      final factory = _FakePeerFactory([predecessor, replacement]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);

      Future<void>? predecessorTeardown;
      addTearDown(() async {
        if (!predecessorDisposalGate.isCompleted) {
          predecessorDisposalGate.complete();
        }
        final teardown = predecessorTeardown;
        if (teardown != null) await teardown;
      });

      await harness.provider.connectToManualHost('192.0.2.22:48634');

      var teardownCompleted = false;
      predecessorTeardown = harness.provider.leaveSession().whenComplete(() {
        teardownCompleted = true;
      });
      await predecessor.disconnectStarted.future;
      expect(teardownCompleted, isFalse);

      await harness.provider.connectToManualHost('192.0.2.23:48634');
      expect(harness.provider.status, RemoteSessionStatus.connected);
      expect(replacement.hasListeners, isTrue);

      final publishedStatuses = <RemoteSessionStatus>[];
      void captureStatus() => publishedStatuses.add(harness.provider.status);
      harness.provider.addListener(captureStatus);

      predecessor.emitError(
        RemotePeerError(type: RemotePeerErrorType.connectionFailed, message: 'stale predecessor error'),
      );
      predecessor.emitDeviceDisconnected();

      expect(publishedStatuses, isEmpty);
      expect(harness.provider.status, RemoteSessionStatus.connected);
      expect(harness.provider.session?.errorMessage, isNull);
      expect(harness.provider.reconnectAttempts, 0);

      replacement.emitDeviceDisconnected();

      expect(publishedStatuses, [RemoteSessionStatus.reconnecting]);
      expect(harness.provider.status, RemoteSessionStatus.reconnecting);
      expect(harness.provider.reconnectAttempts, 1);
      expect(teardownCompleted, isFalse);

      predecessorDisposalGate.complete();
      await predecessorTeardown;

      expect(publishedStatuses, [RemoteSessionStatus.reconnecting]);
      expect(harness.provider.status, RemoteSessionStatus.reconnecting);
      expect(harness.provider.reconnectAttempts, 1);

      harness.provider.removeListener(captureStatus);
      await harness.provider.cancelReconnect();
    });

    test('cancelReconnect fully tears down a running host and discovery', () async {
      final hostDisposalGate = Completer<void>();
      final host = _FakeCompanionRemotePeerService(disconnectGate: hostDisposalGate);
      final discovery = _FakeLanDiscoveryService();
      final factory = _FakePeerFactory([host]);
      final harness = await _RemoteHarness.create(factory.call, discoveryServiceFactory: () => discovery);
      addTearDown(harness.close);

      await harness.provider.startHostServer();
      expect(harness.provider.isHostServerRunning, isTrue);
      expect(harness.provider.debugIsDiscoveryBroadcasting, isTrue);
      expect(host.hasListeners, isTrue);

      final cancellation = harness.provider.cancelReconnect();
      await host.disconnectStarted.future;
      expect(harness.provider.debugIsDiscoveryBroadcasting, isFalse);
      expect(host.hasListeners, isFalse);
      hostDisposalGate.complete();
      await cancellation;

      expect(harness.provider.session, isNull);
      expect(harness.provider.isHostServerRunning, isFalse);
      expect(harness.provider.debugIsDiscoveryBroadcasting, isFalse);
      expect(harness.provider.debugIsDiscoveryListening, isFalse);
      expect(discovery.stopBroadcastingCalls, 1);
      expect(discovery.stopListeningCalls, 1);
      expect(host.disposeCalls, 1);
      expect(host.disconnectCalls, 1);
      expect(host.hasListeners, isFalse);
    });

    test('cancel during join keeps disconnected state and disposes the candidate once', () async {
      final initial = _FakeCompanionRemotePeerService();
      final joinGate = Completer<void>();
      final candidate = _FakeCompanionRemotePeerService(joinGate: joinGate);
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.10:48634');

      final statuses = <RemoteSessionStatus>[];
      harness.provider.addListener(() => statuses.add(harness.provider.status));
      initial.emitDeviceDisconnected();
      expect(harness.provider.status, RemoteSessionStatus.reconnecting);

      final retry = harness.provider.retryReconnectNow();
      await candidate.joinStarted.future;
      expect(candidate.hasListeners, isTrue);

      final cancellation = harness.provider.cancelReconnect();
      expect(harness.provider.status, RemoteSessionStatus.disconnected);
      await cancellation;
      final statusCountAfterCancel = statuses.length;

      joinGate.complete();
      await retry;
      await Future<void>.delayed(Duration.zero);

      expect(harness.provider.status, RemoteSessionStatus.disconnected);
      expect(statuses.skip(statusCountAfterCancel), isNot(contains(RemoteSessionStatus.connected)));
      expect(candidate.disposeCalls, 1);
      expect(candidate.disconnectCalls, 1);
      expect(candidate.hasListeners, isFalse);
      expect(factory.created, 2);
      expect(harness.provider.reconnectAttempts, 0);
    });

    test('leave during join clears the session and rejects late commands', () async {
      final initial = _FakeCompanionRemotePeerService();
      final joinGate = Completer<void>();
      final candidate = _FakeCompanionRemotePeerService(joinGate: joinGate);
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.11:48634');

      var deliveredCommands = 0;
      harness.provider.onCommandReceived = (_) => deliveredCommands++;
      initial.emitDeviceDisconnected();
      final retry = harness.provider.retryReconnectNow();
      await candidate.joinStarted.future;

      await harness.provider.leaveSession();
      expect(harness.provider.session, isNull);
      expect(candidate.hasListeners, isFalse);
      candidate.emitCommand(const RemoteCommand(type: RemoteCommandType.playPause));
      joinGate.complete();
      await retry;

      expect(harness.provider.session, isNull);
      expect(deliveredCommands, 0);
      expect(candidate.disposeCalls, 1);
      expect(factory.created, 2);
      expect(harness.provider.reconnectAttempts, 0);
    });

    for (final action in ['cancel', 'leave']) {
      test('$action before candidate creation prevents replacement allocation', () async {
        final disconnectGate = Completer<void>();
        final initial = _FakeCompanionRemotePeerService(disconnectGate: disconnectGate);
        final replacement = _FakeCompanionRemotePeerService();
        final factory = _FakePeerFactory([initial, replacement]);
        final harness = await _RemoteHarness.create(factory.call);
        addTearDown(harness.close);
        await harness.provider.connectToManualHost('192.0.2.12:48634');

        initial.emitDeviceDisconnected();
        final retry = harness.provider.retryReconnectNow();
        await initial.disconnectStarted.future;

        if (action == 'cancel') {
          await harness.provider.cancelReconnect();
        } else {
          await harness.provider.leaveSession();
        }
        disconnectGate.complete();
        await retry;

        expect(factory.created, 1);
        expect(replacement.joinStarted.isCompleted, isFalse);
        expect(initial.disposeCalls, 1);
      });
    }

    test('dispose during join detaches listeners and prevents a late commit', () async {
      final initial = _FakeCompanionRemotePeerService();
      final joinGate = Completer<void>();
      final candidate = _FakeCompanionRemotePeerService(joinGate: joinGate);
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.13:48634');

      var deliveredCommands = 0;
      harness.provider.onCommandReceived = (_) => deliveredCommands++;
      initial.emitDeviceDisconnected();
      final retry = harness.provider.retryReconnectNow();
      await candidate.joinStarted.future;

      harness.provider.dispose();
      expect(harness.provider.isDisposed, isTrue);
      expect(candidate.hasListeners, isFalse);
      candidate.emitCommand(const RemoteCommand(type: RemoteCommandType.playPause));
      joinGate.complete();
      await retry;
      await Future<void>.delayed(Duration.zero);

      expect(harness.provider.status, isNot(RemoteSessionStatus.connected));
      expect(deliveredCommands, 0);
      expect(candidate.disposeCalls, 1);
      expect(factory.created, 2);
    });

    test('logout invalidates a held reconnect before clearing identity', () async {
      final initial = _FakeCompanionRemotePeerService();
      final joinGate = Completer<void>();
      final candidate = _FakeCompanionRemotePeerService(joinGate: joinGate);
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.14:48634');

      initial.emitDeviceDisconnected();
      final retry = harness.provider.retryReconnectNow();
      await candidate.joinStarted.future;

      await harness.provider.resetForLogout();
      expect(harness.provider.session, isNull);
      expect(harness.provider.isCryptoReady, isFalse);
      expect(harness.provider.debugCryptoConnectionId, isNull);
      expect(candidate.hasListeners, isFalse);

      joinGate.complete();
      await retry;

      expect(harness.provider.session, isNull);
      expect(harness.provider.isCryptoReady, isFalse);
      expect(candidate.disposeCalls, 1);
      expect(factory.created, 2);
      expect(harness.provider.reconnectAttempts, 0);
    });

    test('current reconnect failure is contained and schedules one retry', () async {
      final initial = _FakeCompanionRemotePeerService();
      final candidate = _FakeCompanionRemotePeerService(joinError: StateError('synthetic reconnect failure'));
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.15:48634');

      initial.emitDeviceDisconnected();
      await harness.provider.retryReconnectNow();

      expect(harness.provider.status, RemoteSessionStatus.reconnecting);
      expect(harness.provider.reconnectAttempts, 1);
      expect(candidate.disposeCalls, 1);
      expect(candidate.hasListeners, isFalse);

      await harness.provider.cancelReconnect();
    });

    test('successful current reconnect preserves connected behavior', () async {
      final initial = _FakeCompanionRemotePeerService();
      final candidate = _FakeCompanionRemotePeerService();
      final factory = _FakePeerFactory([initial, candidate]);
      final harness = await _RemoteHarness.create(factory.call);
      addTearDown(harness.close);
      await harness.provider.connectToManualHost('192.0.2.16:48634');

      initial.emitDeviceDisconnected();
      await harness.provider.retryReconnectNow();
      harness.provider.sendCommand(RemoteCommandType.playPause);

      expect(harness.provider.status, RemoteSessionStatus.connected);
      expect(harness.provider.reconnectAttempts, 0);
      expect(candidate.sentCommands.single.type, RemoteCommandType.playPause);
      expect(initial.disposeCalls, 1);
      expect(candidate.disposeCalls, 0);
    });
  });

  group('CompanionRemoteProvider — public API safety', () {
    test('connectToDiscoveredHost reports localized auth failure when crypto is not ready', () async {
      final p = CompanionRemoteProvider();
      await expectLater(
        () => p.connectToManualHost('192.0.2.1:9999'),
        throwsA(
          isA<PeerError>().having((error) => error.message, 'message', t.companionRemote.pairing.cryptoInitFailed),
        ),
      );
      p.dispose();
    });
  });

  group('CompanionRemoteProvider — crypto identity', () {
    test('Jellyfin remote secret is stable across tokens for the same server user', () async {
      final auth = RemoteAuthService.instance;
      auth.clearCache();

      final tokenA = await auth.deriveJellyfinSecret(serverMachineId: 'machine-a', userId: 'user-a');
      final tokenAAgain = await auth.deriveJellyfinSecret(serverMachineId: 'machine-a', userId: 'user-a');
      final tokenB = await auth.deriveJellyfinSecret(serverMachineId: 'machine-a', userId: 'user-a');
      final otherUser = await auth.deriveJellyfinSecret(serverMachineId: 'machine-a', userId: 'user-b');

      expect(tokenAAgain, tokenA);
      expect(tokenB, tokenA);
      expect(otherUser, isNot(tokenA));
    });

    test('ensureCryptoReady rebuilds when the active profile/account changes', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      final accountA = _plexAccount('plex-a', 'client-a');
      final accountB = _plexAccount('plex-b', 'client-b');
      final profileA = _localProfile('profile-a');
      final profileB = _localProfile('profile-b');
      await stack.connections.upsert(accountA);
      await stack.connections.upsert(accountB);
      await stack.profiles.upsert(profileA);
      await stack.profiles.upsert(profileB);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profileA.id, connectionId: accountA.id, userIdentifier: 'admin-a'),
        makeDefault: true,
      );
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profileB.id, connectionId: accountB.id, userIdentifier: 'admin-b'),
        makeDefault: true,
      );
      await stack.storage.setActiveProfileId(profileA.id);
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final okA = await provider.ensureCryptoReady(
        _home('admin-a'),
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
        account: accountA,
      );
      expect(okA, isTrue);
      expect(provider.debugCryptoConnectionId, accountA.id);
      expect(provider.debugCryptoProfileId, profileA.id);

      await stack.active.activate(profileB);

      final ok = await provider.ensureCryptoReady(
        _home('admin-b'),
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
        account: accountB,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, accountB.id);
      expect(provider.debugCryptoProfileId, profileB.id);
    });

    test('ensureCryptoReady uses the active local profile Plex row', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      final accountA = _plexAccount('plex-a', 'client-a');
      final accountB = _plexAccount('plex-b', 'client-b');
      final profile = _localProfile('profile-local');
      await stack.connections.upsert(accountA);
      await stack.connections.upsert(accountB);
      await stack.profiles.upsert(profile);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: accountB.id, userIdentifier: 'child-b', isDefault: true),
        makeDefault: true,
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        _homeWithUsers('admin-b', ['child-b']),
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, accountB.id);
      expect(provider.debugCryptoProfileId, profile.id);
      expect(provider.debugCryptoUserUuid, 'child-b');
    });

    test('ensureCryptoReady uses the active local profile Jellyfin row', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      final jellyfin = _jellyfinConnection('jf-a');
      final profile = _localProfile('profile-jf');
      await stack.connections.upsert(jellyfin);
      await stack.profiles.upsert(profile);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
        makeDefault: true,
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        null,
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, jellyfin.id);
      expect(provider.debugCryptoProfileId, profile.id);
      expect(provider.debugCryptoUserUuid, jellyfin.userId);
    });

    test('ensureCryptoReady includes every active local profile remote identity', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      final account = _plexAccount('plex-a', 'client-a');
      final jellyfin = _jellyfinConnection('jf-a');
      final profile = _localProfile('profile-mixed');
      final home = _homeWithUsers('admin-a', ['child-a']);
      await stack.connections.upsert(account);
      await stack.connections.upsert(jellyfin);
      await stack.profiles.upsert(profile);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
        makeDefault: true,
      );
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: account.id, userIdentifier: 'child-a'),
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        home,
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
        plexHomeForConnection: (_) async => home,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, jellyfin.id);
      expect(provider.debugCryptoConnectionIds, [jellyfin.id, account.id]);
    });

    test('ensureCryptoReady does not fall back to an account without an active profile', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      await stack.connections.upsert(_plexAccount('plex-a', 'client-a'));
      await stack.profiles.upsert(_localProfile('profile-a'));
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        _home('admin-a'),
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
      );

      expect(ok, isFalse);
      expect(provider.isCryptoReady, isFalse);
    });

    test('resetForLogout clears crypto context', () async {
      final stack = await ProfileStack.create();
      addTearDown(stack.dispose);

      final account = _plexAccount('plex-a', 'client-a');
      final profile = _localProfile('profile-a');
      await stack.connections.upsert(account);
      await stack.profiles.upsert(profile);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: account.id, userIdentifier: 'admin-a'),
        makeDefault: true,
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      await provider.ensureCryptoReady(
        _home('admin-a'),
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
        account: account,
      );
      expect(provider.isCryptoReady, isTrue);

      await provider.resetForLogout();

      expect(provider.isCryptoReady, isFalse);
      expect(provider.debugCryptoConnectionId, isNull);
      expect(provider.debugCryptoProfileId, isNull);
    });
  });
}

PlexAccountConnection _plexAccount(String id, String clientIdentifier) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'token-$id',
    clientIdentifier: clientIdentifier,
    accountLabel: id,
    createdAt: DateTime(2026, 1, 1),
  );
}

JellyfinConnection _jellyfinConnection(String id) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://jellyfin.example.test',
    serverName: 'Jellyfin',
    serverMachineId: 'machine-$id',
    userId: 'user-$id',
    userName: 'User $id',
    accessToken: 'token-$id',
    deviceId: 'device-$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

Profile _localProfile(String id) {
  return Profile.local(id: id, displayName: id, createdAt: DateTime(2026, 1, 1));
}

PlexHome _home(String adminUuid) {
  return PlexHome(
    id: 1,
    name: 'Home',
    guestUserID: null,
    guestUserUUID: '',
    guestEnabled: false,
    subscription: false,
    users: [_homeUser(adminUuid, admin: true)],
  );
}

PlexHome _homeWithUsers(String adminUuid, List<String> userUuids) {
  return PlexHome(
    id: 1,
    name: 'Home',
    guestUserID: null,
    guestUserUUID: '',
    guestEnabled: false,
    subscription: false,
    users: [_homeUser(adminUuid, admin: true), for (final uuid in userUuids) _homeUser(uuid, admin: false)],
  );
}

PlexHomeUser _homeUser(String uuid, {required bool admin}) {
  return PlexHomeUser(
    id: admin ? 1 : 2,
    uuid: uuid,
    title: uuid,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: false,
  );
}

class _FakePeerFactory {
  _FakePeerFactory(this.peers);

  final List<_FakeCompanionRemotePeerService> peers;
  int created = 0;

  CompanionRemotePeerService call() {
    if (created >= peers.length) {
      throw StateError('Unexpected peer allocation');
    }
    return peers[created++];
  }
}

class _FakeCompanionRemotePeerService extends CompanionRemotePeerService {
  _FakeCompanionRemotePeerService({this.joinGate, this.disconnectGate, this.joinError});

  final Completer<void>? joinGate;
  final Completer<void>? disconnectGate;
  final Object? joinError;
  final Completer<void> joinStarted = Completer<void>();
  final Completer<void> disconnectStarted = Completer<void>();
  final List<RemoteCommand> sentCommands = [];

  final StreamController<RemoteCommand> _commands = StreamController<RemoteCommand>.broadcast(sync: true);
  final StreamController<RemoteDevice> _connected = StreamController<RemoteDevice>.broadcast(sync: true);
  final StreamController<void> _disconnected = StreamController<void>.broadcast(sync: true);
  final StreamController<RemotePeerError> _errors = StreamController<RemotePeerError>.broadcast(sync: true);
  final StreamController<RemoteSessionStatus> _statuses = StreamController<RemoteSessionStatus>.broadcast(sync: true);

  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool _streamsClosed = false;
  bool _serverRunning = false;

  @override
  bool get isServerRunning => _serverRunning;

  bool get hasListeners =>
      _commands.hasListener ||
      _connected.hasListener ||
      _disconnected.hasListener ||
      _errors.hasListener ||
      _statuses.hasListener;

  @override
  Stream<RemoteCommand> get onCommandReceived => _commands.stream;

  @override
  Stream<RemoteDevice> get onDeviceConnected => _connected.stream;

  @override
  Stream<void> get onDeviceDisconnected => _disconnected.stream;

  @override
  Stream<RemotePeerError> get onError => _errors.stream;

  @override
  Stream<RemoteSessionStatus> get onConnectionStateChanged => _statuses.stream;

  @override
  String? get selectedAuthContextId => 'auth-context';

  @override
  String? get selectedHostClientId => 'host-client';

  @override
  Future<({List<String> addresses, int port})> createSessionForContexts(
    String deviceName,
    String platform,
    List<RemoteAuthContext> authContexts,
  ) async {
    _serverRunning = true;
    return (addresses: const ['127.0.0.1:48634'], port: 48634);
  }

  @override
  Future<void> joinSessionWithContexts(
    String deviceName,
    String platform,
    String hostAddress,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) async {
    if (!joinStarted.isCompleted) joinStarted.complete();
    final gate = joinGate;
    if (gate != null) await gate.future;
    final error = joinError;
    if (error != null) throw error;
  }

  @override
  Future<String> joinSessionRacingWithContexts(
    String deviceName,
    String platform,
    List<String> hostAddresses,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) async {
    await joinSessionWithContexts(
      deviceName,
      platform,
      hostAddresses.first,
      authContexts,
      authContextId: authContextId,
      expectedHostClientId: expectedHostClientId,
    );
    return hostAddresses.first;
  }

  @override
  void sendCommand(RemoteCommand command) {
    sentCommands.add(command);
  }

  void emitDeviceDisconnected() {
    if (!_streamsClosed) _disconnected.add(null);
  }

  void emitCommand(RemoteCommand command) {
    if (!_streamsClosed) _commands.add(command);
  }

  void emitError(RemotePeerError error) {
    if (!_streamsClosed) _errors.add(error);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _serverRunning = false;
    if (!disconnectStarted.isCompleted) disconnectStarted.complete();
    final gate = disconnectGate;
    if (gate != null) await gate.future;
  }

  Future<void>? _disposeInFlight;

  /// Mirrors the real service's idempotent dispose (`_disposed` /
  /// `_disposeInProgress` dedup): only the first call tears down, concurrent
  /// and repeat calls join it. The provider relies on that contract instead of
  /// memoizing disposals itself, so [disposeCalls] counts effective disposals.
  @override
  Future<void> dispose() => _disposeInFlight ??= _disposeOnce();

  Future<void> _disposeOnce() async {
    disposeCalls++;
    await disconnect();
    if (_streamsClosed) return;
    _streamsClosed = true;
    await Future.wait([
      _commands.close(),
      _connected.close(),
      _disconnected.close(),
      _errors.close(),
      _statuses.close(),
    ]);
  }
}

class _FakeLanDiscoveryService extends LanDiscoveryService {
  bool _broadcasting = false;
  bool _listening = false;
  int stopBroadcastingCalls = 0;
  int stopListeningCalls = 0;

  @override
  bool get isBroadcasting => _broadcasting;

  @override
  bool get isListening => _listening;

  @override
  Future<void> startBroadcastingForContexts({
    required List<RemoteAuthContext> contexts,
    required String deviceName,
    required String platform,
    required int wsPort,
    required List<String> ips,
  }) async {
    _broadcasting = true;
  }

  @override
  Future<void> stopBroadcasting() async {
    stopBroadcastingCalls++;
    _broadcasting = false;
  }

  @override
  void stopListening() {
    stopListeningCalls++;
    _listening = false;
  }
}

class _RemoteHarness {
  _RemoteHarness({required this.provider, required this.stack});

  final CompanionRemoteProvider provider;
  final ProfileStack stack;
  bool _closed = false;

  static Future<_RemoteHarness> create(
    CompanionRemotePeerServiceFactory peerServiceFactory, {
    LanDiscoveryServiceFactory discoveryServiceFactory = LanDiscoveryService.new,
  }) async {
    final stack = await ProfileStack.create();

    final account = _plexAccount('remote-account', 'remote-client');
    final profile = _localProfile('remote-profile');
    await stack.connections.upsert(account);
    await stack.profiles.upsert(profile);
    await stack.profileConnections.upsert(
      ProfileConnection(profileId: profile.id, connectionId: account.id, userIdentifier: 'remote-admin'),
      makeDefault: true,
    );
    await stack.storage.setActiveProfileId(profile.id);
    await stack.active.initialize();

    final provider = CompanionRemoteProvider.forTesting(
      peerServiceFactory: peerServiceFactory,
      discoveryServiceFactory: discoveryServiceFactory,
    );
    final ready = await provider.ensureCryptoReady(
      _home('remote-admin'),
      connections: stack.connections,
      activeProfile: stack.active,
      profileConnections: stack.profileConnections,
      account: account,
    );
    if (!ready) {
      throw StateError('Remote test harness failed to initialize crypto');
    }

    return _RemoteHarness(provider: provider, stack: stack);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!provider.isDisposed) provider.dispose();
    await stack.dispose();
  }
}
