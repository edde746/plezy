import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_version.dart';
import '../models/download_models.dart';
import '../utils/download_version_utils.dart';
import '../database/app_database.dart';
import '../database/download_operations.dart';
import '../services/download_manager_service.dart';
import '../services/api_cache.dart';
import '../services/download_storage_service.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';
import '../services/storage_service.dart';
import '../media/media_server_client.dart';
import '../services/sync_rule_executor.dart';
import '../utils/app_logger.dart';
import '../utils/deletion_notifier.dart';
import '../utils/episode_collection.dart';
import '../utils/global_key_utils.dart';
import '../utils/watch_state_notifier.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

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
class DownloadProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final DownloadManagerService _downloadManager;
  final AppDatabase _database;
  final SyncRuleExecutor _syncRuleExecutor;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  StreamSubscription<DeletionProgress>? _deletionProgressSubscription;
  StreamSubscription<WatchStateEvent>? _watchStateSubscription;
  late final Future<void> _initFuture;

  // Track download progress by public globalKey (serverId:ratingKey).
  // Downloads are shared across profiles/users; scoped Jellyfin state lives in
  // watch actions, cache namespaces, and sync-rule ownership.
  final Map<String, DownloadProgress> _downloads = {};

  // Store metadata for display
  final Map<String, MediaItem> _metadata = {};

  // Store Plex thumb paths for offline display (actual file path computed from hash)
  final Map<String, DownloadedArtwork> _artworkPaths = {};

  // Track items currently being queued (building download queue)
  final Set<String> _queueing = {};

  // Public download keys owned by the active profile. Physical download rows
  // stay app-wide; this set controls profile-visible state.
  final Set<String> _ownedDownloadKeys = {};

  // Track items currently being deleted with progress
  final Map<String, DeletionProgress> _deletionProgress = {};

  // Track total episode counts for shows/seasons (for partial download detection)
  // Key: globalKey (serverId:ratingKey), Value: total episode count
  final Map<String, int> _totalEpisodeCounts = {};

  // Persistent sync rules keyed by profile-scoped globalKey
  // (profileId|serverId:ratingKey). Downloads remain public/shared.
  final Map<String, SyncRuleItem> _syncRules = {};

  String? _activeProfileId;

  OfflineModeSource? _offlineSource;

  DownloadProvider({required DownloadManagerService downloadManager, required AppDatabase database})
    : _downloadManager = downloadManager,
      _database = database,
      _syncRuleExecutor = SyncRuleExecutor(database: database) {
    // Listen to progress updates from the download manager
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);

    // Listen to deletion progress updates
    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);

    // Keep cached metadata fresh when items get marked watched/unwatched anywhere
    // in the app, so re-entering a screen reflects the latest state.
    _watchStateSubscription = WatchStateNotifier().stream.listen(_onWatchStateChanged);

    // Load persisted downloads from database
    _initFuture = _loadPersistedDownloads();
  }

  /// Test-only constructor that skips the heavy initial load (artwork dir,
  /// pinned-metadata bulk fetch, episode counts). Only sync rules are loaded
  /// from the database. Use this in tests that exercise the provider's public
  /// database-backed API without mocking [DownloadStorageService],
  /// or path_provider.
  @visibleForTesting
  DownloadProvider.forTesting({
    required DownloadManagerService downloadManager,
    required AppDatabase database,
    String? activeProfileId = 'test-profile',
  }) : _downloadManager = downloadManager,
       _database = database,
       _syncRuleExecutor = SyncRuleExecutor(database: database),
       _activeProfileId = activeProfileId {
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);
    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);
    _watchStateSubscription = WatchStateNotifier().stream.listen(_onWatchStateChanged);
    _initFuture = _loadProfileScopedState();
  }

  /// Inject the offline-mode source so queueing paths can short-circuit when
  /// the device has no Plex connectivity. Propagates to the download manager
  /// and the sync-rule executor so background paths see the same flag.
  void setOfflineSource(OfflineModeSource? source) {
    _offlineSource = source;
    _downloadManager.setOfflineSource(source);
    _syncRuleExecutor.setOfflineSource(source);
  }

  /// Ensures persisted downloads have been loaded from disk.
  Future<void> ensureInitialized() => _initFuture;

  /// Switch the visible sync-rule scope to [profileId]. Physical downloads are
  /// intentionally not reloaded because they are shared across profiles.
  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    unawaited(_reloadProfileScopedStateForActiveProfile());
  }

  Future<void> _reloadProfileScopedStateForActiveProfile() async {
    final targetProfileId = _activeProfileId;
    await _initFuture;
    if (_activeProfileId != targetProfileId) return;
    await _loadProfileScopedState();
    if (_activeProfileId == targetProfileId) {
      safeNotifyListeners();
    }
  }

  String _requireActiveProfileId() {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) {
      throw StateError('Cannot create, update, or claim downloads without an active profile');
    }
    return profileId;
  }

  bool _ownsDownloadKey(String globalKey) => _ownedDownloadKeys.contains(globalKey);

  bool _ownsProgressEntry(MapEntry<String, DownloadProgress> entry) => _ownsDownloadKey(entry.key);

  Future<bool> _claimDownloadForActiveProfile(String globalKey) async {
    final profileId = _requireActiveProfileId();
    if (_ownedDownloadKeys.contains(globalKey)) return false;
    await _database.addDownloadOwner(profileId: profileId, globalKey: globalKey);
    if (_activeProfileId != profileId) return false;
    _ownedDownloadKeys.add(globalKey);
    return true;
  }

  Future<bool> _releaseDownloadForActiveProfile(String globalKey) async {
    final profileId = _requireActiveProfileId();
    if (!_ownedDownloadKeys.contains(globalKey)) return false;
    await _database.removeDownloadOwner(profileId: profileId, globalKey: globalKey);
    if (_activeProfileId == profileId) {
      _ownedDownloadKeys.remove(globalKey);
    }
    return true;
  }

  /// Remove all ownership rows for a deleted profile and delete physical files
  /// that no remaining valid profile owns.
  Future<void> deleteDownloadsForProfile(String profileId) async {
    await _releaseDownloadsForProfileWhere(profileId, (_) => true);
  }

  /// Remove ownership rows for [profileId] that belong to the removed
  /// connection's public server ids. Physical files stay when any other valid
  /// owner remains.
  Future<void> releaseDownloadsForProfileServers(String profileId, Set<String> serverIds) async {
    if (serverIds.isEmpty) return;
    await _releaseDownloadsForProfileWhere(profileId, (globalKey) {
      final parsed = parseGlobalKey(globalKey);
      return parsed != null && serverIds.contains(parsed.serverId);
    });
  }

  Future<void> _releaseDownloadsForProfileWhere(String profileId, bool Function(String globalKey) shouldRelease) async {
    if (profileId.isEmpty) return;
    final ownedKeys = await _database.getDownloadOwnerKeysForProfile(profileId);
    var changed = false;
    for (final globalKey in ownedKeys) {
      if (!shouldRelease(globalKey)) continue;
      final meta = _metadata[globalKey];
      await _database.removeDownloadOwner(profileId: profileId, globalKey: globalKey);
      if (_activeProfileId == profileId) {
        _ownedDownloadKeys.remove(globalKey);
      }
      if (await _database.hasDownloadOwner(globalKey)) {
        changed = true;
        continue;
      }

      await _downloadManager.deleteDownload(globalKey);
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      _artworkPaths.remove(globalKey);
      _totalEpisodeCounts.remove(globalKey);
      if (meta != null) {
        DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
      }
      changed = true;
    }
    if (changed) safeNotifyListeners();
  }

  Future<void> _loadProfileScopedState() async {
    await _loadDownloadOwners();
    await _loadSyncRules();
  }

  /// Test-only seam to populate internal state maps without driving the full
  /// queue/progress pipeline. Intended for tests that exercise functions whose
  /// behavior depends on pre-existing state (e.g. cancelDownload artwork
  /// cleanup, _loadPersistedDownloads transient-state clearing).
  @visibleForTesting
  void debugSeedState({
    Map<String, DownloadProgress>? downloads,
    Map<String, MediaItem>? metadata,
    Map<String, DownloadedArtwork>? artwork,
    Map<String, int>? episodeCounts,
    Set<String>? queueing,
    Map<String, DeletionProgress>? deletionProgress,
    Set<String>? ownedDownloadKeys,
  }) {
    if (downloads != null) _downloads.addAll(downloads);
    if (metadata != null) _metadata.addAll(metadata);
    if (artwork != null) _artworkPaths.addAll(artwork);
    if (episodeCounts != null) _totalEpisodeCounts.addAll(episodeCounts);
    if (queueing != null) _queueing.addAll(queueing);
    if (deletionProgress != null) _deletionProgress.addAll(deletionProgress);
    if (ownedDownloadKeys != null) {
      _ownedDownloadKeys.addAll(ownedDownloadKeys);
    } else if (downloads != null) {
      _ownedDownloadKeys.addAll(downloads.keys);
    }
  }

  /// Test-only inspector for `_totalEpisodeCounts` (no public getter today).
  @visibleForTesting
  int? totalEpisodeCountFor(String globalKey) => _totalEpisodeCounts[globalKey];

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
      _queueing.clear();
      _deletionProgress.clear();
      _ownedDownloadKeys.clear();

      final storageService = DownloadStorageService.instance;

      // Initialize artwork directory path for synchronous access
      await storageService.getArtworkDirectory();

      // Load all downloads from database
      final downloads = await _downloadManager.getAllDownloads();

      // Bulk-load all pinned metadata across both backends in a single pass
      // instead of per-item DB calls.
      final allMetadata = await _downloadManager.getAllPinnedMetadata(preferActiveScope: true);

      for (final item in downloads) {
        _downloads[item.globalKey] = DownloadProgress(
          globalKey: item.globalKey,
          status: DownloadStatus.values[item.status],
          progress: item.progress,
          downloadedBytes: item.downloadedBytes,
          totalBytes: item.totalBytes ?? 0,
          errorMessage: item.errorMessage,
        );

        _artworkPaths[item.globalKey] = DownloadedArtwork(thumbPath: item.thumbPath);

        // Look up metadata from the bulk-loaded map (O(1) instead of DB query per item)
        // Falls back to individual query for any unpinned entries (e.g., legacy data).
        // The fallback dispatches by backend.
        final cached =
            allMetadata[item.globalKey] ??
            await _downloadManager.lookupMetadata(item.serverId, item.ratingKey, preferActiveScope: true);
        if (cached != null) {
          _metadata[item.globalKey] = cached;

          // For episodes, also load parent (show and season) metadata from the same map
          if (cached.isEpisode) {
            _loadParentMetadataFromMap(
              cached,
              allMetadata,
              clientScopeId: _downloadManager.activeClientScopeIdForServer(item.serverId) ?? item.clientScopeId,
            );
          }
        }
      }

      // Load total episode counts from StorageService
      await _loadTotalEpisodeCounts();

      // Load sync rules from database
      await _loadProfileScopedState();

      // Apply queued offline watch actions on top of the server-time metadata
      // we just loaded, so re-entries reflect locally-marked watched/unwatched
      // state from previous sessions until those actions sync to the server.
      await _applyOfflineWatchOverlay();

      appLogger.i(
        'Loaded ${_downloads.length} downloads, ${_metadata.length} metadata entries, '
        '${_totalEpisodeCounts.length} episode counts, and ${_syncRules.length} sync rules',
      );
      safeNotifyListeners();
    } catch (e) {
      appLogger.e('Failed to load persisted downloads', error: e);
    }
  }

  /// Patch `_metadata` viewCount/viewOffsetMs from queued OfflineWatchProgress
  /// actions. Idempotent and cheap (one batched DB read).
  Future<void> _applyOfflineWatchOverlay() async {
    if (_metadata.isEmpty) return;
    try {
      final keys = _metadata.keys.toSet();
      final scopes = <String, String?>{};
      for (final key in keys) {
        scopes[key] = await _offlineWatchScopeForGlobalKey(key);
      }
      final profileId = _activeProfileId;
      final actions = await _database.getLatestWatchActionsForKeys(
        keys,
        profileId: profileId,
        filterProfile: profileId != null,
        clientScopeIdsByGlobalKey: scopes,
      );
      if (actions.isEmpty) return;
      for (final entry in actions.entries) {
        final base = _metadata[entry.key];
        if (base == null) continue;
        final action = entry.value;
        bool? isWatched;
        switch (action.actionType) {
          case 'watched':
            isWatched = true;
          case 'unwatched':
            isWatched = false;
          case 'progress':
            isWatched = action.shouldMarkWatched;
        }
        if (isWatched == null) continue;
        _metadata[entry.key] = base.copyWith(
          viewCount: isWatched ? 1 : 0,
          viewOffsetMs: isWatched ? base.viewOffsetMs : 0,
        );
      }
    } catch (e) {
      appLogger.w('Failed to apply offline watch overlay', error: e);
    }
  }

  Future<String?> _offlineWatchScopeForGlobalKey(String globalKey) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;
    final activeScope = _downloadManager.activeClientScopeIdForServer(parsed.serverId);
    if (activeScope != null && activeScope.isNotEmpty) return activeScope;
    final downloaded = await _database.getDownloadedMedia(globalKey);
    final downloadedScope = downloaded?.clientScopeId;
    return downloadedScope == null || downloadedScope.isEmpty ? null : downloadedScope;
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
  void _loadParentMetadataFromMap(MediaItem episode, Map<String, MediaItem> allMetadata, {String? clientScopeId}) {
    final serverId = episode.serverId;
    if (serverId == null) return;

    MediaItem? lookupParent(String ratingKey) {
      if (clientScopeId != null && clientScopeId.isNotEmpty) {
        final scoped = allMetadata[buildGlobalKey(clientScopeId, ratingKey)];
        if (scoped != null) return scoped;
      }
      return allMetadata[buildGlobalKey(serverId, ratingKey)];
    }

    // Load show metadata
    final showRatingKey = episode.grandparentId;
    if (showRatingKey != null) {
      final showGlobalKey = buildGlobalKey(serverId, showRatingKey);
      if (!_metadata.containsKey(showGlobalKey)) {
        final showMetadata = lookupParent(showRatingKey);
        if (showMetadata != null) {
          _metadata[showGlobalKey] = showMetadata;
          if (showMetadata.thumbPath != null) {
            _artworkPaths[showGlobalKey] = DownloadedArtwork(thumbPath: showMetadata.thumbPath);
          }
        }
      }
    }

    // Load season metadata
    final seasonRatingKey = episode.parentId;
    if (seasonRatingKey != null) {
      final seasonGlobalKey = buildGlobalKey(serverId, seasonRatingKey);
      if (!_metadata.containsKey(seasonGlobalKey)) {
        final seasonMetadata = lookupParent(seasonRatingKey);
        if (seasonMetadata != null) {
          _metadata[seasonGlobalKey] = seasonMetadata;
          if (seasonMetadata.thumbPath != null) {
            _artworkPaths[seasonGlobalKey] = DownloadedArtwork(thumbPath: seasonMetadata.thumbPath);
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
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _deletionProgressSubscription?.cancel();
    _watchStateSubscription?.cancel();
    super.dispose();
  }

  void _onWatchStateChanged(WatchStateEvent event) {
    // Progress ticks fire continuously during playback; only react to discrete
    // watched/unwatched flips so we don't churn listeners on every frame.
    if (event.changeType == WatchStateChangeType.progressUpdate) return;
    if (event.isNowWatched == null) return;

    final globalKey = buildGlobalKey(event.serverId, event.itemId);
    final base = _metadata[globalKey];
    if (base == null) return;

    final isWatched = event.isNowWatched!;
    _metadata[globalKey] = base.copyWith(viewCount: isWatched ? 1 : 0, viewOffsetMs: isWatched ? base.viewOffsetMs : 0);
    // Persist into the per-backend pinned cache so the patch survives reloads
    // (`_loadPersistedDownloads` rehydrates `_metadata` from the cache).
    unawaited(
      ApiCache.forBackend(base.backend)
          .applyWatchState(serverId: event.cacheServerId ?? event.serverId, itemId: event.itemId, isWatched: isWatched)
          .catchError((Object e) {
            appLogger.w('Failed to apply watch state to cache for $globalKey', error: e);
          }),
    );
    safeNotifyListeners();
  }

  /// Ensure metadata has a serverId, falling back to a parent's serverId.
  MediaItem _ensureServerId(MediaItem metadata, String? fallbackServerId) =>
      metadata.serverId != null ? metadata : metadata.copyWith(serverId: fallbackServerId);

  /// All current download progress entries
  Map<String, DownloadProgress> get downloads =>
      Map.unmodifiable(Map.fromEntries(_downloads.entries.where(_ownsProgressEntry)));

  /// All metadata for downloads
  Map<String, MediaItem> get metadata => Map.unmodifiable(_metadata);

  /// Get unique TV shows that have downloaded episodes
  /// Returns stored show metadata, or synthesizes from episode metadata as fallback
  List<MediaItem> get downloadedShows {
    final Map<String, MediaItem> shows = {};

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      if (!_ownsDownloadKey(globalKey)) continue;
      final meta = entry.value;
      final progress = _downloads[globalKey];

      if (progress?.status == DownloadStatus.completed && meta.isEpisode) {
        final showRatingKey = meta.grandparentId;
        if (showRatingKey != null && !shows.containsKey(showRatingKey)) {
          // Try to get stored show metadata first
          final showGlobalKey = buildGlobalKey(meta.serverId!, showRatingKey);
          final storedShow = _metadata[showGlobalKey];

          if (storedShow != null && storedShow.isShow) {
            // Use stored show metadata (has year, summary, clearLogo)
            shows[showRatingKey] = storedShow;
          } else {
            // Fallback: synthesize from episode metadata (missing year, summary)
            // Only Plex consumers read `raw['key']` (library-section + folder
            // navigation), so we synthesize the Plex URI for Plex shows and
            // emit a Jellyfin-shaped item for Jellyfin (Id + Type=Series).
            final synthesizedRaw = switch (meta.backend) {
              MediaBackend.plex => <String, dynamic>{'key': '/library/metadata/$showRatingKey'},
              MediaBackend.jellyfin => <String, dynamic>{'Id': showRatingKey, 'Type': 'Series'},
            };
            shows[showRatingKey] = MediaItem(
              id: showRatingKey,
              backend: meta.backend,
              kind: MediaKind.show,
              title: meta.grandparentTitle ?? 'Unknown Show',
              thumbPath: meta.grandparentThumbPath,
              artPath: meta.grandparentArtPath,
              serverId: meta.serverId,
              raw: synthesizedRaw,
            );
          }
        }
      }
    }

    return shows.values.toList();
  }

  /// Get completed movie downloads
  List<MediaItem> get downloadedMovies {
    return _metadata.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final progress = _downloads[entry.key];
          return progress?.status == DownloadStatus.completed && entry.value.isMovie;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Get metadata for a specific download
  MediaItem? getMetadata(String globalKey) => _metadata[globalKey];

  /// Get artwork paths for a specific download (for offline display)
  DownloadedArtwork? getArtworkPaths(String globalKey) => _artworkPaths[globalKey];

  /// Get local file path for any artwork type (thumb, art, clearLogo, etc.)
  /// Returns null if artwork directory isn't initialized or artworkPath is null
  String? getArtworkLocalPath(String serverId, String? artworkPath) {
    if (artworkPath == null) return null;
    return DownloadStorageService.instance.getArtworkPathSync(serverId, artworkPath);
  }

  /// Get downloaded episodes for a specific show (by grandparentRatingKey)
  List<MediaItem> getDownloadedEpisodesForShow(String showRatingKey) {
    return _metadata.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final progress = _downloads[entry.key];
          final meta = entry.value;
          return progress?.status == DownloadStatus.completed && meta.isEpisode && meta.grandparentId == showRatingKey;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Get episode downloads filtered by show and/or season ratingKey.
  List<DownloadProgress> _getEpisodeDownloads({String? showRatingKey, String? seasonRatingKey}) {
    return _downloads.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final meta = _metadata[entry.key];
          if (meta == null || !meta.isEpisode) return false;
          if (showRatingKey != null && meta.grandparentId != showRatingKey) return false;
          if (seasonRatingKey != null && meta.parentId != seasonRatingKey) return false;
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
      '  - Type: ${meta?.kind.id}\n'
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

  /// Get download progress for a specific item
  /// For shows/seasons, returns aggregate progress of all child episodes
  /// For episodes/movies, returns direct progress
  DownloadProgress? getProgress(String globalKey) {
    // First check if we have direct progress (for episodes/movies)
    final directProgress = _downloads[globalKey];
    if (directProgress != null) {
      if (!_ownsDownloadKey(globalKey)) return null;
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

    // We have metadata, check kind
    if (meta.kind == MediaKind.show) {
      return getAggregateProgressForShow(serverId, ratingKey);
    } else if (meta.kind == MediaKind.season) {
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
    if (!_ownsDownloadKey(globalKey)) {
      appLogger.w('Profile does not own downloaded item: $globalKey');
      return null;
    }

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
    MediaItem metadata,
    MediaServerClient client, {
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
      safeNotifyListeners();

      if (metadata.isMovie || metadata.isEpisode) {
        final queued = await _queueSingleDownload(metadata, client, mediaIndex: config.mediaIndex);
        return queued ? 1 : 0;
      } else if (metadata.isShow) {
        // Stash metadata pre-queue so the UI can render the queueing state;
        // roll back if expansion throws so the orphan doesn't linger.
        final hadMetadata = _metadata.containsKey(globalKey);
        _metadata[globalKey] = metadata;
        try {
          return await _queueShowDownload(metadata, client, versionConfig: config, filter: filter, maxCount: maxCount);
        } catch (_) {
          if (!hadMetadata) _metadata.remove(globalKey);
          rethrow;
        }
      } else if (metadata.isSeason) {
        final hadMetadata = _metadata.containsKey(globalKey);
        _metadata[globalKey] = metadata;
        try {
          return await _queueSeasonDownload(
            metadata,
            client,
            versionConfig: config,
            filter: filter,
            maxCount: maxCount,
          );
        } catch (_) {
          if (!hadMetadata) _metadata.remove(globalKey);
          rethrow;
        }
      } else {
        throw Exception('Cannot download ${metadata.kind.id}');
      }
    } finally {
      _queueing.remove(globalKey);
      safeNotifyListeners();
    }
  }

  /// Queue every playable item from a collection/playlist for download.
  ///
  /// Movies and episodes are queued directly. Shows and seasons are expanded
  /// into their episodes (when [expandShows] is true). Music items, nested
  /// collections/playlists, and unknown types are skipped.
  Future<int> queueListDownload(
    List<MediaItem> items,
    MediaServerClient client, {
    DownloadFilter filter = DownloadFilter.all,
    bool expandShows = true,
  }) async {
    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      throw CellularDownloadBlockedException();
    }

    final unwatchedOnly = filter == DownloadFilter.unwatched;
    int count = 0;

    Future<void> queueItem(MediaItem item) async {
      if (unwatchedOnly && item.isWatched && !item.hasActiveProgress) return;
      final queued = await _queueSingleDownload(item, client);
      if (queued) count++;
    }

    for (final item in items) {
      if (item.isMovie || item.isEpisode) {
        await queueItem(item);
      } else if (item.isShow || item.isSeason) {
        if (!expandShows) continue;
        // One-shot recursive expansion (Plex /grandchildren, Jellyfin
        // Recursive=true) — the per-season walk that used to live here
        // was the same pattern as collectEpisodes*, just inlined.
        final episodes = <MediaItem>[];
        if (item.isShow) {
          await collectEpisodesForShow(client, item.id, unwatchedOnly: unwatchedOnly, out: episodes);
        } else {
          await collectEpisodesForSeason(client, item.id, unwatchedOnly: unwatchedOnly, out: episodes);
        }
        for (final ep in episodes) {
          await queueItem(ep);
        }
      } else {
        // Skip music, clips, nested collections/playlists, unknown types.
        continue;
      }
    }
    return count;
  }

  /// Queue a single movie or episode for download.
  /// Returns true if the item was actually queued, false if skipped.
  Future<bool> _queueSingleDownload(
    MediaItem metadata,
    MediaServerClient client, {
    int mediaIndex = 0,
    DownloadVersionConfig? versionConfig,
  }) async {
    _requireActiveProfileId();
    final globalKey = metadata.globalKey;

    // Don't duplicate the physical download. If another profile already owns
    // the shared row, claiming it makes it visible for the active profile.
    if (_downloads.containsKey(globalKey)) {
      final existing = _downloads[globalKey]!;
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.completed ||
          existing.status == DownloadStatus.queued) {
        final claimed = await _claimDownloadForActiveProfile(globalKey);
        if (claimed) safeNotifyListeners();
        return claimed;
      }
    }

    // Always fetch full metadata before downloading.
    // Hub items may have summary but the cache at /library/metadata/$ratingKey
    // won't have the full API response (with Media/Part data needed for video URL)
    // unless fetchItem has been called.
    //
    // Skip the fetch when offline — it would just fail. The partial metadata
    // from whatever hub/grid invoked the queue is good enough to enqueue; the
    // actual video URL resolves later when we're back online.
    MediaItem metadataToStore = metadata;
    if (_offlineSource?.isOffline ?? false) {
      appLogger.d('Offline — using partial metadata for ${metadata.id}');
    } else {
      try {
        final fullMetadata = await client.fetchItem(metadata.id);
        if (fullMetadata != null) {
          metadataToStore = fullMetadata.copyWith(serverId: metadata.serverId, serverName: metadata.serverName);
        }
      } catch (e) {
        appLogger.w('Failed to fetch full metadata for ${metadata.id}, using partial', error: e);
      }
    }

    // Smart version matching for series/season downloads
    var resolvedIndex = mediaIndex;
    if (versionConfig != null && versionConfig.acceptedSignatures.isNotEmpty) {
      final versions = metadataToStore.mediaVersions;
      if (versions != null && versions.isNotEmpty) {
        final matchedIndex = MediaVersion.findMatchingIndex(versions, versionConfig.acceptedSignatures);
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
    if (metadataToStore.isEpisode) {
      await _fetchAndStoreParentMetadata(metadataToStore, client);
    }

    // Store full metadata for display
    _metadata[globalKey] = metadataToStore;

    await _claimDownloadForActiveProfile(globalKey);

    // Update local state immediately for UI feedback
    _downloads[globalKey] = DownloadProgress(globalKey: globalKey, status: DownloadStatus.queued);
    safeNotifyListeners();

    // Actually trigger download via DownloadManagerService
    await _downloadManager.queueDownload(metadata: metadataToStore, client: client, mediaIndex: resolvedIndex);
    return true;
  }

  /// Fetch and store show and season metadata for an episode
  /// Also downloads artwork for show and season
  Future<void> _fetchAndStoreParentMetadata(MediaItem episode, MediaServerClient client) async {
    final serverId = episode.serverId;
    if (serverId == null) return;

    await _fetchAndStoreRelatedMetadata(serverId: serverId, ratingKey: episode.grandparentId, client: client);
    await _fetchAndStoreRelatedMetadata(serverId: serverId, ratingKey: episode.parentId, client: client);
  }

  /// Fetch, persist, and download artwork for a related metadata item (show or season).
  Future<void> _fetchAndStoreRelatedMetadata({
    required String serverId,
    required String? ratingKey,
    required MediaServerClient client,
  }) async {
    if (ratingKey == null) return;
    final globalKey = buildGlobalKey(serverId, ratingKey);
    final storageService = DownloadStorageService.instance;

    MediaItem? metadata = _metadata[globalKey];
    if (metadata == null) {
      try {
        metadata = await client.fetchItem(ratingKey);
      } catch (e) {
        appLogger.w('Failed to fetch metadata for $ratingKey', error: e);
      }
    }
    if (metadata == null) return;

    final withServer = metadata.copyWith(serverId: serverId);
    _metadata[globalKey] = withServer;
    await _downloadManager.saveMetadata(withServer, client);

    final thumbPath = withServer.thumbPath;
    final hasPoster = thumbPath != null && await storageService.artworkExists(serverId, thumbPath);
    if (!hasPoster) {
      await _downloadManager.downloadArtworkForMetadata(withServer, client);
    }
    _artworkPaths[globalKey] = DownloadedArtwork(thumbPath: thumbPath);
  }

  /// Store leafCount for a show or season so aggregate progress works.
  Future<void> _storeLeafCount(String globalKey, MediaItem metadata) async {
    if (metadata.leafCount != null && metadata.leafCount! > 0) {
      _totalEpisodeCounts[globalKey] = metadata.leafCount!;
      await _persistTotalEpisodeCount(globalKey, metadata.leafCount!);
    }
  }

  /// Queue all episodes from a TV show for download
  Future<int> _queueShowDownload(
    MediaItem show,
    MediaServerClient client, {
    DownloadVersionConfig? versionConfig,
    DownloadFilter filter = DownloadFilter.all,
    int? maxCount,
  }) async {
    await _storeLeafCount(show.globalKey, show);
    return _expandAndQueue(
      container: show,
      client: client,
      versionConfig: versionConfig,
      filter: filter,
      maxCount: maxCount,
      skipExisting: false,
    );
  }

  /// Queue all episodes from a season for download
  Future<int> _queueSeasonDownload(
    MediaItem season,
    MediaServerClient client, {
    DownloadVersionConfig? versionConfig,
    DownloadFilter filter = DownloadFilter.all,
    int? maxCount,
  }) async {
    await _storeLeafCount(season.globalKey, season);
    return _expandAndQueue(
      container: season,
      client: client,
      versionConfig: versionConfig,
      filter: filter,
      maxCount: maxCount,
      skipExisting: false,
    );
  }

  /// Queue only the missing (not downloaded) episodes for a show/season.
  /// Used for resuming partial downloads. Returns the number of episodes queued.
  Future<int> queueMissingEpisodes(
    MediaItem metadata,
    MediaServerClient client, {
    DownloadVersionConfig? versionConfig,
  }) async {
    if (!metadata.isShow && !metadata.isSeason) {
      throw Exception('queueMissingEpisodes only supports shows/seasons');
    }
    final queued = await _expandAndQueue(
      container: metadata,
      client: client,
      versionConfig: versionConfig,
      filter: DownloadFilter.all,
      maxCount: null,
      skipExisting: true,
    );
    if (metadata.isShow) {
      appLogger.i('Queued $queued missing episodes for show ${metadata.title}');
    }
    return queued;
  }

  /// Shared expansion: fetch all episodes under [container] (show or season),
  /// apply [filter] and optional [maxCount], optionally skip items already
  /// queued/downloading/completed ([skipExisting]), and queue each one.
  Future<int> _expandAndQueue({
    required MediaItem container,
    required MediaServerClient client,
    required DownloadVersionConfig? versionConfig,
    required DownloadFilter filter,
    required int? maxCount,
    required bool skipExisting,
  }) async {
    final unwatchedOnly = filter == DownloadFilter.unwatched;
    final episodes = <MediaItem>[];
    if (container.kind == MediaKind.show) {
      await collectEpisodesForShow(client, container.id, unwatchedOnly: unwatchedOnly, out: episodes);
    } else {
      await collectEpisodesForSeason(client, container.id, unwatchedOnly: unwatchedOnly, out: episodes);
    }

    int count = 0;
    for (final episode in episodes) {
      if (maxCount != null && count >= maxCount) break;

      final episodeWithServer = _ensureServerId(episode, container.serverId);

      if (skipExisting) {
        final progress = _downloads[episodeWithServer.globalKey];
        if (progress != null &&
            _ownsDownloadKey(episodeWithServer.globalKey) &&
            (progress.status == DownloadStatus.completed ||
                progress.status == DownloadStatus.downloading ||
                progress.status == DownloadStatus.queued)) {
          continue;
        }
      }

      final queued = await _queueSingleDownload(episodeWithServer, client, versionConfig: versionConfig);
      if (queued) count++;
    }
    return count;
  }

  /// Pause a download (works for both downloading and queued items)
  Future<void> pauseDownload(String globalKey) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null &&
        (progress.status == DownloadStatus.downloading || progress.status == DownloadStatus.queued)) {
      await _downloadManager.pauseDownload(globalKey);
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, MediaServerClient client) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null && progress.status == DownloadStatus.paused) {
      await _downloadManager.resumeDownload(globalKey, client);
    }
  }

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, MediaServerClient client) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null && progress.status == DownloadStatus.failed) {
      await _downloadManager.retryDownload(globalKey, client);
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null) {
      final released = await _releaseDownloadForActiveProfile(globalKey);
      final hasOtherOwners = await _database.hasDownloadOwner(globalKey);
      final removedMeta = _metadata[globalKey];
      if (!hasOtherOwners) {
        await _downloadManager.cancelDownload(globalKey);
        await _database.deleteDownload(globalKey);
        _downloads.remove(globalKey);
        _metadata.remove(globalKey);
        _artworkPaths.remove(globalKey);
        _totalEpisodeCounts.remove(globalKey);
      }
      if (removedMeta != null) {
        DeletionNotifier().notifyDeletedItem(item: removedMeta, isDownloadOnly: true);
      } else if (!released) {
        return;
      }
      safeNotifyListeners();
    }
  }

  /// Delete a downloaded item
  Future<void> deleteDownload(String globalKey) async {
    try {
      final meta = _metadata[globalKey];
      if (meta != null && (meta.isShow || meta.isSeason)) {
        await _deleteOwnedContainerDownloads(globalKey, meta);
        return;
      }
      if (!_ownsDownloadKey(globalKey)) return;

      final released = await _releaseDownloadForActiveProfile(globalKey);
      final hasOtherOwners = await _database.hasDownloadOwner(globalKey);
      if (hasOtherOwners) {
        if (meta != null) {
          DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
        }
        if (released) safeNotifyListeners();
        return;
      }

      // Start deletion (progress will be tracked via stream)
      await _downloadManager.deleteDownload(globalKey);

      // Remove from local state
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      _artworkPaths.remove(globalKey);

      // Notify any open screens so they can drop the item from their lists
      // immediately instead of waiting for an exit/re-enter.
      if (meta != null) {
        DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
      }

      safeNotifyListeners();
    } catch (e) {
      // Remove from deletion tracking on error
      _deletionProgress.remove(globalKey);
      safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> _deleteOwnedContainerDownloads(String globalKey, MediaItem container) async {
    final removedCount = _totalEpisodeCounts.remove(globalKey);
    final storage = await StorageService.getInstance();
    await storage.removeEpisodeCount(globalKey);
    appLogger.i(
      'Removed episode count for $globalKey\n'
      '  - Removed count value: $removedCount\n'
      '  - Metadata type: ${container.kind.id}\n'
      '  - Metadata title: ${container.title}\n'
      '  - Remaining stored counts: ${_totalEpisodeCounts.length}',
    );

    final descendants = _ownedDescendantEntries(container).toList();
    for (final entry in descendants) {
      await deleteDownload(entry.key);
    }

    DeletionNotifier().notifyDeletedItem(item: container, isDownloadOnly: true);
    safeNotifyListeners();
  }

  Iterable<MapEntry<String, MediaItem>> _ownedDescendantEntries(MediaItem container) {
    return _metadata.entries.where((entry) {
      if (!_ownsDownloadKey(entry.key)) return false;
      final meta = entry.value;
      if (meta.serverId != container.serverId) return false;
      return container.isShow
          ? (meta.grandparentId == container.id || meta.parentId == container.id)
          : meta.parentId == container.id;
    });
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
    safeNotifyListeners();
  }

  /// Get deletion progress for an item
  DeletionProgress? getDeletionProgress(String globalKey) => _deletionProgress[globalKey];

  /// Refresh the downloads list from database
  Future<void> refresh() async {
    await _loadPersistedDownloads();
  }

  /// Resume queued downloads that were interrupted by app kill.
  /// Call after a [MediaServerClient] becomes available (e.g. after server connect on launch).
  void resumeQueuedDownloads(MediaServerClient client) {
    _downloadManager.resumeQueuedDownloads(client);
  }

  /// Backend-aware metadata lookup for offline UI. Routes through
  /// [DownloadManagerService] which dispatches to [PlexApiCache] or
  /// [JellyfinApiCache] based on the connection's `kind`.
  Future<MediaItem?> lookupOfflineMetadata(String serverId, String itemId) =>
      _downloadManager.lookupMetadata(serverId, itemId);

  /// Refresh only metadata from API cache (after watch state sync).
  ///
  /// This is more lightweight than full refresh() - only updates metadata
  /// without reloading download progress from database.
  Future<void> refreshMetadataFromCache() async {
    // The initial load runs in the constructor and may still be in flight
    // when callers (e.g. `onServersConnected`) trigger this. Wait for it so
    // `_downloads` is populated before we walk it — otherwise an early call
    // sees an empty map and does nothing useful.
    await ensureInitialized();

    // Walk every download — not just keys we already have metadata for. The
    // initial `_loadPersistedDownloads` may have raced with connection setup
    // (Jellyfin's cache reads need a [Connections] row) and skipped entries;
    // this lets a later refresh actually populate them.
    final keys = <String>{..._metadata.keys, ..._downloads.keys};
    if (keys.isEmpty) return;

    final allMetadata = await _downloadManager.getAllPinnedMetadata(preferActiveScope: true);
    int cacheHits = 0;
    int networkFills = 0;
    int misses = 0;

    for (final globalKey in keys) {
      final parsed = parseGlobalKey(globalKey);
      if (parsed == null) continue;

      try {
        final downloadRecord = await _downloadManager.getDownloadedMedia(globalKey);
        var cached =
            allMetadata[globalKey] ??
            await _downloadManager.lookupMetadata(parsed.serverId, parsed.ratingKey, preferActiveScope: true);
        if (cached != null) {
          cacheHits++;
        } else if (_downloads.containsKey(globalKey)) {
          // Cache miss for an item we know is downloaded — pull from the
          // live server. Repairs profiles where the per-backend cache row
          // was never written or got cleared, the case that produces
          // empty-title sync rules and a missing-downloads list.
          cached = await _downloadManager.fetchAndPinMetadata(
            parsed.serverId,
            parsed.ratingKey,
            preferActiveScope: true,
          );
          if (cached != null) networkFills++;
        }

        if (cached != null) {
          _metadata[globalKey] = cached;
          if (cached.isEpisode) {
            _loadParentMetadataFromMap(
              cached,
              allMetadata,
              clientScopeId:
                  _downloadManager.activeClientScopeIdForServer(parsed.serverId) ?? downloadRecord?.clientScopeId,
            );
          }
        } else {
          misses++;
        }
      } catch (e) {
        appLogger.d('Failed to refresh metadata for $globalKey: $e');
      }
    }

    // Re-apply offline overlay so locally-queued watch actions aren't clobbered
    // by stale per-backend caches that haven't yet seen the server roundtrip.
    await _applyOfflineWatchOverlay();

    final updatedCount = cacheHits + networkFills;
    appLogger.i(
      'refreshMetadataFromCache: walked ${keys.length} keys → '
      '$cacheHits cache hits, $networkFills network fills, $misses unresolved',
    );
    if (updatedCount > 0) {
      safeNotifyListeners();
    }
  }

  /// Auto-delete downloaded episodes/movies that are now marked as watched.
  ///
  /// Only deletes individual episodes and movies, never show/season containers.
  /// [activeId] is excluded from deletion to protect the currently playing item.
  Future<List<String>> autoDeleteWatchedDownloads({String? activeId}) async {
    final deletedTitles = <String>[];

    final completedKeys = _downloads.entries
        .where((e) => _ownsDownloadKey(e.key) && e.value.status == DownloadStatus.completed)
        .map((e) => e.key)
        .toList();

    for (final globalKey in completedKeys) {
      final meta = _metadata[globalKey];
      if (meta == null) continue;
      if (!meta.isEpisode && !meta.isMovie) continue;
      if (!meta.isWatched) continue;

      // Don't delete the episode that's currently playing
      if (activeId != null && meta.id == activeId) continue;

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

  // ============================================================
  // Sync Rules
  // ============================================================

  /// All sync rules for the active profile (profile-scoped globalKey -> SyncRuleItem).
  Map<String, SyncRuleItem> get syncRules => Map.unmodifiable(_syncRules);

  String syncRuleKeyFor(String serverId, String ratingKey, {String? profileId}) {
    final owner = profileId ?? _activeProfileId;
    if (owner == null || owner.isEmpty) return buildGlobalKey(serverId, ratingKey);
    return buildProfileScopedGlobalKey(owner, serverId, ratingKey);
  }

  String syncRuleKeyForGlobalKey(String globalKey) {
    final scoped = parseProfileScopedGlobalKey(globalKey);
    if (scoped != null) {
      return syncRuleKeyFor(scoped.serverId, scoped.ratingKey, profileId: scoped.profileId);
    }
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return globalKey;
    return syncRuleKeyFor(parsed.serverId, parsed.ratingKey);
  }

  String syncRuleKeyForClient(MediaServerClient client, String ratingKey, {String? serverId}) {
    return syncRuleKeyFor(serverId ?? client.serverId, ratingKey);
  }

  /// Candidate active-profile sync-rule keys touched by a watched item event.
  Set<String> syncRuleKeysForWatchEvent(WatchStateEvent event) {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return const {};
    final keys = <String>{};
    void add(String ratingKey) {
      keys.add(syncRuleKeyFor(event.serverId, ratingKey, profileId: profileId));
    }

    add(event.itemId);
    for (final parentKey in event.parentChain) {
      add(parentKey);
    }
    return keys;
  }

  /// Check if a sync rule exists for the given item
  bool hasSyncRule(String globalKey) => _syncRules.containsKey(globalKey);

  /// Get a sync rule for the given item
  SyncRuleItem? getSyncRule(String globalKey) => _syncRules[globalKey];

  /// Create (or upsert) a sync rule for a show, season, collection, or playlist.
  ///
  /// [targetMetadata], when provided, is stored in the in-memory metadata map so
  /// the Sync Rules screen shows the item's title immediately instead of a bare
  /// rating key — useful for collection/playlist rules where no underlying
  /// episode download would otherwise populate it.
  Future<void> createSyncRule({
    required String serverId,
    required String ratingKey,
    required String targetType,
    required int episodeCount,
    int mediaIndex = 0,
    String downloadFilter = SyncRuleFilter.unwatched,
    MediaItem? targetMetadata,
  }) async {
    final profileId = _requireActiveProfileId();
    final publicGlobalKey = buildGlobalKey(serverId, ratingKey);
    final scopedGlobalKey = syncRuleKeyFor(serverId, ratingKey, profileId: profileId);
    await _database.insertSyncRule(
      profileId: profileId,
      serverId: serverId,
      ratingKey: ratingKey,
      globalKey: scopedGlobalKey,
      targetType: targetType,
      episodeCount: episodeCount,
      mediaIndex: mediaIndex,
      downloadFilter: downloadFilter,
    );

    if (targetMetadata != null) {
      final withServer = targetMetadata.serverId != null ? targetMetadata : targetMetadata.copyWith(serverId: serverId);
      _metadata[publicGlobalKey] = withServer;
    }

    // Reload to get the full row with id/timestamps
    final rule = await _database.getSyncRule(scopedGlobalKey);
    if (rule != null) {
      _syncRules[rule.globalKey] = rule;
      safeNotifyListeners();
    }
    appLogger.i('Created sync rule: $scopedGlobalKey ($targetType, filter=$downloadFilter, keep $episodeCount)');
  }

  /// Update the episode count for an existing show/season sync rule.
  Future<void> updateSyncRuleCount(String globalKey, int episodeCount) async {
    _requireActiveProfileId();
    await _database.updateSyncRuleCount(globalKey, episodeCount);
    final existing = _syncRules[globalKey];
    if (existing != null) {
      _syncRules[globalKey] = existing.copyWith(episodeCount: episodeCount);
      safeNotifyListeners();
    }
    appLogger.i('Updated sync rule $globalKey: keep $episodeCount');
  }

  /// Update the download filter for an existing collection/playlist sync rule.
  Future<void> updateSyncRuleFilter(String globalKey, String downloadFilter) async {
    _requireActiveProfileId();
    await _database.updateSyncRuleFilter(globalKey, downloadFilter);
    final existing = _syncRules[globalKey];
    if (existing != null) {
      _syncRules[globalKey] = existing.copyWith(downloadFilter: downloadFilter);
      safeNotifyListeners();
    }
    appLogger.i('Updated sync rule $globalKey: filter=$downloadFilter');
  }

  /// Toggle a sync rule's enabled state.
  Future<void> setSyncRuleEnabled(String globalKey, bool enabled) async {
    _requireActiveProfileId();
    await _database.updateSyncRuleEnabled(globalKey, enabled);
    final existing = _syncRules[globalKey];
    if (existing != null) {
      _syncRules[globalKey] = existing.copyWith(enabled: enabled);
      safeNotifyListeners();
    }
    appLogger.i('${enabled ? 'Enabled' : 'Disabled'} sync rule: $globalKey');
  }

  /// Delete a sync rule. Downloaded episodes are kept.
  Future<void> deleteSyncRule(String globalKey) async {
    _requireActiveProfileId();
    final existing = _syncRules[globalKey] ?? await _database.getSyncRule(globalKey);
    final publicGlobalKey = existing == null ? globalKey : buildGlobalKey(existing.serverId, existing.ratingKey);
    await _database.deleteSyncRule(globalKey);
    _syncRules.remove(globalKey);
    // createSyncRule may have stashed targetMetadata for collection/playlist
    // rules with no underlying download; release it if nothing else holds it.
    if (!_downloads.containsKey(publicGlobalKey)) {
      _metadata.remove(publicGlobalKey);
    }
    safeNotifyListeners();
    appLogger.i('Deleted sync rule: $globalKey');
  }

  /// Execute all sync rules: auto-delete watched + queue replacements.
  ///
  /// Pass [force] `true` from user-initiated triggers (watch-state events,
  /// offline-sync drains) to bypass the executor's cooldown. Defaults to
  /// `false` for background probes (e.g. connectivity reconnects).
  ///
  /// Returns titles of newly queued items (for snackbar display).
  Future<List<String>> executeSyncRules(MultiServerManager serverManager, {bool force = false}) async {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return [];
    if (_syncRules.isEmpty) return [];

    final results = await _syncRuleExecutor.executeSyncRules(
      profileId: profileId,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) =>
          _queueSingleDownload(episode, client, mediaIndex: mediaIndex),
      force: force,
    );

    return results.where((r) => r.queuedCount > 0).map((r) {
      final title = r.title ?? 'Unknown';
      return '$title (${r.queuedCount})';
    }).toList();
  }

  /// Execute a single sync rule immediately (eager path for `addToPlaylist` /
  /// `addToCollection`). Bypasses the cooldown.
  Future<SyncRuleResult?> executeSyncRuleFor(String globalKey, MultiServerManager serverManager) async {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return null;
    if (!_syncRules.containsKey(globalKey)) return null;

    return _syncRuleExecutor.executeSingleRule(
      profileId: profileId,
      globalKey: globalKey,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) =>
          _queueSingleDownload(episode, client, mediaIndex: mediaIndex),
    );
  }

  Future<void> _loadSyncRules() async {
    try {
      _syncRules.clear();
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) return;
      await _database.adoptLegacySyncRulesForProfile(profileId);
      if (_activeProfileId != profileId) return;
      final rules = await _database.getSyncRules(profileId: profileId);
      for (final rule in rules) {
        _syncRules[rule.globalKey] = rule;
      }
    } catch (e) {
      appLogger.w('Failed to load sync rules', error: e);
    }
  }

  Future<void> _loadDownloadOwners() async {
    try {
      _ownedDownloadKeys.clear();
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) return;
      await _database.adoptLegacyDownloadsForProfile(profileId);
      if (_activeProfileId != profileId) return;
      _ownedDownloadKeys.addAll(await _database.getDownloadOwnerKeysForProfile(profileId));
    } catch (e) {
      appLogger.w('Failed to load download ownership', error: e);
    }
  }
}

/// Exception thrown when download is blocked due to cellular-only setting
class CellularDownloadBlockedException implements Exception {
  final String message = 'Downloads are disabled on cellular data';

  @override
  String toString() => message;
}
