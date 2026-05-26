import 'dart:async';

import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../multi_server_manager.dart';
import '../trakt/trakt_scrobble_service.dart';
import '../trakt/trakt_sync_service.dart';
import 'tracker_coordinator.dart';

/// Centralises all tracker service lifecycle calls so main.dart
/// never imports individual tracker implementations.
///
/// When adding a new authority-capable tracker:
///   1. Add its initialisation to [initializeWithServerManager].
///   2. Add its teardown to [dispose] / [cancelInFlight] as needed.
/// When adding a new scrobble-only tracker:
///   1. Register it in [TrackerCoordinator].
class TrackerLifecycle {
  TrackerLifecycle._();

  static Future<void> initializeScrobble() =>
      TraktScrobbleService.instance.initialize();

  /// Initialises all non-Trakt trackers (MAL, AniList, Simkl).
  /// Passed as [onFirstMount] in main.dart so initialization waits for
  /// the first widget mount (when a Plex profile is available).
  static Future<void> initializeCoordinator() =>
      TrackerCoordinator.instance.initialize();

  /// Initialises all tracker services that require a [MultiServerManager]
  /// (e.g. for GUID lookups and Plex-layer cache management).
  static void initializeWithServerManager(MultiServerManager serverManager) {
    unawaited(TraktSyncService.instance.initialize(serverManager: serverManager));
  }

  /// Starts scrobbling for a new playback session.
  static void startPlayback(MediaItem metadata, MediaServerClient client, {bool isLive = false}) {
    unawaited(TraktScrobbleService.instance.startPlayback(metadata, client, isLive: isLive));
    unawaited(TrackerCoordinator.instance.startPlayback(metadata, client, isLive: isLive));
  }

  /// Updates the current playback position for all active scrobblers.
  static void updatePosition(Duration position) {
    TraktScrobbleService.instance.updatePosition(position);
    TrackerCoordinator.instance.updatePosition(position);
  }

  /// Updates the known duration for all active scrobblers.
  static void updateDuration(Duration duration) {
    TraktScrobbleService.instance.updateDuration(duration);
    TrackerCoordinator.instance.updateDuration(duration);
  }

  /// Signals that playback resumed after a pause.
  static void resumePlayback() {
    unawaited(TraktScrobbleService.instance.resumePlayback());
  }

  /// Signals that playback was paused.
  static void pausePlayback() {
    unawaited(TraktScrobbleService.instance.pausePlayback());
  }

  /// Stops active playback scrobbling and any in-flight threshold tracking.
  /// Call this from the video player instead of importing tracker services directly.
  static Future<void> stopPlayback() async {
    unawaited(TraktScrobbleService.instance.stopPlayback());
    await TrackerCoordinator.instance.stopPlayback();
  }

  /// Cancels all in-flight tracker operations across all tracker families.
  static void cancelInFlight() {
    TrackerCoordinator.instance.cancelInFlight();
    TraktScrobbleService.instance.cancelInFlight();
  }

  static Future<void> dispose() => TraktSyncService.instance.dispose();

  static void flushQueue() => TraktSyncService.instance.flushQueue();
}
