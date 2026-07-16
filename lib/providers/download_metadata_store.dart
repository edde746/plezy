part of 'download_provider.dart';

/// Owns downloaded metadata, artwork references, and profile-scoped watch
/// overlays. [DownloadProvider] remains responsible for queue and ownership
/// orchestration; this store keeps cache hydration and watch synchronization in
/// one lifecycle-bound component.
class _DownloadMetadataStore extends ChangeNotifier {
  _DownloadMetadataStore(this._downloadManager, this._database, {String? activeProfileId})
    : _activeProfileId = activeProfileId {
    _watchStateSubscription = WatchStateNotifier().stream.listen(_onWatchStateChanged);
    _watchStateStore.addListener(notifyListeners);
    _watchStateStore.setActiveProfileId(activeProfileId);
  }

  final DownloadManagerService _downloadManager;
  final AppDatabase _database;
  final WatchStateStore _watchStateStore = WatchStateStore();
  late final StreamSubscription<WatchStateEvent> _watchStateSubscription;

  final Map<String, MediaItem> items = {};
  final Map<String, DownloadedArtwork> artworkPaths = {};
  final Map<String, String?> _watchScopesByServer = {};
  String? _activeProfileId;

  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    _watchScopesByServer.clear();
    _watchStateStore
      ..setActiveProfileId(profileId)
      ..setActiveClientScopesByServer(const {});
  }

  MediaItem applyWatchState(MediaItem item) => _watchStateStore.apply(item);

  MediaItem? resolved(String globalKey) {
    final item = items[globalKey];
    return item == null ? null : applyWatchState(item);
  }

  Map<String, MediaItem> get resolvedItems =>
      Map.unmodifiable({for (final entry in items.entries) entry.key: applyWatchState(entry.value)});

  /// Loads show/season or artist/album metadata from an already-fetched cache
  /// snapshot without issuing per-parent database queries.
  void loadParentMetadataFromMap(MediaItem leaf, Map<String, MediaItem> allMetadata, {String? clientScopeId}) {
    final serverId = leaf.serverId;
    if (serverId == null) return;

    MediaItem? lookupParent(String ratingKey) {
      if (clientScopeId != null && clientScopeId.isNotEmpty) {
        final scoped = allMetadata[buildGlobalKey(ServerId(clientScopeId), ratingKey)];
        if (scoped != null) return scoped;
      }
      return allMetadata[buildGlobalKey(ServerId(serverId), ratingKey)];
    }

    void loadParent(String? ratingKey) {
      if (ratingKey == null) return;
      final parentGlobalKey = buildGlobalKey(ServerId(serverId), ratingKey);
      if (items.containsKey(parentGlobalKey)) return;
      final parentMetadata = lookupParent(ratingKey);
      if (parentMetadata == null) return;
      items[parentGlobalKey] = parentMetadata;
      if (parentMetadata.thumbPath != null) {
        artworkPaths[parentGlobalKey] = DownloadedArtwork(thumbPath: parentMetadata.thumbPath);
      }
    }

    loadParent(leaf.grandparentId);
    loadParent(leaf.parentId);
  }

  /// Rehydrates queued offline watch actions into the canonical hierarchy-aware
  /// watch-state layer for the active profile.
  Future<void> hydrateOfflineWatchOverlay({
    required Map<String, DownloadProgress> downloads,
    required bool Function(String globalKey) ownsDownloadKey,
    bool Function()? isStale,
  }) async {
    bool stale() => isStale?.call() ?? false;

    try {
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) {
        _watchStateStore.setHydratedPatches(const []);
        return;
      }

      final keys = <String>{};
      for (final item in items.values) {
        keys.add(item.globalKey);
        final serverId = serverIdOrNull(item.serverId);
        if (serverId == null) continue;
        for (final parentId in item.parentChain) {
          keys.add(buildGlobalKey(serverId, parentId));
        }
      }
      if (keys.isEmpty) {
        _watchStateStore.setHydratedPatches(const []);
        return;
      }

      final scopes = <String, String?>{};
      final scopesByServer = <String, String?>{};
      for (final key in keys) {
        final parsed = parseGlobalKey(key);
        if (parsed == null) continue;
        var scope = scopesByServer[parsed.serverId];
        if (!scopesByServer.containsKey(parsed.serverId)) {
          scope = await _offlineWatchScopeForServer(
            parsed.serverId,
            downloads: downloads,
            ownsDownloadKey: ownsDownloadKey,
          );
          scopesByServer[parsed.serverId] = scope;
        }
        scopes[key] = scope;
        if (stale()) return;
      }

      _watchScopesByServer
        ..clear()
        ..addAll(scopesByServer);
      _watchStateStore.setActiveClientScopesByServer(_watchScopesByServer);

      final actions = await _database.getWatchActionsForKeys(
        keys,
        profileId: profileId,
        filterProfile: true,
        clientScopeIdsByGlobalKey: scopes,
      );
      if (stale()) return;

      final hydrated = <HydratedWatchStatePatch>[];
      for (final entry in actions.entries) {
        final snapshot = WatchStateResolver.fromActions(entry.value);
        if (snapshot.isEmpty) continue;
        final latest = entry.value.firstWhere(
          (action) =>
              action.actionType == 'watched' || action.actionType == 'unwatched' || action.actionType == 'progress',
        );
        final scopedKey = latest.clientScopeId != null && latest.clientScopeId!.isNotEmpty
            ? buildGlobalKey(ServerId(latest.clientScopeId!), latest.ratingKey)
            : latest.globalKey;
        hydrated.add(
          HydratedWatchStatePatch(
            globalKey: scopedKey,
            patch: WatchStatePatch.fromSnapshot(snapshot),
            updatedAt: latest.updatedAt,
            order: latest.id,
          ),
        );
      }
      _watchStateStore.setHydratedPatches(hydrated);
    } catch (error) {
      appLogger.w('Failed to apply offline watch overlay', error: error);
    }
  }

  Future<String?> _offlineWatchScopeForServer(
    String serverId, {
    required Map<String, DownloadProgress> downloads,
    required bool Function(String globalKey) ownsDownloadKey,
  }) async {
    final activeScope = _downloadManager.activeClientScopeIdForServer(ServerId(serverId));
    if (activeScope != null && activeScope.isNotEmpty) return activeScope;
    for (final globalKey in downloads.keys.toList(growable: false)) {
      if (!ownsDownloadKey(globalKey)) continue;
      final parsed = parseGlobalKey(globalKey);
      if (parsed?.serverId != serverId) continue;
      final downloadedScope = (await _database.getDownloadedMedia(globalKey))?.clientScopeId;
      if (downloadedScope != null && downloadedScope.isNotEmpty) return downloadedScope;
    }
    return null;
  }

  void _onWatchStateChanged(WatchStateEvent event) {
    final snapshot = WatchStateResolver.fromEvent(event);
    if (snapshot.isEmpty) return;

    final globalKey = buildGlobalKey(ServerId(event.serverId), event.itemId);
    final base = items[globalKey];
    final eventScope = event.cacheServerId;
    final activeScope = _downloadManager.activeClientScopeIdForServer(ServerId(event.serverId));
    if (activeScope != null && activeScope.isNotEmpty) {
      _watchScopesByServer[event.serverId] = activeScope;
      _watchStateStore.setActiveClientScopesByServer(_watchScopesByServer);
    }
    if (base == null) return;
    if (eventScope != null && eventScope.isNotEmpty && eventScope != event.serverId && eventScope != activeScope) {
      return;
    }

    final isWatched = snapshot.isWatched;
    final shouldPersistToCache =
        isWatched != null && (event.changeType != WatchStateChangeType.progressUpdate || event.isNowWatched == true);
    if (!shouldPersistToCache) return;

    unawaited(
      () async {
        if (base.backend == MediaBackend.plex &&
            await _database.hasDownloadOwner(globalKey, excludingProfileId: _activeProfileId)) {
          return;
        }
        await ApiCache.forBackend(base.backend).applyWatchState(
          serverId: ServerId(event.cacheServerId ?? event.serverId),
          itemId: event.itemId,
          isWatched: isWatched,
        );
      }().catchError((Object error) {
        appLogger.w('Failed to apply watch state to cache for $globalKey', error: error);
      }),
    );
  }

  @override
  void dispose() {
    _watchStateSubscription.cancel();
    _watchStateStore
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
