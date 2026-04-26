import 'package:drift/drift.dart';

import 'app_database.dart';
import '../models/download_models.dart';
import '../profiles/profile.dart';

/// Extension methods on AppDatabase for download operations
extension DownloadDatabaseOperations on AppDatabase {
  Future<void> addDownloadOwner({required String profileId, required String globalKey}) async {
    if (profileId.isEmpty) return;
    await into(downloadOwners).insert(
      DownloadOwnersCompanion.insert(
        profileId: profileId,
        globalKey: globalKey,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeDownloadOwner({required String profileId, required String globalKey}) async {
    await (delete(downloadOwners)..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).go();
  }

  Future<void> removeDownloadOwnersForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    await (delete(downloadOwners)..where((t) => t.profileId.equals(profileId))).go();
  }

  Future<Set<String>> getDownloadOwnerKeysForProfile(String profileId) async {
    if (profileId.isEmpty) return const {};
    final rows = await (select(downloadOwners)..where((t) => t.profileId.equals(profileId))).get();
    return rows.map((row) => row.globalKey).toSet();
  }

  Future<int> getDownloadOwnerCount(String globalKey) async {
    return (await _validDownloadOwnerRows(globalKey)).length;
  }

  Future<bool> hasDownloadOwner(String globalKey, {String? excludingProfileId}) async {
    final rows = await _validDownloadOwnerRows(globalKey, excludingProfileId: excludingProfileId);
    return rows.isNotEmpty;
  }

  Future<List<DownloadOwnerItem>> _validDownloadOwnerRows(String globalKey, {String? excludingProfileId}) async {
    final rows = await (select(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).get();
    if (rows.isEmpty) return const [];
    final candidates = rows
        .where((row) => excludingProfileId == null || excludingProfileId.isEmpty || row.profileId != excludingProfileId)
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    final localProfileRows = await select(profiles).get();
    final localProfileIds = localProfileRows.map((row) => row.id).toSet();
    final connectionRows = await select(connections).get();
    final connectionIds = connectionRows.map((row) => row.id).toSet();
    return candidates
        .where((row) {
          if (localProfileIds.contains(row.profileId)) return true;
          final plexHome = parsePlexHomeProfileId(row.profileId);
          if (plexHome != null) return connectionIds.contains(plexHome.accountConnectionId);
          return localProfileIds.isEmpty;
        })
        .toList(growable: false);
  }

  /// Claim pre-v17 shared download rows for [profileId]. Rows that already
  /// have any owner are left untouched so later profiles do not inherit them.
  Future<void> adoptLegacyDownloadsForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    final rows = await select(downloadedMedia).get();
    for (final row in rows) {
      if (await getDownloadOwnerCount(row.globalKey) == 0) {
        await addDownloadOwner(profileId: profileId, globalKey: row.globalKey);
      }
    }
  }

  /// Insert a new download into the database.
  Future<void> insertDownload({
    required String serverId,
    String? clientScopeId,
    required String ratingKey,
    required String globalKey,
    required String type,
    String? parentRatingKey,
    String? grandparentRatingKey,
    required int status,
    int mediaIndex = 0,
  }) async {
    await into(downloadedMedia).insert(
      DownloadedMediaCompanion.insert(
        serverId: serverId,
        clientScopeId: Value(clientScopeId),
        ratingKey: ratingKey,
        globalKey: globalKey,
        type: type,
        parentRatingKey: Value(parentRatingKey),
        grandparentRatingKey: Value(grandparentRatingKey),
        status: status,
        mediaIndex: Value(mediaIndex),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Add item to download queue
  Future<void> addToQueue({
    required String mediaGlobalKey,
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
  }) async {
    await into(downloadQueue).insert(
      DownloadQueueCompanion.insert(
        mediaGlobalKey: mediaGlobalKey,
        priority: Value(priority),
        addedAt: DateTime.now().millisecondsSinceEpoch,
        downloadSubtitles: Value(downloadSubtitles),
        downloadArtwork: Value(downloadArtwork),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Get next item from queue (highest priority, oldest first)
  /// Only returns items that are not paused
  Future<DownloadQueueItem?> getNextQueueItem() async {
    // Join with downloadedMedia to check status and filter out paused items
    final query = select(
      downloadQueue,
    ).join([innerJoin(downloadedMedia, downloadedMedia.globalKey.equalsExp(downloadQueue.mediaGlobalKey))]);

    query
      ..where(downloadedMedia.status.equals(DownloadStatus.queued.index))
      ..orderBy([
        OrderingTerm(expression: downloadQueue.priority, mode: OrderingMode.desc),
        OrderingTerm(expression: downloadQueue.addedAt),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.readTable(downloadQueue);
  }

  /// Update download status
  Future<void> updateDownloadStatus(String globalKey, int status) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(status: Value(status)));
  }

  /// Update download progress
  Future<void> updateDownloadProgress(String globalKey, int progress, int downloadedBytes, int totalBytes) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        progress: Value(progress),
        downloadedBytes: Value(downloadedBytes),
        totalBytes: Value(totalBytes),
      ),
    );
  }

  /// Update video file path
  Future<void> updateVideoFilePath(String globalKey, String filePath) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        videoFilePath: Value(filePath),
        downloadedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Update artwork paths
  Future<void> updateArtworkPaths({required String globalKey, String? thumbPath}) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(thumbPath: Value(thumbPath)));
  }

  /// Update download error and increment retry count
  Future<void> updateDownloadError(String globalKey, String errorMessage) async {
    // Get current retry count to increment it
    final existing = await getDownloadedMedia(globalKey);
    final currentCount = existing?.retryCount ?? 0;

    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(errorMessage: Value(errorMessage), retryCount: Value(currentCount + 1)),
    );
  }

  /// Clear download error and reset retry count (for retry)
  Future<void> clearDownloadError(String globalKey) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      const DownloadedMediaCompanion(errorMessage: Value(null), retryCount: Value(0)),
    );
  }

