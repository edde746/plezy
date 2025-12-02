import 'dart:async';

import '../mpv/mpv.dart';

import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';

/// Tracks playback progress and reports it to the Plex server.
///
/// Handles:
/// - Periodic timeline updates during playback
/// - Resume position tracking
/// - State change reporting (playing, paused, stopped)
class PlaybackProgressTracker {
  final PlexClient client;
  final PlexMetadata metadata;
  final Player player;

  /// Timer for periodic progress updates
  Timer? _progressTimer;

  /// Update interval (default: 10 seconds)
  final Duration updateInterval;

  PlaybackProgressTracker({
    required this.client,
    required this.metadata,
    required this.player,
    this.updateInterval = const Duration(seconds: 10),
  });

  /// Start tracking playback progress
  ///
  /// Begins periodic timeline updates to the Plex server.
  void startTracking() {
    if (_progressTimer != null) {
      appLogger.w('Progress tracking already started');
      return;
    }

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (player.state.playing) {
        _sendProgress('playing');
      }
    });

    appLogger.d(
      'Started progress tracking (interval: ${updateInterval.inSeconds}s)',
    );
  }

  /// Stop tracking playback progress
  ///
  /// Cancels the periodic timer.
  void stopTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
    appLogger.d('Stopped progress tracking');
  }

  /// Send progress update to Plex server
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

      // Build timeline query parameters
      final queryParams = {
        'ratingKey': metadata.ratingKey,
        'key': '/library/metadata/${metadata.ratingKey}',
        'state': state,
        'time': position.inMilliseconds.toString(),
        'duration': duration.inMilliseconds.toString(),
      };

      // Add playQueueItemID if available (for playlist/shuffle playback)
      if (metadata.playQueueItemID != null) {
        queryParams['playQueueItemID'] = metadata.playQueueItemID.toString();
      }

      // Send timeline update
      await client
          .updateProgress(
            metadata.ratingKey,
            time: position.inMilliseconds,
            state: state,
            duration: duration.inMilliseconds,
          )
          .catchError((error) {
            // Silent handling - don't interrupt playback for progress errors
            appLogger.d(
              'Failed to update progress (non-critical)',
              error: error,
            );
          });

      appLogger.d(
        'Progress update sent: $state at ${position.inSeconds}s / ${duration.inSeconds}s',
      );
    } catch (e) {
      appLogger.d('Failed to send progress update (non-critical)', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
