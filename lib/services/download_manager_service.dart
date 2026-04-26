import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:plezy/utils/content_utils.dart';
import 'package:plezy/utils/plex_http_client.dart';
import '../database/app_database.dart';
import '../database/download_operations.dart';
import 'settings_service.dart';
import 'saf_storage_service.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../services/offline_mode_source.dart';
import '../services/plex_client.dart';
import '../services/download_storage_service.dart';
import '../services/plex_api_cache.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/codec_utils.dart';
import '../utils/global_key_utils.dart';
import '../utils/plex_cache_parser.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  final PlexHttpClient _http;

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

  // Resolve the correct PlexClient for a given serverId (set via setClientResolver).
  // Falls back to _fallbackClient when the resolver is unavailable or returns null.
  PlexClient? Function(String serverId)? _clientResolver;
  PlexClient? _fallbackClient;

  OfflineModeSource? _offlineSource;

  // background_downloader state
  bool _fileDownloaderInitialized = false;
  static const _downloadGroup = 'video_downloads';
  static const _maxAppRetries = 3;
  static const _nativeRetries = 5;
  static const _autoRetryDelay = Duration(seconds: 30);
  static const _progressDebounceDelay = Duration(seconds: 2);
  static const _videoExtensions = {'.mp4', '.ogv', '.mkv', '.m4v', '.avi'};

  // Keys currently being paused — prevents holding queue from promoting them
  final Set<String> _pausingKeys = {};

  // Keys whose completion callback is in-flight — prevents orphan scan from re-queuing them
  final Set<String> _completingKeys = {};

  // Prevents concurrent _processQueue calls
  bool _isProcessingQueue = false;
  bool _disposed = false;

  // Debounce timers for DB progress writes (keyed by globalKey).
  // UI progress streams are still real-time; only the DB write is debounced.
  final Map<String, Timer> _progressDebounceTimers = {};

  // App-level auto-retry timers for downloads that exhausted native retries.
  // Keyed by globalKey; each timer fires a fresh re-enqueue after a delay.
  final Map<String, Timer> _autoRetryTimers = {};

  // Circuit breaker: consecutive instant failures in _processQueue.
  // Stops the queue when all items fail with the same error (e.g. DNS).
  int _consecutiveQueueFailures = 0;
  static const _maxConsecutiveFailures = 3;

  /// Public method to check if downloads should be blocked due to cellular-only setting
  /// Can be used by DownloadProvider to show user-friendly error
  static Future<bool> shouldBlockDownloadOnCellular() async {
    final List<ConnectivityResult> connectivity;
    try {
      connectivity = await Connectivity().checkConnectivity();
    } catch (e) {
      // connectivity_plus can throw PlatformException on Windows — don't block
      return false;
    }
    return shouldBlockDownloadOnCellularWith(connectivity);
  }

  /// Same check as [shouldBlockDownloadOnCellular] but uses a pre-read
  /// connectivity result so callers that already queried connectivity don't
  /// pay for a second platform round-trip.
  static Future<bool> shouldBlockDownloadOnCellularWith(List<ConnectivityResult> connectivity) async {
    final settings = await SettingsService.getInstance();
    if (!settings.read(SettingsService.downloadOnWifiOnly)) return false;
    if (connectivity.isEmpty) return false;
    return connectivity.contains(ConnectivityResult.mobile) &&
        !connectivity.contains(ConnectivityResult.wifi) &&
        !connectivity.contains(ConnectivityResult.ethernet);
  }

  /// Future that completes when interrupted download recovery finishes.
  /// Await this before reading download state from the DB to avoid races.
  late final Future<void> recoveryFuture;

  DownloadManagerService({
    required AppDatabase database,
    required DownloadStorageService storageService,
    PlexHttpClient? http,
  }) : _database = database,
       _storageService = storageService,
       _http = http ?? httpClient;

  /// Register a callback to resolve the correct PlexClient for a given serverId.
  void setClientResolver(PlexClient? Function(String serverId) resolver) {
    _clientResolver = resolver;
  }

  /// Inject the offline-mode source. When `isOffline`, queue/resume paths skip
  /// network work and defer until connectivity returns.
  void setOfflineSource(OfflineModeSource? source) {
    _offlineSource = source;
  }

  bool get _isOffline => _offlineSource?.isOffline ?? false;

  /// Look up the correct client for [serverId].
  /// Returns null if the server is offline — callers should skip/defer the work.
  PlexClient? _getClient(String? serverId) {
    if (serverId != null && _clientResolver != null) {
      return _clientResolver!(serverId);
    }
    return _fallbackClient;
  }

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
    // Deliver status updates from iOS background-to-foreground transitions
    await FileDownloader().resumeFromBackground();

    _fileDownloaderInitialized = true;
  }

  /// Recover downloads that were interrupted when the app was killed.
  /// Uses background_downloader's rescheduleKilledTasks for native recovery,
  /// then scans drift for orphaned items.
  Future<void> recoverInterruptedDownloads() async {
    try {
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Initializing FileDownloader', category: 'downloads')));
      await _initializeFileDownloader();

      // Let background_downloader re-enqueue tasks killed by the OS
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Rescheduling killed tasks', category: 'downloads')));
      final (rescheduled, _) = await FileDownloader().rescheduleKilledTasks();
      if (rescheduled.isNotEmpty) {
        appLogger.i('Rescheduled ${rescheduled.length} killed download task(s)');
      }

      // One-time migration: normalize stored file paths that may contain a
      // doubled base-dir prefix from an earlier bug in the recovery callback.
      // Re-run on v2 to also fix paths without a leading / that the v1 migration missed.
      final prefs = (await SettingsService.getInstance()).prefs;
      if ((prefs.getInt('download_paths_normalized_version') ?? 0) < 2) {
        final allItems = await _database.select(_database.downloadedMedia).get();
        var fixed = 0;
        for (final item in allItems) {
          if (item.videoFilePath != null) {
            final vfp = item.videoFilePath!;
            var normalized = await _storageService.toRelativePath(vfp);
            // If toRelativePath didn't help, try extracting from downloads/ onward
            // for paths that lack a leading / but contain nested base-dir fragments
            if (normalized == vfp) {
              final idx = vfp.indexOf('downloads/');
              if (idx > 0) normalized = vfp.substring(idx);
            }
            appLogger.d('Path migration: videoFilePath="$vfp", normalized="$normalized"');
            if (normalized != vfp) {
              await _database.updateVideoFilePath(item.globalKey, normalized);
              fixed++;
            }
          }
          if (item.thumbPath != null) {
            final tp = item.thumbPath!;
            var normalized = await _storageService.toRelativePath(tp);
            if (normalized == tp) {
              final idx = tp.indexOf('downloads/');
              if (idx > 0) normalized = tp.substring(idx);
            }
            if (normalized != tp) {
              await _database.updateArtworkPaths(globalKey: item.globalKey, thumbPath: normalized);
            }
          }
        }
        if (fixed > 0) appLogger.i('Normalized $fixed corrupted download path(s)');
        await prefs.setInt('download_paths_normalized_version', 2);
      }

      // Scan drift for orphaned items stuck in 'downloading'
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Scanning for orphaned downloads', category: 'downloads')));
      final allDownloads = await _database.select(_database.downloadedMedia).get();
      for (final item in allDownloads) {
        if (item.status == DownloadStatus.downloading.index) {
          // Skip items whose completion callback is already in-flight (race with trackTasks)
          if (_completingKeys.contains(item.globalKey)) {
            appLogger.d('Skipping orphan check for ${item.globalKey}: completion in progress');
            continue;
          }

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
    _fallbackClient = client;

    if (_isOffline) {
      appLogger.d('Skipping resumeQueuedDownloads — offline');
      return;
    }

    // Attempt deferred supplementary downloads for recovered items
    _processPendingSupplementaryDownloads(client);

    unawaited(
      _database
          .getNextQueueItem()
          .then((item) {
            if (item != null) {
              appLogger.i('Resuming queued downloads after app restart');
              _processQueue(client);
            }
          })
          .catchError((e, st) {
            appLogger.e('Failed to resume queued downloads', error: e, stackTrace: st);
          }),
    );
  }

  /// Attempt supplementary downloads (artwork, subtitles) for items that were
  /// recovered with a completed video but missed post-processing.
  Future<void> _processPendingSupplementaryDownloads(PlexClient client) async {
    if (_pendingSupplementaryDownloads.isEmpty) return;

    final keys = Set<String>.from(_pendingSupplementaryDownloads);
    _pendingSupplementaryDownloads.clear();

    for (final globalKey in keys) {
      try {
        // Resolve the correct client for this item's server
        final parsed = parseGlobalKey(globalKey);
        final itemClient = _getClient(parsed?.serverId);
        if (itemClient == null) {
          appLogger.d('Deferring supplementary download $globalKey: server offline');
          _pendingSupplementaryDownloads.add(globalKey);
          continue;
        }

        final metadata = await _resolveMetadata(globalKey);
        if (metadata == null) {
          appLogger.w('No metadata for deferred supplementary download: $globalKey');
          continue;
        }

        // Look up show year for episodes
        int? showYear;
        if (metadata.type == 'episode' && metadata.grandparentRatingKey != null) {
          if (parsed != null) {
            showYear = await _fetchShowYear(parsed.serverId, metadata.grandparentRatingKey);
          }
        }

        await _downloadArtwork(globalKey, metadata, itemClient);
        await _downloadChapterThumbnails(metadata.serverId!, metadata.ratingKey, itemClient);

        // Attempt subtitles
        try {
          final playbackData = await itemClient.getVideoPlaybackData(metadata.ratingKey);
          if (playbackData.mediaInfo != null) {
            await _downloadSubtitles(globalKey, metadata, playbackData.mediaInfo!, itemClient, showYear: showYear);
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

  /// Cancel any per-download timers (progress debounce + auto-retry) for [key].
  /// Idempotent; safe to call from any terminal/pause path.
  void _cancelDownloadTimers(String key) {
    _progressDebounceTimers.remove(key)?.cancel();
    _autoRetryTimers.remove(key)?.cancel();
  }

  /// Delete a file if it exists and log the deletion
  /// Returns true if file was deleted, false otherwise
  Future<bool> _deleteFileIfExists(File file, String description) async {
    try {
      if (await file.exists()) {
        await file.delete();
        appLogger.i('Deleted $description: ${file.path}');
        return true;
      }
    } catch (e) {
      appLogger.w('Failed to delete $description: ${file.path}', error: e);
    }
    return false;
  }

  /// Delete a SAF file or directory. Missing targets are a silent no-op.
  Future<void> _tryDeleteSaf(String uri, {required bool isDir, required String description}) async {
    final ok = await SafStorageService.instance.delete(uri, isDir: isDir);
    if (ok) appLogger.i('Deleted $description: $uri');
  }

  /// Recursively delete a SAF directory — lists children in parallel, deletes
  /// leaves, recurses into subdirectories, then removes the dir itself.
  /// Manual recursion because DocumentsProvider-level recursion isn't guaranteed
  /// across providers.
  Future<void> _deleteSafDirRecursive(String dirUri, {required String description}) async {
    final saf = SafStorageService.instance;
    final children = await saf.list(dirUri);
    if (children != null && children.isNotEmpty) {
      await Future.wait(
        children.map((child) {
          return child.isDir
              ? _deleteSafDirRecursive(child.uri, description: description)
              : saf.delete(child.uri, isDir: false);
        }),
      );
    }
    await _tryDeleteSaf(dirUri, isDir: true, description: description);
  }

  /// Walk a chain of SAF directory URIs (deepest-first) and delete each that is empty.
  /// Stops at the first non-empty directory. Skips missing/null entries.
  Future<void> _deleteEmptySafDirsInOrder(List<String?> dirUris) async {
    final saf = SafStorageService.instance;
    for (final uri in dirUris) {
      if (uri == null) break;
      if (!await saf.exists(uri, isDir: true)) continue;
      final children = await saf.list(uri);
      if (children == null || children.isNotEmpty) break;
      if (!await saf.delete(uri, isDir: true)) break;
      appLogger.i('Cleaned up empty SAF directory: $uri');
    }
  }

  /// Find a SAF file in [dirUri] whose name (minus extension) matches [baseName].
  Future<SafDocumentFile?> _findSafFileByBaseName(String dirUri, String baseName) async {
    final children = await SafStorageService.instance.list(dirUri);
    if (children == null) return null;
    for (final child in children) {
      if (!child.isDir && path.basenameWithoutExtension(child.name) == baseName) return child;
    }
    return null;
  }

  /// Delete the canonical target file and any pre-existing numbered duplicates
  /// in [safDirUri] before re-enqueueing a SAF download. SAF DocumentsProviders
  /// auto-number on createDocument when a name conflict exists, which would
  /// otherwise produce "name (1).ext" / "name.ext (1)" corrupt duplicates on
  /// every app-level retry.
  Future<void> _cleanupSafTargetFile(String safDirUri, String safFileName) async {
    final children = await SafStorageService.instance.list(safDirUri);
    if (children == null) return;

    // Match BOTH numbering schemes a DocumentsProvider may use:
    //   "S02E11 - The Hunt (1).mkv"  - inserted before extension (most providers)
    //   "S02E11 - The Hunt.mkv (1)"  - appended after full name (Downloads tree)
    final base = path.basenameWithoutExtension(safFileName);
    final ext = path.extension(safFileName);
    final dup = RegExp(
      '^${RegExp.escape(base)} \\(\\d+\\)${RegExp.escape(ext)}\$|'
      '^${RegExp.escape(safFileName)} \\(\\d+\\)\$',
    );

    await Future.wait([
      for (final child in children)
        if (!child.isDir && (child.name == safFileName || dup.hasMatch(child.name)))
          _tryDeleteSaf(
            child.uri,
            isDir: false,
            description: child.name == safFileName
                ? 'stale SAF video before re-download'
                : 'stale SAF numbered duplicate',
          ),
    ]);
  }

  /// Queue a download for a media item
  Future<void> queueDownload({
    required PlexMetadata metadata,
    required PlexClient client,
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
    int mediaIndex = 0,
  }) async {
    final globalKey = metadata.globalKey;

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
      type: metadata.type ?? '',
      parentRatingKey: metadata.parentRatingKey,
      grandparentRatingKey: metadata.grandparentRatingKey,
      status: DownloadStatus.queued.index,
      mediaIndex: mediaIndex,
    );

    // Ensure metadata is in cache before pinning.
    // Normally getMetadataWithImages already cached the full API response (with chapters/markers),
    // but if the network failed during the provider's fetch, the cache entry may not exist.
    final cached = await _apiCache.get(metadata.serverId!, '/library/metadata/${metadata.ratingKey}');
    if (cached == null) {
      await _cacheMetadataForOffline(metadata.serverId!, metadata.ratingKey, metadata);
    } else {
      await _apiCache.pinForOffline(metadata.serverId!, metadata.ratingKey);
    }

    // Add to queue
    await _database.addToQueue(
      mediaGlobalKey: globalKey,
      priority: priority,
      downloadSubtitles: downloadSubtitles,
      downloadArtwork: downloadArtwork,
    );

    _emitProgress(globalKey, DownloadStatus.queued, 0);

    // Start processing if not already
    unawaited(_processQueue(client));
  }

  /// Process the download queue — prepares and enqueues items with background_downloader.
  /// Non-blocking: returns after all queued items are enqueued (downloads run natively).
  Future<void> _processQueue(PlexClient client) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    _fallbackClient = client;

    try {
      await _initializeFileDownloader();

      while (true) {
        if (_consecutiveQueueFailures >= _maxConsecutiveFailures) {
          appLogger.w('Circuit breaker: $_consecutiveQueueFailures consecutive failures, pausing queue');
          break;
        }

        final nextItem = await _database.getNextQueueItem();
        if (nextItem == null) break;

        // Resolve the correct client for the item's server — skip if server is offline
        final parsed = parseGlobalKey(nextItem.mediaGlobalKey);
        final itemClient = _getClient(parsed?.serverId);
        if (itemClient == null) {
          appLogger.d('Skipping queued download ${nextItem.mediaGlobalKey}: server offline');
          continue;
        }
        final enqueued = await _prepareAndEnqueueDownload(nextItem.mediaGlobalKey, itemClient, nextItem);
        if (enqueued) {
          _consecutiveQueueFailures = 0;
        } else {
          _consecutiveQueueFailures++;
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Cancel any lingering background task and reset progress before re-enqueuing.
  Future<void> _cleanupStaleDownload(String globalKey) async {
    final existingTaskId = await _database.getBgTaskId(globalKey);
    if (existingTaskId != null) {
      await FileDownloader().cancelTaskWithId(existingTaskId);
      await _database.updateBgTaskId(globalKey, null);
      appLogger.d('Cancelled stale bg task $existingTaskId for $globalKey');
    }
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
  }

  /// Resolve metadata, video URL, and file path, then enqueue a background download task.
  /// Returns true if successfully enqueued, false if it failed immediately.
  Future<bool> _prepareAndEnqueueDownload(String globalKey, PlexClient client, DownloadQueueItem queueItem) async {
    try {
      // Guard: don't re-enqueue an item that's already completed or was deleted
      final existing = await _database.getDownloadedMedia(globalKey);
      if (existing == null || existing.status == DownloadStatus.completed.index) {
        appLogger.d('Skipping enqueue for $globalKey: already completed or deleted');
        await _database.removeFromQueue(globalKey);
        return true;
      }

      appLogger.i('Preparing download for $globalKey');
      if (existing.bgTaskId != null) await _cleanupStaleDownload(globalKey);
      await _transitionStatus(globalKey, DownloadStatus.downloading);

      final parsed = parseGlobalKey(globalKey);
      if (parsed == null) throw Exception('Invalid globalKey: $globalKey');
      final serverId = parsed.serverId;
      final ratingKey = parsed.ratingKey;

      var metadata = await _apiCache.getMetadata(serverId, ratingKey);
      if (metadata == null) {
        // Cache miss — try re-fetching from server (cache may have been cleared between queue and prepare)
        appLogger.w('Cache miss for $globalKey, attempting network re-fetch');
        try {
          final fetched = await client.getMetadataWithImages(ratingKey);
          if (fetched != null) metadata = fetched.copyWith(serverId: serverId);
        } catch (e) {
          appLogger.w('Network re-fetch failed for $globalKey', error: e);
        }
        if (metadata == null) {
          throw Exception('Metadata not found in cache and could not be fetched for $globalKey');
        }
      }

      final selectedMediaIndex = existing.mediaIndex;
      var playbackData = await client.getVideoPlaybackData(metadata.ratingKey, mediaIndex: selectedMediaIndex);
      if (playbackData.videoUrl == null) {
        // Cache may contain a synthetic entry (from _cacheMetadataForOffline) without
        // Media/Part data. Force a fresh network fetch to populate the cache properly.
        appLogger.w('No video URL from cache for $globalKey, retrying via network');
        final fetched = await client.getMetadataWithImages(ratingKey);
        if (fetched != null) metadata = fetched.copyWith(serverId: serverId);
        playbackData = await client.getVideoPlaybackData(metadata.ratingKey, mediaIndex: selectedMediaIndex);
        if (playbackData.videoUrl == null) throw Exception('Could not get video URL for $globalKey');
      }

      final ext = _getExtensionFromUrl(playbackData.videoUrl!) ?? 'mp4';

      // Look up show year for episodes
      final showYear = metadata.type == 'episode'
          ? await _fetchShowYear(serverId, metadata.grandparentRatingKey)
          : null;

      // Build display name for notifications
      final displayName = metadata.type == 'episode'
          ? '${metadata.grandparentTitle ?? metadata.displayTitle} - ${metadata.displayTitle}'
          : metadata.displayTitle;

      // Get WiFi-only setting for native enforcement
      final settings = await SettingsService.getInstance();
      final requiresWiFi = settings.read(SettingsService.downloadOnWifiOnly);

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

        await _cleanupSafTargetFile(safDirUri, safFileName);

        final task = UriDownloadTask(
          url: playbackData.videoUrl!,
          filename: safFileName,
          directoryUri: Uri.parse(safDirUri),
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: _nativeRetries,
          allowPause: true,
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

        // Clean up partial files from previous attempts to prevent
        // background_downloader from creating numbered copies (File (1).mp4)
        await Future.wait([
          _deleteFileIfExists(File(downloadFilePath), 'stale video before re-download'),
          _deleteFileIfExists(File('$downloadFilePath.part'), 'stale .part before re-download'),
        ]);

        await File(downloadFilePath).parent.create(recursive: true);

        final task = DownloadTask(
          url: playbackData.videoUrl!,
          filename: path.basename(downloadFilePath),
          directory: path.dirname(downloadFilePath),
          baseDirectory: BaseDirectory.root,
          group: _downloadGroup,
          updates: Updates.statusAndProgress,
          requiresWiFi: requiresWiFi,
          retries: _nativeRetries,
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
      return true;
    } catch (e) {
      appLogger.e('Failed to prepare download for $globalKey', error: e);
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: e.toString());
      await _database.removeFromQueue(globalKey);
      _pendingDownloadContext.remove(globalKey);
      return false;
    }
  }

  /// Callback: background_downloader progress update
  void _onTaskProgress(TaskProgressUpdate update) {
    if (_disposed) return;
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

    // Debounce DB writes — only the latest progress value is persisted after
    // a 2-second settle period. The stream above provides real-time UI updates;
    // the DB write is only for crash-recovery state.
    _progressDebounceTimers[globalKey]?.cancel();
    _progressDebounceTimers[globalKey] = Timer(_progressDebounceDelay, () {
      _progressDebounceTimers.remove(globalKey);
      _database.updateDownloadProgress(globalKey, progress, downloadedBytes, totalBytes).catchError((e) {
        appLogger.w('Failed to update download progress in DB', error: e);
      });
    });
  }

  /// Callback: background_downloader status change
  void _onTaskStatusChanged(TaskStatusUpdate update) {
    if (_disposed) return;
    final globalKey = update.task.metaData;
    if (globalKey.isEmpty) return;

    appLogger.d('Background task status: ${update.status} for $globalKey');

    try {
      switch (update.status) {
        case TaskStatus.complete:
          _onDownloadComplete(globalKey, update.task);
        case TaskStatus.failed:
          _onDownloadFailed(globalKey, update.exception?.description ?? 'Download failed');
        case TaskStatus.notFound:
          _onDownloadPermanentlyFailed(globalKey, 'File not found (404)');
        case TaskStatus.canceled:
          if (_pausingKeys.contains(globalKey)) break;
          _onDownloadCanceled(globalKey);
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
    } catch (e) {
      appLogger.e('Error handling download status change for $globalKey', error: e);
    }
  }

  /// Handle a system-initiated cancel — re-queue unless already completed.
  Future<void> _onDownloadCanceled(String globalKey) async {
    _cancelDownloadTimers(globalKey);
    final ctx = _pendingDownloadContext.remove(globalKey);
    if (ctx == null) return;
    if (_completingKeys.contains(globalKey)) return;

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) return;

    appLogger.w('Download cancelled by system for $globalKey, re-queuing');
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final client = _getClient(parseGlobalKey(globalKey)?.serverId);
    if (client != null) unawaited(_processQueue(client));
  }

  /// Handle a failed download — auto-retry if retries remain, otherwise permanently fail.
  /// Native retries (Range-based resume) are already exhausted at this point.
  Future<void> _onDownloadFailed(String globalKey, String errorMessage) async {
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Ignoring failure event for $globalKey: completion in progress');
      return;
    }
    _cancelDownloadTimers(globalKey);
    _pendingDownloadContext.remove(globalKey);

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) {
      appLogger.d('Ignoring stale failure for completed download $globalKey');
      return;
    }
    final retryCount = existing?.retryCount ?? 0;

    // DNS/connection errors fail instantly and exhaust native retries in milliseconds,
    // creating a retry storm. Treat them as permanent failures.
    final isNetworkError =
        errorMessage.contains('Unable to resolve host') ||
        errorMessage.contains('No address associated with hostname') ||
        errorMessage.contains('Network is unreachable') ||
        errorMessage.contains('Connection refused');
    final isServerError = errorMessage.contains('500 Internal Server Error');

    final client = _getClient(parseGlobalKey(globalKey)?.serverId);
    final hadProgress = (existing?.downloadedBytes ?? 0) > 0;

    if (!isNetworkError && !isServerError && retryCount < _maxAppRetries && client != null) {
      // App-level auto-retry: schedule a fresh download after a delay.
      // Each new task gets 5 native retries with Range-based resume.
      appLogger.w(
        'Download failed for $globalKey (attempt ${retryCount + 1}/$_maxAppRetries), '
        'scheduling auto-retry in ${_autoRetryDelay.inSeconds}s: $errorMessage',
      );
      await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: errorMessage);
      await _database.removeFromQueue(globalKey);
      _autoRetryTimers[globalKey] = Timer(_autoRetryDelay, () {
        _autoRetryTimers.remove(globalKey);
        _performAutoRetry(globalKey);
      });

      // Only advance the queue if the download actually started transferring.
      // Instant failures (DNS, connection) would just cause the next item to fail too.
      if (hadProgress) unawaited(_processQueue(client));
    } else {
      if (isNetworkError) {
        appLogger.w('Network error for $globalKey, failing permanently (no auto-retry): $errorMessage');
      }
      final userMessage = isServerError ? t.downloads.serverErrorBitrate : errorMessage;
      await _onDownloadPermanentlyFailed(globalKey, userMessage);
    }
  }

  /// Handle a non-retryable failure (e.g. 404) — fail immediately without auto-retry.
  Future<void> _onDownloadPermanentlyFailed(String globalKey, String errorMessage) async {
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Ignoring permanent failure event for $globalKey: completion in progress');
      return;
    }
    _cancelDownloadTimers(globalKey);
    _pendingDownloadContext.remove(globalKey);

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing?.status == DownloadStatus.completed.index) {
      appLogger.d('Ignoring stale permanent failure for completed download $globalKey');
      return;
    }

    appLogger.e('Download permanently failed for $globalKey: $errorMessage');
    await _transitionStatus(globalKey, DownloadStatus.failed, errorMessage: errorMessage);
    await _database.removeFromQueue(globalKey);

    // Try to enqueue more items from the queue
    final client = _getClient(parseGlobalKey(globalKey)?.serverId);
    if (client != null) unawaited(_processQueue(client));
  }

  /// Execute an app-level auto-retry: transition back to queued and re-enqueue.
  Future<void> _performAutoRetry(String globalKey) async {
    if (_disposed) return;
    final client = _getClient(parseGlobalKey(globalKey)?.serverId);
    if (client == null) {
      appLogger.w('Cannot auto-retry $globalKey: no client available');
      return;
    }

    final existing = await _database.getDownloadedMedia(globalKey);
    if (existing == null || existing.status != DownloadStatus.failed.index) {
      // Download was cancelled/deleted/retried by user during the delay
      return;
    }

    appLogger.i('Auto-retrying download for $globalKey');
    await _database.updateBgTaskId(globalKey, null);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    unawaited(_processQueue(client));
  }

  /// Handle a completed video download — store path, download supplementary content, mark done.
  Future<void> _onDownloadComplete(String globalKey, Task task) async {
    _consecutiveQueueFailures = 0;
    // Prevent duplicate concurrent completions (e.g. trackTasks replaying events)
    if (_completingKeys.contains(globalKey)) {
      appLogger.d('Already processing completion for $globalKey, skipping');
      return;
    }
    _completingKeys.add(globalKey);
    try {
      // Flush any pending debounced progress write + cancel any scheduled retry
      _cancelDownloadTimers(globalKey);

      // Fresh DB check — bail if already completed (guards against race with orphan scan)
      final existingCheck = await _database.getDownloadedMedia(globalKey);
      if (existingCheck?.status == DownloadStatus.completed.index) {
        appLogger.d('Download already completed for $globalKey, skipping');
        return;
      }

      final ctx = _pendingDownloadContext.remove(globalKey);

      // ── Phase 1 (critical): resolve and store the video file path ──
      final String storedPath;
      if (ctx != null) {
        // Happy path: context available from this session
        if (ctx.isSafMode) {
          // UriDownloadTask wrote directly to SAF — find the file URI
          final child = await SafStorageService.instance.getChild(ctx.filePath, [task.filename]);
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
        final client = ctx?.client ?? _getClient(parseGlobalKey(globalKey)?.serverId);
        final showYear = ctx?.showYear;

        // Get queue item settings (still in drift at this point)
        final queueItem =
            ctx?.queueItem ??
            await (_database.select(
              _database.downloadQueue,
            )..where((t) => t.mediaGlobalKey.equals(globalKey))).getSingleOrNull();
        final downloadArtwork = queueItem?.downloadArtwork ?? true;
        final downloadSubtitles = queueItem?.downloadSubtitles ?? true;

        if (metadata != null && client != null) {
          if (downloadArtwork) {
            await _downloadArtwork(globalKey, metadata, client);
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
      await _database.removeFromQueue(globalKey);
    } finally {
      _completingKeys.remove(globalKey);
      // Always advance the queue, even after errors
      final nextClient = _getClient(parseGlobalKey(globalKey)?.serverId);
      if (nextClient != null) unawaited(_processQueue(nextClient));
    }
  }

  /// Resolve metadata from cache using a globalKey
  Future<PlexMetadata?> _resolveMetadata(String globalKey) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;
    return _apiCache.getMetadata(parsed.serverId, parsed.ratingKey);
  }

  /// Look up the year of the parent show for an episode (used for folder naming).
  Future<int?> _fetchShowYear(String serverId, String? grandparentRatingKey) async {
    if (grandparentRatingKey == null) return null;
    final showCached = await _apiCache.get(serverId, '/library/metadata/$grandparentRatingKey');
    final showJson = PlexCacheParser.extractFirstMetadata(showCached);
    if (showJson != null) return PlexMetadata.fromJson(showJson).year;
    return null;
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

    final child = await SafStorageService.instance.getChild(dirUri, [safFileName]);
    return child?.uri;
  }

  /// Download artwork for a media item using hash-based storage
  /// Downloads all artwork types: thumb/poster, clearLogo, and background art
  Future<void> _downloadArtwork(String globalKey, PlexMetadata metadata, PlexClient client) async {
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

      // Download square background art
      if (metadata.backgroundSquare != null) {
        await _downloadSingleArtwork(serverId, metadata.backgroundSquare!, client);
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
      await _http.downloadFile(url, filePath);
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

    // Download square background art
    if (metadata.backgroundSquare != null) {
      await _downloadSingleArtwork(serverId, metadata.backgroundSquare!, client);
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
        await _http.downloadFile(subtitleUrl, subtitlePath);

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
    if (_disposed) return;
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
    if (status == DownloadStatus.failed && errorMessage != null) {
      await _database.updateDownloadError(globalKey, errorMessage);
    }
    _emitProgress(
      globalKey,
      status,
      progress ?? (status == DownloadStatus.completed ? 100 : 0),
      errorMessage: errorMessage,
    );
  }

  /// Emit progress update with artwork paths so DownloadProvider can sync
  void _emitProgressWithArtwork(String globalKey, {String? thumbPath}) {
    if (_disposed) return;
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
      _cancelDownloadTimers(globalKey);
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
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final resolvedClient = _getClient(parseGlobalKey(globalKey)?.serverId) ?? client;
    unawaited(_processQueue(resolvedClient));
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, PlexClient client) async {
    _autoRetryTimers.remove(globalKey)?.cancel();
    await _database.clearDownloadError(globalKey);
    await _database.updateBgTaskId(globalKey, null);
    await _database.updateDownloadProgress(globalKey, 0, 0, 0);
    await _transitionStatus(globalKey, DownloadStatus.queued);
    await _database.addToQueue(mediaGlobalKey: globalKey);
    final resolvedClient = _getClient(parseGlobalKey(globalKey)?.serverId) ?? client;
    unawaited(_processQueue(resolvedClient));
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    _cancelDownloadTimers(globalKey);
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
    _cancelDownloadTimers(globalKey);
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
      DeletionProgress(globalKey: globalKey, itemTitle: metadata.displayTitle, currentItem: 0, totalItems: totalItems),
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
        itemTitle: metadata.displayTitle,
        currentItem: totalItems,
        totalItems: totalItems,
      ),
    );
  }

  /// Emit deletion progress update
  void _emitDeletionProgress(DeletionProgress progress) {
    if (_disposed) return;
    _deletionProgressController.add(progress);
  }

  /// Calculate total items to delete (for progress tracking)
  Future<int> _getTotalItemsToDelete(PlexMetadata metadata, String _) async {
    switch (metadata.mediaType) {
      case PlexMediaType.episode:
      case PlexMediaType.movie:
        return 1;
      case PlexMediaType.season:
        final episodes = await _database.getEpisodesBySeason(metadata.ratingKey);
        return episodes.length;
      case PlexMediaType.show:
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
        final gk = buildGlobalKey(serverId, ratingKey);
        final downloadRecord = await _database.getDownloadedMedia(gk);
        if (downloadRecord?.videoFilePath != null) {
          await _deleteByFilePath(downloadRecord!);
          return;
        }
        appLogger.w('Cannot delete - no metadata for $gk');
        return;
      }

      final isSaf = _storageService.isUsingSaf;
      switch (metadata.mediaType) {
        case PlexMediaType.episode:
          isSaf ? await _deleteEpisodeFilesSaf(metadata, serverId) : await _deleteEpisodeFiles(metadata, serverId);
          break;
        case PlexMediaType.season:
          isSaf ? await _deleteSeasonFilesSaf(metadata, serverId) : await _deleteSeasonFiles(metadata, serverId);
          break;
        case PlexMediaType.show:
          isSaf ? await _deleteShowFilesSaf(metadata, serverId) : await _deleteShowFiles(metadata, serverId);
          break;
        case PlexMediaType.movie:
          isSaf ? await _deleteMovieFilesSaf(metadata, serverId) : await _deleteMovieFiles(metadata, serverId);
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

  /// Delete chapter thumbnails for a media item (with reference counting).
  ///
  /// Pre-loads all chapter paths for other items on the same server in one pass,
  /// then checks membership in a Set — O(items * chapters) instead of
  /// O(thumbs * items * chapters) with repeated DB queries.
  Future<void> _deleteChapterThumbnails(String serverId, String ratingKey) async {
    try {
      final thumbPaths = await _getChapterThumbPaths(serverId, ratingKey);

      if (thumbPaths.isEmpty) {
        appLogger.d('No chapter thumbnails to delete for $ratingKey');
        return;
      }

      // Build a set of all chapter thumb paths used by OTHER items on this server
      final otherItems = await _database.getDownloadsByServerId(serverId);
      final inUseThumbPaths = <String>{};
      for (final item in otherItems) {
        if (item.ratingKey == ratingKey) continue;
        final itemChapterPaths = await _getChapterThumbPaths(serverId, item.ratingKey);
        inUseThumbPaths.addAll(itemChapterPaths);
      }

      int deletedCount = 0;
      int preservedCount = 0;

      for (final thumbPath in thumbPaths) {
        try {
          if (inUseThumbPaths.contains(thumbPath)) {
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
        }
      }

      if (deletedCount > 0 || preservedCount > 0) {
        appLogger.i('Deleted $deletedCount of ${thumbPaths.length} chapter thumbnails ($preservedCount preserved)');
      }
    } catch (e, stack) {
      appLogger.w('Error deleting chapter thumbnails for $ratingKey', error: e, stackTrace: stack);
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

      // Safety net: verify the actual DB-recorded file is gone
      await _ensureDbFileDeleted(serverId, episode.ratingKey);
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
        parentTitle: season.displayTitle,
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

  /// Delete episodes in a collection (season or show). In SAF mode, cleans up
  /// app-private subtitle/thumbnail assets per episode — the SAF video files
  /// and parent directories are wiped in one recursive call by the caller.
  Future<void> _deleteEpisodesInCollection({
    required List<DownloadedMediaItem> episodes,
    required String serverId,
    required String parentKey,
    required String parentTitle,
  }) async {
    final isSaf = _storageService.isUsingSaf;
    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final episodeGlobalKey = buildGlobalKey(serverId, episode.ratingKey);

      _emitDeletionProgress(
        DeletionProgress(
          globalKey: buildGlobalKey(serverId, parentKey),
          itemTitle: parentTitle,
          currentItem: i + 1,
          totalItems: episodes.length,
          currentOperation: 'Deleting episode ${i + 1} of ${episodes.length}',
        ),
      );

      if (isSaf) {
        final episodeMetadata = await _apiCache.getMetadata(serverId, episode.ratingKey);
        if (episodeMetadata != null) {
          await _deleteEpisodeFilesSaf(episodeMetadata, serverId, skipSafVideoAndParents: true);
        } else {
          await _deleteChapterThumbnails(serverId, episode.ratingKey);
          await _deleteByFilePath(episode);
        }
      } else {
        await _deleteChapterThumbnails(serverId, episode.ratingKey);
        await _deleteByFilePath(episode);
      }

      await _apiCache.deleteForItem(serverId, episode.ratingKey);
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
        parentTitle: show.displayTitle,
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

      // Safety net: verify the actual DB-recorded file is gone
      await _ensureDbFileDeleted(serverId, movie.ratingKey);
    } catch (e, stack) {
      appLogger.e('Error deleting movie files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteMovieFilesSaf(PlexMetadata movie, String serverId) async {
    try {
      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final movieDir = await SafStorageService.instance.getChild(
          safBaseUri,
          _storageService.getMovieSafPathComponents(movie),
        );
        if (movieDir != null) {
          await _deleteSafDirRecursive(movieDir.uri, description: 'movie directory');
        }
      }
      await _deleteChapterThumbnails(serverId, movie.ratingKey);
      await _ensureDbFileDeleted(serverId, movie.ratingKey);
    } catch (e, stack) {
      appLogger.e('Error deleting SAF movie files', error: e, stackTrace: stack);
    }
  }

  /// When called inside a bulk season/show delete, the caller wipes the parent
  /// dir — so we skip the SAF video delete and parent walk-up here.
  Future<void> _deleteEpisodeFilesSaf(
    PlexMetadata episode,
    String serverId, {
    bool skipSafVideoAndParents = false,
  }) async {
    try {
      final parentMetadata = episode.grandparentRatingKey != null
          ? await _apiCache.getMetadata(serverId, episode.grandparentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      final safBaseUri = _storageService.safBaseUri;
      String? seasonDirUri;
      String? showDirUri;

      if (safBaseUri != null && !skipSafVideoAndParents) {
        final saf = SafStorageService.instance;
        final resolved = await Future.wait([
          saf.getChild(safBaseUri, _storageService.getEpisodeSafPathComponents(episode, showYear: showYear)),
          saf.getChild(safBaseUri, _storageService.getShowSafPathComponents(episode, showYear: showYear)),
        ]);
        seasonDirUri = resolved[0]?.uri;
        showDirUri = resolved[1]?.uri;

        if (seasonDirUri != null) {
          final baseName = _storageService.getEpisodeSafBaseName(episode);
          final file = await _findSafFileByBaseName(seasonDirUri, baseName);
          if (file != null) {
            await _tryDeleteSaf(file.uri, isDir: false, description: 'SAF episode video');
          }
        }
      }

      // Subtitles and the episode thumbnail are written into app-private storage
      // even in SAF mode (getDownloadsDirectory() falls through to default when
      // _customPathType == 'saf'). Deletion follows suit until writing is migrated.
      final thumbPath = await _storageService.getEpisodeThumbnailPath(episode, showYear: showYear);
      await _deleteFileIfExists(File(thumbPath), 'episode thumbnail');

      final subsDir = await _storageService.getEpisodeSubtitlesDirectory(episode, showYear: showYear);
      if (await subsDir.exists()) {
        await subsDir.delete(recursive: true);
        appLogger.i('Deleted episode subtitles: ${subsDir.path}');
      }

      await _deleteChapterThumbnails(serverId, episode.ratingKey);

      if (!skipSafVideoAndParents) {
        await _deleteEmptySafDirsInOrder([seasonDirUri, showDirUri]);
        await _ensureDbFileDeleted(serverId, episode.ratingKey);
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF episode files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteSeasonFilesSaf(PlexMetadata season, String serverId) async {
    try {
      final parentMetadata = season.parentRatingKey != null
          ? await _apiCache.getMetadata(serverId, season.parentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      final episodesInSeason = await _database.getEpisodesBySeason(season.ratingKey);
      appLogger.d('Deleting ${episodesInSeason.length} episodes in season ${season.ratingKey} (SAF)');
      await _deleteEpisodesInCollection(
        episodes: episodesInSeason,
        serverId: serverId,
        parentKey: season.ratingKey,
        parentTitle: season.displayTitle,
      );

      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final saf = SafStorageService.instance;
        final seasonDir = await saf.getChild(
          safBaseUri,
          _storageService.getSeasonSafPathComponents(season, showYear: showYear),
        );
        if (seasonDir != null) {
          await _deleteSafDirRecursive(seasonDir.uri, description: 'season directory');
        }
        final showDir = await saf.getChild(
          safBaseUri,
          _storageService.getShowSafPathComponents(season, showYear: showYear),
        );
        if (showDir != null) {
          await _deleteEmptySafDirsInOrder([showDir.uri]);
        }
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF season files', error: e, stackTrace: stack);
    }
  }

  Future<void> _deleteShowFilesSaf(PlexMetadata show, String serverId) async {
    try {
      final episodesInShow = await _database.getEpisodesByShow(show.ratingKey);
      appLogger.d('Deleting ${episodesInShow.length} episodes in show ${show.ratingKey} (SAF)');
      await _deleteEpisodesInCollection(
        episodes: episodesInShow,
        serverId: serverId,
        parentKey: show.ratingKey,
        parentTitle: show.displayTitle,
      );

      final safBaseUri = _storageService.safBaseUri;
      if (safBaseUri != null) {
        final showDir = await SafStorageService.instance.getChild(
          safBaseUri,
          _storageService.getShowSafPathComponents(show),
        );
        if (showDir != null) {
          await _deleteSafDirRecursive(showDir.uri, description: 'show directory');
        }
      }
    } catch (e, stack) {
      appLogger.e('Error deleting SAF show files', error: e, stackTrace: stack);
    }
  }

  /// Safety net: after metadata-based deletion, verify the actual DB-recorded
  /// video file is gone. If not, delete it and clean up parent directories.
  Future<void> _ensureDbFileDeleted(String serverId, String ratingKey) async {
    try {
      final globalKey = buildGlobalKey(serverId, ratingKey);
      final record = await _database.getDownloadedMedia(globalKey);
      if (record?.videoFilePath == null) return;

      final storedPath = record!.videoFilePath!;
      if (_storageService.isSafUri(storedPath)) {
        // SAF mode: parent cleanup is handled by the type-specific SAF helpers —
        // here we only verify the video URI itself is gone.
        if (await SafStorageService.instance.exists(storedPath, isDir: false)) {
          appLogger.w('Safety net: SAF video still exists after metadata deletion, deleting: $storedPath');
          await SafStorageService.instance.delete(storedPath, isDir: false);
        }
        return;
      }

      final videoPath = await _storageService.ensureAbsolutePath(storedPath);
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) return;

      appLogger.w('Safety net: video still exists after metadata deletion, deleting: $videoPath');
      await videoFile.delete();

      // Clean up .part file and subtitles directory alongside video
      await _deleteFileIfExists(File('$videoPath.part'), 'partial download');
      final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
      final subsDir = Directory(subsPath);
      if (await subsDir.exists()) await subsDir.delete(recursive: true);

      // Walk up empty parent directories toward downloads root
      await _cleanupEmptyParentDirectories(videoFile.parent);
    } catch (e, stack) {
      appLogger.w('Safety net deletion failed', error: e, stackTrace: stack);
    }
  }

  /// Walk up from a directory toward the downloads root, removing empty dirs.
  Future<void> _cleanupEmptyParentDirectories(Directory dir) async {
    try {
      final downloadsDir = await _storageService.getDownloadsDirectory();
      var current = dir;
      while (current.path != downloadsDir.path && current.path.startsWith(downloadsDir.path)) {
        if (!await current.exists()) {
          current = current.parent;
          continue;
        }
        final contents = await current.list().toList();
        if (contents.isEmpty) {
          await current.delete();
          appLogger.i('Cleaned up empty directory: ${current.path}');
          current = current.parent;
        } else {
          break;
        }
      }
    } catch (e) {
      appLogger.w('Error cleaning up parent directories', error: e);
    }
  }

  /// Clean up empty directories after deleting episode (file mode only — the
  /// SAF deleters call [_deleteEmptySafDirsInOrder] directly).
  Future<void> _cleanupEmptyDirectories(PlexMetadata episode, int? showYear) async {
    if (_storageService.isUsingSaf) return;
    final seasonDir = await _storageService.getSeasonDirectory(episode, showYear: showYear);

    if (await seasonDir.exists()) {
      final contents = await seasonDir.list().toList();
      final hasVideos = contents.any(
        (e) => _videoExtensions.any((ext) => e.path.endsWith(ext)) || e.path.contains('_subs'),
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

  /// Clean up show directory if empty (file mode only).
  Future<void> _cleanupShowDirectory(PlexMetadata metadata, int? showYear) async {
    if (_storageService.isUsingSaf) return;
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
  Future<bool> _isSeasonArtworkInUse(PlexMetadata episode, int? _) async {
    final seasonKey = episode.parentRatingKey;
    if (seasonKey == null) return false;

    final otherEpisodes = await _database.getEpisodesBySeason(seasonKey);

    // Check if any episodes besides this one
    return otherEpisodes.any((e) => e.globalKey != episode.globalKey);
  }

  /// Check if show artwork is in use
  Future<bool> _isShowArtworkInUse(PlexMetadata metadata, int? _) async {
    final showKey = metadata.grandparentRatingKey ?? metadata.parentRatingKey ?? metadata.ratingKey;

    // Use targeted query instead of full table scan
    final showEpisodes = await _database.getEpisodesByShow(showKey);

    // Check if any episodes belong to this show besides the current item
    return showEpisodes.any((item) => item.globalKey != metadata.globalKey);
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
      if (record.videoFilePath != null && _storageService.isSafUri(record.videoFilePath!)) {
        // Metadata is gone by the time this fallback runs, so parent-dir cleanup
        // is not attempted here — SAF URIs don't expose a parent reliably.
        await _tryDeleteSaf(record.videoFilePath!, isDir: false, description: 'SAF video file');
      } else if (record.videoFilePath != null) {
        final videoPath = await _storageService.ensureAbsolutePath(record.videoFilePath!);
        final videoFile = File(videoPath);
        final videoDeleted = await _deleteFileIfExists(videoFile, 'video file');

        if (videoDeleted) {
          // Delete .part file from interrupted downloads
          await _deleteFileIfExists(File('$videoPath.part'), 'partial download');

          // Delete subtitle directory
          final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
          final subsDir = Directory(subsPath);
          if (await subsDir.exists()) {
            await subsDir.delete(recursive: true);
            appLogger.i('Deleted subtitles: $subsPath');
          }

          // Clean up empty parent directories
          await _cleanupEmptyParentDirectories(videoFile.parent);
        }
      }

      // thumbPath is a Plex API path (e.g. /library/metadata/123/thumb/...),
      // not a local file path — resolve it via getArtworkPathFromThumb
      if (record.thumbPath != null) {
        final parsed = parseGlobalKey(record.globalKey);
        if (parsed != null) {
          final thumbPath = await _storageService.getArtworkPathFromThumb(parsed.serverId, record.thumbPath!);
          await _deleteFileIfExists(File(thumbPath), 'thumbnail');
        }
      }
    } catch (e, stack) {
      appLogger.e('Error in fallback deletion', error: e, stackTrace: stack);
    }
  }

  /// Get all downloaded media items (for loading persisted data)
  Future<List<DownloadedMediaItem>> getAllDownloads() {
    return _database.select(_database.downloadedMedia).get();
  }

  /// Get a specific downloaded media item by globalKey
  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) {
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
  /// Merges with existing cache to preserve Chapter/Marker/Media arrays
  Future<void> _cacheMetadataForOffline(String serverId, String ratingKey, PlexMetadata metadata) async {
    final endpoint = '/library/metadata/$ratingKey';

    // Check for existing cache entry to preserve fields not in PlexMetadata
    final existing = await _apiCache.get(serverId, endpoint);
    final existingMeta = PlexCacheParser.extractFirstMetadata(existing);

    Map<String, dynamic> merged;
    if (existingMeta != null) {
      // Start with existing (has Chapter/Marker/Media), overlay new metadata
      merged = existingMeta;
      final newJson = metadata.toJson();
      // Only update fields that toJson() sets to non-null values
      for (final entry in newJson.entries) {
        if (entry.value != null) {
          merged[entry.key] = entry.value;
        }
      }
    } else {
      merged = metadata.toJson();
    }

    final cachedResponse = {
      'MediaContainer': {
        'Metadata': [merged],
      },
    };

    await _apiCache.put(serverId, endpoint, cachedResponse);
    await _apiCache.pinForOffline(serverId, ratingKey);
  }

  void dispose() {
    _disposed = true;
    for (final timer in _progressDebounceTimers.values) {
      timer.cancel();
    }
    _progressDebounceTimers.clear();
    for (final timer in _autoRetryTimers.values) {
      timer.cancel();
    }
    _autoRetryTimers.clear();
    _pendingDownloadContext.clear();
    _pendingSupplementaryDownloads.clear();
    _completingKeys.clear();
    _pausingKeys.clear();
    _progressController.close();
    _deletionProgressController.close();
  }
}
