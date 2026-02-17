import '../models/download_settings.dart';
import '../models/download_models.dart';
import '../models/plex_metadata.dart';
import '../providers/download_provider.dart';
import '../services/download_storage_service.dart';
import '../services/plex_client.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

/// Service that automatically checks for and downloads new episodes
/// of shows that the user has subscribed to (partially or fully downloaded).
/// Also handles watched episode cleanup based on per-series retention settings.
class AutoDownloadService {
  bool _isChecking = false;
  DateTime? _lastCheckTime;

  /// Minimum interval between auto-download checks to prevent excessive API calls
  static const Duration minCheckInterval = Duration(minutes: 5);

  /// Refresh a show or season respecting per-series download settings.
  /// Called by the manual refresh button and detail page.
  /// Returns the number of newly queued episodes.
  Future<int> refreshShow(PlexMetadata metadata, PlexClient client, DownloadProvider downloadProvider) async {
    final settingsService = await SettingsService.getInstance();

    // For seasons, look up the parent show's settings
    final isShow = metadata.type.toLowerCase() == 'show';
    final isSeason = metadata.type.toLowerCase() == 'season';
    final showRatingKey = isShow
        ? metadata.ratingKey
        : isSeason
            ? metadata.parentRatingKey
            : null;

    // Only apply per-series logic for shows/seasons
    if (showRatingKey == null) {
      return await downloadProvider.queueMissingEpisodes(metadata, client);
    }

    final perShowSettings = settingsService.getDownloadSettings(showRatingKey);

    if (perShowSettings == null) {
      // No per-series settings — use legacy behavior (queue all missing)
      return await downloadProvider.queueMissingEpisodes(metadata, client);
    }

    // For seasons: if per-show settings exist, operate on the whole show
    // (smart queueing needs the full episode list across all seasons)
    PlexMetadata show;
    if (isShow) {
      show = metadata;
    } else {
      // Fetch the show metadata
      final showMeta = await client.getMetadataWithImages(showRatingKey);
      if (showMeta == null) {
        return await downloadProvider.queueMissingEpisodes(metadata, client);
      }
      show = showMeta.serverId != null ? showMeta : showMeta.copyWith(serverId: metadata.serverId);
    }

    // Fetch the full episode list once — shared by queue, cleanup, and trim
    final allEpisodes = await _fetchAllEpisodes(show, client);

    // 1. Cleanup watched episodes based on retention mode
    await _cleanupWatchedEpisodes(show, allEpisodes, client, downloadProvider, settingsService, perShowSettings);

    int queued = 0;
    if (perShowSettings.downloadAllEpisodes) {
      queued = await downloadProvider.queueMissingEpisodes(show, client);
    } else {
      // Smart queue: keep last N unwatched
      final targetKeys = _computeTargetEpisodeKeys(allEpisodes, perShowSettings.episodeCount);
      queued = await _queueSmartEpisodes(allEpisodes, targetKeys, downloadProvider, client);
      // Trim: delete downloaded episodes outside the target window
      await _trimExcessEpisodes(show, targetKeys, downloadProvider);
    }

    return queued;
  }

