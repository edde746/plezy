
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/services/jellyfin_api_cache.dart';
import 'package:vibe_stream/services/plex_api_cache.dart';

/// Pins the per-backend `applyWatchState` cache mutations. The two
/// implementations are duplicated by design (see ApiCache.applyWatchState's
/// drift-discipline note) — these tests are the enforcement arm: unit
/// conversions (ms ↔ 100-ns ticks, epoch-seconds ↔ ISO-8601) and the
/// intentional asymmetries fail here instead of drifting silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlexApiCache.applyWatchState', () {
    final serverId = ServerId('plex-srv');
    const endpoint = '/library/metadata/movie-1';

    Map<String, dynamic> container({int viewCount = 0, int viewOffset = 5000}) => {
      'MediaContainer': {
        'Metadata': [
          {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'Movie', 'viewCount': viewCount, 'viewOffset': viewOffset},
        ],
      },
    };

    Future<Map<String, dynamic>> readBack() async {
      final cached = await PlexApiCache.instance.get(serverId, endpoint);
      return (cached!['MediaContainer']['Metadata'] as List).first as Map<String, dynamic>;
    }

    test('watched flip sets viewCount, zeroes viewOffset, stamps lastViewedAt', () async {
      await PlexApiCache.instance.put(serverId, endpoint, container());

      await PlexApiCache.instance.applyWatchState(serverId: serverId, itemId: 'movie-1', isWatched: true);

      final json = await readBack();
      expect(json['viewCount'], 1);
      expect(json['viewOffset'], 0);
      expect(json['lastViewedAt'], isA<int>());
      expect(json['lastViewedAt'] as int, greaterThan(0));
    });

    test('watched flip preserves an existing viewCount', () async {
      await PlexApiCache.instance.put(serverId, endpoint, container(viewCount: 3));

      await PlexApiCache.instance.applyWatchState(serverId: serverId, itemId: 'movie-1', isWatched: true);

      expect((await readBack())['viewCount'], 3);
    });

    test('unwatched flip zeroes viewCount/viewOffset and leaves lastViewedAt alone', () async {
      await PlexApiCache.instance.put(serverId, endpoint, container(viewCount: 2));

      await PlexApiCache.instance.applyWatchState(serverId: serverId, itemId: 'movie-1', isWatched: false);

      final json = await readBack();
      expect(json['viewCount'], 0);
      expect(json['viewOffset'], 0);
      expect(json.containsKey('lastViewedAt'), isFalse);
    });

    test('richer snapshot fields overwrite the flip defaults', () async {
      await PlexApiCache.instance.put(serverId, endpoint, container());

      await PlexApiCache.instance.applyWatchState(
        serverId: serverId,
        itemId: 'movie-1',
        isWatched: true,
        viewOffsetMs: 123456,
        lastViewedAt: 1700000000,
        viewedLeafCount: 7,
      );

      final json = await readBack();
      // Plex stores epoch-seconds and flat fields; viewedLeafCount is stored
      // directly (unlike Jellyfin, which ignores it — see its test below).
      expect(json['viewOffset'], 123456);
      expect(json['lastViewedAt'], 1700000000);
      expect(json['viewedLeafCount'], 7);
    });

    test('no cached row is a silent no-op', () async {
      await PlexApiCache.instance.applyWatchState(serverId: serverId, itemId: 'missing', isWatched: true);
    });
  });

  group('JellyfinApiCache.applyWatchState', () {
    final serverId = ServerId('jf-srv');

    Map<String, dynamic> dto({int playCount = 0}) => {
      'Id': 'item-1',
      'Type': 'Movie',
      'Name': 'Movie',
      'UserData': {'Played': false, 'PlayCount': playCount, 'PlaybackPositionTicks': 990000},
    };

    Future<Map<String, dynamic>> readBack(String userId) async {
      final cached = await JellyfinApiCache.instance.get(serverId, '/Users/$userId/Items/item-1');
      return cached!['UserData'] as Map<String, dynamic>;
    }

    test('mutates every per-user row for the same item', () async {
      // Jellyfin caches one row per userId — both must flip, otherwise a
      // profile switch surfaces the other user's stale row (audit D-cluster).
      await JellyfinApiCache.instance.put(serverId, '/Users/user-a/Items/item-1', dto());
      await JellyfinApiCache.instance.put(serverId, '/Users/user-b/Items/item-1', dto());

      await JellyfinApiCache.instance.applyWatchState(serverId: serverId, itemId: 'item-1', isWatched: true);

      expect((await readBack('user-a'))['Played'], isTrue);
      expect((await readBack('user-b'))['Played'], isTrue);
    });

    test('converts viewOffsetMs to 100-ns ticks', () async {
      await JellyfinApiCache.instance.put(serverId, '/Users/user-a/Items/item-1', dto());

      await JellyfinApiCache.instance.applyWatchState(
        serverId: serverId,
        itemId: 'item-1',
        isWatched: true,
        viewOffsetMs: 5000,
      );

      expect((await readBack('user-a'))['PlaybackPositionTicks'], 5000 * 10000);
    });

    test('converts epoch-seconds lastViewedAt to ISO-8601 LastPlayedDate', () async {
      await JellyfinApiCache.instance.put(serverId, '/Users/user-a/Items/item-1', dto());

      await JellyfinApiCache.instance.applyWatchState(
        serverId: serverId,
        itemId: 'item-1',
        isWatched: true,
        lastViewedAt: 1700000000,
      );

      final lastPlayed = (await readBack('user-a'))['LastPlayedDate'] as String;
      expect(DateTime.parse(lastPlayed), DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true));
    });

    test('watched flip preserves an existing PlayCount; unwatched zeroes it', () async {
      await JellyfinApiCache.instance.put(serverId, '/Users/user-a/Items/item-1', dto(playCount: 4));

      await JellyfinApiCache.instance.applyWatchState(serverId: serverId, itemId: 'item-1', isWatched: true);
      expect((await readBack('user-a'))['PlayCount'], 4);

      await JellyfinApiCache.instance.applyWatchState(serverId: serverId, itemId: 'item-1', isWatched: false);
      final userData = await readBack('user-a');
      expect(userData['PlayCount'], 0);
      expect(userData['Played'], isFalse);
    });

    test('viewedLeafCount is intentionally ignored (UnplayedItemCount stays server-computed)', () async {
      await JellyfinApiCache.instance.put(serverId, '/Users/user-a/Items/item-1', dto());

      await JellyfinApiCache.instance.applyWatchState(
        serverId: serverId,
        itemId: 'item-1',
        isWatched: true,
        viewedLeafCount: 9,
      );

      final userData = await readBack('user-a');
      expect(userData.containsKey('UnplayedItemCount'), isFalse);
      expect(userData.values, isNot(contains(9)));
    });

    test('malformed cached rows are skipped without throwing', () async {
      await db
          .into(db.apiCache)
          .insertOnConflictUpdate(
            ApiCacheCompanion(
              cacheKey: const Value('jf-srv:/Users/user-a/Items/item-1'),
              data: const Value('not json'),
              cachedAt: Value(DateTime.now()),
            ),
          );

      await JellyfinApiCache.instance.applyWatchState(serverId: serverId, itemId: 'item-1', isWatched: true);
    });
  });
}
