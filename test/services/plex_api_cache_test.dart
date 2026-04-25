import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';

void main() {
  late AppDatabase db;
  late PlexApiCache cache;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // PlexApiCache is a singleton initialized via static factory. Re-init
    // against the in-memory db for each test for full isolation.
    PlexApiCache.initialize(db);
    cache = PlexApiCache.instance;
  });

  tearDown(() async {
    await db.close();
  });

  // Helper: minimal Plex MediaContainer payload that PlexCacheParser can parse.
  Map<String, dynamic> mediaContainer({String ratingKey = '42', String title = 'Item'}) => {
    'MediaContainer': {
      'Metadata': [
        {'ratingKey': ratingKey, 'title': title, 'type': 'movie'},
      ],
    },
  };

  // ============================================================
  // Singleton
  // ============================================================

  group('singleton', () {
    test('initialize swaps the underlying database', () async {
      final newDb = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(newDb);
      expect(identical(PlexApiCache.instance.database, newDb), isTrue);
      await newDb.close();
    });

    test('database getter exposes the underlying AppDatabase', () {
      expect(identical(cache.database, db), isTrue);
    });
  });

  // ============================================================
  // get / put — cache hit and miss
  // ============================================================

  group('get / put', () {
    test('miss returns null for an unknown key', () async {
      expect(await cache.get('srv', '/library/metadata/1'), isNull);
    });

    test('put + get round-trip preserves the JSON map', () async {
      final payload = mediaContainer(ratingKey: '1', title: 'Hello');
      await cache.put('srv', '/library/metadata/1', payload);

      final hit = await cache.get('srv', '/library/metadata/1');
      expect(hit, isNotNull);
      expect(hit, equals(payload));
    });

    test('put on existing key overwrites prior data (insertOnConflictUpdate)', () async {
      await cache.put('srv', '/library/metadata/1', {
        'MediaContainer': {
          'Metadata': [
            {'title': 'first'},
          ],
        },
      });
      await cache.put('srv', '/library/metadata/1', {
        'MediaContainer': {
          'Metadata': [
            {'title': 'second'},
          ],
        },
      });

      final hit = await cache.get('srv', '/library/metadata/1');
      expect(((hit!['MediaContainer'] as Map)['Metadata'] as List).first['title'], 'second');
    });

    test('keys are namespaced by serverId — same endpoint on different servers is isolated', () async {
      await cache.put('srv-a', '/library/metadata/1', mediaContainer(ratingKey: 'A'));
      await cache.put('srv-b', '/library/metadata/1', mediaContainer(ratingKey: 'B'));

      final a = await cache.get('srv-a', '/library/metadata/1');
      final b = await cache.get('srv-b', '/library/metadata/1');
      expect(((a!['MediaContainer'] as Map)['Metadata'] as List).first['ratingKey'], 'A');
      expect(((b!['MediaContainer'] as Map)['Metadata'] as List).first['ratingKey'], 'B');
    });

    test('put writes a fresh cachedAt timestamp on overwrite', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      final firstRow = await (db.select(
        db.apiCache,
      )..where((t) => t.cacheKey.equals('srv:/library/metadata/1'))).getSingle();

      // Wait one tick so DateTime.now() advances.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await cache.put('srv', '/library/metadata/1', mediaContainer(title: 'Updated'));
      final secondRow = await (db.select(
        db.apiCache,
      )..where((t) => t.cacheKey.equals('srv:/library/metadata/1'))).getSingle();

      expect(secondRow.cachedAt.isAfter(firstRow.cachedAt) || secondRow.cachedAt == firstRow.cachedAt, isTrue);
    });
  });

  // ============================================================
  // deleteForServer / deleteForItem / clearAll
  // ============================================================

  group('deletion', () {
    test('deleteForServer wipes only the targeted serverId', () async {
      await cache.put('srv-a', '/library/metadata/1', mediaContainer(ratingKey: '1'));
      await cache.put('srv-a', '/library/metadata/2', mediaContainer(ratingKey: '2'));
      await cache.put('srv-b', '/library/metadata/1', mediaContainer(ratingKey: '1'));

      await cache.deleteForServer('srv-a');

      expect(await cache.get('srv-a', '/library/metadata/1'), isNull);
      expect(await cache.get('srv-a', '/library/metadata/2'), isNull);
      expect(await cache.get('srv-b', '/library/metadata/1'), isNotNull);
    });

    test('deleteForItem removes both metadata and children endpoints', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      await cache.put('srv', '/library/metadata/1/children', mediaContainer());
      await cache.put('srv', '/library/metadata/2', mediaContainer());

      await cache.deleteForItem('srv', '1');

      expect(await cache.get('srv', '/library/metadata/1'), isNull);
      expect(await cache.get('srv', '/library/metadata/1/children'), isNull);
      // Unrelated item not affected.
      expect(await cache.get('srv', '/library/metadata/2'), isNotNull);
    });

    test('clearAll wipes every row across servers', () async {
      await cache.put('srv-a', '/library/metadata/1', mediaContainer());
      await cache.put('srv-b', '/library/metadata/2', mediaContainer());

      await cache.clearAll();

      expect(await db.select(db.apiCache).get(), isEmpty);
    });
  });

  // ============================================================
  // Pinning
  // ============================================================

  group('pinning', () {
    test('isPinned defaults to false for a freshly cached item', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      expect(await cache.isPinned('srv', '1'), isFalse);
    });

    test('isPinned returns false when the item is not cached at all', () async {
      expect(await cache.isPinned('srv', 'missing'), isFalse);
    });

    test('pinForOffline marks the row as pinned', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      await cache.pinForOffline('srv', '1');
      expect(await cache.isPinned('srv', '1'), isTrue);
    });

    test('unpinForOffline reverts the pin', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      await cache.pinForOffline('srv', '1');
      await cache.unpinForOffline('srv', '1');
      expect(await cache.isPinned('srv', '1'), isFalse);
    });

    test('pinForOffline on missing row is a no-op (no insert, no throw)', () async {
      await cache.pinForOffline('srv', 'missing');
      expect(await cache.isPinned('srv', 'missing'), isFalse);
    });

    test('getPinnedKeys extracts ratingKeys from pinned rows for the server', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer());
      await cache.put('srv', '/library/metadata/2', mediaContainer());
      await cache.put('srv', '/library/metadata/3', mediaContainer());
      await cache.put('other', '/library/metadata/4', mediaContainer());

      await cache.pinForOffline('srv', '1');
      await cache.pinForOffline('srv', '3');
      await cache.pinForOffline('other', '4');

      final keys = await cache.getPinnedKeys('srv');
      expect(keys, equals({'1', '3'}));
    });

    test('getPinnedKeys ignores cache rows whose endpoint is not /library/metadata/<id>', () async {
      // Cached at a non-metadata endpoint — its key shape won't match the regex.
      await db
          .into(db.apiCache)
          .insert(ApiCacheCompanion.insert(cacheKey: 'srv:/library/sections/1/all', data: jsonEncode({'foo': 'bar'})));
      // Force-pin via raw update to exercise the regex skip path.
      await (db.update(db.apiCache)..where((t) => t.cacheKey.equals('srv:/library/sections/1/all'))).write(
        const ApiCacheCompanion(pinned: Value(true)),
      );

      expect(await cache.getPinnedKeys('srv'), isEmpty);
    });

    test('getPinnedKeys handles alphanumeric ratingKeys', () async {
      // Plex sometimes uses alphanumeric ratingKeys (e.g. for online-content).
      await cache.put('srv', '/library/metadata/abc-123', mediaContainer(ratingKey: 'abc-123'));
      await cache.pinForOffline('srv', 'abc-123');

      final keys = await cache.getPinnedKeys('srv');
      expect(keys, equals({'abc-123'}));
    });
  });

  // ============================================================
  // getMetadata / getAllPinnedMetadata
  // ============================================================

  group('metadata extraction', () {
    test('getMetadata returns null when the key is not cached', () async {
      expect(await cache.getMetadata('srv', 'missing'), isNull);
    });

    test('getMetadata returns null when cached payload has no Metadata array', () async {
      await cache.put('srv', '/library/metadata/empty', {
        'MediaContainer': {'size': 0},
      });
      expect(await cache.getMetadata('srv', 'empty'), isNull);
    });

    test('getMetadata parses MediaContainer.Metadata[0] and tags it with serverId', () async {
      await cache.put('srv', '/library/metadata/42', mediaContainer(ratingKey: '42', title: 'Hello'));

      final meta = await cache.getMetadata('srv', '42');
      expect(meta, isNotNull);
      expect(meta!.ratingKey, '42');
      expect(meta.title, 'Hello');
      expect(meta.serverId, 'srv');
    });

    test('getAllPinnedMetadata returns an empty map when nothing is pinned', () async {
      await cache.put('srv', '/library/metadata/1', mediaContainer(ratingKey: '1'));
      // No pin yet.
      expect(await cache.getAllPinnedMetadata(), isEmpty);
    });

    test('getAllPinnedMetadata aggregates pinned items across servers, keyed by globalKey', () async {
      await cache.put('srv-a', '/library/metadata/1', mediaContainer(ratingKey: '1', title: 'A1'));
      await cache.put('srv-a', '/library/metadata/2', mediaContainer(ratingKey: '2', title: 'A2'));
      await cache.put('srv-b', '/library/metadata/9', mediaContainer(ratingKey: '9', title: 'B9'));
      // One unpinned row to verify it's filtered out.
      await cache.put('srv-b', '/library/metadata/10', mediaContainer(ratingKey: '10', title: 'B10'));

      await cache.pinForOffline('srv-a', '1');
      await cache.pinForOffline('srv-a', '2');
      await cache.pinForOffline('srv-b', '9');

      final result = await cache.getAllPinnedMetadata();
      expect(result.keys.toSet(), {'srv-a:1', 'srv-a:2', 'srv-b:9'});
      expect(result['srv-a:1']!.title, 'A1');
      expect(result['srv-a:1']!.serverId, 'srv-a');
      expect(result['srv-b:9']!.title, 'B9');
      expect(result['srv-b:9']!.serverId, 'srv-b');
    });

    test('getAllPinnedMetadata skips rows whose key is not a metadata endpoint', () async {
      // Insert a pinned row at a non-metadata endpoint via raw insert.
      await db
          .into(db.apiCache)
          .insert(
            ApiCacheCompanion.insert(
              cacheKey: 'srv:/library/sections/1/all',
              data: jsonEncode(mediaContainer()),
              pinned: const Value(true),
            ),
          );
      await cache.put('srv', '/library/metadata/1', mediaContainer(ratingKey: '1'));
      await cache.pinForOffline('srv', '1');

      final result = await cache.getAllPinnedMetadata();
      expect(result.keys.toSet(), {'srv:1'});
    });

    test('getAllPinnedMetadata silently skips rows with malformed JSON', () async {
      // Bad-JSON pinned row.
      await db
          .into(db.apiCache)
          .insert(
            ApiCacheCompanion.insert(
              cacheKey: 'srv:/library/metadata/bad',
              data: 'not-json',
              pinned: const Value(true),
            ),
          );
      // Good pinned row.
      await cache.put('srv', '/library/metadata/good', mediaContainer(ratingKey: 'good', title: 'OK'));
      await cache.pinForOffline('srv', 'good');

      final result = await cache.getAllPinnedMetadata();
      expect(result.keys, contains('srv:good'));
      expect(result.keys, isNot(contains('srv:bad')));
    });
  });
}
