import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/models/download_models.dart';

void main() {
  final suite = _AppDatabaseTestSuite();
  suite.registerTests();
}

class _AppDatabaseTestSuite {
  late AppDatabase db;

  void registerTests() {
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    _registerSchemaTests();
    _registerApiCacheTests();
    _registerDownloadedMediaTests();
    _registerOfflineWatchProgressTests();
    _registerSyncRulesTests();
  }

  void _registerSchemaTests() {
    // ============================================================
    // Schema sanity
    // ============================================================

    group('schema', () {
      test('schemaVersion is 14', () {
        expect(db.schemaVersion, 14);
      });

      test('all tables are accessible and start empty', () async {
        expect(await db.select(db.downloadedMedia).get(), isEmpty);
        expect(await db.select(db.downloadOwners).get(), isEmpty);
        expect(await db.select(db.downloadQueue).get(), isEmpty);
        expect(await db.select(db.apiCache).get(), isEmpty);
        expect(await db.select(db.offlineWatchProgress).get(), isEmpty);
        expect(await db.select(db.syncRules).get(), isEmpty);
        expect(await db.select(db.connections).get(), isEmpty);
        expect(await db.select(db.profiles).get(), isEmpty);
        expect(await db.select(db.profileConnections).get(), isEmpty);
      });

      test('ProfileConnections has no profile_id FK (virtual plex_home profiles)', () async {
        // v20 dropped the profile_id FK so virtual Plex Home profiles can
        // persist join rows without a parent `profiles` row. The two
        // profile-delete sites (profile_detail_screen, profile_switch_screen)
        // call ProfileConnectionRegistry.removeAllForProfile manually before
        // deleting the profile, so the cascade isn't needed.
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.connections)
            .insert(
              ConnectionsCompanion.insert(id: 'c1', kind: 'plex', displayName: 'C1', configJson: '{}', createdAt: now),
            );
        // No `profiles` row inserted — this would have failed pre-v20.
        await db
            .into(db.profileConnections)
            .insert(
              ProfileConnectionsCompanion.insert(
                profileId: 'plex-home-c1-uuid',
                connectionId: 'c1',
                userIdentifier: 'uuid',
              ),
            );
        expect(await db.select(db.profileConnections).get(), hasLength(1));
      });

      test('ProfileConnections FK cascades when a Connection is deleted', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.connections)
            .insert(
              ConnectionsCompanion.insert(id: 'c2', kind: 'plex', displayName: 'C2', configJson: '{}', createdAt: now),
            );
        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(id: 'p2', kind: 'local', displayName: 'P2', configJson: '{}', createdAt: now),
            );
        await db
            .into(db.profileConnections)
            .insert(ProfileConnectionsCompanion.insert(profileId: 'p2', connectionId: 'c2', userIdentifier: 'u2'));

        await (db.delete(db.connections)..where((t) => t.id.equals('c2'))).go();
        expect(await db.select(db.profileConnections).get(), isEmpty);
      });

      test('hot-query indices exist in sqlite_master', () async {
        // sqlite_master rows let us assert the indices physically exist
        // without depending on Drift's `Migrator` having run them.
        final rows = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index'").get();
        final names = rows.map((r) => r.read<String>('name')).toSet();
        expect(
          names,
          containsAll(['idx_profiles_kind', 'idx_profile_connections_profile_id', 'idx_offline_watch_progress_server']),
        );
      });
    });
  }

  void _registerApiCacheTests() {
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
        await db
            .into(db.apiCache)
            .insert(ApiCacheCompanion.insert(cacheKey: 'k2', data: 'b', pinned: const Value(true)));

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
            .insertOnConflictUpdate(
              ApiCacheCompanion.insert(cacheKey: 'dup', data: 'second', pinned: const Value(true)),
            );

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
  }

  void _registerDownloadedMediaTests() {
    // ============================================================
    // DownloadedMedia: round-trip + helpers + update + delete
    // ============================================================

    group('DownloadedMedia', () {
      Future<int> insertMovie({
        String serverId = 'srv1',
        String? clientScopeId,
        String ratingKey = '100',
        int status = 0, // queued
        int progress = 0,
      }) async {
        return db
            .into(db.downloadedMedia)
            .insert(
              DownloadedMediaCompanion.insert(
                serverId: serverId,
                clientScopeId: Value(clientScopeId),
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
        expect(rows.first.clientScopeId, isNull);
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

      test('clientScopeId is persisted for user-scoped downloads', () async {
        await insertMovie(serverId: 'jf-machine', clientScopeId: 'jf-machine/user-a');

        final row = await db.select(db.downloadedMedia).getSingle();
        expect(row.serverId, 'jf-machine');
        expect(row.clientScopeId, 'jf-machine/user-a');
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

      test('download owners keep profile visibility separate for one physical row', () async {
        await insertMovie(ratingKey: '1', status: DownloadStatus.completed.index);

        await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv1:1');
        await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv1:1');

        expect(await db.getDownloadOwnerKeysForProfile('profile-a'), {'srv1:1'});
        expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {'srv1:1'});
        expect(await db.getDownloadOwnerCount('srv1:1'), 2);

        await db.removeDownloadOwner(profileId: 'profile-a', globalKey: 'srv1:1');
        expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
        expect(await db.hasDownloadOwner('srv1:1'), isTrue);
        expect(await db.hasDownloadOwner('srv1:1', excludingProfileId: 'profile-b'), isFalse);
      });

      test('adoptLegacyDownloadsForProfile claims only ownerless physical rows', () async {
        await insertMovie(ratingKey: '1', status: DownloadStatus.completed.index);
        await insertMovie(ratingKey: '2', status: DownloadStatus.completed.index);
        await db.addDownloadOwner(profileId: 'profile-existing', globalKey: 'srv1:2');

        await db.adoptLegacyDownloadsForProfile('profile-a');

        expect(await db.getDownloadOwnerKeysForProfile('profile-a'), {'srv1:1'});
        expect(await db.getDownloadOwnerKeysForProfile('profile-existing'), {'srv1:2'});
      });
    });
  }

  void _registerOfflineWatchProgressTests() {
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
        expect(rows.first.clientScopeId, isNull);
        expect(rows.first.actionType, OfflineActionType.progress.id);
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

      test('upsertProgressAction keeps scoped Jellyfin users separate', () async {
        await db.upsertProgressAction(
          serverId: 'srv',
          clientScopeId: 'srv/user-a',
          ratingKey: '42',
          viewOffset: 1000,
          duration: 10000,
          shouldMarkWatched: false,
        );
        await db.upsertProgressAction(
          serverId: 'srv',
          clientScopeId: 'srv/user-b',
          ratingKey: '42',
          viewOffset: 9000,
          duration: 10000,
          shouldMarkWatched: true,
        );

        final rows = await (db.select(
          db.offlineWatchProgress,
        )..orderBy([(t) => OrderingTerm.asc(t.clientScopeId)])).get();
        expect(rows, hasLength(2));
        expect(rows.map((r) => r.clientScopeId), ['srv/user-a', 'srv/user-b']);
        expect(rows.map((r) => r.viewOffset), [1000, 9000]);
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

        await db.insertWatchAction(serverId: 'srv', ratingKey: '42', actionType: OfflineActionType.watched.id);

        final rows = await db.select(db.offlineWatchProgress).get();
        expect(rows, hasLength(1));
        expect(rows.first.actionType, OfflineActionType.watched.id);
        expect(rows.first.viewOffset, isNull);
      });

      test('insertWatchAction clears only matching clientScopeId conflicts', () async {
        await db.upsertProgressAction(
          serverId: 'srv',
          clientScopeId: 'srv/user-a',
          ratingKey: '42',
          viewOffset: 1000,
          duration: 10000,
          shouldMarkWatched: false,
        );
        await db.upsertProgressAction(
          serverId: 'srv',
          clientScopeId: 'srv/user-b',
          ratingKey: '42',
          viewOffset: 2000,
          duration: 10000,
          shouldMarkWatched: false,
        );

        await db.insertWatchAction(
          serverId: 'srv',
          clientScopeId: 'srv/user-a',
          ratingKey: '42',
          actionType: OfflineActionType.watched.id,
        );

        final rows = await (db.select(
          db.offlineWatchProgress,
        )..orderBy([(t) => OrderingTerm.asc(t.clientScopeId), (t) => OrderingTerm.asc(t.actionType)])).get();
        expect(rows, hasLength(2));
        expect(rows.map((r) => (r.clientScopeId, r.actionType)).toList(), [
          ('srv/user-a', OfflineActionType.watched.id),
          ('srv/user-b', OfflineActionType.progress.id),
        ]);
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
                actionType: OfflineActionType.watched.id,
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
                actionType: OfflineActionType.watched.id,
                createdAt: now + 50,
                updatedAt: now + 50,
              ),
            );

        final pending = await db.getPendingWatchActions();
        expect(pending.map((p) => p.ratingKey).toList(), ['2', '1']);
      });

      test('adoptLegacyOfflineWatchActionsForProfile claims null-profile rows', () async {
        await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(
          profileId: 'profile-existing',
          serverId: 's',
          ratingKey: '2',
          actionType: OfflineActionType.watched.id,
        );

        await db.adoptLegacyOfflineWatchActionsForProfile('profile-a');

        expect((await db.getPendingWatchActions(profileId: 'profile-a')).map((r) => r.ratingKey), ['1']);
        expect((await db.getPendingWatchActions(profileId: 'profile-existing')).map((r) => r.ratingKey), ['2']);
      });

      test('getPendingWatchActionsForServer filters by serverId', () async {
        await db.insertWatchAction(serverId: 'a', ratingKey: '1', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(serverId: 'b', ratingKey: '2', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(serverId: 'a', ratingKey: '3', actionType: OfflineActionType.unwatched.id);

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
                actionType: OfflineActionType.progress.id,
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
                actionType: OfflineActionType.watched.id,
                createdAt: now,
                updatedAt: now + 50,
              ),
            );

        final latest = await db.getLatestWatchAction('s:1');
        expect(latest, isNotNull);
        expect(latest!.actionType, OfflineActionType.watched.id);
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
                actionType: OfflineActionType.progress.id,
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
                actionType: OfflineActionType.watched.id,
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
                actionType: OfflineActionType.unwatched.id,
                createdAt: now,
                updatedAt: now,
              ),
            );

        final result = await db.getLatestWatchActionsForKeys({'s:1', 's:2', 's:3-missing'});
        expect(result.keys.toSet(), {'s:1', 's:2'});
        expect(result['s:1']!.actionType, OfflineActionType.watched.id);
        expect(result['s:2']!.actionType, OfflineActionType.unwatched.id);
      });

      test('getLatestWatchActionsForKeys filters by expected clientScopeId', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.offlineWatchProgress)
            .insert(
              OfflineWatchProgressCompanion.insert(
                serverId: 'jf',
                clientScopeId: const Value('jf/user-a'),
                ratingKey: '1',
                globalKey: 'jf:1',
                actionType: OfflineActionType.unwatched.id,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.offlineWatchProgress)
            .insert(
              OfflineWatchProgressCompanion.insert(
                serverId: 'jf',
                clientScopeId: const Value('jf/user-b'),
                ratingKey: '1',
                globalKey: 'jf:1',
                actionType: OfflineActionType.watched.id,
                createdAt: now,
                updatedAt: now + 100,
              ),
            );

        final userA = await db.getLatestWatchActionsForKeys({'jf:1'}, clientScopeIdsByGlobalKey: {'jf:1': 'jf/user-a'});
        final userB = await db.getLatestWatchActionsForKeys({'jf:1'}, clientScopeIdsByGlobalKey: {'jf:1': 'jf/user-b'});

        expect(userA['jf:1']!.actionType, OfflineActionType.unwatched.id);
        expect(userB['jf:1']!.actionType, OfflineActionType.watched.id);
      });

      test('getLatestWatchActionsForKeys filters by profile when requested', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.offlineWatchProgress)
            .insert(
              OfflineWatchProgressCompanion.insert(
                serverId: 's',
                profileId: const Value('profile-a'),
                ratingKey: '1',
                globalKey: 's:1',
                actionType: OfflineActionType.unwatched.id,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.offlineWatchProgress)
            .insert(
              OfflineWatchProgressCompanion.insert(
                serverId: 's',
                profileId: const Value('profile-b'),
                ratingKey: '1',
                globalKey: 's:1',
                actionType: OfflineActionType.watched.id,
                createdAt: now,
                updatedAt: now + 100,
              ),
            );

        final profileA = await db.getLatestWatchActionsForKeys({'s:1'}, profileId: 'profile-a', filterProfile: true);
        final profileB = await db.getLatestWatchActionsForKeys({'s:1'}, profileId: 'profile-b', filterProfile: true);
        final globalLatest = await db.getLatestWatchActionsForKeys({'s:1'});

        expect(profileA['s:1']!.actionType, OfflineActionType.unwatched.id);
        expect(profileB['s:1']!.actionType, OfflineActionType.watched.id);
        expect(globalLatest['s:1']!.actionType, OfflineActionType.watched.id);
      });

      test('getLatestWatchActionsForKeys with empty input returns empty map (no query)', () async {
        expect(await db.getLatestWatchActionsForKeys({}), isEmpty);
      });

      test('updateSyncAttempt increments syncAttempts and stores lastError', () async {
        await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.id);
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
        await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.watched.id);
        final rows = await db.select(db.offlineWatchProgress).get();
        expect(rows, hasLength(2));

        await db.deleteWatchAction(rows.first.id);
        expect(await db.select(db.offlineWatchProgress).get(), hasLength(1));
      });

      test('getPendingSyncCount counts every row', () async {
        expect(await db.getPendingSyncCount(), 0);

        await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.unwatched.id);
        expect(await db.getPendingSyncCount(), 2);
      });

      test('clearAllWatchActions empties the table', () async {
        await db.insertWatchAction(serverId: 's', ratingKey: '1', actionType: OfflineActionType.watched.id);
        await db.insertWatchAction(serverId: 's', ratingKey: '2', actionType: OfflineActionType.unwatched.id);

        await db.clearAllWatchActions();
        expect(await db.select(db.offlineWatchProgress).get(), isEmpty);
      });
    });
  }

  void _registerSyncRulesTests() {
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
        expect(rules.first.profileId, '');
        expect(rules.first.episodeCount, 5);
        expect(rules.first.enabled, isTrue); // default
        expect(rules.first.downloadFilter, 'unwatched'); // default
        expect(rules.first.mediaIndex, 0); // default
        expect(rules.first.lastExecutedAt, isNull);
      });

      test('insertSyncRule upserts on the UNIQUE globalKey instead of crashing', () async {
        // The auto-incremented primary key never collides, so a duplicate
        // globalKey would fail the UNIQUE constraint with a vanilla
        // `insertOnConflictUpdate`. The helper drives the upsert off
        // [globalKey] so re-creating a rule for the same target updates the
        // existing row rather than throwing.
        await db.insertSyncRule(
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'srv:10',
          targetType: 'show',
          episodeCount: 5,
        );
        await db.insertSyncRule(
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'srv:10',
          targetType: 'season',
          episodeCount: 99,
          downloadFilter: 'all',
        );

        final rules = await db.getSyncRules();
        expect(rules, hasLength(1));
        expect(rules.first.targetType, 'season');
        expect(rules.first.episodeCount, 99);
        expect(rules.first.downloadFilter, 'all');
      });

      test('insertSyncRule allows the same server item for different profiles', () async {
        await db.insertSyncRule(
          profileId: 'profile-a',
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'profile-a|srv:10',
          targetType: 'show',
          episodeCount: 5,
        );
        await db.insertSyncRule(
          profileId: 'profile-b',
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'profile-b|srv:10',
          targetType: 'show',
          episodeCount: 9,
        );

        expect(await db.getSyncRules(profileId: 'profile-a'), hasLength(1));
        expect((await db.getSyncRules(profileId: 'profile-a')).single.episodeCount, 5);
        expect(await db.getSyncRules(profileId: 'profile-b'), hasLength(1));
        expect((await db.getSyncRules(profileId: 'profile-b')).single.episodeCount, 9);
      });

      test('insertSyncRule preserves enabled + lastExecutedAt across upserts', () async {
        await db.insertSyncRule(
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'srv:10',
          targetType: 'show',
          episodeCount: 5,
        );
        await db.updateSyncRuleEnabled('srv:10', false);
        await db.updateSyncRuleLastExecuted('srv:10');
        final firstRun = (await db.getSyncRule('srv:10'))!;

        await db.insertSyncRule(
          serverId: 'srv',
          ratingKey: '10',
          globalKey: 'srv:10',
          targetType: 'show',
          episodeCount: 8,
        );
        final afterUpsert = (await db.getSyncRule('srv:10'))!;
        expect(afterUpsert.episodeCount, 8);
        expect(afterUpsert.enabled, isFalse, reason: 'upsert should preserve disabled flag');
        expect(afterUpsert.lastExecutedAt, firstRun.lastExecutedAt);
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
}
