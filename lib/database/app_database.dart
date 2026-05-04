import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import '../models/download_models.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';

part 'app_database.g.dart';

/// Action queued in the offline watch-progress sync table. The serialized
/// form ([id]) is what gets persisted in [OfflineWatchProgress.actionType];
/// keep these strings stable across renames so existing rows resolve.
enum OfflineActionType {
  progress,
  watched,
  unwatched;

  /// Stable string id used for persistence. Survives an enum-name rename
  /// (e.g. `progress` → `inProgress`) — `.name` would corrupt every row.
  String get id => switch (this) {
    OfflineActionType.progress => 'progress',
    OfflineActionType.watched => 'watched',
    OfflineActionType.unwatched => 'unwatched',
  };

  /// Inverse of [id]. Throws on unknown so a typo in production doesn't
  /// silently fall back to the wrong action.
  static OfflineActionType fromId(String id) => switch (id) {
    'progress' => OfflineActionType.progress,
    'watched' => OfflineActionType.watched,
    'unwatched' => OfflineActionType.unwatched,
    _ => throw ArgumentError('Unknown OfflineActionType id: $id'),
  };
}

@DriftDatabase(
  tables: [
    DownloadedMedia,
    DownloadOwners,
    DownloadQueue,
    ApiCache,
    OfflineWatchProgress,
    SyncRules,
    Connections,
    Profiles,
    ProfileConnections,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor — inject an in-memory [QueryExecutor]
  /// (e.g. `NativeDatabase.memory()`) so tests don't touch real disk.
  @visibleForTesting
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // Enforce ProfileConnections → Profiles/Connections cascades.
      // Drift turns FKs *off* during migrations, so the per-connection
      // pragma we set in `_openConnection` is wiped on first open. This
      // hook runs after migrations and re-enables it for subsequent
      // queries — also applies to in-memory test databases that don't go
      // through `_openConnection`.
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 7) {
          appLogger.i('Adding OfflineWatchProgress table (v7 migration)');
          await m.createTable(offlineWatchProgress);
        }
        if (from < 8) {
          appLogger.i('Adding bgTaskId column to DownloadedMedia (v8 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.bgTaskId column',
            () => m.addColumn(downloadedMedia, downloadedMedia.bgTaskId),
          );
        }
        if (from < 9) {
          appLogger.i('Adding mediaIndex column to DownloadedMedia (v9 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.mediaIndex column',
            () => m.addColumn(downloadedMedia, downloadedMedia.mediaIndex),
          );
        }
        if (from < 10) {
          appLogger.i('Adding SyncRules table (v10 migration)');
          await m.createTable(syncRules);
        }
        if (from < 11) {
          appLogger.i('Adding enabled column to SyncRules (v11 migration)');
          await _ignoreAlreadyExists('SyncRules.enabled column', () => m.addColumn(syncRules, syncRules.enabled));
        }
        if (from < 12) {
          appLogger.i('Adding downloadFilter column to SyncRules (v12 migration)');
          await _ignoreAlreadyExists(
            'SyncRules.downloadFilter column',
            () => m.addColumn(syncRules, syncRules.downloadFilter),
          );
        }
        if (from < 13) {
          appLogger.i('Adding indexes on DownloadedMedia hot-queried columns (v13 migration)');
          final indexes = {
            'idx_downloaded_media_status': idxDownloadedMediaStatus,
            'idx_downloaded_media_server': idxDownloadedMediaServer,
            'idx_downloaded_media_parent': idxDownloadedMediaParent,
            'idx_downloaded_media_grandparent': idxDownloadedMediaGrandparent,
          };
          for (final entry in indexes.entries) {
            await _ignoreAlreadyExists('Index ${entry.key}', () => m.create(entry.value));
          }
        }
        if (from < 14) {
          appLogger.i(
            'Adding Connections, Profiles, ProfileConnections, DownloadOwners + scope/profile columns (v14 migration)',
          );

          await m.createTable(connections);
          await m.create(idxConnectionsKind);

          await m.createTable(profiles);
          await m.create(idxProfilesKind);

          await m.createTable(profileConnections);
          await m.create(idxProfileConnectionsConnectionId);
          await m.create(idxProfileConnectionsProfileId);

          await _ignoreAlreadyExists('DownloadOwners table', () => m.createTable(downloadOwners));
          await _ignoreAlreadyExists('Index idx_download_owners_profile', () => m.create(idxDownloadOwnersProfile));
          await _ignoreAlreadyExists(
            'Index idx_download_owners_global_key',
            () => m.create(idxDownloadOwnersGlobalKey),
          );

          await _ignoreAlreadyExists(
            'DownloadedMedia.clientScopeId column',
            () => m.addColumn(downloadedMedia, downloadedMedia.clientScopeId),
          );
          await _ignoreAlreadyExists(
            'OfflineWatchProgress.clientScopeId column',
            () => m.addColumn(offlineWatchProgress, offlineWatchProgress.clientScopeId),
          );
          await _ignoreAlreadyExists('SyncRules.profileId column', () => m.addColumn(syncRules, syncRules.profileId));
          await _ignoreAlreadyExists(
            'OfflineWatchProgress.profileId column',
            () => m.addColumn(offlineWatchProgress, offlineWatchProgress.profileId),
          );

          await customStatement('''
            UPDATE downloaded_media
            SET client_scope_id = (
              SELECT id FROM connections
              WHERE kind = 'jellyfin'
                AND substr(id, 1, length(downloaded_media.server_id) + 1) = downloaded_media.server_id || '/'
              LIMIT 1
            )
            WHERE client_scope_id IS NULL
              AND EXISTS (
                SELECT 1 FROM connections
                WHERE kind = 'jellyfin'
                  AND substr(id, 1, length(downloaded_media.server_id) + 1) = downloaded_media.server_id || '/'
              )
          ''');
          await customStatement('''
            UPDATE offline_watch_progress
            SET client_scope_id = (
              SELECT id FROM connections
              WHERE kind = 'jellyfin'
                AND substr(id, 1, length(offline_watch_progress.server_id) + 1) = offline_watch_progress.server_id || '/'
              LIMIT 1
            )
            WHERE client_scope_id IS NULL
              AND EXISTS (
                SELECT 1 FROM connections
                WHERE kind = 'jellyfin'
                  AND substr(id, 1, length(offline_watch_progress.server_id) + 1) = offline_watch_progress.server_id || '/'
              )
          ''');

          await m.create(idxOfflineWatchProgressServer);
          await _ignoreAlreadyExists('Index idx_sync_rules_profile', () => m.create(idxSyncRulesProfile));
          await _ignoreAlreadyExists(
            'Index idx_offline_watch_progress_profile',
            () => m.create(idxOfflineWatchProgressProfile),
          );
        }
      },
    );
  }

  Future<void> _ignoreAlreadyExists(String label, Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already exists') || message.contains('duplicate column name')) {
        appLogger.w('$label already exists during migration: $e');
        return;
      }
      rethrow;
    }
  }

  Expression<bool> _clientScopePredicate(GeneratedColumn<String> column, String? clientScopeId) {
    return clientScopeId == null ? column.isNull() : column.equals(clientScopeId);
  }

  Expression<bool> _nullableTextPredicate(GeneratedColumn<String> column, String? value) {
    return value == null ? column.isNull() : column.equals(value);
  }

  /// Get all pending offline watch actions for sync
  Future<List<OfflineWatchProgressItem>> getPendingWatchActions({String? profileId}) {
    final query = select(offlineWatchProgress)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    return query.get();
  }

  /// Claim pre-v18 offline watch actions for [profileId]. Those rows predate
  /// profile ownership and have `NULL profile_id`; the first active profile
  /// inherits them so already-watched offline progress is not stranded.
  Future<void> adoptLegacyOfflineWatchActionsForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    await (update(
      offlineWatchProgress,
    )..where((t) => t.profileId.isNull())).write(OfflineWatchProgressCompanion(profileId: Value(profileId)));
  }

  /// Get pending watch actions for a specific server
  Future<List<OfflineWatchProgressItem>> getPendingWatchActionsForServer(String serverId, {String? profileId}) {
    return (select(offlineWatchProgress)
          ..where(
            (t) =>
                t.serverId.equals(serverId) &
                (profileId == null ? const Constant(true) : t.profileId.equals(profileId)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get the latest action for a specific item
  Future<OfflineWatchProgressItem?> getLatestWatchAction(
    String globalKey, {
    String? profileId,
    bool filterProfile = false,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(offlineWatchProgress)
          ..where(
            (t) =>
                t.globalKey.equals(globalKey) &
                (filterProfile ? _nullableTextPredicate(t.profileId, profileId) : const Constant(true)) &
                (filterClientScope ? _clientScopePredicate(t.clientScopeId, clientScopeId) : const Constant(true)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get the latest actions for multiple items in a single query
  ///
  /// Returns a map of globalKey -> latest action for each key.
  /// Keys with no actions will not be present in the returned map.
  Future<Map<String, OfflineWatchProgressItem>> getLatestWatchActionsForKeys(
    Set<String> globalKeys, {
    String? profileId,
    bool filterProfile = false,
    Map<String, String?>? clientScopeIdsByGlobalKey,
  }) async {
    if (globalKeys.isEmpty) return {};

    // Query all actions for the given keys
    final allActions =
        await (select(offlineWatchProgress)
              ..where(
                (t) =>
                    t.globalKey.isIn(globalKeys) &
                    (filterProfile ? _nullableTextPredicate(t.profileId, profileId) : const Constant(true)),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    // Group by globalKey and take the latest (first due to ordering)
    final result = <String, OfflineWatchProgressItem>{};
    for (final action in allActions) {
      if (clientScopeIdsByGlobalKey != null && clientScopeIdsByGlobalKey.containsKey(action.globalKey)) {
        final expectedScope = clientScopeIdsByGlobalKey[action.globalKey];
        if (!_clientScopeValuesMatch(action.clientScopeId, expectedScope)) continue;
      }
      // Only keep the first (latest) action for each key
      result.putIfAbsent(action.globalKey, () => action);
    }

    return result;
  }

  bool _clientScopeValuesMatch(String? actual, String? expected) {
    final normalizedActual = actual == null || actual.isEmpty ? null : actual;
    final normalizedExpected = expected == null || expected.isEmpty ? null : expected;
    return normalizedActual == normalizedExpected;
  }

  /// Insert or update a progress action (merges with existing).
  Future<void> upsertProgressAction({
    String? profileId,
    required String serverId,
    String? clientScopeId,
    required String ratingKey,
    required int viewOffset,
    required int duration,
    required bool shouldMarkWatched,
  }) async {
    final globalKey = buildGlobalKey(serverId, ratingKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check for existing progress entry
    final existing =
        await (select(offlineWatchProgress)
              ..where(
                (t) =>
                    t.globalKey.equals(globalKey) &
                    _nullableTextPredicate(t.profileId, profileId) &
                    _clientScopePredicate(t.clientScopeId, clientScopeId) &
                    t.actionType.equals(OfflineActionType.progress.id),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      // Update existing progress entry
      await (update(offlineWatchProgress)..where((t) => t.id.equals(existing.id))).write(
        OfflineWatchProgressCompanion(
          viewOffset: Value(viewOffset),
          duration: Value(duration),
          shouldMarkWatched: Value(shouldMarkWatched),
          profileId: Value(profileId),
          clientScopeId: Value(clientScopeId),
          updatedAt: Value(now),
        ),
      );
    } else {
      // Insert new progress entry
      await into(offlineWatchProgress).insert(
        OfflineWatchProgressCompanion.insert(
          serverId: serverId,
          profileId: Value(profileId),
          clientScopeId: Value(clientScopeId),
          ratingKey: ratingKey,
          globalKey: globalKey,
          actionType: OfflineActionType.progress.id,
          viewOffset: Value(viewOffset),
          duration: Value(duration),
          shouldMarkWatched: Value(shouldMarkWatched),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  /// Insert a manual watch action (watched or unwatched).
  /// Removes conflicting actions for the same item.
  Future<void> insertWatchAction({
    String? profileId,
    required String serverId,
    String? clientScopeId,
    required String ratingKey,
    required String actionType, // 'watched' or 'unwatched'
  }) async {
    final globalKey = buildGlobalKey(serverId, ratingKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Remove conflicting actions (opposite action type and progress)
    await (delete(offlineWatchProgress)..where(
          (t) =>
              t.globalKey.equals(globalKey) &
              _nullableTextPredicate(t.profileId, profileId) &
              _clientScopePredicate(t.clientScopeId, clientScopeId),
        ))
        .go();

    // Insert the new action
    await into(offlineWatchProgress).insert(
      OfflineWatchProgressCompanion.insert(
        serverId: serverId,
        profileId: Value(profileId),
        clientScopeId: Value(clientScopeId),
        ratingKey: ratingKey,
        globalKey: globalKey,
        actionType: actionType,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Delete a specific watch action after successful sync
  Future<void> deleteWatchAction(int id) {
    return (delete(offlineWatchProgress)..where((t) => t.id.equals(id))).go();
  }

  /// Update sync attempt count and error message
  Future<void> updateSyncAttempt(int id, String? errorMessage) async {
    final existing = await (select(offlineWatchProgress)..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      await (update(offlineWatchProgress)..where((t) => t.id.equals(id))).write(
        OfflineWatchProgressCompanion(syncAttempts: Value(existing.syncAttempts + 1), lastError: Value(errorMessage)),
      );
    }
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount({String? profileId}) async {
    final query = selectOnly(offlineWatchProgress)..addColumns([offlineWatchProgress.id.count()]);
    if (profileId != null) {
      query.where(offlineWatchProgress.profileId.equals(profileId));
    }
    final count = await query.map((row) => row.read(offlineWatchProgress.id.count())).getSingle();
    return count ?? 0;
  }

  /// Clear all pending watch actions (e.g., after logout)
  Future<void> clearAllWatchActions() {
    return delete(offlineWatchProgress).go();
  }

  Future<List<SyncRuleItem>> getSyncRules({String? profileId}) {
    final query = select(syncRules);
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    return query.get();
  }

  Future<SyncRuleItem?> getSyncRule(String globalKey) {
    return (select(syncRules)..where((t) => t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  Future<void> insertSyncRule({
    String profileId = '',
    required String serverId,
    required String ratingKey,
    required String globalKey,
    required String targetType,
    required int episodeCount,
    int mediaIndex = 0,
    String downloadFilter = 'unwatched',
  }) async {
    // [insertOnConflictUpdate] defaults the conflict target to the primary
    // key (`id`), which is auto-incremented — the conflict never triggers
    // and the row's UNIQUE [globalKey] constraint blows up instead. Drive
    // the upsert off the public [globalKey] so re-creating a rule for the same
    // shared target updates the existing row.
    await into(syncRules).insert(
      SyncRulesCompanion.insert(
        serverId: serverId,
        profileId: Value(profileId),
        ratingKey: ratingKey,
        globalKey: globalKey,
        targetType: targetType,
        episodeCount: episodeCount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        mediaIndex: Value(mediaIndex),
        downloadFilter: Value(downloadFilter),
      ),
      onConflict: DoUpdate(
        (_) => SyncRulesCompanion(
          serverId: Value(serverId),
          profileId: Value(profileId),
          ratingKey: Value(ratingKey),
          targetType: Value(targetType),
          episodeCount: Value(episodeCount),
          mediaIndex: Value(mediaIndex),
          downloadFilter: Value(downloadFilter),
        ),
        target: [syncRules.globalKey],
      ),
    );
  }

  /// Claim pre-v16 public sync rules for [profileId]. Rules created before
  /// profile ownership have an empty profile id and a public global key.
  Future<void> adoptLegacySyncRulesForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    final legacyRules = await (select(syncRules)..where((t) => t.profileId.equals(''))).get();
    for (final rule in legacyRules) {
      final scopedKey = buildProfileScopedGlobalKey(profileId, rule.serverId, rule.ratingKey);
      final duplicate = await getSyncRule(scopedKey);
      if (duplicate != null) {
        await (delete(syncRules)..where((t) => t.id.equals(rule.id))).go();
        continue;
      }
      await (update(syncRules)..where((t) => t.id.equals(rule.id))).write(
        SyncRulesCompanion(profileId: Value(profileId), globalKey: Value(scopedKey)),
      );
    }
  }

  Future<void> updateSyncRuleCount(String globalKey, int episodeCount) async {
    await (update(
      syncRules,
    )..where((t) => t.globalKey.equals(globalKey))).write(SyncRulesCompanion(episodeCount: Value(episodeCount)));
  }

  Future<void> updateSyncRuleFilter(String globalKey, String downloadFilter) async {
    await (update(
      syncRules,
    )..where((t) => t.globalKey.equals(globalKey))).write(SyncRulesCompanion(downloadFilter: Value(downloadFilter)));
  }

  Future<void> updateSyncRuleEnabled(String globalKey, bool enabled) async {
    await (update(
      syncRules,
    )..where((t) => t.globalKey.equals(globalKey))).write(SyncRulesCompanion(enabled: Value(enabled)));
  }

  Future<void> updateSyncRuleLastExecuted(String globalKey) async {
    await (update(syncRules)..where((t) => t.globalKey.equals(globalKey))).write(
      SyncRulesCompanion(lastExecutedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<void> deleteSyncRule(String globalKey) async {
    await (delete(syncRules)..where((t) => t.globalKey.equals(globalKey))).go();
  }

  /// Get all downloaded media items (for syncing watch states)
  Future<List<DownloadedMediaItem>> getAllDownloadedMetadata() {
    return (select(downloadedMedia)..where((t) => t.status.equals(DownloadStatus.completed.index))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = (Platform.isAndroid || Platform.isIOS)
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();

    final file = File(p.join(dbFolder.path, 'plezy_downloads.db'));

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Migrate from old location on desktop (was in Documents subfolder)
    if (!Platform.isAndroid && !Platform.isIOS && !await file.exists()) {
      final oldFolder = await getApplicationDocumentsDirectory();
      final oldFile = File(p.join(oldFolder.path, 'plezy_downloads.db'));
      if (await oldFile.exists()) {
        await oldFile.rename(file.path);
      }
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL');
        db.execute('PRAGMA synchronous=NORMAL');
        // Enforce ProfileConnections → Profiles/Connections cascades.
        // SQLite requires this on every connection — it's not persisted.
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
