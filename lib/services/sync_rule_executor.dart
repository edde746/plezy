import '../database/app_database.dart';
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/global_key_utils.dart';
import 'download_manager_service.dart';
import 'multi_server_manager.dart';
import 'plex_client.dart';

/// Result of executing a single sync rule.
class SyncRuleResult {
  final String globalKey;
  final String? title;
  final int queuedCount;

  const SyncRuleResult({required this.globalKey, this.title, required this.queuedCount});
}

/// Evaluates sync rules and queues downloads to maintain the target episode count.
///
/// Each sync rule says "keep N unwatched episodes downloaded for show/season X".
/// The executor counts how many unwatched episodes are already downloaded,
/// calculates the deficit, and queues new episodes to fill the gap.
class SyncRuleExecutor {
  final AppDatabase _database;
  bool _isExecuting = false;

  SyncRuleExecutor({required AppDatabase database}) : _database = database;

  bool get isExecuting => _isExecuting;

  /// Execute all sync rules and return results for newly queued items.
  ///
  /// [downloads] is the current download state map from DownloadProvider.
  /// [metadata] is the current metadata map from DownloadProvider.
  /// [queueSingleDownload] is a callback to queue a single episode via DownloadProvider.
  Future<List<SyncRuleResult>> executeSyncRules({
    required MultiServerManager serverManager,
    required Map<String, DownloadProgress> downloads,
    required Map<String, PlexMetadata> metadata,
    required Future<bool> Function(PlexMetadata episode, PlexClient client, {int mediaIndex}) queueSingleDownload,
  }) async {
    if (_isExecuting) {
      appLogger.d('Sync rule execution already in progress, skipping');
      return [];
    }

    // Respect WiFi-only setting
    if (await DownloadManagerService.shouldBlockDownloadOnCellular()) {
      appLogger.d('Skipping sync rules — cellular download blocked');
      return [];
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

      return results;
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

    // Collect all unwatched episodes from server
    final unwatchedEpisodes = <PlexMetadata>[];
    if (rule.targetType == ContentTypes.show) {
      await _collectUnwatchedForShow(client, rule.serverId, rule.ratingKey, unwatchedEpisodes);
    } else {
      await _collectUnwatchedForSeason(client, rule.serverId, rule.ratingKey, unwatchedEpisodes);
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

    // Get display title from metadata
    final displayTitle = metadata[rule.globalKey]?.title;
    appLogger.i('Sync rule ${rule.globalKey}: queued $queued episodes (had $alreadyHave/$targetCount)');

    return SyncRuleResult(globalKey: rule.globalKey, title: displayTitle, queuedCount: queued);
  }

  static bool _isActiveDownload(DownloadProgress? p) =>
      p != null &&
      (p.status == DownloadStatus.completed || p.status == DownloadStatus.downloading || p.status == DownloadStatus.queued);

  Future<void> _collectUnwatchedForShow(
    PlexClient client,
    String serverId,
    String showRatingKey,
    List<PlexMetadata> out,
  ) async {
    final seasons = await client.getChildren(showRatingKey);
    for (final season in seasons) {
      if (season.type == ContentTypes.season) {
        await _collectUnwatchedForSeason(client, serverId, season.ratingKey, out);
      }
    }
  }

  Future<void> _collectUnwatchedForSeason(
    PlexClient client,
    String serverId,
    String seasonRatingKey,
    List<PlexMetadata> out,
  ) async {
    final episodes = await client.getChildren(seasonRatingKey);
    for (final ep in episodes) {
      if (ep.type == 'episode' && !ep.isWatched && !ep.hasActiveProgress) {
        out.add(ep);
      }
    }
  }
}
