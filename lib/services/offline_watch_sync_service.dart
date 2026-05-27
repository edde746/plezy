import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/download_operations.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import 'offline_mode_source.dart';
import '../utils/watch_state_notifier.dart';
import 'multi_server_manager.dart';
import 'plex_client.dart';
import 'settings_service.dart';
import 'trackers/tracker_coordinator.dart';

/// Service for managing offline watch progress and syncing it back to the
/// owning server. Backend-neutral over [MediaServerClient] — Plex actions
/// hit `/:/scrobble` and `/:/timeline`, Jellyfin actions hit
/// `/UserPlayedItems/{id}` and `/Sessions/Playing*` through the same queue.
///
/// Handles:
/// - Queuing progress updates when offline
/// - Queuing manual watch/unwatch actions
/// - Auto-marking items as watched at the server's threshold
/// - Syncing queued actions when connectivity is restored
class OfflineWatchSyncService extends ChangeNotifier {
  final AppDatabase _database;
  final MultiServerManager _serverManager;

  OfflineModeSource? _offlineModeSource;
  VoidCallback? _offlineModeListener;
  bool _isSyncing = false;
  bool _isBidirectionalSyncing = false;
  bool _isShutDown = false;
  DateTime? _lastSyncTime;
  bool _hasPerformedStartupSync = false;
  String? _activeProfileId;
  int? _availableProfileCount;
  final Set<String> _legacyWatchActionsAdoptedForProfiles = <String>{};

  /// Callback to refresh download provider metadata after sync
  VoidCallback? onWatchStatesRefreshed;

  /// Get watched threshold for a server. Cascades:
  /// 1. Plex's fetched server prefs (`/:/prefs`)
  /// 2. Jellyfin's fixed [MediaServerClient.watchedThreshold] (0.9)
  /// 3. Cached value in SettingsService
  /// 4. Default 90%
  double getWatchedThreshold(String serverId) {
    final client = _serverManager.getClient(serverId);
    if (client is PlexClient && client.serverPrefs.isNotEmpty) {
      return client.watchedThresholdPercent / 100.0;
    }
    if (client != null && client.backend != MediaBackend.plex) {
      // Jellyfin (and any future neutral backend) — the client exposes a
      // fixed threshold that mirrors the wire-protocol behaviour.
      return client.watchedThreshold;
    }
    final cached = SettingsService.instanceOrNull?.read(SettingsService.watchedThresholdPref(serverId)) ?? 90;
    return cached / 100.0;
  }

  /// Minimum interval between syncs.
  /// Mobile: no throttle (always sync on resume for cross-device updates)
  /// Desktop: 2 minutes (reduced from 10 min to handle tab-switching better)
  static Duration get minSyncInterval {
    if (Platform.isIOS || Platform.isAndroid) {
      return Duration.zero;
    }
    return const Duration(minutes: 2);
  }

  /// Maximum sync attempts before suppressing additional server-write retries.
  /// Queued actions are retained so a transient outage or server bug never
  /// silently drops local watch progress.
  static const int maxSyncAttempts = 5;

  OfflineWatchSyncService({required AppDatabase database, required MultiServerManager serverManager})
    : _database = database,
      _serverManager = serverManager;

  /// Whether a sync is currently in progress
  bool get isSyncing => _isSyncing;

  void setActiveProfileId(String? profileId, {int? availableProfileCount}) {
    _activeProfileId = profileId;
    _availableProfileCount = availableProfileCount;
    if (profileId != null && profileId.isNotEmpty) {
      unawaited(_adoptLegacyWatchActionsForProfile(profileId, availableProfileCount: availableProfileCount));
    }
  }

  Future<void> _adoptLegacyWatchActionsForProfile(String profileId, {int? availableProfileCount}) async {
    if (profileId.isEmpty || !_legacyWatchActionsAdoptedForProfiles.add(profileId)) return;
    if (availableProfileCount != 1) {
      _legacyWatchActionsAdoptedForProfiles.remove(profileId);
      return;
    }
    try {
      await _database.adoptLegacyOfflineWatchActionsForProfile(profileId);
    } catch (e, st) {
      _legacyWatchActionsAdoptedForProfiles.remove(profileId);
      appLogger.w('Failed to adopt legacy offline watch actions for $profileId', error: e, stackTrace: st);
    }
  }

