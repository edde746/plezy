import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late JellyfinApiCache cache;

  setUp(() {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    cache = JellyfinApiCache.instance;
  });

  tearDown(() async {
    await db.close();
  });

  // Minimal Jellyfin BaseItemDto-shaped payload. The mapper only needs Id +
  // Type + Name to produce a valid MediaItem; the rest is pass-through.
  Map<String, dynamic> jellyfinItem({String id = 'item-1', String name = 'Hello', String type = 'Movie'}) {
    return {'Id': id, 'Type': type, 'Name': name};
  }

  // Insert a Jellyfin connection row with the production-shape id
  // (`${machineId}/$userId`) and configJson containing the bare serverName.
  Future<void> insertJellyfinConnection({
    required String machineId,
    required String userId,
    required String serverName,
    String accessToken = 'token',
  }) async {
    await db
        .into(db.connections)
        .insert(
          ConnectionsCompanion.insert(
            id: '$machineId/$userId',
            kind: 'jellyfin',
            displayName: 'someone · $serverName',
            configJson: jsonEncode({
              'baseUrl': 'http://example.lan',
              'serverName': serverName,
              'serverMachineId': machineId,
              'userId': userId,
              'userName': 'someone',
              'accessToken': accessToken,
              'deviceId': 'device',
            }),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  // Cache rows are written by [JellyfinClient] under
  // `serverId:/Users/{userId}/Items/{itemId}` — mirror the shape exactly so
  // we exercise the same lookup pattern.
  Future<void> putItemRow({
    required String serverId,
    required String userId,
    required String itemId,
    Map<String, dynamic>? data,
    bool pinned = false,
  }) async {
    final payload = data ?? jellyfinItem(id: itemId);
    await db
        .into(db.apiCache)
        .insert(
          ApiCacheCompanion.insert(
            cacheKey: '$serverId:/Users/$userId/Items/$itemId',
            data: jsonEncode(payload),
            pinned: Value(pinned),
          ),
        );
  }

  group('getMetadata', () {
    test('resolves serverName via the Jellyfin compound connection id (machineId/userId)', () async {
      // Production stores connection rows under `${machineId}/$userId` while
      // [JellyfinClient.serverId] returns the bare machineId. The cache
      // lookup must reconcile the mismatch — otherwise downloaded Jellyfin
      // items lose their metadata after an app reload.
      const machineId = 'jf-machine';
      const userId = 'jf-user';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'My Jellyfin');
      await putItemRow(
        serverId: machineId,
        userId: userId,
        itemId: 'item-1',
        data: jellyfinItem(id: 'item-1', name: 'A Movie'),
      );

      final meta = await cache.getMetadata(machineId, 'item-1');
      expect(meta, isNotNull, reason: 'cache lookup must succeed despite id-format mismatch');
      expect(meta!.title, 'A Movie');
      expect(meta.serverId, machineId);
      expect(meta.serverName, 'My Jellyfin', reason: 'serverName is the bare value, not the compound displayName');
    });

    test('returns null when the connection row is missing', () async {
      // Cache row exists but no Connections row → lookup can't resolve serverName.
      await putItemRow(serverId: 'orphan', userId: 'u', itemId: 'item-1');
      expect(await cache.getMetadata('orphan', 'item-1'), isNull);
    });

    test('absolutizes image paths against the connection baseUrl + accessToken', () async {
      // Regression: cached items used to skip absolutization, leaking raw
      // `/Items/.../Images/Primary?tag=...` paths into the download manager
      // → Cronet rejected with net::ERR_INVALID_URL.
      const machineId = 'jf-machine';
      const userId = 'jf-user';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'My Jellyfin');
      await putItemRow(
        serverId: machineId,
        userId: userId,
        itemId: 'item-1',
        data: {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': 'A Movie',
          'ImageTags': {'Primary': 'tag-abc', 'Logo': 'tag-logo'},
        },
      );

      final meta = await cache.getMetadata(machineId, 'item-1');
      expect(meta, isNotNull);
      expect(meta!.thumbPath, 'http://example.lan/Items/item-1/Images/Primary?tag=tag-abc&api_key=token');
      expect(meta.clearLogoPath, 'http://example.lan/Items/item-1/Images/Logo?tag=tag-logo&api_key=token');
    });

    test('absolutizes image paths with decrypted accessToken', () async {
      const machineId = 'jf-machine';
      const userId = 'jf-user';
      await insertJellyfinConnection(
        machineId: machineId,
        userId: userId,
        serverName: 'My Jellyfin',
        accessToken: await CredentialVault.protect('secret-token'),
      );
      await putItemRow(
        serverId: machineId,
        userId: userId,
        itemId: 'item-1',
        data: {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': 'A Movie',
          'ImageTags': {'Primary': 'tag-abc'},
        },
      );

      final meta = await cache.getMetadata(machineId, 'item-1');
      expect(meta, isNotNull);
      expect(meta!.thumbPath, contains('api_key=secret-token'));
      expect(meta.thumbPath, isNot(contains('enc:v1:')));
    });

    test('scopes UserData by Jellyfin compound connection id', () async {
      const machineId = 'jf-machine';
      await insertJellyfinConnection(machineId: machineId, userId: 'user-a', serverName: 'Shared JF');
      await insertJellyfinConnection(machineId: machineId, userId: 'user-b', serverName: 'Shared JF');
      await putItemRow(
        serverId: '$machineId/user-a',
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For A'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );
      await putItemRow(
        serverId: '$machineId/user-b',
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For B'),
          'UserData': {'Played': true, 'PlayCount': 1},
        },
      );

      final a = await cache.getMetadata('$machineId/user-a', 'item-1');
      final b = await cache.getMetadata('$machineId/user-b', 'item-1');

      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.serverId, machineId);
      expect(a.isWatched, isFalse);
      expect(a.title, 'For A');
      expect(b!.serverId, machineId);
      expect(b.isWatched, isTrue);
      expect(b.title, 'For B');
    });
  });

  group('getAllPinnedMetadata', () {
    test('aggregates pinned items keyed by globalKey across multiple users on the same server', () async {
      // Same machineId, two users → two connection rows. Both pin items.
      // Both should resolve via the prefix match.
      const machineId = 'jf-machine';
      await insertJellyfinConnection(machineId: machineId, userId: 'user-a', serverName: 'Shared JF');
      await insertJellyfinConnection(machineId: machineId, userId: 'user-b', serverName: 'Shared JF');

      await putItemRow(serverId: machineId, userId: 'user-a', itemId: 'item-1', pinned: true);
      await putItemRow(serverId: machineId, userId: 'user-b', itemId: 'item-2', pinned: true);
      // Unpinned row is filtered out.
      await putItemRow(serverId: machineId, userId: 'user-a', itemId: 'item-3');

      final pinned = await cache.getAllPinnedMetadata();
      expect(pinned.keys.toSet(), {'$machineId:item-1', '$machineId:item-2'});
      expect(pinned['$machineId:item-1']!.serverName, 'Shared JF');
    });

    test('skips pinned rows whose serverId has no matching connection', () async {
      await putItemRow(serverId: 'orphan-machine', userId: 'u', itemId: 'lost', pinned: true);
      expect(await cache.getAllPinnedMetadata(), isEmpty);
    });

    test('keeps same-server Jellyfin users addressable by compound pinned keys', () async {
      const machineId = 'jf-machine';
      await insertJellyfinConnection(machineId: machineId, userId: 'user-a', serverName: 'Shared JF');
      await insertJellyfinConnection(machineId: machineId, userId: 'user-b', serverName: 'Shared JF');
      await putItemRow(
        serverId: '$machineId/user-a',
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For A'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
        pinned: true,
      );
      await putItemRow(
        serverId: '$machineId/user-b',
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For B'),
          'UserData': {'Played': true, 'PlayCount': 1},
        },
        pinned: true,
      );

      final pinned = await cache.getAllPinnedMetadata();
      expect(pinned['$machineId:item-1'], isNull);
      expect(pinned['$machineId/user-a:item-1']!.title, 'For A');
      expect(pinned['$machineId/user-b:item-1']!.title, 'For B');
      expect(pinned['$machineId/user-a:item-1']!.serverId, machineId);
      expect(pinned['$machineId/user-b:item-1']!.serverId, machineId);
    });
  });

  group('pinForOffline', () {
    test('pins by user-segment wildcard so a single call covers any user', () async {
      const machineId = 'jf-machine';
      await putItemRow(serverId: machineId, userId: 'user-a', itemId: 'item-1');
      await putItemRow(serverId: machineId, userId: 'user-b', itemId: 'item-1');
      await putItemRow(serverId: machineId, userId: 'user-a', itemId: 'item-2');

      await cache.pinForOffline(machineId, 'item-1');

      // Both per-user rows for item-1 get pinned, item-2 stays unpinned.
      final rows = await db.select(db.apiCache).get();
      final pinnedKeys = rows.where((r) => r.pinned).map((r) => r.cacheKey).toSet();
      expect(pinnedKeys, {'$machineId:/Users/user-a/Items/item-1', '$machineId:/Users/user-b/Items/item-1'});
    });

    test('pins only the requested compound Jellyfin user scope', () async {
      const machineId = 'jf-machine';
      await putItemRow(serverId: '$machineId/user-a', userId: 'user-a', itemId: 'item-1');
      await putItemRow(serverId: '$machineId/user-b', userId: 'user-b', itemId: 'item-1');

      await cache.pinForOffline('$machineId/user-a', 'item-1');

      final rows = await db.select(db.apiCache).get();
      final pinnedKeys = rows.where((r) => r.pinned).map((r) => r.cacheKey).toSet();
      expect(pinnedKeys, {'$machineId/user-a:/Users/user-a/Items/item-1'});
    });
  });

  group('applyWatchState', () {
    test('mutates only the requested compound Jellyfin user scope', () async {
      const machineId = 'jf-machine';
      await putItemRow(
        serverId: '$machineId/user-a',
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );
      await putItemRow(
        serverId: '$machineId/user-b',
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );

      await cache.applyWatchState(serverId: '$machineId/user-a', itemId: 'item-1', isWatched: true);

      final rows = await db.select(db.apiCache).get();
      final byKey = {for (final row in rows) row.cacheKey: jsonDecode(row.data) as Map<String, dynamic>};
      expect((byKey['$machineId/user-a:/Users/user-a/Items/item-1']!['UserData'] as Map)['Played'], isTrue);
      expect((byKey['$machineId/user-b:/Users/user-b/Items/item-1']!['UserData'] as Map)['Played'], isFalse);
    });
  });
}
