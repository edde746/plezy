import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/user_profile_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('UserProfileProvider (settings-only)', () {
    test('starts with all-null state and no error', () {
      final p = UserProfileProvider();
      expect(p.profileSettings, isNull);
      expect(p.isLoading, isFalse);
      expect(p.error, isNull);
      p.dispose();
    });

    test('refreshProfileSettings without a stored token is a no-op', () async {
      final p = UserProfileProvider();
      var notified = 0;
      p.addListener(() => notified++);
      await p.refreshProfileSettings();
      // No token → no API call → no notify, no error.
      expect(notified, 0);
      expect(p.profileSettings, isNull);
      p.dispose();
    });

    test('logout without initialization is safe', () async {
      final p = UserProfileProvider();
      await p.logout();
      expect(p.profileSettings, isNull);
      expect(p.error, isNull);
      p.dispose();
    });

    test('safeNotifyListeners after dispose does not throw', () async {
      final p = UserProfileProvider();
      p.dispose();
      await p.logout();
    });

    test('settings connection follows the profile default row', () async {
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
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final profile = Profile(
        id: 'local-owner',
        kind: ProfileKind.local,
        displayName: 'Owner',
        createdAt: DateTime(2026, 1, 1),
      );
      final plex = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'plex-token',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex',
        createdAt: DateTime(2026, 1, 1),
      );
      final jellyfin = JellyfinConnection(
        id: 'jf-machine/user-a',
        baseUrl: 'https://jf.example.com',
        serverName: 'Jellyfin',
        serverMachineId: 'jf-machine',
        userId: 'user-a',
        userName: 'User A',
        accessToken: 'jf-token',
        deviceId: 'device-a',
        createdAt: DateTime(2026, 1, 1),
      );
      await profiles.upsert(profile);
      await connections.upsert(plex);
      await connections.upsert(jellyfin);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: profile.id,
          connectionId: plex.id,
          userToken: 'plex-user-token',
          userIdentifier: 'plex-user',
          isDefault: true,
        ),
        makeDefault: true,
      );
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
      );
      await storage.setActiveProfileId(profile.id);
      await active.initialize();

      final p = UserProfileProvider()
        ..attach(
          connections: connections,
          activeProfile: active,
          profileConnections: profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(await p.debugResolveActiveSettingsConnectionForTesting(), isA<PlexAccountConnection>());

      await profileConnections.setDefault(profile.id, jellyfin.id);

      expect(await p.debugResolveActiveSettingsConnectionForTesting(), isA<JellyfinConnection>());
    });

    test('watches Plex Home profile connection rows', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_homeUser(uuid: 'home-user-a', title: 'Home User')],
      );
      final active = ActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      );
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final account = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'account-token-a',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex A',
        createdAt: DateTime(2026, 1, 1),
      );
      await connections.upsert(account);
      await plexHome.refresh(account);
      await storage.setActiveProfileId(plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: 'home-user-a'));
      await active.initialize();

      final p = UserProfileProvider()
        ..attach(
          connections: connections,
          activeProfile: active,
          profileConnections: profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(p.debugWatchedProfileConnectionProfileId, active.activeId);
    });

    test('Plex token fallback uses the selected local profile account', () async {
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
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });

      final profile = Profile(
        id: 'local-owner',
        kind: ProfileKind.local,
        displayName: 'Owner',
        createdAt: DateTime(2026, 1, 1),
      );
      final accountA = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'wrong-owner-token',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex A',
        createdAt: DateTime(2026, 1, 1),
      );
      final accountB = PlexAccountConnection(
        id: 'plex-b',
        accountToken: 'selected-owner-token',
        clientIdentifier: 'client-b',
        accountLabel: 'Plex B',
        createdAt: DateTime(2026, 1, 1),
      );
      await profiles.upsert(profile);
      await connections.upsert(accountA);
      await connections.upsert(accountB);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: profile.id,
          connectionId: accountB.id,
          userIdentifier: 'home-user-b',
          isDefault: true,
        ),
        makeDefault: true,
      );
      await storage.setActiveProfileId(profile.id);
      await active.initialize();

      final p = UserProfileProvider()
        ..attach(
          connections: connections,
          activeProfile: active,
          profileConnections: profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(await p.debugResolveActivePlexUserTokenForTesting(), 'selected-owner-token');
    });
  });
}

PlexHomeUser _homeUser({required String uuid, required String title}) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: title,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: true,
    guest: false,
    protected: false,
  );
}
