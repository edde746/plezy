import 'dart:async';

import '../utils/app_logger.dart';

/// Arbitrates the one-native-player-instance rule between the music engine
/// and the video player.
///
/// Only one native playback core should be kept alive at a time: the music
/// service's audio `Player` lives across screens, while the video core is
/// owned by its screen and may finish retiring after the route is removed.
/// The video screen calls
/// [claimVideo] at the very start of its player initialization so a playing
/// music session is fully stopped *and its native core disposed* before the
/// video core is constructed.
class PlaybackCoordinator {
  PlaybackCoordinator._();

  static final PlaybackCoordinator instance = PlaybackCoordinator._();

  Future<void> Function()? _stopMusicSession;

  Future<void> Function()? _shutdownVideoSession;
  Future<bool> Function()? _exitVideoSession;
  final Set<Future<void>> _videoRetirements = {};

  bool get hasVideoSession => _shutdownVideoSession != null || _videoRetirements.isNotEmpty;

  /// Explicit user/agent stop, unlike shutdown, also leaves the player route.
  /// False means the owner requires a confirmation or cannot leave its route.
  Future<bool> stopVideoAndExit() async {
    var exited = _shutdownVideoSession == null;
    await Future.wait<void>([
      ..._videoRetirements,
      if (_exitVideoSession case final exit?)
        Future<bool>.sync(exit).then<void>((value) {
          exited = value;
        }),
    ]);
    return exited;
  }

  /// Register the screen that owns video, before its asynchronous startup.
  void registerVideoSession({required Future<void> Function() shutdown, Future<bool> Function()? stopAndExit}) {
    _shutdownVideoSession = shutdown;
    _exitVideoSession = stopAndExit;
  }

  /// A replaced screen must not release its successor's registration.
  /// Retirement remains owned independently until cleanup settles.
  void unregisterVideoSession(Future<void> Function() shutdown, {Future<void>? retirement}) {
    if (_shutdownVideoSession == shutdown) {
      _shutdownVideoSession = null;
      _exitVideoSession = null;
    }
    if (retirement == null || !_videoRetirements.add(retirement)) return;
    unawaited(
      retirement.then<void>(
        (_) {
          _videoRetirements.remove(retirement);
        },
        onError: (Object error, StackTrace stackTrace) {
          _videoRetirements.remove(retirement);
          appLogger.w('PlaybackCoordinator: video retirement failed', error: error, stackTrace: stackTrace);
        },
      ),
    );
  }

  /// Quiesce video and await its native stop, final report and pending retirements.
  /// The owner coalesces repeated calls; the application owns the deadline.
  Future<void> shutdownVideo() async {
    await Future.wait<void>([
      ..._videoRetirements,
      if (_shutdownVideoSession case final shutdown?) Future<void>.sync(shutdown),
    ]);
  }

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

  /// Music playback is about to construct its audio core. Currently a no-op:
  /// music cannot be started from inside the video screen, but bounded route
  /// exit can expose music UI while video cleanup is still retiring.
  /// This hook does not currently serialize music startup with that cleanup.
  Future<void> claimMusic() async {}
}
