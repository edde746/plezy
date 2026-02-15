import 'dart:async';

import '../utils/io_helpers.dart';
import '../utils/platform_helper.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:plezy/utils/content_utils.dart';
import '../database/app_database.dart';
import 'settings_service.dart';
import 'saf_storage_service.dart';
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../services/plex_client.dart';
import '../services/download_storage_service.dart';
import '../services/plex_api_cache.dart';
import '../utils/app_logger.dart';
import '../utils/codec_utils.dart';
import '../utils/global_key_utils.dart';
import '../utils/plex_cache_parser.dart';

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
  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) async {
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

  /// Update the background_downloader task ID for a download
  Future<void> updateBgTaskId(String globalKey, String? taskId) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(bgTaskId: Value(taskId)),
    );
  }

  /// Get the background_downloader task ID for a download
  Future<String?> getBgTaskId(String globalKey) async {
    final item = await getDownloadedMedia(globalKey);
    return item?.bgTaskId;
  }
}

/// Context for a download that's been enqueued with background_downloader.
/// Carries metadata needed between enqueue and completion callback.
class _DownloadContext {
  final PlexMetadata metadata;
  final DownloadQueueItem queueItem;
  final String filePath; // Absolute path (normal) or SAF dir URI (SAF mode)
  final String extension;
  final PlexClient client;
  final int? showYear;
  final bool isSafMode;
  final PlexMediaInfo? mediaInfo;

  _DownloadContext({
    required this.metadata,
    required this.queueItem,
    required this.filePath,
    required this.extension,
    required this.client,
    this.showYear,
    this.isSafMode = false,
    this.mediaInfo,
  });
}

class DownloadManagerService {
  final AppDatabase _database;
  final DownloadStorageService _storageService;
  final PlexApiCache _apiCache = PlexApiCache.instance;
  final Dio _dio;

  // Stream controller for download progress updates
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  // Stream controller for deletion progress updates
  final _deletionProgressController = StreamController<DeletionProgress>.broadcast();
  Stream<DeletionProgress> get deletionProgressStream => _deletionProgressController.stream;

  // Context for downloads enqueued in this session
  final Map<String, _DownloadContext> _pendingDownloadContext = {};

  // Items recovered with video complete but supplementary downloads missing
  final Set<String> _pendingSupplementaryDownloads = {};

  // Cached client for recovery and queue processing
  PlexClient? _lastClient;

  // background_downloader state
  bool _fileDownloaderInitialized = false;
  static const _downloadGroup = 'video_downloads';

  // Keys currently being paused — prevents holding queue from promoting them
  final Set<String> _pausingKeys = {};

  // Prevents concurrent _processQueue calls
  bool _isProcessingQueue = false;

  /// Public method to check if downloads should be blocked due to cellular-only setting
  /// Can be used by DownloadProvider to show user-friendly error
  static Future<bool> shouldBlockDownloadOnCellular() async {
    final settings = await SettingsService.getInstance();
    if (!settings.getDownloadOnWifiOnly()) return false;

    final connectivity = await Connectivity().checkConnectivity();
    // Block if on cellular and NOT on WiFi (allow if both are available)
    return connectivity.contains(ConnectivityResult.mobile) &&
        !connectivity.contains(ConnectivityResult.wifi) &&
        !connectivity.contains(ConnectivityResult.ethernet);
  }

  /// Future that completes when interrupted download recovery finishes.
  /// Await this before reading download state from the DB to avoid races.
  late final Future<void> recoveryFuture;

  DownloadManagerService({required AppDatabase database, required DownloadStorageService storageService, Dio? dio})
    : _database = database,
      _storageService = storageService,
      _dio = dio ?? Dio();

  /// Initialize background_downloader with callbacks, notifications, and concurrency config.
  Future<void> _initializeFileDownloader() async {
    if (_fileDownloaderInitialized) return;

    FileDownloader()
        .registerCallbacks(
          group: _downloadGroup,
          taskStatusCallback: _onTaskStatusChanged,
          taskProgressCallback: _onTaskProgress,
        )
        .configureNotificationForGroup(
          _downloadGroup,
          running: const TaskNotification('{displayName}', 'Downloading...'),
          complete: const TaskNotification('{displayName}', 'Download complete'),
          error: const TaskNotification('{displayName}', 'Download failed'),
          paused: const TaskNotification('{displayName}', 'Download paused'),
          progressBar: true,
        );

    // Configure native holding queue: max 1 concurrent (Plex server limitation)
    await FileDownloader().configure(globalConfig: (Config.holdingQueue, (1, 1, 1)));

    // Track tasks for persistence across app restarts
    await FileDownloader().trackTasks();

    _fileDownloaderInitialized = true;
  }

  /// Recover downloads that were interrupted when the app was killed.
  /// Uses background_downloader's rescheduleKilledTasks for native recovery,
  /// then scans drift for orphaned items.
  Future<void> recoverInterruptedDownloads() async {
    try {
      await _initializeFileDownloader();

      // Let background_downloader re-enqueue tasks killed by the OS
      final (rescheduled, _) = await FileDownloader().rescheduleKilledTasks();
      if (rescheduled.isNotEmpty) {
        appLogger.i('Rescheduled ${rescheduled.length} killed download task(s)');
      }

      // Scan drift for orphaned items stuck in 'downloading'
      final allDownloads = await _database.select(_database.downloadedMedia).get();

      for (final item in allDownloads) {
        if (item.status == DownloadStatus.downloading.index) {
          // Video already downloaded but post-processing didn't complete
          if (item.videoFilePath != null) {
            appLogger.i('Download ${item.globalKey} has video but incomplete post-processing, completing');
            await _database.updateDownloadStatus(item.globalKey, DownloadStatus.completed.index);
            await _database.removeFromQueue(item.globalKey);
            _emitProgress(item.globalKey, DownloadStatus.completed, 100);
            _pendingSupplementaryDownloads.add(item.globalKey);
            continue;
          }

          // Check if background_downloader still has this task
          Task? bgTask;
          if (item.bgTaskId != null) {
            bgTask = await FileDownloader().taskForId(item.bgTaskId!);
          }

          if (bgTask == null) {
            // No active bg task — orphan, re-queue it
            appLogger.i('Re-queuing orphaned download: ${item.globalKey}');
            await _database.updateDownloadStatus(item.globalKey, DownloadStatus.queued.index);
            await _database.updateBgTaskId(item.globalKey, null);
            await _database.addToQueue(mediaGlobalKey: item.globalKey);
          }
          // If bgTask exists, background_downloader is still handling it
        }
      }
    } catch (e) {
      appLogger.e('Failed to recover interrupted downloads', error: e);
    }
  }

