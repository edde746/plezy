import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../providers/offline_mode_provider.dart';
import '../utils/app_logger.dart';
import 'multi_server_manager.dart';
import 'plex_api_cache.dart';
import 'plex_client.dart';

/// Service for managing offline watch progress and syncing to Plex servers.
///
/// Handles:
/// - Queuing progress updates when offline
/// - Queuing manual watch/unwatch actions
/// - Auto-marking items as watched at 90% threshold
/// - Syncing queued actions when connectivity is restored
class OfflineWatchSyncService extends ChangeNotifier {
  final AppDatabase _database;
  final MultiServerManager _serverManager;

  OfflineModeProvider? _offlineModeProvider;
  VoidCallback? _offlineModeListener;
  bool _isSyncing = false;
  bool _isBidirectionalSyncing = false;
  DateTime? _lastSyncTime;
  bool _hasPerformedStartupSync = false;

  /// Callback to refresh download provider metadata after sync
  VoidCallback? onWatchStatesRefreshed;

  /// Watch threshold - mark as watched when progress exceeds this percentage
  static const double watchedThreshold = 0.90;

  /// Minimum interval between syncs.
  /// Mobile: no throttle (always sync on resume for cross-device updates)
  /// Desktop: 2 minutes (reduced from 10 min to handle tab-switching better)
  static Duration get minSyncInterval {
    if (Platform.isIOS || Platform.isAndroid) {
      return Duration.zero;
    }
    return const Duration(minutes: 2);
  }

  /// Maximum sync attempts before giving up on an item
  static const int maxSyncAttempts = 5;

  OfflineWatchSyncService({required AppDatabase database, required MultiServerManager serverManager})
    : _database = database,
      _serverManager = serverManager;

  /// Whether a sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Start monitoring for connectivity changes to auto-sync
  void startConnectivityMonitoring(OfflineModeProvider offlineModeProvider) {
    // Remove previous listener if any
    if (_offlineModeProvider != null && _offlineModeListener != null) {
      _offlineModeProvider!.removeListener(_offlineModeListener!);
    }

    _offlineModeProvider = offlineModeProvider;
    _offlineModeListener = () {
      if (!offlineModeProvider.isOffline) {
        // We just came online - trigger bidirectional sync
        appLogger.i('Connectivity restored - starting bidirectional watch sync');
        _performBidirectionalSync();
      }
    };

    offlineModeProvider.addListener(_offlineModeListener!);

    // Don't sync on startup - servers aren't connected yet.
    // Sync will happen when:
    // - Connectivity is restored (listener triggers)
    // - App resumes from background (onAppResumed)
  }

