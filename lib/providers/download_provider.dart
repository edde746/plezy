import 'dart:async';
import '../media/ids.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_merge.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_version.dart';
import '../models/download_models.dart';
import '../utils/download_version_utils.dart';
import '../database/app_database.dart';
import '../database/download_operations.dart';
import '../services/download_manager_service.dart';
import '../services/api_cache.dart';
import '../services/download_artwork_service.dart';
import '../services/download_storage_service.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';
import '../services/watch_state_resolver.dart';
import 'watch_state_store.dart';
import '../media/media_server_client.dart';
import '../services/sync_rule_executor.dart';
import '../utils/app_logger.dart';
import '../utils/deletion_notifier.dart';
import '../utils/downloaded_version_match.dart';
import '../media/episode_collection.dart';
import '../utils/global_key_utils.dart';
import '../utils/watch_state_notifier.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

part 'download_metadata_store.dart';

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
  String? getLocalPath(DownloadStorageService storage, ServerId serverId) {
    if (thumbPath == null) return null;
    return DownloadArtworkService.localPathSync(storage, serverId, thumbPath);
  }
}

class _RelatedMetadataDownloadContext {
  final hydratedMetadataKeys = <String>{};
  final ensuredArtworkKeys = <String>{};
}

typedef _MetadataHydrationResult = ({MediaItem? metadata, bool networkFilled, bool stale});

