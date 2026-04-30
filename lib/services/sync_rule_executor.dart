import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/app_database.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../models/download_models.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/episode_collection.dart';
import '../utils/global_key_utils.dart';
import 'download_manager_service.dart';
import 'multi_server_manager.dart';
import 'offline_mode_source.dart';
import 'playlist_items_loader.dart';

/// Sync-rule filter values stored in `SyncRules.downloadFilter`.
class SyncRuleFilter {
  SyncRuleFilter._();
  static const String all = 'all';
  static const String unwatched = 'unwatched';
}

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
class SyncRuleExecutor {
  final AppDatabase _database;
  bool _isExecuting = false;
  DateTime? _lastFullRunAt;

  static const Duration _cooldownWifi = Duration(minutes: 30);
  static const Duration _cooldownCellular = Duration(hours: 3);

  OfflineModeSource? _offlineSource;

  SyncRuleExecutor({required AppDatabase database}) : _database = database;

  bool get isExecuting => _isExecuting;

  /// Inject the offline-mode source so we can skip running rules when the
  /// device has no Plex connectivity (every `getChildren` call would fail).
  void setOfflineSource(OfflineModeSource? source) {
    _offlineSource = source;
  }

  /// Execute every enabled sync rule.
  ///
  /// The adaptive cooldown (30 min on WiFi/Ethernet, 3 h on cellular) only
  /// applies to background probes — reasons the rule set may have drifted
  /// without the app knowing, i.e. connectivity transitions. User-initiated
  /// runs (a watch event flushing, a sync-queue drain) pass [force] `true`
  /// to bypass it: we already know state changed and the UX expectation is
  /// immediate feedback.
  ///
  /// [queueSingleDownload] queues a single movie/episode and returns `true` if it
  /// was actually queued (false when the item was already present).
  Future<List<SyncRuleResult>> executeSyncRules({
    required String profileId,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required Future<bool> Function(MediaItem episode, MediaServerClient client, {int mediaIndex}) queueSingleDownload,
    bool force = false,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping');
      return [];
    }

    if (_offlineSource?.isOffline ?? false) {
      appLogger.d('Skipping sync rules — offline');
      return [];
    }

    // Read connectivity once for both the WiFi-only gate and the cooldown pick.
    final List<ConnectivityResult> connectivity = await _readConnectivity();
    if (await DownloadManagerService.shouldBlockDownloadOnCellularWith(connectivity)) {
      appLogger.d('Skipping sync rules — cellular download blocked');
      return [];
    }

    if (!force && _lastFullRunAt != null) {
      final hasWifi =
          connectivity.contains(ConnectivityResult.wifi) || connectivity.contains(ConnectivityResult.ethernet);
      final cooldown = hasWifi ? _cooldownWifi : _cooldownCellular;
      final elapsed = DateTime.now().difference(_lastFullRunAt!);
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
          );
          if (result != null && result.queuedCount > 0) {
            results.add(result);
          }
        } catch (e) {
          appLogger.w('Failed to execute sync rule ${rule.globalKey}: $e');
        }
      }

      _lastFullRunAt = DateTime.now();
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
    required Future<bool> Function(MediaItem episode, MediaServerClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping single-rule run for $globalKey');
      return null;
    }

    if (_offlineSource?.isOffline ?? false) {
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
      );
    } catch (e) {
      appLogger.w('Failed to execute single sync rule $globalKey: $e');
      return null;
    } finally {
      _isExecuting = false;
    }
  }

  Future<SyncRuleResult?> _executeRule({
    required SyncRuleItem rule,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, MediaItem> metadata,
    required Future<bool> Function(MediaItem episode, MediaServerClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final client = serverManager.getClient(rule.serverId);
    if (client == null || !serverManager.isServerOnline(rule.serverId)) {
      appLogger.d('Skipping sync rule ${rule.globalKey} — server offline or unavailable');
      return null;
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
          clientScopeId: _clientScopeIdFor(client, rule.serverId),
          profileId: rule.profileId,
          downloads: downloads,
          metadata: resolvedMetadata,
          queueSingleDownload: queueSingleDownload,
        );
      case ContentTypes.collection:
      case ContentTypes.playlist:
        return _executeListRule(
          rule: rule,
          client: client,
          clientScopeId: _clientScopeIdFor(client, rule.serverId),
          profileId: rule.profileId,
          downloads: downloads,
          metadata: resolvedMetadata,
          queueSingleDownload: queueSingleDownload,
        );
      default:
        appLogger.w('Sync rule ${rule.globalKey}: unknown targetType ${rule.targetType}');
        return null;
    }
  }

  String? _clientScopeIdFor(MediaServerClient client, String serverId) {
    final cacheServerId = client.cacheServerId;
    return cacheServerId == serverId || cacheServerId.isEmpty ? null : cacheServerId;
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
    required Future<bool> Function(MediaItem episode, MediaServerClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final fromServer = <MediaItem>[];
    if (rule.targetType == ContentTypes.show) {
      await collectEpisodesForShow(client, rule.ratingKey, unwatchedOnly: true, out: fromServer);
    } else {
      await collectEpisodesForSeason(client, rule.ratingKey, unwatchedOnly: true, out: fromServer);
    }

    final unwatchedEpisodes = await _excludeLocallyWatched(
      episodes: fromServer,
      serverId: rule.serverId,
      profileId: profileId,
      clientScopeId: clientScopeId,
    );

    if (unwatchedEpisodes.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: no unwatched episodes available');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    int alreadyHave = 0;
    for (final ep in unwatchedEpisodes) {
      final gk = buildGlobalKey(rule.serverId, ep.id);
      if (_isActiveDownload(downloads[gk])) alreadyHave++;
    }

    // episodeCount == 0 means "all unwatched" — target is total unwatched count
    final targetCount = rule.episodeCount > 0 ? rule.episodeCount : unwatchedEpisodes.length;
    final deficit = targetCount - alreadyHave;
    if (deficit <= 0) {
      appLogger.d('Sync rule ${rule.globalKey}: no deficit ($alreadyHave/$targetCount already have)');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    int queued = 0;
    for (final ep in unwatchedEpisodes) {
      if (queued >= deficit) break;

      final gk = buildGlobalKey(rule.serverId, ep.id);
      if (_isActiveDownload(downloads[gk])) continue;

      final episodeWithServer = ep.serverId != null ? ep : ep.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(episodeWithServer, client, mediaIndex: rule.mediaIndex);
      if (ok) {
        queued++;
        appLogger.i('Sync rule ${rule.globalKey}: queued ${ep.title ?? ep.id}');
      }
    }

    await _database.updateSyncRuleLastExecuted(rule.globalKey);

    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued episodes (had $alreadyHave/$targetCount)');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
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
    required Future<bool> Function(MediaItem episode, MediaServerClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final List<MediaItem> rootItems;
    try {
      // Page list calls so long collections/playlists don't truncate at the
      // default limit. Plex collections use a distinct collections endpoint;
      // Jellyfin's collection page implementation maps to its children API.
      if (rule.targetType == ContentTypes.collection) {
        rootItems = await _fetchAllCollectionItems(client, rule.ratingKey);
      } else {
        rootItems = await _fetchAllPlaylistItems(client, rule.ratingKey);
      }
    } catch (e) {
      appLogger.w('Sync rule ${rule.globalKey}: failed to fetch list items: $e');
      return null;
    }

    if (rootItems.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: list is empty');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    final unwatchedOnly = rule.downloadFilter == SyncRuleFilter.unwatched;
    final collected = <MediaItem>[];
    await _collectItemsForList(client, rootItems, unwatchedOnly: unwatchedOnly, out: collected);

    final candidates = unwatchedOnly
        ? await _excludeLocallyWatched(
            episodes: collected,
            serverId: rule.serverId,
            profileId: profileId,
            clientScopeId: clientScopeId,
          )
        : collected;

    if (candidates.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: no candidates after filtering');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    int queued = 0;
    for (final item in candidates) {
      final gk = buildGlobalKey(rule.serverId, item.id);
      if (_isActiveDownload(downloads[gk])) continue;

      final itemWithServer = item.serverId != null ? item : item.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(itemWithServer, client, mediaIndex: 0);
      if (ok) {
        queued++;
        appLogger.i('Sync rule ${rule.globalKey}: queued ${item.title ?? item.id}');
      }
    }

    await _database.updateSyncRuleLastExecuted(rule.globalKey);

    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued items from ${candidates.length} candidates');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
  }

  /// Page through every item in a playlist; the neutral
  /// [MediaServerClient.fetchPlaylistItems] caps each page (Plex at 100,
  /// Jellyfin honours `limit`).
  Future<List<MediaItem>> _fetchAllPlaylistItems(MediaServerClient client, String playlistId) async {
    return fetchAllPlaylistItems(client, playlistId);
  }

  /// Page through every item in a collection. Plex requires
  /// [MediaServerClient.fetchCollectionPage] because collection children live
  /// under `/library/collections/{id}/children`, not metadata children.
  Future<List<MediaItem>> _fetchAllCollectionItems(MediaServerClient client, String collectionId) async {
    final all = <MediaItem>[];
    const pageSize = 100;
    var offset = 0;
    while (true) {
      final page = await client.fetchCollectionPage(collectionId, start: offset, size: pageSize);
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      if (all.length >= page.totalCount || page.items.length < pageSize) break;
      offset += page.items.length;
    }
    return all;
  }

  /// Walks [items] and collects playable movie/episode entries into [out].
  /// Shows and seasons are expanded into their episodes; music and nested
  /// collections/playlists are skipped.
  Future<void> _collectItemsForList(
    MediaServerClient client,
    List<MediaItem> items, {
    required bool unwatchedOnly,
    required List<MediaItem> out,
  }) async {
    for (final item in items) {
      switch (item.kind) {
        case MediaKind.movie:
        case MediaKind.episode:
          if (unwatchedOnly && item.isWatched && !item.hasActiveProgress) break;
          out.add(item);
        case MediaKind.show:
          await collectEpisodesForShow(client, item.id, unwatchedOnly: unwatchedOnly, out: out);
        case MediaKind.season:
          await collectEpisodesForSeason(client, item.id, unwatchedOnly: unwatchedOnly, out: out);
        default:
          // Skip music, clips, nested collections/playlists, unknown types.
          break;
      }
    }
  }

  /// Drop items the user already marked watched locally — the server response
  /// still shows them as unwatched until the next bidirectional-sync push
  /// drains the OfflineWatchProgress queue, which can be many seconds away.
  /// Without this filter, sync rules immediately re-queue an episode the
  /// user just marked watched on a downloaded-detail screen.
  Future<List<MediaItem>> _excludeLocallyWatched({
    required List<MediaItem> episodes,
    required String serverId,
    required String profileId,
    String? clientScopeId,
  }) async {
    if (episodes.isEmpty) return episodes;
    final keys = episodes.map((ep) => buildGlobalKey(serverId, ep.id)).toSet();
    final actions = await _database.getLatestWatchActionsForKeys(
      keys,
      profileId: profileId,
      filterProfile: true,
      clientScopeIdsByGlobalKey: {for (final key in keys) key: clientScopeId},
    );
    if (actions.isEmpty) return episodes;
    return episodes.where((ep) {
      final action = actions[buildGlobalKey(serverId, ep.id)];
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
          p.status == DownloadStatus.queued);

  Future<List<ConnectivityResult>> _readConnectivity() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (_) {
      // connectivity_plus can throw PlatformException on Windows — treat as unknown.
      return const <ConnectivityResult>[];
    }
  }
}
