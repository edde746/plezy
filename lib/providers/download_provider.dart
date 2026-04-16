import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:plezy/utils/content_utils.dart';
import '../models/download_models.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../utils/download_version_utils.dart';
import '../services/download_manager_service.dart';
// PlexSyncer
import '../services/manifest_import_service.dart';
import '../services/download_storage_service.dart';
import '../services/storage_service.dart';
import '../services/plex_api_cache.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';

/// Filter mode for batch downloads (shows/seasons).
/// Use [all] to download everything, or [unwatched] with an optional maxCount.
enum DownloadFilter { all, unwatched }

/// Holds Plex thumb path reference for downloaded artwork.
/// The actual file path is computed from the hash of serverId + thumb path.
class DownloadedArtwork {
  /// The Plex thumb path (e.g., /library/metadata/12345/thumb/1234567890)
  final String? thumbPath;

  const DownloadedArtwork({this.thumbPath});

  /// Get the local file path for this artwork
  String? getLocalPath(DownloadStorageService storage, String serverId) {
    if (thumbPath == null) return null;
    return storage.getArtworkPathSync(serverId, thumbPath!);
  }
}

/// Provider for managing download state and operations.
class DownloadProvider extends ChangeNotifier {
  final DownloadManagerService _downloadManager;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  StreamSubscription<DeletionProgress>? _deletionProgressSubscription;
  late final Future<void> _initFuture;

  // Track download progress by globalKey (serverId:ratingKey)
  final Map<String, DownloadProgress> _downloads = {};

  // Store metadata for display
  final Map<String, PlexMetadata> _metadata = {};

  // Store Plex thumb paths for offline display (actual file path computed from hash)
  final Map<String, DownloadedArtwork> _artworkPaths = {};

  // Track items currently being queued (building download queue)
  final Set<String> _queueing = {};

  // Track items currently being deleted with progress
  final Map<String, DeletionProgress> _deletionProgress = {};

  // Track total episode counts for shows/seasons (for partial download detection)
  // Key: globalKey (serverId:ratingKey), Value: total episode count
  final Map<String, int> _totalEpisodeCounts = {};

  DownloadProvider({required DownloadManagerService downloadManager}) : _downloadManager = downloadManager {
    // Listen to progress updates from the download manager
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);

