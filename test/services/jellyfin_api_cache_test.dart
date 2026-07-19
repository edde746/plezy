import 'dart:async';
import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
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
    required ServerId serverId,
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
        serverId: ServerId(machineId),
        userId: userId,
        itemId: 'item-1',
        data: jellyfinItem(id: 'item-1', name: 'A Movie'),
      );

      final meta = await cache.getMetadata(ServerId(machineId), 'item-1');
      expect(meta, isNotNull, reason: 'cache lookup must succeed despite id-format mismatch');
      expect(meta!.title, 'A Movie');
      expect(meta.serverId, machineId);
      expect(meta.serverName, 'My Jellyfin', reason: 'serverName is the bare value, not the compound displayName');
    });

    test('returns null when the connection row is missing', () async {
      // Cache row exists but no Connections row → lookup can't resolve serverName.
      await putItemRow(serverId: ServerId('orphan'), userId: 'u', itemId: 'item-1');
      expect(await cache.getMetadata(ServerId('orphan'), 'item-1'), isNull);
    });

    test('absolutizes image paths against the connection baseUrl + accessToken', () async {
      // Regression: cached items used to skip absolutization, leaking raw
      // `/Items/.../Images/Primary?tag=...` paths into the download manager
      // → Cronet rejected with net::ERR_INVALID_URL.
      const machineId = 'jf-machine';
      const userId = 'jf-user';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'My Jellyfin');
      await putItemRow(
        serverId: ServerId(machineId),
        userId: userId,
        itemId: 'item-1',
        data: {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': 'A Movie',
          'ImageTags': {'Primary': 'tag-abc', 'Logo': 'tag-logo'},
        },
      );

      final meta = await cache.getMetadata(ServerId(machineId), 'item-1');
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
        serverId: ServerId(machineId),
        userId: userId,
        itemId: 'item-1',
        data: {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': 'A Movie',
          'ImageTags': {'Primary': 'tag-abc'},
        },
      );

      final meta = await cache.getMetadata(ServerId(machineId), 'item-1');
      expect(meta, isNotNull);
      expect(meta!.thumbPath, contains('api_key=secret-token'));
      expect(meta.thumbPath, isNot(contains('enc:v1:')));
    });

    test('scopes UserData by Jellyfin compound connection id', () async {
      const machineId = 'jf-machine';
      await insertJellyfinConnection(machineId: machineId, userId: 'user-a', serverName: 'Shared JF');
      await insertJellyfinConnection(machineId: machineId, userId: 'user-b', serverName: 'Shared JF');
      await putItemRow(
        serverId: ServerId('$machineId/user-a'),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For A'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );
      await putItemRow(
        serverId: ServerId('$machineId/user-b'),
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For B'),
          'UserData': {'Played': true, 'PlayCount': 1},
        },
      );

      final a = await cache.getMetadata(ServerId('$machineId/user-a'), 'item-1');
      final b = await cache.getMetadata(ServerId('$machineId/user-b'), 'item-1');

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

      await putItemRow(serverId: ServerId(machineId), userId: 'user-a', itemId: 'item-1', pinned: true);
      await putItemRow(serverId: ServerId(machineId), userId: 'user-b', itemId: 'item-2', pinned: true);
      // Unpinned row is filtered out.
      await putItemRow(serverId: ServerId(machineId), userId: 'user-a', itemId: 'item-3');

      final pinned = await cache.getAllPinnedMetadata();
      expect(pinned.keys.toSet(), {'$machineId:item-1', '$machineId:item-2'});
      expect(pinned['$machineId:item-1']!.serverName, 'Shared JF');
    });

    test('skips pinned rows whose serverId has no matching connection', () async {
      await putItemRow(serverId: ServerId('orphan-machine'), userId: 'u', itemId: 'lost', pinned: true);
      expect(await cache.getAllPinnedMetadata(), isEmpty);
    });

    test('keeps same-server Jellyfin users addressable by compound pinned keys', () async {
      const machineId = 'jf-machine';
      await insertJellyfinConnection(machineId: machineId, userId: 'user-a', serverName: 'Shared JF');
      await insertJellyfinConnection(machineId: machineId, userId: 'user-b', serverName: 'Shared JF');
      await putItemRow(
        serverId: ServerId('$machineId/user-a'),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1', name: 'For A'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
        pinned: true,
      );
      await putItemRow(
        serverId: ServerId('$machineId/user-b'),
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
      await putItemRow(serverId: ServerId(machineId), userId: 'user-a', itemId: 'item-1');
      await putItemRow(serverId: ServerId(machineId), userId: 'user-b', itemId: 'item-1');
      await putItemRow(serverId: ServerId(machineId), userId: 'user-a', itemId: 'item-2');

      await cache.pinForOffline(ServerId(machineId), 'item-1');

      // Both per-user rows for item-1 get pinned, item-2 stays unpinned.
      final rows = await db.select(db.apiCache).get();
      final pinnedKeys = rows.where((r) => r.pinned).map((r) => r.cacheKey).toSet();
      expect(pinnedKeys, {'$machineId:/Users/user-a/Items/item-1', '$machineId:/Users/user-b/Items/item-1'});
    });

    test('pins only the requested compound Jellyfin user scope', () async {
      const machineId = 'jf-machine';
      await putItemRow(serverId: ServerId('$machineId/user-a'), userId: 'user-a', itemId: 'item-1');
      await putItemRow(serverId: ServerId('$machineId/user-b'), userId: 'user-b', itemId: 'item-1');

      await cache.pinForOffline(ServerId('$machineId/user-a'), 'item-1');

      final rows = await db.select(db.apiCache).get();
      final pinnedKeys = rows.where((r) => r.pinned).map((r) => r.cacheKey).toSet();
      expect(pinnedKeys, {'$machineId/user-a:/Users/user-a/Items/item-1'});
    });
  });

  group('applyWatchState', () {
    test('mutates only the requested compound Jellyfin user scope', () async {
      const machineId = 'jf-machine';
      await putItemRow(
        serverId: ServerId('$machineId/user-a'),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );
      await putItemRow(
        serverId: ServerId('$machineId/user-b'),
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );

      await cache.applyWatchState(serverId: ServerId('$machineId/user-a'), itemId: 'item-1', isWatched: true);

      final rows = await db.select(db.apiCache).get();
      final byKey = {for (final row in rows) row.cacheKey: jsonDecode(row.data) as Map<String, dynamic>};
      expect((byKey['$machineId/user-a:/Users/user-a/Items/item-1']!['UserData'] as Map)['Played'], isTrue);
      expect((byKey['$machineId/user-b:/Users/user-b/Items/item-1']!['UserData'] as Map)['Played'], isFalse);
    });

    test('bare Jellyfin server id updates the only cached user scope', () async {
      const machineId = 'jf-machine';
      await putItemRow(
        serverId: ServerId(machineId),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'Played': false, 'PlayCount': 0},
        },
      );

      await cache.applyWatchState(serverId: ServerId(machineId), itemId: 'item-1', isWatched: true);

      final row = await db.select(db.apiCache).getSingle();
      expect((jsonDecode(row.data)['UserData'] as Map)['Played'], isTrue);
    });

    test('bare Jellyfin server id skips ambiguous multi-user cache updates', () async {
      const machineId = 'jf-machine';
      for (final userId in ['user-a', 'user-b']) {
        await putItemRow(
          serverId: ServerId(machineId),
          userId: userId,
          itemId: 'item-1',
          data: {
            ...jellyfinItem(id: 'item-1'),
            'UserData': {'Played': false, 'PlayCount': 0},
          },
        );
      }

      await cache.applyWatchState(serverId: ServerId(machineId), itemId: 'item-1', isWatched: true);

      final rows = await db.select(db.apiCache).get();
      for (final row in rows) {
        expect((jsonDecode(row.data)['UserData'] as Map)['Played'], isFalse);
      }
    });
  });

  group('applyFavoriteState', () {
    test('concurrent favorite and watch-state patches preserve both fields', () async {
      const scopeId = 'jf-machine/user-a';
      await putItemRow(
        serverId: ServerId(scopeId),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false, 'Played': false, 'PlayCount': 0},
        },
        pinned: true,
      );
      final start = Completer<void>();

      final watchPatch = () async {
        await start.future;
        await cache.applyWatchState(serverId: ServerId(scopeId), itemId: 'item-1', isWatched: true);
      }();
      final favoritePatch = () async {
        await start.future;
        await cache.applyFavoriteState(serverId: ServerId(scopeId), itemId: 'item-1', isFavorite: true);
      }();
      start.complete();
      await Future.wait([watchPatch, favoritePatch]);

      final row = await db.select(db.apiCache).getSingle();
      final userData = jsonDecode(row.data)['UserData'] as Map<String, dynamic>;
      expect(userData['Played'], isTrue);
      expect(userData['IsFavorite'], isTrue);
      expect(row.pinned, isTrue);
    });

    test('fetch commit ordering accepts older-first and ignores an uncommitted newer fetch', () async {
      final serverId = ServerId('jf-machine/user-a');
      const orderedItemId = 'ordered-item';
      const orderedEndpoint = '/Users/user-a/Items/$orderedItemId';
      final older = cache.beginItemFetch(serverId, orderedItemId);
      final newer = cache.beginItemFetch(serverId, orderedItemId);

      await cache.putFetchedItem(
        serverId: serverId,
        itemId: orderedItemId,
        endpoint: orderedEndpoint,
        favoriteGenerationAtStart: older.favoriteGeneration,
        fetchSequence: older.fetchSequence,
        data: {
          ...jellyfinItem(id: orderedItemId),
          'UserData': {'IsFavorite': true},
        },
      );
      await cache.putFetchedItem(
        serverId: serverId,
        itemId: orderedItemId,
        endpoint: orderedEndpoint,
        favoriteGenerationAtStart: newer.favoriteGeneration,
        fetchSequence: newer.fetchSequence,
        data: {
          ...jellyfinItem(id: orderedItemId),
          'UserData': {'IsFavorite': false},
        },
      );

      var cached = await cache.get(serverId, orderedEndpoint);
      expect((cached!['UserData'] as Map)['IsFavorite'], isFalse);

      const failedNewerItemId = 'failed-newer-item';
      const failedNewerEndpoint = '/Users/user-a/Items/$failedNewerItemId';
      final usableOlder = cache.beginItemFetch(serverId, failedNewerItemId);
      cache.beginItemFetch(serverId, failedNewerItemId); // This newer request fails before committing.
      await cache.putFetchedItem(
        serverId: serverId,
        itemId: failedNewerItemId,
        endpoint: failedNewerEndpoint,
        favoriteGenerationAtStart: usableOlder.favoriteGeneration,
        fetchSequence: usableOlder.fetchSequence,
        data: {
          ...jellyfinItem(id: failedNewerItemId),
          'UserData': {'IsFavorite': true},
        },
      );

      cached = await cache.get(serverId, failedNewerEndpoint);
      expect((cached!['UserData'] as Map)['IsFavorite'], isTrue);
    });

    test('mutates only the requested user while preserving pinned metadata and other UserData', () async {
      const machineId = 'jf-machine';
      await putItemRow(
        serverId: ServerId('$machineId/user-a'),
        userId: 'user-a',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false, 'Played': true},
        },
        pinned: true,
      );
      await putItemRow(
        serverId: ServerId('$machineId/user-b'),
        userId: 'user-b',
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false, 'Played': false},
        },
      );

      await cache.applyFavoriteState(serverId: ServerId('$machineId/user-a'), itemId: 'item-1', isFavorite: true);

      var rows = await db.select(db.apiCache).get();
      var byKey = {for (final row in rows) row.cacheKey: row};
      final aKey = '$machineId/user-a:/Users/user-a/Items/item-1';
      final bKey = '$machineId/user-b:/Users/user-b/Items/item-1';
      var aUserData = jsonDecode(byKey[aKey]!.data)['UserData'] as Map<String, dynamic>;
      var bUserData = jsonDecode(byKey[bKey]!.data)['UserData'] as Map<String, dynamic>;
      expect(aUserData['IsFavorite'], isTrue);
      expect(aUserData['Played'], isTrue);
      expect(byKey[aKey]!.pinned, isTrue);
      expect(bUserData['IsFavorite'], isFalse);

      await cache.applyFavoriteState(serverId: ServerId('$machineId/user-a'), itemId: 'item-1', isFavorite: false);

      rows = await db.select(db.apiCache).get();
      byKey = {for (final row in rows) row.cacheKey: row};
      aUserData = jsonDecode(byKey[aKey]!.data)['UserData'] as Map<String, dynamic>;
      bUserData = jsonDecode(byKey[bKey]!.data)['UserData'] as Map<String, dynamic>;
      expect(aUserData['IsFavorite'], isFalse);
      expect(byKey[aKey]!.pinned, isTrue);
      expect(bUserData['IsFavorite'], isFalse);
    });

    test('bare Jellyfin server id skips ambiguous multi-user cache updates', () async {
      const machineId = 'jf-machine';
      for (final userId in ['user-a', 'user-b']) {
        await putItemRow(
          serverId: ServerId(machineId),
          userId: userId,
          itemId: 'item-1',
          data: {
            ...jellyfinItem(id: 'item-1'),
            'UserData': {'IsFavorite': false},
          },
        );
      }

      await cache.applyFavoriteState(serverId: ServerId(machineId), itemId: 'item-1', isFavorite: true);

      final rows = await db.select(db.apiCache).get();
      for (final row in rows) {
        expect((jsonDecode(row.data)['UserData'] as Map)['IsFavorite'], isFalse);
      }
    });

    test('malformed cached rows are skipped without throwing', () async {
      await db
          .into(db.apiCache)
          .insert(
            ApiCacheCompanion.insert(
              cacheKey: 'jf-machine/user-a:/Users/user-a/Items/item-1',
              data: 'not json',
              pinned: const Value(true),
            ),
          );

      await cache.applyFavoriteState(serverId: ServerId('jf-machine/user-a'), itemId: 'item-1', isFavorite: true);

      final row = await db.select(db.apiCache).getSingle();
      expect(row.data, 'not json');
      expect(row.pinned, isTrue);
    });
  });

  group('JellyfinClient favorite cache synchronization', () {
    test('an older same-generation GET cannot replace a newer committed response', () async {
      const machineId = 'jf-machine';
      const userId = 'user-a';
      const scopeId = '$machineId/$userId';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'Shared JF');
      await putItemRow(
        serverId: ServerId(scopeId),
        userId: userId,
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false},
        },
        pinned: true,
      );
      await cache.applyFavoriteState(serverId: ServerId(scopeId), itemId: 'item-1', isFavorite: true);
      final olderStarted = Completer<void>();
      final releaseOlder = Completer<void>();
      var getCount = 0;
      final client = testJellyfinClient(
        connection: testJellyfinConnection(machineId: machineId, userId: userId),
        handler: (_) async {
          getCount++;
          if (getCount == 1) {
            olderStarted.complete();
            await releaseOlder.future;
            return http.Response(
              jsonEncode({
                ...jellyfinItem(id: 'item-1'),
                'UserData': {'IsFavorite': true},
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              ...jellyfinItem(id: 'item-1'),
              'UserData': {'IsFavorite': false},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        },
      );
      addTearDown(() {
        if (!releaseOlder.isCompleted) releaseOlder.complete();
        client.close();
      });

      final olderFetch = client.fetchItem('item-1');
      await olderStarted.future;
      final newer = await client.fetchItem('item-1');
      releaseOlder.complete();
      final older = await olderFetch;

      final offline = await cache.getMetadata(ServerId(scopeId), 'item-1');
      expect(newer!.isFavorite, isFalse);
      expect(older!.isFavorite, isFalse);
      expect(offline!.isFavorite, isFalse);
      expect((await db.select(db.apiCache).getSingle()).pinned, isTrue);
    });

    test('a GET started before the mutation cannot overwrite the favorite cache patch', () async {
      const machineId = 'jf-machine';
      const userId = 'user-a';
      const scopeId = '$machineId/$userId';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'Shared JF');
      await putItemRow(
        serverId: ServerId(scopeId),
        userId: userId,
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false},
        },
        pinned: true,
      );
      final getStarted = Completer<void>();
      final releaseGet = Completer<void>();
      final client = testJellyfinClient(
        connection: testJellyfinConnection(machineId: machineId, userId: userId),
        handler: (request) async {
          if (request.method == 'GET') {
            getStarted.complete();
            await releaseGet.future;
            return http.Response(
              jsonEncode({
                ...jellyfinItem(id: 'item-1'),
                'UserData': {'IsFavorite': false},
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response('', 204);
        },
      );
      addTearDown(() {
        if (!releaseGet.isCompleted) releaseGet.complete();
        client.close();
      });
      const item = MediaItem.jellyfin(id: 'item-1', kind: MediaKind.movie, serverId: machineId);

      final staleFetch = client.fetchItem(item.id);
      await getStarted.future;
      await client.setFavorite(item, true);
      releaseGet.complete();

      final fetched = await staleFetch;
      final offline = await cache.getMetadata(ServerId(scopeId), item.id);
      expect(fetched!.isFavorite, isTrue);
      expect(offline!.isFavorite, isTrue);
      expect((await db.select(db.apiCache).getSingle()).pinned, isTrue);
    });

    test('successful favorite changes update pinned cached metadata in place', () async {
      const machineId = 'jf-machine';
      const userId = 'user-a';
      await insertJellyfinConnection(machineId: machineId, userId: userId, serverName: 'Shared JF');
      await putItemRow(
        serverId: ServerId('$machineId/$userId'),
        userId: userId,
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false, 'Played': true},
        },
        pinned: true,
      );
      final client = testJellyfinClient(
        connection: testJellyfinConnection(machineId: machineId, userId: userId),
        handler: (_) async => http.Response('', 204),
      );
      addTearDown(client.close);
      const item = MediaItem.jellyfin(id: 'item-1', kind: MediaKind.movie, serverId: machineId);

      await client.setFavorite(item, true);

      var cached = await cache.getMetadata(ServerId('$machineId/$userId'), 'item-1');
      expect(cached!.isFavorite, isTrue);
      expect(cached.isWatched, isTrue);
      expect((await db.select(db.apiCache).getSingle()).pinned, isTrue);

      await client.setFavorite(item, false);

      cached = await cache.getMetadata(ServerId('$machineId/$userId'), 'item-1');
      expect(cached!.isFavorite, isFalse);
      expect((await db.select(db.apiCache).getSingle()).pinned, isTrue);
    });

    test('failed favorite requests leave cached metadata unchanged', () async {
      const machineId = 'jf-machine';
      const userId = 'user-a';
      await putItemRow(
        serverId: ServerId('$machineId/$userId'),
        userId: userId,
        itemId: 'item-1',
        data: {
          ...jellyfinItem(id: 'item-1'),
          'UserData': {'IsFavorite': false},
        },
        pinned: true,
      );
      final client = testJellyfinClient(
        connection: testJellyfinConnection(machineId: machineId, userId: userId),
        handler: (_) async => http.Response('server error', 500),
      );
      addTearDown(client.close);
      const item = MediaItem.jellyfin(id: 'item-1', kind: MediaKind.movie, serverId: machineId);

      await expectLater(client.setFavorite(item, true), throwsA(isA<MediaServerHttpException>()));

      final row = await db.select(db.apiCache).getSingle();
      expect((jsonDecode(row.data)['UserData'] as Map)['IsFavorite'], isFalse);
      expect(row.pinned, isTrue);
    });
  });
}