  /// Resume queued downloads that have no active processing.
  /// Call after a PlexClient becomes available (e.g. after server connect on launch).
  void resumeQueuedDownloads(PlexClient client) {
    _lastClient = client;

    // Attempt deferred supplementary downloads for recovered items
    _processPendingSupplementaryDownloads(client);

    _database.getNextQueueItem().then((item) {
      if (item != null) {
        appLogger.i('Resuming queued downloads after app restart');
        _processQueue(client);
      }
    });
  }

  /// Attempt supplementary downloads (artwork, subtitles) for items that were
  /// recovered with a completed video but missed post-processing.
  Future<void> _processPendingSupplementaryDownloads(PlexClient client) async {
    if (_pendingSupplementaryDownloads.isEmpty) return;

    final keys = Set<String>.from(_pendingSupplementaryDownloads);
    _pendingSupplementaryDownloads.clear();

    for (final globalKey in keys) {
      try {
        final metadata = await _resolveMetadata(globalKey);
        if (metadata == null) {
          appLogger.w('No metadata for deferred supplementary download: $globalKey');
          continue;
        }

        // Look up show year for episodes
        int? showYear;
        if (metadata.type == 'episode' && metadata.grandparentRatingKey != null) {
          final parsed = parseGlobalKey(globalKey);
          if (parsed != null) {
            final showCached = await _apiCache.get(parsed.serverId, '/library/metadata/${metadata.grandparentRatingKey}');
            final showJson = PlexCacheParser.extractFirstMetadata(showCached);
            if (showJson != null) showYear = PlexMetadata.fromJson(showJson).year;
          }
        }

        await _downloadArtwork(globalKey, metadata, client, showYear: showYear);
        await _downloadChapterThumbnails(metadata.serverId!, metadata.ratingKey, client);

        // Attempt subtitles
        try {
          final playbackData = await client.getVideoPlaybackData(metadata.ratingKey);
          if (playbackData.mediaInfo != null) {
            await _downloadSubtitles(globalKey, metadata, playbackData.mediaInfo!, client, showYear: showYear);
          }
        } catch (e) {
          appLogger.w('Could not fetch playback data for deferred subtitles: $globalKey', error: e);
        }

        appLogger.i('Deferred supplementary downloads completed for $globalKey');
      } catch (e) {
        appLogger.w('Deferred supplementary downloads failed for $globalKey', error: e);
      }
    }
  }

  /// Delete a file if it exists and log the deletion
  /// Returns true if file was deleted, false otherwise
  Future<bool> _deleteFileIfExists(File file, String description) async {
    if (await file.exists()) {
      await file.delete();
      appLogger.i('Deleted $description: ${file.path}');
      return true;
    }
    return false;
  }

  /// Queue a download for a media item
  Future<void> queueDownload({
    required PlexMetadata metadata,
    required PlexClient client,
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
  }) async {
    final globalKey = '${metadata.serverId}:${metadata.ratingKey}';

    // Check if already downloading or completed
    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing != null &&
        (existing.status == DownloadStatus.downloading.index || existing.status == DownloadStatus.completed.index)) {
      appLogger.i('Download already exists for $globalKey with status ${existing.status}');
      return;
    }

    // Insert into database
    await _database.insertDownload(
      serverId: metadata.serverId!,
      ratingKey: metadata.ratingKey,
      globalKey: globalKey,
      type: metadata.type,
      parentRatingKey: metadata.parentRatingKey,
      grandparentRatingKey: metadata.grandparentRatingKey,
      status: DownloadStatus.queued.index,
    );

    // Pin the already-cached API response for offline use
    // (getMetadataWithImages was already called by download_provider, which cached with chapters/markers)
    await _apiCache.pinForOffline(metadata.serverId!, metadata.ratingKey);

    // Add to queue
    await _database.addToQueue(
      mediaGlobalKey: globalKey,
      priority: priority,
      downloadSubtitles: downloadSubtitles,
      downloadArtwork: downloadArtwork,
    );

    _emitProgress(globalKey, DownloadStatus.queued, 0);

