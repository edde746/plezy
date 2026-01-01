import 'package:flutter/foundation.dart';

import '../models/plex_metadata.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/plex_api_cache.dart';
import '../utils/watch_state_notifier.dart';
import 'download_provider.dart';

/// Provider for offline watch status UI state.
///
/// Provides:
/// - Effective watch status (local changes + cached server data)
/// - Offline "OnDeck" calculation for shows
/// - Manual mark watched/unwatched while offline
class OfflineWatchProvider extends ChangeNotifier {
  final OfflineWatchSyncService _syncService;
  final DownloadProvider _downloadProvider;
  // ignore: unused_field - reserved for future cached metadata lookup
  final PlexApiCache _apiCache;

  OfflineWatchProvider({
    required OfflineWatchSyncService syncService,
    required DownloadProvider downloadProvider,
    required PlexApiCache apiCache,
  }) : _syncService = syncService,
       _downloadProvider = downloadProvider,
       _apiCache = apiCache {
    // Listen to sync service changes to update UI
    _syncService.addListener(_onSyncServiceChanged);
  }

  void _onSyncServiceChanged() {
    notifyListeners();
  }

  /// Whether a sync is in progress
  bool get isSyncing => _syncService.isSyncing;

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() => _syncService.getPendingSyncCount();

  /// Get the effective watch status for a media item.
  ///
  /// Priority:
  /// 1. Local offline action (if exists)
  /// 2. Cached server data from API cache
  /// 3. Metadata from download provider
  ///
  /// Returns true if watched, false otherwise.
  Future<bool> isWatched(String globalKey) async {
    // First check local offline action
    final localStatus = await _syncService.getLocalWatchStatus(globalKey);
    if (localStatus != null) {
      return localStatus;
    }

    // Fall back to cached metadata
    final metadata = _downloadProvider.getMetadata(globalKey);
    if (metadata != null) {
      return metadata.isWatched;
    }

    return false;
  }

  /// Check watch status synchronously using cached metadata.
  ///
  /// This is useful for UI that can't await, but may not reflect
  /// the most recent local actions.
  bool isWatchedSync(PlexMetadata metadata) {
    // Note: This doesn't check local actions synchronously
    // because that would require async database access.
    // For real-time accuracy, use isWatched() instead.
    return metadata.isWatched;
  }

  /// Get the effective view offset (resume position) for a media item.
  ///
  /// Priority:
  /// 1. Local offline progress (if exists)
  /// 2. Metadata from download provider
  ///
  /// Returns null if no position is available.
  Future<int?> getViewOffset(String globalKey) async {
    // First check local offline progress
    final localOffset = await _syncService.getLocalViewOffset(globalKey);
    if (localOffset != null) {
      return localOffset;
    }

    // Fall back to cached metadata
    final metadata = _downloadProvider.getMetadata(globalKey);
    return metadata?.viewOffset;
  }

  /// Get sorted episodes for a show (by season, then episode number).
  List<PlexMetadata> _getSortedEpisodes(String showRatingKey) {
    final episodes = _downloadProvider.getDownloadedEpisodesForShow(showRatingKey);
    if (episodes.isEmpty) return episodes;

    episodes.sort((a, b) {
      final seasonCompare = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
      if (seasonCompare != 0) return seasonCompare;
      return (a.index ?? 0).compareTo(b.index ?? 0);
    });

    return episodes;
  }

  /// Batch resolve watch statuses for a list of episodes.
  ///
  /// Returns a map of globalKey -> isWatched for each episode.
  Future<Map<String, bool>> _resolveEpisodeWatchStatuses(List<PlexMetadata> episodes) async {
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
  Future<PlexMetadata?> getNextUnwatchedEpisode(String showRatingKey) async {
    final episodes = _getSortedEpisodes(showRatingKey);
    if (episodes.isEmpty) return null;

    final watchStatuses = await _resolveEpisodeWatchStatuses(episodes);

    // Find first unwatched episode
    for (final episode in episodes) {
      if (!watchStatuses[episode.globalKey]!) {
        return episode;
      }
    }

    // All episodes watched - return first episode for replay
    return episodes.first;
  }

  /// Find the next unwatched downloaded episode synchronously.
  ///
  /// This uses cached metadata without checking local offline actions.
  /// For real-time accuracy, use getNextUnwatchedEpisode() instead.
  PlexMetadata? getNextUnwatchedEpisodeSync(String showRatingKey) {
    final episodes = _getSortedEpisodes(showRatingKey);
    if (episodes.isEmpty) return null;

    // Find first unwatched episode (using metadata's isWatched)
    for (final episode in episodes) {
      if (!episode.isWatched) {
        return episode;
      }
    }

    // All episodes watched - return first episode for replay
    return episodes.first;
  }

  /// Mark an item as watched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsWatched({required String serverId, required String ratingKey}) async {
    await _syncService.queueMarkWatched(serverId: serverId, ratingKey: ratingKey);

    // Emit event for immediate UI update
    final globalKey = '$serverId:$ratingKey';
    final metadata = _downloadProvider.getMetadata(globalKey);
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: true);
    } else {
      // Fallback: emit minimal event without parent chain
      WatchStateNotifier().notify(
        WatchStateEvent(
          ratingKey: ratingKey,
          serverId: serverId,
          changeType: WatchStateChangeType.watched,
          parentChain: [],
          mediaType: 'unknown',
          isNowWatched: true,
        ),
      );
    }

    notifyListeners();
  }

  /// Mark an item as unwatched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsUnwatched({required String serverId, required String ratingKey}) async {
    await _syncService.queueMarkUnwatched(serverId: serverId, ratingKey: ratingKey);

    // Emit event for immediate UI update
    final globalKey = '$serverId:$ratingKey';
    final metadata = _downloadProvider.getMetadata(globalKey);
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: false);
    } else {
      // Fallback: emit minimal event without parent chain
      WatchStateNotifier().notify(
        WatchStateEvent(
          ratingKey: ratingKey,
          serverId: serverId,
          changeType: WatchStateChangeType.unwatched,
          parentChain: [],
          mediaType: 'unknown',
          isNowWatched: false,
        ),
      );
    }

    notifyListeners();
  }

  /// Get downloaded episodes for a show with their watch status.
  ///
  /// Returns a list of (episode, isWatched) pairs.
  /// Uses batched database query for efficiency.
  Future<List<(PlexMetadata episode, bool isWatched)>> getEpisodesWithWatchStatus(String showRatingKey) async {
    final episodes = _downloadProvider.getDownloadedEpisodesForShow(showRatingKey);
    if (episodes.isEmpty) return [];

    final watchStatuses = await _resolveEpisodeWatchStatuses(episodes);

    return [for (final episode in episodes) (episode, watchStatuses[episode.globalKey]!)];
  }

  /// Trigger a manual sync of pending items.
  Future<void> syncNow() async {
    await _syncService.syncPendingItems();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }
}
