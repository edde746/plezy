import 'package:drift/drift.dart';

import 'app_database.dart';
import '../models/download_models.dart';

/// Extension methods on AppDatabase for download operations
extension DownloadDatabaseOperations on AppDatabase {
  /// Insert a new download into the database
  Future<void> insertDownload({
    required String serverId,
    required String ratingKey,
    required String globalKey,
    required String type,
    String? parentRatingKey,
    String? grandparentRatingKey,
    required int status,
  }) async {
    await into(downloadedMedia).insert(
      DownloadedMediaCompanion.insert(
        serverId: serverId,
        ratingKey: ratingKey,
        globalKey: globalKey,
        type: type,
        parentRatingKey: Value(parentRatingKey),
        grandparentRatingKey: Value(grandparentRatingKey),
        status: status,
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
    await (delete(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(globalKey))).go();
  }

  /// Get all downloaded episodes for a season
  Future<List<DownloadedMediaItem>> getEpisodesBySeason(String seasonKey) {
    return (select(downloadedMedia)..where((t) => t.parentRatingKey.equals(seasonKey))).get();
  }

  /// Get all downloaded episodes for a show
  Future<List<DownloadedMediaItem>> getEpisodesByShow(String showKey) {
    return (select(downloadedMedia)..where((t) => t.grandparentRatingKey.equals(showKey))).get();
  }

  /// Get all downloaded items for a specific server
  Future<List<DownloadedMediaItem>> getDownloadsByServerId(String serverId) {
    return (select(downloadedMedia)..where((t) => t.serverId.equals(serverId))).get();
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
