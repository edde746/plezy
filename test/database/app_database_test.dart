import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/download_models.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ============================================================
  // Schema sanity
  // ============================================================

  group('schema', () {
    test('schemaVersion is 13', () {
      expect(db.schemaVersion, 13);
    });

    test('all tables are accessible and start empty', () async {
      expect(await db.select(db.downloadedMedia).get(), isEmpty);
      expect(await db.select(db.downloadQueue).get(), isEmpty);
      expect(await db.select(db.apiCache).get(), isEmpty);
      expect(await db.select(db.offlineWatchProgress).get(), isEmpty);
      expect(await db.select(db.syncRules).get(), isEmpty);
    });
  });

  // ============================================================
  // ApiCache: insert / select / update / delete round-trip
  // ============================================================

  group('ApiCache', () {
    test('insert + select round-trip preserves fields', () async {
      await db
          .into(db.apiCache)
          .insert(ApiCacheCompanion.insert(cacheKey: 'srv:/library/metadata/1', data: '{"hello":"world"}'));

      final rows = await db.select(db.apiCache).get();
      expect(rows, hasLength(1));
      expect(rows.first.cacheKey, 'srv:/library/metadata/1');
      expect(rows.first.data, '{"hello":"world"}');
      expect(rows.first.pinned, isFalse); // default
    });

    test('default pinned=false, custom pinned=true is honored', () async {
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'k1', data: 'a'));
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'k2', data: 'b', pinned: const Value(true)));

      final rows = await (db.select(db.apiCache)..orderBy([(t) => OrderingTerm.asc(t.cacheKey)])).get();
      expect(rows.map((r) => r.pinned).toList(), [false, true]);
    });

    test('cacheKey is the primary key (duplicate insert without replace fails)', () async {
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'dup', data: 'first'));
      expect(
        () => db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'dup', data: 'second')),
        throwsA(isA<Exception>()),
      );
    });

    test('insertOnConflictUpdate replaces the row', () async {
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'dup', data: 'first'));
      await db
          .into(db.apiCache)
          .insertOnConflictUpdate(ApiCacheCompanion.insert(cacheKey: 'dup', data: 'second', pinned: const Value(true)));

      final rows = await db.select(db.apiCache).get();
      expect(rows, hasLength(1));
      expect(rows.first.data, 'second');
      expect(rows.first.pinned, isTrue);
    });

    test('update modifies existing row', () async {
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'k', data: 'orig'));
      await (db.update(
        db.apiCache,
      )..where((t) => t.cacheKey.equals('k'))).write(const ApiCacheCompanion(data: Value('updated')));

      final row = await (db.select(db.apiCache)..where((t) => t.cacheKey.equals('k'))).getSingle();
      expect(row.data, 'updated');
    });

    test('delete removes the row', () async {
      await db.into(db.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'k', data: 'v'));
      expect(await db.select(db.apiCache).get(), hasLength(1));

      await (db.delete(db.apiCache)..where((t) => t.cacheKey.equals('k'))).go();
      expect(await db.select(db.apiCache).get(), isEmpty);
    });
  });

  // ============================================================
  // DownloadedMedia: round-trip + helpers + update + delete
  // ============================================================

  group('DownloadedMedia', () {
    Future<int> insertMovie({
      String serverId = 'srv1',
      String ratingKey = '100',
      int status = 0, // queued
      int progress = 0,
    }) async {
      return db
          .into(db.downloadedMedia)
          .insert(
            DownloadedMediaCompanion.insert(
              serverId: serverId,
              ratingKey: ratingKey,
              globalKey: '$serverId:$ratingKey',
              type: 'movie',
              status: status,
              progress: Value(progress),
            ),
          );
    }

    test('insert + select round-trip preserves fields', () async {
      await insertMovie();

      final rows = await db.select(db.downloadedMedia).get();
      expect(rows, hasLength(1));
      expect(rows.first.serverId, 'srv1');
      expect(rows.first.ratingKey, '100');
      expect(rows.first.globalKey, 'srv1:100');
      expect(rows.first.type, 'movie');
      expect(rows.first.status, 0);
      expect(rows.first.progress, 0);
      expect(rows.first.downloadedBytes, 0); // default
      expect(rows.first.retryCount, 0); // default
      expect(rows.first.mediaIndex, 0); // default
      expect(rows.first.bgTaskId, isNull);
      expect(rows.first.totalBytes, isNull);
    });

    test('updating progress field works', () async {
      await insertMovie();
      await (db.update(db.downloadedMedia)..where((t) => t.globalKey.equals('srv1:100'))).write(
        const DownloadedMediaCompanion(progress: Value(75), downloadedBytes: Value(1024)),
      );

      final row = await (db.select(db.downloadedMedia)..where((t) => t.globalKey.equals('srv1:100'))).getSingle();
      expect(row.progress, 75);
      expect(row.downloadedBytes, 1024);
    });

    test('globalKey unique constraint blocks duplicate insert', () async {
      await insertMovie();
      expect(insertMovie(), throwsA(isA<Exception>()));
    });

    test('delete removes only the matching row', () async {
      await insertMovie(ratingKey: '1');
      await insertMovie(ratingKey: '2');
      expect(await db.select(db.downloadedMedia).get(), hasLength(2));

      await (db.delete(db.downloadedMedia)..where((t) => t.globalKey.equals('srv1:1'))).go();

      final rows = await db.select(db.downloadedMedia).get();
      expect(rows, hasLength(1));
      expect(rows.first.ratingKey, '2');
    });

    test('getAllDownloadedMetadata returns only completed items', () async {
      await insertMovie(ratingKey: '1', status: DownloadStatus.queued.index);
      await insertMovie(ratingKey: '2', status: DownloadStatus.completed.index);
      await insertMovie(ratingKey: '3', status: DownloadStatus.failed.index);
      await insertMovie(ratingKey: '4', status: DownloadStatus.completed.index);

      final completed = await db.getAllDownloadedMetadata();
      expect(completed.map((i) => i.ratingKey).toSet(), {'2', '4'});
    });
  });

  // ============================================================
  // OfflineWatchProgress helpers
  // ============================================================

  group('OfflineWatchProgress', () {
    test('upsertProgressAction inserts a new progress row', () async {
      await db.upsertProgressAction(
        serverId: 'srv',
        ratingKey: '42',
        viewOffset: 5000,
        duration: 10000,
        shouldMarkWatched: false,
      );

      final rows = await db.select(db.offlineWatchProgress).get();
      expect(rows, hasLength(1));
      expect(rows.first.globalKey, 'srv:42');
      expect(rows.first.actionType, OfflineActionType.progress.name);
      expect(rows.first.viewOffset, 5000);
      expect(rows.first.duration, 10000);
      expect(rows.first.shouldMarkWatched, isFalse);
      expect(rows.first.syncAttempts, 0);
    });

    test('upsertProgressAction merges into the existing progress row', () async {
      await db.upsertProgressAction(
        serverId: 'srv',
        ratingKey: '42',
        viewOffset: 1000,
        duration: 10000,
        shouldMarkWatched: false,
      );
      await db.upsertProgressAction(
        serverId: 'srv',
        ratingKey: '42',
        viewOffset: 9500,
        duration: 10000,
        shouldMarkWatched: true,
      );

      final rows = await db.select(db.offlineWatchProgress).get();
      expect(rows, hasLength(1));
      expect(rows.first.viewOffset, 9500);
      expect(rows.first.shouldMarkWatched, isTrue);
    });

    test('insertWatchAction (watched) clears prior progress + insert single row', () async {
      // Existing progress row for the same item
      await db.upsertProgressAction(
        serverId: 'srv',
        ratingKey: '42',
        viewOffset: 5000,
        duration: 10000,
        shouldMarkWatched: false,
      );

      await db.insertWatchAction(serverId: 'srv', ratingKey: '42', actionType: OfflineActionType.watched.name);

      final rows = await db.select(db.offlineWatchProgress).get();
      expect(rows, hasLength(1));
      expect(rows.first.actionType, OfflineActionType.watched.name);
      expect(rows.first.viewOffset, isNull);
    });

    test('getPendingWatchActions returns rows ordered by createdAt asc', () async {
      // Inject deterministic createdAt by raw inserts
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '1',
              globalKey: 's:1',
              actionType: OfflineActionType.watched.name,
              createdAt: now + 100,
              updatedAt: now + 100,
            ),
          );
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '2',
              globalKey: 's:2',
              actionType: OfflineActionType.watched.name,
              createdAt: now + 50,
              updatedAt: now + 50,
            ),
          );

      final pending = await db.getPendingWatchActions();
      expect(pending.map((p) => p.ratingKey).toList(), ['2', '1']);
    });

    test('getPendingWatchActionsForServer filters by serverId', () async {
      await db.insertWatchAction(serverId: 'a', ratingKey: '1', actionType: OfflineActionType.watched.name);
      await db.insertWatchAction(serverId: 'b', ratingKey: '2', actionType: OfflineActionType.watched.name);
      await db.insertWatchAction(serverId: 'a', ratingKey: '3', actionType: OfflineActionType.unwatched.name);

      final aRows = await db.getPendingWatchActionsForServer('a');
      expect(aRows.map((r) => r.ratingKey).toSet(), {'1', '3'});

      final bRows = await db.getPendingWatchActionsForServer('b');
      expect(bRows.map((r) => r.ratingKey).toSet(), {'2'});
    });

    test('getLatestWatchAction picks the most recently updated row', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '1',
              globalKey: 's:1',
              actionType: OfflineActionType.progress.name,
              createdAt: now,
              updatedAt: now - 100,
            ),
          );
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '1',
              globalKey: 's:1',
              actionType: OfflineActionType.watched.name,
              createdAt: now,
              updatedAt: now + 50,
            ),
          );

      final latest = await db.getLatestWatchAction('s:1');
      expect(latest, isNotNull);
      expect(latest!.actionType, OfflineActionType.watched.name);
    });

    test('getLatestWatchAction returns null when no rows', () async {
      expect(await db.getLatestWatchAction('nope:nope'), isNull);
    });

    test('getLatestWatchActionsForKeys batches lookups, latest per key', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '1',
              globalKey: 's:1',
              actionType: OfflineActionType.progress.name,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '1',
              globalKey: 's:1',
              actionType: OfflineActionType.watched.name,
              createdAt: now,
              updatedAt: now + 100,
            ),
          );
      await db
          .into(db.offlineWatchProgress)
          .insert(
            OfflineWatchProgressCompanion.insert(
              serverId: 's',
              ratingKey: '2',
              globalKey: 's:2',
              actionType: OfflineActionType.unwatched.name,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final result = await db.getLatestWatchActionsForKeys({'s:1', 's:2', 's:3-missing'});
      expect(result.keys.toSet(), {'s:1', 's:2'});
      expect(result['s:1']!.actionType, OfflineActionType.watched.name);
      expect(result['s:2']!.actionType, OfflineActionType.unwatched.name);
    });

    test('getLatestWatchActionsForKeys with empty input returns empty map (no query)', () async {
      expect(await db.getLatestWatchActionsForKeys({}), isEmpty);
    });

    test('updateSyncAttempt increments syncAttempts and stores lastError', () async {
      await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.name);
      final inserted = (await db.select(db.offlineWatchProgress).get()).single;

      await db.updateSyncAttempt(inserted.id, 'boom');
      var row = (await db.select(db.offlineWatchProgress).get()).single;
      expect(row.syncAttempts, 1);
      expect(row.lastError, 'boom');

      await db.updateSyncAttempt(inserted.id, null);
      row = (await db.select(db.offlineWatchProgress).get()).single;
      expect(row.syncAttempts, 2);
      expect(row.lastError, isNull);
    });

    test('updateSyncAttempt is a no-op when id does not exist', () async {
      await db.updateSyncAttempt(999, 'irrelevant');
      expect(await db.select(db.offlineWatchProgress).get(), isEmpty);
    });

    test('deleteWatchAction removes only the matching row', () async {
      await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.name);
      await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.watched.name);
      final rows = await db.select(db.offlineWatchProgress).get();
      expect(rows, hasLength(2));

      await db.deleteWatchAction(rows.first.id);
      expect(await db.select(db.offlineWatchProgress).get(), hasLength(1));
    });

    test('getPendingSyncCount counts every row', () async {
      expect(await db.getPendingSyncCount(), 0);

      await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.name);
      await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.unwatched.name);
      expect(await db.getPendingSyncCount(), 2);
    });

    test('clearAllWatchActions empties the table', () async {
      await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.name);
      await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.unwatched.name);

      await db.clearAllWatchActions();
      expect(await db.select(db.offlineWatchProgress).get(), isEmpty);
    });
  });

  // ============================================================
  // Sync Rules helpers
  // ============================================================

  group('SyncRules', () {
    test('insertSyncRule + getSyncRules round-trip with defaults', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );

      final rules = await db.getSyncRules();
      expect(rules, hasLength(1));
      expect(rules.first.targetType, 'show');
      expect(rules.first.episodeCount, 5);
      expect(rules.first.enabled, isTrue); // default
      expect(rules.first.downloadFilter, 'unwatched'); // default
      expect(rules.first.mediaIndex, 0); // default
      expect(rules.first.lastExecutedAt, isNull);
    });

    test('insertSyncRule with duplicate globalKey throws on the UNIQUE constraint', () async {
      // insertOnConflictUpdate only auto-targets the primary key (`id`), so a
      // collision on the UNIQUE `global_key` column still throws — this pins
      // current production behavior.
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      expect(
        () => db.insertSyncRule(
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'srv:10',
          targetType: 'season',
          episodeCount: 99,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getSyncRule returns the matching rule or null', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      expect(await db.getSyncRule('srv:10'), isNotNull);
      expect(await db.getSyncRule('srv:nope'), isNull);
    });

    test('updateSyncRuleCount mutates only the count', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      await db.updateSyncRuleCount('srv:10', 12);

      final rule = await db.getSyncRule('srv:10');
      expect(rule!.episodeCount, 12);
      expect(rule.targetType, 'show'); // unchanged
    });

    test('updateSyncRuleFilter mutates the filter', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      await db.updateSyncRuleFilter('srv:10', 'all');

      final rule = await db.getSyncRule('srv:10');
      expect(rule!.downloadFilter, 'all');
    });

    test('updateSyncRuleEnabled toggles enabled', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      await db.updateSyncRuleEnabled('srv:10', false);
      expect((await db.getSyncRule('srv:10'))!.enabled, isFalse);

      await db.updateSyncRuleEnabled('srv:10', true);
      expect((await db.getSyncRule('srv:10'))!.enabled, isTrue);
    });

    test('updateSyncRuleLastExecuted writes a timestamp', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      final before = DateTime.now().millisecondsSinceEpoch;
      await db.updateSyncRuleLastExecuted('srv:10');
      final after = DateTime.now().millisecondsSinceEpoch;

      final rule = await db.getSyncRule('srv:10');
      expect(rule!.lastExecutedAt, isNotNull);
      expect(rule.lastExecutedAt! >= before, isTrue);
      expect(rule.lastExecutedAt! <= after, isTrue);
    });

    test('deleteSyncRule removes the matching row', () async {
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '10',
        globalKey: 'srv:10',
        targetType: 'show',
        episodeCount: 5,
      );
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '11',
        globalKey: 'srv:11',
        targetType: 'show',
        episodeCount: 5,
      );

      await db.deleteSyncRule('srv:10');

      final remaining = await db.getSyncRules();
      expect(remaining, hasLength(1));
      expect(remaining.first.globalKey, 'srv:11');
    });
  });
}
