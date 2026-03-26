import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';

AppDatabase _openInMemoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late PlexApiCache cache;

  setUp(() {
    db = _openInMemoryDb();
    cache = PlexApiCache.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlexApiCache.buildKey', () {
    test('combines serverId and endpoint with colon', () {
      expect(cache.buildKey('server1', '/library/metadata/42'), 'server1:/library/metadata/42');
    });
  });

  group('PlexApiCache.getBatch', () {
    test('returns empty map for empty key set', () async {
      final result = await cache.getBatch({});
      expect(result, isEmpty);
    });

    test('returns empty map when no keys match', () async {
      await cache.put('s1', '/library/metadata/1', {'title': 'Movie A'});

      final result = await cache.getBatch({'s1:/library/metadata/99'});
      expect(result, isEmpty);
    });

    test('returns matching entries by exact key', () async {
      await cache.put('s1', '/library/metadata/1', {'title': 'Movie A'});
      await cache.put('s1', '/library/metadata/2', {'title': 'Movie B'});

      final result = await cache.getBatch({'s1:/library/metadata/1'});
      expect(result.length, 1);
      expect(result['s1:/library/metadata/1']?['title'], 'Movie A');
    });

    test('returns multiple matching entries', () async {
      await cache.put('s1', '/library/metadata/1', {'title': 'Movie A'});
      await cache.put('s1', '/library/metadata/2', {'title': 'Movie B'});
      await cache.put('s1', '/library/metadata/3', {'title': 'Movie C'});

      final result = await cache.getBatch({
        's1:/library/metadata/1',
        's1:/library/metadata/3',
      });

      expect(result.length, 2);
      expect(result['s1:/library/metadata/1']?['title'], 'Movie A');
      expect(result['s1:/library/metadata/3']?['title'], 'Movie C');
      expect(result.containsKey('s1:/library/metadata/2'), isFalse);
    });

    test('omits keys not present in cache (partial hit)', () async {
      await cache.put('s1', '/library/metadata/1', {'title': 'Movie A'});

      final result = await cache.getBatch({
        's1:/library/metadata/1',
        's1:/library/metadata/missing',
      });

      expect(result.length, 1);
      expect(result.containsKey('s1:/library/metadata/1'), isTrue);
      expect(result.containsKey('s1:/library/metadata/missing'), isFalse);
    });

    test('does not cross server boundaries', () async {
      await cache.put('serverA', '/library/metadata/1', {'title': 'From A'});
      await cache.put('serverB', '/library/metadata/1', {'title': 'From B'});

      final result = await cache.getBatch({'serverA:/library/metadata/1'});
      expect(result.length, 1);
      expect(result['serverA:/library/metadata/1']?['title'], 'From A');
    });

    test('returned data matches what was stored', () async {
      final data = {'MediaContainer': {'Metadata': [{'title': 'Test', 'ratingKey': '5', 'type': 'movie'}]}};
      await cache.put('s1', '/library/metadata/5', data);

      final result = await cache.getBatch({'s1:/library/metadata/5'});
      expect(result['s1:/library/metadata/5'], data);
    });
  });
}
