import 'dart:async';
import '../media/ids.dart';
import 'package:flutter/foundation.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_merge.dart';
import '../media/media_item_sort.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_version.dart';
import '../models/download_models.dart';
import '../utils/download_version_utils.dart';
import '../database/app_database.dart';
import '../database/download_operations.dart';
import '../services/background_work_diagnostics_service.dart';
import '../services/download_manager_service.dart';
import '../services/api_cache.dart';
import '../services/download_artwork_service.dart';
import '../services/download_storage_service.dart';
import '../services/downloaded_video_source.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';
import '../services/watch_state_resolver.dart';
import 'watch_state_store.dart';
import '../media/media_server_client.dart';
import '../services/sync_rule_executor.dart';
import '../utils/app_logger.dart';
import '../utils/deletion_notifier.dart';
import '../media/episode_collection.dart';
import '../utils/global_key_utils.dart';
import '../utils/content_utils.dart';
import '../utils/notification_permission.dart';
import '../utils/watch_state_notifier.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

part 'download_metadata_store.dart';

typedef _QueueOwnership = ({String profileId, int generation});

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
  final Map<String, _QueueOwnership> _queueing = {};

  // Public download keys owned by the active profile. Physical download rows
  // stay app-wide; this set controls profile-visible state.
  final Set<String> _ownedDownloadKeys = {};

  /// Library identity stamped on each `downloaded_media` row at enqueue time,
  /// keyed by globalKey. Hydrated items merge it in when their own fields are
  /// null, so rows enqueued before v23 (or while offline) still surface a
  /// library once metadata carries one.
  final Map<String, ({String? libraryId, String? libraryTitle})> _downloadLibraries = {};

  // Track items currently being deleted with progress
  final Map<String, DeletionProgress> _deletionProgress = {};

  // Persistent sync rules keyed by profile-scoped globalKey
  // (profileId|serverId:ratingKey). Downloads remain public/shared.
  final Map<String, SyncRuleItem> _syncRules = {};
  final Set<String> _removingSyncRuleKeys = {};
  bool _syncRuleCleanupInProgress = false;

  String? _activeProfileId;
  int _profileGeneration = 0;
  Future<void>? _profileScopedReloadFuture;

  _QueueOwnership _captureQueueOwnership() => (profileId: _requireActiveProfileId(), generation: _profileGeneration);

  bool _isQueueOwnershipCurrent(_QueueOwnership ownership) =>
      _activeProfileId == ownership.profileId && _profileGeneration == ownership.generation;

  OfflineModeSource? _offlineSource;
  int _networkStateGeneration = 0;

  DownloadProvider({required this._downloadManager, required this._database})
    : _syncRuleExecutor = SyncRuleExecutor(database: _database) {
    _metadataStore = _DownloadMetadataStore(_downloadManager, _database)..addListener(_onMetadataStoreChanged);
    _progressSubscription = _downloadManager.progressStream.listen(_onProgressUpdate);

    _deletionProgressSubscription = _downloadManager.deletionProgressStream.listen(_onDeletionProgressUpdate);

    _initFuture = _loadPersistedDownloads();

    // Lets the diagnostics service score whether downloads actually advance
    // while the app is backgrounded, without it reaching into providers.
    BackgroundWorkDiagnosticsService.instance.bindActivitySource(downloadActivitySnapshot);
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
    if (!identical(_offlineSource, source)) {
      _offlineSource?.removeListener(_onOfflineSourceChanged);
      _offlineSource = source;
      _offlineSource?.addListener(_onOfflineSourceChanged);
      _networkStateGeneration++;
    }
    _downloadManager.setOfflineSource(source);
  }

  /// Ensures persisted downloads have been loaded from disk.
  Future<void> ensureInitialized() => _initFuture;

  Future<void> setDownloadLocation({required String path, required String pathType, void Function()? checkCurrent}) {
    return _downloadManager.setDownloadLocation(path: path, pathType: pathType, checkCurrent: checkCurrent);
  }

  Future<void> resetDownloadLocation({void Function()? checkCurrent}) {
    return _downloadManager.resetDownloadLocation(checkCurrent: checkCurrent);
  }

  /// Switch the visible sync-rule scope to [profileId]. Physical downloads are
  /// intentionally not reloaded because they are shared across profiles.
  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _profileGeneration++;
    _queueing.clear();
    _ownedDownloadKeys.clear();
    _syncRules.clear();
    _metadata.clear();
    _activeProfileId = profileId;
    _metadataStore.setActiveProfileId(profileId);
    safeNotifyListeners();
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
    await refreshMetadataFromCache();
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
  Future<bool> _claimDownloadForProfile(String globalKey, _QueueOwnership ownership, MediaServerClient client) async {
    if (!_isQueueOwnershipCurrent(ownership)) return false;
    if (_ownedDownloadKeys.contains(globalKey)) return false;
    await _database.addDownloadOwner(
      profileId: ownership.profileId,
      globalKey: globalKey,
      backendId: client.backend.id,
      clientScopeId: client.cacheServerId,
    );
    if (!_isQueueOwnershipCurrent(ownership)) return false;
    _ownedDownloadKeys.add(globalKey);
    return true;
  }

  Future<bool> _releaseDownloadForProfile(
    String globalKey,
    String profileId, {
    bool onlyIfShared = false,
    DownloadOwnerItem? ownerHint,
  }) async {
    DownloadOwnerItem? owner = ownerHint;
    if (onlyIfShared) {
      // Capture the departing cache namespace before the atomic database
      // release; the ownership row is gone by the time cache cleanup runs.
      owner ??= await _database.getDownloadOwner(profileId: profileId, globalKey: globalKey);
      final result = await _database.removeSharedDownloadOwnerAndRebindIncompleteMedia(
        profileId: profileId,
        globalKey: globalKey,
      );
      if (!result.hasRemainingOwner) return false;
      owner = result.removedOwner ?? owner;
    } else {
      owner ??= await _database.getDownloadOwner(profileId: profileId, globalKey: globalKey);
      await _database.removeDownloadOwner(profileId: profileId, globalKey: globalKey);
    }

    final parsed = parseGlobalKey(globalKey);
    if (parsed != null && owner != null) {
      await _downloadManager.deleteMetadataForOwner(
        globalKey: globalKey,
        serverId: parsed.serverId,
        itemId: parsed.ratingKey,
        profileId: profileId,
        backendId: owner.backend,
        clientScopeId: owner.clientScopeId,
      );
    }
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
    await _downloadManager.preparePlexMetadataForLogoutTransfer();
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
      final releasedAsShared = await _releaseDownloadForProfile(globalKey, profileId, onlyIfShared: true);
      if (releasedAsShared) {
        changed = true;
        continue;
      }

      // Keep the final durable owner until physical deletion succeeds. A
      // retry can then resume cleanup without orphaning the shared row.
      final finalOwner = await _database.getDownloadOwner(profileId: profileId, globalKey: globalKey);
      await _downloadManager.deleteDownload(globalKey);
      await _releaseDownloadForProfile(globalKey, profileId, ownerHint: finalOwner);
      _downloads.remove(globalKey);
      _metadata.remove(globalKey);
      _artworkPaths.remove(globalKey);
      _downloadLibraries.remove(globalKey);
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
    Map<String, ({String? libraryId, String? libraryTitle})>? downloadLibraries,
  }) {
    if (downloads != null) _downloads.addAll(downloads);
    if (metadata != null) _metadata.addAll(metadata);
    if (artwork != null) _artworkPaths.addAll(artwork);
    if (downloadLibraries != null) _downloadLibraries.addAll(downloadLibraries);
    if (queueing != null) {
      final ownership = _captureQueueOwnership();
      for (final globalKey in queueing) {
        _queueing[globalKey] = ownership;
      }
    }
    if (deletionProgress != null) _deletionProgress.addAll(deletionProgress);
    if (ownedDownloadKeys != null) {
      _ownedDownloadKeys.addAll(ownedDownloadKeys);
    } else if (downloads != null) {
      _ownedDownloadKeys.addAll(downloads.keys);
    }
  }

  @visibleForTesting
  Future<void> debugHydrateOfflineWatchOverlay() => _applyOfflineWatchOverlay();

  @visibleForTesting
  Future<void> debugWaitForProfileScopedReload() async {
    await _profileScopedReloadFuture;
  }

  @visibleForTesting
  Future<void> debugWaitForWatchStateWrites() => _metadataStore.waitForWatchStateWrites();

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
      _downloadLibraries.clear();
      await _loadDownloadOwners();

      final storageService = DownloadStorageService.instance;

      // Initialize artwork directory path for synchronous access
      await storageService.getArtworkDirectory();

      final downloads = await _downloadManager.getAllDownloads();

      // Bulk-load all pinned metadata across every backend in a single pass
      // instead of per-item DB calls.
      final pinned = await _downloadManager.getAllPinnedMetadata(activeProfileId: _activeProfileId);

      for (final item in downloads) {
        _downloads[item.globalKey] = DownloadProgress(
          globalKey: item.globalKey,
          status: DownloadStatus.values[item.status],
          progress: item.progress,
          downloadedBytes: item.downloadedBytes,
          totalBytes: item.totalBytes ?? 0,
          errorMessage: item.errorMessage,
          downloadedAt: item.downloadedAt,
        );

        _artworkPaths[item.globalKey] = DownloadedArtwork(thumbPath: item.thumbPath);
        _downloadLibraries[item.globalKey] = (libraryId: item.libraryId, libraryTitle: item.libraryTitle);

        if (_ownsDownloadKey(item.globalKey)) {
          await _hydrateDownloadMetadata(item.globalKey, pinned);
        }
      }

      await _loadSyncRules();

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
    ({Map<String, MediaItem> items, Map<String, String?> scopesByServer}) pinned, {
    bool fetchOnMiss = false,
    bool Function()? isStale,
  }) async {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return (metadata: null, networkFilled: false, stale: false);

    // MediaBrowser bulk keys are compound-scoped (`machine/user:item`); Plex
    // keys are public. Try the exact profile namespace first, then the public
    // key, then the per-item lookup (which also finds cached-but-unpinned rows).
    final clientScopeId = pinned.scopesByServer[parsed.serverId];
    var cached =
        (clientScopeId == null ? null : pinned.items[buildGlobalKey(ServerId(clientScopeId), parsed.ratingKey)]) ??
        pinned.items[globalKey] ??
        await _downloadManager.lookupMetadata(
          parsed.serverId,
          parsed.ratingKey,
          preferActiveScope: true,
          activeProfileId: _activeProfileId,
        );
    if (isStale?.call() ?? false) return (metadata: null, networkFilled: false, stale: true);

    var networkFilled = false;
    if (cached == null && fetchOnMiss && _downloads.containsKey(globalKey)) {
      cached = await _downloadManager.fetchAndPinMetadata(
        parsed.serverId,
        parsed.ratingKey,
        preferActiveScope: true,
        activeProfileId: _activeProfileId,
      );
      if (isStale?.call() ?? false) return (metadata: null, networkFilled: false, stale: true);
      networkFilled = cached != null;
    }

    if (cached == null) {
      // Parent rows can be shared by multiple downloaded siblings. A missing
      // leaf invalidates only that leaf; profile changes clear the whole store.
      _metadata.remove(globalKey);
    }
    if (cached != null) {
      // The row's stamped library identity wins only when the cached item
      // lacks its own — pre-v23 rows and offline enqueues stay useful.
      final library = _downloadLibraries[globalKey];
      if (library != null &&
          (library.libraryId != null || library.libraryTitle != null) &&
          (cached.libraryId == null || cached.libraryTitle == null)) {
        cached = cached.copyWith(
          libraryId: cached.libraryId ?? library.libraryId,
          libraryTitle: cached.libraryTitle ?? library.libraryTitle,
        );
      }
      _metadata[globalKey] = cached;
      if (cached.isEpisode || cached.kind == MediaKind.track) {
        _loadParentMetadataFromMap(cached, pinned.items, clientScopeId: clientScopeId);
      }
    }
    return (metadata: cached, networkFilled: networkFilled, stale: false);
  }

  void _onProgressUpdate(DownloadProgress progress) {
    appLogger.d('Progress update received: ${progress.globalKey} - ${progress.status} - ${progress.progress}%');
    final ownedByActiveProfile = _ownsDownloadKey(progress.globalKey);
    final previous = _downloads[progress.globalKey];
    final terminalUpdateOmittedBytes =
        previous != null &&
        progress.downloadedBytes == 0 &&
        previous.downloadedBytes > 0 &&
        switch (progress.status) {
          DownloadStatus.completed ||
          DownloadStatus.failed ||
          DownloadStatus.cancelled ||
          DownloadStatus.partial => true,
          DownloadStatus.queued || DownloadStatus.downloading || DownloadStatus.paused => false,
        };
    // Terminal status-only events omit byte fields. Preserve only those omitted
    // counters; live progress and explicit retry resets must remain authoritative.
    final merged = terminalUpdateOmittedBytes
        ? progress.copyWith(
            progress: progress.progress == 0 ? previous.progress : progress.progress,
            downloadedBytes: previous.downloadedBytes,
            totalBytes: progress.totalBytes == 0 ? previous.totalBytes : progress.totalBytes,
          )
        : progress;
    // The completion timestamp is stamped on the transition into completed
    // (a re-download earns a fresh stamp) and carried through every later
    // event so sort-by-date survives status-only updates.
    final downloadedAt =
        merged.downloadedAt ??
        (merged.status == DownloadStatus.completed && previous?.status != DownloadStatus.completed
            ? DateTime.now().millisecondsSinceEpoch
            : previous?.downloadedAt);
    _downloads[progress.globalKey] = downloadedAt == merged.downloadedAt
        ? merged
        : merged.copyWith(downloadedAt: downloadedAt);

    // Sync artwork paths when they are available.
    if (merged.hasArtworkPaths) {
      _artworkPaths[merged.globalKey] = DownloadedArtwork(thumbPath: merged.thumbPath);
    }

    if (ownedByActiveProfile) safeNotifyListeners();
  }

  @override
  void dispose() {
    BackgroundWorkDiagnosticsService.instance.unbindActivitySource(downloadActivitySnapshot);
    _offlineSource?.removeListener(_onOfflineSourceChanged);
    _progressSubscription?.cancel();
    _deletionProgressSubscription?.cancel();
    _metadataStore
      ..removeListener(_onMetadataStoreChanged)
      ..dispose();
    super.dispose();
  }

  void _onMetadataStoreChanged() => safeNotifyListeners();
  void _onOfflineSourceChanged() => _networkStateGeneration++;

  /// Ensure metadata has a serverId, falling back to a parent's serverId.
  MediaItem _ensureServerId(MediaItem metadata, String? fallbackServerId) =>
      metadata.serverId != null ? metadata : metadata.copyWith(serverId: fallbackServerId);

  /// All current download progress entries
  Map<String, DownloadProgress> get downloads =>
      Map.unmodifiable(Map.fromEntries(_downloads.entries.where(_ownsProgressEntry)));

  /// Per-item [MediaItemSortExtras] for sorting [items] by download
  /// bookkeeping. Leaves resolve their own row; containers (shows, seasons,
  /// albums) aggregate over their completed downloaded leaves — newest
  /// `downloadedAt`, summed `totalBytes` — so the download sorts work on
  /// container groupings too. Computed once per call: hoist the result rather
  /// than calling inside a comparator.
  Map<String, MediaItemSortExtras> downloadSortExtras(List<MediaItem> items) {
    final extras = <String, MediaItemSortExtras>{};
    final containerKeys = {
      for (final item in items)
        if (item.isShow || item.isSeason || item.kind == MediaKind.album) item.globalKey,
    };

    void accumulate(String key, DownloadProgress progress) {
      final existing = extras[key];
      final downloadedAt = progress.downloadedAt;
      final totalBytes = progress.totalBytes;
      extras[key] = (
        downloadedAt: downloadedAt != null && downloadedAt > (existing?.downloadedAt ?? 0)
            ? downloadedAt
            : existing?.downloadedAt,
        totalBytes: (existing?.totalBytes ?? 0) + totalBytes,
      );
    }

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      if (!_ownsDownloadKey(globalKey)) continue;
      final progress = _downloads[globalKey];
      if (progress?.status != DownloadStatus.completed) continue;
      final meta = entry.value;
      final serverId = meta.serverId;
      if (serverId == null) continue;

      accumulate(globalKey, progress!);
      if (containerKeys.isEmpty) continue;

      // Fan the leaf's bookkeeping out to every container it could belong to.
      if (meta.isEpisode) {
        final showId = meta.grandparentId;
        if (showId != null) {
          final showKey = buildGlobalKey(ServerId(serverId), showId);
          if (containerKeys.contains(showKey)) accumulate(showKey, progress);
        }
        final seasonId = meta.parentId;
        if (seasonId != null && seasonId.isNotEmpty) {
          final seasonKey = buildGlobalKey(ServerId(serverId), seasonId);
          if (containerKeys.contains(seasonKey)) accumulate(seasonKey, progress);
        }
      } else if (meta.isTrack) {
        final albumId = meta.parentId;
        if (albumId != null) {
          final albumKey = buildGlobalKey(ServerId(serverId), albumId);
          if (containerKeys.contains(albumKey)) accumulate(albumKey, progress);
        }
      }
    }
    return extras;
  }

  /// Aggregate transfer activity for [BackgroundWorkDiagnosticsService].
  ///
  /// Deliberately unfiltered by profile: the OS restricts the process, not a
  /// profile. Byte and percentage totals are merged monotonically per row;
  /// status counters distinguish a drained queue from a killed task.
  ///
  /// A method rather than a getter so the tear-off handed to
  /// [BackgroundWorkDiagnosticsService.bindActivitySource] compares equal at
  /// unbind time.
  DownloadActivitySnapshot downloadActivitySnapshot() {
    var activeTasks = 0;
    var completedTasks = 0;
    var failedTasks = 0;
    var downloadedBytes = 0;
    var progressUnits = 0;
    for (final progress in _downloads.values) {
      switch (progress.status) {
        case DownloadStatus.downloading:
          activeTasks++;
        case DownloadStatus.completed:
          completedTasks++;
        case DownloadStatus.failed:
          failedTasks++;
        case DownloadStatus.queued:
        case DownloadStatus.paused:
        case DownloadStatus.cancelled:
        case DownloadStatus.partial:
          break;
      }
      downloadedBytes += progress.downloadedBytes;
      progressUnits += progress.progress;
    }
    return (
      activeTasks: activeTasks,
      completedTasks: completedTasks,
      failedTasks: failedTasks,
      downloadedBytes: downloadedBytes,
      progressUnits: progressUnits,
      networkAvailable: _offlineSource == null ? null : !_offlineSource!.isOffline,
      networkStateGeneration: _networkStateGeneration,
    );
  }

  /// All metadata for downloads
  Map<String, MediaItem> get metadata => _metadataStore.resolvedItems;

  /// Get unique TV shows that have downloaded episodes
  /// Returns stored show metadata, or synthesizes from episode metadata as fallback
  List<MediaItem> get downloadedShows => _downloadedContainers(
    isLeaf: (meta) => meta.isEpisode,
    containerIdOf: (meta) => meta.grandparentId,
    containerKind: MediaKind.show,
    synthesize: (meta, showRatingKey) {
      // Fallback: synthesize from episode metadata (missing year, summary)
      // Only Plex consumers read `raw['key']` (library-section + folder
      // navigation), so we synthesize the Plex URI for Plex shows and
      // emit a MediaBrowser-shaped item for Jellyfin or Emby
      // (`Id` + `Type=Series`).
      final synthesizedRaw = switch (meta.backend) {
        MediaBackend.plex => <String, dynamic>{'key': '/library/metadata/$showRatingKey'},
        MediaBackend.jellyfin || MediaBackend.emby => <String, dynamic>{'Id': showRatingKey, 'Type': 'Series'},
      };
      return MediaItem(
        id: showRatingKey,
        backend: meta.backend,
        kind: MediaKind.show,
        title: meta.grandparentTitle ?? t.common.unknown,
        thumbPath: meta.grandparentThumbPath,
        artPath: meta.grandparentArtPath,
        serverId: meta.serverId,
        raw: synthesizedRaw,
      );
    },
    // Counts and library identity come from the downloaded episodes, not the
    // stored container row: the unwatched badge must reflect what is actually
    // on disk, and a container cached without library fields still groups
    // correctly once any episode carries them.
    finish: _withDownloadedLeafCounts,
  );

  /// One item per container (show/album) that has completed, owned leaf
  /// downloads: the stored container row when present and of [containerKind]
  /// (it carries year, summary, clearLogo), else [synthesize]d from the first
  /// leaf. [finish] receives each container with its watch-state-applied
  /// leaves.
  List<MediaItem> _downloadedContainers({
    required bool Function(MediaItem leaf) isLeaf,
    required String? Function(MediaItem leaf) containerIdOf,
    required MediaKind containerKind,
    required MediaItem Function(MediaItem leaf, String containerId) synthesize,
    required MediaItem Function(MediaItem container, List<MediaItem> leaves) finish,
  }) {
    final containers = <String, MediaItem>{};
    final leavesByContainer = <String, List<MediaItem>>{};

    for (final entry in _metadata.entries) {
      final globalKey = entry.key;
      if (!_ownsDownloadKey(globalKey)) continue;
      final meta = _metadataStore.applyWatchState(entry.value);
      if (_downloads[globalKey]?.status != DownloadStatus.completed || !isLeaf(meta)) continue;
      final containerId = containerIdOf(meta);
      if (containerId == null) continue;
      final containerKey = buildGlobalKey(ServerId(meta.serverId!), containerId);
      leavesByContainer.putIfAbsent(containerKey, () => []).add(meta);
      if (containers.containsKey(containerKey)) continue;

      final stored = _resolvedMetadata(containerKey);
      containers[containerKey] = stored != null && stored.kind == containerKind
          ? stored
          : synthesize(meta, containerId);
    }

    return [for (final entry in containers.entries) finish(entry.value, leavesByContainer[entry.key]!)];
  }

  /// Fill [target]'s missing library identity from [sources] — the
  /// row-stamped identity survives on leaves even when a container's own
  /// metadata predates stamping (or was fetched without it, e.g. Jellyfin
  /// album/show parents), and vice versa for leaves whose container row is
  /// stamped.
  MediaItem _withLibraryFallback(MediaItem target, List<MediaItem> sources) {
    var libraryId = target.libraryId;
    var libraryTitle = target.libraryTitle;
    if (libraryId == null || libraryTitle == null) {
      for (final source in sources) {
        libraryId ??= source.libraryId;
        libraryTitle ??= source.libraryTitle;
        if (libraryId != null && libraryTitle != null) break;
      }
    }
    if (libraryId == target.libraryId && libraryTitle == target.libraryTitle) return target;
    return target.copyWith(libraryId: libraryId, libraryTitle: libraryTitle);
  }

  /// Overrides a show/season container's leaf counts with the downloaded
  /// episodes' own numbers and fills missing library identity from them.
  /// [episodes] must already be watch-state-applied.
  MediaItem _withDownloadedLeafCounts(MediaItem container, List<MediaItem> episodes) {
    final withLibrary = _withLibraryFallback(container, episodes);
    return withLibrary.copyWith(
      leafCount: episodes.length,
      viewedLeafCount: episodes.where((episode) => episode.isWatched).length,
    );
  }

  /// Completed, owned episode downloads across every show. Missing library
  /// identity is inherited from the stored show row so a leaf groups and
  /// filters the same way its containers do.
  List<MediaItem> get downloadedEpisodes =>
      _completedLeaves(isLeaf: (meta) => meta.isEpisode, containerOf: _showLibraryFallbackFor);

  /// Completed, owned track downloads across every album. Missing library
  /// identity is inherited from the stored album row.
  List<MediaItem> get downloadedTracks =>
      _completedLeaves(isLeaf: (meta) => meta.kind == MediaKind.track, containerOf: _albumLibraryFallbackFor);

  /// Completed, owned downloads matching [isLeaf], watch state applied, with
  /// missing library identity filled from the stored row [containerOf] finds.
  List<MediaItem> _completedLeaves({
    required bool Function(MediaItem meta) isLeaf,
    required MediaItem? Function(MediaItem leaf) containerOf,
  }) {
    final leaves = <MediaItem>[];
    for (final entry in _metadata.entries) {
      if (!_ownsDownloadKey(entry.key) || _downloads[entry.key]?.status != DownloadStatus.completed) continue;
      if (!isLeaf(entry.value)) continue;
      final leaf = _metadataStore.applyWatchState(entry.value);
      leaves.add(_withLibraryFallback(leaf, [?containerOf(leaf)]));
    }
    return leaves;
  }

  /// Seasons with downloaded episodes across every show, ordered by season
  /// number. Stored season metadata wins when present; counts and library
  /// identity always come from the downloaded episodes.
  List<MediaItem> get downloadedSeasons => _downloadedSeasons(null);

  /// Seasons with downloaded episodes for one show. Accepts the show's
  /// globalKey (`serverId:ratingKey`); a bare ratingKey matches episodes by
  /// grandparent id on every server.
  List<MediaItem> downloadedSeasonsForShow(String showRatingKey, {MediaItem? showFallback}) =>
      _downloadedSeasons(showRatingKey, showFallback: showFallback);

  List<MediaItem> _downloadedSeasons(String? showKey, {MediaItem? showFallback}) {
    final parsed = showKey == null ? null : parseGlobalKey(showKey);
    final episodes = downloadedEpisodes.where((episode) {
      if (showKey == null) return true;
      if (parsed != null) {
        return episode.serverId == parsed.serverId.value && episode.grandparentId == parsed.ratingKey;
      }
      return episode.grandparentId == showKey;
    });

    // Group by season identity: the parent ratingKey when episodes carry one,
    // the season number otherwise. The key always includes the server and
    // show so same-numbered seasons of different shows never merge.
    final seasonMap = <String, List<MediaItem>>{};
    for (final episode in episodes) {
      final seasonId = episode.parentId;
      final key = seasonId != null && seasonId.isNotEmpty
          ? '${episode.serverId}:${episode.grandparentId}:$seasonId'
          : '${episode.serverId}:${episode.grandparentId}#${episode.parentIndex ?? 0}';
      seasonMap.putIfAbsent(key, () => []).add(episode);
    }

    final seasons = <MediaItem>[
      for (final entry in seasonMap.entries)
        _downloadedSeasonItem(
          entry.value,
          libraryFallback: _libraryFallbackItem(showFallback) ?? _showLibraryFallbackFor(entry.value.first),
        ),
    ]..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
    return seasons;
  }

  /// The stored show row for [episode]'s series, used to inherit library
  /// identity the episodes themselves lack.
  MediaItem? _showLibraryFallbackFor(MediaItem episode) => _storedContainerFor(episode, episode.grandparentId);

  /// The stored album row for [track]'s album, used to inherit library
  /// identity the track itself lacks.
  MediaItem? _albumLibraryFallbackFor(MediaItem track) => _storedContainerFor(track, track.parentId);

  MediaItem? _storedContainerFor(MediaItem leaf, String? containerId) {
    final serverId = leaf.serverId;
    if (containerId == null || serverId == null) return null;
    return _resolvedMetadata(buildGlobalKey(ServerId(serverId), containerId));
  }

  /// [fallback] when it actually carries library identity, else null — an
  /// unstamped candidate must not suppress the provider's own lookup.
  MediaItem? _libraryFallbackItem(MediaItem? fallback) =>
      fallback != null && (fallback.libraryId != null || fallback.libraryTitle != null) ? fallback : null;

  MediaItem _downloadedSeasonItem(List<MediaItem> episodes, {MediaItem? libraryFallback}) {
    final firstEp = episodes.first;
    final seasonIndex = firstEp.parentIndex ?? 0;
    final seasonId = firstEp.parentId ?? '';
    final seasonGlobalKey = firstEp.serverId == null || seasonId.isEmpty
        ? null
        : buildGlobalKey(ServerId(firstEp.serverId!), seasonId);
    final storedSeason = seasonGlobalKey == null ? null : _resolvedMetadata(seasonGlobalKey);

    final base = storedSeason != null && storedSeason.isSeason
        ? storedSeason.copyWith(serverId: firstEp.serverId, serverName: firstEp.serverName ?? storedSeason.serverName)
        : MediaItem(
            id: seasonId.isNotEmpty ? seasonId : '${firstEp.grandparentId}#s$seasonIndex',
            backend: firstEp.backend,
            kind: MediaKind.season,
            title: firstEp.parentTitle?.isNotEmpty == true
                ? firstEp.parentTitle
                : t.common.seasonNumber(number: seasonIndex),
            index: seasonIndex,
            thumbPath: firstEp.parentThumbPath,
            parentId: firstEp.grandparentId,
            parentTitle: firstEp.grandparentTitle,
            serverId: firstEp.serverId,
            serverName: firstEp.serverName,
          );
    return _withDownloadedLeafCounts(base, [
      for (final episode in episodes)
        episode.copyWith(
          libraryId: episode.libraryId ?? libraryFallback?.libraryId,
          libraryTitle: episode.libraryTitle ?? libraryFallback?.libraryTitle,
        ),
    ]);
  }

  /// Distinct libraries across owned completed downloads, for grouping and
  /// filtering. Items stamped before v23 (or while offline) fall back to the
  /// server name so they still form a selectable bucket.
  List<({String serverId, String? libraryId, String title})> get downloadedLibraries {
    final seen = <String, ({String serverId, String? libraryId, String title})>{};
    for (final entry in _metadata.entries) {
      if (!_ownsDownloadKey(entry.key)) continue;
      if (_downloads[entry.key]?.status != DownloadStatus.completed) continue;
      final meta = entry.value;
      final serverId = meta.serverId;
      if (serverId == null) continue;
      final key = '$serverId:${meta.libraryId}';
      seen.putIfAbsent(
        key,
        () => (
          serverId: serverId,
          libraryId: meta.libraryId,
          title: meta.libraryTitle ?? meta.serverName ?? t.common.unknown,
        ),
      );
    }
    final libraries = seen.values.toList()
      ..sort((a, b) {
        final byTitle = a.title.compareTo(b.title);
        if (byTitle != 0) return byTitle;
        final byServer = a.serverId.compareTo(b.serverId);
        if (byServer != 0) return byServer;
        return (a.libraryId ?? '').compareTo(b.libraryId ?? '');
      });
    return libraries;
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
  /// Library identity is inherited from the stamped tracks when the album
  /// metadata lacks it (MediaBrowser album parents carry none).
  List<MediaItem> get downloadedAlbums {
    final list = _downloadedContainers(
      isLeaf: (meta) => meta.kind == MediaKind.track,
      containerIdOf: (meta) => meta.parentId,
      containerKind: MediaKind.album,
      synthesize: (meta, albumRatingKey) => MediaItem(
        id: albumRatingKey,
        backend: meta.backend,
        kind: MediaKind.album,
        title: meta.albumTitle ?? t.common.unknown,
        parentId: meta.grandparentId,
        parentTitle: meta.grandparentTitle,
        thumbPath: meta.parentThumbPath ?? meta.thumbPath,
        serverId: meta.serverId,
      ),
      finish: _withLibraryFallback,
    );
    list.sort((a, b) {
      final byArtist = (a.albumArtistTitle ?? '').compareTo(b.albumArtistTitle ?? '');
      if (byArtist != 0) return byArtist;
      return (a.title ?? '').compareTo(b.title ?? '');
    });
    return list;
  }

  /// Completed downloaded tracks of the album at [albumGlobalKey], sorted by
  /// disc then track number — the offline playback queue for that album.
  List<MediaItem> getDownloadedTracksForAlbum(String albumGlobalKey) {
    final album = parseGlobalKey(albumGlobalKey);
    if (album == null) return const <MediaItem>[];
    final tracks = _metadata.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final meta = entry.value;
          return meta.kind == MediaKind.track &&
              meta.serverId == album.serverId.value &&
              meta.parentId == album.ratingKey &&
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

  /// Get downloaded episodes for the show at [showGlobalKey]
  List<MediaItem> getDownloadedEpisodesForShow(String showGlobalKey) {
    final show = parseGlobalKey(showGlobalKey);
    if (show == null) return const <MediaItem>[];
    return _metadata.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final progress = _downloads[entry.key];
          final meta = entry.value;
          return progress?.status == DownloadStatus.completed &&
              meta.isEpisode &&
              meta.serverId == show.serverId.value &&
              meta.grandparentId == show.ratingKey;
        })
        .map((entry) => _metadataStore.applyWatchState(entry.value))
        .toList();
  }

  /// Get leaf downloads (episodes or tracks) of one server's container,
  /// filtered by grandparent (show/artist) and/or parent (season/album)
  /// ratingKey.
  List<DownloadProgress> _getLeafDownloads({
    required ServerId serverId,
    String? grandparentRatingKey,
    String? parentRatingKey,
  }) {
    return _downloads.entries
        .where((entry) {
          if (!_ownsDownloadKey(entry.key)) return false;
          final meta = _metadata[entry.key];
          if (meta == null || !(meta.isEpisode || meta.kind == MediaKind.track)) return false;
          if (meta.serverId != serverId.value) return false;
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
      episodes: _getLeafDownloads(serverId: serverId, grandparentRatingKey: showRatingKey),
      entityType: 'show',
    );
  }

  /// Calculate aggregate progress for a season (based on all its episodes)
  /// Returns synthetic DownloadProgress with aggregated values
  DownloadProgress? getAggregateProgressForSeason(ServerId serverId, String seasonRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: seasonRatingKey,
      episodes: _getLeafDownloads(serverId: serverId, parentRatingKey: seasonRatingKey),
      entityType: 'season',
    );
  }

  /// Aggregate progress for an album (parent of its tracks).
  DownloadProgress? getAggregateProgressForAlbum(ServerId serverId, String albumRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: albumRatingKey,
      episodes: _getLeafDownloads(serverId: serverId, parentRatingKey: albumRatingKey),
      entityType: 'album',
    );
  }

  /// Aggregate progress for an artist (grandparent of its tracks).
  DownloadProgress? getAggregateProgressForArtist(ServerId serverId, String artistRatingKey) {
    return _calculateAggregateProgress(
      serverId: serverId,
      ratingKey: artistRatingKey,
      episodes: _getLeafDownloads(serverId: serverId, grandparentRatingKey: artistRatingKey),
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
    final directProgress = _downloads[globalKey];
    if (directProgress != null) {
      if (!_ownsDownloadKey(globalKey)) return null;
      return directProgress;
    }

    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;

    final serverId = parsed.serverId;
    final ratingKey = parsed.ratingKey;

    final meta = _metadata[globalKey];
    if (meta == null) {
      // No metadata stored yet, might be a container (show/season/artist/
      // album) being queued. Check if any leaves exist for this as a parent —
      // the aggregate helpers are kind-agnostic over grandparent/parent keys.
      var entityType = 'show';
      var leaves = _getLeafDownloads(serverId: serverId, grandparentRatingKey: ratingKey);
      if (leaves.isEmpty) {
        entityType = 'season';
        leaves = _getLeafDownloads(serverId: serverId, parentRatingKey: ratingKey);
      }
      if (leaves.isEmpty) return null;
      return _calculateAggregateProgress(
        serverId: serverId,
        ratingKey: ratingKey,
        episodes: leaves,
        entityType: entityType,
      );
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
  @visibleForTesting
  bool isQueued(String globalKey) {
    final progress = getProgress(globalKey);
    return progress?.status == DownloadStatus.queued;
  }

  /// Check if an item is currently being queued (building download queue)
  bool isQueueing(String globalKey) => _queueing.containsKey(globalKey);

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

    final source = await resolveDownloadedVideoSource(
      downloadedItem,
      requestedMediaIndex: mediaIndex,
      requestedMediaSourceId: mediaSourceId,
    );
    return source?.path;
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

    final ownership = _captureQueueOwnership();
    final globalKey = metadata.globalKey;
    final config = versionConfig ?? DownloadVersionConfig();
    if (_queueing.containsKey(globalKey)) return 0;
    _queueing[globalKey] = ownership;
    safeNotifyListeners();

    try {
      // Claim the operation before the first await so a second tap cannot
      // launch a duplicate container expansion.
      if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
        throw CellularDownloadBlockedException();
      }
      if (!_isQueueOwnershipCurrent(ownership)) return 0;
      // The queueing claim above remains held while Android's permission
      // dialog is open, so a second tap cannot launch duplicate expansion.
      await NotificationPermission.ensure();
      if (!_isQueueOwnershipCurrent(ownership)) return 0;

      if (metadata.isMovie || metadata.isEpisode || metadata.kind == MediaKind.track) {
        final queued = await _queueSingleDownload(
          metadata,
          client,
          ownership: ownership,
          mediaIndex: config.mediaIndex,
        );
        return queued ? 1 : 0;
      } else if (metadata.kind == MediaKind.album || metadata.kind == MediaKind.artist) {
        return await _withStashedMetadata(
          metadata,
          ownership,
          () => _queueMusicContainerDownload(metadata, client, ownership),
        );
      } else if (metadata.isShow || metadata.isSeason) {
        return await _withStashedMetadata(
          metadata,
          ownership,
          () => _expandAndQueue(
            container: metadata,
            client: client,
            ownership: ownership,
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
      if (_queueing[globalKey] == ownership) {
        _queueing.remove(globalKey);
        safeNotifyListeners();
      }
    }
  }

  Future<T> _withStashedMetadata<T>(
    MediaItem metadata,
    _QueueOwnership ownership,
    Future<T> Function() operation,
  ) async {
    if (!_isQueueOwnershipCurrent(ownership)) {
      throw StateError('Queue ownership is stale');
    }
    final globalKey = metadata.globalKey;
    final previous = _metadata[globalKey];
    _metadata[globalKey] = metadata;
    try {
      return await operation();
    } catch (_) {
      if (_isQueueOwnershipCurrent(ownership)) {
        if (previous == null) {
          _metadata.remove(globalKey);
        } else {
          _metadata[globalKey] = previous;
        }
      }
      rethrow;
    }
  }

  /// Queue every playable item from a collection/playlist for download.
  ///
  /// Expansion follows [collectListLeaves] so a one-shot list download queues
  /// exactly what a sync rule on the same list would.
  ///
  /// When [syncRule] is given, the rule's membership — the unfiltered leaves of
  /// the list, not just the ones this pass queues — is linked to the rule so a
  /// later "delete rule and its downloads" pass can find every associated row.
  Future<int> queueListDownload(
    List<MediaItem> items,
    MediaServerClient client, {
    DownloadFilter filter = DownloadFilter.all,
    SyncRuleItem? syncRule,
  }) async {
    if (!_downloadManager.downloadsSupported) return 0;

    final ownership = _captureQueueOwnership();
    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      throw CellularDownloadBlockedException();
    }
    if (!_isQueueOwnershipCurrent(ownership)) return 0;

    final unwatchedOnly = filter == DownloadFilter.unwatched;
    final membership = <MediaItem>[];
    final candidates = <MediaItem>[];
    // Expand one list entry at a time so a cancelled queue stops before the
    // next container is fetched.
    for (final item in items) {
      if (!_isQueueOwnershipCurrent(ownership)) return 0;
      final leaves = <MediaItem>[];
      await collectListLeaves(client, [item], unwatchedOnly: unwatchedOnly, out: leaves);
      candidates.addAll(leaves);
      if (syncRule != null) {
        if (unwatchedOnly) {
          // Rule membership spans the whole list; only the queue is filtered.
          await collectListLeaves(client, [item], unwatchedOnly: false, out: membership);
        } else {
          membership.addAll(leaves);
        }
      }
    }
    if (!_isQueueOwnershipCurrent(ownership)) return 0;

    if (syncRule != null) {
      for (final item in membership) {
        final withServer = _ensureServerId(item, client.serverId);
        if (_hasActiveOwnedDownload(withServer.globalKey)) {
          await _associateSyncRuleDownload(syncRule, withServer.globalKey, ownership);
        }
      }
    }

    final relatedContext = _RelatedMetadataDownloadContext();
    var count = 0;
    for (final item in candidates) {
      if (!_isQueueOwnershipCurrent(ownership)) return count;
      final withServer = _ensureServerId(item, client.serverId);
      if (_hasActiveOwnedDownload(withServer.globalKey)) continue;
      final queued = await _queueSingleDownload(
        withServer,
        client,
        ownership: ownership,
        relatedContext: relatedContext,
      );
      if (syncRule != null) {
        await _associateSyncRuleDownload(syncRule, withServer.globalKey, ownership);
      }
      if (queued) count++;
    }
    if (syncRule != null && _isQueueOwnershipCurrent(ownership)) {
      await markSyncRuleDownloadLinksInitialized(syncRule.globalKey);
    }
    return count;
  }

  /// Queue a single movie or episode for download.
  /// Returns true if the item was actually queued, false if skipped.
  Future<bool> _queueSingleDownload(
    MediaItem metadata,
    MediaServerClient client, {
    required _QueueOwnership ownership,
    int mediaIndex = 0,
    DownloadVersionConfig? versionConfig,
    _RelatedMetadataDownloadContext? relatedContext,
  }) async {
    if (!_downloadManager.downloadsSupported) return false;

    if (!_isQueueOwnershipCurrent(ownership)) return false;
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
        try {
          await _downloadManager.saveMetadata(metadataToStore, client);
        } catch (e) {
          // Claiming an already-present physical download must also work
          // offline. Cache enrichment is best effort; ownership is durable.
          appLogger.w('Failed to pin metadata while claiming $globalKey', error: e);
        }
        if (!_isQueueOwnershipCurrent(ownership)) return false;
        final claimed = await _claimDownloadForProfile(globalKey, ownership, client);
        if (!_isQueueOwnershipCurrent(ownership)) return false;
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
    if (!_isQueueOwnershipCurrent(ownership)) return false;

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
          if (!_isQueueOwnershipCurrent(ownership)) return false;
          if (pickedIndex == null) return false;
          resolvedIndex = pickedIndex;
          if (!_isQueueOwnershipCurrent(ownership)) return false;
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
        ownership: ownership,
        context: relatedContext ?? _RelatedMetadataDownloadContext(),
      );
      if (!_isQueueOwnershipCurrent(ownership)) return false;
    }

    // Store full metadata for display
    if (!_isQueueOwnershipCurrent(ownership)) return false;
    _metadata[globalKey] = metadataToStore;

    await _claimDownloadForProfile(globalKey, ownership, client);
    if (!_isQueueOwnershipCurrent(ownership)) return false;

    _downloads[globalKey] = DownloadProgress(globalKey: globalKey, status: DownloadStatus.queued);
    safeNotifyListeners();

    if (!_isQueueOwnershipCurrent(ownership)) return false;
    final storedMetadata = await _downloadManager.queueDownload(
      metadata: metadataToStore,
      client: client,
      mediaIndex: resolvedIndex,
    );
    // The manager may have stamped library identity during the enqueue; keep
    // the hydrated item and the row-derived map in sync with what was stored.
    if (!identical(storedMetadata, metadataToStore)) {
      _metadata[globalKey] = storedMetadata;
    }
    if (storedMetadata.libraryId != null || storedMetadata.libraryTitle != null) {
      _downloadLibraries[globalKey] = (libraryId: storedMetadata.libraryId, libraryTitle: storedMetadata.libraryTitle);
    }
    return true;
  }

  /// Fetch and store parent metadata for a leaf item — show + season for an
  /// episode, artist + album for a track (same grandparent/parent fields).
  /// Also downloads the parents' artwork.
  Future<void> _fetchAndStoreParentMetadata(
    MediaItem leaf,
    MediaServerClient client, {
    required _QueueOwnership ownership,
    required _RelatedMetadataDownloadContext context,
  }) async {
    final serverId = leaf.serverId;
    if (serverId == null) return;

    await _fetchAndStoreRelatedMetadata(
      serverId: ServerId(serverId),
      ratingKey: leaf.grandparentId,
      client: client,
      ownership: ownership,
      context: context,
    );
    if (!_isQueueOwnershipCurrent(ownership)) return;
    await _fetchAndStoreRelatedMetadata(
      serverId: ServerId(serverId),
      ratingKey: leaf.parentId,
      client: client,
      ownership: ownership,
      context: context,
    );
  }

  /// Fetch, persist, and download artwork for a related metadata item (show or season).
  Future<void> _fetchAndStoreRelatedMetadata({
    required ServerId serverId,
    required String? ratingKey,
    required MediaServerClient client,
    required _QueueOwnership ownership,
    required _RelatedMetadataDownloadContext context,
  }) async {
    if (ratingKey == null || !_isQueueOwnershipCurrent(ownership)) return;
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
    if (metadata == null || !_isQueueOwnershipCurrent(ownership)) return;

    final withServer = metadata.copyWith(serverId: serverId);
    _metadata[globalKey] = withServer;
    if (!_isQueueOwnershipCurrent(ownership)) return;
    await _downloadManager.saveMetadata(withServer, client);
    if (!_isQueueOwnershipCurrent(ownership)) return;

    final thumbPath = withServer.thumbPath;
    if (fetchedFreshMetadata || context.ensuredArtworkKeys.add(globalKey)) {
      if (!_isQueueOwnershipCurrent(ownership)) return;
      await _downloadManager.downloadArtworkForMetadata(withServer, client);
      if (!_isQueueOwnershipCurrent(ownership)) return;
    }
    _artworkPaths[globalKey] = DownloadedArtwork(thumbPath: thumbPath);
  }

  /// Queue every track under an album/artist. Expansion is one
  /// recursive-leaves call ([MediaServerClient.fetchPlayableDescendants]) on
  /// every backend — Plex branches album→/children, while MediaBrowser retries
  /// tag-only artists by album-artist credit.
  Future<int> _queueMusicContainerDownload(
    MediaItem container,
    MediaServerClient client,
    _QueueOwnership ownership,
  ) async {
    final tracks = await client.fetchPlayableDescendants(container.id);
    if (!_isQueueOwnershipCurrent(ownership)) return 0;
    final relatedContext = _RelatedMetadataDownloadContext();
    int count = 0;
    for (final track in tracks) {
      if (!_isQueueOwnershipCurrent(ownership)) return count;
      final trackWithServer = _ensureServerId(track, container.serverId);
      final queued = await _queueSingleDownload(
        trackWithServer,
        client,
        ownership: ownership,
        relatedContext: relatedContext,
      );
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
    final ownership = _captureQueueOwnership();
    final queued = await _expandAndQueue(
      container: metadata,
      client: client,
      ownership: ownership,
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
    required _QueueOwnership ownership,
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
    if (!_isQueueOwnershipCurrent(ownership)) return 0;

    int count = 0;
    for (final episode in episodes) {
      if (!_isQueueOwnershipCurrent(ownership)) return count;
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
        ownership: ownership,
        versionConfig: versionConfig,
        relatedContext: relatedContext,
      );
      if (queued) count++;
    }
    return count;
  }

  /// Forwards [action] to the manager when the active profile owns
  /// [globalKey] and its download is in one of [statuses].
  Future<void> _whenOwnedIn(String globalKey, Set<DownloadStatus> statuses, Future<void> Function() action) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null && statuses.contains(progress.status)) await action();
  }

  /// Pause a download (works for both downloading and queued items)
  Future<void> pauseDownload(String globalKey) => _whenOwnedIn(globalKey, const {
    DownloadStatus.downloading,
    DownloadStatus.queued,
  }, () => _downloadManager.pauseDownload(globalKey));

  /// Resume a paused download
  Future<void> resumeDownload(String globalKey, MediaServerClient client) =>
      _whenOwnedIn(globalKey, const {DownloadStatus.paused}, () => _downloadManager.resumeDownload(globalKey, client));

  /// Retry a failed download
  Future<void> retryDownload(String globalKey, MediaServerClient client) =>
      _whenOwnedIn(globalKey, const {DownloadStatus.failed}, () => _downloadManager.retryDownload(globalKey, client));

  /// Cancel a download
  Future<void> cancelDownload(String globalKey) async {
    if (!_ownsDownloadKey(globalKey)) return;
    final progress = _downloads[globalKey];
    if (progress != null) {
      final profileId = _requireActiveProfileId();
      final removedMeta = _metadata[globalKey];
      var released = await _releaseDownloadForProfile(globalKey, profileId, onlyIfShared: true);
      if (!released) {
        released = await _removeExclusiveDownload(
          globalKey,
          profileId,
          () => _downloadManager.cancelAndRemoveDownload(globalKey),
        );
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

      final profileId = _requireActiveProfileId();
      final releasedAsShared = await _releaseDownloadForProfile(globalKey, profileId, onlyIfShared: true);
      if (releasedAsShared) {
        if (notify && meta != null) {
          DeletionNotifier().notifyDeletedItem(item: meta, isDownloadOnly: true);
        }
        if (notify) safeNotifyListeners();
        return;
      }

      await _removeExclusiveDownload(globalKey, profileId, () => _downloadManager.deleteDownload(globalKey));

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

  /// Physically removes [globalKey] for its last owner [profileId]: [remove]
  /// runs the manager operation, then the ownership row is released and the
  /// item dropped from the in-memory maps. Returns the release result.
  Future<bool> _removeExclusiveDownload(String globalKey, String profileId, Future<void> Function() remove) async {
    final finalOwner = await _database.getDownloadOwner(profileId: profileId, globalKey: globalKey);
    await remove();
    final released = await _releaseDownloadForProfile(globalKey, profileId, ownerHint: finalOwner);
    _downloads.remove(globalKey);
    _metadata.remove(globalKey);
    _artworkPaths.remove(globalKey);
    _downloadLibraries.remove(globalKey);
    return released;
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
  ///
  /// Resolves via the active profile's persisted scope — never the download
  /// creator's `clientScopeId` — so a shared download can't leak another
  /// user's cached watch state or token-stamped URLs. A profile with no
  /// persisted scope (or no cached row under its own namespace) gets null and
  /// the caller falls back to its lightweight seed metadata.
  Future<MediaItem?> lookupOfflineMetadata(ServerId serverId, String itemId) =>
      _downloadManager.lookupMetadata(serverId, itemId, preferActiveScope: true, activeProfileId: _activeProfileId);

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
    final keys = <String>{..._downloads.keys.where(_ownsDownloadKey)};
    if (keys.isEmpty) {
      await _applyOfflineWatchOverlay(expectedProfileGeneration: profileGeneration);
      return;
    }

    final pinned = await _downloadManager.getAllPinnedMetadata(activeProfileId: _activeProfileId);
    if (isStale()) return;
    int cacheHits = 0;
    int networkFills = 0;
    int misses = 0;

    for (final globalKey in keys) {
      try {
        final result = await _hydrateDownloadMetadata(globalKey, pinned, fetchOnMiss: true, isStale: isStale);
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

  /// Deletes [globalKey] if it is a completed episode/movie download; returns
  /// the deleted item's display title, or null when it is not an auto-remove
  /// candidate.
  ///
  /// Shared core of the auto-remove-watched rule. The watched judgment stays
  /// with the caller: the sweep in [autoDeleteWatchedDownloads] trusts server
  /// metadata, while [OfflineWatchProvider] fires right after a local
  /// mark-watched that metadata cannot reflect yet.
  Future<String?> deleteWatchedDownloadCandidate(String globalKey, {required String logContext}) async {
    final meta = _resolvedMetadata(globalKey);
    if (meta == null) return null;
    if (!meta.isEpisode && !meta.isMovie) return null;
    if (_downloads[globalKey]?.status != DownloadStatus.completed) return null;

    appLogger.i('Auto-deleting $logContext download: ${meta.title} ($globalKey)');
    await deleteDownload(globalKey);
    return meta.title ?? t.common.unknown;
  }

  /// Auto-delete downloaded episodes/movies that are now marked as watched.
  ///
  /// Only deletes individual episodes and movies, never show/season containers.
  /// [activeGlobalKey] is excluded from deletion to protect the currently playing item.
  Future<List<String>> autoDeleteWatchedDownloads({String? activeGlobalKey}) async {
    final deletedTitles = <String>[];

    final completedKeys = _downloads.entries
        .where((e) => _ownsDownloadKey(e.key) && e.value.status == DownloadStatus.completed)
        .map((e) => e.key)
        .toList();

    for (final globalKey in completedKeys) {
      final meta = _resolvedMetadata(globalKey);
      if (meta == null) continue;
      if (!meta.isWatched) continue;

      // Don't delete the episode that's currently playing
      if (activeGlobalKey != null && meta.globalKey == activeGlobalKey) continue;

      try {
        final title = await deleteWatchedDownloadCandidate(globalKey, logContext: 'watched');
        if (title != null) deletedTitles.add(title);
      } catch (e) {
        appLogger.w('Failed to auto-delete watched download $globalKey: $e');
      }
    }

    return deletedTitles;
  }

  /// All sync rules for the active profile (profile-scoped globalKey -> SyncRuleItem).
  Map<String, SyncRuleItem> get syncRules => Map.unmodifiable(_syncRules);

  bool get syncRulesSupported => _downloadManager.downloadsSupported;

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

  bool _hasActiveOwnedDownload(String globalKey) {
    if (!_ownsDownloadKey(globalKey)) return false;
    final progress = _downloads[globalKey];
    return progress != null &&
        (progress.status == DownloadStatus.downloading ||
            progress.status == DownloadStatus.completed ||
            progress.status == DownloadStatus.queued ||
            progress.status == DownloadStatus.paused);
  }

  Future<void> _associateSyncRuleDownload(
    SyncRuleItem rule,
    String downloadGlobalKey,
    _QueueOwnership ownership,
  ) async {
    if (!_isQueueOwnershipCurrent(ownership) ||
        _removingSyncRuleKeys.contains(rule.globalKey) ||
        !_hasActiveOwnedDownload(downloadGlobalKey)) {
      return;
    }
    final currentRule = _syncRules[rule.globalKey];
    if (currentRule == null) return;
    await _database.associateSyncRuleDownload(currentRule, downloadGlobalKey);
  }

  Future<bool> _queueSyncRuleDownload(
    MediaItem item,
    MediaServerClient client, {
    required _QueueOwnership ownership,
    required _RelatedMetadataDownloadContext relatedContext,
    int mediaIndex = 0,
  }) async {
    if (!_isQueueOwnershipCurrent(ownership)) return false;
    return _queueSingleDownload(
      item,
      client,
      ownership: ownership,
      mediaIndex: mediaIndex,
      relatedContext: relatedContext,
    );
  }

  Future<void> markSyncRuleDownloadLinksInitialized(String globalKey) async {
    await _database.markSyncRuleDownloadLinksInitialized(globalKey);
    final existing = _syncRules[globalKey];
    if (existing != null) {
      _syncRules[globalKey] = existing.copyWith(downloadLinksInitialized: true);
    }
  }

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

  /// Validate the options actually consumed by each sync-rule kind.
  static void validateSyncRuleOptions(
    SyncRuleItem rule, {
    int? episodeCount,
    String? downloadFilter,
    bool? includeSpecials,
    int? mediaIndex,
  }) {
    final isList = rule.targetType == ContentTypes.collection || rule.targetType == ContentTypes.playlist;
    if (episodeCount != null) {
      if (isList) throw UnsupportedError('List rules do not use episode counts');
      if (episodeCount < 0) throw ArgumentError('Episode count must be nonnegative');
    }
    if (downloadFilter != null) {
      if (!isList) throw UnsupportedError('Episode rules always select unwatched episodes');
      if (downloadFilter != SyncRuleFilter.all && downloadFilter != SyncRuleFilter.unwatched) {
        throw ArgumentError('Invalid sync rule filter');
      }
    }
    if (includeSpecials != null && rule.targetType != ContentTypes.show) {
      throw UnsupportedError('Only show rules use includeSpecials');
    }
    if (mediaIndex != null) {
      if (isList) throw UnsupportedError('List rules always use the default version');
      if (mediaIndex < 0) throw ArgumentError('Version index must be nonnegative');
    }
  }

  /// Edit existing configuration only; this never executes or creates a rule.
  Future<SyncRuleItem> updateSyncRuleOptions(
    String globalKey, {
    int? episodeCount,
    String? downloadFilter,
    bool? enabled,
    bool? includeSpecials,
    int? mediaIndex,
    void Function()? checkCurrent,
  }) async {
    final profileId = _requireActiveProfileId();
    final generation = _profileGeneration;
    final expected = _syncRules[globalKey];
    if (expected == null || expected.profileId != profileId) throw StateError('Sync rule is not owned by this profile');
    validateSyncRuleOptions(
      expected,
      episodeCount: episodeCount,
      downloadFilter: downloadFilter,
      includeSpecials: includeSpecials,
      mediaIndex: mediaIndex,
    );
    void guard({bool requireIdle = true}) {
      checkCurrent?.call();
      if (isDisposed || _activeProfileId != profileId || _profileGeneration != generation) {
        throw StateError('Download profile changed');
      }
      if (requireIdle &&
          (_syncRuleCleanupInProgress || _syncRuleExecutor.isExecuting || _removingSyncRuleKeys.contains(globalKey))) {
        throw const SyncRuleCleanupBusyException();
      }
      if (_syncRules[globalKey]?.id != expected.id) throw StateError('Sync rule no longer exists');
    }

    guard();
    final updated = await _database.updateSyncRuleOptions(
      expected,
      episodeCount: episodeCount,
      downloadFilter: downloadFilter,
      enabled: enabled,
      includeSpecials: includeSpecials,
      mediaIndex: mediaIndex,
      checkCurrent: guard,
    );
    guard(requireIdle: false);
    _syncRules[globalKey] = updated;
    safeNotifyListeners();
    return updated;
  }

  /// Delete a sync rule. Downloaded episodes are kept.
  Future<void> deleteSyncRule(String globalKey) async {
    _requireActiveProfileId();
    final existing = _syncRules[globalKey] ?? await _database.getSyncRule(globalKey);
    await _deleteSyncRuleRecord(globalKey, existing);
    safeNotifyListeners();
  }

  /// Delete a list sync rule and every active-profile download associated only
  /// with that rule. Other rules and profile owners keep their copies.
  Future<void> deleteSyncRuleAndDownloads(String globalKey, MultiServerManager serverManager) async {
    final profileId = _requireActiveProfileId();
    if (_syncRuleCleanupInProgress || _syncRuleExecutor.isExecuting) {
      throw const SyncRuleCleanupBusyException();
    }

    final ownership = _captureQueueOwnership();
    final existing = await _database.getSyncRule(globalKey);
    if (existing == null || existing.profileId != profileId) return;
    if (existing.targetType != ContentTypes.collection && existing.targetType != ContentTypes.playlist) {
      throw ArgumentError.value(existing.targetType, 'targetType', 'Only collection/playlist rules support cleanup');
    }

    var stateChanged = false;
    _syncRuleCleanupInProgress = true;
    try {
      await _backfillUninitializedRuleLinksForServer(existing, serverManager, ownership);
      if (!_isQueueOwnershipCurrent(ownership)) {
        throw const SyncRuleCleanupBusyException();
      }

      final trackedRule = await _database.getSyncRule(globalKey);
      if (trackedRule == null || !trackedRule.downloadLinksInitialized) {
        throw SyncRuleCleanupUnavailableException(globalKey);
      }

      _removingSyncRuleKeys.add(globalKey);
      await _database.updateSyncRuleEnabled(globalKey, false);
      final cachedRule = _syncRules[globalKey];
      if (cachedRule != null) {
        _syncRules[globalKey] = cachedRule.copyWith(enabled: false, downloadLinksInitialized: true);
      }
      stateChanged = true;

      final downloadKeys = await _database.getExclusiveSyncRuleDownloadKeys(trackedRule);
      _batchDeletionDepth++;
      try {
        for (final downloadKey in downloadKeys) {
          if (!_isQueueOwnershipCurrent(ownership)) {
            throw const SyncRuleCleanupBusyException();
          }
          final wasOwned = _ownsDownloadKey(downloadKey);
          final metadata = _metadata[downloadKey];
          await _deleteDownload(downloadKey, notify: false);
          if (wasOwned && metadata != null) {
            DeletionNotifier().notifyDeletedItem(item: metadata, isDownloadOnly: true);
          }
        }
      } finally {
        _batchDeletionDepth--;
      }

      await _deleteSyncRuleRecord(globalKey, trackedRule);
      appLogger.i('Deleted sync rule and ${downloadKeys.length} associated downloads: $globalKey');
    } finally {
      _removingSyncRuleKeys.remove(globalKey);
      _syncRuleCleanupInProgress = false;
      if (stateChanged) safeNotifyListeners();
    }
  }

  Future<void> _backfillUninitializedRuleLinksForServer(
    SyncRuleItem target,
    MultiServerManager serverManager,
    _QueueOwnership ownership,
  ) async {
    final rules = await _database.getUninitializedSyncRulesForServer(
      profileId: target.profileId,
      serverId: ServerId(target.serverId),
    );
    final requiredRules = rules.where((rule) => rule.enabled || rule.globalKey == target.globalKey);
    for (final rule in requiredRules) {
      if (!_isQueueOwnershipCurrent(ownership)) {
        throw const SyncRuleCleanupBusyException();
      }
      switch (rule.targetType) {
        case ContentTypes.show:
        case ContentTypes.season:
          final downloadKeys = await _database.getOwnedDownloadKeysForAncestorRule(
            profileId: rule.profileId,
            serverId: ServerId(rule.serverId),
            ratingKey: rule.ratingKey,
            matchGrandparent: rule.targetType == ContentTypes.show,
          );
          for (final downloadKey in downloadKeys) {
            await _database.associateSyncRuleDownload(rule, downloadKey);
          }
          await _database.markSyncRuleDownloadLinksInitialized(rule.globalKey);
          break;
        case ContentTypes.collection:
        case ContentTypes.playlist:
          final backfilled = await _syncRuleExecutor.backfillListRuleDownloadLinks(
            rule: rule,
            serverManager: serverManager,
            downloads: downloads,
            metadata: Map.unmodifiable(_metadata),
            associateDownload: (resolvedRule, downloadKey) async {
              if (_isQueueOwnershipCurrent(ownership) && _hasActiveOwnedDownload(downloadKey)) {
                await _database.associateSyncRuleDownload(resolvedRule, downloadKey);
              }
            },
          );
          if (!backfilled) {
            throw SyncRuleCleanupUnavailableException(rule.globalKey);
          }
          break;
        default:
          throw SyncRuleCleanupUnavailableException(rule.globalKey);
      }
      final cachedRule = _syncRules[rule.globalKey];
      if (cachedRule != null) {
        _syncRules[rule.globalKey] = cachedRule.copyWith(downloadLinksInitialized: true);
      }
    }
  }

  Future<void> _deleteSyncRuleRecord(String globalKey, SyncRuleItem? existing) async {
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
    if (_syncRuleCleanupInProgress) return [];

    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return [];
    final ownership = _captureQueueOwnership();
    if (_syncRules.isEmpty) return [];

    final relatedContext = _RelatedMetadataDownloadContext();
    final results = await _syncRuleExecutor.executeSyncRules(
      profileId: profileId,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      associateDownload: (rule, downloadGlobalKey) => _associateSyncRuleDownload(rule, downloadGlobalKey, ownership),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) {
        // A profile switch mid-pass must not keep queueing the old profile's
        // rules; whatever does get queued is claimed for the rule's owner,
        // never the new active profile.
        return _queueSyncRuleDownload(
          episode,
          client,
          ownership: ownership,
          relatedContext: relatedContext,
          mediaIndex: mediaIndex,
        );
      },
      isOffline: _offlineSource?.isOffline ?? false,
      force: force,
    );

    return results.where((r) => r.queuedCount > 0).map((r) {
      final title = r.title ?? t.common.unknown;
      return '$title (${r.queuedCount})';
    }).toList();
  }

  /// Execute a single sync rule immediately (eager path for `addToPlaylist` /
  /// `addToCollection`). Bypasses the cooldown.
  Future<SyncRuleResult?> executeSyncRuleFor(String globalKey, MultiServerManager serverManager) async {
    if (!_downloadManager.downloadsSupported) return null;
    if (_syncRuleCleanupInProgress) return null;

    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return null;
    final ownership = _captureQueueOwnership();
    if (!_syncRules.containsKey(globalKey)) return null;

    final relatedContext = _RelatedMetadataDownloadContext();
    return _syncRuleExecutor.executeSingleRule(
      profileId: profileId,
      globalKey: globalKey,
      serverManager: serverManager,
      downloads: downloads,
      metadata: Map.unmodifiable(_metadata),
      associateDownload: (rule, downloadGlobalKey) => _associateSyncRuleDownload(rule, downloadGlobalKey, ownership),
      queueSingleDownload: (episode, client, {int mediaIndex = 0}) => _queueSyncRuleDownload(
        episode,
        client,
        ownership: ownership,
        relatedContext: relatedContext,
        mediaIndex: mediaIndex,
      ),
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
      final generation = _profileGeneration;
      if (profileId == null || profileId.isEmpty) {
        _ownedDownloadKeys.clear();
        return;
      }
      bool isStillActive() => _activeProfileId == profileId && _profileGeneration == generation;
      await _database.adoptLegacyDownloadsForProfile(profileId, isStillActive: isStillActive);
      await _downloadManager.adoptTransferredPlexMetadataForProfile(profileId, isStillActive: isStillActive);
      if (!isStillActive()) return;
      final ownedKeys = await _database.getDownloadOwnerKeysForProfile(profileId);
      if (!isStillActive()) return;
      _ownedDownloadKeys
        ..clear()
        ..addAll(ownedKeys);
    } catch (e) {
      appLogger.w('Failed to load download ownership', error: e);
    }
  }
}

class SyncRuleCleanupBusyException implements Exception {
  const SyncRuleCleanupBusyException();
}

class SyncRuleCleanupUnavailableException implements Exception {
  final String ruleGlobalKey;

  const SyncRuleCleanupUnavailableException(this.ruleGlobalKey);
}

/// Exception thrown when download is blocked due to cellular-only setting
class CellularDownloadBlockedException implements Exception {
  String get message => t.settings.cellularDownloadBlocked;

  @override
  String toString() => message;
}
