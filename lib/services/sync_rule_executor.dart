import 'package:connectivity_plus/connectivity_plus.dart';
import '../media/ids.dart';

import '../database/app_database.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../models/download_models.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../media/episode_collection.dart';
import '../utils/global_key_utils.dart';
import 'download_manager_service.dart';
import 'multi_server_manager.dart';
import 'playlist_items_loader.dart';

/// Sync-rule filter values stored in `SyncRules.downloadFilter`.
class SyncRuleFilter {
  SyncRuleFilter._();
  static const String all = 'all';
  static const String unwatched = 'unwatched';
}

typedef AssociateSyncRuleDownload = Future<void> Function(SyncRuleItem rule, String downloadGlobalKey);
typedef QueueSyncRuleDownload = Future<bool> Function(MediaItem item, MediaServerClient client, {int mediaIndex});

/// Deletes a download this rule no longer needs. Used only by rule types
/// that remove downloads on membership shrinkage (currently `continueWatching`
/// — episode/list rules only ever top up, never remove).
typedef DeleteSyncRuleDownload = Future<void> Function(String downloadGlobalKey);

typedef _ResolvedListRuleItems = ({List<MediaItem> membership, List<MediaItem> candidates});

/// Result of executing a single sync rule.
class SyncRuleResult {
  final String globalKey;
  final String? title;
  final int queuedCount;

  const SyncRuleResult({required this.globalKey, this.title, required this.queuedCount});
}

/// Evaluates sync rules and queues downloads so the device matches the rule's target.
///
/// Rule types:
/// - **show** / **season**: keep N unwatched episodes queued (0 = all unwatched).
/// - **collection** / **playlist**: mirror the list's current contents, expanding
///   shows/seasons into episodes, filtered by `downloadFilter` (`all` or `unwatched`).
/// - **continueWatching**: system-managed, one per connected server; mirrors that
///   server's Continue Watching shelf, removing downloads that fall off it.
class SyncRuleExecutor {
  final AppDatabase _database;
  bool _isExecuting = false;

  /// Per profile: one profile's background pass must not consume another
  /// profile's cooldown window after a switch.
  final Map<String, DateTime> _lastFullRunAtByProfile = {};

  static const Duration _cooldownWifi = Duration(minutes: 30);
  static const Duration _cooldownCellular = Duration(hours: 3);

  SyncRuleExecutor({required this._database});

  bool get isExecuting => _isExecuting;

  /// Execute every enabled sync rule.
  ///
  /// The adaptive cooldown (30 min on WiFi/Ethernet, 3 h on cellular) only
  /// applies to background probes — reasons the rule set may have drifted
  /// without the app knowing, i.e. connectivity transitions. User-initiated
  /// runs (a watch event flushing, a sync-queue drain) pass [force] `true`
  /// to bypass it: we already know state changed and the UX expectation is
  /// immediate feedback.
  ///
  /// [associateDownload] records coverage for an already-present download.
  /// [queueSingleDownload] queues and records a missing download, returning
  /// whether a queue entry was created.
  Future<List<SyncRuleResult>> executeSyncRules({
    required String profileId,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
    required DeleteSyncRuleDownload deleteSyncRuleDownload,
    required bool isOffline,
    bool force = false,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping');
      return [];
    }

    if (isOffline) {
      appLogger.d('Skipping sync rules — offline');
      return [];
    }

    // Read connectivity once for both the WiFi-only gate and the cooldown pick.
    final List<ConnectivityResult> connectivity = await _readConnectivity();
    if (await DownloadManagerService.shouldBlockDownloadOnCellularWith(connectivity)) {
      appLogger.d('Skipping sync rules — cellular download blocked');
      return [];
    }

    final lastFullRunAt = _lastFullRunAtByProfile[profileId];
    if (!force && lastFullRunAt != null) {
      final hasWifi =
          connectivity.contains(ConnectivityResult.wifi) || connectivity.contains(ConnectivityResult.ethernet);
      final cooldown = hasWifi ? _cooldownWifi : _cooldownCellular;
      final elapsed = DateTime.now().difference(lastFullRunAt);
      if (elapsed < cooldown) {
        appLogger.d(
          'Sync rules cooldown active (${elapsed.inMinutes}m < ${cooldown.inMinutes}m, hasWifi=$hasWifi) — skipping',
        );
        return [];
      }
    }

    _isExecuting = true;
    try {
      final rules = await _database.getSyncRules(profileId: profileId);
      if (rules.isEmpty) return [];

      appLogger.i('Executing ${rules.length} sync rules');
      final results = <SyncRuleResult>[];

      for (final rule in rules) {
        if (!rule.enabled) continue;
        try {
          final result = await _executeRule(
            rule: rule,
            serverManager: serverManager,
            downloads: downloads,
            metadata: metadata,
            queueSingleDownload: queueSingleDownload,
            associateDownload: associateDownload,
            deleteSyncRuleDownload: deleteSyncRuleDownload,
          );
          if (result != null && result.queuedCount > 0) {
            results.add(result);
          }
        } catch (e) {
          appLogger.w('Failed to execute sync rule ${rule.globalKey}: $e');
        }
      }

      _lastFullRunAtByProfile[profileId] = DateTime.now();
      return results;
    } finally {
      _isExecuting = false;
    }
  }

