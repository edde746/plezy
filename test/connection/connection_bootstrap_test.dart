import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_bootstrap.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/services/server_registry.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late ConnectionRegistry registry;
  late ProfileRegistry profileRegistry;
  late StorageService storage;
  late ServerRegistry serverRegistry;
  late ConnectionBootstrap bootstrap;
  late List<PlexHomeUser> fetchedHomeUsers;
  late Map<String, dynamic>? fetchedUserInfo;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ConnectionRegistry(db);
    profileRegistry = ProfileRegistry(db);
    storage = await StorageService.getInstance();
    serverRegistry = ServerRegistry(storage);
    fetchedHomeUsers = const [];
    fetchedUserInfo = null;
    bootstrap = ConnectionBootstrap(
      storage: storage,
      connectionRegistry: registry,
      serverRegistry: serverRegistry,
      profileRegistry: profileRegistry,
      plexHomeUserFetcher: (_) async => fetchedHomeUsers,
      plexUserInfoFetcher: (_) async => fetchedUserInfo ?? (throw StateError('user info unavailable')),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ConnectionBootstrap.migrateLegacyPlexAccount', () {
    test('returns null when no legacy Plex token is stored', () async {
      final result = await bootstrap.migrateLegacyPlexAccount();
      expect(result, isNull);
      expect(await registry.list(), isEmpty);
    });

    test('migrates a stored Plex token into a PlexAccountConnection', () async {
      await storage.prefs.setString('plex_token', 'legacy-token-abc');

      final result = await bootstrap.migrateLegacyPlexAccount();

      expect(result, isA<PlexAccountConnection>());
      expect(result!.accountToken, 'legacy-token-abc');
      // The clientIdentifier comes from StorageService — non-empty after
      // first call to getOrCreateClientIdentifier.
      expect(result.clientIdentifier, isNotEmpty);
      // Account label falls back to "Plex" when the user-info call fails
      // (no network in the test environment).
      expect(result.accountLabel, isNotEmpty);

      // The migrated row is now in the registry.
      final stored = await registry.list();
      expect(stored.length, 1);
      expect(stored.single, isA<PlexAccountConnection>());
      expect((stored.single as PlexAccountConnection).accountToken, 'legacy-token-abc');
    });

    test('keeps the legacy plex_token until full bootstrap succeeds', () async {
      await storage.prefs.setString('plex_token', 'legacy-token-xyz');

      final first = await bootstrap.migrateLegacyPlexAccount();
      final second = await bootstrap.migrateLegacyPlexAccount();

      expect(first, isA<PlexAccountConnection>());
      // The token is cleared only after run() has also hydrated/selects a
      // virtual Plex profile. Until then, keeping it makes failed profile
      // hydration retryable.
      expect(second, isA<PlexAccountConnection>());
      expect(storage.prefs.getString('plex_token'), 'legacy-token-xyz');
      expect((await registry.list()).length, 1);
    });

    test('preserves stable id derived from the device clientIdentifier', () async {
      await storage.prefs.setString('plex_token', 'legacy-token-1');
      final clientId = await storage.getOrCreateClientIdentifier();
      final migrated = await bootstrap.migrateLegacyPlexAccount();

      expect(migrated!.id, 'plex.$clientId');
    });

    test('uses Plex account UUID for migrated connection id when available', () async {
      await storage.prefs.setString('plex_token', 'legacy-token-uuid');
      await storage.prefs.setString('client_identifier', 'device-client');
      fetchedUserInfo = {'uuid': 'account-uuid-1', 'username': 'edde'};

      final migrated = await bootstrap.migrateLegacyPlexAccount();

      expect(migrated!.id, 'plex.account-uuid-1');
      expect(migrated.clientIdentifier, 'device-client');
      expect(migrated.accountLabel, 'edde');
      final stored = await registry.list();
      expect(stored.single.id, 'plex.account-uuid-1');
    });

    test('run promotes legacy Plex Home UUID and copies user cache to connection scope', () async {
      await storage.prefs.setString('plex_token', 'legacy-token-home');
      await storage.prefs.setString('client_identifier', 'client-1');
      await storage.prefs.setString('servers_list', json.encode([_legacyPlexServerJson(accessToken: 'server-token')]));
      await storage.prefs.setString('current_user_uuid', 'home-user-1');
      await storage.prefs.setString(
        'home_users_cache',
        json.encode({
          'id': 1,
          'name': 'Home',
          'guestUserID': null,
          'guestUserUUID': '',
          'guestEnabled': false,
          'subscription': true,
          'users': [
            {
              'id': 10,
              'uuid': 'home-user-1',
              'title': 'Kid',
              'thumb': '',
              'hasPassword': false,
              'restricted': false,
              'updatedAt': null,
              'admin': false,
              'guest': false,
              'protected': false,
            },
          ],
        }),
      );

      await bootstrap.run();

      expect(storage.getActiveProfileId(), 'plex-home-plex.client-1-home-user-1');
      expect(storage.prefs.getString('plex_token'), isNull);
      expect(storage.prefs.getString('servers_list'), isNull);
      expect(storage.prefs.getString('current_user_uuid'), isNull);
      expect(storage.prefs.getString('home_users_cache'), isNull);

      final migrated = storage.getPlexHomeUsersCacheJson('plex.client-1');
      expect(migrated, isNotNull);
      final users = json.decode(migrated!) as List<dynamic>;
      expect(users.single, containsPair('uuid', 'home-user-1'));
    });

    test('run selects fetched Plex Home admin as virtual active profile when no legacy UUID exists', () async {
      await storage.prefs.setString('plex_token', 'legacy-owner-token');
      await storage.prefs.setString('client_identifier', 'client-owner');
      fetchedHomeUsers = [
        PlexHomeUser(
          id: 10,
          uuid: 'managed-user',
          title: 'Managed',
          thumb: '',
          hasPassword: false,
          restricted: true,
          updatedAt: null,
          admin: false,
          guest: false,
          protected: false,
        ),
        PlexHomeUser(
          id: 1,
          uuid: 'admin-user',
          title: 'Owner',
          thumb: '',
          hasPassword: false,
          restricted: false,
          updatedAt: null,
          admin: true,
          guest: false,
          protected: false,
        ),
      ];

      await bootstrap.run();

      expect(await profileRegistry.list(), isEmpty);
      expect(storage.getActiveProfileId(), 'plex-home-plex.client-owner-admin-user');
      final cached = storage.getPlexHomeUsersCacheJson('plex.client-owner');
      expect(cached, isNotNull);
      final users = json.decode(cached!) as List<dynamic>;
      expect(users.map((u) => (u as Map<String, dynamic>)['uuid']), containsAll(['managed-user', 'admin-user']));
    });

    test('run clears leftover legacy servers_list when migration was already marked done', () async {
      await storage.prefs.setBool('profile_migration_v1_done', true);
      await storage.prefs.setString(
        'servers_list',
        json.encode([_legacyPlexServerJson(accessToken: 'plain-server-token')]),
      );

      await bootstrap.run();

      expect(storage.prefs.getString('servers_list'), isNull);
    });

    test('run retries later when Plex Home profiles cannot be hydrated', () async {
      await storage.prefs.setString('plex_token', 'legacy-owner-token');
      await storage.prefs.setString('client_identifier', 'client-owner');

      await bootstrap.run();

      expect(storage.prefs.getBool('profile_migration_v1_done'), isNull);
      expect(storage.prefs.getString('plex_token'), 'legacy-owner-token');
      expect(storage.getActiveProfileId(), isNull);
      expect(await registry.list(), isEmpty);
      expect(await profileRegistry.list(), isEmpty);
    });
  });
}

Map<String, dynamic> _legacyPlexServerJson({required String accessToken}) {
  return {
    'name': 'Plex',
    'clientIdentifier': 'server-1',
    'accessToken': accessToken,
    'owned': true,
    'connections': [
      {'protocol': 'http', 'address': '127.0.0.1', 'port': 32400, 'uri': 'http://127.0.0.1:32400'},
    ],
  };
}
