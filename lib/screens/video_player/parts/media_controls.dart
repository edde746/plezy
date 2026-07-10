part of '../../video_player_screen.dart';

extension _VideoPlayerMediaControlsMethods on VideoPlayerScreenState {
  bool get _shouldSuspendMediaControlsForTvBackground =>
      Platform.isAndroid && PlatformDetector.isTV() && !_shouldSkipForPip;

  Future<void> _suspendMediaControlsForTvBackground(String reason) async {
    if (!_shouldSuspendMediaControlsForTvBackground) return;

    _mediaControlsManager?.suspendUpdates();
    if (!_mediaControlsSuspendedForTvBackground) {
      _mediaControlsSuspendedForTvBackground = true;
      _recordLifecycleState('media_controls', action: 'suspended:$reason');
    }

    await _mediaControlsManager?.clear();
  }

  void _resumeMediaControlsAfterTvBackground(String reason) {
    if (!_mediaControlsSuspendedForTvBackground) return;

    _mediaControlsSuspendedForTvBackground = false;
    _mediaControlsManager?.resumeUpdates();
    _recordLifecycleState('media_controls', action: 'resumed:$reason');
  }

  Future<void> _syncMediaControlsAvailability() async {
    if (_mediaControlsSuspendedForTvBackground) return;

    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (!mounted || manager == null || currentPlayer == null) return;

    final playbackState = context.read<PlaybackStateProvider>();
    final canNavigateEpisodes = _currentMetadata.isEpisode || playbackState.isPlaylistActive;
    final canSeek = !widget.isLive && (currentPlayer.state.seekable || _usesPlexVodTranscodeSeekPolicy);

    if (!mounted || currentPlayer != player || manager != _mediaControlsManager) return;

    await manager.setControlsEnabled(
      canGoNext: canNavigateEpisodes,
      canGoPrevious: canNavigateEpisodes,
      canSeek: canSeek,
      canStop: true,
      // In-track skips work on live TV too through the capture buffer.
      canSkip: true,
      // Rate changes don't apply to a live stream.
      canSetSpeed: !widget.isLive,
    );
  }

  Future<void> _seekBackForRewind(Player p) async {
    if (_rewindOnResume <= 0) return;
    final target = p.state.position - Duration(seconds: _rewindOnResume);
    await _seekPlayback(clampSeekPosition(p, target));
  }

  Future<void> _restoreMediaControlsAfterResume() async {
    if (!_isPlayerInitialized || !mounted) return;

    unawaited(_setWakelock(player?.state.isActive ?? false));

    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (manager != null && currentPlayer != null) {
      final client = _isOfflinePlayback ? null : _getMediaServerClient(context);
      await manager.updateMetadata(
        metadata: _currentMetadata,
        client: client,
        duration: _currentMetadata.durationMs != null ? Duration(milliseconds: _currentMetadata.durationMs!) : null,
      );
      await _syncMediaControlsAvailability();
    }

    if (!mounted || currentPlayer != player || currentPlayer == null) return;

    final wasPlayingBeforeInactive = _wasPlayingBeforeInactive;
    if (wasPlayingBeforeInactive) {
      try {
        await _seekBackForRewind(currentPlayer);
        await _playWithPlaybackIntent(currentPlayer);
        appLogger.d('Video resumed after returning from inactive state');
      } catch (e) {
        appLogger.w('Failed to resume playback after returning from inactive state', error: e);
      } finally {
        _wasPlayingBeforeInactive = false;
      }
    }

    _updateMediaControlsPlaybackState();
    appLogger.d('Media controls restored on app resume');
  }

  /// Wrapper method to update media controls playback state
  void _updateMediaControlsPlaybackState() {
    if (_mediaControlsSuspendedForTvBackground) return;
    if (player == null) return;

    _mediaControlsManager?.updatePlaybackState(
      isPlaying: player!.state.isActive,
      position: player!.state.position,
      speed: player!.state.rate,
      force: true, // Force update since this is an explicit state change
    );
  }
}
