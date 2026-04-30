import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexHomeUser _user(String uuid, {bool admin = false, bool protected = false, String name = 'User'}) {
  return PlexHomeUser(
    id: 0,
    uuid: uuid,
    title: name,
    username: null,
    email: null,
    friendlyName: null,
    thumb: 'https://plex.tv/users/$uuid/avatar',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: protected,
  );
}

PlexAccountConnection _account(String id) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'tok-$id',
    clientIdentifier: 'cid-$id',
    accountLabel: 'acct-$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late AppDatabase db;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late StorageService storage;
  late PlexHomeService service;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connections = ConnectionRegistry(db);
    profileConnections = ProfileConnectionRegistry(db);
    storage = await StorageService.getInstance();
  });

  tearDown(() async {
    await service.dispose();
    await db.close();
  });

  group('PlexHomeService', () {
    test('refresh fetches and caches users for a connection', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('admin-uuid', admin: true), _user('kid-uuid', protected: true)],
      );
      final acct = _account('plex.dev1');
      await connections.upsert(acct);
      await service.refresh(acct);

      expect(service.current[acct.id], hasLength(2));
      expect(service.current[acct.id]!.firstWhere((u) => u.admin).uuid, 'admin-uuid');
    });

    test('refresh persists users to SharedPreferences', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev2');
      await connections.upsert(acct);
      await service.refresh(acct);

      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNotNull);
    });

    test('start hydrates the cache from SharedPreferences', () async {
      // Pre-seed the cache.
      await storage.savePlexHomeUsersCache('plex.dev3', [_user('seeded-uuid').toJson()]);
      final acct = _account('plex.dev3');
      await connections.upsert(acct);

      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [], // background refresh returns empty
      );
      await service.start();

      // Cache hydrated synchronously from SharedPreferences before any
      // background fetch resolves.
      expect(service.current[acct.id], hasLength(1));
      expect(service.current[acct.id]!.first.uuid, 'seeded-uuid');
    });

    test('concurrent start calls await the same in-flight startup', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );

      final first = service.start();
      final second = service.start();

      expect(identical(first, second), isTrue);
      await second;
    });

    test('removing a Plex connection clears its cache slot', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev4');
      await connections.upsert(acct);
      await service.refresh(acct);
      expect(service.current[acct.id], isNotNull);

      await service.start();
      // Wait for the service's own stream to emit a snapshot without
      // `acct.id` instead of a fixed-duration sleep — deterministic on slow
      // CI runners and matches when the listener actually settles, not just
      // 30ms after the remove() future resolves.
      final cleared = expectLater(
        service.stream,
        emitsThrough(predicate<Map<String, List<PlexHomeUser>>>((m) => !m.containsKey(acct.id))),
      );
      await connections.remove(acct.id);
      await cleared;

      expect(service.current[acct.id], isNull);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
    });

    test('materializeFirstPlexHome wraps the first cached account', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [
          _user('admin-uuid', admin: true, name: 'Admin'),
          _user('kid-uuid', name: 'Kid'),
        ],
      );
      final acct = _account('plex.dev5');
      await connections.upsert(acct);
      await service.refresh(acct);

      final home = await service.materializeFirstPlexHome();
      expect(home, isNotNull);
      expect(home!.users, hasLength(2));
      expect(home.adminUser?.uuid, 'admin-uuid');
    });

    test('materializeFirstPlexHome waits for startup cache hydration', () async {
      await storage.savePlexHomeUsersCache('plex.dev-cached', [_user('cached-admin', admin: true).toJson()]);
      final acct = _account('plex.dev-cached');
      await connections.upsert(acct);
      final refreshBlocker = Completer<List<PlexHomeUser>>();
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) => refreshBlocker.future,
      );
      addTearDown(() {
        if (!refreshBlocker.isCompleted) refreshBlocker.complete(const []);
      });

      final home = await service.materializeFirstPlexHome();

      expect(home, isNotNull);
      expect(home!.adminUser?.uuid, 'cached-admin');
    });

    test('clearAll wipes both memory and disk caches', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev6');
      await connections.upsert(acct);
      await service.refresh(acct);

      await service.clearAll();
      expect(service.current, isEmpty);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
    });
  });
}