  /// Perform bidirectional sync: push local changes, then pull server states.
  ///
  /// Push always happens immediately. Pull respects [minSyncInterval] unless [force] is true.
  Future<void> _performBidirectionalSync({bool force = false}) async {
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
    if (_offlineModeProvider?.isOffline != true) {
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
    if (_hasPerformedStartupSync) return;
    _hasPerformedStartupSync = true;

    if (_offlineModeProvider?.isOffline != true) {
      appLogger.i('Servers connected - performing startup sync');
      _performBidirectionalSync();
    }
  }

  /// Queue a progress update for later sync.
  ///
  /// This is called during offline playback to track the watch position.
  /// If progress exceeds 90%, shouldMarkWatched is set to true.
  Future<void> queueProgressUpdate({
    required String serverId,
    required String ratingKey,
    required int viewOffset,
    required int duration,
  }) async {
    final shouldMarkWatched = isWatchedByProgress(viewOffset, duration);

    await _database.upsertProgressAction(
      serverId: serverId,
      ratingKey: ratingKey,
      viewOffset: viewOffset,
      duration: duration,
      shouldMarkWatched: shouldMarkWatched,
    );

    appLogger.d(
      'Queued offline progress: $serverId:$ratingKey at ${(viewOffset / 1000).toStringAsFixed(0)}s / ${(duration / 1000).toStringAsFixed(0)}s (${((viewOffset / duration) * 100).toStringAsFixed(1)}%)',
    );

    notifyListeners();
  }

  /// Queue a manual "mark as watched" action.
  ///
  /// Removes any conflicting actions for the same item.
  Future<void> queueMarkWatched({required String serverId, required String ratingKey}) =>
      _queueWatchStatusAction(serverId: serverId, ratingKey: ratingKey, actionType: 'watched');

  /// Queue a manual "mark as unwatched" action.
  ///
  /// Removes any conflicting actions for the same item.
  Future<void> queueMarkUnwatched({required String serverId, required String ratingKey}) =>
      _queueWatchStatusAction(serverId: serverId, ratingKey: ratingKey, actionType: 'unwatched');

  /// Internal helper to queue watch/unwatch actions.
  Future<void> _queueWatchStatusAction({
    required String serverId,
    required String ratingKey,
    required String actionType,
  }) async {
    await _database.insertWatchAction(serverId: serverId, ratingKey: ratingKey, actionType: actionType);

    appLogger.d('Queued offline mark $actionType: $serverId:$ratingKey');
    notifyListeners();
  }

  /// Check if an item should be considered watched based on progress percentage.
  bool isWatchedByProgress(int viewOffset, int duration) {
    if (duration == 0) return false;
    return (viewOffset / duration) >= watchedThreshold;
  }

  /// Get the local watch status for a media item.
  ///
  /// Returns:
  /// - `true` if item was marked as watched locally or progress >= 90%
  /// - `false` if item was marked as unwatched locally
  /// - `null` if no local action exists (use cached server data)
  Future<bool?> getLocalWatchStatus(String globalKey) async {
    final action = await _database.getLatestWatchAction(globalKey);
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
  Future<Map<String, bool?>> getLocalWatchStatusesBatched(Set<String> globalKeys) async {
    if (globalKeys.isEmpty) return {};

    final actions = await _database.getLatestWatchActionsForKeys(globalKeys);
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
  Future<int?> getLocalViewOffset(String globalKey) async {
    final action = await _database.getLatestWatchAction(globalKey);
    if (action == null) return null;

    // Only return offset for progress actions
    if (action.actionType == 'progress') {
      return action.viewOffset;
    }

    return null;
  }

  /// Get count of pending sync items.
  Future<int> getPendingSyncCount() async {
    return _database.getPendingSyncCount();
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
      final pendingActions = await _database.getPendingWatchActions();

      if (pendingActions.isEmpty) {
        appLogger.d('No pending watch actions to sync');
        return;
      }

      appLogger.i('Syncing ${pendingActions.length} pending watch actions');

      // First pass: handle retry limit exceeded and group by server
      final actionsByServer = <String, List<OfflineWatchProgressItem>>{};

      for (final action in pendingActions) {
        // Delete items that have exceeded retry limit
        if (action.syncAttempts >= maxSyncAttempts) {
          appLogger.w(
            'Deleting action ${action.id} - exceeded retry limit '
            '(${action.syncAttempts} attempts). Last error: ${action.lastError}',
          );
          await _database.deleteWatchAction(action.id);
          continue;
        }

        // Check if server still exists
        if (_serverManager.getServer(action.serverId) == null) {
          appLogger.w('Deleting action ${action.id} - server ${action.serverId} no longer exists');
          await _database.deleteWatchAction(action.id);
          continue;
        }

        actionsByServer.putIfAbsent(action.serverId, () => []).add(action);
      }

      // Second pass: process each server's actions with single connectivity check
      for (final entry in actionsByServer.entries) {
        final serverId = entry.key;
        final actions = entry.value;

        await _withOnlineClient(serverId, (client) async {
          for (final action in actions) {
            try {
              await _syncAction(client, action);
              // Success - delete the action from queue
              await _database.deleteWatchAction(action.id);
              appLogger.d('Successfully synced action ${action.id}: ${action.actionType} for ${action.ratingKey}');
            } catch (e) {
              appLogger.w('Failed to sync action ${action.id}: $e');
              await _database.updateSyncAttempt(action.id, e.toString());
            }
          }
        });

        // If _withOnlineClient returned null (server offline), mark actions for retry
        if (_serverManager.getClient(serverId) == null || !_serverManager.isServerOnline(serverId)) {
          for (final action in actions) {
            // Only update if we haven't already processed it
            final stillPending = await _database.getLatestWatchAction('${action.serverId}:${action.ratingKey}');
            if (stillPending != null && stillPending.id == action.id) {
              await _database.updateSyncAttempt(action.id, 'Server not available');
            }
          }
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Execute a callback with an online client for the given server.
  ///
  /// Returns null if no client available or server is offline.
  /// The callback receives the PlexClient and should return the result.
  Future<T?> _withOnlineClient<T>(String serverId, Future<T> Function(PlexClient client) callback) async {
    final client = _serverManager.getClient(serverId);
    if (client == null) {
      appLogger.d('No client for server $serverId, skipping');
      return null;
    }

    if (!_serverManager.isServerOnline(serverId)) {
      appLogger.d('Server $serverId is offline, skipping');
      return null;
    }

    return callback(client);
  }

  /// Sync a single action to the server.
  Future<void> _syncAction(PlexClient client, OfflineWatchProgressItem action) async {
    switch (action.actionType) {
      case 'watched':
        await client.markAsWatched(action.ratingKey);
        break;

      case 'unwatched':
        await client.markAsUnwatched(action.ratingKey);
        break;

      case 'progress':
        // First, update the timeline with current position
        if (action.viewOffset != null && action.duration != null) {
          await client.updateProgress(
            action.ratingKey,
            time: action.viewOffset!,
            state: 'stopped', // Use 'stopped' since we're syncing after the fact
            duration: action.duration,
          );
        }

        // If progress exceeded threshold, also mark as watched
        if (action.shouldMarkWatched) {
          await client.markAsWatched(action.ratingKey);
        }
        break;
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
      // Get all downloaded items from database
      final downloadedItems = await _database.getAllDownloadedMetadata();

      if (downloadedItems.isEmpty) {
        appLogger.d('No downloaded items to sync watch states for');
        return;
      }

      appLogger.i('Syncing watch states from server for ${downloadedItems.length} items');

      // Separate episodes (with season parent) from other items (movies, etc.)
      // Structure: serverId -> seasonRatingKey -> Set<episodeRatingKey>
      final episodesByServerAndSeason = <String, Map<String, Set<String>>>{};
      // Structure: serverId -> List<ratingKey>
      final nonEpisodeItems = <String, List<String>>{};

      for (final item in downloadedItems) {
        if (item.type == 'episode' && item.parentRatingKey != null) {
          // Group episodes by server and season for batch fetching
          episodesByServerAndSeason
              .putIfAbsent(item.serverId, () => {})
              .putIfAbsent(item.parentRatingKey!, () => {})
              .add(item.ratingKey);
        } else {
          // Movies, or episodes without parent (fallback to individual fetch)
          nonEpisodeItems.putIfAbsent(item.serverId, () => []).add(item.ratingKey);
        }
      }

      int syncedCount = 0;
      int seasonCount = 0;

      // Fetch episodes by season (batch) - one API call per season
      for (final serverEntry in episodesByServerAndSeason.entries) {
        final serverId = serverEntry.key;
        final seasonMap = serverEntry.value;

        await _withOnlineClient(serverId, (client) async {
          for (final seasonEntry in seasonMap.entries) {
            final seasonRatingKey = seasonEntry.key;
            final downloadedEpisodeKeys = seasonEntry.value;

            try {
              // Fetch all episodes in this season with one API call
              final seasonEpisodes = await client.getChildren(seasonRatingKey);
              seasonCount++;

              // Cache only the episodes we have downloaded
              for (final episode in seasonEpisodes) {
                if (downloadedEpisodeKeys.contains(episode.ratingKey)) {
                  await PlexApiCache.instance.put(serverId, '/library/metadata/${episode.ratingKey}', {
                    'MediaContainer': {
                      'Metadata': [episode.toJson()],
                    },
                  });
                  syncedCount++;
                }
              }
            } catch (e) {
              appLogger.d('Failed to sync watch states for season $seasonRatingKey: $e');
            }
          }
        });
      }

      // Fetch non-episode items individually (movies, etc.)
      // Optimized to fetch in parallel batches
      for (final entry in nonEpisodeItems.entries) {
        final serverId = entry.key;
        final ratingKeys = entry.value;

        await _withOnlineClient(serverId, (client) async {
          // Process in chunks of 5 to avoid overwhelming the server
          const batchSize = 5;
          for (var i = 0; i < ratingKeys.length; i += batchSize) {
            final end = (i + batchSize < ratingKeys.length) ? i + batchSize : ratingKeys.length;
            final batch = ratingKeys.sublist(i, end);

            await Future.wait(
              batch.map((ratingKey) async {
                try {
                  final metadata = await client.getMetadataWithImages(ratingKey);
                  if (metadata != null) {
                    await PlexApiCache.instance.put(serverId, '/library/metadata/$ratingKey', {
                      'MediaContainer': {
                        'Metadata': [metadata.toJson()],
                      },
                    });
                    syncedCount++;
                  }
                } catch (e) {
                  appLogger.d('Failed to sync watch state for $ratingKey: $e');
                }
              }),
            );
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
    if (_offlineModeProvider != null && _offlineModeListener != null) {
      _offlineModeProvider!.removeListener(_offlineModeListener!);
    }
    super.dispose();
  }
}