  /// Remove item from queue
  Future<void> removeFromQueue(String mediaGlobalKey) async {
    await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(mediaGlobalKey))).go();
  }

  /// Get downloaded media item
  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) {
    return (select(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  /// Delete a download
  Future<void> deleteDownload(String globalKey) async {
    await (delete(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(globalKey))).go();
  }

  /// Get all downloaded episodes for a season
  Future<List<DownloadedMediaItem>> getEpisodesBySeason(
    String seasonKey, {
    String? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.parentRatingKey.equals(seasonKey) &
              _optionalServerPredicate(t.serverId, serverId) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  /// Get all downloaded episodes for a show
  Future<List<DownloadedMediaItem>> getEpisodesByShow(
    String showKey, {
    String? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.grandparentRatingKey.equals(showKey) &
              _optionalServerPredicate(t.serverId, serverId) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  /// Get all downloaded items for a specific server
  Future<List<DownloadedMediaItem>> getDownloadsByServerId(String serverId) {
    return (select(downloadedMedia)..where((t) => t.serverId.equals(serverId))).get();
  }

  Expression<bool> _optionalServerPredicate(GeneratedColumn<String> column, String? serverId) {
    return serverId == null ? const Constant(true) : column.equals(serverId);
  }

  Expression<bool> _optionalClientScopePredicate(
    GeneratedColumn<String> column,
    String? clientScopeId, {
    required bool filterClientScope,
  }) {
    if (!filterClientScope && (clientScopeId == null || clientScopeId.isEmpty)) {
      return const Constant(true);
    }
    if (clientScopeId == null || clientScopeId.isEmpty) {
      return column.isNull() | column.equals('');
    }
    return column.equals(clientScopeId);
  }

  /// Update the background_downloader task ID for a download
  Future<void> updateBgTaskId(String globalKey, String? taskId) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(bgTaskId: Value(taskId)));
  }

  /// Get the background_downloader task ID for a download
  Future<String?> getBgTaskId(String globalKey) async {
    final item = await getDownloadedMedia(globalKey);
    return item?.bgTaskId;
  }
}
