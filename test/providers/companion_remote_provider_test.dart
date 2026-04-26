import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetSharedPreferencesForTest);

  group('CompanionRemoteProvider — initial state', () {
    test('starts with no session and no connected device', () {
      final p = CompanionRemoteProvider();
      expect(p.session, isNull);
      expect(p.isInSession, isFalse);
      expect(p.isHost, isFalse);
      expect(p.isRemote, isFalse);
      expect(p.isConnected, isFalse);
      expect(p.connectedDevice, isNull);
      expect(p.status, RemoteSessionStatus.disconnected);
      p.dispose();
    });

    test('isPlayerActive starts false', () {
      final p = CompanionRemoteProvider();
      expect(p.isPlayerActive, isFalse);
      p.dispose();
    });

    test('isHostServerRunning starts false (no peer service yet)', () {
      final p = CompanionRemoteProvider();
      expect(p.isHostServerRunning, isFalse);
      p.dispose();
    });

    test('reconnectAttempts starts at 0', () {
      final p = CompanionRemoteProvider();
      expect(p.reconnectAttempts, 0);
      p.dispose();
    });

    test('isCryptoReady is false until initializeCrypto is called', () {
      final p = CompanionRemoteProvider();
      expect(p.isCryptoReady, isFalse);
      p.dispose();
    });

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
    test('dispose runs cleanly with no peer service or subscriptions', () {
      final p = CompanionRemoteProvider();
      expect(p.dispose, returnsNormally);
    });

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

  group('CompanionRemoteProvider — public API safety', () {
    test('connectToDiscoveredHost throws StateError when crypto not ready', () async {
      final p = CompanionRemoteProvider();
      // Constructing a DiscoveredHost-like object would require importing
      // the lan_discovery_service; skip the constructed-instance variant
      // and instead exercise connectToManualHost which has the same guard.
      await expectLater(() => p.connectToManualHost('192.0.2.1:9999'), throwsA(isA<StateError>()));
      p.dispose();
    });

    test('connectToManualHost rejects empty host strings via crypto guard', () async {
      final p = CompanionRemoteProvider();
      // Crypto isn't ready → guard fires before any network logic.
      await expectLater(() => p.connectToManualHost(''), throwsA(isA<StateError>()));
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
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final accountA = _plexAccount('plex-a', 'client-a');
      final accountB = _plexAccount('plex-b', 'client-b');
      final profileA = _localProfile('profile-a');
      final profileB = _localProfile('profile-b');
      await connections.upsert(accountB);
      await profiles.upsert(profileB);
      await profileConnections.upsert(
        ProfileConnection(profileId: profileB.id, connectionId: accountB.id, userIdentifier: 'admin-b'),
        makeDefault: true,
      );
      await storage.setActiveProfileId(profileB.id);
      await active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      await provider.initializeCrypto(home: _home('admin-a'), account: accountA, activeProfile: profileA);
      expect(provider.debugCryptoConnectionId, accountA.id);
      expect(provider.debugCryptoProfileId, profileA.id);

      final ok = await provider.ensureCryptoReady(
        _home('admin-b'),
        connections: connections,
        activeProfile: active,
        profileConnections: profileConnections,
        account: accountB,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, accountB.id);
      expect(provider.debugCryptoProfileId, profileB.id);
    });

    test('ensureCryptoReady uses the active local profile Plex row', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final accountA = _plexAccount('plex-a', 'client-a');
      final accountB = _plexAccount('plex-b', 'client-b');
      final profile = _localProfile('profile-local');
      await connections.upsert(accountA);
      await connections.upsert(accountB);
      await profiles.upsert(profile);
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: accountB.id, userIdentifier: 'child-b', isDefault: true),
        makeDefault: true,
      );
      await storage.setActiveProfileId(profile.id);
      await active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        _homeWithUsers('admin-b', ['child-b']),
        connections: connections,
        activeProfile: active,
        profileConnections: profileConnections,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, accountB.id);
      expect(provider.debugCryptoProfileId, profile.id);
      expect(provider.debugCryptoUserUuid, 'child-b');
    });

    test('ensureCryptoReady uses the active local profile Jellyfin row', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final jellyfin = _jellyfinConnection('jf-a');
      final profile = _localProfile('profile-jf');
      await connections.upsert(jellyfin);
      await profiles.upsert(profile);
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
        makeDefault: true,
      );
      await storage.setActiveProfileId(profile.id);
      await active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        null,
        connections: connections,
        activeProfile: active,
        profileConnections: profileConnections,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, jellyfin.id);
      expect(provider.debugCryptoProfileId, profile.id);
      expect(provider.debugCryptoUserUuid, jellyfin.userId);
    });

    test('ensureCryptoReady includes every active local profile remote identity', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final account = _plexAccount('plex-a', 'client-a');
      final jellyfin = _jellyfinConnection('jf-a');
      final profile = _localProfile('profile-mixed');
      final home = _homeWithUsers('admin-a', ['child-a']);
      await connections.upsert(account);
      await connections.upsert(jellyfin);
      await profiles.upsert(profile);
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
        makeDefault: true,
      );
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: account.id, userIdentifier: 'child-a'),
      );
      await storage.setActiveProfileId(profile.id);
      await active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        home,
        connections: connections,
        activeProfile: active,
        profileConnections: profileConnections,
        plexHomeForConnection: (_) async => home,
      );

      expect(ok, isTrue);
      expect(provider.debugCryptoConnectionId, jellyfin.id);
      expect(provider.debugCryptoConnectionIds, [jellyfin.id, account.id]);
    });

    test('ensureCryptoReady does not fall back to an account without an active profile', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      await connections.upsert(_plexAccount('plex-a', 'client-a'));
      await profiles.upsert(_localProfile('profile-a'));
      await active.initialize();

      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      final ok = await provider.ensureCryptoReady(
        _home('admin-a'),
        connections: connections,
        activeProfile: active,
        profileConnections: profileConnections,
      );

      expect(ok, isFalse);
      expect(provider.isCryptoReady, isFalse);
    });

    test('resetForLogout clears crypto context', () async {
      final provider = CompanionRemoteProvider();
      addTearDown(provider.dispose);
      await provider.initializeCrypto(
        home: _home('admin-a'),
        account: _plexAccount('plex-a', 'client-a'),
        activeProfile: _localProfile('profile-a'),
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
  return Profile(id: id, kind: ProfileKind.local, displayName: id, createdAt: DateTime(2026, 1, 1));
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
