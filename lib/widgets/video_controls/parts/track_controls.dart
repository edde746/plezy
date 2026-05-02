part of '../video_controls.dart';

extension _PlexVideoControlsTrackMethods on _PlexVideoControlsState {
  void _toggleSubtitles() {
    final currentTrack = widget.player.state.track.subtitle;
    // No-op if no subtitle track is selected
    if (currentTrack == null || currentTrack.id == 'no') return;

    final newVisible = !_subtitlesVisible;
    widget.player.setProperty('sub-visibility', newVisible ? 'yes' : 'no');
    _setControlsState(() {
      _subtitlesVisible = newVisible;
    });
  }

  void _onSubtitleTrackChanged(SubtitleTrack track) {
    // Reset visibility when user explicitly picks a new subtitle track
    if (track.id != 'no' && !_subtitlesVisible) {
      widget.player.setProperty('sub-visibility', 'yes');
      _setControlsState(() {
        _subtitlesVisible = true;
      });
    }
    widget.onSubtitleTrackChanged?.call(track);
  }

  void _toggleShader() {
    final shaderService = widget.shaderService;
    if (shaderService == null || !shaderService.isSupported) return;

    if (shaderService.currentPreset.isEnabled) {
      // Currently active - disable temporarily
      unawaited(
        shaderService
            .applyPreset(ShaderPreset.none)
            .then((_) {
              // ignore: no-empty-block - setState triggers rebuild to reflect disabled shader
              if (mounted) _setControlsState(() {});
              widget.onShaderChanged?.call();
            })
            .catchError((Object e, StackTrace st) {
              appLogger.w('Failed to disable shader', error: e, stackTrace: st);
            }),
      );
    } else {
      // Currently off - restore saved preset
      final shaderProvider = context.read<ShaderProvider>();
      final saved = shaderProvider.savedPreset;
      final allPresets = shaderProvider.allPresets;
      final targetPreset = saved.isEnabled
          ? saved
          : allPresets.firstWhere((p) => p.isEnabled, orElse: () => allPresets[1]);
      unawaited(
        shaderService
            .applyPreset(targetPreset)
            .then((_) {
              shaderProvider.setCurrentPreset(targetPreset);
              // ignore: no-empty-block - setState triggers rebuild to reflect restored shader
              if (mounted) _setControlsState(() {});
              widget.onShaderChanged?.call();
            })
            .catchError((Object e, StackTrace st) {
              appLogger.w('Failed to apply shader preset', error: e, stackTrace: st);
            }),
      );
    }
  }

  void _nextAudioTrack() {
    if (!widget.canControl) return;
    widget.onCycleAudioTrack?.call();
  }

  void _nextSubtitleTrack() {
    if (!widget.canControl) return;
    widget.onCycleSubtitleTrack?.call();
  }

  void _nextChapter() => _seekToNextChapter();

  void _previousChapter() => _seekToPreviousChapter();