    // Listen to deletion progress updates
    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);

    // Load persisted downloads from database
    _initFuture = _loadPersistedDownloads();
  }

  /// Ensures persisted downloads have been loaded from disk.
  Future<void> ensureInitialized() => _initFuture;

  /// Load all persisted downloads and metadata from the database/cache
  Future<void> _loadPersistedDownloads() async {
    try {
      // Wait for recovery to finish before loading state so that
      // interrupted "downloading" rows have been transitioned to "queued"
      await _downloadManager.recoveryFuture;

      // Clear existing data to prevent stale entries after deletions
      _downloads.clear();
      _artworkPaths.clear();
      _metadata.clear();
      _totalEpisodeCounts.clear();

      final storageService = DownloadStorageService.instance;
      final apiCache = PlexApiCache.instance;

      // Initialize artwork directory path for synchronous access
      await storageService.getArtworkDirectory();

      // Load all downloads from database
      final downloads = await _downloadManager.getAllDownloads();

      // Bulk-load all pinned metadata in a single query instead of per-item DB calls
      final allMetadata = await apiCache.getAllPinnedMetadata();

      for (final item in downloads) {
        _downloads[item.globalKey] = DownloadProgress(
          globalKey: item.globalKey,
          status: DownloadStatus.values[item.status],
          progress: item.progress,
          downloadedBytes: item.downloadedBytes,
          totalBytes: item.totalBytes ?? 0,
        );

        // Store Plex thumb path reference (file path computed from hash when needed)
        _artworkPaths[item.globalKey] = DownloadedArtwork(thumbPath: item.thumbPath);

        // Look up metadata from the bulk-loaded map (O(1) instead of DB query per item)
        // Falls back to individual query for any unpinned entries (e.g., legacy data)
        final metadata = allMetadata[item.globalKey] ?? await apiCache.getMetadata(item.serverId, item.ratingKey);
        if (metadata != null) {
          _metadata[item.globalKey] = metadata;

          // For episodes, also load parent (show and season) metadata from the same map
          if (metadata.isEpisode) {
            _loadParentMetadataFromMap(metadata, allMetadata);
          }
        }
      }

      // Load total episode counts from StorageService
      await _loadTotalEpisodeCounts();

      appLogger.i(
        'Loaded ${_downloads.length} downloads, ${_metadata.length} metadata entries, '
        'and ${_totalEpisodeCounts.length} episode counts',
      );
      notifyListeners();
    } catch (e) {
      appLogger.e('Failed to load persisted downloads', error: e);
    }
  }

  /// Load total episode counts from StorageService
  Future<void> _loadTotalEpisodeCounts() async {
    try {
      final storage = await StorageService.getInstance();
      final counts = storage.loadAllEpisodeCounts();
      _totalEpisodeCounts.addAll(counts);

      appLogger.i('Loaded ${_totalEpisodeCounts.length} episode counts from StorageService');
    } catch (e) {
      appLogger.w('Failed to load episode counts', error: e);
    }
  }

  /// Persist total episode count to StorageService
  Future<void> _persistTotalEpisodeCount(String globalKey, int count) async {
    try {
      final storage = await StorageService.getInstance();
      await storage.saveTotalEpisodeCount(globalKey, count);
      appLogger.d('Persisted episode count for $globalKey: $count');
    } catch (e) {
      appLogger.w('Failed to persist episode count for $globalKey', error: e);
    }
  }

  /// Load parent (show and season) metadata from a pre-loaded map (no DB I/O).
  /// Used during bulk initialization to avoid per-item DB queries.
  void _loadParentMetadataFromMap(PlexMetadata episode, Map<String, PlexMetadata> allMetadata) {
    final serverId = episode.serverId;
    if (serverId == null) return;

    // Load show metadata
    final showRatingKey = episode.grandparentRatingKey;
    if (showRatingKey != null) {
      final showGlobalKey = buildGlobalKey(serverId, showRatingKey);
      if (!_metadata.containsKey(showGlobalKey)) {
        final showMetadata = allMetadata[showGlobalKey];
        if (showMetadata != null) {
          _metadata[showGlobalKey] = showMetadata;
          if (showMetadata.thumb != null) {
            _artworkPaths[showGlobalKey] = DownloadedArtwork(thumbPath: showMetadata.thumb);
          }
        }
      }
    }

    // Load season metadata
    final seasonRatingKey = episode.parentRatingKey;
    if (seasonRatingKey != null) {
      final seasonGlobalKey = buildGlobalKey(serverId, seasonRatingKey);
      if (!_metadata.containsKey(seasonGlobalKey)) {
        final seasonMetadata = allMetadata[seasonGlobalKey];
        if (seasonMetadata != null) {
          _metadata[seasonGlobalKey] = seasonMetadata;
          if (seasonMetadata.thumb != null) {
            _artworkPaths[seasonGlobalKey] = DownloadedArtwork(thumbPath: seasonMetadata.thumb);
          }
        }
      }
    }
  }

  void _onProgressUpdate(DownloadProgress progress) {
    appLogger.d('Progress update received: ${progress.globalKey} - ${progress.status} - ${progress.progress}%');

    _downloads[progress.globalKey] = progress;

    // Sync artwork paths when they are available
    if (progress.hasArtworkPaths) {
      _artworkPaths[progress.globalKey] = DownloadedArtwork(thumbPath: progress.thumbPath);
    }

    appLogger.d('Notifying listeners for ${progress.globalKey}');
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _deletionProgressSubscription?.cancel();
    super.dispose();
  }

  /// Ensure metadata has a serverId, falling back to a parent's serverId.
  PlexMetadata _ensureServerId(PlexMetadata metadata, String? fallbackServerId) =>
      metadata.serverId != null ? metadata : metadata.copyWith(serverId: fallbackServerId);

  /// All current download progress entries
  Map<String, DownloadProgress> get downloads => Map.unmodifiable(_downloads);

  /// All metadata for downloads
  Map<String, PlexMetadata> get metadata => Map.unmodifiable(_metadata);

  /// Get all queued/downloading items (for Queue tab)
  List<DownloadProgress> get queuedDownloads {
    return _downloads.values
        .where(
          (p) =>
              p.status == DownloadStatus.queued ||
              p.status == DownloadStatus.downloading ||
              p.status == DownloadStatus.paused,
        )
        .toList();
  }

  /// Get all completed downloads
  List<DownloadProgress> get completedDownloads {
    return _downloads.values.where((p) => p.status == DownloadStatus.completed).toList();
  }

  /// Get completed TV episode downloads (individual episodes)
  List<PlexMetadata> get downloadedEpisodes {
    return _metadata.entries
        .where((entry) {
          final progress = _downloads[entry.key];
          return progress?.status == DownloadStatus.completed && entry.value.type == 'episode';
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Get unique TV shows that have downloaded episodes
  /// Returns stored show metadata, or synthesizes from episode metadata as fallback
  List<PlexMetadata> get downloadedShows {
    final Map<String, PlexMetadata> shows = {};

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      final meta = entry.value;
      final progress = _downloads[globalKey];

      if (progress?.status == DownloadStatus.completed && meta.type == 'episode') {
        final showRatingKey = meta.grandparentRatingKey;
        if (showRatingKey != null && !shows.containsKey(showRatingKey)) {
          // Try to get stored show metadata first
          final showGlobalKey = buildGlobalKey(meta.serverId!, showRatingKey);
          final storedShow = _metadata[showGlobalKey];

          if (storedShow != null && storedShow.type == 'show') {
            // Use stored show metadata (has year, summary, clearLogo)
            shows[showRatingKey] = storedShow;
          } else {
            // Fallback: synthesize from episode metadata (missing year, summary)
            shows[showRatingKey] = PlexMetadata(
              ratingKey: showRatingKey,
              key: '/library/metadata/$showRatingKey',
              type: 'show',
              title: meta.grandparentTitle ?? 'Unknown Show',
              thumb: meta.grandparentThumb,
              art: meta.grandparentArt,
              serverId: meta.serverId,
            );
          }
        }
      }
    }

    return shows.values.toList();
  }

  /// Get completed movie downloads
  List<PlexMetadata> get downloadedMovies {
    return _metadata.entries
        .where((entry) {
          final progress = _downloads[entry.key];
          return progress?.status == DownloadStatus.completed && entry.value.type == 'movie';
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Get metadata for a specific download
  PlexMetadata? getMetadata(String globalKey) => _metadata[globalKey];

  /// Get artwork paths for a specific download (for offline display)
  DownloadedArtwork? getArtworkPaths(String globalKey) => _artworkPaths[globalKey];

  /// Get local file path for any artwork type (thumb, art, clearLogo, etc.)
  /// Returns null if artwork directory isn't initialized or artworkPath is null
  String? getArtworkLocalPath(String serverId, String? artworkPath) {
    if (artworkPath == null) return null;
    return DownloadStorageService.instance.getArtworkPathSync(serverId, artworkPath);
  }

  /// Get downloaded episodes for a specific show (by grandparentRatingKey)
  List<PlexMetadata> getDownloadedEpisodesForShow(String showRatingKey) {
    return _metadata.entries
        .where((entry) {
          final progress = _downloads[entry.key];
          final meta = entry.value;
          return progress?.status == DownloadStatus.completed &&
              meta.type == 'episode' &&
              meta.grandparentRatingKey == showRatingKey;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Get episode downloads filtered by show and/or season ratingKey.
  List<DownloadProgress> _getEpisodeDownloads({
    String? showRatingKey,
    String? seasonRatingKey,
  }) {
    return _downloads.entries
        .where((entry) {
          final meta = _metadata[entry.key];
          if (meta?.type != 'episode') return false;
          if (showRatingKey != null && meta?.grandparentRatingKey != showRatingKey) return false;
          if (seasonRatingKey != null && meta?.parentRatingKey != seasonRatingKey) return false;
          return true;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Calculate aggregate progress for a show (based on all its episodes)
  /// Returns synthetic DownloadProgress with aggregated values
  DownloadProgress? getAggregateProgressForShow(String serverId, String showRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: showRatingKey,
      episodes: _getEpisodeDownloads(showRatingKey: showRatingKey),
      entityType: 'show',
    );
  }

  /// Calculate aggregate progress for a season (based on all its episodes)
  /// Returns synthetic DownloadProgress with aggregated values
  DownloadProgress? getAggregateProgressForSeason(String serverId, String seasonRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: seasonRatingKey,
      episodes: _getEpisodeDownloads(seasonRatingKey: seasonRatingKey),
      entityType: 'season',
    );
  }

  /// Shared helper to calculate aggregate download progress for shows/seasons
  DownloadProgress? _calculateAggregateProgress({
    required String serverId,
    required String ratingKey,
    required List<DownloadProgress> episodes,
    required String entityType,
  }) {
    final globalKey = buildGlobalKey(serverId, ratingKey);

    // DIAGNOSTIC: Check all sources of episode count
    final meta = _metadata[globalKey];
    final metadataLeafCount = meta?.leafCount;
    final storedCount = _totalEpisodeCounts[globalKey];
    final downloadedCount = episodes.length;

    appLogger.d(
      '📊 Episode count sources for $entityType $ratingKey:\n'
      '  - Metadata leafCount: $metadataLeafCount\n'
      '  - Stored count: $storedCount\n'
      '  - Downloaded episodes: $downloadedCount\n'
      '  - Metadata exists: ${meta != null}\n'
      '  - Type: ${meta?.type}\n'
      '  - Title: ${meta?.title}',
    );

    // Get total episode count - Use metadata.leafCount as primary source
    int totalEpisodes;
    String countSource;

    if (metadataLeafCount != null && metadataLeafCount > 0) {
      totalEpisodes = metadataLeafCount;
      countSource = 'metadata.leafCount';
    } else if (storedCount != null && storedCount > 0) {
      totalEpisodes = storedCount;
      countSource = 'stored count (StorageService)';
    } else {
      totalEpisodes = downloadedCount;
      countSource = 'downloaded episodes (fallback)';
    }

    appLogger.d('✅ Using totalEpisodes=$totalEpisodes from [$countSource] for $entityType $ratingKey');

    // If we have stored count but no downloads, check if it's a valid partial state
    if (totalEpisodes == 0 || (episodes.isEmpty && totalEpisodes > 0)) {
      appLogger.d('⚠️  No valid downloads for $entityType $ratingKey, returning null');
      return null;
    }

    // Calculate aggregate statistics
    int completedCount = 0;
    int downloadingCount = 0;
    int queuedCount = 0;
    int failedCount = 0;

    for (final ep in episodes) {
      switch (ep.status) {
        case DownloadStatus.completed:
          completedCount++;
        case DownloadStatus.downloading:
          downloadingCount++;
        case DownloadStatus.queued:
          queuedCount++;
        case DownloadStatus.failed:
          failedCount++;
        default:
          break;
      }
    }

    // Determine overall status
    final DownloadStatus overallStatus;
    if (completedCount == totalEpisodes) {
      overallStatus = DownloadStatus.completed;
    } else if (completedCount > 0 && downloadingCount == 0 && queuedCount == 0 && completedCount < totalEpisodes) {
      overallStatus = DownloadStatus.partial;
    } else if (downloadingCount > 0) {
      overallStatus = DownloadStatus.downloading;
    } else if (queuedCount > 0) {
      overallStatus = DownloadStatus.queued;
    } else if (failedCount > 0) {
      overallStatus = DownloadStatus.failed;
    } else {
      return null;
    }

    // Calculate overall progress percentage based on TOTAL episodes
    final int overallProgress = totalEpisodes > 0 ? ((completedCount * 100) / totalEpisodes).round() : 0;

    appLogger.d(
      'Aggregate progress for $entityType $ratingKey: $overallProgress% '
      '($completedCount completed, $downloadingCount downloading, '
      '$queuedCount queued of $totalEpisodes total) - Status: $overallStatus',
    );

    return DownloadProgress(
      globalKey: globalKey,
      status: overallStatus,
      progress: overallProgress,
      downloadedBytes: 0,
      totalBytes: 0,
      currentFile: '$completedCount/$totalEpisodes episodes',
    );
  }

  /// Whether there are any downloads (active or completed)
  bool get hasDownloads => _downloads.isNotEmpty;

  /// Whether there are any active downloads
  bool get hasActiveDownloads =>
      _downloads.values.any((p) => p.status == DownloadStatus.downloading || p.status == DownloadStatus.queued);

  /// Get download progress for a specific item
  /// For shows/seasons, returns aggregate progress of all child episodes
  /// For episodes/movies, returns direct progress
  DownloadProgress? getProgress(String globalKey) {
    // First check if we have direct progress (for episodes/movies)
    final directProgress = _downloads[globalKey];
    if (directProgress != null) {
      return directProgress;
    }

    // If no direct progress, check if this is a show or season
    // and calculate aggregate progress from episodes
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;

    final serverId = parsed.serverId;
    final ratingKey = parsed.ratingKey;

    // Try to get metadata to determine type
    final meta = _metadata[globalKey];
    if (meta == null) {
      // No metadata stored yet, might be a show/season being queued
      // Check if any episodes exist for this as a parent
      final episodesAsShow = _getEpisodeDownloads(showRatingKey: ratingKey);
      if (episodesAsShow.isNotEmpty) {
        return getAggregateProgressForShow(serverId, ratingKey);
      }

      final episodesAsSeason = _getEpisodeDownloads(seasonRatingKey: ratingKey);
      if (episodesAsSeason.isNotEmpty) {
        return getAggregateProgressForSeason(serverId, ratingKey);
      }

      return null;
    }

    // We have metadata, check type
    final mt = meta.mediaType;
    if (mt == PlexMediaType.show) {
      return getAggregateProgressForShow(serverId, ratingKey);
    } else if (mt == PlexMediaType.season) {
      return getAggregateProgressForSeason(serverId, ratingKey);
    }

    return null;
  }

  /// Check if an item is downloaded
  /// For shows/seasons, checks if all episodes are downloaded
  bool isDownloaded(String globalKey) {
    final progress = getProgress(globalKey);
    return progress?.status == DownloadStatus.completed;
  }

  /// Check if an item is currently downloading
  /// For shows/seasons, checks if any episodes are downloading
  bool isDownloading(String globalKey) {
    final progress = getProgress(globalKey);
    return progress?.status == DownloadStatus.downloading;
  }

  /// Check if an item is in the queue
  /// For shows/seasons, checks if any episodes are queued
  bool isQueued(String globalKey) {
    final progress = getProgress(globalKey);
    return progress?.status == DownloadStatus.queued;
  }

  /// Check if an item is currently being queued (building download queue)
  bool isQueueing(String globalKey) => _queueing.contains(globalKey);

  /// Get the local video file path for a downloaded item
  /// Returns null if not downloaded or file doesn't exist
  Future<String?> getVideoFilePath(String globalKey) async {
    appLogger.d('getVideoFilePath called with globalKey: $globalKey');

    final downloadedItem = await _downloadManager.getDownloadedMedia(globalKey);
    if (downloadedItem == null) {
      appLogger.w('No downloaded item found for globalKey: $globalKey');
      return null;
    }
    if (downloadedItem.status != DownloadStatus.completed.index) {
      appLogger.w('Download not complete. Status: ${downloadedItem.status}');
      return null;
    }
    if (downloadedItem.videoFilePath == null) {
      appLogger.w('Video file path is null for globalKey: $globalKey');
      return null;
    }

    final storedPath = downloadedItem.videoFilePath!;
    final storageService = DownloadStorageService.instance;

    // SAF URIs (content://) are already valid - don't transform them
    if (storageService.isSafUri(storedPath)) {
      appLogger.d('Found SAF video path: $storedPath');
      return storedPath;
    }

    // Convert stored path (may be relative) to absolute path
    final absolutePath = await storageService.ensureAbsolutePath(storedPath);

    // Verify file exists
    final file = File(absolutePath);
    if (!await file.exists()) {
      appLogger.w('Offline video file not found: $absolutePath');
      return null;
    }
    return absolutePath;
  }

  /// Queue a download for a media item.
  /// For movies and episodes, queues directly.
  /// For shows and seasons, fetches all child episodes and queues them.
  /// Returns the number of items queued.
  Future<int> queueDownload(
    PlexMetadata metadata,
    PlexClient client, {
    DownloadVersionConfig? versionConfig,
    DownloadFilter filter = DownloadFilter.all,
    int? maxCount,
  }) async {
    final globalKey = metadata.globalKey;
    final config = versionConfig ?? DownloadVersionConfig();

    // Check if downloads are blocked on cellular
    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      throw CellularDownloadBlockedException();
    }

    try {
      // Mark as queueing to show loading state in UI
      _queueing.add(globalKey);
      notifyListeners();

      final mt = metadata.mediaType;

      if (mt == PlexMediaType.movie || mt == PlexMediaType.episode) {
        final queued = await _queueSingleDownload(metadata, client, mediaIndex: config.mediaIndex);
        return queued ? 1 : 0;
      } else if (mt == PlexMediaType.show) {
        _metadata[globalKey] = metadata;
        return await _queueShowDownload(metadata, client, versionConfig: config, filter: filter, maxCount: maxCount);
      } else if (mt == PlexMediaType.season) {
        _metadata[globalKey] = metadata;
        return await _queueSeasonDownload(metadata, client, versionConfig: config, filter: filter, maxCount: maxCount);
      } else {
        throw Exception('Cannot download ${metadata.type}');
      }
    } finally {
      _queueing.remove(globalKey);
      notifyListeners();
    }
  }

  /// Queue all video items from a playlist for download.
  /// Returns the number of items queued.
  Future<int> queuePlaylistDownload(
    List<PlexMetadata> items,
    PlexClient client, {
    DownloadFilter filter = DownloadFilter.all,
  }) async {
    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      throw CellularDownloadBlockedException();
    }

    int count = 0;
    for (final item in items) {
      final mt = item.mediaType;
      if (mt != PlexMediaType.movie && mt != PlexMediaType.episode) continue;
      if (filter == DownloadFilter.unwatched && item.isWatched && !item.hasActiveProgress) continue;

      final queued = await _queueSingleDownload(item, client);
      if (queued) count++;
    }
    return count;
  }

  /// Queue a single movie or episode for download.
  /// Returns true if the item was actually queued, false if skipped.
  Future<bool> _queueSingleDownload(
    PlexMetadata metadata,
    PlexClient client, {
    int mediaIndex = 0,
    DownloadVersionConfig? versionConfig,
  }) async {
    final globalKey = metadata.globalKey;

    // Don't re-queue if already downloading or completed
    if (_downloads.containsKey(globalKey)) {
      final existing = _downloads[globalKey]!;
      if (existing.status == DownloadStatus.downloading || existing.status == DownloadStatus.completed) {
        return false;
      }
    }

    // Always fetch full metadata before downloading.
    // Hub items may have summary but the cache at /library/metadata/$ratingKey
    // won't have the full API response (with Media/Part data needed for video URL)
    // unless getMetadataWithImages has been called.
    PlexMetadata metadataToStore = metadata;
    try {
      final fullMetadata = await client.getMetadataWithImages(metadata.ratingKey);
      if (fullMetadata != null) {
        metadataToStore = fullMetadata.copyWith(serverId: metadata.serverId, serverName: metadata.serverName);
      }
    } catch (e) {
      appLogger.w('Failed to fetch full metadata for ${metadata.ratingKey}, using partial', error: e);
    }

    // Smart version matching for series/season downloads
    var resolvedIndex = mediaIndex;
    if (versionConfig != null && versionConfig.acceptedSignatures.isNotEmpty) {
      final versions = metadataToStore.mediaVersions;
      if (versions != null && versions.isNotEmpty) {
        final matchedIndex = PlexMediaVersion.findMatchingIndex(versions, versionConfig.acceptedSignatures);
        if (matchedIndex != null) {
          resolvedIndex = matchedIndex;
        } else if (versionConfig.onVersionMismatch != null) {
          final pickedIndex = await versionConfig.onVersionMismatch!(metadataToStore, versions);
          if (pickedIndex == null) return false;
          resolvedIndex = pickedIndex;
          versionConfig.acceptedSignatures.add(versions[pickedIndex].signature);
        }
      }
    }

    // For episodes, also fetch and store show and season metadata for offline display
    if (metadataToStore.type == 'episode') {
      await _fetchAndStoreParentMetadata(metadataToStore, client);
    }

    // Store full metadata for display
    _metadata[globalKey] = metadataToStore;

    // Update local state immediately for UI feedback
    _downloads[globalKey] = DownloadProgress(globalKey: globalKey, status: DownloadStatus.queued);
    notifyListeners();

    // Actually trigger download via DownloadManagerService
    await _downloadManager.queueDownload(metadata: metadataToStore, client: client, mediaIndex: resolvedIndex);
    return true;
  }

  /// Fetch and store show and season metadata for an episode
  /// Also downloads artwork for show and season
  Future<void> _fetchAndStoreParentMetadata(PlexMetadata episode, PlexClient client) async {
    final serverId = episode.serverId;
    if (serverId == null) return;

    await _fetchAndStoreRelatedMetadata(serverId: serverId, ratingKey: episode.grandparentRatingKey, client: client);
    await _fetchAndStoreRelatedMetadata(serverId: serverId, ratingKey: episode.parentRatingKey, client: client);
  }

  /// Fetch, persist, and download artwork for a related metadata item (show or season).
  Future<void> _fetchAndStoreRelatedMetadata({
    required String serverId,
    required String? ratingKey,
    required PlexClient client,
  }) async {
    if (ratingKey == null) return;
    final globalKey = buildGlobalKey(serverId, ratingKey);
    final storageService = DownloadStorageService.instance;

    PlexMetadata? metadata = _metadata[globalKey];
    if (metadata == null) {
      try {
        metadata = await client.getMetadataWithImages(ratingKey);
      } catch (e) {
        appLogger.w('Failed to fetch metadata for $ratingKey', error: e);
      }
    }
    if (metadata == null) return;

    final withServer = metadata.copyWith(serverId: serverId);
    _metadata[globalKey] = withServer;
    await _downloadManager.saveMetadata(withServer);

    final thumbPath = withServer.thumb;
    final hasPoster = thumbPath != null && await storageService.artworkExists(serverId, thumbPath);
    if (!hasPoster) {
      await _downloadManager.downloadArtworkForMetadata(withServer, client);
    }
    _artworkPaths[globalKey] = DownloadedArtwork(thumbPath: thumbPath);
  }

  /// Store leafCount for a show or season so aggregate progress works.
  Future<void> _storeLeafCount(String globalKey, PlexMetadata metadata) async {
    if (metadata.leafCount != null && metadata.leafCount! > 0) {
      _totalEpisodeCounts[globalKey] = metadata.leafCount!;
      await _persistTotalEpisodeCount(globalKey, metadata.leafCount!);
    }
  }

  /// Queue all episodes from a TV show for download
  Future<int> _queueShowDownload(PlexMetadata show, PlexClient client,
      {DownloadVersionConfig? versionConfig, DownloadFilter filter = DownloadFilter.all, int? maxCount}) async {
    int count = 0;
    final seasons = await client.getChildren(show.ratingKey);

    await _storeLeafCount(show.globalKey, show);

    int? remaining = maxCount;
    for (final season in seasons) {
      if (season.type == 'season') {
        if (remaining != null && remaining <= 0) break;
        final seasonWithServer = _ensureServerId(season, show.serverId);
        final queued = await _queueSeasonDownload(seasonWithServer, client,
            versionConfig: versionConfig, filter: filter, maxCount: remaining);
        count += queued;
        if (remaining != null) remaining -= queued;
      }
    }

    return count;
  }

  /// Queue all episodes from a season for download
  Future<int> _queueSeasonDownload(PlexMetadata season, PlexClient client,
      {DownloadVersionConfig? versionConfig, DownloadFilter filter = DownloadFilter.all, int? maxCount}) async {
    int count = 0;
    final episodes = await client.getChildren(season.ratingKey);

    await _storeLeafCount(season.globalKey, season);

    for (final episode in episodes) {
      if (episode.type == 'episode') {
        if (filter == DownloadFilter.unwatched && episode.isWatched && !episode.hasActiveProgress) continue;
        if (maxCount != null && count >= maxCount) break;

        final episodeWithServer = _ensureServerId(episode, season.serverId);
        final queued = await _queueSingleDownload(episodeWithServer, client, versionConfig: versionConfig);
        if (queued) count++;
      }
    }

    return count;
  }

  /// Queue only the missing (not downloaded) episodes for a show/season
  /// Used for resuming partial downloads
  /// Returns the number of episodes queued
  Future<int> queueMissingEpisodes(
    PlexMetadata metadata,
    PlexClient client, {
    DownloadVersionConfig? versionConfig,
  }) async {
    final mt = metadata.mediaType;

    if (mt == PlexMediaType.show) {
      return await _queueMissingShowEpisodes(metadata, client, versionConfig: versionConfig);
    } else if (mt == PlexMediaType.season) {
      return await _queueMissingSeasonEpisodes(metadata, client, versionConfig: versionConfig);
    } else {
      throw Exception('queueMissingEpisodes only supports shows/seasons');
    }
  }

  /// Queue missing episodes for a show
  Future<int> _queueMissingShowEpisodes(PlexMetadata show, PlexClient client,
      {DownloadVersionConfig? versionConfig}) async {
    int queuedCount = 0;

    final seasons = await client.getChildren(show.ratingKey);

    for (final season in seasons) {
      if (season.type == 'season') {
        final seasonWithServer = _ensureServerId(season, show.serverId);
        queuedCount += await _queueMissingSeasonEpisodes(seasonWithServer, client, versionConfig: versionConfig);
      }
    }

    appLogger.i('Queued $queuedCount missing episodes for show ${show.title}');
    return queuedCount;
  }

  /// Queue missing episodes for a season
  Future<int> _queueMissingSeasonEpisodes(PlexMetadata season, PlexClient client,
      {DownloadVersionConfig? versionConfig}) async {
    int queuedCount = 0;

    final episodes = await client.getChildren(season.ratingKey);

    for (final episode in episodes) {
      if (episode.type == 'episode') {
        final episodeWithServer = _ensureServerId(episode, season.serverId);

        final episodeGlobalKey = episodeWithServer.globalKey;

        // Only queue if NOT already downloaded or in progress
        final progress = _downloads[episodeGlobalKey];
        if (progress == null ||
            (progress.status != DownloadStatus.completed &&
                progress.status != DownloadStatus.downloading &&
                progress.status != DownloadStatus.queued)) {
          final queued = await _queueSingleDownload(episodeWithServer, client, versionConfig: versionConfig);
          if (queued) {
            queuedCount++;
            appLogger.d('Queued missing episode: ${episode.title} ($episodeGlobalKey)');
          }
        }
      }
    }

    return queuedCount;
  }

  /// Pause a download (works for both downloading and queued items)
  Future<void> pauseDownload(String globalKey) async {
    final progress = _downloads[globalKey];
    if (progress != null &&
        (progress.status == DownloadStatus.downloading || progress.status == DownloadStatus.queued)) {
      await _downloadManager.pauseDownload(globalKey);
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, PlexClient client) async {
    final progress = _downloads[globalKey];
    if (progress != null && progress.status == DownloadStatus.paused) {
      await _downloadManager.resumeDownload(globalKey, client);
    }
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, PlexClient client) async {
    final progress = _downloads[globalKey];
    if (progress != null && progress.status == DownloadStatus.failed) {
      await _downloadManager.retryDownload(globalKey, client);
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    final progress = _downloads[globalKey];
    if (progress != null) {
      await _downloadManager.cancelDownload(globalKey);
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      notifyListeners();
    }
  }

  /// Delete a downloaded item
  Future<void> deleteDownload(String globalKey) async {
    try {
      // Check if this is a show/season and clean up episode count
      final meta = _metadata[globalKey];
      if (meta?.type == 'show' || meta?.type == 'season') {
        final removedCount = _totalEpisodeCounts.remove(globalKey);
        final storage = await StorageService.getInstance();
        await storage.removeEpisodeCount(globalKey);
        appLogger.i(
          'Removed episode count for $globalKey\n'
          '  - Removed count value: $removedCount\n'
          '  - Metadata type: ${meta?.type}\n'
          '  - Metadata title: ${meta?.title}\n'
          '  - Remaining stored counts: ${_totalEpisodeCounts.length}',
        );
      }

      // Start deletion (progress will be tracked via stream)
      await _downloadManager.deleteDownload(globalKey);

      // Remove from local state
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      _artworkPaths.remove(globalKey);

      notifyListeners();
    } catch (e) {
      // Remove from deletion tracking on error
      _deletionProgress.remove(globalKey);
      notifyListeners();
      rethrow;
    }
  }

  /// Handle deletion progress updates
  void _onDeletionProgressUpdate(DeletionProgress progress) {
    if (progress.isComplete) {
      // Deletion complete - remove from tracking
      _deletionProgress.remove(progress.globalKey);
    } else {
      // Update progress
      _deletionProgress[progress.globalKey] = progress;
    }
    notifyListeners();
  }

  /// Check if an item is being deleted
  bool isDeleting(String globalKey) => _deletionProgress.containsKey(globalKey);

  /// Get deletion progress for an item
  DeletionProgress? getDeletionProgress(String globalKey) => _deletionProgress[globalKey];

  /// Get all items currently being deleted
  UnmodifiableMapView<String, DeletionProgress> get deletionProgress => UnmodifiableMapView(_deletionProgress);

  // ─────────────────────────────────────────────────────────────────────────
  // PlexSyncer: import externally-synced files from a manifest.json
  // ─────────────────────────────────────────────────────────────────────────

  /// Read the PlexSyncer manifest from the SAF folder, then register every
  /// resolved item as a completed download.
  ///
  /// Returns a brief summary string describing what happened, suitable for
  /// display in a [SnackBar] or dialog.
  Future<ImportSummary> importFromManifest({PlexClient? Function(String serverId)? clientResolver}) async {
    // 1. Read + resolve the manifest (SAF/JSON only — no DB access here).
    final readResult = await ManifestImportService.instance.readManifest();

    if (readResult.hasError) {
      return ImportSummary(error: readResult.error);
    }

    final serverId   = readResult.serverId;
    final serverName = readResult.serverName;
    int imported = 0;
    int skipped  = 0;
    // Track shows we've already fetched artwork for to avoid redundant requests.
    final fetchedShowKeys = <String>{};

    for (final item in readResult.resolved) {
      final globalKey = buildGlobalKey(serverId, item.ratingKey);

      // Skip items already in the database.
      final existing = await _downloadManager.getDownloadedMedia(globalKey);
      if (existing != null) {
        skipped++;
        continue;
      }

      // Build a PlexMetadata from the resolved item.
      final metadata = PlexMetadata(
        ratingKey:            item.ratingKey,
        key:                  '/library/metadata/${item.ratingKey}',
        type:                 item.type,
        title:                item.title,
        summary:              item.summary,
        thumb:                item.thumb,
        art:                  item.art,
        duration:             item.duration,
        year:                 item.type == 'movie' ? item.year : null,
        grandparentTitle:     item.grandparentTitle,
        grandparentThumb:     item.grandparentThumb,
        grandparentRatingKey: item.grandparentRatingKey,
        parentTitle:          item.parentTitle,
        parentRatingKey:      item.parentRatingKey,
        parentIndex:          item.seasonNumber,
        index:                item.episodeNumber,
        serverId:             serverId,
        serverName:           serverName,
      );

      // For episodes, ensure a show stub and season stub exist in cache.
      if (item.type == 'episode') {
        // Show stub
        if (item.grandparentRatingKey != null &&
            item.grandparentRatingKey!.isNotEmpty) {
          await _downloadManager.registerSyncedParentStub(PlexMetadata(
            ratingKey:  item.grandparentRatingKey!,
            key:        '/library/metadata/${item.grandparentRatingKey}',
            type:       'show',
            title:      item.grandparentTitle,
            thumb:      item.grandparentThumb,
            art:        item.grandparentArt,
            year:       item.grandparentYear,
            serverId:   serverId,
            serverName: serverName,
          ));
        }
        // Season stub
        if (item.parentRatingKey != null && item.parentRatingKey!.isNotEmpty) {
          await _downloadManager.registerSyncedParentStub(PlexMetadata(
            ratingKey:            item.parentRatingKey!,
            key:                  '/library/metadata/${item.parentRatingKey}',
            type:                 'season',
            title:                item.parentTitle,
            thumb:                item.parentThumb ?? item.grandparentThumb,
            parentIndex:          item.seasonNumber,
            grandparentTitle:     item.grandparentTitle,
            grandparentRatingKey: item.grandparentRatingKey,
            serverId:             serverId,
            serverName:           serverName,
          ));
        }
      }

      // Register the file and write to DB.
      await _downloadManager.registerSyncedDownload(
        metadata:  metadata,
        fileUri:   item.fileUri,
        thumbPath: item.thumb,
      );

      // Update local provider state immediately (same pattern as queueDownload).
      _downloads[globalKey] = DownloadProgress(
        globalKey: globalKey,
        status:    DownloadStatus.completed,
        progress:  100,
      );
      _metadata[globalKey]   = metadata;
      _artworkPaths[globalKey] = DownloadedArtwork(thumbPath: item.thumb);

      // Also populate the show-level artwork path so the TV Shows grid
      // shows the poster immediately in this session (without a restart).
      if (item.type == 'episode' && item.grandparentRatingKey != null &&
          item.grandparentRatingKey!.isNotEmpty) {
        final showKey = buildGlobalKey(serverId, item.grandparentRatingKey!);
        if (!_artworkPaths.containsKey(showKey)) {
          _artworkPaths[showKey] = DownloadedArtwork(thumbPath: item.grandparentThumb);
        }
      }

      // Fetch artwork when online. Show poster is fetched once per unique show
      // (tracked in fetchedShowKeys) to avoid redundant requests in a loop.
      // A short await between episode requests prevents Plex rate-limiting.
      if (clientResolver != null) {
        final client = clientResolver!(serverId);
        if (client != null) {
          await _downloadManager.downloadArtworkForMetadata(metadata, client);
          if (item.type == 'episode' && item.grandparentRatingKey?.isNotEmpty == true &&
              !fetchedShowKeys.contains(item.grandparentRatingKey)) {
            fetchedShowKeys.add(item.grandparentRatingKey!);
            await _downloadManager.downloadArtworkForMetadata(
              PlexMetadata(
                ratingKey:  item.grandparentRatingKey!,
                key:        '/library/metadata/${item.grandparentRatingKey}',
                type:       'show',
                thumb:      item.grandparentThumb,
                art:        item.grandparentArt,
                serverId:   serverId,
                serverName: serverName,
              ),
              client,
            );
          }
        }
      }

      imported++;
    }

    // Prune stale PlexSyncer items — any DB entry whose videoFilePath is a
    // SAF URI under the PlexSyncer folder but is no longer in the manifest
    // was removed by PlexSyncer (watched, rotated out, or deselected).
    // The file itself is already gone (removed by rclone / Round Sync).
    int pruned = 0;
    if (readResult.psRootUri.isNotEmpty) {
      // Parse the document ID of the PlexSyncer root once.
      // SAF child URIs have document IDs that start with the parent's document ID.
      final psDocId = Uri.parse(readResult.psRootUri).pathSegments.last;

      final allDownloads = await _downloadManager.getAllDownloads();
      for (final row in allDownloads) {
        final path = row.videoFilePath;
        if (path == null || !path.startsWith('content://')) continue;

        // Check if this file is under the PlexSyncer SAF folder.
        final fileDocId = Uri.parse(path).pathSegments.last;
        if (!fileDocId.startsWith(psDocId)) continue;

        // It's a PlexSyncer file — is it still in the manifest?
        if (readResult.manifestGlobalKeys.contains(row.globalKey)) continue;

        // Orphaned: remove from DB and in-memory state.
        // File is already gone so deleteDownload will find nothing to delete.
        appLogger.i('PlexSyncer prune: removing stale row ${row.globalKey}');
        try {
          await _downloadManager.deleteDownload(row.globalKey);
          _downloads.remove(row.globalKey);
          _metadata.remove(row.globalKey);
          _artworkPaths.remove(row.globalKey);
          pruned++;
        } catch (e) {
          appLogger.w('PlexSyncer prune: failed to remove ${row.globalKey}', error: e);
        }
      }
      if (pruned > 0) appLogger.i('PlexSyncer: pruned $pruned stale item(s)');
    }

    notifyListeners();

    return ImportSummary(
      imported: imported,
      skipped:  skipped,
      missing:  readResult.missing,
      pruned:   pruned,
    );
  }

  /// Refresh the downloads list from database
  Future<void> refresh() async {
    await _loadPersistedDownloads();
  }

  /// Resume queued downloads that were interrupted by app kill.
  /// Call after a PlexClient becomes available (e.g. after server connect on launch).
  void resumeQueuedDownloads(PlexClient client) {
    _downloadManager.resumeQueuedDownloads(client);
  }

  /// Refresh only metadata from API cache (after watch state sync).
  ///
  /// This is more lightweight than full refresh() - only updates metadata
  /// without reloading download progress from database.
  Future<void> refreshMetadataFromCache() async {
    final apiCache = PlexApiCache.instance;
    int updatedCount = 0;

    for (final globalKey in _metadata.keys.toList()) {
      final parsed = parseGlobalKey(globalKey);
      if (parsed == null) continue;

      final serverId = parsed.serverId;
      final ratingKey = parsed.ratingKey;

      try {
        final metadata = await apiCache.getMetadata(serverId, ratingKey);
        if (metadata != null) {
          _metadata[globalKey] = metadata;
          updatedCount++;
        }
      } catch (e) {
        appLogger.d('Failed to refresh metadata for $globalKey: $e');
      }
    }

    if (updatedCount > 0) {
      appLogger.i('Refreshed metadata from cache for $updatedCount items');
      notifyListeners();
    }
  }

  /// Auto-delete downloaded episodes/movies that are now marked as watched.
  ///
  /// Only deletes individual episodes and movies, never show/season containers.
  Future<List<String>> autoDeleteWatchedDownloads() async {
    final deletedTitles = <String>[];

    final completedKeys = _downloads.entries
        .where((e) => e.value.status == DownloadStatus.completed)
        .map((e) => e.key)
        .toList();

    for (final globalKey in completedKeys) {
      final meta = _metadata[globalKey];
      if (meta == null) continue;
      if (!meta.isEpisode && !meta.isMovie) continue;
      if (!meta.isWatched) continue;

      try {
        appLogger.i('Auto-deleting watched download: ${meta.title} ($globalKey)');
        await deleteDownload(globalKey);
        deletedTitles.add(meta.title ?? 'Unknown');
      } catch (e) {
        appLogger.w('Failed to auto-delete watched download $globalKey: $e');
      }
    }

    return deletedTitles;
  }
}

// PlexSyncer: summary returned by DownloadProvider.importFromManifest()
class ImportSummary {
  final int     imported;
  final int     skipped;
  final int     missing;
  final int     pruned;
  final String? error;

  const ImportSummary({
    this.imported = 0,
    this.skipped  = 0,
    this.missing  = 0,
    this.pruned   = 0,
    this.error,
  });

  bool get hasError => error != null;

  String toUserMessage() {
    if (hasError) return error!;
    final buf = StringBuffer();
    if (imported > 0) buf.write('$imported item(s) added.');
    if (skipped  > 0) buf.write(' $skipped already present.');
    if (pruned   > 0) buf.write(' $pruned item(s) removed.');
    if (missing  > 0) buf.write(' $missing file(s) not yet on device.');
    if (buf.isEmpty) buf.write('Everything up to date.');
    return buf.toString();
  }
}

/// Exception thrown when download is blocked due to cellular-only setting
class CellularDownloadBlockedException implements Exception {
  final String message = 'Downloads are disabled on cellular data';

  @override
  String toString() => message;
}
