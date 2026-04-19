import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/app_database.dart';
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/global_key_utils.dart';
import 'download_manager_service.dart';
import 'multi_server_manager.dart';
import 'plex_client.dart';

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

  SyncRuleExecutor({required AppDatabase database}) : _database = database;

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
  /// [queueSingleDownload] queues a single movie/episode and returns `true` if it
  /// was actually queued (false when the item was already present).
  Future<List<SyncRuleResult>> executeSyncRules({
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
    bool force = false,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping');
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
      final rules = await _database.getSyncRules();
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
    required String globalKey,
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping single-rule run for $globalKey');
      return null;
    }

    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      appLogger.d('Skipping single sync rule $globalKey — cellular download blocked');
      return null;
    }

    final rule = await _database.getSyncRule(globalKey);
    if (rule == null || !rule.enabled) {
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
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final client = serverManager.getClient(rule.serverId);
    if (client == null || !serverManager.isServerOnline(rule.serverId)) {
      appLogger.d('Skipping sync rule ${rule.globalKey} — server offline');
      return null;
    }

    switch (rule.targetType) {
      case ContentTypes.show:
      case ContentTypes.season:
        return _executeEpisodeRule(
          rule: rule,
          client: client,
          downloads: downloads,
          metadata: metadata,
          queueSingleDownload: queueSingleDownload,
        );
      case ContentTypes.collection:
      case ContentTypes.playlist:
        return _executeListRule(
          rule: rule,
          client: client,
          downloads: downloads,
          metadata: metadata,
          queueSingleDownload: queueSingleDownload,
        );
      default:
        appLogger.w('Sync rule ${rule.globalKey}: unknown targetType ${rule.targetType}');
        return null;
    }
  }

  /// Keep [rule.episodeCount] unwatched episodes queued for a show/season
  /// (0 = all). Always "unwatched" — watched/all filtering doesn't apply here.
  Future<SyncRuleResult?> _executeEpisodeRule({
    required SyncRuleItem rule,
    required PlexClient client,
    required Map<String, DownloadProgress> downloads,
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final unwatchedEpisodes = <PlexMetadata>[];
    if (rule.targetType == ContentTypes.show) {
      await _collectEpisodesForShow(client, rule.ratingKey, unwatchedOnly: true, out: unwatchedEpisodes);
    } else {
      await _collectEpisodesForSeason(client, rule.ratingKey, unwatchedOnly: true, out: unwatchedEpisodes);
    }

    if (unwatchedEpisodes.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: no unwatched episodes available');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    int alreadyHave = 0;
    for (final ep in unwatchedEpisodes) {
      final gk = buildGlobalKey(rule.serverId, ep.ratingKey);
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

      final gk = buildGlobalKey(rule.serverId, ep.ratingKey);
      if (_isActiveDownload(downloads[gk])) continue;

      final episodeWithServer = ep.serverId != null ? ep : ep.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(episodeWithServer, client, mediaIndex: rule.mediaIndex);
      if (ok) {
        queued++;
        appLogger.d('Sync rule ${rule.globalKey}: queued ${ep.title}');
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
    required PlexClient client,
    required Map<String, DownloadProgress> downloads,
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    final List<PlexMetadata> rootItems;
    try {
      rootItems = rule.targetType == ContentTypes.collection
          ? await client.getCollectionItems(rule.ratingKey)
          : await client.getPlaylist(rule.ratingKey);
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
    final candidates = <PlexMetadata>[];
    await _collectItemsForList(client, rootItems, unwatchedOnly: unwatchedOnly, out: candidates);

    if (candidates.isEmpty) {
      appLogger.d('Sync rule ${rule.globalKey}: no candidates after filtering');
      await _database.updateSyncRuleLastExecuted(rule.globalKey);
      return null;
    }

    int queued = 0;
    for (final item in candidates) {
      final gk = buildGlobalKey(rule.serverId, item.ratingKey);
      if (_isActiveDownload(downloads[gk])) continue;

      final itemWithServer = item.serverId != null ? item : item.copyWith(serverId: rule.serverId);
      final ok = await queueSingleDownload(itemWithServer, client, mediaIndex: 0);
      if (ok) {
        queued++;
        appLogger.d('Sync rule ${rule.globalKey}: queued ${item.title}');
      }
    }

    await _database.updateSyncRuleLastExecuted(rule.globalKey);

    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued items from ${candidates.length} candidates');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
  }

  /// Walks [items] and collects playable movie/episode entries into [out].
  /// Shows and seasons are expanded into their episodes; music and nested
  /// collections/playlists are skipped.
  Future<void> _collectItemsForList(
    PlexClient client,
    List<PlexMetadata> items, {
    required bool unwatchedOnly,
    required List<PlexMetadata> out,
  }) async {
    for (final item in items) {
      final type = item.type?.toLowerCase();
      switch (type) {
        case ContentTypes.movie:
        case ContentTypes.episode:
          if (unwatchedOnly && item.isWatched && !item.hasActiveProgress) break;
          out.add(item);
        case ContentTypes.show:
          await _collectEpisodesForShow(client, item.ratingKey, unwatchedOnly: unwatchedOnly, out: out);
        case ContentTypes.season:
          await _collectEpisodesForSeason(client, item.ratingKey, unwatchedOnly: unwatchedOnly, out: out);
        default:
          // Skip music, clips, nested collections/playlists, unknown types.
          break;
      }
    }
  }

  Future<void> _collectEpisodesForShow(
    PlexClient client,
    String showRatingKey, {
    required bool unwatchedOnly,
    required List<PlexMetadata> out,
  }) async {
    final seasons = await client.getChildren(showRatingKey);
    for (final season in seasons) {
      if (season.type == ContentTypes.season) {
        await _collectEpisodesForSeason(client, season.ratingKey, unwatchedOnly: unwatchedOnly, out: out);
      }
    }
  }

  Future<void> _collectEpisodesForSeason(
    PlexClient client,
    String seasonRatingKey, {
    required bool unwatchedOnly,
    required List<PlexMetadata> out,
  }) async {
    final episodes = await client.getChildren(seasonRatingKey);
    for (final ep in episodes) {
      if (ep.type != ContentTypes.episode) continue;
      if (unwatchedOnly && ep.isWatched && !ep.hasActiveProgress) continue;
      out.add(ep);
    }
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
