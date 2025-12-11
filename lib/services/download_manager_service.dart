import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import '../database/app_database.dart';
import 'settings_service.dart';
import '../models/download_status.dart';
import '../models/download_progress.dart';
import '../models/deletion_progress.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../services/plex_client.dart';
import '../services/download_storage_service.dart';
import '../services/plex_api_cache.dart';
import '../utils/app_logger.dart';

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
    final query = select(downloadQueue).join([
      innerJoin(
        downloadedMedia,
        downloadedMedia.globalKey.equalsExp(downloadQueue.mediaGlobalKey),
      ),
    ]);

    query
      ..where(downloadedMedia.status.equals(DownloadStatus.paused.index).not())
      ..orderBy([
        OrderingTerm(
          expression: downloadQueue.priority,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(expression: downloadQueue.addedAt),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.readTable(downloadQueue);
  }

  /// Update download status
  Future<void> updateDownloadStatus(String globalKey, int status) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey)))
        .write(DownloadedMediaCompanion(status: Value(status)));
  }

  /// Update download progress
  Future<void> updateDownloadProgress(
    String globalKey,
    int progress,
    int downloadedBytes,
    int totalBytes,
  ) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        progress: Value(progress),
        downloadedBytes: Value(downloadedBytes),
        totalBytes: Value(totalBytes),
      ),
    );
  }

  /// Update video file path
  Future<void> updateVideoFilePath(String globalKey, String filePath) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        videoFilePath: Value(filePath),
        downloadedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Update artwork paths
  Future<void> updateArtworkPaths({
    required String globalKey,
    String? thumbPath,
  }) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey)))
        .write(DownloadedMediaCompanion(thumbPath: Value(thumbPath)));
  }

  /// Update download error and increment retry count
  Future<void> updateDownloadError(
    String globalKey,
    String errorMessage,
  ) async {
    // Get current retry count to increment it
    final existing = await getDownloadedMedia(globalKey);
    final currentCount = existing?.retryCount ?? 0;

    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        errorMessage: Value(errorMessage),
        retryCount: Value(currentCount + 1),
      ),
    );
  }

  /// Clear download error and reset retry count (for retry)
  Future<void> clearDownloadError(String globalKey) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey)))
        .write(const DownloadedMediaCompanion(
      errorMessage: Value(null),
      retryCount: Value(0),
    ));
  }

  /// Remove item from queue
  Future<void> removeFromQueue(String mediaGlobalKey) async {
    await (delete(
      downloadQueue,
    )..where((t) => t.mediaGlobalKey.equals(mediaGlobalKey))).go();
  }

  /// Get downloaded media item
  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) async {
    return (select(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  /// Delete a download
  Future<void> deleteDownload(String globalKey) async {
    await (delete(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(
      downloadQueue,
    )..where((t) => t.mediaGlobalKey.equals(globalKey))).go();
  }
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
  final _deletionProgressController =
      StreamController<DeletionProgress>.broadcast();
  Stream<DeletionProgress> get deletionProgressStream =>
      _deletionProgressController.stream;

  // Active downloads with cancel tokens
  final Map<String, CancelToken> _activeDownloads = {};

  // Flag to prevent multiple queue processing
  bool _isProcessingQueue = false;

  // Connectivity listener for auto-resume
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Cached client for auto-resume
  PlexClient? _lastClient;

  /// Check if downloads should be blocked due to cellular-only setting
  Future<bool> _shouldBlockDownload() async {
    return shouldBlockDownloadOnCellular();
  }

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

  DownloadManagerService({
    required AppDatabase database,
    required DownloadStorageService storageService,
    Dio? dio,
  }) : _database = database,
       _storageService = storageService,
       _dio = dio ?? Dio();

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
        (existing.status == DownloadStatus.downloading.index ||
            existing.status == DownloadStatus.completed.index)) {
      appLogger.i(
        'Download already exists for $globalKey with status ${existing.status}',
      );
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

  /// Start processing the download queue - processes one item at a time
  Future<void> _processQueue(PlexClient client) async {
    if (_isProcessingQueue) {
      appLogger.d('Queue processing already in progress');
      return;
    }

    _isProcessingQueue = true;
    _lastClient = client; // Cache for auto-resume
    _setupConnectivityListener(); // Setup listener for auto-resume

    try {
      while (true) {
        // Check if we should pause due to cellular
        if (await _shouldBlockDownload()) {
          appLogger.i(
            'Pausing downloads - on cellular data with WiFi-only enabled',
          );
          break;
        }

        // Get next item from queue
        final nextItem = await _database.getNextQueueItem();
        if (nextItem == null) {
          appLogger.d('No more items in queue');
          break;
        }

        await _startDownload(nextItem.mediaGlobalKey, client, nextItem);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Setup connectivity listener to auto-resume downloads when WiFi becomes available
  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      // If WiFi becomes available, try to resume queue
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        final hasQueuedItems = await _database.getNextQueueItem() != null;
        if (hasQueuedItems && !_isProcessingQueue && _lastClient != null) {
          appLogger.i('WiFi available - resuming downloads');
          _processQueue(_lastClient!);
        }
      }
    });
  }

  /// Start downloading a specific item
  Future<void> _startDownload(
    String globalKey,
    PlexClient client,
    DownloadQueueItem queueItem,
  ) async {
    try {
      appLogger.i('Starting download for $globalKey');

      // Update status to downloading
      await _database.updateDownloadStatus(
        globalKey,
        DownloadStatus.downloading.index,
      );
      appLogger.d('Status updated to downloading, emitting initial progress');
      _emitProgress(globalKey, DownloadStatus.downloading, 0);

      // Parse globalKey to get serverId and ratingKey
      final parts = globalKey.split(':');
      final serverId = parts[0];
      final ratingKey = parts[1];

      // Get metadata from cache
      final cachedResponse = await _apiCache.get(
        serverId,
        '/library/metadata/$ratingKey',
      );
      if (cachedResponse == null) {
        throw Exception('Metadata not found in cache for $globalKey');
      }

      // Parse metadata from cached response
      final metadataList =
          cachedResponse['MediaContainer']?['Metadata'] as List?;
      if (metadataList == null || metadataList.isEmpty) {
        throw Exception('Invalid cached metadata for $globalKey');
      }
      final metadata = PlexMetadata.fromJson(
        metadataList[0],
      ).copyWith(serverId: serverId);

      // Get video playback data (includes URL, streams, etc.)
      final playbackData = await client.getVideoPlaybackData(
        metadata.ratingKey,
      );
      if (playbackData.videoUrl == null) {
        throw Exception('Could not get video URL');
      }

      // Cache playback extras (chapters + markers) for offline use
      // This fetches and caches in one call
      await client.getPlaybackExtras(metadata.ratingKey);

      // Determine file extension from URL or default to mp4
      final extension = _getExtensionFromUrl(playbackData.videoUrl!) ?? 'mp4';

      final metadataWithServer = metadata;

      // For episodes, look up the show's year from cached show metadata
      int? showYear;
      if (metadataWithServer.type == 'episode' &&
          metadataWithServer.grandparentRatingKey != null) {
        final showCached = await _apiCache.get(
          serverId,
          '/library/metadata/${metadataWithServer.grandparentRatingKey}',
        );
        if (showCached != null) {
          final showList = showCached['MediaContainer']?['Metadata'] as List?;
          if (showList != null && showList.isNotEmpty) {
            final showMetadata = PlexMetadata.fromJson(showList[0]);
            showYear = showMetadata.year;
          }
        }
      }

      // Create cancel token
      final cancelToken = CancelToken();
      _activeDownloads[globalKey] = cancelToken;

      appLogger.d('Starting video download for $globalKey');

      // Determine download path and handle SAF mode
      final String downloadFilePath;
      final String storedPath;

      if (_storageService.isUsingSaf) {
        // SAF mode: download to temp cache first, then copy to SAF
        final tempFileName = '${globalKey.replaceAll(':', '_')}.$extension';
        downloadFilePath = await _storageService.getTempDownloadPath(
          tempFileName,
        );

        // Download to temp path
        await _downloadFile(
          url: playbackData.videoUrl!,
          filePath: downloadFilePath,
          globalKey: globalKey,
          cancelToken: cancelToken,
        );

        appLogger.d('Video downloaded to temp, copying to SAF for $globalKey');

        // Copy to SAF
        final List<String> pathComponents;
        final String safFileName;
        if (metadataWithServer.type == 'movie') {
          pathComponents = _storageService.getMovieSafPathComponents(
            metadataWithServer,
          );
          safFileName = _storageService.getMovieSafFileName(
            metadataWithServer,
            extension,
          );
        } else if (metadataWithServer.type == 'episode') {
          pathComponents = _storageService.getEpisodeSafPathComponents(
            metadataWithServer,
            showYear: showYear,
          );
          safFileName = _storageService.getEpisodeSafFileName(
            metadataWithServer,
            extension,
          );
        } else {
          pathComponents = [serverId, metadataWithServer.ratingKey];
          safFileName = 'video.$extension';
        }

        final safUri = await _storageService.copyToSaf(
          downloadFilePath,
          pathComponents,
          safFileName,
          _storageService.getMimeType(extension),
        );

        if (safUri == null) {
          throw Exception('Failed to copy video to SAF storage');
        }

        storedPath = safUri;
        appLogger.d('Video copied to SAF: $safUri');
      } else {
        // Normal mode: download directly to final path
        if (metadataWithServer.type == 'movie') {
          downloadFilePath = await _storageService.getMovieVideoPath(
            metadataWithServer,
            extension,
          );
        } else if (metadataWithServer.type == 'episode') {
          downloadFilePath = await _storageService.getEpisodeVideoPath(
            metadataWithServer,
            extension,
            showYear: showYear,
          );
        } else {
          downloadFilePath = await _storageService.getVideoFilePath(
            serverId,
            metadataWithServer.ratingKey,
            extension,
          );
        }

        await _downloadFile(
          url: playbackData.videoUrl!,
          filePath: downloadFilePath,
          globalKey: globalKey,
          cancelToken: cancelToken,
        );

        // Store relative path (survives iOS container UUID changes)
        storedPath = await _storageService.toRelativePath(downloadFilePath);
      }

      appLogger.d('Video download completed for $globalKey');

      // Update database with stored path (SAF URI or relative path)
      await _database.updateVideoFilePath(globalKey, storedPath);

      // Download artwork if enabled (only episode-specific artwork, not show/season)
      // Use the passed queueItem's settings (not getNextQueueItem which would return the NEXT item)
      if (queueItem.downloadArtwork) {
        await _downloadArtwork(
          globalKey,
          metadataWithServer,
          client,
          showYear: showYear,
        );

        // Download chapter thumbnails
        await _downloadChapterThumbnails(
          metadataWithServer.serverId!,
          metadataWithServer.ratingKey,
          client,
        );
      }

      // Download subtitles if enabled
      if (queueItem.downloadSubtitles && playbackData.mediaInfo != null) {
        await _downloadSubtitles(
          globalKey,
          metadataWithServer,
          playbackData.mediaInfo!,
          client,
          showYear: showYear,
        );
      }

      // Mark as completed
      await _database.updateDownloadStatus(
        globalKey,
        DownloadStatus.completed.index,
      );
      await _database.removeFromQueue(globalKey);
      _emitProgress(globalKey, DownloadStatus.completed, 100);

      _activeDownloads.remove(globalKey);

      appLogger.i('Download completed for $globalKey');
    } catch (e) {
      // Check if this was a user-initiated cancel/pause (not a real failure)
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Status was already set by pauseDownload() or cancelDownload()
        // Just clean up and exit without marking as failed
        appLogger.d('Download cancelled/paused for $globalKey: ${e.message}');
        _activeDownloads.remove(globalKey);
        return;
      }

      appLogger.e('Download failed for $globalKey', error: e);
      await _database.updateDownloadStatus(
        globalKey,
        DownloadStatus.failed.index,
      );
      await _database.updateDownloadError(globalKey, e.toString());
      // Remove from queue to prevent endless retry loop
      await _database.removeFromQueue(globalKey);
      _emitProgress(
        globalKey,
        DownloadStatus.failed,
        0,
        errorMessage: e.toString(),
      );
      _activeDownloads.remove(globalKey);
    }
  }

  Future<void> _downloadFile({
    required String url,
    required String filePath,
    required String globalKey,
    required CancelToken cancelToken,
  }) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);

    int lastBytes = 0;
    DateTime lastUpdate = DateTime.now();

    await _dio.download(
      url,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        // Calculate speed (update every 500ms)
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds >= 500) {
          final elapsedSeconds = now
              .difference(lastUpdate)
              .inSeconds
              .clamp(1, double.infinity);
          final bytesPerSecond = (received - lastBytes) / elapsedSeconds;
          lastUpdate = now;
          lastBytes = received;

          final progress = total > 0 ? ((received / total) * 100).round() : 0;

          appLogger.d(
            'Download progress: $progress% ($received/$total bytes) for $globalKey',
          );

          _progressController.add(
            DownloadProgress(
              globalKey: globalKey,
              status: DownloadStatus.downloading,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
              speed: bytesPerSecond,
              currentFile: 'video',
            ),
          );

          // Update database asynchronously (non-blocking)
          _database
              .updateDownloadProgress(globalKey, progress, received, total)
              .catchError((e) {
                appLogger.w(
                  'Failed to update download progress in DB',
                  error: e,
                );
              });
        }
      },
    );
  }

  /// Download artwork for a media item using hash-based storage
  /// Downloads all artwork types: thumb/poster, clearLogo, and background art
  Future<void> _downloadArtwork(
    String globalKey,
    PlexMetadata metadata,
    PlexClient client, {
    int? showYear,
  }) async {
    if (metadata.serverId == null) return;

    try {
      _emitProgress(
        globalKey,
        DownloadStatus.downloading,
        0,
        currentFile: 'artwork',
      );

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
      await _database.updateArtworkPaths(
        globalKey: globalKey,
        thumbPath: metadata.thumb,
      );

      _emitProgressWithArtwork(globalKey, thumbPath: metadata.thumb);
      appLogger.d('Artwork downloaded for $globalKey');
    } catch (e) {
      appLogger.w('Failed to download artwork for $globalKey', error: e);
      // Don't fail the entire download if artwork fails
    }
  }

  /// Download a single artwork file if it doesn't already exist
  Future<void> _downloadSingleArtwork(
    String serverId,
    String artworkPath,
    PlexClient client,
  ) async {
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

      final filePath = await _storageService.getArtworkPathFromThumb(
        serverId,
        artworkPath,
      );
      final file = File(filePath);

      // Ensure parent directory exists
      await file.parent.create(recursive: true);

      // Download the artwork
      await _dio.download(url, filePath);
      appLogger.i('Downloaded artwork: $artworkPath -> $filePath');
    } catch (e, stack) {
      appLogger.w(
        'Failed to download artwork: $artworkPath',
        error: e,
        stackTrace: stack,
      );
      // Don't throw - artwork download failures shouldn't kill the entire download
    }
  }

  /// Download all artwork for a metadata item (public method for parent metadata)
  /// Downloads thumb/poster, clearLogo, and background art
  Future<void> downloadArtworkForMetadata(
    PlexMetadata metadata,
    PlexClient client,
  ) async {
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
  Future<void> _downloadChapterThumbnails(
    String serverId,
    String ratingKey,
    PlexClient client,
  ) async {
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
      _emitProgress(
        globalKey,
        DownloadStatus.downloading,
        0,
        currentFile: 'subtitles',
      );

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
        final extension = _getExtensionFromCodec(subtitle.codec);

        // Get user-friendly subtitle path based on media type
        final String subtitlePath;
        if (metadata.type == 'episode') {
          subtitlePath = await _storageService.getEpisodeSubtitlePath(
            metadata,
            subtitle.id,
            extension,
            showYear: showYear,
          );
        } else if (metadata.type == 'movie') {
          subtitlePath = await _storageService.getMovieSubtitlePath(
            metadata,
            subtitle.id,
            extension,
          );
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

  String _getExtensionFromCodec(String? codec) {
    if (codec == null) return 'srt';

    switch (codec.toLowerCase()) {
      case 'subrip':
      case 'srt':
        return 'srt';
      case 'ass':
        return 'ass';
      case 'ssa':
        return 'ssa';
      case 'webvtt':
      case 'vtt':
        return 'vtt';
      case 'mov_text':
        return 'srt';
      case 'pgs':
      case 'hdmv_pgs_subtitle':
        return 'sup';
      case 'dvd_subtitle':
      case 'dvdsub':
        return 'sub';
      default:
        return 'srt';
    }
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
    // Cancel active download if exists
    final cancelToken = _activeDownloads[globalKey];
    if (cancelToken != null) {
      cancelToken.cancel('Paused by user');
      _activeDownloads.remove(globalKey);
    }
    // Update status to paused
    await _database.updateDownloadStatus(
      globalKey,
      DownloadStatus.paused.index,
    );
    // Remove from queue so it doesn't restart
    await _database.removeFromQueue(globalKey);
    _emitProgress(globalKey, DownloadStatus.paused, 0);
  }

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, PlexClient client) async {
    await _database.updateDownloadStatus(
      globalKey,
      DownloadStatus.queued.index,
    );
    // Re-add to queue (pauseDownload removes from queue)
    await _database.addToQueue(mediaGlobalKey: globalKey);
    _emitProgress(globalKey, DownloadStatus.queued, 0);
    _processQueue(client);
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, PlexClient client) async {
    // Clear error and reset retry count
    await _database.clearDownloadError(globalKey);
    // Reset status to queued
    await _database.updateDownloadStatus(
      globalKey,
      DownloadStatus.queued.index,
    );
    // Re-add to queue
    await _database.addToQueue(mediaGlobalKey: globalKey);
    _emitProgress(globalKey, DownloadStatus.queued, 0);
    _processQueue(client);
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    final cancelToken = _activeDownloads[globalKey];
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled by user');
      _activeDownloads.remove(globalKey);
    }
    await _database.updateDownloadStatus(
      globalKey,
      DownloadStatus.cancelled.index,
    );
    await _database.removeFromQueue(globalKey);
    _emitProgress(globalKey, DownloadStatus.cancelled, 0);
  }

  /// Delete a downloaded item and its files
  Future<void> deleteDownload(String globalKey) async {
    // Cancel if actively downloading
    final cancelToken = _activeDownloads[globalKey];
    if (cancelToken != null) {
      cancelToken.cancel('Download deleted');
      _activeDownloads.remove(globalKey);
    }

    // Delete files from storage
    final parts = globalKey.split(':');
    if (parts.length != 2) {
      await _database.deleteDownload(globalKey);
      return;
    }

    final serverId = parts[0];
    final ratingKey = parts[1];
    final metadata = await _getMetadataFromCache(serverId, ratingKey);

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
      DeletionProgress(
        globalKey: globalKey,
        itemTitle: metadata.title,
        currentItem: 0,
        totalItems: totalItems,
      ),
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
  Future<int> _getTotalItemsToDelete(
    PlexMetadata metadata,
    String serverId,
  ) async {
    switch (metadata.type.toLowerCase()) {
      case 'episode':
        return 1; // Single episode
      case 'movie':
        return 1; // Single movie
      case 'season':
        // Count episodes in season
        final seasonKey = metadata.ratingKey;
        final episodes = await (_database.select(
          _database.downloadedMedia,
        )..where((t) => t.parentRatingKey.equals(seasonKey))).get();
        return episodes.length;
      case 'show':
        // Count all episodes in show
        final showKey = metadata.ratingKey;
        final episodes = await (_database.select(
          _database.downloadedMedia,
        )..where((t) => t.grandparentRatingKey.equals(showKey))).get();
        return episodes.length;
      default:
        return 1;
    }
  }

  /// Delete media files using metadata to find correct paths
  Future<void> _deleteMediaFilesWithMetadata(
    String serverId,
    String ratingKey,
  ) async {
    try {
      // Get metadata from API cache
      final metadata = await _getMetadataFromCache(serverId, ratingKey);

      if (metadata == null) {
        // Fallback: Try database record
        final downloadRecord = await _database.getDownloadedMedia(
          '$serverId:$ratingKey',
        );
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

  /// Get metadata from API cache
  Future<PlexMetadata?> _getMetadataFromCache(
    String serverId,
    String ratingKey,
  ) async {
    final cachedData = await _apiCache.get(
      serverId,
      '/library/metadata/$ratingKey',
    );
    if (cachedData != null && cachedData['MediaContainer'] != null) {
      final container = cachedData['MediaContainer'] as Map<String, dynamic>;
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        final metadataJson = container['Metadata'][0] as Map<String, dynamic>;
        return PlexMetadata.fromJson(metadataJson).copyWith(serverId: serverId);
      }
    }
    return null;
  }

  /// Get chapter thumb paths from cached metadata
  Future<List<String>> _getChapterThumbPaths(
    String serverId,
    String ratingKey,
  ) async {
    try {
      final cachedData = await _apiCache.get(
        serverId,
        '/library/metadata/$ratingKey',
      );

      if (cachedData == null || cachedData['MediaContainer'] == null) {
        return [];
      }

      final container = cachedData['MediaContainer'] as Map<String, dynamic>;
      final metadataList = container['Metadata'] as List?;

      if (metadataList == null || metadataList.isEmpty) {
        return [];
      }

      final metadata = metadataList[0] as Map<String, dynamic>;
      final chapters = metadata['Chapter'] as List?;

      if (chapters == null) {
        return [];
      }

      final thumbPaths = <String>[];
      for (final chapter in chapters) {
        final thumbPath = chapter['thumb'] as String?;
        if (thumbPath != null && thumbPath.isNotEmpty) {
          thumbPaths.add(thumbPath);
        }
      }

      return thumbPaths;
    } catch (e) {
      appLogger.w('Error getting chapter thumb paths for $ratingKey', error: e);
      return [];
    }
  }

  /// Check if a chapter thumbnail is used by any other downloaded items
  Future<bool> _isChapterThumbnailInUse(
    String serverId,
    String thumbPath,
    String excludeRatingKey,
  ) async {
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
        final itemChapterPaths = await _getChapterThumbPaths(
          serverId,
          item.ratingKey,
        );

        // Check if this item has the same thumb path
        if (itemChapterPaths.contains(thumbPath)) {
          return true; // Thumbnail is in use
        }
      }

      return false; // Thumbnail is not in use
    } catch (e) {
      appLogger.w(
        'Error checking chapter thumbnail usage: $thumbPath',
        error: e,
      );
      // On error, assume in use to be safe (don't delete)
      return true;
    }
  }

  /// Delete chapter thumbnails for a media item (with reference counting)
  Future<void> _deleteChapterThumbnails(
    String serverId,
    String ratingKey,
  ) async {
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
          final inUse = await _isChapterThumbnailInUse(
            serverId,
            thumbPath,
            ratingKey,
          );

          if (inUse) {
            appLogger.d('Preserving chapter thumbnail (in use): $thumbPath');
            preservedCount++;
            continue;
          }

          // Get artwork file path and delete
          final artworkPath = await _storageService.getArtworkPathFromThumb(
            serverId,
            thumbPath,
          );
          final file = File(artworkPath);

          if (await file.exists()) {
            await file.delete();
            deletedCount++;
            appLogger.d('Deleted chapter thumbnail: $thumbPath');
          }
        } catch (e) {
          appLogger.w(
            'Failed to delete chapter thumbnail: $thumbPath',
            error: e,
          );
          // Continue with other chapters even if one fails
        }
      }

      if (deletedCount > 0 || preservedCount > 0) {
        appLogger.i(
          'Deleted $deletedCount of ${thumbPaths.length} chapter thumbnails ($preservedCount preserved)',
        );
      }
    } catch (e, stack) {
      appLogger.w(
        'Error deleting chapter thumbnails for $ratingKey',
        error: e,
        stackTrace: stack,
      );
      // Don't throw - chapter deletion shouldn't block main deletion
    }
  }

  /// Delete episode files
  Future<void> _deleteEpisodeFiles(
    PlexMetadata episode,
    String serverId,
  ) async {
    try {
      final parentMetadata = episode.grandparentRatingKey != null
          ? await _getMetadataFromCache(serverId, episode.grandparentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      // Delete video file
      final videoPathTemplate = await _storageService.getEpisodeVideoPath(
        episode,
        'tmp',
        showYear: showYear,
      );
      final videoPathWithoutExt = videoPathTemplate.substring(
        0,
        videoPathTemplate.lastIndexOf('.'),
      );
      final actualVideoFile = await _findFileWithAnyExtension(
        videoPathWithoutExt,
      );
      if (actualVideoFile != null && await actualVideoFile.exists()) {
        await actualVideoFile.delete();
        appLogger.i('Deleted episode video: ${actualVideoFile.path}');
      }

      // Delete thumbnail
      final thumbPath = await _storageService.getEpisodeThumbnailPath(
        episode,
        showYear: showYear,
      );
      final thumbFile = File(thumbPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
        appLogger.i('Deleted episode thumbnail: $thumbPath');
      }

      // Delete subtitles directory
      final subsDir = await _storageService.getEpisodeSubtitlesDirectory(
        episode,
        showYear: showYear,
      );
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
          ? await _getMetadataFromCache(serverId, season.parentRatingKey!)
          : null;
      final showYear = parentMetadata?.year;

      // Get all episodes in this season
      final seasonKey = season.ratingKey;
      final episodesInSeason = await (_database.select(
        _database.downloadedMedia,
      )..where((t) => t.parentRatingKey.equals(seasonKey))).get();

      appLogger.d(
        'Deleting ${episodesInSeason.length} episodes in season $seasonKey',
      );
      for (int i = 0; i < episodesInSeason.length; i++) {
        final episode = episodesInSeason[i];
        final episodeGlobalKey = '$serverId:${episode.ratingKey}';

        // Emit progress update
        _emitDeletionProgress(
          DeletionProgress(
            globalKey: '$serverId:$seasonKey',
            itemTitle: season.title,
            currentItem: i + 1,
            totalItems: episodesInSeason.length,
            currentOperation:
                'Deleting episode ${i + 1} of ${episodesInSeason.length}',
          ),
        );

        // Delete chapter thumbnails
        await _deleteChapterThumbnails(serverId, episode.ratingKey);

        // Delete episode files (video, subtitles) if stored outside season directory
        await _deleteByFilePath(episode);

        // Delete episode from API cache
        await _apiCache.deleteForItem(serverId, episode.ratingKey);

        // Delete episode DB entry
        await _database.deleteDownload(episodeGlobalKey);
      }

      final seasonDir = await _storageService.getSeasonDirectory(
        season,
        showYear: showYear,
      );
      if (await seasonDir.exists()) {
        await seasonDir.delete(recursive: true);
        appLogger.i('Deleted season directory: ${seasonDir.path}');
      }

      await _cleanupShowDirectory(season, showYear);
    } catch (e, stack) {
      appLogger.e('Error deleting season files', error: e, stackTrace: stack);
    }
  }

  /// Delete show files
  Future<void> _deleteShowFiles(PlexMetadata show, String serverId) async {
    try {
      // Get all episodes in this show
      final showKey = show.ratingKey;
      final episodesInShow = await (_database.select(
        _database.downloadedMedia,
      )..where((t) => t.grandparentRatingKey.equals(showKey))).get();

      appLogger.d(
        'Deleting ${episodesInShow.length} episodes in show $showKey',
      );
      for (int i = 0; i < episodesInShow.length; i++) {
        final episode = episodesInShow[i];
        final episodeGlobalKey = '$serverId:${episode.ratingKey}';

        // Emit progress update
        _emitDeletionProgress(
          DeletionProgress(
            globalKey: '$serverId:$showKey',
            itemTitle: show.title,
            currentItem: i + 1,
            totalItems: episodesInShow.length,
            currentOperation:
                'Deleting episode ${i + 1} of ${episodesInShow.length}',
          ),
        );

        // Delete chapter thumbnails
        await _deleteChapterThumbnails(serverId, episode.ratingKey);

        // Delete episode files (video, subtitles) if stored outside show directory
        await _deleteByFilePath(episode);

        // Delete episode from API cache
        await _apiCache.deleteForItem(serverId, episode.ratingKey);

        // Delete episode DB entry
        await _database.deleteDownload(episodeGlobalKey);
      }

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
  Future<void> _cleanupEmptyDirectories(
    PlexMetadata episode,
    int? showYear,
  ) async {
    final seasonDir = await _storageService.getSeasonDirectory(
      episode,
      showYear: showYear,
    );

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
  Future<void> _cleanupShowDirectory(
    PlexMetadata metadata,
    int? showYear,
  ) async {
    final showDir = await _storageService.getShowDirectory(
      metadata,
      showYear: showYear,
    );

    if (await showDir.exists()) {
      final contents = await showDir.list().toList();
      final hasSeasons = contents.any(
        (e) => e is Directory && e.path.contains('Season '),
      );

      if (!hasSeasons) {
        if (!await _isShowArtworkInUse(metadata, showYear)) {
          await showDir.delete(recursive: true);
          appLogger.i('Deleted empty show directory: ${showDir.path}');
        }
      }
    }
  }

  /// Check if season artwork is in use
  Future<bool> _isSeasonArtworkInUse(
    PlexMetadata episode,
    int? showYear,
  ) async {
    final seasonKey = episode.parentRatingKey;
    if (seasonKey == null) return false;

    final otherEpisodes = await (_database.select(
      _database.downloadedMedia,
    )..where((t) => t.parentRatingKey.equals(seasonKey))).get();

    // Check if any episodes besides this one
    return otherEpisodes.any(
      (e) => e.globalKey != '${episode.serverId}:${episode.ratingKey}',
    );
  }

  /// Check if show artwork is in use
  Future<bool> _isShowArtworkInUse(PlexMetadata metadata, int? showYear) async {
    final showKey =
        metadata.grandparentRatingKey ??
        metadata.parentRatingKey ??
        metadata.ratingKey;

    final allItems = await _database.select(_database.downloadedMedia).get();

    // Check if any items belong to this show besides this one
    return allItems.any(
      (item) =>
          (item.grandparentRatingKey == showKey ||
              item.parentRatingKey == showKey) &&
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
          .where(
            (e) =>
                e is File && path.basenameWithoutExtension(e.path) == baseName,
          )
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
        final videoPath = await _storageService.toAbsolutePath(
          record.videoFilePath!,
        );
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          await videoFile.delete();
          appLogger.i('Deleted video file: $videoPath');

          // Delete subtitle directory
          final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
          final subsDir = Directory(subsPath);
          if (await subsDir.exists()) {
            await subsDir.delete(recursive: true);
            appLogger.i('Deleted subtitles: $subsPath');
          }
        }
      }

      if (record.thumbPath != null) {
        final thumbPath = await _storageService.toAbsolutePath(
          record.thumbPath!,
        );
        final thumbFile = File(thumbPath);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
          appLogger.i('Deleted thumbnail: $thumbPath');
        }
      }
    } catch (e, stack) {
      appLogger.e('Error in fallback deletion', error: e, stackTrace: stack);
    }
  }

  /// Get all downloads with a specific status
  Stream<List<DownloadedMediaItem>> watchDownloadsByStatus(
    DownloadStatus status,
  ) {
    return (_database.select(
      _database.downloadedMedia,
    )..where((t) => t.status.equals(status.index))).watch();
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
    await _cacheMetadataForOffline(
      metadata.serverId!,
      metadata.ratingKey,
      metadata,
    );
  }

  /// Cache metadata in the API response format for offline access
  /// This simulates what PlexClient would receive from the server
  Future<void> _cacheMetadataForOffline(
    String serverId,
    String ratingKey,
    PlexMetadata metadata,
  ) async {
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
  Future<void> cacheChildrenForOffline(
    String serverId,
    String parentRatingKey,
    List<PlexMetadata> children,
  ) async {
    final endpoint = '/library/metadata/$parentRatingKey/children';

    // Build a response structure that matches the Plex API format
    final cachedResponse = {
      'MediaContainer': {'Metadata': children.map((c) => c.toJson()).toList()},
    };

    await _apiCache.put(serverId, endpoint, cachedResponse);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    for (final token in _activeDownloads.values) {
      token.cancel('Service disposed');
    }
    _progressController.close();
    _deletionProgressController.close();
  }
}