  Future<void> _adoptLegacyWatchActionsForActiveProfile() async {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return;
    await _adoptLegacyWatchActionsForProfile(profileId, availableProfileCount: _availableProfileCount);
  }

  void startConnectivityMonitoring(OfflineModeSource source) {
    if (_offlineModeSource != null && _offlineModeListener != null) {
      _offlineModeSource!.removeListener(_offlineModeListener!);
    }

    _offlineModeSource = source;
    _offlineModeListener = () {
      if (!source.isOffline) {
        // We just came online - trigger bidirectional sync
        appLogger.i('Connectivity restored - starting bidirectional watch sync');
        _performBidirectionalSync();
      }
    };

    source.addListener(_offlineModeListener!);

    // Don't sync on startup - servers aren't connected yet.
    // Sync will happen when:
    // - Connectivity is restored (listener triggers)
    // - App resumes from background (onAppResumed)
  }

  /// Perform bidirectional sync: push local changes, then pull server states.
  ///
  /// Push always happens immediately. Pull respects [minSyncInterval] unless [force] is true.
  Future<void> _performBidirectionalSync({bool force = false}) async {
    if (_isShutDown) return;

    // Prevent overlapping bidirectional syncs
    if (_isBidirectionalSyncing) {
      appLogger.d('Bidirectional sync already in progress, skipping');
      return;
    }

    if (_serverManager.onlineClients.isEmpty) {
      appLogger.d('Skipping watch sync - no connected servers available yet');
      return;
    }

    _isBidirectionalSyncing = true;
    try {
      // Always push local changes to server (never throttle outbound sync)
      await syncPendingItems();

      // Only throttle the pull from server
      if (!force && _lastSyncTime != null) {
        final elapsed = DateTime.now().difference(_lastSyncTime!);
        if (elapsed < minSyncInterval) {
          appLogger.d(
            'Skipping server pull - last sync was ${elapsed.inMinutes}m ago (min: ${minSyncInterval.inMinutes}m)',
          );
          return;
        }
      }

      // Pull latest states from server
      await syncWatchStatesFromServer();
      _lastSyncTime = DateTime.now();
    } finally {
      _isBidirectionalSyncing = false;
    }
  }

  /// Called when app becomes active - syncs for cross-device updates.
  /// On mobile, always syncs immediately (device-switching scenario).
  /// On desktop, respects the throttle interval.
  void onAppResumed() {
    if (_isShutDown) return;
    if (_offlineModeSource?.isOffline != true) {
      final isMobile = Platform.isIOS || Platform.isAndroid;
      appLogger.d('App resumed - ${isMobile ? "forcing" : "checking"} sync');
      _performBidirectionalSync(force: isMobile);
    }
  }

  /// Called when servers connect on app startup.
  ///
  /// Triggers the initial sync now that PlexClients are available.
  /// Only runs once per app session.
  void onServersConnected() {
    if (_isShutDown) return;
    if (_hasPerformedStartupSync) return;
    _hasPerformedStartupSync = true;

    if (_offlineModeSource?.isOffline != true) {
      appLogger.i('Servers connected - performing startup sync');
      _performBidirectionalSync();
    }
  }

  /// Queue a progress update for later sync.
  ///
  /// This is called during offline playback to track the watch position.
  /// If progress exceeds the server's threshold, shouldMarkWatched is set to true.
  ///
  /// The `ratingKey:` parameter on the underlying `_database` calls is
  /// preserved as the on-disk column name; the in-memory parameter renamed
  /// here is just the API-level identifier.
  Future<String?> queueProgressUpdate({
    required String serverId,
    required String itemId,
    required int viewOffset,
    required int duration,
  }) async {
    final shouldMarkWatched = isWatchedByProgress(viewOffset, duration, serverId: serverId);
    final clientScopeId = await _clientScopeIdForItem(serverId, itemId);

    await _database.upsertProgressAction(
      profileId: _activeProfileId,
      serverId: serverId,
      clientScopeId: clientScopeId,
      ratingKey: itemId,
      viewOffset: viewOffset,
      duration: duration,
      shouldMarkWatched: shouldMarkWatched,
    );

    appLogger.d(
      'Queued offline progress: $serverId:$itemId at ${(viewOffset / 1000).toStringAsFixed(0)}s / ${(duration / 1000).toStringAsFixed(0)}s (${((viewOffset / duration) * 100).toStringAsFixed(1)}%)',
    );

    notifyListeners();
    return clientScopeId;
  }

