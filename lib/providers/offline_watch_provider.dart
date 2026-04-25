import 'package:flutter/foundation.dart';

import '../i18n/strings.g.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_state_notifier.dart';
import 'download_provider.dart';
import '../utils/global_key_utils.dart';

/// Provider for offline watch status UI state.
///
/// Provides:
/// - Effective watch status (local changes + cached server data)
/// - Offline "OnDeck" calculation for shows
/// - Manual mark watched/unwatched while offline
class OfflineWatchProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final OfflineWatchSyncService _syncService;
  final DownloadProvider _downloadProvider;

  OfflineWatchProvider({required OfflineWatchSyncService syncService, required DownloadProvider downloadProvider})
    : _syncService = syncService,
      _downloadProvider = downloadProvider {
    // Listen to sync service changes to update UI
    _syncService.addListener(_onSyncServiceChanged);
  }

  void _onSyncServiceChanged() {
    safeNotifyListeners();
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

    // Sort Season 0 (Specials) to the end so regular seasons play first
    episodes.sort((a, b) {
      final aIsSpecial = (a.parentIndex ?? 0) == 0;
      final bIsSpecial = (b.parentIndex ?? 0) == 0;
      if (aIsSpecial != bIsSpecial) return aIsSpecial ? 1 : -1;
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
    return episodes.firstOrNull;
  }

  /// Emit a watch state change event for immediate UI update.
  void _emitWatchStateChange({
    required String serverId,
    required String ratingKey,
    required bool isNowWatched,
    required WatchStateChangeType changeType,
  }) {
    final globalKey = buildGlobalKey(serverId, ratingKey);
    final metadata = _downloadProvider.getMetadata(globalKey);
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: isNowWatched);
    } else {
      // Fallback: emit minimal event without parent chain
      WatchStateNotifier().notify(
        WatchStateEvent(
          ratingKey: ratingKey,
          serverId: serverId,
          changeType: changeType,
          parentChain: [],
          mediaType: 'unknown',
          isNowWatched: isNowWatched,
        ),
      );
    }
  }

  /// Mark an item as watched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsWatched({required String serverId, required String ratingKey}) async {
    await _syncService.queueMarkWatched(serverId: serverId, ratingKey: ratingKey);
    _emitWatchStateChange(
      serverId: serverId,
      ratingKey: ratingKey,
      isNowWatched: true,
      changeType: WatchStateChangeType.watched,
    );
    safeNotifyListeners();
    _autoDeleteIfWatched(serverId, ratingKey);
  }

  /// Auto-delete a download if the auto-remove setting is enabled.
  void _autoDeleteIfWatched(String serverId, String ratingKey) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null || !settings.read(SettingsService.autoRemoveWatchedDownloads)) return;

    final globalKey = buildGlobalKey(serverId, ratingKey);
    final meta = _downloadProvider.getMetadata(globalKey);
    if (meta == null) return;
    if (!meta.isEpisode && !meta.isMovie) return;

    final progress = _downloadProvider.downloads[globalKey];
    if (progress?.status != DownloadStatus.completed) return;

    appLogger.i('Auto-deleting locally-watched download: ${meta.title} ($globalKey)');
    _downloadProvider
        .deleteDownload(globalKey)
        .then(
          (_) {
            showMainSnackBar(t.messages.autoRemovedWatchedDownload(title: meta.title ?? 'Unknown'));
          },
          onError: (e) {
            appLogger.w('Failed to auto-delete locally-watched download $globalKey: $e');
          },
        );
  }

  /// Mark an item as unwatched while offline.
  ///
  /// This queues the action for sync when online and emits a [WatchStateEvent].
  Future<void> markAsUnwatched({required String serverId, required String ratingKey}) async {
    await _syncService.queueMarkUnwatched(serverId: serverId, ratingKey: ratingKey);
    _emitWatchStateChange(
      serverId: serverId,
      ratingKey: ratingKey,
      isNowWatched: false,
      changeType: WatchStateChangeType.unwatched,
    );
    safeNotifyListeners();
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

  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }
}
