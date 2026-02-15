import 'dart:async';

import '../mpv/mpv.dart';

import 'plex_client.dart';
import 'offline_watch_sync_service.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/watch_state_notifier.dart';

/// Tracks playback progress and reports it to the Plex server.
///
/// Handles:
/// - Periodic timeline updates during playback (online) or queuing (offline)
/// - Resume position tracking
/// - State change reporting (playing, paused, stopped)
/// - Offline progress queuing for later sync
class PlaybackProgressTracker {
  /// Plex client for online progress updates (null when offline)
  final PlexClient? client;

  /// Metadata of the media being played
  final PlexMetadata metadata;

  /// Video player instance
  final Player player;

  /// Whether playback is in offline mode
  final bool isOffline;

  /// Service for queuing offline progress updates
  final OfflineWatchSyncService? offlineWatchService;

  /// Timer for periodic progress updates
  Timer? _progressTimer;

  /// Update interval (default: 10 seconds)
  final Duration updateInterval;

  /// Counts consecutive online progress failures for backoff logic.
  int _consecutiveFailures = 0;

  /// Timer ticks to skip before retrying after failures (exponential backoff).
  int _ticksToSkip = 0;

  PlaybackProgressTracker({
    required this.client,
    required this.metadata,
    required this.player,
    this.isOffline = false,
    this.offlineWatchService,
    this.updateInterval = const Duration(seconds: 10),
  }) : assert(!isOffline || offlineWatchService != null, 'offlineWatchService is required when isOffline is true'),
       assert(isOffline || client != null, 'client is required when isOffline is false');

  /// Start tracking playback progress
  ///
  /// Begins periodic timeline updates to the Plex server (online)
  /// or queuing progress updates locally (offline).
  void startTracking() {
    if (_progressTimer != null) {
      appLogger.w('Progress tracking already started');
      return;
    }

    // Send initial progress immediately (don't wait for first timer tick)
    if (player.state.playing) {
      _sendProgress('playing');
    }

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (player.state.playing) {
        // Skip ticks when backing off after consecutive failures to avoid
        // flooding the network with doomed requests during an outage.
        if (_ticksToSkip > 0) {
          _ticksToSkip--;
          return;
        }
        _sendProgress('playing');
      }
    });

    appLogger.d('Started progress tracking (interval: ${updateInterval.inSeconds}s, offline: $isOffline)');
  }

  /// Stop tracking playback progress
  ///
  /// Cancels the periodic timer.
  void stopTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
    appLogger.d('Stopped progress tracking');
  }

  /// Send progress update to Plex server or queue locally
  ///
  /// [state] can be 'playing', 'paused', or 'stopped'
  Future<void> sendProgress(String state) async {
    await _sendProgress(state);
  }

  Future<void> _sendProgress(String state) async {
    try {
      final position = player.state.position;
      final duration = player.state.duration;

      // Don't send progress if no duration (not ready)
      if (duration.inMilliseconds == 0) {
        return;
      }

      if (isOffline) {
        // Queue progress update for later sync
        await _sendOfflineProgress(position, duration);
      } else if (state == 'stopped') {
        // Stopped must complete before disposal
        await _sendOnlineProgress(state, position, duration);
        _resetBackoff();
      } else {
        // Fire-and-forget for playing/paused — avoid blocking the Dart event loop
        _sendOnlineProgress(state, position, duration).then((_) {
          _resetBackoff();
        }).catchError((Object e) {
          _consecutiveFailures++;
          // Exponential backoff: skip 1, 2, 4, 8... ticks (capped at 6 ≈ 60s)
          _ticksToSkip = (1 << (_consecutiveFailures - 1)).clamp(1, 6);
          appLogger.d(
            'Progress update failed ($_consecutiveFailures consecutive), '
            'skipping next $_ticksToSkip tick(s)',
            error: e,
          );
        });
      }

      // Emit watch state event on stop for UI updates across screens
      if (state == 'stopped' && position.inMilliseconds > 0) {
        WatchStateNotifier().notifyProgress(
          metadata: metadata,
          viewOffset: position.inMilliseconds,
          duration: duration.inMilliseconds,
        );
      }
    } catch (e) {
      if (!isOffline) {
        _consecutiveFailures++;
        _ticksToSkip = (1 << (_consecutiveFailures - 1)).clamp(1, 6);
        appLogger.d(
          'Progress update failed ($_consecutiveFailures consecutive), '
          'skipping next $_ticksToSkip tick(s)',
          error: e,
        );
      } else {
        appLogger.d('Failed to send progress update (non-critical)', error: e);
      }
    }
  }

  void _resetBackoff() {
    if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
      _ticksToSkip = 0;
    }
  }

  /// Send progress update to Plex server (online mode)
  Future<void> _sendOnlineProgress(String state, Duration position, Duration duration) async {
    await client!.updateProgress(
      metadata.ratingKey,
      time: position.inMilliseconds,
      state: state,
      duration: duration.inMilliseconds,
    );
  }

  /// Queue progress update locally (offline mode)
  Future<void> _sendOfflineProgress(Duration position, Duration duration) async {
    final serverId = metadata.serverId;
    if (serverId == null) {
      appLogger.w('Cannot queue offline progress: serverId is null');
      return;
    }

    await offlineWatchService!.queueProgressUpdate(
      serverId: serverId,
      ratingKey: metadata.ratingKey,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
    );

    final percent = (position.inMilliseconds / duration.inMilliseconds * 100);
    appLogger.d(
      'Offline progress queued: ${position.inSeconds}s / ${duration.inSeconds}s (${percent.toStringAsFixed(1)}%)',
    );
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
