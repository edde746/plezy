import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/jellyfin/bonfire_profile.dart';
import 'package:plezy/profiles/bonfire_service.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfin(String id) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://jellyfin.example.net',
    serverName: 'Home Media',
    serverMachineId: 'machine-$id',
    userId: 'master-$id',
    userName: 'dalgibbard',
    accessToken: 'master-token-$id',
    deviceId: 'device-$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

BonfireProfile _profile(String userId, {bool requiresPin = false, bool isMaster = false}) {
  return BonfireProfile.fromJson({
    'profileUserId': userId,
    'profileName': 'Profile $userId',
    'masterUserId': 'master-1',
    'requiresPin': requiresPin,
    'isMaster': isMaster,
  });
}

void main() {
  setUp(() => resetSharedPreferencesForTest());

  group('BonfireProfileService', () {
    test('hydrate paints the picker from the on-disk cache without live calls', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      await connections.upsert(_jellyfin('jf-1'));
      await storage.setBonfireProfilesCacheJson(
        'machine-jf-1',
        jsonEncode(const [
          {'profileUserId': 'u-kids', 'profileName': 'Kids', 'masterUserId': 'm-1', 'requiresPin': true},
          {'profileUserId': 'u-movies', 'profileName': 'Movies', 'masterUserId': 'm-1'},
        ]),
      );

      var fetcherCalls = 0;
      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async {
          fetcherCalls++;
          return const [];
        },
      );
      addTearDown(service.dispose);

      await service.hydrate();
      expect(fetcherCalls, 0);
      expect(service.current['machine-jf-1']!.map((p) => p.profileName), ['Kids', 'Movies']);
      expect(service.current['machine-jf-1']!.first.requiresPin, isTrue);
    });

    test('refreshConnection fetches live, updates the snapshot, and persists the cache', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      await connections.upsert(_jellyfin('jf-1'));

      final requested = <String>[];
      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async {
          requested.add(conn.id);
          return [_profile('u-adult'), _profile('u-kids', requiresPin: true)];
        },
      );
      addTearDown(service.dispose);

      await service.refreshConnection('jf-1');
      expect(requested, ['jf-1']);
      expect(service.current['machine-jf-1']!.length, 2);
      final cached = storage.getBonfireProfilesCacheJson('machine-jf-1');
      expect(cached, isNotNull);
      expect(cached!.contains('u-kids'), isTrue);
    });

    test('a server without the plugin (fetcher null) yields no profiles and clears stale cache', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      await connections.upsert(_jellyfin('jf-1'));
      await storage.setBonfireProfilesCacheJson(
          'machine-jf-1', jsonEncode([{'profileUserId': 'u-old', 'masterUserId': 'm'}]));

      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async => null,
      );
      addTearDown(service.dispose);

      await service.hydrate();
      await service.refreshConnection('jf-1');
      expect(service.current.containsKey('machine-jf-1'), isFalse);
      expect(storage.getBonfireProfilesCacheJson('machine-jf-1'), anyOf(isNull, isEmpty));
    });

    test('non-Jellyfin connections never hit the fetcher', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      await connections.upsert(
        PlexAccountConnection(
          id: 'plex-1',
          accountToken: 'tok',
          clientIdentifier: 'cid',
          accountLabel: 'acct',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      var fetcherCalls = 0;
      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async {
          fetcherCalls++;
          return const [];
        },
      );
      addTearDown(service.dispose);

      await service.refreshConnection('plex-1');
      expect(fetcherCalls, 0);
      expect(service.current, isEmpty);
    });

    test('stream emits the current snapshot immediately on subscribe', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      await connections.upsert(_jellyfin('jf-1'));

      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async => [_profile('u-kids')],
      );
      addTearDown(service.dispose);

      await service.refreshConnection('jf-1');
      final snapshot = await service.stream.first;
      expect(snapshot['machine-jf-1']!.single.profileUserId, 'u-kids');
    });

    test('profile entries are keyed per machine: a Bonfire child connection never forks the list', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final connections = ConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      final raw = _jellyfin('jf-1');
      // The binder registers Bonfire children as compound-id copies of the
      // parent connection. If those leaked into the snapshot the picker would
      // rediscover the household under a caller-dependent id on every switch.
      await connections.upsert(raw);
      await connections.upsert(
        raw.copyWith(
          id: 'jf-1/u-kids',
          accessToken: 'child-token',
          userId: 'u-kids',
          userName: 'Kids',
        ),
      );

      final vehicles = <String>[];
      final service = BonfireProfileService(
        connections: connections,
        storage: storage,
        bonfireProfileFetcher: (conn) async {
          vehicles.add(conn.id);
          // Bonfire's /list always includes the master profile; a list that
          // contains it proves the vehicle token could address the household.
          return [_profile('u-master', isMaster: true), _profile('u-kids')];
        },
      );
      addTearDown(service.dispose);

      await service.refreshConnection('jf-1');
      final snapshot = service.current;
      expect(snapshot.keys, ['machine-jf-1']);
      expect(snapshot['machine-jf-1']!.map((p) => p.profileUserId), ['u-master', 'u-kids']);
      // The raw login connection (id == machine id) is the fetch vehicle —
      // its master token addresses the whole household.
      await service.start();
      expect(vehicles.every((id) => id == 'jf-1'), isTrue);
    });
  });
}