  Future<String?> queueMarkWatched({required String serverId, required String itemId}) =>
      _queueWatchStatusAction(serverId: serverId, itemId: itemId, actionType: OfflineActionType.watched.id);

  Future<String?> queueMarkUnwatched({required String serverId, required String itemId}) =>
      _queueWatchStatusAction(serverId: serverId, itemId: itemId, actionType: OfflineActionType.unwatched.id);

  Future<String?> _queueWatchStatusAction({
    required String serverId,
    required String itemId,
    required String actionType,
  }) async {
    final clientScopeId = await _clientScopeIdForItem(serverId, itemId);
    await _database.insertWatchAction(
      profileId: _activeProfileId,
      serverId: serverId,
      clientScopeId: clientScopeId,
      ratingKey: itemId,
      actionType: actionType,
    );

    appLogger.d('Queued offline mark $actionType: $serverId:$itemId');
    notifyListeners();
    return clientScopeId;
  }

  /// Check if an item should be considered watched based on progress percentage.
  bool isWatchedByProgress(int viewOffset, int duration, {String? serverId}) {
    if (duration == 0) return false;
    final threshold = serverId != null ? getWatchedThreshold(serverId) : 0.9;
    return (viewOffset / duration) >= threshold;
  }

  /// Get the local watch status for a media item.
  ///
  /// Returns:
  /// - `true` if item was marked as watched locally or progress >= server threshold
  /// - `false` if item was marked as unwatched locally
  /// - `null` if no local action exists (use cached server data)
  Future<bool?> getLocalWatchStatus(String globalKey, {String? clientScopeId}) async {
    await _adoptLegacyWatchActionsForActiveProfile();
    final expectedScope = clientScopeId ?? _activeClientScopeIdForGlobalKey(globalKey);
    final profileId = _activeProfileId;
    final action = await _database.getLatestWatchAction(
      globalKey,
      profileId: profileId,
      filterProfile: profileId != null,
      clientScopeId: expectedScope,
      filterClientScope: expectedScope != null,
    );
    if (action == null) return null;

    switch (action.actionType) {
      case 'watched':
        return true;
      case 'unwatched':
        return false;
      case 'progress':
        // Check if progress exceeds threshold
        return action.shouldMarkWatched;
      default:
        return null;
    }
  }

  /// Get local watch statuses for multiple items in a single database query.
  ///
  /// Returns a map of globalKey -> watch status (true/false/null).
  /// More efficient than calling getLocalWatchStatus multiple times.
  Future<Map<String, bool?>> getLocalWatchStatusesBatched(
    Set<String> globalKeys, {
    Map<String, String?>? clientScopeIdsByGlobalKey,
  }) async {
    if (globalKeys.isEmpty) return {};
    await _adoptLegacyWatchActionsForActiveProfile();

    final scopes = clientScopeIdsByGlobalKey ?? _activeClientScopeIdsForGlobalKeys(globalKeys);
    final profileId = _activeProfileId;
    final actions = await _database.getLatestWatchActionsForKeys(
      globalKeys,
      profileId: profileId,
      filterProfile: profileId != null,
      clientScopeIdsByGlobalKey: scopes,
    );
    final result = <String, bool?>{};

    for (final key in globalKeys) {
      final action = actions[key];
      if (action == null) {
        result[key] = null;
        continue;
      }

      switch (action.actionType) {
        case 'watched':
          result[key] = true;
        case 'unwatched':
          result[key] = false;
        case 'progress':
          result[key] = action.shouldMarkWatched;
        default:
          result[key] = null;
      }
    }

    return result;
  }