  /// Check for new episodes of subscribed shows and queue them for download.
  Future<void> checkForNewEpisodes(PlexClient client, DownloadProvider downloadProvider) async {
    if (_isChecking) {
      appLogger.d('Auto-download: Already checking, skipping');
      return;
    }

    if (_lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < minCheckInterval) {
        appLogger.d('Auto-download: Checked ${elapsed.inSeconds}s ago, skipping (min ${minCheckInterval.inMinutes}m)');
        return;
      }
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();

    try {
      final settingsService = await SettingsService.getInstance();
      final autoDownloadNewEpisodes = settingsService.getAutoDownloadNewEpisodes();
      final autoDownloadNewSeasons = settingsService.getAutoDownloadNewSeasons();

      final storageService = DownloadStorageService.instance;
      final storageAvailable = await storageService.isStorageAvailable();

      if (!storageAvailable) {
        appLogger.d('Auto-download: Storage unavailable, skipping check');
        return;
      }

      final subscribedShows = downloadProvider.getSubscribedShows();

      if (subscribedShows.isEmpty) {
        appLogger.d('Auto-download: No subscribed shows found');
        return;
      }

      appLogger.i('Auto-download: Checking ${subscribedShows.length} subscribed shows for new episodes');

      int totalQueued = 0;

      for (final show in subscribedShows) {
        if (show.serverId != client.serverId) {
          continue;
        }

        try {
          final perShowSettings = settingsService.getDownloadSettings(show.ratingKey);

          if (perShowSettings != null) {
            // PER-SERIES: use refreshShow which handles queue + cleanup + trim
            final queued = await refreshShow(show, client, downloadProvider);
            totalQueued += queued;
          } else {
            // EXISTING GLOBAL BEHAVIOR (unchanged)
            if (!autoDownloadNewEpisodes && !autoDownloadNewSeasons) {
              continue;
            }

            if (autoDownloadNewSeasons) {
              final queued = await downloadProvider.queueMissingEpisodes(show, client);
              if (queued > 0) {
                appLogger.i('Auto-download: Queued $queued new episodes for "${show.title}" (all seasons)');
                totalQueued += queued;
              }
            } else {
              final seasons = downloadProvider.getDownloadedSeasonsForShow(show.ratingKey);
              for (final season in seasons) {
                final queued = await downloadProvider.queueMissingEpisodes(season, client);
                if (queued > 0) {
                  appLogger.i('Auto-download: Queued $queued new episodes for "${show.title}" ${season.title}');
                  totalQueued += queued;
                }
              }
            }
          }
        } catch (e) {
          appLogger.d('Auto-download: Error checking show "${show.title}": $e');
        }
      }

      if (totalQueued > 0) {
        appLogger.i('Auto-download: Total $totalQueued new episodes queued');
      } else {
        appLogger.d('Auto-download: No new episodes found');
      }
    } catch (e) {
      appLogger.d('Auto-download: Error during check: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Fetch all episodes for a show, sorted by season+episode index.
  Future<List<PlexMetadata>> _fetchAllEpisodes(PlexMetadata show, PlexClient client) async {
    final seasons = await client.getChildren(show.ratingKey);
    final allEpisodes = <PlexMetadata>[];
    final seasonList = seasons.where((s) => s.type == 'season').toList();
    seasonList.sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    for (final season in seasonList) {
      final episodes = await client.getChildren(season.ratingKey);
      final seasonEpisodes = episodes.where((e) => e.type == 'episode').toList();
      seasonEpisodes.sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

      for (final ep in seasonEpisodes) {
        allEpisodes.add(ep.serverId != null ? ep : ep.copyWith(serverId: show.serverId));
      }
    }

    return allEpisodes;
  }

  /// Compute the set of globalKeys that should be in the "keep last N" window.
  Set<String> _computeTargetEpisodeKeys(List<PlexMetadata> allEpisodes, int keepCount) {
    if (allEpisodes.isEmpty) return {};

    // Find the first unwatched episode
    int firstUnwatchedIdx = allEpisodes.length;
    for (int i = 0; i < allEpisodes.length; i++) {
      if (allEpisodes[i].viewCount == null || allEpisodes[i].viewCount == 0) {
        firstUnwatchedIdx = i;
        break;
      }
    }

    final endIdx = (firstUnwatchedIdx + keepCount).clamp(0, allEpisodes.length);
    final targetEpisodes = allEpisodes.sublist(firstUnwatchedIdx, endIdx);

    return targetEpisodes.map((e) => '${e.serverId}:${e.ratingKey}').toSet();
  }

  /// Queue episodes that are in the target window but not yet downloaded.
  Future<int> _queueSmartEpisodes(
    List<PlexMetadata> allEpisodes,
    Set<String> targetKeys,
    DownloadProvider downloadProvider,
    PlexClient client,
  ) async {
    int queuedCount = 0;

    for (final episode in allEpisodes) {
      final globalKey = '${episode.serverId}:${episode.ratingKey}';
      if (!targetKeys.contains(globalKey)) continue;

      final progress = downloadProvider.getProgress(globalKey);
      if (progress == null ||
          (progress.status != DownloadStatus.completed &&
              progress.status != DownloadStatus.downloading &&
              progress.status != DownloadStatus.queued)) {
        await downloadProvider.queueDownload(episode, client);
        queuedCount++;
        appLogger.d('Auto-download: Smart-queued episode: ${episode.title} ($globalKey)');
      }
    }

    return queuedCount;
  }

  /// Delete downloaded episodes that are outside the target "keep last N" window.
  /// Only removes completed downloads — never touches in-progress ones.
  Future<void> _trimExcessEpisodes(
    PlexMetadata show,
    Set<String> targetKeys,
    DownloadProvider downloadProvider,
  ) async {
    final downloadedEpisodes = downloadProvider.getDownloadedEpisodesForShow(show.ratingKey);

    for (final meta in downloadedEpisodes) {
      final globalKey = meta.globalKey;
      if (targetKeys.contains(globalKey)) continue;

      // This episode is downloaded but outside the keep window — delete it
      await downloadProvider.deleteDownload(globalKey);
      appLogger.i('Auto-download: Trimmed episode outside keep window: ${meta.title} ($globalKey)');
    }
  }

  /// Clean up watched episodes based on retention settings.
  Future<void> _cleanupWatchedEpisodes(
    PlexMetadata show,
    List<PlexMetadata> allEpisodes,
    PlexClient client,
    DownloadProvider downloadProvider,
    SettingsService settingsService,
    DownloadSettings settings,
  ) async {
    final downloadedEpisodes = downloadProvider.getDownloadedEpisodesForShow(show.ratingKey);
    if (downloadedEpisodes.isEmpty) return;

    // Build a map of ratingKey -> fresh metadata from the already-fetched episode list
    final freshMetaByRatingKey = <String, PlexMetadata>{};
    for (final ep in allEpisodes) {
      freshMetaByRatingKey[ep.ratingKey] = ep;
    }

    for (final meta in downloadedEpisodes) {
      final globalKey = meta.globalKey;
      try {
        // Use fresh metadata from the already-fetched list (avoids extra API calls)
        final freshMeta = freshMetaByRatingKey[meta.ratingKey] ?? meta;

        final isWatched = (freshMeta.viewCount ?? 0) > 0;
        if (!isWatched) {
          await settingsService.clearWatchedDetectedAt(globalKey);
          continue;
        }

        // Episode is watched — determine effective watched time
        DateTime? localDetectedAt = settingsService.getWatchedDetectedAt(globalKey);
        if (localDetectedAt == null) {
          localDetectedAt = DateTime.now();
          await settingsService.setWatchedDetectedAt(globalKey, localDetectedAt);
        }

        DateTime? serverWatchedAt;
        if (freshMeta.lastViewedAt != null) {
          serverWatchedAt = DateTime.fromMillisecondsSinceEpoch(freshMeta.lastViewedAt! * 1000);
        }

        final effectiveWatchedTime = (serverWatchedAt != null && serverWatchedAt.isBefore(localDetectedAt))
            ? serverWatchedAt
            : localDetectedAt;

        switch (settings.deleteMode) {
          case DeleteRetentionMode.onNextRefresh:
            await downloadProvider.deleteDownload(globalKey);
            await settingsService.clearWatchedDetectedAt(globalKey);
            appLogger.i('Auto-download: Deleted watched episode $globalKey (onNextRefresh)');
            break;

          case DeleteRetentionMode.afterDays:
            final retentionPeriod = Duration(days: settings.retentionValue);
            if (DateTime.now().difference(effectiveWatchedTime) > retentionPeriod) {
              await downloadProvider.deleteDownload(globalKey);
              await settingsService.clearWatchedDetectedAt(globalKey);
              appLogger.i(
                'Auto-download: Deleted watched episode $globalKey (after ${settings.retentionValue} days)',
              );
            }
            break;

          case DeleteRetentionMode.afterWeeks:
            final retentionPeriod = Duration(days: settings.retentionValue * 7);
            if (DateTime.now().difference(effectiveWatchedTime) > retentionPeriod) {
              await downloadProvider.deleteDownload(globalKey);
              await settingsService.clearWatchedDetectedAt(globalKey);
              appLogger.i(
                'Auto-download: Deleted watched episode $globalKey (after ${settings.retentionValue} weeks)',
              );
            }
            break;
        }
      } catch (e) {
        appLogger.d('Auto-download: Error cleaning up episode $globalKey: $e');
      }
    }
  }
}
