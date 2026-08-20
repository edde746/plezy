part of '../../video_player_screen.dart';

/// Subtitle/audio cycling for companion-remote and keyboard shortcuts.
/// Stays on the State: the drain loop coalesces queued presses into
/// [_switchPlaybackSource] reopens and is bound to the transition lease.
extension _VideoPlayerCompanionRemoteMethods on VideoPlayerScreenState {
  void _cycleSubtitleTrack() {
    final sourceTracks = _sourceSubtitleTracksForControls();
    if (!_isOfflinePlayback && sourceTracks.isNotEmpty) {
      _pendingSubtitleCycleCount++;
      if (!_subtitleCycleDrainActive) unawaited(_drainSubtitleCycles());
      return;
    }
    _cycleSubtitleTrackNatively();
  }

  /// Cycle through the native track list, for playback with no source
  /// catalog to advance through (downloads, and items whose server exposes no
  /// subtitle rows).
  ///
  /// The manager owns the selection and the server write-back; the committed
  /// choice is this screen's, and the episode carry-over reads it, so a cycle
  /// that lands on Off has to be recorded here or the next episode inherits
  /// the choice this one started with.
  void _cycleSubtitleTrackNatively() {
    final cycled = _trackManager?.cycleSubtitleTrack();
    if (cycled != null) _rememberNativeSubtitleSelection(cycled);
  }

  Future<void> _drainSubtitleCycles() async {
    if (_subtitleCycleDrainActive) return;
    _subtitleCycleDrainActive = true;
    try {
      while (mounted && _pendingSubtitleCycleCount > 0) {
        await _waitForPlaybackTransitionIdle();
        if (!mounted || _pendingSubtitleCycleCount == 0) break;

        // Collapse every press queued before this dispatch into one target.
        // Presses arriving during the reopen remain queued for the next pass.
        final advances = _pendingSubtitleCycleCount;
        final sourceTracks = _sourceSubtitleTracksForControls();
        if (_isOfflinePlayback || sourceTracks.isEmpty) {
          _pendingSubtitleCycleCount -= advances;
          for (var i = 0; i < advances; i++) {
            _cycleSubtitleTrackNatively();
          }
          continue;
        }
        final currentChoice =
            _selectedSourceSubtitleChoiceForControls(sourceTracks) ?? const PlaybackSourceSubtitleChoice.off();
        final targetChoice = PlaybackSubtitleResolver.advanceSourceChoice(sourceTracks, currentChoice, advances);
        final outcome = await _switchPlaybackSource(newSubtitleChoice: targetChoice);
        if (outcome == PlaybackSourceChangeOutcome.busy) {
          await _waitForPlaybackTransitionIdle();
          continue;
        }
        _pendingSubtitleCycleCount -= advances;
      }
    } finally {
      _subtitleCycleDrainActive = false;
    }
  }

  void _cycleAudioTrack() => _trackManager?.cycleAudioTrack();
}
