part of '../../video_player_screen.dart';

extension _VideoPlayerSeekingMethods on VideoPlayerScreenState {
  Future<void> _seekPlayback(Duration position) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final target = clampSeekPosition(currentPlayer, position);
    // Declare intentional seeks before the delegate can unbind/reload at EOF.
    _activeWatchTogetherSession()?.onLocalSeek(target);
    await _performSeekPlayback(target);
  }

  Future<void> _performSeekPlayback(Duration position, {bool Function()? isCurrent}) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final generation = _transitionGate.generation;

    final target = clampSeekPosition(currentPlayer, position);
    // Parked on a dead stream (#1520): a native seek would land inside the
    // drained cache — rebuild the stream at the target instead.
    if (_eofRecovery.parked && !widget.isLive && _transitionGate.transition == PlaybackTransition.idle) {
      await _eofRecovery.retry(reason: 'seek', resumePosition: target);
      return;
    }
    // Finish an already-dispatched seek before issuing a newer target; an old
    // native completion must not land after the user's superseding seek.
    while (_nativeSeekDrain != null) {
      await _nativeSeekDrain!.future;
    }
    if (!_isCurrentPlaybackGeneration(generation, currentPlayer) || !(isCurrent?.call() ?? true)) return;
    _nativeSeekDrain = Completer<void>();
    try {
      await currentPlayer.seek(target);
    } finally {
      _nativeSeekDrain!.complete();
      _nativeSeekDrain = null;
    }
  }

  /// Relative seek shared by the companion remote and the OS media-control
  /// skip commands, including the live-TV capture-buffer branch.
  Future<void> _seekRelative(Duration delta) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    if (widget.isLive && _live.captureBuffer != null) {
      _liveSeek.seekBy(delta.inSeconds);
      return;
    }
    await _seekPlayback(currentPlayer.state.position + delta);
  }
}