  /// Get the local view offset (resume position) for a media item.
  ///
  /// Returns the locally tracked position, or null if none exists.
  Future<int?> getLocalViewOffset(String globalKey, {String? clientScopeId}) async {
    await _adoptLegacyWatchActionsForActiveProfile();
    final expectedScope = clientScopeId ?? _activeClientScopeIdForGlobalKey(globalKey);
    final profileId = _activeProfileId;
    final action = await _database.getLatestWatchAction(
      globalKey,
      profileId: profileId,
      filterProfile: profileId != null,
      clientScopeId: expectedScope,
      filterClientScope: expectedScope != null,
    );
    if (action == null) return null;

    // Only return offset for progress actions
    if (action.actionType == OfflineActionType.progress.id) {
      return action.viewOffset;
    }

    return null;
  }

  Future<int> getPendingSyncCount() async {
    await _adoptLegacyWatchActionsForActiveProfile();
    final profileId = _activeProfileId;
    return profileId == null || profileId.isEmpty
        ? _database.getPendingSyncCount()
        : _database.getPendingSyncCount(profileId: profileId);
  }

  /// Sync all pending items to their respective servers.
  ///
  /// Called automatically when connectivity is restored, or manually.
  /// Actions are batched by server to reduce connectivity lookups.
  Future<void> syncPendingItems() async {
    if (_isSyncing) {
      appLogger.d('Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await _adoptLegacyWatchActionsForActiveProfile();
      final profileId = _activeProfileId;
      final pendingActions = profileId == null || profileId.isEmpty
          ? await _database.getPendingWatchActions()
          : await _database.getPendingWatchActions(profileId: profileId);

      if (pendingActions.isEmpty) {
        appLogger.d('No pending watch actions to sync');
        return;
      }

      appLogger.i('Syncing ${pendingActions.length} pending watch actions');

      for (final action in pendingActions) {
        if (action.syncAttempts >= maxSyncAttempts) {
          appLogger.w(
            'Skipping action ${action.id} - exceeded retry limit '
            '(${action.syncAttempts} attempts). Last error: ${action.lastError}',
          );
          continue;
        }

        final synced = await _withOnlineClientForAction(action, (client) async {
          try {
            await _syncAction(client, action);
            await _database.deleteWatchAction(action.id);
            appLogger.d('Successfully synced action ${action.id}: ${action.actionType} for ${action.ratingKey}');
          } catch (e) {
            appLogger.w('Failed to sync action ${action.id}: $e');
            await _database.updateSyncAttempt(action.id, e.toString());
          }
        });
        if (!synced) {
          appLogger.d('Keeping action ${action.id} queued until server is available');
          continue;
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> _clientScopeIdForItem(String serverId, String itemId) async {
    // A downloaded row's clientScopeId is a cache/source hint, not an owner.
    // Offline watch actions are user-owned, so a new local action follows the
    // currently active scoped Jellyfin client. Once queued, _clientForAction
    // replays that exact scope even if the active user changes later.
    final client = _serverManager.getClient(serverId);
    if (client != null) {
      final scopeId = client.cacheServerId;
      if (scopeId != serverId) return scopeId;
    }
    final download = await _database.getDownloadedMedia(buildGlobalKey(serverId, itemId));
    final downloadedScopeId = download?.clientScopeId;
    if (downloadedScopeId != null && downloadedScopeId.isNotEmpty) return downloadedScopeId;
    return null;
  }

  Future<({MediaServerClient client, String? clientScopeId})?> _clientForAction(OfflineWatchProgressItem action) async {
    final scopeId = action.clientScopeId;
    if (scopeId != null && scopeId.isNotEmpty) {
      final scoped = _serverManager.getJellyfinClientByCompoundId(scopeId);
      if (scoped != null) return (client: scoped, clientScopeId: scopeId);
    }
    final client = _serverManager.getClient(action.serverId);
    if (client == null) return null;
    if (client.backend == MediaBackend.jellyfin && client.cacheServerId != action.serverId) {
      appLogger.w(
        'Refusing to sync unscoped Jellyfin action ${action.id} for ${action.serverId}:${action.ratingKey}; '
        'no queued client scope is available',
      );
      return null;
    }
    return (client: client, clientScopeId: action.clientScopeId);
  }

  Future<bool> _withOnlineClientForAction(
    OfflineWatchProgressItem action,
    Future<void> Function(MediaServerClient client) callback,
  ) async {
    final resolved = await _clientForAction(action);
    if (resolved == null) {
      appLogger.d('No client for server ${action.serverId} scope ${action.clientScopeId}, skipping');
      return false;
    }

    if (!_serverManager.isClientOnline(action.serverId, clientScopeId: resolved.clientScopeId)) {
      appLogger.d('Server ${action.serverId} scope ${resolved.clientScopeId} is offline, skipping');
      return false;
    }

    await callback(resolved.client);
    return true;
  }

  Map<String, String?> _activeClientScopeIdsForGlobalKeys(Set<String> globalKeys) {
    final scopes = <String, String?>{};
    for (final globalKey in globalKeys) {
      final scopeId = _activeClientScopeIdForGlobalKey(globalKey);
      if (scopeId != null) scopes[globalKey] = scopeId;
    }
    return scopes;
  }

  String? _activeClientScopeIdForGlobalKey(String globalKey) {
    final parsed = parseGlobalKey(globalKey);
    if (parsed == null) return null;
    return _activeClientScopeIdForServer(parsed.serverId);
  }

  String? _activeClientScopeIdForServer(String serverId) {
    final client = _serverManager.getClient(serverId);
    if (client == null) return null;
    final scopeId = client.cacheServerId;
    return scopeId == serverId ? null : scopeId;
  }

  Future<MediaServerClient?> _clientForDownloadScope(String serverId, String? clientScopeId) async {
    if (clientScopeId != null && clientScopeId.isNotEmpty) {
      final scoped = _serverManager.getJellyfinClientByCompoundId(clientScopeId);
      if (scoped != null) return scoped;
    }
    return _serverManager.getClient(serverId);
  }

  Future<T?> _withOnlineClientForDownloadScope<T>(
    String serverId,
    String? clientScopeId,
    Future<T> Function(MediaServerClient client) callback,
  ) async {
    final client = await _clientForDownloadScope(serverId, clientScopeId);
    if (client == null) {
      appLogger.d('No client for server $serverId scope $clientScopeId, skipping');
      return null;
    }

    if (!_serverManager.isClientOnline(serverId, clientScopeId: clientScopeId)) {
      appLogger.d('Server $serverId scope $clientScopeId is offline, skipping');
      return null;
    }

    return callback(client);
  }

  /// Sync a single action to the server.
  ///
  /// Uses the neutral [MediaServerClient] surface so Jellyfin's
  /// `/UserPlayedItems/{id}` and `/Sessions/Playing*` endpoints receive
  /// the same queued state Plex's `/:/scrobble` and `/:/timeline` do.
  Future<void> _syncAction(MediaServerClient client, OfflineWatchProgressItem action) async {
    // Fetch metadata so the WatchStateNotifier emission inside
    // markWatched/markUnwatched carries enough context for downstream
    // listeners (UI invalidation, Trakt sync). Best-effort: a missed metadata
    // fetch falls back to a minimal MediaItem — the network call still goes
    // through, just without a rich event payload.
    final emitsEvent =
        action.actionType == OfflineActionType.watched.id ||
        action.actionType == OfflineActionType.unwatched.id ||
        (action.actionType == OfflineActionType.progress.id && action.shouldMarkWatched);
    MediaItem? item;
    if (emitsEvent) {
      try {
        item = await client.fetchItem(action.ratingKey);
      } catch (_) {
        // Fall through to the synthetic item below.
      }
    }
    item ??= MediaItem(
      id: action.ratingKey,
      backend: client.backend,
      kind: MediaKind.unknown,
      serverId: action.serverId,
    );

    switch (action.actionType) {
      case 'watched':
        await client.markWatched(item);
        await TrackerCoordinator.instance.markWatched(item, client);
        break;

      case 'unwatched':
        await client.markUnwatched(item);
        await TrackerCoordinator.instance.markUnwatched(item, client);
        break;

      case 'progress':
        // Push the resume position. Jellyfin's `/Sessions/Playing/Stopped`
        // ignores events that arrive without an open session row, so we
        // bracket with a Started call. Plex's `/:/timeline` collapses both
        // into a single row and treats the second as the canonical state.
        if (action.viewOffset != null && action.duration != null) {
          final position = Duration(milliseconds: action.viewOffset!);
          final duration = Duration(milliseconds: action.duration!);
          try {
            await client.reportPlaybackStarted(itemId: action.ratingKey, position: position, duration: duration);
          } catch (e) {
            // Plex sometimes 5xxs the start when nothing follows; treat as
            // best-effort and continue to the stop call which is the one
            // that actually persists the resume position.
            appLogger.d('Offline progress: started call failed (continuing)', error: e);
          }
          await client.reportPlaybackStopped(itemId: action.ratingKey, position: position, duration: duration);
        }

        // If progress exceeded threshold, also mark as watched.
        if (action.shouldMarkWatched) {
          await client.markWatched(item);
          await TrackerCoordinator.instance.markWatched(item, client);
        }
        break;
    }
  }

  /// Sync watch states for all episodes in a single season.
  ///
  /// Returns the number of episodes synced, or -1 on failure.
  Future<int> _syncSeasonEpisodes(
    MediaServerClient client,
    String serverId,
    String seasonRatingKey,
    Set<String> downloadedEpisodeKeys,
  ) async {
    try {
      final seasonEpisodes = await client.fetchChildren(seasonRatingKey);
      int synced = 0;

      for (final episode in seasonEpisodes) {
        if (!downloadedEpisodeKeys.contains(episode.id)) continue;

        final cacheServerId = client.cacheServerId;
        final prior = await client.cache.getMetadata(cacheServerId, episode.id);
        final isWatched = (episode.viewCount ?? 0) > 0;

        if (prior != null) {
          // Existing cached row — patch in the watch-state and rollup
          // fields without disturbing Media/Chapter blobs.
          final wasWatched = (prior.viewCount ?? 0) > 0;
          await client.cache.applyWatchState(
            serverId: cacheServerId,
            itemId: episode.id,
            isWatched: isWatched,
            viewOffsetMs: episode.viewOffsetMs,
            lastViewedAt: episode.lastViewedAt,
            viewedLeafCount: episode.viewedLeafCount,
          );
          if (wasWatched != isWatched) {
            WatchStateNotifier().notifyWatched(
              item: episode,
              isNowWatched: isWatched,
              cacheServerId: client.cacheServerId,
            );
          }
        } else {
          // No cached row yet — populate the canonical row via fetchItem
          // (cache-fallback mixin writes the response to cache for free)
          // and then stamp the watch snapshot. Transition is unknowable
          // without a prior row, so we skip the notify to match the
          // previous synthesize-fresh-row behaviour.
          try {
            await client.fetchItem(episode.id);
            await client.cache.applyWatchState(
              serverId: cacheServerId,
              itemId: episode.id,
              isWatched: isWatched,
              viewOffsetMs: episode.viewOffsetMs,
              lastViewedAt: episode.lastViewedAt,
              viewedLeafCount: episode.viewedLeafCount,
            );
          } catch (e) {
            appLogger.d('Cache populate failed for ${episode.id}', error: e);
          }
        }
        synced++;
      }

      return synced;
    } catch (e) {
      appLogger.d('Failed to sync watch states for season $seasonRatingKey: $e');
      return -1;
    }
  }

  /// Fetch latest watch states from server and update local cache.
  ///
  /// Called when coming online or on app startup to pull any watch state
  /// changes made on other devices.
  ///
  /// Optimized to fetch episodes by season (one API call per season)
  /// instead of one API call per episode.
  Future<void> syncWatchStatesFromServer() async {
    try {
      final profileId = _activeProfileId;
      if (profileId == null || profileId.isEmpty) {
        appLogger.d('Skipping watch-state pull — no active profile');
        return;
      }

      await _database.adoptLegacyDownloadsForProfile(profileId);
      final ownedKeys = await _database.getDownloadOwnerKeysForProfile(profileId);
      if (ownedKeys.isEmpty) {
        appLogger.d('No active-profile downloads to sync watch states for');
        return;
      }

      // Pull watch state only for downloads visible to the active profile. The
      // physical rows are shared across profiles, but server watch state is not.
      final downloadedItems = (await _database.getAllDownloadedMetadata())
          .where((item) => ownedKeys.contains(item.globalKey))
          .toList();

      if (downloadedItems.isEmpty) {
        appLogger.d('No downloaded items to sync watch states for');
        return;
      }

      appLogger.i('Syncing watch states from server for ${downloadedItems.length} items');

      // Separate episodes (with season parent) from other items (movies,
      // etc.), using the active scoped client for user-owned Jellyfin watch
      // state. Downloads are shared, but server watch state is per user.
      // Structure: (serverId, clientScopeId) -> seasonRatingKey -> Set<episodeRatingKey>
      final episodesByScopeAndSeason = <({String serverId, String? clientScopeId}), Map<String, Set<String>>>{};
      // Structure: (serverId, clientScopeId) -> List<ratingKey>
      final nonEpisodeItems = <({String serverId, String? clientScopeId}), List<String>>{};

      for (final item in downloadedItems) {
        final scope = (serverId: item.serverId, clientScopeId: _activeClientScopeIdForServer(item.serverId));
        if (item.type == 'episode' && item.parentRatingKey != null) {
          // Group episodes by server and season for batch fetching
          episodesByScopeAndSeason
              .putIfAbsent(scope, () => {})
              .putIfAbsent(item.parentRatingKey!, () => {})
              .add(item.ratingKey);
        } else {
          // Movies, or episodes without parent (fallback to individual fetch)
          nonEpisodeItems.putIfAbsent(scope, () => []).add(item.ratingKey);
        }
      }

      int syncedCount = 0;
      int seasonCount = 0;

      // Fetch episodes by season (batch) - one API call per season
      for (final scopeEntry in episodesByScopeAndSeason.entries) {
        final scope = scopeEntry.key;
        final seasonMap = scopeEntry.value;

        await _withOnlineClientForDownloadScope(scope.serverId, scope.clientScopeId, (client) async {
          for (final seasonEntry in seasonMap.entries) {
            final result = await _syncSeasonEpisodes(client, scope.serverId, seasonEntry.key, seasonEntry.value);
            if (result >= 0) {
              syncedCount += result;
              seasonCount++;
            }
          }
        });
      }

      // Fetch non-episode items individually (movies, etc.)
      for (final entry in nonEpisodeItems.entries) {
        final scope = entry.key;
        final ratingKeys = entry.value;

        await _withOnlineClientForDownloadScope(scope.serverId, scope.clientScopeId, (client) async {
          for (final ratingKey in ratingKeys) {
            try {
              // Snapshot prior viewCount through the neutral cache so we
              // can detect a watched-status change from another device.
              final prior = await client.cache.getMetadata(client.cacheServerId, ratingKey);
              final wasWatched = (prior?.viewCount ?? 0) > 0;

              // fetchItem already caches the full API response (with
              // chapters/markers) via the client's internal cache layer.
              final metadata = await client.fetchItem(ratingKey);
              if (metadata != null) {
                syncedCount++;
                final isWatched = (metadata.viewCount ?? 0) > 0;
                if (wasWatched != isWatched) {
                  WatchStateNotifier().notifyWatched(
                    item: metadata,
                    isNowWatched: isWatched,
                    cacheServerId: client.cacheServerId,
                  );
                }
              }
            } catch (e) {
              appLogger.d('Failed to sync watch state for $ratingKey: $e');
            }
          }
        });
      }

      final movieCount = nonEpisodeItems.values.fold(0, (a, b) => a + b.length);
      appLogger.i('Synced watch states: $seasonCount seasons, $movieCount other items ($syncedCount total)');

      // Notify download provider to refresh metadata from updated cache
      if (syncedCount > 0) {
        onWatchStatesRefreshed?.call();
      }

      notifyListeners();
    } catch (e) {
      appLogger.w('Error syncing watch states from server: $e');
    }
  }

  /// Clear all pending watch actions (e.g., when logging out).
  Future<void> clearAll() async {
    await _database.clearAllWatchActions();
    notifyListeners();
  }

  @override
  void dispose() {
    _isShutDown = true;
    if (_offlineModeSource != null && _offlineModeListener != null) {
      _offlineModeSource!.removeListener(_offlineModeListener!);
    }
    super.dispose();
  }
}
