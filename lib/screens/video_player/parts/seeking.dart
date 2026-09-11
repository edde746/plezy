part of '../../video_player_screen.dart';

extension _VideoPlayerSeekingMethods on VideoPlayerScreenState {
  Future<void> _seekPlayback(Duration position) async {
    final currentPlayer = player;
    if (!mounted || _shuttingDown || currentPlayer == null) return;
    final target = clampSeekPosition(currentPlayer, position);
    // Declare intentional seeks before the delegate can unbind/reload at EOF.
    _activeWatchTogetherSession()?.onLocalSeek(target);
    await _performSeekPlayback(target);
  }

  Future<void> _performSeekPlayback(Duration position, {bool Function()? isCurrent}) async {
    final currentPlayer = player;
    if (!mounted || _shuttingDown || currentPlayer == null) return;
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

  /// One skip step, as the viewer configured it.
  ///
  /// Every OS skip command carries the interval the platform advertised —
  /// Android's MediaSession hardcodes 15 s — and it is deliberately ignored:
  /// a lock-screen skip, a companion-remote skip and an in-app skip all move
  /// the playhead by the same amount.
  Duration get _configuredSkipStep => Duration(seconds: SettingsService.instance.read(SettingsService.seekTimeSmall));

  /// Skip one configured step in [forward]'s direction.
  void _skipByConfiguredStep({required bool forward}) {
    final step = _configuredSkipStep;
    _seekRelative(forward ? step : -step);
  }

  /// Relative seek shared by the companion remote, the OS media-control skip
  /// commands and the screen's own transport keys, including the live-TV
  /// capture-buffer branch.
  ///
  /// Off live TV the step is accumulated rather than dispatched: all three
  /// sources arrive in bursts faster than a native seek completes, and
  /// [_performSeekPlayback] serialises on the in-flight one — so a seek per
  /// event would have every queued event rebase off the same stale position.
  void _seekRelative(Duration delta) {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    // Live TV keeps its own epoch accumulator: an absolute target is
    // meaningless against a moving live edge (#1253).
    if (widget.isLive && _live.captureBuffer != null) {
      _liveSeek.seekBy(delta.inSeconds);
      return;
    }
    _relativeSkip.seekBy(delta);
  }
}
