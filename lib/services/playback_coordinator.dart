import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mpv/mpv.dart';
import '../utils/app_logger.dart';

enum VideoAutomationCommand { play, pause, toggle }

enum VideoPlayerSlot { primary, companion }

/// A reservation for one native video plugin instance. The slot stays held
/// until its owner has disposed the native player, including failed starts.
class VideoPlayerLease {
  VideoPlayerLease._(this.slot, this._coordinator);

  final VideoPlayerSlot slot;
  final PlaybackCoordinator _coordinator;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _coordinator._releaseVideoPlayerLease(this);
  }
}

/// The app registers one primary and one companion native video channel.
/// Refuse an additional open rather than replacing the companion's core.
class WorkspaceVideoCapacityException implements Exception {
  const WorkspaceVideoCapacityException();

  @override
  String toString() => 'The workspace already has two video sessions. Close one before opening another video.';
}

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

  /// A music pane explicitly retained in Plezy's app-owned workspace survives
  /// a newly opened video route. Outside Multiview, existing arbitration stays
  /// unchanged.
  bool _workspaceRetainsMusic = false;
  bool get workspaceRetainsMusic => _workspaceRetainsMusic;
  int _workspaceVideoSessionCount = 0;
  int get workspaceVideoSessionCount => _workspaceVideoSessionCount;
  bool get workspaceRetainsVideo => _workspaceVideoSessionCount > 0;
  Set<VideoPlayerSlot> _workspaceVideoPlayerSlots = <VideoPlayerSlot>{};
  final Set<VideoPlayerLease> _videoPlayerLeases = <VideoPlayerLease>{};
  VideoPlayerSlot? get nextVideoPlayerSlot {
    final occupied = <VideoPlayerSlot>{
      ..._workspaceVideoPlayerSlots,
      ..._videoPlayerLeases.map((lease) => lease.slot),
    };
    if (_workspaceVideoSessionCount > occupied.length && !occupied.contains(VideoPlayerSlot.primary)) {
      // Older adapters may report an occupied session before they publish a
      // slot. Conservatively treat that one as primary while upgrading.
      occupied.add(VideoPlayerSlot.primary);
    }
    if (!occupied.contains(VideoPlayerSlot.primary)) return VideoPlayerSlot.primary;
    if (!occupied.contains(VideoPlayerSlot.companion)) return VideoPlayerSlot.companion;
    return null;
  }
  bool _workspaceHasCompetingAudioOwner = false;
  bool get workspaceHasCompetingAudioOwner => _workspaceHasCompetingAudioOwner;

  void setWorkspaceRetainsMusic(bool retain) {
    _workspaceRetainsMusic = retain;
  }

  void setWorkspaceVideoSessionCount(int count) {
    _workspaceVideoSessionCount = count.clamp(0, 2).toInt();
  }

  void setWorkspaceVideoPlayerSlots(Iterable<VideoPlayerSlot> slots) {
    _workspaceVideoPlayerSlots = Set<VideoPlayerSlot>.of(slots);
  }

  void setWorkspaceHasCompetingAudioOwner(bool hasCompetingOwner) {
    _workspaceHasCompetingAudioOwner = hasCompetingOwner;
  }

  Future<void> Function()? _stopThemeSession;
  Future<void> Function()? _stopFileSession;
  bool Function()? _isFileSessionActive;
  bool get hasFileSession => _isFileSessionActive?.call() ?? false;
  Future<void> Function()? _stopNarration;
  void registerNarrationSession(Future<void> Function() stop) => _stopNarration = stop;
  void unregisterNarrationSession(Future<void> Function() stop) {
    if (_stopNarration == stop) _stopNarration = null;
  }

  void registerFileSession(Future<void> Function() stop, {bool Function()? isActive}) {
    _stopFileSession = stop;
    _isFileSessionActive = isActive;
  }

  void unregisterFileSession(Future<void> Function() stop) {
    if (_stopFileSession == stop) {
      _stopFileSession = null;
      _isFileSessionActive = null;
    }
  }

  /// File-backed audio, video and narration share the existing native channels.
  Future<void> claimFiles({bool preserveWorkspaceVideo = true, bool preserveWorkspaceMusic = false}) async {
    await _stopNarration?.call();
    await _stopTheme();
    if (!preserveWorkspaceMusic || !_workspaceRetainsMusic) await _stopMusicSession?.call();
    if (!preserveWorkspaceVideo || !_workspaceRetainsVideo) await shutdownVideo();
  }

  /// Theme songs share the music channel, so both claims stop them first.
  void registerThemeSession(Future<void> Function() stop) => _stopThemeSession = stop;

  Future<void> _stopTheme() async {
    try {
      await _stopThemeSession?.call();
    } catch (e, st) {
      appLogger.w('PlaybackCoordinator: theme song teardown failed', error: e, stackTrace: st);
    }
  }

  Future<void> Function()? _shutdownVideoSession;
  Future<bool> Function()? _exitVideoSession;
  Future<bool> Function(VideoAutomationCommand command)? _controlVideoSession;
  PlayerState? Function()? _videoPlayerState;
  final Set<Future<void>> _videoRetirements = {};

  bool get hasVideoSession => _shutdownVideoSession != null || _videoRetirements.isNotEmpty;

  /// Cached state of the registered screen's player, for diagnostics that must
  /// not cost a platform-channel round trip. Null while no screen owns video,
  /// before its player is built, and for a session that is only retiring.
  PlayerState? get videoPlayerState => _videoPlayerState?.call();
  final _videoSessionActive = ValueNotifier<bool>(false);

  /// Follows [hasVideoSession], including the retirement that outlives the
  /// video route, so screens waiting on it can resume once it settles.
  ValueListenable<bool> get videoSessionActive => _videoSessionActive;

  void _publishVideoSession() => _videoSessionActive.value = hasVideoSession;

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
    Future<bool> Function(VideoAutomationCommand command)? control,
    PlayerState? Function()? playerState,
  }) {
    _shutdownVideoSession = shutdown;
    _exitVideoSession = stopAndExit;
    _controlVideoSession = control;
    _videoPlayerState = playerState;
    _publishVideoSession();
  }

  /// A replaced screen must not release its successor's registration.
  /// Retirement remains owned independently until cleanup settles.
  void unregisterVideoSession(Future<void> Function() shutdown, {Future<void>? retirement}) {
    if (_shutdownVideoSession == shutdown) {
      _shutdownVideoSession = null;
      _exitVideoSession = null;
      _controlVideoSession = null;
      _videoPlayerState = null;
    }
    if (retirement != null && _videoRetirements.add(retirement)) {
      unawaited(
        retirement.then<void>(
          (_) {
            _videoRetirements.remove(retirement);
            _publishVideoSession();
          },
          onError: (Object error, StackTrace stackTrace) {
            _videoRetirements.remove(retirement);
            _publishVideoSession();
            appLogger.w('PlaybackCoordinator: video retirement failed', error: error, stackTrace: stackTrace);
          },
        ),
      );
    }
    _publishVideoSession();
  }

  /// Quiesce video and await its native stop, final report and pending retirements.
  /// The owner coalesces repeated calls; the application owns the deadline.
  Future<void> shutdownVideo() async {
    await Future.wait<void>([
      ..._videoRetirements,
      if (_shutdownVideoSession case final shutdown?) Future<void>.sync(shutdown),
    ]);
  }

  /// Dispatches a scoped automation transport command to the screen that owns
  /// the current video session. Returns false when no controllable player is
  /// active, such as when a cold-start control link opens the app.
  Future<bool> controlVideo(VideoAutomationCommand command) async {
    final control = _controlVideoSession;
    if (control == null) return false;
    return control(command);
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
  Future<void> claimVideo({bool stopFileSession = true}) async {
    if (_workspaceVideoSessionCount >= 2) throw const WorkspaceVideoCapacityException();
    await _claimVideoPlayback(stopFileSession: stopFileSession);
  }

  /// Reserve the native channel first, before awaiting other session teardown.
  /// Two simultaneous opens therefore cannot both select the primary core.
  Future<VideoPlayerLease> claimVideoSlot({bool stopFileSession = true}) {
    if (_workspaceVideoSessionCount >= 2) throw const WorkspaceVideoCapacityException();
    final slot = nextVideoPlayerSlot;
    if (slot == null) throw const WorkspaceVideoCapacityException();
    final lease = VideoPlayerLease._(slot, this);
    _videoPlayerLeases.add(lease);
    return _claimVideoPlayback(stopFileSession: stopFileSession).then(
      (_) => lease,
      onError: (Object error, StackTrace stackTrace) {
        lease.release();
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  /// Reinitialize an existing owner while retaining its slot lease.
  Future<void> claimVideoForLease(VideoPlayerLease lease, {bool stopFileSession = true}) {
    if (!_videoPlayerLeases.contains(lease)) throw const WorkspaceVideoCapacityException();
    return _claimVideoPlayback(stopFileSession: stopFileSession);
  }

  void _releaseVideoPlayerLease(VideoPlayerLease lease) {
    _videoPlayerLeases.remove(lease);
  }

  Future<void> _claimVideoPlayback({required bool stopFileSession}) async {
    await _stopNarration?.call();
    if (stopFileSession) await _stopFileSession?.call();
    await _stopTheme();
    final stop = _stopMusicSession;
    if (stop == null || _workspaceRetainsMusic) return;
    try {
      await stop();
    } catch (e, st) {
      // The video player must still be able to start; a wedged audio core
      // is strictly worse than a leaked stop error.
      appLogger.w('PlaybackCoordinator: music session teardown failed', error: e, stackTrace: st);
    }
  }

  /// Music playback is about to construct its audio core. Stops a detail-page
  /// theme song, which uses the same channel; video is deliberately not awaited.
  ///
  /// Bounded route exit can expose music UI while video cleanup is still
  /// retiring, but the two share nothing that has to be serialized: they are
  /// separate plugin instances on separate channels
  /// (`com.plezy/mpv_audio_player` vs `com.plezy/mpv_player`), so neither
  /// contends for `PlayerBase`'s per-channel event-channel owner; on Android
  /// each holds its own native session, handle and locks; and a retiring video
  /// core releases audio focus in the synchronous part of its dispose, before
  /// the teardown thread it leaves running.
  ///
  /// Making this await [_videoRetirements] would hand a wedged video teardown
  /// — the one case where retirement outlives the route by more than a frame —
  /// the power to stop music from starting at all, which is the bricking the
  /// per-session native rework exists to prevent.
  Future<void> claimMusic() async {
    await _stopNarration?.call();
    await _stopFileSession?.call();
    await _stopTheme();
  }
}
