import 'dart:async';

import 'package:flutter/foundation.dart';
import '../media/ids.dart';

import '../i18n/strings.g.dart';
import '../media/episode_collection.dart';
import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_state_notifier.dart';
import 'download_provider.dart';
import '../utils/global_key_utils.dart';

/// Provider for offline watch status UI state.
///
/// Provides:
/// - Offline "OnDeck" calculation for shows
/// - Manual mark watched/unwatched while offline
class OfflineWatchProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final OfflineWatchSyncService _syncService;
  final DownloadProvider _downloadProvider;

  OfflineWatchProvider({required this._syncService, required this._downloadProvider});

  /// Get episodes for a show in the shared [sortEpisodesByWatchOrder] order,
  /// so the offline watch order matches what "download next N" selects
  /// (#1414/#1416/#1952).
  List<MediaItem> _getSortedEpisodes(String showId) {
    final episodes = _downloadProvider.getDownloadedEpisodesForShow(showId);
    if (episodes.isEmpty) return episodes;
    sortEpisodesByWatchOrder(episodes);
    return episodes;
  }

  /// Batch resolve watch statuses for a list of episodes.
  ///
  /// Returns a map of globalKey -> isWatched for each episode.
  Future<Map<String, bool>> _resolveEpisodeWatchStatuses(List<MediaItem> episodes) async {
    if (episodes.isEmpty) return {};

    final globalKeys = episodes.map((e) => e.globalKey).toSet();
    final localStatuses = await _syncService.getLocalWatchStatusesBatched(globalKeys);

    return {
      for (final episode in episodes)
        episode.globalKey:
            localStatuses[episode.globalKey] ?? _downloadProvider.getMetadata(episode.globalKey)?.isWatched ?? false,
    };
  }

  /// Find the next unwatched downloaded episode for a show.
  ///
  /// This is the "offline OnDeck" calculation - finds the first
  /// episode that hasn't been watched (or is in progress).
  ///
  /// Episodes are sorted by season number, then episode number.
  ///
  /// Returns the next unwatched episode, or the first episode if all watched.
  Future<MediaItem?> getNextUnwatchedEpisode(String showId) async {
    final episodes = _getSortedEpisodes(showId);
    if (episodes.isEmpty) return null;

    final watchStatuses = await _resolveEpisodeWatchStatuses(episodes);

    for (final episode in episodes) {
      if (!watchStatuses[episode.globalKey]!) {
        return episode;
      }
    }

    // All episodes watched - return first episode for replay
    return episodes.firstOrNull;
  }

  /// Emit a watch state change event for immediate UI update.
  void _emitWatchStateChange({
    required ServerId serverId,
    required String itemId,
    required bool isNowWatched,
    required WatchStateChangeType changeType,
    required WatchPatchId patchId,
    String? cacheServerId,
  }) {
    final globalKey = buildGlobalKey(ServerId(serverId), itemId);
    final metadata = _downloadProvider.getMetadata(globalKey);
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(
        item: metadata,
        isNowWatched: isNowWatched,
        cacheServerId: cacheServerId,
        patchId: patchId,
      );
    } else {
      // Fallback: emit minimal event without parent chain.
      WatchStateNotifier().notify(
        WatchStateEvent(
          itemId: itemId,
          serverId: serverId,
          cacheServerId: cacheServerId,
          changeType: changeType,
          parentChain: [],
          isNowWatched: isNowWatched,
          patchId: patchId,
        ),
      );
    }
  }

  /// Mark an item as watched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsWatched({required ServerId serverId, required String itemId}) async {
    final queued = await _syncService.queueMarkWatched(serverId: serverId, itemId: itemId);
    _emitWatchStateChange(
      serverId: serverId,
      itemId: itemId,
      isNowWatched: true,
      changeType: WatchStateChangeType.watched,
      cacheServerId: queued.clientScopeId,
      patchId: WatchPatchId.offlineAction(profileId: queued.profileId, rowId: queued.rowId, revision: queued.revision),
    );
    safeNotifyListeners();
    unawaited(_autoDeleteIfWatched(serverId, itemId));
  }

  /// Auto-delete a download if the auto-remove setting is enabled.
  Future<void> _autoDeleteIfWatched(ServerId serverId, String itemId) async {
    final settings = SettingsService.instanceOrNull;
    if (settings == null || !settings.read(SettingsService.autoRemoveWatchedDownloads)) return;

    final globalKey = buildGlobalKey(ServerId(serverId), itemId);
    try {
      final title = await _downloadProvider.deleteWatchedDownloadCandidate(globalKey, logContext: 'locally-watched');
      if (title != null) showMainSnackBar(t.messages.autoRemovedWatchedDownload(title: title));
    } catch (e) {
      appLogger.w('Failed to auto-delete locally-watched download $globalKey: $e');
    }
  }

  /// Mark an item as unwatched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsUnwatched({required ServerId serverId, required String itemId}) async {
    final queued = await _syncService.queueMarkUnwatched(serverId: serverId, itemId: itemId);
    _emitWatchStateChange(
      serverId: serverId,
      itemId: itemId,
      isNowWatched: false,
      changeType: WatchStateChangeType.unwatched,
      cacheServerId: queued.clientScopeId,
      patchId: WatchPatchId.offlineAction(profileId: queued.profileId, rowId: queued.rowId, revision: queued.revision),
    );
    safeNotifyListeners();
  }
}