  TrackControlsState _buildTrackControlsState({
    required PlaybackStateProvider playbackState,
    required VoidCallback? onToggleAlwaysOnTop,
  }) {
    final versionQuality = effectiveVersionQualityControls(
      isOfflinePlayback: widget.isOfflinePlayback,
      availableVersions: widget.availableVersions,
      serverSupportsTranscoding: widget.serverSupportsTranscoding,
      isTranscoding: widget.isTranscoding,
      sourceAudioTracks: widget.sourceAudioTracks,
      selectedAudioStreamId: widget.selectedAudioStreamId,
    );
    return TrackControlsState(
      availableVersions: versionQuality.availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      selectedQualityPreset: widget.selectedQualityPreset,
      serverSupportsTranscoding: versionQuality.serverSupportsTranscoding,
      isTranscoding: versionQuality.isTranscoding,
      sourceAudioTracks: versionQuality.sourceAudioTracks,
      selectedAudioStreamId: versionQuality.selectedAudioStreamId,
      sourceDurationMs: widget.metadata.durationMs,
      boxFitMode: widget.boxFitMode,
      audioSyncOffset: _audioSyncOffset,
      subtitleSyncOffset: _subtitleSyncOffset,
      isRotationLocked: _isRotationLocked,
      isScreenLocked: _isScreenLocked,
      isFullscreen: _isFullscreen,
      isAlwaysOnTop: _isAlwaysOnTop,
      onTogglePIPMode: (_isPipSupported && !PlatformDetector.isTV()) ? widget.onTogglePIPMode : null,
      onCycleBoxFitMode: widget.onCycleBoxFitMode,
      onToggleRotationLock: _toggleRotationLock,
      onToggleScreenLock: _toggleScreenLock,
      onToggleFullscreen: _toggleFullscreen,
      onToggleAlwaysOnTop: onToggleAlwaysOnTop,
      onSwitchVersion: versionQuality.canSwitch ? (i) => _switchVersionAndQuality(newMediaIndex: i) : null,
      onSwitchQualityPreset: versionQuality.canSwitch ? (p) => _switchVersionAndQuality(newPreset: p) : null,
      onSwitchAudioStreamId: versionQuality.canSwitch ? (id) => _switchVersionAndQuality(newAudioStreamId: id) : null,
      onAudioTrackChanged: widget.onAudioTrackChanged,
      onSubtitleTrackChanged: _onSubtitleTrackChanged,
      onSecondarySubtitleTrackChanged: widget.onSecondarySubtitleTrackChanged,
      onLoadSeekTimes: null,
      onCancelAutoHide: () => _hideTimer?.cancel(),
      onStartAutoHide: _startHideTimer,
      // Sync offsets are now driven by listenable rebuilds — the sheet writes
      // to SettingsService and the parent re-reads via `_audioSyncOffset` /
      // `_subtitleSyncOffset` getters. Callback kept for sheet API compat.
      onSyncOffsetChanged: null,
      serverId: widget.metadata.serverId ?? '',
      shaderService: widget.shaderService,
      onShaderChanged: widget.onShaderChanged,
      isAmbientLightingEnabled: widget.isAmbientLightingEnabled,
      onToggleAmbientLighting: widget.player.playerType != 'exoplayer' ? widget.onToggleAmbientLighting : null,
      canControl: widget.canControl,
      isLive: widget.isLive,
      subtitlesVisible: _subtitlesVisible,
      showQueueButton: playbackState.isQueueActive,
      onQueueItemSelected: playbackState.isQueueActive ? _onQueueItemSelected : null,
      ratingKey: widget.metadata.id,
      mediaTitle: widget.metadata.title,
      onSubtitleDownloaded: _onSubtitleDownloaded,
      // Plex proxies OpenSubtitles via its server-side plugin; Jellyfin
      // doesn't expose an equivalent so the Search Subtitles tile is hidden
      // for Jellyfin items. The check uses the registered client type for
      // this metadata's serverId.
      subtitleSearchSupported: _isPlexBackedMetadata(),
    );
  }

  /// True when the active server supports external subtitle search (Plex
  /// today). Requires a server id because the download callback needs the
  /// Plex client/token for that server.
  bool _isPlexBackedMetadata() {
    try {
      final serverId = widget.metadata.serverId;
      if (serverId == null) return false;
      final manager = context.read<MultiServerProvider>().serverManager;
      final c = manager.getClient(serverId);
      return c?.capabilities.externalSubtitleSearch ?? false;
    } catch (_) {
      return false;
    }
  }

  Widget _buildTrackChapterControlsWidget({bool hideChaptersAndQueue = false}) {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: _toggleAlwaysOnTop,
    );

    return TrackChapterControls(
      player: widget.player,
      chapters: _chapters,
      chaptersLoaded: _chaptersLoaded,
      trackControlsState: trackControlsState,
      onSeekCompleted: widget.onSeekCompleted,
      hideChaptersAndQueue: hideChaptersAndQueue,
    );
  }
}
