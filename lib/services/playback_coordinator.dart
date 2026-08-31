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
  Future<void> Function()? _stopThemeSession;
  Future<void> _claimTail = Future<void>.value();

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

  /// Register the profile's single theme-music session. Theme playback uses
  /// the same native audio core as music, so it must release that core before
  /// music or video starts.
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

  /// Music playback is about to construct its audio core, so release any
  /// active theme session first.
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
