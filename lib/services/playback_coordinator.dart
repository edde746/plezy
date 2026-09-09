import '../utils/app_logger.dart';

/// Arbitrates the one-native-player-instance rule between the music engine
/// and the video player.
///
/// Only one native playback core is kept alive at a time: the music
/// service's audio `Player` lives across screens, while the video core only
/// exists while the video player screen is open. The video screen calls
/// [claimVideo] at the very start of its player initialization so a playing
/// music session is fully stopped *and its native core disposed* before the
/// video core is constructed.
class PlaybackCoordinator {
  PlaybackCoordinator._();

  static final PlaybackCoordinator instance = PlaybackCoordinator._();

  Future<void> Function()? _stopMusicSession;

  Future<void> Function()? _shutdownVideoSession;
  Future<bool> Function()? _exitVideoSession;

  bool get hasVideoSession => _shutdownVideoSession != null;

  /// Explicit user/agent stop, unlike shutdown, also leaves the player route.
  /// False means the owner requires a confirmation or cannot leave its route.
  Future<bool> stopVideoAndExit() async => await _exitVideoSession?.call() ?? !hasVideoSession;

  /// Register the screen that owns video, before its asynchronous startup.
  void registerVideoSession({required Future<void> Function() shutdown, Future<bool> Function()? stopAndExit}) {
    _shutdownVideoSession = shutdown;
    _exitVideoSession = stopAndExit;
  }

  /// A replaced screen must not release its successor's registration.
  void unregisterVideoSession(Future<void> Function() shutdown) {
    if (_shutdownVideoSession == shutdown) {
      _shutdownVideoSession = null;
      _exitVideoSession = null;
    }
  }

  /// Quiesce video and await its native stop and final backend report.
  /// The owner coalesces repeated calls; the application owns the deadline.
  Future<void> shutdownVideo() => _shutdownVideoSession?.call() ?? Future<void>.value();

  /// Register the active music session's teardown. [stopAndDispose] must
  /// stop playback, send final progress, and dispose the audio `Player`
  /// before completing. Replaces any previous registration (there is one
  /// music service per profile session).
  void registerMusicSession({required Future<void> Function() stopAndDispose}) {
    _stopMusicSession = stopAndDispose;
  }

  /// Remove [stopAndDispose] if it is the current registration. Passing the
  /// same callback used to register keeps a stale unregister (from an
  /// already-replaced session) from tearing down the new one.
  void unregisterMusicSession(Future<void> Function() stopAndDispose) {
    if (_stopMusicSession == stopAndDispose) _stopMusicSession = null;
  }

  /// Video playback is about to construct its native core: stop and dispose
  /// any live music session first. Completes once the audio core is gone.
  Future<void> claimVideo() async {
    final stop = _stopMusicSession;
    if (stop == null) return;
    try {
      await stop();
    } catch (e, st) {
      // The video player must still be able to start; a wedged audio core
      // is strictly worse than a leaked stop error.
      appLogger.w('PlaybackCoordinator: music session teardown failed', error: e, stackTrace: st);
    }
  }

  /// Music playback is about to construct its audio core. Currently a no-op
  /// guard: the video core only exists while the video player screen is
  /// open, and music playback cannot be started from inside that screen —
  /// leaving it disposes the video core before any music UI is reachable.
  /// Kept as an explicit seam so a future "start music over video" flow has
  /// a single place to add the reverse teardown.
  Future<void> claimMusic() async {}
}
