part of '../../video_player_screen.dart';

extension _VideoPlayerMediaControlsMethods on VideoPlayerScreenState {
  Future<void> _syncMediaControlsAvailability() async {
    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (!mounted || manager == null || currentPlayer == null) return;

    final playbackState = context.read<PlaybackStateProvider>();
    final canNavigateEpisodes = _currentMetadata.isEpisode || playbackState.isPlaylistActive;
    final canSeek = !widget.isLive && currentPlayer.state.seekable;

    if (!mounted || currentPlayer != player || manager != _mediaControlsManager) return;

    await manager.setControlsEnabled(
      canGoNext: canNavigateEpisodes,
      canGoPrevious: canNavigateEpisodes,
      canSeek: canSeek,
    );
  }

  Future<void> _seekBackForRewind(Player p) async {
    if (_rewindOnResume <= 0) return;
    final target = p.state.position - Duration(seconds: _rewindOnResume);
    await p.seek(clampSeekPosition(p, target));
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

    if (_wasPlayingBeforeInactive) {
      try {
        await _seekBackForRewind(currentPlayer);
        await currentPlayer.play();
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
    if (player == null) return;

    _mediaControlsManager?.updatePlaybackState(
      isPlaying: player!.state.isActive,
      position: player!.state.position,
      speed: player!.state.rate,
      force: true, // Force update since this is an explicit state change
    );
  }
}