/// Provider for managing download state and operations.
class DownloadProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  int _batchDeletionDepth = 0;
  final DownloadManagerService _downloadManager;
  final AppDatabase _database;
  final SyncRuleExecutor _syncRuleExecutor;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  StreamSubscription<DeletionProgress>? _deletionProgressSubscription;
  late final Future<void> _initFuture;

  // Track download progress by public globalKey (serverId:ratingKey).
  // Downloads are shared across profiles/users; scoped Jellyfin state lives in
  // watch actions, cache namespaces, and sync-rule ownership.
  final Map<String, DownloadProgress> _downloads = {};

  // Metadata and artwork cache lifecycle is isolated from queue ownership.
  late final _DownloadMetadataStore _metadataStore;
  Map<String, MediaItem> get _metadata => _metadataStore.items;
  Map<String, DownloadedArtwork> get _artworkPaths => _metadataStore.artworkPaths;

  // Track items currently being queued (building download queue)
  final Set<String> _queueing = {};

  // Public download keys owned by the active profile. Physical download rows
  // stay app-wide; this set controls profile-visible state.
  final Set<String> _ownedDownloadKeys = {};

  // Track items currently being deleted with progress
  final Map<String, DeletionProgress> _deletionProgress = {};

  // Persistent sync rules keyed by profile-scoped globalKey
  // (profileId|serverId:ratingKey). Downloads remain public/shared.
  final Map<String, SyncRuleItem> _syncRules = {};

  String? _activeProfileId;
  int _profileGeneration = 0;
  Future<void>? _profileScopedReloadFuture;

  OfflineModeSource? _offlineSource;

  DownloadProvider({required this._downloadManager, required this._database})
    : _syncRuleExecutor = SyncRuleExecutor(database: _database) {
    _metadataStore = _DownloadMetadataStore(_downloadManager, _database)..addListener(_onMetadataStoreChanged);
    // Listen to progress updates from the download manager
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);

    // Listen to deletion progress updates
    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);

    // Load persisted downloads from database
    _initFuture = _loadPersistedDownloads();
  }

  /// Test-only constructor that skips the heavy initial load (artwork dir,
  /// pinned-metadata bulk fetch). Only sync rules are loaded
  /// from the database. Use this in tests that exercise the provider's public
  /// database-backed API without mocking [DownloadStorageService],
  /// or path_provider.
  @visibleForTesting
  DownloadProvider.forTesting({
    required this._downloadManager,
    required this._database,
    this._activeProfileId = 'test-profile',
  }) : _syncRuleExecutor = SyncRuleExecutor(database: _database) {
    _metadataStore = _DownloadMetadataStore(_downloadManager, _database, activeProfileId: _activeProfileId)
      ..addListener(_onMetadataStoreChanged);
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);
    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);
    _initFuture = _loadProfileScopedState();
  }

  /// Inject the offline-mode source so queueing paths can short-circuit when
  /// the device has no Plex connectivity. Sync-rule execution receives a
  /// snapshot of this state when invoked, keeping this provider as the owner.
  void setOfflineSource(OfflineModeSource? source) {
    _offlineSource = source;
    _downloadManager.setOfflineSource(source);
  }

  /// Ensures persisted downloads have been loaded from disk.
  Future<void> ensureInitialized() => _initFuture;

  /// Switch the visible sync-rule scope to [profileId]. Physical downloads are
  /// intentionally not reloaded because they are shared across profiles.
  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    _metadataStore.setActiveProfileId(profileId);
    _profileGeneration++;
    final reload = _reloadProfileScopedStateForActiveProfile();
    _profileScopedReloadFuture = reload;
    unawaited(reload);
  }

  Future<void> _reloadProfileScopedStateForActiveProfile() async {
    final targetProfileId = _activeProfileId;
    final targetGeneration = _profileGeneration;
    await _initFuture;
    if (_activeProfileId != targetProfileId || _profileGeneration != targetGeneration) return;
    await _loadProfileScopedState();
    await _applyOfflineWatchOverlay(expectedProfileGeneration: targetGeneration);
    if (_activeProfileId == targetProfileId && _profileGeneration == targetGeneration) {
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

  /// Claim [globalKey] for an explicit [profileId] — sync rules claim for
  /// the RULE'S owner, not whoever is active when the pass lands, so a
  /// mid-run profile switch can't leak ownership across profiles.
  Future<bool> _claimDownloadForProfile(String globalKey, String profileId) async {
    if (_activeProfileId == profileId && _ownedDownloadKeys.contains(globalKey)) return false;
    await _database.addDownloadOwner(profileId: profileId, globalKey: globalKey);
    // _ownedDownloadKeys mirrors only the active profile's rows.
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

  /// Preserve physical downloads across a full logout while detaching them
  /// from profiles that are about to be deleted. The next selected profile
  /// adopts the ownerless rows through [_loadDownloadOwners].
  Future<void> detachDownloadsForLogout() async {
    // Invalidate any in-flight profile reload before waiting for it: an old
    // reload may still finish its DB adoption, but cannot repopulate the
    // active-profile view after this point.
    _activeProfileId = null;
    _metadataStore.setActiveProfileId(null);
    _profileGeneration++;
    await _initFuture;
    await _profileScopedReloadFuture;
    await _database.clearAllDownloadOwners();
    _ownedDownloadKeys.clear();
    _syncRules.clear();
    safeNotifyListeners();
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
    Set<String>? queueing,
    Map<String, DeletionProgress>? deletionProgress,
    Set<String>? ownedDownloadKeys,
  }) {
    if (downloads != null) _downloads.addAll(downloads);
    if (metadata != null) _metadata.addAll(metadata);
    if (artwork != null) _artworkPaths.addAll(artwork);
    if (queueing != null) _queueing.addAll(queueing);
    if (deletionProgress != null) _deletionProgress.addAll(deletionProgress);
    if (ownedDownloadKeys != null) {
      _ownedDownloadKeys.addAll(ownedDownloadKeys);
    } else if (downloads != null) {
      _ownedDownloadKeys.addAll(downloads.keys);
    }
  }

  @visibleForTesting
  Future<void> debugHydrateOfflineWatchOverlay() => _applyOfflineWatchOverlay();

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

        await _hydrateDownloadMetadata(item.globalKey, allMetadata, downloadRecord: item);
      }

      // Load sync rules from database
      await _loadProfileScopedState();

      // Apply queued offline watch actions on top of the server-time metadata
      // we just loaded, so re-entries reflect locally-marked watched/unwatched
      // state from previous sessions until those actions sync to the server.
      await _applyOfflineWatchOverlay();

      appLogger.i(
        'Loaded ${_downloads.length} downloads, ${_metadata.length} metadata entries, '
        'and ${_syncRules.length} sync rules',
      );
      safeNotifyListeners();
    } catch (e) {
      appLogger.e('Failed to load persisted downloads', error: e);
    }
  }

  /// Hydrate queued OfflineWatchProgress actions into the canonical
  /// hierarchy-aware watch-state layer.
  Future<void> _applyOfflineWatchOverlay({int? expectedProfileGeneration}) {
    return _metadataStore.hydrateOfflineWatchOverlay(
      downloads: _downloads,
      ownsDownloadKey: _ownsDownloadKey,
      isStale: expectedProfileGeneration == null
          ? null
          : () => isDisposed || expectedProfileGeneration != _profileGeneration,
    );
  }

  /// Load parent metadata (show + season for episodes, artist + album for
  /// tracks) from a pre-loaded map (no DB I/O). Used during bulk
  /// initialization to avoid per-item DB queries.
  void _loadParentMetadataFromMap(MediaItem leaf, Map<String, MediaItem> allMetadata, {String? clientScopeId}) {
    _metadataStore.loadParentMetadataFromMap(leaf, allMetadata, clientScopeId: clientScopeId);
  }

  Future<_MetadataHydrationResult> _hydrateDownloadMetadata(
    String globalKey,
    Map<String, MediaItem> allMetadata, {
    DownloadedMediaItem? downloadRecord,
    bool fetchOnMiss = false,
    bool Function()? isStale,
  }) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return (metadata: null, networkFilled: false, stale: false);

    var record = downloadRecord;
    if (record == null) {
      record = await _downloadManager.getDownloadedMedia(globalKey);
      if (isStale?.call() ?? false) return (metadata: null, networkFilled: false, stale: true);
    }

    var cached =
        allMetadata[globalKey] ??
        await _downloadManager.lookupMetadata(parsed.serverId, parsed.ratingKey, preferActiveScope: true);
    if (isStale?.call() ?? false) return (metadata: null, networkFilled: false, stale: true);

    var networkFilled = false;
    if (cached == null && fetchOnMiss && _downloads.containsKey(globalKey)) {
      cached = await _downloadManager.fetchAndPinMetadata(parsed.serverId, parsed.ratingKey, preferActiveScope: true);
      if (isStale?.call() ?? false) return (metadata: null, networkFilled: false, stale: true);
      networkFilled = cached != null;
    }

    if (cached != null) {
      _metadata[globalKey] = cached;
      if (cached.isEpisode || cached.kind == MediaKind.track) {
        _loadParentMetadataFromMap(
          cached,
          allMetadata,
          clientScopeId: _downloadManager.activeClientScopeIdForServer(parsed.serverId) ?? record?.clientScopeId,
        );
      }
    }
    return (metadata: cached, networkFilled: networkFilled, stale: false);
  }

  void _onProgressUpdate(DownloadProgress progress) {
    appLogger.d('Progress update received: ${progress.globalKey} - ${progress.status} - ${progress.progress}%');
    final ownedByActiveProfile = _ownsDownloadKey(progress.globalKey);
    _downloads[progress.globalKey] = progress;

    // Sync artwork paths when they are available.
    if (progress.hasArtworkPaths) {
      _artworkPaths[progress.globalKey] = DownloadedArtwork(thumbPath: progress.thumbPath);
    }

    if (ownedByActiveProfile) safeNotifyListeners();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _deletionProgressSubscription?.cancel();
    _metadataStore
      ..removeListener(_onMetadataStoreChanged)
      ..dispose();
    super.dispose();
  }

  void _onMetadataStoreChanged() => safeNotifyListeners();

  /// Ensure metadata has a serverId, falling back to a parent's serverId.
  MediaItem _ensureServerId(MediaItem metadata, String? fallbackServerId) =>
      metadata.serverId != null ? metadata : metadata.copyWith(serverId: fallbackServerId);

  /// All current download progress entries
  Map<String, DownloadProgress> get downloads =>
      Map.unmodifiable(Map.fromEntries(_downloads.entries.where(_ownsProgressEntry)));

  /// All metadata for downloads
  Map<String, MediaItem> get metadata => _metadataStore.resolvedItems;

  /// Get unique TV shows that have downloaded episodes
  /// Returns stored show metadata, or synthesizes from episode metadata as fallback
  List<MediaItem> get downloadedShows {
    final Map<String, MediaItem> shows = {};

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      if (!_ownsDownloadKey(globalKey)) continue;
      final meta = _metadataStore.applyWatchState(entry.value);
      final progress = _downloads[globalKey];

      if (progress?.status == DownloadStatus.completed && meta.isEpisode) {
        final showRatingKey = meta.grandparentId;
        if (showRatingKey != null && !shows.containsKey(showRatingKey)) {
          // Try to get stored show metadata first
          final showGlobalKey = buildGlobalKey(ServerId(meta.serverId!), showRatingKey);
          final storedShow = _resolvedMetadata(showGlobalKey);

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
              title: meta.grandparentTitle ?? t.common.unknown,
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
        .map((entry) => _metadataStore.applyWatchState(entry.value))
        .toList();
  }

  /// Unique albums that have completed downloaded tracks, sorted by artist
  /// then album title. Uses stored album metadata (persisted alongside each
  /// track download) and falls back to synthesizing from track fields.
  List<MediaItem> get downloadedAlbums {
    final Map<String, MediaItem> albums = {};

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      if (!_ownsDownloadKey(globalKey)) continue;
      final meta = _metadataStore.applyWatchState(entry.value);
      if (meta.kind != MediaKind.track) continue;
      if (_downloads[globalKey]?.status != DownloadStatus.completed) continue;

      final albumRatingKey = meta.parentId;
      if (albumRatingKey == null || albums.containsKey(albumRatingKey)) continue;

      final albumGlobalKey = buildGlobalKey(ServerId(meta.serverId!), albumRatingKey);
      final storedAlbum = _resolvedMetadata(albumGlobalKey);
      if (storedAlbum != null && storedAlbum.kind == MediaKind.album) {
        albums[albumRatingKey] = storedAlbum;
      } else {
        albums[albumRatingKey] = MediaItem(
          id: albumRatingKey,
          backend: meta.backend,
          kind: MediaKind.album,
          title: meta.albumTitle ?? t.common.unknown,
          parentId: meta.grandparentId,
          parentTitle: meta.grandparentTitle,
          thumbPath: meta.parentThumbPath ?? meta.thumbPath,
          serverId: meta.serverId,
        );
      }
    }

    final list = albums.values.toList();
    list.sort((a, b) {
      final byArtist = (a.albumArtistTitle ?? '').compareTo(b.albumArtistTitle ?? '');
      if (byArtist != 0) return byArtist;
      return (a.title ?? '').compareTo(b.title ?? '');
    });
    return list;
  }

  /// Completed downloaded tracks of an album, sorted by disc then track
  /// number — the offline playback queue for that album.
  List<MediaItem> getDownloadedTracksForAlbum(String albumRatingKey) {
    final tracks = _metadata.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final meta = entry.value;
          return meta.kind == MediaKind.track &&
              meta.parentId == albumRatingKey &&
              _downloads[entry.key]?.status == DownloadStatus.completed;
        })
        .map((entry) => _metadataStore.applyWatchState(entry.value))
        .toList();
    tracks.sort((a, b) {
      final byDisc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
      if (byDisc != 0) return byDisc;
      return (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
    });
    return tracks;
  }

  /// Get metadata for a specific download
  MediaItem? _resolvedMetadata(String globalKey) => _metadataStore.resolved(globalKey);

  MediaItem? getMetadata(String globalKey) => _resolvedMetadata(globalKey);

  /// Get artwork paths for a specific download (for offline display)
  DownloadedArtwork? getArtworkPaths(String globalKey) => _artworkPaths[globalKey];

  /// Get local file path for any artwork type (thumb, art, clearLogo, etc.)
  /// Returns null if artwork directory isn't initialized or artworkPath is null
  String? getArtworkLocalPath(ServerId serverId, String? artworkPath) {
    if (artworkPath == null) return null;
    return DownloadArtworkService.localPathSync(DownloadStorageService.instance, serverId, artworkPath);
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
        .map((entry) => _metadataStore.applyWatchState(entry.value))
        .toList();
  }

  /// Get leaf downloads (episodes or tracks) filtered by grandparent
  /// (show/artist) and/or parent (season/album) ratingKey.
  List<DownloadProgress> _getLeafDownloads({String? grandparentRatingKey, String? parentRatingKey}) {
    return _downloads.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final meta = _metadata[entry.key];
          if (meta == null || !(meta.isEpisode || meta.kind == MediaKind.track)) return false;
          if (grandparentRatingKey != null && meta.grandparentId != grandparentRatingKey) return false;
          if (parentRatingKey != null && meta.parentId != parentRatingKey) return false;
          return true;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Calculate aggregate progress for a show (based on all its episodes)
  /// Returns synthetic DownloadProgress with aggregated values
  DownloadProgress? getAggregateProgressForShow(ServerId serverId, String showRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: showRatingKey,
      episodes: _getLeafDownloads(grandparentRatingKey: showRatingKey),
      entityType: 'show',
    );
  }

  /// Calculate aggregate progress for a season (based on all its episodes)
  /// Returns synthetic DownloadProgress with aggregated values
  DownloadProgress? getAggregateProgressForSeason(ServerId serverId, String seasonRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: seasonRatingKey,
      episodes: _getLeafDownloads(parentRatingKey: seasonRatingKey),
      entityType: 'season',
    );
  }

  /// Aggregate progress for an album (parent of its tracks).
  DownloadProgress? getAggregateProgressForAlbum(ServerId serverId, String albumRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: albumRatingKey,
      episodes: _getLeafDownloads(parentRatingKey: albumRatingKey),
      entityType: 'album',
    );
  }

  /// Aggregate progress for an artist (grandparent of its tracks).
  DownloadProgress? getAggregateProgressForArtist(ServerId serverId, String artistRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: artistRatingKey,
      episodes: _getLeafDownloads(grandparentRatingKey: artistRatingKey),
      entityType: 'artist',
    );
  }

  /// Shared helper to calculate aggregate download progress for shows/seasons
  DownloadProgress? _calculateAggregateProgress({
    required ServerId serverId,
    required String ratingKey,
    required List<DownloadProgress> episodes,
    required String entityType,
  }) {
    final globalKey = buildGlobalKey(ServerId(serverId), ratingKey);

    // The progress ring reflects only the episodes the user actually queued for
    // this show/season — not the show's full episode count. _getEpisodeDownloads
    // returns just the owned download records, so episodes.length IS the queued
    // count. Downloading 5 of a 50-episode show therefore reaches 100% at 5/5.
    //
    final int totalEpisodes = episodes.length;

    if (totalEpisodes == 0) {
      appLogger.d('⚠️  No queued downloads for $entityType $ratingKey, returning null');
      return null;
    }

    // Calculate aggregate statistics
    int completedCount = 0;
    int downloadingCount = 0;
    int queuedCount = 0;
    int failedCount = 0;
    int summedProgress = 0; // sum of per-episode progress (completed counts as 100)

    for (final ep in episodes) {
      summedProgress += ep.status == DownloadStatus.completed ? 100 : ep.progress;
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

    // Smooth percentage across the queued episodes: an in-flight episode
    // contributes its partial progress so the ring advances continuously,
    // rather than jumping only when whole episodes complete. Cap below 100%
    // until every episode is actually complete — otherwise rounding (e.g.
    // 99.8 → 100) could fill the ring while a download is still finishing.
    final int rawProgress = (summedProgress / totalEpisodes).round();
    final int overallProgress = completedCount == totalEpisodes ? 100 : (rawProgress > 99 ? 99 : rawProgress);

    appLogger.d(
      'Aggregate progress for $entityType $ratingKey: $overallProgress% '
      '($completedCount completed, $downloadingCount downloading, '
      '$queuedCount queued of $totalEpisodes total) - Status: $overallStatus',
    );

    final leafNoun = entityType == 'album' || entityType == 'artist' ? 'tracks' : 'episodes';
    return DownloadProgress(
      globalKey: globalKey,
      status: overallStatus,
      progress: overallProgress,
      downloadedBytes: 0,
      totalBytes: 0,
      currentFile: '$completedCount/$totalEpisodes $leafNoun',
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
      // No metadata stored yet, might be a container (show/season/artist/
      // album) being queued. Check if any leaves exist for this as a parent —
      // the aggregate helpers are kind-agnostic over grandparent/parent keys.
      final leavesAsGrandparent = _getLeafDownloads(grandparentRatingKey: ratingKey);
      if (leavesAsGrandparent.isNotEmpty) {
        return getAggregateProgressForShow(serverId, ratingKey);
      }

      final leavesAsParent = _getLeafDownloads(parentRatingKey: ratingKey);
      if (leavesAsParent.isNotEmpty) {
        return getAggregateProgressForSeason(serverId, ratingKey);
      }

      return null;
    }

    // We have metadata, check kind
    return switch (meta.kind) {
      MediaKind.show => getAggregateProgressForShow(serverId, ratingKey),
      MediaKind.season => getAggregateProgressForSeason(serverId, ratingKey),
      MediaKind.album => getAggregateProgressForAlbum(serverId, ratingKey),
      MediaKind.artist => getAggregateProgressForArtist(serverId, ratingKey),
      _ => null,
    };
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

  /// Get the completed download record for an item, or null when the item
  /// isn't fully downloaded or isn't owned by the active profile. Callers use
  /// the row's mediaIndex/mediaSourceId to target the version actually on
  /// disk instead of assuming the server default.
  Future<DownloadedMediaItem?> getCompletedDownload(String globalKey) async {
    if (!_ownsDownloadKey(globalKey)) return null;
    final downloadedItem = await _downloadManager.getDownloadedMedia(globalKey);
    if (downloadedItem == null || downloadedItem.status != DownloadStatus.completed.index) {
      return null;
    }
    return downloadedItem;
  }

  /// Get the local video file path for a downloaded item
  /// Returns null if not downloaded or file doesn't exist
  Future<String?> getVideoFilePath(String globalKey, {int? mediaIndex, String? mediaSourceId}) async {
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
    if (!downloadedVersionMatches(
      downloadedItem,
      requestedMediaIndex: mediaIndex,
      requestedMediaSourceId: mediaSourceId,
    )) {
      appLogger.w(
        'Downloaded version mismatch for $globalKey: have index ${downloadedItem.mediaIndex} '
        '(source ${downloadedItem.mediaSourceId}), expected index $mediaIndex '
        '(source ${mediaSourceId?.trim()})',
      );
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
  /// For movies, episodes, and tracks, queues directly.
  /// For shows and seasons, fetches all child episodes and queues them.
  /// For albums and artists, fetches all child tracks and queues them.
  /// Returns the number of items queued.
  Future<int> queueDownload(
    MediaItem metadata,
    MediaServerClient client, {
    DownloadVersionConfig? versionConfig,
    DownloadFilter filter = DownloadFilter.all,
    int? maxCount,
    bool includeSpecials = true,
  }) async {
    if (!_downloadManager.downloadsSupported) return 0;

    final globalKey = metadata.globalKey;
    final config = versionConfig ?? DownloadVersionConfig();
    if (!_queueing.add(globalKey)) return 0;
    safeNotifyListeners();

    try {
      // Claim the operation before the first await so a second tap cannot
      // launch a duplicate container expansion.
      if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
        throw CellularDownloadBlockedException();
      }

      if (metadata.isMovie || metadata.isEpisode || metadata.kind == MediaKind.track) {
        final queued = await _queueSingleDownload(metadata, client, mediaIndex: config.mediaIndex);
        return queued ? 1 : 0;
      } else if (metadata.kind == MediaKind.album || metadata.kind == MediaKind.artist) {
        return await _withStashedMetadata(metadata, () => _queueMusicContainerDownload(metadata, client));
      } else if (metadata.isShow || metadata.isSeason) {
        return await _withStashedMetadata(
          metadata,
          () => _expandAndQueue(
            container: metadata,
            client: client,
            versionConfig: config,
            filter: filter,
            maxCount: maxCount,
            skipExisting: false,
            includeSpecials: includeSpecials,
          ),
        );
      } else {
        throw Exception('Cannot download ${metadata.kind.id}');
      }
    } finally {
      _queueing.remove(globalKey);
      safeNotifyListeners();
    }
  }

  Future<T> _withStashedMetadata<T>(MediaItem metadata, Future<T> Function() operation) async {
    final globalKey = metadata.globalKey;
    final previous = _metadata[globalKey];
    _metadata[globalKey] = metadata;
    try {
      return await operation();
    } catch (_) {
      if (previous == null) {
        _metadata.remove(globalKey);
      } else {
        _metadata[globalKey] = previous;
      }
      rethrow;
    }
  }

  /// Queue every playable item from a collection/playlist for download.
  ///
  /// Movies, episodes, and tracks are queued directly. Shows and seasons are
  /// expanded into their episodes and albums/artists into their tracks (when
  /// [expandShows] is true). Nested collections/playlists and unknown types
  /// are skipped.
  Future<int> queueListDownload(
    List<MediaItem> items,
    MediaServerClient client, {
    DownloadFilter filter = DownloadFilter.all,
    bool expandShows = true,
  }) async {
    if (!_downloadManager.downloadsSupported) return 0;

    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      throw CellularDownloadBlockedException();
    }

    final unwatchedOnly = filter == DownloadFilter.unwatched;
    final relatedContext = _RelatedMetadataDownloadContext();
    int count = 0;

    Future<void> queueItem(MediaItem item) async {
      if (unwatchedOnly && !item.isUnwatchedOrInProgress) return;
      final queued = await _queueSingleDownload(item, client, relatedContext: relatedContext);
      if (queued) count++;
    }

    for (final item in items) {
      if (item.isMovie || item.isEpisode || item.kind == MediaKind.track) {
        await queueItem(item);
      } else if (item.isShow || item.isSeason) {
        if (!expandShows) continue;
        // One-shot recursive expansion for both shows and seasons.
        final episodes = <MediaItem>[];
        await collectEpisodes(client, item.id, unwatchedOnly: unwatchedOnly, out: episodes, fallback: item);
        for (final ep in episodes) {
          await queueItem(ep);
        }
      } else if (item.kind == MediaKind.album || item.kind == MediaKind.artist) {
        if (!expandShows) continue;
        // Same one-shot expansion for music containers (album/artist →
        // tracks) via the shared recursive-leaves call.
        for (final track in await client.fetchPlayableDescendants(item.id)) {
          await queueItem(_ensureServerId(track, item.serverId));
        }
      } else {
        // Skip clips, nested collections/playlists, unknown types.
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
    _RelatedMetadataDownloadContext? relatedContext,
    String? claimForProfileId,
  }) async {
    if (!_downloadManager.downloadsSupported) return false;

    final ownerProfileId = claimForProfileId ?? _requireActiveProfileId();
    var metadataToStore = metadata.serverId == null ? metadata.copyWith(serverId: client.serverId) : metadata;
    final globalKey = metadataToStore.globalKey;

    // Don't duplicate the physical download. If another profile already owns
    // the shared row, claiming it makes it visible for the owning profile.
    if (_downloads.containsKey(globalKey)) {
      final existing = _downloads[globalKey]!;
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.completed ||
          existing.status == DownloadStatus.queued ||
          existing.status == DownloadStatus.paused) {
        final claimed = await _claimDownloadForProfile(globalKey, ownerProfileId);
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
    if (_offlineSource?.isOffline ?? false) {
      appLogger.d('Offline — using partial metadata for ${metadata.id}');
    } else {
      try {
        final fullMetadata = await client.fetchItem(metadata.id);
        if (fullMetadata != null) {
          metadataToStore = mergeFetchedMediaItem(
            fetched: fullMetadata,
            existing: metadataToStore,
            fallbackServerId: client.serverId,
          );
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

    // For episodes (show + season) and tracks (artist + album), also fetch
    // and store parent metadata for offline display.
    if (metadataToStore.isEpisode || metadataToStore.kind == MediaKind.track) {
      await _fetchAndStoreParentMetadata(
        metadataToStore,
        client,
        context: relatedContext ?? _RelatedMetadataDownloadContext(),
      );
    }

    // Store full metadata for display
    _metadata[globalKey] = metadataToStore;

    await _claimDownloadForProfile(globalKey, ownerProfileId);

    // Update local state immediately for UI feedback
    _downloads[globalKey] = DownloadProgress(globalKey: globalKey, status: DownloadStatus.queued);
    safeNotifyListeners();

    // Actually trigger download via DownloadManagerService
    await _downloadManager.queueDownload(metadata: metadataToStore, client: client, mediaIndex: resolvedIndex);
    return true;
  }

  /// Fetch and store parent metadata for a leaf item — show + season for an
  /// episode, artist + album for a track (same grandparent/parent fields).
  /// Also downloads the parents' artwork.
  Future<void> _fetchAndStoreParentMetadata(
    MediaItem leaf,
    MediaServerClient client, {
    required _RelatedMetadataDownloadContext context,
  }) async {
    final serverId = leaf.serverId;
    if (serverId == null) return;

    await _fetchAndStoreRelatedMetadata(
      serverId: ServerId(serverId),
      ratingKey: leaf.grandparentId,
      client: client,
      context: context,
    );
    await _fetchAndStoreRelatedMetadata(
      serverId: ServerId(serverId),
      ratingKey: leaf.parentId,
      client: client,
      context: context,
    );
  }

  /// Fetch, persist, and download artwork for a related metadata item (show or season).
  Future<void> _fetchAndStoreRelatedMetadata({
    required ServerId serverId,
    required String? ratingKey,
    required MediaServerClient client,
    required _RelatedMetadataDownloadContext context,
  }) async {
    if (ratingKey == null) return;
    final globalKey = buildGlobalKey(ServerId(serverId), ratingKey);

    MediaItem? metadata = _metadata[globalKey];
    var fetchedFreshMetadata = false;
    if (!(_offlineSource?.isOffline ?? false) && !context.hydratedMetadataKeys.contains(globalKey)) {
      try {
        final fetched = await client.fetchItem(ratingKey);
        if (fetched != null) {
          metadata = mergeFetchedMediaItem(fetched: fetched, existing: metadata, fallbackServerId: serverId);
          context.hydratedMetadataKeys.add(globalKey);
          fetchedFreshMetadata = true;
        }
      } catch (e) {
        appLogger.w('Failed to fetch metadata for $ratingKey', error: e);
      }
    }
    if (metadata == null) return;

    final withServer = metadata.copyWith(serverId: serverId);
    _metadata[globalKey] = withServer;
    await _downloadManager.saveMetadata(withServer, client);

    final thumbPath = withServer.thumbPath;
    if (fetchedFreshMetadata || context.ensuredArtworkKeys.add(globalKey)) {
      await _downloadManager.downloadArtworkForMetadata(withServer, client);
    }
    _artworkPaths[globalKey] = DownloadedArtwork(thumbPath: thumbPath);
  }

  /// Queue every track under an album/artist. Expansion is one
  /// recursive-leaves call ([MediaServerClient.fetchPlayableDescendants]) on
  /// both backends — Plex branches album→/children, Jellyfin retries
  /// tag-only artists by album-artist credit.
  Future<int> _queueMusicContainerDownload(MediaItem container, MediaServerClient client) async {
    final tracks = await client.fetchPlayableDescendants(container.id);
    final relatedContext = _RelatedMetadataDownloadContext();
    int count = 0;
    for (final track in tracks) {
      final trackWithServer = _ensureServerId(track, container.serverId);
      final queued = await _queueSingleDownload(trackWithServer, client, relatedContext: relatedContext);
      if (queued) count++;
    }
    return count;
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
    bool includeSpecials = true,
  }) async {
    final unwatchedOnly = filter == DownloadFilter.unwatched;
    // Downloading the Specials season itself must still queue its episodes —
    // only suppress Specials when sweeping a whole show or a regular season.
    final effectiveIncludeSpecials =
        includeSpecials || (container.kind == MediaKind.season && isSpecialSeasonNumber(container.index));
    final relatedContext = _RelatedMetadataDownloadContext();
    final episodes = <MediaItem>[];
    await collectEpisodes(
      client,
      container.id,
      unwatchedOnly: unwatchedOnly,
      out: episodes,
      fallback: container,
      includeSpecials: effectiveIncludeSpecials,
    );

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

      final queued = await _queueSingleDownload(
        episodeWithServer,
        client,
        versionConfig: versionConfig,
        relatedContext: relatedContext,
      );
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
      }
      if (removedMeta != null) {
        DeletionNotifier().notifyDeletedItem(item: removedMeta, isDownloadOnly: true);
      } else if (!released) {
        return;
      }
      safeNotifyListeners();
    }
  }

  /// Delete a downloaded item.
  Future<void> deleteDownload(String globalKey) => _deleteDownload(globalKey, notify: true);

  Future<void> _deleteDownload(String globalKey, {required bool notify}) async {
    try {
      final meta = _metadata[globalKey];
      if (meta != null &&
          (meta.isShow || meta.isSeason || meta.kind == MediaKind.album || meta.kind == MediaKind.artist)) {
        await _deleteOwnedContainerDownloads(globalKey, meta);
        return;
      }
      if (!_ownsDownloadKey(globalKey)) return;

      final released = await _releaseDownloadForActiveProfile(globalKey);
      final hasOtherOwners = await _database.hasDownloadOwner(globalKey);
      if (hasOtherOwners) {
        if (notify && meta != null) {
          DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
        }
        if (notify && released) safeNotifyListeners();
        return;
      }

      await _downloadManager.deleteDownload(globalKey);
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      _artworkPaths.remove(globalKey);

      if (notify && meta != null) {
        DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
      }
      if (notify) safeNotifyListeners();
    } catch (e) {
      _deletionProgress.remove(globalKey);
      if (notify) safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> _deleteOwnedContainerDownloads(String globalKey, MediaItem container) async {
    final descendants = _ownedDescendantEntries(container).toList();
    _batchDeletionDepth++;
    try {
      for (final entry in descendants) {
        await _deleteDownload(entry.key, notify: false);
        DeletionNotifier().notifyDeletedItem(item: entry.value, isDownloadOnly: true);
      }
    } finally {
      _batchDeletionDepth--;
    }

    DeletionNotifier().notifyDeletedItem(item: container, isDownloadOnly: true);
    safeNotifyListeners();
  }

  Iterable<MapEntry<String, MediaItem>> _ownedDescendantEntries(MediaItem container) {
    // Shows and artists are grandparents of their leaves; seasons and albums
    // are direct parents.
    final matchesGrandparent = container.isShow || container.kind == MediaKind.artist;
    return _metadata.entries.where((entry) {
      if (!_ownsDownloadKey(entry.key)) return false;
      final meta = entry.value;
      if (meta.serverId != container.serverId) return false;
      return matchesGrandparent
          ? (meta.grandparentId == container.id || meta.parentId == container.id)
          : meta.parentId == container.id;
    });
  }

  /// Handle deletion progress updates.
  void _onDeletionProgressUpdate(DeletionProgress progress) {
    if (progress.isComplete) {
      _deletionProgress.remove(progress.globalKey);
    } else {
      _deletionProgress[progress.globalKey] = progress;
    }
    if (_batchDeletionDepth == 0 && _ownsDownloadKey(progress.globalKey)) {
      safeNotifyListeners();
    }
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
    if (!_downloadManager.downloadsSupported) return;
    _downloadManager.resumeQueuedDownloads(client);
  }

  /// Backend-aware metadata lookup for offline UI. Routes through
  /// [DownloadManagerService] which dispatches to [PlexApiCache] or
  /// [JellyfinApiCache] based on the connection's `kind`.
  Future<MediaItem?> lookupOfflineMetadata(ServerId serverId, String itemId) =>
      _downloadManager.lookupMetadata(serverId, itemId);

  /// Refresh only metadata from API cache (after watch state sync).
  ///
  /// This is more lightweight than full refresh() - only updates metadata
  /// without reloading download progress from database.
  Future<void> refreshMetadataFromCache() async {
    final profileGeneration = _profileGeneration;
    bool isStale() => isDisposed || profileGeneration != _profileGeneration;
    // The initial load runs in the constructor and may still be in flight
    // when callers (e.g. `onServersConnected`) trigger this. Wait for it so
    // `_downloads` is populated before we walk it — otherwise an early call
    // sees an empty map and does nothing useful.
    await ensureInitialized();
    if (isStale()) return;

    // Walk every download — not just keys we already have metadata for. The
    // initial `_loadPersistedDownloads` may have raced with connection setup
    // (Jellyfin's cache reads need a [Connections] row) and skipped entries;
    // this lets a later refresh actually populate them.
    final keys = <String>{..._metadata.keys, ..._downloads.keys};
    if (keys.isEmpty) return;

    final allMetadata = await _downloadManager.getAllPinnedMetadata(preferActiveScope: true);
    if (isStale()) return;
    int cacheHits = 0;
    int networkFills = 0;
    int misses = 0;

    for (final globalKey in keys) {
      try {
        final result = await _hydrateDownloadMetadata(globalKey, allMetadata, fetchOnMiss: true, isStale: isStale);
        if (result.stale) return;
        if (result.metadata == null) {
          misses++;
        } else if (result.networkFilled) {
          networkFills++;
        } else {
          cacheHits++;
        }
      } catch (e) {
        appLogger.d('Failed to refresh metadata for $globalKey: $e');
      }
    }

    // Re-apply offline overlay so locally-queued watch actions aren't clobbered
    // by stale per-backend caches that haven't yet seen the server roundtrip.
    await _applyOfflineWatchOverlay(expectedProfileGeneration: profileGeneration);
    if (isStale()) return;

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
      final meta = _resolvedMetadata(globalKey);
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

  /// All sync rules for the active profile (profile-scoped globalKey -> SyncRuleItem).
  Map<String, SyncRuleItem> get syncRules => Map.unmodifiable(_syncRules);

  String syncRuleKeyFor(ServerId serverId, String ratingKey, {String? profileId}) {
    final owner = profileId ?? _activeProfileId;
    if (owner == null || owner.isEmpty) return buildGlobalKey(ServerId(serverId), ratingKey);
    return buildProfileScopedGlobalKey(owner, ServerId(serverId), ratingKey);
  }

  String syncRuleKeyForClient(MediaServerClient client, String ratingKey, {ServerId? serverId}) {
    return syncRuleKeyFor(serverId ?? client.serverId, ratingKey);
  }

  /// Candidate active-profile sync-rule keys touched by a watched item event.
  Set<String> syncRuleKeysForWatchEvent(WatchStateEvent event) {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return const {};
    final keys = <String>{};
    void add(String ratingKey) {
      keys.add(syncRuleKeyFor(ServerId(event.serverId), ratingKey, profileId: profileId));
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
    required ServerId serverId,
    required String ratingKey,
    required String targetType,
    required int episodeCount,
    int mediaIndex = 0,
    String downloadFilter = SyncRuleFilter.unwatched,
    bool includeSpecials = true,
    MediaItem? targetMetadata,
  }) async {
    final profileId = _requireActiveProfileId();
    final publicGlobalKey = buildGlobalKey(ServerId(serverId), ratingKey);
    final scopedGlobalKey = syncRuleKeyFor(ServerId(serverId), ratingKey, profileId: profileId);
    await _database.insertSyncRule(
      profileId: profileId,
      serverId: serverId,
      ratingKey: ratingKey,
      globalKey: scopedGlobalKey,
      targetType: targetType,
      episodeCount: episodeCount,
      mediaIndex: mediaIndex,
      downloadFilter: downloadFilter,
      includeSpecials: includeSpecials,
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
    appLogger.i(
      'Created sync rule: $scopedGlobalKey '
      '($targetType, filter=$downloadFilter, keep $episodeCount, includeSpecials=$includeSpecials)',
    );
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
    final publicGlobalKey = existing == null
        ? globalKey
        : buildGlobalKey(ServerId(existing.serverId), existing.ratingKey);
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
    if (!_downloadManager.downloadsSupported) return [];

    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return [];
    if (_syncRules.isEmpty) return [];

    final relatedContext = _RelatedMetadataDownloadContext();
    final results = await _syncRuleExecutor.executeSyncRules(
      profileId: profileId,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) async {
        // A profile switch mid-pass must not keep queueing the old
        // profile's rules; whatever does get queued is claimed for the
        // rule's owner, never the new active profile.
        if (_activeProfileId != profileId) return false;
        return _queueSingleDownload(
          episode,
          client,
          mediaIndex: mediaIndex,
          relatedContext: relatedContext,
          claimForProfileId: profileId,
        );
      },
      isOffline: _offlineSource?.isOffline ?? false,
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
    if (!_downloadManager.downloadsSupported) return null;

    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return null;
    if (!_syncRules.containsKey(globalKey)) return null;

    final relatedContext = _RelatedMetadataDownloadContext();
    return _syncRuleExecutor.executeSingleRule(
      profileId: profileId,
      globalKey: globalKey,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) async {
        if (_activeProfileId != profileId) return false;
        return _queueSingleDownload(
          episode,
          client,
          mediaIndex: mediaIndex,
          relatedContext: relatedContext,
          claimForProfileId: profileId,
        );
      },
      isOffline: _offlineSource?.isOffline ?? false,
    );
  }

  Future<void> _loadSyncRules() async {
    try {
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) {
        _syncRules.clear();
        return;
      }
      await _database.adoptLegacySyncRulesForProfile(profileId);
      if (_activeProfileId != profileId) return;
      final rules = await _database.getSyncRules(profileId: profileId);
      if (_activeProfileId != profileId) return;
      _syncRules
        ..clear()
        ..addEntries(rules.map((rule) => MapEntry(rule.globalKey, rule)));
    } catch (e) {
      appLogger.w('Failed to load sync rules', error: e);
    }
  }

  Future<void> _loadDownloadOwners() async {
    try {
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) {
        _ownedDownloadKeys.clear();
        return;
      }
      await _database.adoptLegacyDownloadsForProfile(profileId);
      if (_activeProfileId != profileId) return;
      final ownedKeys = await _database.getDownloadOwnerKeysForProfile(profileId);
      if (_activeProfileId != profileId) return;
      _ownedDownloadKeys
        ..clear()
        ..addAll(ownedKeys);
    } catch (e) {
      appLogger.w('Failed to load download ownership', error: e);
    }
  }
}

/// Exception thrown when download is blocked due to cellular-only setting
class CellularDownloadBlockedException implements Exception {
  String get message => t.settings.cellularDownloadBlocked;

  @override
  String toString() => message;
}
