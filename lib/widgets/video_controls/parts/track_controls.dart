part of '../video_controls.dart';

final Expando<LatestAsyncWrite<String>> _subtitleVisibilityWrites = Expando<LatestAsyncWrite<String>>();

extension _PlexVideoControlsTrackMethods on _PlexVideoControlsState {
  void _toggleSubtitles() {
    // Restoring always works: backends without a renderer-level visibility
    // switch hide subtitles by deselecting them, so the current track reads
    // as Off while hidden and a selection check would trap the toggle.
    if (!_subtitlesVisible) {
      _setSubtitleVisibility(true);
      return;
    }

    // A burned-in subtitle is pixels rather than a track: there is nothing selected to hide, and
    // `setSubtitleVisibility` could not remove painted pixels anyway. Only a new negotiation can,
    // and that is a real subtitle *choice* - it re-encodes the stream and the server remembers it.
    // Doing that behind a transient visibility shortcut would silently overwrite the viewer's saved
    // selection with Off, so the shortcut says where the control actually lives instead of
    // pretending to work or doing nothing at all.
    if (_hasBurnedSourceSubtitle()) {
      showAppSnackBar(context, t.messages.burnedSubtitlesUseMenu);
      return;
    }

    final currentTrack = widget.player.state.track.subtitle;
    if (currentTrack == null || currentTrack.id == SubtitleTrack.off.id) return;

    _setSubtitleVisibility(false);
  }

  /// Whether the server burned the selected subtitle into the picture.
  ///
  /// The same rule the player screen applies to a subtitle *change*, asked with an off target: only
  /// a burned current selection forces the server's hand, and a selection delivered as a file stays
  /// an ordinary native track the player can hide itself. Shared rather than restated so the two
  /// cannot drift.
  bool _hasBurnedSourceSubtitle() {
    final choice = widget.selectedSubtitleChoice;
    final sourceStreamId = choice != null && !choice.isOff ? choice.sourceStreamId : null;
    return PlaybackSubtitleResolver.burnRequiresRenegotiation(
      // A live source selection is always delivered by burning into the
      // rebuilt stream (`isLive` never has sidecars), so it counts as a
      // transcode for this rule even though the player screen tracks no
      // transcoding session for live playback.
      isTranscoding: widget.isTranscoding || widget.isLive,
      currentSourceStreamId: sourceStreamId,
      currentSelectionHasSidecar:
          sourceStreamId != null &&
          widget.sourceSubtitleSidecars.any((sidecar) => sidecar.sourceStreamId == sourceStreamId),
      targetIsOff: true,
      targetIsExternalFile: false,
    );
  }

  void _onSubtitleTrackChanged(SubtitleTrack track) {
    if (track.id != 'no' && !_subtitlesVisible) {
      _setSubtitleVisibility(true);
    }
    widget.onSubtitleTrackChanged?.call(track);
  }

  void _setSubtitleVisibility(bool visible) {
    final targetPlayer = widget.player;
    final coordinator = _subtitleVisibilityWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin('sub-visibility');
    final generation = ++_subtitleVisibilityWriteGeneration;
    _setControlsState(() {
      _subtitlesVisible = visible;
    });

    unawaited(() async {
      try {
        final committed = await coordinator.commitIfLatest('sub-visibility', writeToken, () async {
          await targetPlayer.setProperty('sub-visibility', visible ? 'yes' : 'no');
          if (mounted && targetPlayer == widget.player) {
            // Preserve every successfully executed mutation as the rollback
            // baseline, even when a newer optimistic toggle is queued.
            _confirmedSubtitlesVisible = visible;
          }
        });
        if (!committed ||
            !mounted ||
            generation != _subtitleVisibilityWriteGeneration ||
            targetPlayer != widget.player) {
          return;
        }
      } catch (error, stackTrace) {
        appLogger.w('Failed to update subtitle visibility', error: error, stackTrace: stackTrace);
        if (!mounted || generation != _subtitleVisibilityWriteGeneration || targetPlayer != widget.player) {
          return;
        }
        _setControlsState(() {
          _subtitlesVisible = _confirmedSubtitlesVisible;
        });
      }
    }());
  }

  void _toggleShader() {
    final shaderService = widget.shaderService;
    if (shaderService == null || !shaderService.isSupported) return;

    final shaderProvider = context.read<ShaderProvider>();
    // The restore target honors the configured persistence scope, so toggling
    // back on inside an Anime4K library restores that library's preset rather
    // than the global one.
    final savedPresetId = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, widget.metadata);
    final targetPreset = resolveShaderTogglePreset(
      currentPreset: shaderService.currentPreset,
      savedPreset: shaderProvider.findPresetById(savedPresetId) ?? ShaderPreset.none,
      allPresets: shaderProvider.allPresets,
    );

    if (targetPreset.isEnabled && widget.isAmbientLightingEnabled) {
      widget.onToggleAmbientLighting?.call();
    }

