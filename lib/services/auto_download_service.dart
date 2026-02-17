import '../providers/download_provider.dart';
import '../services/download_storage_service.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';

/// Service that automatically checks for and downloads new episodes
/// of shows that the user has subscribed to (partially or fully downloaded).
class AutoDownloadService {
  bool _isChecking = false;
  DateTime? _lastCheckTime;

  /// Minimum interval between auto-download checks to prevent excessive API calls
  static const Duration minCheckInterval = Duration(minutes: 5);

  /// Check for new episodes of subscribed shows and queue them for download.
  ///
  /// This method:
  /// 1. Throttles checks to prevent excessive API calls
  /// 2. Silently skips if storage is unavailable (for removable storage)
  /// 3. Gets subscribed shows and queues missing episodes
  Future<void> checkForNewEpisodes(
    PlexClient client,
    DownloadProvider downloadProvider,
  ) async {
    // Throttle: Skip if already checking
    if (_isChecking) {
      appLogger.d('Auto-download: Already checking, skipping');
      return;
    }

    // Throttle: Skip if checked recently
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
      // Check if storage is available (for removable storage support)
      final storageService = DownloadStorageService.instance;
      final storageAvailable = await storageService.isStorageAvailable();

      if (!storageAvailable) {
        appLogger.d('Auto-download: Storage unavailable, skipping check');
        return;
      }

      // Get shows that should auto-download new episodes
      final subscribedShows = downloadProvider.getSubscribedShows();

      if (subscribedShows.isEmpty) {
        appLogger.d('Auto-download: No subscribed shows found');
        return;
      }

      appLogger.i('Auto-download: Checking ${subscribedShows.length} subscribed shows for new episodes');

      int totalQueued = 0;

      for (final show in subscribedShows) {
        // Only check shows that match the current server
        if (show.serverId != client.serverId) {
          continue;
        }

        try {
          final queued = await downloadProvider.queueMissingEpisodes(show, client);
          if (queued > 0) {
            appLogger.i('Auto-download: Queued $queued new episodes for "${show.title}"');
            totalQueued += queued;
          }
        } catch (e) {
          // Log error but continue with other shows
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
}
