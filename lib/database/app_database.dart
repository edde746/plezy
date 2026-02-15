import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import '../models/download_models.dart';
import '../utils/app_logger.dart';

part 'app_database.g.dart';

// Simplified database with API cache for offline support
@DriftDatabase(tables: [DownloadedMedia, DownloadQueue, ApiCache, OfflineWatchProgress])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8; // Added bgTaskId column to DownloadedMedia

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
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
          await m.addColumn(downloadedMedia, downloadedMedia.bgTaskId);
        }
      },
    );
  }

  // ============================================================
  // Offline Watch Progress Operations
  // ============================================================

  /// Get all pending offline watch actions for sync
  Future<List<OfflineWatchProgressItem>> getPendingWatchActions() {
    return (select(offlineWatchProgress)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  /// Get pending watch actions for a specific server
  Future<List<OfflineWatchProgressItem>> getPendingWatchActionsForServer(String serverId) {
    return (select(offlineWatchProgress)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get the latest action for a specific item
  Future<OfflineWatchProgressItem?> getLatestWatchAction(String globalKey) {
    return (select(offlineWatchProgress)
          ..where((t) => t.globalKey.equals(globalKey))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get the latest actions for multiple items in a single query
  ///
  /// Returns a map of globalKey -> latest action for each key.
  /// Keys with no actions will not be present in the returned map.
  Future<Map<String, OfflineWatchProgressItem>> getLatestWatchActionsForKeys(Set<String> globalKeys) async {
    if (globalKeys.isEmpty) return {};

    // Query all actions for the given keys
    final allActions =
        await (select(offlineWatchProgress)
              ..where((t) => t.globalKey.isIn(globalKeys))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    // Group by globalKey and take the latest (first due to ordering)
    final result = <String, OfflineWatchProgressItem>{};
    for (final action in allActions) {
      // Only keep the first (latest) action for each key
      result.putIfAbsent(action.globalKey, () => action);
    }

    return result;
  }

  /// Insert or update a progress action (merges with existing)
  Future<void> upsertProgressAction({
    required String serverId,
    required String ratingKey,
    required int viewOffset,
    required int duration,
    required bool shouldMarkWatched,
  }) async {
    final globalKey = '$serverId:$ratingKey';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check for existing progress entry
    final existing =
        await (select(offlineWatchProgress)
              ..where((t) => t.globalKey.equals(globalKey) & t.actionType.equals('progress'))
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      // Update existing progress entry
      await (update(offlineWatchProgress)..where((t) => t.id.equals(existing.id))).write(
        OfflineWatchProgressCompanion(
          viewOffset: Value(viewOffset),
          duration: Value(duration),
          shouldMarkWatched: Value(shouldMarkWatched),
          updatedAt: Value(now),
        ),
      );
    } else {
      // Insert new progress entry
      await into(offlineWatchProgress).insert(
        OfflineWatchProgressCompanion.insert(
          serverId: serverId,
          ratingKey: ratingKey,
          globalKey: globalKey,
          actionType: 'progress',
          viewOffset: Value(viewOffset),
          duration: Value(duration),
          shouldMarkWatched: Value(shouldMarkWatched),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  /// Insert a manual watch action (watched or unwatched)
  /// Removes conflicting actions for the same item
  Future<void> insertWatchAction({
    required String serverId,
    required String ratingKey,
    required String actionType, // 'watched' or 'unwatched'
  }) async {
    final globalKey = '$serverId:$ratingKey';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Remove conflicting actions (opposite action type and progress)
    await (delete(offlineWatchProgress)..where((t) => t.globalKey.equals(globalKey))).go();

    // Insert the new action
    await into(offlineWatchProgress).insert(
      OfflineWatchProgressCompanion.insert(
        serverId: serverId,
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
  Future<int> getPendingSyncCount() async {
    final count = await (selectOnly(offlineWatchProgress)..addColumns([offlineWatchProgress.id.count()]))
        .map((row) => row.read(offlineWatchProgress.id.count()))
        .getSingle();
    return count ?? 0;
  }

  /// Clear all pending watch actions (e.g., after logout)
  Future<void> clearAllWatchActions() {
    return delete(offlineWatchProgress).go();
  }

  // ============================================================
  // Downloaded Media Queries for Watch State Sync
  // ============================================================

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

    // Ensure directory exists
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

    return NativeDatabase(file);
  });
}