  /// Execute one rule by global key. Used for the eager trigger after
  /// `addToPlaylist` / `addToCollection`. Not throttled by the cooldown.
  Future<SyncRuleResult?> executeSingleRule({
    required String profileId,
    required String globalKey,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
    required DeleteSyncRuleDownload deleteSyncRuleDownload,
    required bool isOffline,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping single-rule run for $globalKey');
      return null;
    }

    if (isOffline) {
      appLogger.d('Skipping single sync rule $globalKey — offline');
      return null;
    }

    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      appLogger.d('Skipping single sync rule $globalKey — cellular download blocked');
      return null;
    }

    final rule = await _database.getSyncRule(globalKey);
    if (rule == null || !rule.enabled || rule.profileId != profileId) {
      return null;
    }

    _isExecuting = true;
    try {
      return await _executeRule(
        rule: rule,
        serverManager: serverManager,
        downloads: downloads,
        metadata: metadata,
        queueSingleDownload: queueSingleDownload,
        associateDownload: associateDownload,
        deleteSyncRuleDownload: deleteSyncRuleDownload,
      );
    } catch (e) {
      appLogger.w('Failed to execute single sync rule $globalKey: $e');
      return null;
    } finally {
      _isExecuting = false;
    }
  }

  /// Populate persistent coverage for a legacy list rule without queueing
  /// missing items. Returns false when the rule cannot be resolved safely.
  Future<bool> backfillListRuleDownloadLinks({
    required SyncRuleItem rule,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
  }) async {
    if (_isExecuting || (rule.targetType != ContentTypes.collection && rule.targetType != ContentTypes.playlist)) {
      return false;
    }

    final client = serverManager.getClient(ServerId(rule.serverId));
    if (client == null || !serverManager.isServerOnline(ServerId(rule.serverId))) {
      return false;
    }

    _isExecuting = true;
    try {
      final resolved = await _resolveListRuleItems(
        rule: rule,
        client: client,
        clientScopeId: _clientScopeIdFor(client, ServerId(rule.serverId)),
        profileId: rule.profileId,
        metadata: metadata,
      );
      for (final item in resolved.membership) {
        final globalKey = buildGlobalKey(ServerId(rule.serverId), item.id);
        if (_isActiveDownload(downloads[globalKey])) {
          await associateDownload(rule, globalKey);
        }
      }
      await _completeRuleExecution(rule.globalKey);
      return true;
    } catch (error, stackTrace) {
      appLogger.w('Failed to backfill sync rule ${rule.globalKey}', error: error, stackTrace: stackTrace);
      return false;
    } finally {
      _isExecuting = false;
    }
  }

  Future<SyncRuleResult?> _executeRule({
    required SyncRuleItem rule,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
    required DeleteSyncRuleDownload deleteSyncRuleDownload,
  }) async {
    final client = serverManager.getClient(ServerId(rule.serverId));
    if (client == null || !serverManager.isServerOnline(ServerId(rule.serverId))) {
      appLogger.d('Skipping sync rule ${rule.globalKey} — server offline or unavailable');
      return null;
    }

    if (rule.targetType == ContentTypes.continueWatching) {
      return _executeContinueWatchingRule(
        rule: rule,
        client: client,
        downloads: downloads,
        associateDownload: associateDownload,
        queueSingleDownload: queueSingleDownload,
        deleteSyncRuleDownload: deleteSyncRuleDownload,
      );
    }

    // Migration safety net for rules created before targetMetadata was passed
    // at creation time: fetch the rule target's title once so the snackbar
    // doesn't fall back to "Unknown". On failure, keep the original map.
    var resolvedMetadata = metadata;
    if (metadata[rule.globalKey]?.title == null) {
      try {
        final fetched = await client.fetchItem(rule.ratingKey);
        if (fetched != null) {
          resolvedMetadata = {...metadata, rule.globalKey: fetched};
        }
      } catch (e) {
        appLogger.d('Sync rule ${rule.globalKey}: title fetch failed', error: e);
      }
    }

    switch (rule.targetType) {
      case ContentTypes.show:
      case ContentTypes.season:
        return _executeEpisodeRule(
          rule: rule,
          client: client,
          clientScopeId: _clientScopeIdFor(client, ServerId(rule.serverId)),
          profileId: rule.profileId,
          downloads: downloads,
          metadata: resolvedMetadata,
          associateDownload: associateDownload,
          queueSingleDownload: queueSingleDownload,
        );
      case ContentTypes.collection:
      case ContentTypes.playlist:
        return _executeListRule(
          rule: rule,
          client: client,
          clientScopeId: _clientScopeIdFor(client, ServerId(rule.serverId)),
          profileId: rule.profileId,
          downloads: downloads,
          metadata: resolvedMetadata,
          associateDownload: associateDownload,
          queueSingleDownload: queueSingleDownload,
        );
      default:
        appLogger.w('Sync rule ${rule.globalKey}: unknown targetType ${rule.targetType}');
        return null;
    }
  }

  String? _clientScopeIdFor(MediaServerClient client, ServerId serverId) {
    final cacheServerId = client.cacheServerId;
    return cacheServerId == serverId || cacheServerId.isEmpty ? null : cacheServerId;
  }

  Future<void> _completeRuleExecution(String globalKey) {
    return _database.completeSyncRuleExecution(globalKey);
  }

  /// Keep [rule.episodeCount] unwatched episodes queued for a show/season
  /// (0 = all). Always "unwatched" — watched/all filtering doesn't apply here.
  Future<SyncRuleResult?> _executeEpisodeRule({
    required SyncRuleItem rule,
    required MediaServerClient client,
    required String? clientScopeId,
    required String profileId,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
  }) async {
    final fromServer = <MediaItem>[];
    final sourceMetadata = metadata[rule.globalKey];
    await collectEpisodes(
      client,
      rule.ratingKey,
      unwatchedOnly: true,
      out: fromServer,
      fallback: sourceMetadata,
      includeSpecials: rule.targetType != ContentTypes.show || rule.includeSpecials,
    );

    final unwatchedEpisodes = await _excludeLocallyWatched(
      episodes: fromServer,
      serverId: ServerId(rule.serverId),
      profileId: profileId,
      clientScopeId: clientScopeId,
    );

    if (unwatchedEpisodes.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: no unwatched episodes available');
      await _completeRuleExecution(rule.globalKey);
      return null;
    }

    int alreadyHave = 0;
    for (final ep in unwatchedEpisodes) {
      final gk = buildGlobalKey(ServerId(rule.serverId), ep.id);
      if (_isActiveDownload(downloads[gk])) {
        alreadyHave++;
        await associateDownload(rule, gk);
      }
    }

    // episodeCount == 0 means "all unwatched" — target is total unwatched count
    final targetCount = rule.episodeCount > 0 ? rule.episodeCount : unwatchedEpisodes.length;
    final deficit = targetCount - alreadyHave;
    if (deficit <= 0) {
      appLogger.d('Sync rule ${rule.globalKey}: no deficit ($alreadyHave/$targetCount already have)');
      await _completeRuleExecution(rule.globalKey);
      return null;
    }

    int queued = 0;
    for (final ep in unwatchedEpisodes) {
      if (queued >= deficit) break;

      final gk = buildGlobalKey(ServerId(rule.serverId), ep.id);
      if (_isActiveDownload(downloads[gk])) continue;

      final episodeWithServer = ep.serverId != null ? ep : ep.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(episodeWithServer, client, mediaIndex: rule.mediaIndex);
      await associateDownload(rule, gk);
      if (ok) {
        queued++;
        appLogger.i('Sync rule ${rule.globalKey}: queued ${ep.title ?? ep.id}');
      }
    }

    await _completeRuleExecution(rule.globalKey);

    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued episodes (had $alreadyHave/$targetCount)');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
  }

  /// System-managed rule (one per connected server, created/removed by the
  /// "Auto-download Continue Watching" setting rather than by the user):
  /// mirror the server's current Continue Watching shelf. Unlike the deficit
  /// top-up above, membership can *shrink* — an episode watched to the end,
  /// or superseded by the next one in its show's on-deck slot, drops off the
  /// shelf — so this is a straight set diff: new shelf items get queued,
  /// items no longer on the shelf get their download removed, but only when
  /// this rule is their sole reason for existing (a manual download, or one
  /// also covered by a show/season sync rule, is left alone).
  Future<SyncRuleResult?> _executeContinueWatchingRule({
    required SyncRuleItem rule,
    required MediaServerClient client,
    required Map<String, DownloadProgress> downloads,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
    required DeleteSyncRuleDownload deleteSyncRuleDownload,
  }) async {
    final serverId = ServerId(rule.serverId);
    final shelf = await client.fetchContinueWatching();

    final previousLinks = await _database.getSyncRuleDownloadLinks(rule.id);
    final previousKeys = previousLinks.map((link) => link.downloadGlobalKey).toSet();
    final currentKeys = <String>{};

    int queued = 0;
    for (final item in shelf) {
      final gk = buildGlobalKey(serverId, item.id);
      currentKeys.add(gk);

      // Only track downloads this rule itself created — a pre-existing
      // download (manual, or owned by another rule) that happens to be on
      // the shelf right now is left alone, not adopted, so it's never at
      // risk of being removed later just because it eventually drops off.
      if (_isActiveDownload(downloads[gk])) continue;

      final itemWithServer = item.serverId != null ? item : item.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(itemWithServer, client, mediaIndex: 0);
      await associateDownload(rule, gk);
      if (ok) {
        queued++;
        appLogger.i('Sync rule ${rule.globalKey}: queued ${item.title ?? item.id}');
      }
    }

    final droppedKeys = previousKeys.difference(currentKeys);
    var removed = 0;
    if (droppedKeys.isNotEmpty) {
      final exclusiveKeys = (await _database.getExclusiveSyncRuleDownloadKeys(rule)).toSet();
      for (final key in droppedKeys) {
        if (exclusiveKeys.contains(key)) {
          await deleteSyncRuleDownload(key);
          removed++;
          appLogger.i('Sync rule ${rule.globalKey}: removed $key — left Continue Watching');
        } else {
          // Still needed elsewhere; just stop counting it as our coverage.
          await _database.removeSyncRuleDownloadLink(rule.id, key);
        }
      }
    }

    await _completeRuleExecution(rule.globalKey);
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued, removed $removed (shelf size ${shelf.length})');

    return SyncRuleResult(globalKey: rule.globalKey, title: null, queuedCount: queued);
  }

  /// Collection/playlist logic: fetch the list, expand any shows/seasons into
  /// episodes, filter by [rule.downloadFilter], queue everything not already
  /// downloaded. No deficit cap. `mediaIndex` is always 0 for these rules.
  Future<SyncRuleResult?> _executeListRule({
    required SyncRuleItem rule,
    required MediaServerClient client,
    required String? clientScopeId,
    required String profileId,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required AssociateSyncRuleDownload associateDownload,
    required QueueSyncRuleDownload queueSingleDownload,
  }) async {
    final _ResolvedListRuleItems resolved;
    try {
      resolved = await _resolveListRuleItems(
        rule: rule,
        client: client,
        clientScopeId: clientScopeId,
        profileId: profileId,
        metadata: metadata,
      );
    } catch (e) {
      appLogger.w('Sync rule ${rule.globalKey}: failed to fetch list items: $e');
      return null;
    }

    for (final item in resolved.membership) {
      final globalKey = buildGlobalKey(ServerId(rule.serverId), item.id);
      if (_isActiveDownload(downloads[globalKey])) {
        await associateDownload(rule, globalKey);
      }
    }

    final candidates = resolved.candidates;

    int queued = 0;
    for (final item in candidates) {
      final gk = buildGlobalKey(ServerId(rule.serverId), item.id);
      if (_isActiveDownload(downloads[gk])) continue;

      final itemWithServer = item.serverId != null ? item : item.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(itemWithServer, client, mediaIndex: 0);
      await associateDownload(rule, gk);
      if (ok) {
        queued++;
        appLogger.i('Sync rule ${rule.globalKey}: queued ${item.title ?? item.id}');
      }
    }

    await _completeRuleExecution(rule.globalKey);

    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued items from ${candidates.length} candidates');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
  }

  Future<_ResolvedListRuleItems> _resolveListRuleItems({
    required SyncRuleItem rule,
    required MediaServerClient client,
    required String? clientScopeId,
    required String profileId,
    required Map<String, MediaItem> metadata,
  }) async {
    // Page list calls so long collections/playlists don't truncate at the
    // default limit. Plex collections use a distinct collections endpoint;
    // Jellyfin's collection page implementation maps to its children API.
    final rootItems = rule.targetType == ContentTypes.collection
        ? await _fetchAllCollectionItems(client, rule.ratingKey, source: metadata[rule.globalKey])
        : await _fetchAllPlaylistItems(client, rule.ratingKey);
    if (rootItems.isEmpty) {
      return (membership: const <MediaItem>[], candidates: const <MediaItem>[]);
    }

    // Resolve the complete membership for cleanup provenance. The rule's
    // unwatched filter applies only to queueing; watched downloads still
    // belong to the list and must be removable with it.
    final membership = <MediaItem>[];
    await collectListLeaves(client, rootItems, unwatchedOnly: false, out: membership);
    if (rule.downloadFilter != SyncRuleFilter.unwatched) {
      return (membership: membership, candidates: membership);
    }
    final serverUnwatched = <MediaItem>[];
    await collectListLeaves(client, rootItems, unwatchedOnly: true, out: serverUnwatched);
    final candidates = await _excludeLocallyWatched(
      episodes: serverUnwatched,
      serverId: ServerId(rule.serverId),
      profileId: profileId,
      clientScopeId: clientScopeId,
    );
    return (membership: membership, candidates: candidates);
  }

  /// Page through every item in a playlist using the shared playlist page size.
  Future<List<MediaItem>> _fetchAllPlaylistItems(MediaServerClient client, String playlistId) async {
    return fetchAllPlaylistItems(client, playlistId);
  }

  /// Page through every item in a collection. Plex requires
  /// [MediaServerClient.fetchCollectionPage] because collection children live
  /// under `/library/collections/{id}/children`, not metadata children.
  Future<List<MediaItem>> _fetchAllCollectionItems(
    MediaServerClient client,
    String collectionId, {
    MediaItem? source,
  }) => fetchAllCollectionItemsPaged(
    client,
    collectionId,
    libraryId: source?.libraryId,
    libraryTitle: source?.libraryTitle,
  );

  /// Drop items the user already marked watched locally — the server response
  /// still shows them as unwatched until the next bidirectional-sync push
  /// drains the OfflineWatchProgress queue, which can be many seconds away.
  /// Without this filter, sync rules immediately re-queue an episode the
  /// user just marked watched on a downloaded-detail screen.
  Future<List<MediaItem>> _excludeLocallyWatched({
    required List<MediaItem> episodes,
    required ServerId serverId,
    required String profileId,
    String? clientScopeId,
  }) async {
    if (episodes.isEmpty) return episodes;
    final keys = episodes.map((ep) => buildGlobalKey(ServerId(serverId), ep.id)).toSet();
    final actions = await _database.getLatestWatchActionsForKeys(
      keys,
      profileId: profileId,
      filterProfile: true,
      clientScopeIdsByGlobalKey: {for (final key in keys) key: clientScopeId},
    );
    if (actions.isEmpty) return episodes;
    return episodes.where((ep) {
      final action = actions[buildGlobalKey(ServerId(serverId), ep.id)];
      if (action == null) return true;
      if (action.actionType == OfflineActionType.watched.id) return false;
      if (action.actionType == OfflineActionType.progress.id && action.shouldMarkWatched) return false;
      return true;
    }).toList();
  }

  static bool _isActiveDownload(DownloadProgress? p) =>
      p != null &&
      (p.status == DownloadStatus.completed ||
          p.status == DownloadStatus.downloading ||
          p.status == DownloadStatus.queued ||
          p.status == DownloadStatus.paused);

  Future<List<ConnectivityResult>> _readConnectivity() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (_) {
      // connectivity_plus can throw PlatformException on Windows — treat as unknown.
      return const <ConnectivityResult>[];
    }
  }
}
