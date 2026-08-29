import 'dart:async';

import '../mpv/mpv.dart';
import '../utils/app_logger.dart';

/// Stops a playing music session before the video player builds its core.
///
/// The music service's audio `Player` lives across screens; the video core is
/// owned by its screen and may finish retiring after the route is removed.
/// The video screen calls [claimVideo] at the very start of its player
/// initialization so a playing music session is fully stopped *and its native
/// core disposed* before the video core is constructed — the point is that the
/// outgoing session reports its progress and gives up audio focus, not that
/// two native cores cannot coexist.
class PlaybackCoordinator {
  PlaybackCoordinator._();

  static final PlaybackCoordinator instance = PlaybackCoordinator._();

  Future<void> Function()? _stopMusicSession;
  Future<void> Function()? _stopThemeSession;
  Future<void> _claimTail = Future<void>.value();

  Future<void> Function()? _shutdownVideoSession;
  Future<bool> Function()? _exitVideoSession;
  PlayerState? Function()? _videoPlayerState;
  final Set<Future<void>> _videoRetirements = {};

  bool get hasVideoSession => _shutdownVideoSession != null || _videoRetirements.isNotEmpty;

  /// Cached state of the registered screen's player, for diagnostics that must
  /// not cost a platform-channel round trip. Null while no screen owns video,
  /// before its player is built, and for a session that is only retiring.
  PlayerState? get videoPlayerState => _videoPlayerState?.call();

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
  void registerVideoSession({
    required Future<void> Function() shutdown,
    Future<bool> Function()? stopAndExit,
    PlayerState? Function()? playerState,
  }) {
    _shutdownVideoSession = shutdown;
    _exitVideoSession = stopAndExit;
    _videoPlayerState = playerState;
  }

  /// A replaced screen must not release its successor's registration.
  /// Retirement remains owned independently until cleanup settles.
  void unregisterVideoSession(Future<void> Function() shutdown, {Future<void>? retirement}) {
    if (_shutdownVideoSession == shutdown) {
      _shutdownVideoSession = null;
      _exitVideoSession = null;
      _videoPlayerState = null;
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

  /// Register the profile's theme-music session so music or video can stop it.
  void registerThemeSession({required Future<void> Function() stopAndDispose}) {
    _stopThemeSession = stopAndDispose;
  }

  void unregisterThemeSession(Future<void> Function() stopAndDispose) {
    if (_stopThemeSession == stopAndDispose) _stopThemeSession = null;
  }

  /// Video playback is about to construct its native core: stop and dispose
  /// any live music session first. Completes once the audio core is gone.
  Future<void> claimVideo() => _enqueueClaim(() async {
    await _stopSession(_stopMusicSession, 'music');
    await _stopSession(_stopThemeSession, 'theme');
  });

  /// Release theme audio before music starts, without waiting for retiring
  /// video cores: music and video use independent native sessions.
  Future<void> claimMusic() => _enqueueClaim(() => _stopSession(_stopThemeSession, 'theme'));

  /// Theme playback is about to construct its audio core, so release any
  /// active music session first.
  Future<void> claimTheme() => _enqueueClaim(() => _stopSession(_stopMusicSession, 'music'));

  Future<void> _enqueueClaim(Future<void> Function() claim) {
    _claimTail = _claimTail.then((_) => claim(), onError: (_, _) => claim());
    return _claimTail;
  }

  Future<void> _stopSession(Future<void> Function()? stop, String sessionName) async {
    if (stop == null) return;
    try {
      await stop();
    } catch (e, st) {
      appLogger.w('PlaybackCoordinator: $sessionName session teardown failed', error: e, stackTrace: st);
    }
  }
}