    unawaited(
      shaderService
          .applyPreset(targetPreset)
          .then((_) async {
            if (!mounted) return;
            if (targetPreset.isEnabled) {
              await ScopedPlayerPrefs.write(ScopedPlayerPrefs.shaderPreset, widget.metadata, targetPreset.id);
            }
            // Toggling off stays session-only; the write above already synced
            // the provider when the configured scope is global.
            shaderProvider.setCurrentPreset(targetPreset);
            if (!mounted) return;
            // ignore: no-empty-block - setState triggers rebuild to reflect shader changes
            _setControlsState(() {});
            widget.onShaderChanged?.call();
          })
          .catchError((Object e, StackTrace st) {
            appLogger.w('Failed to toggle shader preset', error: e, stackTrace: st);
          }),
    );
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
      sourceSubtitleTracks: widget.sourceSubtitleTracks,
      selectedSubtitleChoice: widget.selectedSubtitleChoice,
    );
    final canSwitchSourceSubtitles = versionQuality.canSwitch && versionQuality.sourceSubtitleTracks.isNotEmpty;
    return TrackControlsState(
      availableVersions: versionQuality.availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      selectedQualityPreset: widget.selectedQualityPreset,
      serverSupportsTranscoding: versionQuality.serverSupportsTranscoding,
      isTranscoding: versionQuality.isTranscoding,
      sourceAudioTracks: versionQuality.sourceAudioTracks,
      selectedAudioStreamId: versionQuality.selectedAudioStreamId,
      sourceSubtitleTracks: canSwitchSourceSubtitles
          ? versionQuality.sourceSubtitleTracks
          : const <MediaSubtitleTrack>[],
      selectedSubtitleChoice: canSwitchSourceSubtitles ? versionQuality.selectedSubtitleChoice : null,
      selectedSecondarySubtitleStreamId: canSwitchSourceSubtitles ? widget.selectedSecondarySubtitleStreamId : null,
      sourceSubtitleSidecars: canSwitchSourceSubtitles
          ? widget.sourceSubtitleSidecars
          : const <PlaybackSubtitleSidecar>[],
      sourcePartId: canSwitchSourceSubtitles ? widget.sourcePartId : null,
      sourceDurationMs: widget.metadata.durationMs,
      boxFitMode: widget.boxFitMode,
      videoZoomScale: widget.videoZoomScale,
      audioSyncOffset: _audioSyncOffset,
      subtitleSyncOffset: _subtitleSyncOffset,
      isRotationLocked: _isRotationLocked,
      isFullscreen: _isFullscreen,
      isAlwaysOnTop: _isAlwaysOnTop,
      onTogglePIPMode: (_isPipSupported && !PlatformDetector.isTV()) ? widget.onTogglePIPMode : null,
      onCycleBoxFitMode: widget.onCycleBoxFitMode,
      onVideoZoomChanged: widget.onVideoZoomChanged,
      onResetVideoZoom: widget.onResetVideoZoom,
      onToggleRotationLock: _toggleRotationLock,
      onToggleScreenLock: _toggleScreenLock,
      onToggleFullscreen: _toggleFullscreen,
      onToggleAlwaysOnTop: onToggleAlwaysOnTop,
      onSwitchVersion: versionQuality.canSwitch ? (i) => _switchVersionAndQuality(newMediaIndex: i) : null,
      onSwitchQualityPreset: versionQuality.canSwitch ? (p) => _switchVersionAndQuality(newPreset: p) : null,
      onSwitchAudioStreamId: versionQuality.canSwitch ? (id) => _switchVersionAndQuality(newAudioStreamId: id) : null,
      onSwitchSubtitle: canSwitchSourceSubtitles
          ? (choice) => _switchVersionAndQuality(newSubtitleChoice: choice)
          : null,
      onAudioTrackChanged: widget.onAudioTrackChanged,
      onSubtitleTrackChanged: _onSubtitleTrackChanged,
      onSecondarySubtitleTrackChanged: widget.onSecondarySubtitleTrackChanged,
      onCancelAutoHide: widget.chromeController.cancelAutoHide,
      onStartAutoHide: _startHideTimer,
      serverId: widget.metadata.serverId,
      metadata: widget.metadata,
      shaderService: widget.shaderService,
      onShaderChanged: widget.onShaderChanged,
      isAmbientLightingEnabled: widget.isAmbientLightingEnabled,
      onToggleAmbientLighting: widget.player.playerType != 'exoplayer' ? widget.onToggleAmbientLighting : null,
      canControl: widget.canControl,
      isLive: widget.isLive,
      subtitlesVisible: _subtitlesVisible,
      showQueueButton: playbackState.isQueueActive && widget.canNavigateMediaItems,
      onQueueItemSelected: playbackState.isQueueActive && widget.canNavigateMediaItems ? _onQueueItemSelected : null,
      ratingKey: widget.metadata.id,
      mediaTitle: widget.metadata.title,
      onSubtitleDownloaded: _onSubtitleDownloaded,
      // Search Subtitles is gated by backend capabilities (Plex, Emby).
      subtitleSearchSupported: _supportsSubtitleSearch(),
    );
  }

  /// True when the active server advertises server-side subtitle search.
  bool _supportsSubtitleSearch() {
    try {
      final serverId = widget.metadata.serverId;
      if (serverId == null) return false;
      final manager = context.read<MultiServerProvider>().serverManager;
      final c = manager.getClient(ServerId(serverId));
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
      onSeekRequested: widget.onSeekRequested,
      onSeekCompleted: widget.onSeekCompleted,
      hideChaptersAndQueue: hideChaptersAndQueue,
    );
  }
}