    // Start processing if not already
    _processQueue(client);
  }

  /// Process the download queue — prepares and enqueues items with background_downloader.
  /// Non-blocking: returns after all queued items are enqueued (downloads run natively).
  Future<void> _processQueue(PlexClient client) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    _lastClient = client;

    try {
      await _initializeFileDownloader();

      while (true) {
        final nextItem = await _database.getNextQueueItem();
        if (nextItem == null) break;

        await _prepareAndEnqueueDownload(nextItem.mediaGlobalKey, client, nextItem);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Resolve metadata, video URL, and file path, then enqueue a background download task.
  Future<void> _prepareAndEnqueueDownload(String globalKey, PlexClient client, DownloadQueueItem queueItem) async {
    try {
      appLogger.i('Preparing download for $globalKey');
      await _transitionStatus(globalKey, DownloadStatus.downloading);

      final parsed = parseGlobalKey(globalKey);
      if (parsed == null) throw Exception('Invalid globalKey: $globalKey');
      final serverId = parsed.serverId;
      final ratingKey = parsed.ratingKey;

      final metadata = await _apiCache.getMetadata(serverId, ratingKey);
      if (metadata == null) throw Exception('Metadata not found in cache for $globalKey');

      final playbackData = await client.getVideoPlaybackData(metadata.ratingKey);
      if (playbackData.videoUrl == null) throw Exception('Could not get video URL');

      final ext = _getExtensionFromUrl(playbackData.videoUrl!) ?? 'mp4';

      // Look up show year for episodes
      int? showYear;
      if (metadata.type == 'episode' && metadata.grandparentRatingKey != null) {
        final showCached = await _apiCache.get(serverId, '/library/metadata/${metadata.grandparentRatingKey}');
        final showJson = PlexCacheParser.extractFirstMetadata(showCached);
        if (showJson != null) showYear = PlexMetadata.fromJson(showJson).year;
      }

      // Build display name for notifications
      final displayName =
          metadata.type == 'episode' ? '${metadata.grandparentTitle ?? metadata.title} - ${metadata.title}' : metadata.title;

      // Get WiFi-only setting for native enforcement
      final settings = await SettingsService.getInstance();
      final requiresWiFi = settings.getDownloadOnWifiOnly();

      if (_storageService.isUsingSaf) {
        // SAF mode: use UriDownloadTask (writes directly to content:// URI, no pause/resume)
        final List<String> pathComponents;
        final String safFileName;
        if (metadata.type == 'movie') {
          pathComponents = _storageService.getMovieSafPathComponents(metadata);
          safFileName = _storageService.getMovieSafFileName(metadata, ext);
        } else if (metadata.type == 'episode') {
          pathComponents = _storageService.getEpisodeSafPathComponents(metadata, showYear: showYear);
          safFileName = _storageService.getEpisodeSafFileName(metadata, ext);
        } else {
          pathComponents = [serverId, metadata.ratingKey];
          safFileName = 'video.$ext';
        }

        final safDirUri = await SafStorageService.instance.createNestedDirectories(
          _storageService.safBaseUri!,
          pathComponents,
        );
        if (safDirUri == null) throw Exception('Failed to create SAF directory');

        final task = UriDownloadTask(
          url: playbackData.videoUrl!,
          filename: safFileName,
          directoryUri: Uri.parse(safDirUri),
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: 3,
          metaData: globalKey,
          displayName: displayName,
        );

        _pendingDownloadContext[globalKey] = _DownloadContext(
          metadata: metadata,
          queueItem: queueItem,
          filePath: safDirUri,
          extension: ext,
          client: client,
          showYear: showYear,
          isSafMode: true,
          mediaInfo: playbackData.mediaInfo,
        );

        await _database.updateBgTaskId(globalKey, task.taskId);
        final success = await FileDownloader().enqueue(task);
        if (!success) throw Exception('Failed to enqueue SAF download task');
        appLogger.i('Enqueued SAF download task ${task.taskId} for $globalKey');
      } else {
        // Normal mode: use DownloadTask with pause/resume support
        String downloadFilePath;
        if (metadata.type == 'movie') {
          downloadFilePath = await _storageService.getMovieVideoPath(metadata, ext);
        } else if (metadata.type == 'episode') {
          downloadFilePath = await _storageService.getEpisodeVideoPath(metadata, ext, showYear: showYear);
        } else {
          downloadFilePath = await _storageService.getVideoFilePath(serverId, metadata.ratingKey, ext);
        }

        await File(downloadFilePath).parent.create(recursive: true);

        final task = DownloadTask(
          url: playbackData.videoUrl!,
          filename: path.basename(downloadFilePath),
          directory: path.dirname(downloadFilePath),
          baseDirectory: BaseDirectory.root,
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: 3,
          allowPause: true,
          metaData: globalKey,
          displayName: displayName,
        );

        _pendingDownloadContext[globalKey] = _DownloadContext(
          metadata: metadata,
          queueItem: queueItem,
          filePath: downloadFilePath,
          extension: ext,
          client: client,
          showYear: showYear,
          mediaInfo: playbackData.mediaInfo,
        );

        await _database.updateBgTaskId(globalKey, task.taskId);
        final success = await FileDownloader().enqueue(task);
        if (!success) throw Exception('Failed to enqueue download task');
        appLogger.i('Enqueued download task ${task.taskId} for $globalKey');
      }
    } catch (e) {
      appLogger.e('Failed to prepare download for $globalKey', error: e);
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: e.toString());
      await _database.updateDownloadError(globalKey, e.toString());
      await _database.removeFromQueue(globalKey);
      _pendingDownloadContext.remove(globalKey);
    }
  }

  /// Callback: background_downloader progress update
  void _onTaskProgress(TaskProgressUpdate update) {
    final globalKey = update.task.metaData;
    if (globalKey.isEmpty || update.progress < 0) return;

    // If this item is being paused, the holding queue promoted it — cancel it
    if (_pausingKeys.contains(globalKey)) {
      FileDownloader().cancelTaskWithId(update.task.taskId);
      return;
    }

    final progress = (update.progress * 100).round().clamp(0, 100);
    final speedBytesPerSec = update.hasNetworkSpeed ? update.networkSpeed * 1024 * 1024 : 0.0;
    final totalBytes = update.hasExpectedFileSize ? update.expectedFileSize : 0;
    final downloadedBytes = totalBytes > 0 ? (update.progress * totalBytes).round() : 0;

    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: DownloadStatus.downloading,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        speed: speedBytesPerSec,
        currentFile: 'video',
      ),
    );

    _database.updateDownloadProgress(globalKey, progress, downloadedBytes, totalBytes).catchError((e) {
      appLogger.w('Failed to update download progress in DB', error: e);
    });
  }

  /// Callback: background_downloader status change
  void _onTaskStatusChanged(TaskStatusUpdate update) {
    final globalKey = update.task.metaData;
    if (globalKey.isEmpty) return;

    appLogger.d('Background task status: ${update.status} for $globalKey');

    switch (update.status) {
      case TaskStatus.complete:
        _onDownloadComplete(globalKey, update.task);
      case TaskStatus.failed:
        _onDownloadFailed(globalKey, update.exception?.description ?? 'Download failed');
      case TaskStatus.notFound:
        _onDownloadFailed(globalKey, 'File not found (404)');
      case TaskStatus.canceled:
        if (_pausingKeys.contains(globalKey)) {
          // Expected cancel from holding-queue promotion during pause — ignore
          break;
        }
        final ctx = _pendingDownloadContext.remove(globalKey);
        if (ctx != null) {
          // Context still present → OS cancelled the task, not user code
          // (user-initiated pause/cancel/delete removes context before cancellation completes)
          appLogger.w('Download cancelled by system for $globalKey, re-queuing');
          _database.updateBgTaskId(globalKey, null);
          _transitionStatus(globalKey, DownloadStatus.queued);
          _database.addToQueue(mediaGlobalKey: globalKey);
          if (_lastClient != null) _processQueue(_lastClient!);
        }
      case TaskStatus.paused:
        appLogger.d('Download paused by system for $globalKey');
      case TaskStatus.waitingToRetry:
        appLogger.d('Download waiting to retry for $globalKey');
      case TaskStatus.enqueued:
      case TaskStatus.running:
        // If this item is being paused, the holding queue promoted it — cancel it
        if (_pausingKeys.contains(globalKey)) {
          FileDownloader().cancelTaskWithId(update.task.taskId);
        }
        break;
    }
  }

  /// Handle a permanently failed download
  Future<void> _onDownloadFailed(String globalKey, String errorMessage) async {
    _pendingDownloadContext.remove(globalKey);
    appLogger.e('Download failed for $globalKey: $errorMessage');
    await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: errorMessage);
    await _database.updateDownloadError(globalKey, errorMessage);
    await _database.removeFromQueue(globalKey);

    // Try to enqueue more items from the queue
    if (_lastClient != null) _processQueue(_lastClient!);
  }

  /// Handle a completed video download — store path, download supplementary content, mark done.
  Future<void> _onDownloadComplete(String globalKey, Task task) async {
    try {
      final ctx = _pendingDownloadContext.remove(globalKey);

      // ── Phase 1 (critical): resolve and store the video file path ──
      final String storedPath;
      if (ctx != null) {
        // Happy path: context available from this session
        if (ctx.isSafMode) {
          // UriDownloadTask wrote directly to SAF — find the file URI
          final child = await SafStorageService.instance.getChild(ctx.filePath, task.filename);
          if (child != null) {
            storedPath = child.uri;
          } else {
            storedPath = await _resolveSafStoredPath(ctx.metadata, ctx.extension, ctx.showYear) ?? '';
            if (storedPath.isEmpty) throw Exception('Cannot determine SAF file URI');
          }
        } else {
          storedPath = await _storageService.toRelativePath(ctx.filePath);
        }
      } else {
        // Recovery path: context missing (app was restarted)
        final existing = await _database.getDownloadedMedia(globalKey);
        if (existing?.videoFilePath != null && existing?.status == DownloadStatus.completed.index) {
          appLogger.d('Download already completed for $globalKey');
          return;
        }
        if (existing?.videoFilePath != null) {
          // Video path set but status not completed — just finish up
          storedPath = existing!.videoFilePath!;
        } else if (task is UriDownloadTask) {
          // SAF mode recovery: re-derive path from metadata
          final parsed = parseGlobalKey(globalKey);
          if (parsed == null) throw Exception('Invalid globalKey for recovery: $globalKey');
          final metadata = await _apiCache.getMetadata(parsed.serverId, parsed.ratingKey);
          if (metadata == null) throw Exception('No metadata for SAF recovery of $globalKey');
          final ext = _getExtensionFromUrl(task.url) ?? 'mp4';
          storedPath = await _resolveSafStoredPath(metadata, ext, null) ?? '';
          if (storedPath.isEmpty) throw Exception('Cannot resolve SAF path on recovery');
        } else {
          // Normal mode recovery: reconstruct from task
          storedPath = await _storageService.toRelativePath('${task.directory}/${task.filename}');
        }
      }

      // Store video path in DB
      await _database.updateVideoFilePath(globalKey, storedPath);
      appLogger.d('Video download completed for $globalKey');

      // ── Phase 2 (best-effort): supplementary downloads ──
      try {
        final metadata = ctx?.metadata ?? await _resolveMetadata(globalKey);
        final client = ctx?.client ?? _lastClient;
        final showYear = ctx?.showYear;

        // Get queue item settings (still in drift at this point)
        final queueItem =
            ctx?.queueItem ??
            await (_database.select(_database.downloadQueue)..where((t) => t.mediaGlobalKey.equals(globalKey)))
                .getSingleOrNull();
        final downloadArtwork = queueItem?.downloadArtwork ?? true;
        final downloadSubtitles = queueItem?.downloadSubtitles ?? true;

        if (metadata != null && client != null) {
          if (downloadArtwork) {
            await _downloadArtwork(globalKey, metadata, client, showYear: showYear);
            await _downloadChapterThumbnails(metadata.serverId!, metadata.ratingKey, client);
          }
          if (downloadSubtitles) {
            PlexMediaInfo? mediaInfo = ctx?.mediaInfo;
            if (mediaInfo == null) {
              try {
                final playbackData = await client.getVideoPlaybackData(metadata.ratingKey);
                mediaInfo = playbackData.mediaInfo;
              } catch (e) {
                appLogger.w('Could not re-fetch playback data for subtitles', error: e);
              }
            }
            if (mediaInfo != null) {
              await _downloadSubtitles(globalKey, metadata, mediaInfo, client, showYear: showYear);
            }
          }
        }
      } catch (e) {
        appLogger.w('Supplementary downloads failed for $globalKey (video is saved)', error: e);
      }

      // Mark as completed — video is saved regardless of supplementary outcome
      await _transitionStatus(globalKey, DownloadStatus.completed);
      await _database.removeFromQueue(globalKey);
      appLogger.i('Download completed for $globalKey');
    } catch (e) {
      appLogger.e('Post-download processing failed for $globalKey', error: e);
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: 'Post-processing failed: $e');
      await _database.updateDownloadError(globalKey, 'Post-processing failed: $e');
      await _database.removeFromQueue(globalKey);
    } finally {
      // Always advance the queue, even after errors
      if (_lastClient != null) _processQueue(_lastClient!);
    }
  }

  /// Resolve metadata from cache using a globalKey
  Future<PlexMetadata?> _resolveMetadata(String globalKey) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;
    return _apiCache.getMetadata(parsed.serverId, parsed.ratingKey);
  }

  /// Re-derive the SAF file URI from metadata (for recovery when context is lost)
  Future<String?> _resolveSafStoredPath(PlexMetadata metadata, String ext, int? showYear) async {
    final safBaseUri = _storageService.safBaseUri;
    if (safBaseUri == null) return null;

    final List<String> pathComponents;
    final String safFileName;
    if (metadata.type == 'movie') {
      pathComponents = _storageService.getMovieSafPathComponents(metadata);
      safFileName = _storageService.getMovieSafFileName(metadata, ext);
    } else if (metadata.type == 'episode') {
      pathComponents = _storageService.getEpisodeSafPathComponents(metadata, showYear: showYear);
      safFileName = _storageService.getEpisodeSafFileName(metadata, ext);
    } else {
      pathComponents = [metadata.serverId!, metadata.ratingKey];
      safFileName = 'video.$ext';
    }

    final dirUri = await SafStorageService.instance.createNestedDirectories(safBaseUri, pathComponents);
    if (dirUri == null) return null;

    final child = await SafStorageService.instance.getChild(dirUri, safFileName);
    return child?.uri;
  }

  /// Download artwork for a media item using hash-based storage
  /// Downloads all artwork types: thumb/poster, clearLogo, and background art
  Future<void> _downloadArtwork(String globalKey, PlexMetadata metadata, PlexClient client, {int? showYear}) async {
    if (metadata.serverId == null) return;

    try {
      _emitProgress(globalKey, DownloadStatus.downloading, 0, currentFile: 'artwork');

      final serverId = metadata.serverId!;

      // Download thumb/poster
      if (metadata.thumb != null) {
        await _downloadSingleArtwork(serverId, metadata.thumb!, client);
      }

      // Download clear logo
      if (metadata.clearLogo != null) {
        await _downloadSingleArtwork(serverId, metadata.clearLogo!, client);
      }

      // Download background art
      if (metadata.art != null) {
        await _downloadSingleArtwork(serverId, metadata.art!, client);
      }

      // Store thumb reference in database (primary artwork for display)
      await _database.updateArtworkPaths(globalKey: globalKey, thumbPath: metadata.thumb);

      _emitProgressWithArtwork(globalKey, thumbPath: metadata.thumb);
      appLogger.d('Artwork downloaded for $globalKey');
    } catch (e) {
      appLogger.w('Failed to download artwork for $globalKey', error: e);
      // Don't fail the entire download if artwork fails
    }
  }

  /// Download a single artwork file if it doesn't already exist
  Future<void> _downloadSingleArtwork(String serverId, String artworkPath, PlexClient client) async {
    try {
      // Check if already downloaded (deduplication)
      if (await _storageService.artworkExists(serverId, artworkPath)) {
        appLogger.d('Artwork already exists: $artworkPath');
        return;
      }

      final url = client.getThumbnailUrl(artworkPath);
      if (url.isEmpty) {
        appLogger.w('Empty thumbnail URL for: $artworkPath');
        return;
      }

      final filePath = await _storageService.getArtworkPathFromThumb(serverId, artworkPath);
      final file = File(filePath);

      // Ensure parent directory exists
      await file.parent.create(recursive: true);

      // Download the artwork
      await _dio.download(url, filePath);
      appLogger.i('Downloaded artwork: $artworkPath -> $filePath');
    } catch (e, stack) {
      appLogger.w('Failed to download artwork: $artworkPath', error: e, stackTrace: stack);
      // Don't throw - artwork download failures shouldn't kill the entire download
    }
  }

  /// Download all artwork for a metadata item (public method for parent metadata)
  /// Downloads thumb/poster, clearLogo, and background art
  Future<void> downloadArtworkForMetadata(PlexMetadata metadata, PlexClient client) async {
    if (metadata.serverId == null) return;
    final serverId = metadata.serverId!;

    // Download thumb/poster
    if (metadata.thumb != null) {
      await _downloadSingleArtwork(serverId, metadata.thumb!, client);
    }

    // Download clear logo
    if (metadata.clearLogo != null) {
      await _downloadSingleArtwork(serverId, metadata.clearLogo!, client);
    }

    // Download background art
    if (metadata.art != null) {
      await _downloadSingleArtwork(serverId, metadata.art!, client);
    }
  }

  /// Download chapter thumbnail images for a media item
  Future<void> _downloadChapterThumbnails(String serverId, String ratingKey, PlexClient client) async {
    try {
      // Get chapters from the cached API response
      final extras = await client.getPlaybackExtras(ratingKey);

      for (final chapter in extras.chapters) {
        if (chapter.thumb != null) {
          await _downloadSingleArtwork(serverId, chapter.thumb!, client);
        }
      }

      if (extras.chapters.isNotEmpty) {
        appLogger.d('Downloaded ${extras.chapters.length} chapter thumbnails');
      }
    } catch (e) {
      appLogger.w('Failed to download chapter thumbnails', error: e);
      // Don't fail the entire download if chapter thumbnails fail
    }
  }

  /// [showYear]: For episodes, pass the show's premiere year (not the episode's year)
  Future<void> _downloadSubtitles(
    String globalKey,
    PlexMetadata metadata,
    PlexMediaInfo mediaInfo,
    PlexClient client, {
    int? showYear,
  }) async {
    try {
      _emitProgress(globalKey, DownloadStatus.downloading, 0, currentFile: 'subtitles');

      for (final subtitle in mediaInfo.subtitleTracks) {
        // Only download external subtitles
        if (!subtitle.isExternal || subtitle.key == null) {
          continue;
        }

        final baseUrl = client.config.baseUrl;
        final token = client.config.token ?? '';
        final subtitleUrl = subtitle.getSubtitleUrl(baseUrl, token);
        if (subtitleUrl == null) continue;

        // Determine file extension
        final extension = CodecUtils.getSubtitleExtension(subtitle.codec);

        // Get user-friendly subtitle path based on media type
        final String subtitlePath;
        if (metadata.isEpisode) {
          subtitlePath = await _storageService.getEpisodeSubtitlePath(
            metadata,
            subtitle.id,
            extension,
            showYear: showYear,
          );
        } else if (metadata.isMovie) {
          subtitlePath = await _storageService.getMovieSubtitlePath(metadata, subtitle.id, extension);
        } else {
          // Fallback to old structure
          subtitlePath = await _storageService.getSubtitlePath(
            metadata.serverId!,
            metadata.ratingKey,
            subtitle.id,
            extension,
          );
        }

        // Download subtitle file
        final file = File(subtitlePath);
        await file.parent.create(recursive: true);
        await _dio.download(subtitleUrl, subtitlePath);

        appLogger.d('Downloaded subtitle ${subtitle.id} for $globalKey');
      }
    } catch (e) {
      appLogger.w('Failed to download subtitles for $globalKey', error: e);
      // Don't fail the entire download if subtitles fail
    }
  }

  String? _getExtensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return null;
    return path.substring(lastDot + 1).split('?').first;
  }

  void _emitProgress(
    String globalKey,
    DownloadStatus status,
    int progress, {
    String? errorMessage,
    String? currentFile,
  }) {
    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: status,
        progress: progress,
        errorMessage: errorMessage,
        currentFile: currentFile,
      ),
    );
  }

  /// Update download status in database and emit progress notification.
  ///
  /// This helper combines two common operations:
  /// 1. Update status in the database
  /// 2. Emit progress to listeners
  ///
  /// Default progress is 0 for most statuses, 100 for completed.
  Future<void> _transitionStatus(String globalKey, DownloadStatus status, {int? progress, String? errorMessage}) async {
    await _database.updateDownloadStatus(globalKey, status.index);
    _emitProgress(
      globalKey,
      status,
      progress ?? (status == DownloadStatus.completed ? 100 : 0),
      errorMessage: errorMessage,
    );
  }

  /// Emit progress update with artwork paths so DownloadProvider can sync
  void _emitProgressWithArtwork(String globalKey, {String? thumbPath}) {
    // Emit a progress update containing artwork path
    // The status is preserved as downloading since artwork is just one step
    _progressController.add(
      DownloadProgress(
        globalKey: globalKey,
        status: DownloadStatus.downloading,
        progress: 0,
        currentFile: 'artwork',
        thumbPath: thumbPath,
      ),
    );
  }

  /// Pause a download (works for both downloading and queued items)
  Future<void> pauseDownload(String globalKey) async {
    // Mark as pausing synchronously so callbacks from holding-queue promotions
    // can detect and cancel promoted tasks before any await yields.
    _pausingKeys.add(globalKey);

    try {
      final bgTaskId = await _database.getBgTaskId(globalKey);
      if (bgTaskId != null) {
        final task = await FileDownloader().taskForId(bgTaskId);
        if (task != null && task is DownloadTask) {
          // Normal mode: native pause support
          await FileDownloader().pause(task);
        } else {
          // SAF mode (UriDownloadTask) or task not found: cancel (re-download on resume)
          await FileDownloader().cancelTaskWithId(bgTaskId);
        }
      }
      _pendingDownloadContext.remove(globalKey);
      await _transitionStatus(globalKey, DownloadStatus.paused);
      await _database.removeFromQueue(globalKey);
    } finally {
      _pausingKeys.remove(globalKey);
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, PlexClient client) async {
    final bgTaskId = await _database.getBgTaskId(globalKey);

    // Try native resume first (only works for normal-mode DownloadTask that was paused)
    if (bgTaskId != null) {
      final task = await FileDownloader().taskForId(bgTaskId);
      if (task != null && task is DownloadTask) {
        final resumed = await FileDownloader().resume(task);
        if (resumed) {
          appLogger.i('Resumed download via background_downloader for $globalKey');
          await _database.updateDownloadStatus(globalKey, DownloadStatus.downloading.index);
          _emitProgress(globalKey, DownloadStatus.downloading, 0);
          return;
        }
      }
    }

    // Native resume failed or not supported (SAF mode) — re-enqueue from scratch
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    _processQueue(client);
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, PlexClient client) async {
    await _database.clearDownloadError(globalKey);
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    _processQueue(client);
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    final bgTaskId = await _database.getBgTaskId(globalKey);
    if (bgTaskId != null) {
      await FileDownloader().cancelTaskWithId(bgTaskId);
    }
    _pendingDownloadContext.remove(globalKey);
    await _transitionStatus(globalKey, DownloadStatus.cancelled);
    await _database.removeFromQueue(globalKey);
  }

  /// Delete a downloaded item and its files
  Future<void> deleteDownload(String globalKey) async {
    // Cancel if actively downloading via background_downloader
    final bgTaskId = await _database.getBgTaskId(globalKey);
    if (bgTaskId != null) {
      await FileDownloader().cancelTaskWithId(bgTaskId);
    }
    _pendingDownloadContext.remove(globalKey);

    // Delete files from storage
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) {
      await _database.deleteDownload(globalKey);
      return;
    }

    final serverId = parsed.serverId;
    final ratingKey = parsed.ratingKey;
    final metadata = await _apiCache.getMetadata(serverId, ratingKey);

    if (metadata == null) {
      // Fallback deletion without progress
      await _deleteMediaFilesWithMetadata(serverId, ratingKey);
      await _apiCache.deleteForItem(serverId, ratingKey);
      await _database.deleteDownload(globalKey);
      return;
    }

    // Determine total items to delete
    final totalItems = await _getTotalItemsToDelete(metadata, serverId);

    // Emit initial progress
    _emitDeletionProgress(
      DeletionProgress(globalKey: globalKey, itemTitle: metadata.title, currentItem: 0, totalItems: totalItems),
    );

    // Delete files from storage (with progress updates)
    await _deleteMediaFilesWithMetadata(serverId, ratingKey);

    // Delete from API cache
    await _apiCache.deleteForItem(serverId, ratingKey);

    // Delete from database
    await _database.deleteDownload(globalKey);

    // Emit completion
    _emitDeletionProgress(
      DeletionProgress(
        globalKey: globalKey,
        itemTitle: metadata.title,
        currentItem: totalItems,
        totalItems: totalItems,
      ),
    );
  }

  /// Emit deletion progress update
  void _emitDeletionProgress(DeletionProgress progress) {
    _deletionProgressController.add(progress);
  }

  /// Calculate total items to delete (for progress tracking)
  Future<int> _getTotalItemsToDelete(PlexMetadata metadata, String serverId) async {
    switch (metadata.type.toLowerCase()) {
      case 'episode':
        return 1; // Single episode
      case 'movie':
        return 1; // Single movie
      case 'season':
        // Count episodes in season
        final episodes = await _database.getEpisodesBySeason(metadata.ratingKey);
        return episodes.length;
      case 'show':
        // Count all episodes in show
        final episodes = await _database.getEpisodesByShow(metadata.ratingKey);
        return episodes.length;
      default:
        return 1;
    }
  }

  /// Delete media files using metadata to find correct paths
  Future<void> _deleteMediaFilesWithMetadata(String serverId, String ratingKey) async {
    try {
      // Get metadata from API cache
      final metadata = await _apiCache.getMetadata(serverId, ratingKey);

      if (metadata == null) {
        // Fallback: Try database record
        final downloadRecord = await _database.getDownloadedMedia('$serverId:$ratingKey');
        if (downloadRecord?.videoFilePath != null) {
          await _deleteByFilePath(downloadRecord!);
          return;
        }
        appLogger.w('Cannot delete - no metadata for $serverId:$ratingKey');
        return;
      }

      // Delete based on type
      switch (metadata.type.toLowerCase()) {
        case 'episode':
          await _deleteEpisodeFiles(metadata, serverId);
          break;
        case 'season':
          await _deleteSeasonFiles(metadata, serverId);
          break;
        case 'show':
          await _deleteShowFiles(metadata, serverId);
          break;
        case 'movie':
          await _deleteMovieFiles(metadata, serverId);
          break;
        default:
          appLogger.w('Unknown type for deletion: ${metadata.type}');
      }
    } catch (e, stack) {
      appLogger.e('Error deleting files', error: e, stackTrace: stack);
    }
  }

  /// Get chapter thumb paths from cached metadata
  Future<List<String>> _getChapterThumbPaths(String serverId, String ratingKey) async {
    try {
      final cachedData = await _apiCache.get(serverId, '/library/metadata/$ratingKey');
      final chapters = PlexCacheParser.extractChapters(cachedData);
      if (chapters == null) return [];

      return chapters
          .map((ch) => ch['thumb'] as String?)
          .where((thumb) => thumb != null && thumb.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      appLogger.w('Error getting chapter thumb paths for $ratingKey', error: e);
      return [];
    }
  }

  /// Check if a chapter thumbnail is used by any other downloaded items
  Future<bool> _isChapterThumbnailInUse(String serverId, String thumbPath, String excludeRatingKey) async {
    try {
      // Get all downloaded items
      final allItems = await _database.select(_database.downloadedMedia).get();

      // Check if any other item uses this chapter thumbnail
      for (final item in allItems) {
        // Skip the item being deleted
        if (item.ratingKey == excludeRatingKey) {
          continue;
        }

        // Get chapter thumb paths for this item
        final itemChapterPaths = await _getChapterThumbPaths(serverId, item.ratingKey);

        // Check if this item has the same thumb path
        if (itemChapterPaths.contains(thumbPath)) {
          return true; // Thumbnail is in use
        }
      }

      return false; // Thumbnail is not in use
    } catch (e) {
      appLogger.w('Error checking chapter thumbnail usage: $thumbPath', error: e);
      // On error, assume in use to be safe (don't delete)
      return true;
    }
  }

  /// Delete chapter thumbnails for a media item (with reference counting)
  Future<void> _deleteChapterThumbnails(String serverId, String ratingKey) async {
    try {
      final thumbPaths = await _getChapterThumbPaths(serverId, ratingKey);

      if (thumbPaths.isEmpty) {
        appLogger.d('No chapter thumbnails to delete for $ratingKey');
        return;
      }

      int deletedCount = 0;
      int preservedCount = 0;

      for (final thumbPath in thumbPaths) {
        try {
          // Check if this thumbnail is used by other items
          final inUse = await _isChapterThumbnailInUse(serverId, thumbPath, ratingKey);

          if (inUse) {
            appLogger.d('Preserving chapter thumbnail (in use): $thumbPath');
            preservedCount++;
            continue;
          }

          // Get artwork file path and delete
          final artworkPath = await _storageService.getArtworkPathFromThumb(serverId, thumbPath);
          if (await _deleteFileIfExists(File(artworkPath), 'chapter thumbnail')) {
            deletedCount++;
          }
        } catch (e) {
          appLogger.w('Failed to delete chapter thumbnail: $thumbPath', error: e);
          // Continue with other chapters even if one fails
        }
      }

      if (deletedCount > 0 || preservedCount > 0) {
        appLogger.i('Deleted $deletedCount of ${thumbPaths.length} chapter thumbnails ($preservedCount preserved)');
      }
    } catch (e, stack) {
      appLogger.w('Error deleting chapter thumbnails for $ratingKey', error: e, stackTrace: stack);
      // Don't throw - chapter deletion shouldn't block main deletion
    }
  }

  /// Delete episode files
  Future<void> _deleteEpisodeFiles(PlexMetadata episode, String serverId) async {
    try {
      final parentMetadata = episode.grandparentRatingKey != null
          ? await _apiCache.getMetadata(serverId, episode.grandparentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      // Delete video file
      final videoPathTemplate = await _storageService.getEpisodeVideoPath(episode, 'tmp', showYear: showYear);
      final videoPathWithoutExt = videoPathTemplate.substring(0, videoPathTemplate.lastIndexOf('.'));
      final actualVideoFile = await _findFileWithAnyExtension(videoPathWithoutExt);
      if (actualVideoFile != null) {
        await _deleteFileIfExists(actualVideoFile, 'episode video');
        // Also clean up any .part file from interrupted downloads
        await _deleteFileIfExists(File('${actualVideoFile.path}.part'), 'partial download');
      }

      // Delete thumbnail
      final thumbPath = await _storageService.getEpisodeThumbnailPath(episode, showYear: showYear);
      await _deleteFileIfExists(File(thumbPath), 'episode thumbnail');

      // Delete subtitles directory
      final subsDir = await _storageService.getEpisodeSubtitlesDirectory(episode, showYear: showYear);
      if (await subsDir.exists()) {
        await subsDir.delete(recursive: true);
        appLogger.i('Deleted episode subtitles: ${subsDir.path}');
      }

      // Delete chapter thumbnails (with reference counting)
      await _deleteChapterThumbnails(serverId, episode.ratingKey);

      // Clean up parent directories if empty
      await _cleanupEmptyDirectories(episode, showYear);
    } catch (e, stack) {
      appLogger.e('Error deleting episode files', error: e, stackTrace: stack);
    }
  }

  /// Delete season files
  Future<void> _deleteSeasonFiles(PlexMetadata season, String serverId) async {
    try {
      final parentMetadata = season.parentRatingKey != null
          ? await _apiCache.getMetadata(serverId, season.parentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      // Get all episodes in this season
      final episodesInSeason = await _database.getEpisodesBySeason(season.ratingKey);

      appLogger.d('Deleting ${episodesInSeason.length} episodes in season ${season.ratingKey}');
      await _deleteEpisodesInCollection(
        episodes: episodesInSeason,
        serverId: serverId,
        parentKey: season.ratingKey,
        parentTitle: season.title,
      );

      final seasonDir = await _storageService.getSeasonDirectory(season, showYear: showYear);
      if (await seasonDir.exists()) {
        await seasonDir.delete(recursive: true);
        appLogger.i('Deleted season directory: ${seasonDir.path}');
      }

      await _cleanupShowDirectory(season, showYear);
    } catch (e, stack) {
      appLogger.e('Error deleting season files', error: e, stackTrace: stack);
    }
  }

  /// Delete episodes in a collection (season or show)
  /// Returns the number of episodes deleted
  Future<void> _deleteEpisodesInCollection({
    required List<DownloadedMediaItem> episodes,
    required String serverId,
    required String parentKey,
    required String parentTitle,
  }) async {
    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final episodeGlobalKey = '$serverId:${episode.ratingKey}';

      // Emit progress update
      _emitDeletionProgress(
        DeletionProgress(
          globalKey: '$serverId:$parentKey',
          itemTitle: parentTitle,
          currentItem: i + 1,
          totalItems: episodes.length,
          currentOperation: 'Deleting episode ${i + 1} of ${episodes.length}',
        ),
      );

      // Delete chapter thumbnails
      await _deleteChapterThumbnails(serverId, episode.ratingKey);

      // Delete episode files (video, subtitles)
      await _deleteByFilePath(episode);

      // Delete episode from API cache
      await _apiCache.deleteForItem(serverId, episode.ratingKey);

      // Delete episode DB entry
      await _database.deleteDownload(episodeGlobalKey);
    }
  }

  /// Delete show files
  Future<void> _deleteShowFiles(PlexMetadata show, String serverId) async {
    try {
      // Get all episodes in this show
      final episodesInShow = await _database.getEpisodesByShow(show.ratingKey);

      appLogger.d('Deleting ${episodesInShow.length} episodes in show ${show.ratingKey}');
      await _deleteEpisodesInCollection(
        episodes: episodesInShow,
        serverId: serverId,
        parentKey: show.ratingKey,
        parentTitle: show.title,
      );

      final showDir = await _storageService.getShowDirectory(show);
      if (await showDir.exists()) {
        await showDir.delete(recursive: true);
        appLogger.i('Deleted show directory: ${showDir.path}');
      }
    } catch (e, stack) {
      appLogger.e('Error deleting show files', error: e, stackTrace: stack);
    }
  }

  /// Delete movie files
  Future<void> _deleteMovieFiles(PlexMetadata movie, String serverId) async {
    try {
      final movieDir = await _storageService.getMovieDirectory(movie);
      if (await movieDir.exists()) {
        await movieDir.delete(recursive: true);
        appLogger.i('Deleted movie directory: ${movieDir.path}');
      }

      // Delete chapter thumbnails (with reference counting)
      await _deleteChapterThumbnails(serverId, movie.ratingKey);
    } catch (e, stack) {
      appLogger.e('Error deleting movie files', error: e, stackTrace: stack);
    }
  }

  /// Clean up empty directories after deleting episode
  Future<void> _cleanupEmptyDirectories(PlexMetadata episode, int? showYear) async {
    final seasonDir = await _storageService.getSeasonDirectory(episode, showYear: showYear);

    if (await seasonDir.exists()) {
      final contents = await seasonDir.list().toList();
      final hasVideos = contents.any(
        (e) =>
            e.path.endsWith('.mp4') ||
            e.path.endsWith('.ogv') ||
            e.path.endsWith('.mkv') ||
            e.path.endsWith('.m4v') ||
            e.path.endsWith('.avi') ||
            e.path.contains('_subs'),
      );

      if (!hasVideos) {
        if (!await _isSeasonArtworkInUse(episode, showYear)) {
          await seasonDir.delete(recursive: true);
          appLogger.i('Deleted empty season directory: ${seasonDir.path}');
          await _cleanupShowDirectory(episode, showYear);
        }
      }
    }
  }

  /// Clean up show directory if empty
  Future<void> _cleanupShowDirectory(PlexMetadata metadata, int? showYear) async {
    final showDir = await _storageService.getShowDirectory(metadata, showYear: showYear);

    if (await showDir.exists()) {
      final contents = await showDir.list().toList();
      final hasSeasons = contents.any((e) => e is Directory && e.path.contains('Season '));

      if (!hasSeasons) {
        if (!await _isShowArtworkInUse(metadata, showYear)) {
          await showDir.delete(recursive: true);
          appLogger.i('Deleted empty show directory: ${showDir.path}');
        }
      }
    }
  }

  /// Check if season artwork is in use
  Future<bool> _isSeasonArtworkInUse(PlexMetadata episode, int? showYear) async {
    final seasonKey = episode.parentRatingKey;
    if (seasonKey == null) return false;

    final otherEpisodes = await _database.getEpisodesBySeason(seasonKey);

    // Check if any episodes besides this one
    return otherEpisodes.any((e) => e.globalKey != '${episode.serverId}:${episode.ratingKey}');
  }

  /// Check if show artwork is in use
  Future<bool> _isShowArtworkInUse(PlexMetadata metadata, int? showYear) async {
    final showKey = metadata.grandparentRatingKey ?? metadata.parentRatingKey ?? metadata.ratingKey;

    final allItems = await _database.select(_database.downloadedMedia).get();

    // Check if any items belong to this show besides this one
    return allItems.any(
      (item) =>
          (item.grandparentRatingKey == showKey || item.parentRatingKey == showKey) &&
          item.globalKey != '${metadata.serverId}:${metadata.ratingKey}',
    );
  }

  /// Find file with any extension
  Future<File?> _findFileWithAnyExtension(String pathWithoutExt) async {
    final dir = Directory(path.dirname(pathWithoutExt));
    final baseName = path.basename(pathWithoutExt);

    if (!await dir.exists()) return null;

    try {
      final files = await dir
          .list()
          .where((e) => e is File && path.basenameWithoutExtension(e.path) == baseName)
          .toList();

      return files.isNotEmpty ? files.first as File : null;
    } catch (e) {
      appLogger.w('Error finding file: $pathWithoutExt', error: e);
      return null;
    }
  }

  /// Fallback deletion using file paths from database
  Future<void> _deleteByFilePath(DownloadedMediaItem record) async {
    try {
      if (record.videoFilePath != null) {
        final videoPath = await _storageService.toAbsolutePath(record.videoFilePath!);
        final videoDeleted = await _deleteFileIfExists(File(videoPath), 'video file');

        // Delete subtitle directory if video was deleted
        if (videoDeleted) {
          final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
          final subsDir = Directory(subsPath);
          if (await subsDir.exists()) {
            await subsDir.delete(recursive: true);
            appLogger.i('Deleted subtitles: $subsPath');
          }
        }
      }

      if (record.thumbPath != null) {
        final thumbPath = await _storageService.toAbsolutePath(record.thumbPath!);
        await _deleteFileIfExists(File(thumbPath), 'thumbnail');
      }
    } catch (e, stack) {
      appLogger.e('Error in fallback deletion', error: e, stackTrace: stack);
    }
  }

  /// Get all downloads with a specific status
  Stream<List<DownloadedMediaItem>> watchDownloadsByStatus(DownloadStatus status) {
    return (_database.select(_database.downloadedMedia)..where((t) => t.status.equals(status.index))).watch();
  }

  /// Get all downloaded media items (for loading persisted data)
  Future<List<DownloadedMediaItem>> getAllDownloads() async {
    return _database.select(_database.downloadedMedia).get();
  }

  /// Get a specific downloaded media item by globalKey
  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) async {
    return _database.getDownloadedMedia(globalKey);
  }

  /// Save metadata for a media item (show, season, movie, or episode)
  /// Used to persist parent metadata (shows/seasons) for offline display
  Future<void> saveMetadata(PlexMetadata metadata) async {
    if (metadata.serverId == null) {
      appLogger.w('Cannot save metadata without serverId');
      return;
    }

    // Cache to API cache for offline use
    await _cacheMetadataForOffline(metadata.serverId!, metadata.ratingKey, metadata);
  }

  /// Cache metadata in the API response format for offline access
  /// This simulates what PlexClient would receive from the server
  Future<void> _cacheMetadataForOffline(String serverId, String ratingKey, PlexMetadata metadata) async {
    final endpoint = '/library/metadata/$ratingKey';

    // Build a response structure that matches the Plex API format
    final cachedResponse = {
      'MediaContainer': {
        'Metadata': [metadata.toJson()],
      },
    };

    await _apiCache.put(serverId, endpoint, cachedResponse);
    await _apiCache.pinForOffline(serverId, ratingKey);
  }

  /// Cache children (seasons or episodes) in the API response format
  Future<void> cacheChildrenForOffline(String serverId, String parentRatingKey, List<PlexMetadata> children) async {
    final endpoint = '/library/metadata/$parentRatingKey/children';

    // Build a response structure that matches the Plex API format
    final cachedResponse = {
      'MediaContainer': {'Metadata': children.map((c) => c.toJson()).toList()},
    };

    await _apiCache.put(serverId, endpoint, cachedResponse);
  }

  void dispose() {
    _progressController.close();
    _deletionProgressController.close();
  }
}
