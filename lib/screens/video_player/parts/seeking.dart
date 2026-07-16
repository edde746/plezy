part of '../../video_player_screen.dart';

extension _VideoPlayerSeekingMethods on VideoPlayerScreenState {
  Future<void> _seekPlayback(Duration position) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;

    final target = clampSeekPosition(currentPlayer, position);
    // Parked on a dead stream (#1520): a native seek would land inside the
    // drained cache — rebuild the stream at the target instead.
    if (_spuriousEofRecoveryParked && !widget.isLive && _playbackTransition == _PlaybackTransition.idle) {
      await _retrySpuriousEofRecovery(reason: 'seek', resumePosition: target);
      return;
    }
    await currentPlayer.seek(target);
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
