part of '../../video_player_screen.dart';

extension _VideoPlayerBuildMethods on VideoPlayerScreenState {
  static const double _videoLayoutSizeTolerance = 0.1;
  static const double _pinchZoomActivationThreshold = 0.06;
  static const int _pinchZoomActivationUpdateThreshold = 3;

  bool _isSameVideoLayoutSize(Size a, Size b) {
    return (a.width - b.width).abs() <= _videoLayoutSizeTolerance &&
        (a.height - b.height).abs() <= _videoLayoutSizeTolerance;
  }

  void _scheduleVideoLayoutUpdate(Size newSize) {
    final currentPlayer = player;
    if (currentPlayer == null) return;

    final lastSize = _lastVideoLayoutSize;
    if (_lastVideoLayoutPlayer == currentPlayer && lastSize != null && _isSameVideoLayoutSize(lastSize, newSize)) {
      return;
    }

    _pendingVideoLayoutSize = newSize;
    if (_videoLayoutUpdateScheduled) return;
    _videoLayoutUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoLayoutUpdateScheduled = false;
      if (!mounted) return;

      final pendingSize = _pendingVideoLayoutSize;
      final currentPlayer = player;
      _pendingVideoLayoutSize = null;
      if (pendingSize == null || currentPlayer == null) return;

      final lastSize = _lastVideoLayoutSize;
      if (_lastVideoLayoutPlayer == currentPlayer &&
          lastSize != null &&
          _isSameVideoLayoutSize(lastSize, pendingSize)) {
        return;
      }

      _lastVideoLayoutSize = pendingSize;
      _lastVideoLayoutPlayer = currentPlayer;
      _videoFilterManager?.updatePlayerSize(pendingSize);
      _videoPIPManager?.updatePlayerSize(pendingSize);
      _updateAmbientLightingOnResize(pendingSize);
      unawaited(currentPlayer.updateFrame());
    });
  }

  PlaybackSourceSubtitleChoice? _selectedSourceSubtitleChoiceForControls(List<MediaSubtitleTrack> tracks) {
    if (tracks.isEmpty) return null;
    final selection = _playbackSession?.subtitleSelection;
    if (selection != null) {
      if (selection.isOff) return const PlaybackSourceSubtitleChoice.off();
      final sourceId = selection.primarySourceStreamId;
      if (sourceId != null && tracks.any((track) => track.id == sourceId)) {
        return PlaybackSourceSubtitleChoice.source(sourceId);
      }
    }
    for (final track in tracks) {
      if (track.selected) return PlaybackSourceSubtitleChoice.source(track.id);
    }
    return const PlaybackSourceSubtitleChoice.off();
  }

  List<PlaybackSubtitleSidecar> _sourceSubtitleSidecarsForControls() =>
      _playbackSession?.context.result.subtitleSidecars ?? const <PlaybackSubtitleSidecar>[];

  List<MediaSubtitleTrack> _sourceSubtitleTracksForControls() {
    final sidecarSourceIds = {for (final sidecar in _sourceSubtitleSidecarsForControls()) ?sidecar.sourceStreamId};
    return selectableSourceSubtitleTracks(
      _currentMediaInfo?.subtitleTracks ?? const <MediaSubtitleTrack>[],
      isTranscoding: _isTranscoding,
      sidecarSourceIds: sidecarSourceIds,
      supportsEmbeddedTranscodeSelection: _currentMetadata.backend == MediaBackend.plex,
    );
  }

  Widget _buildLoadingSpinner() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildPlayerInitializationSurface() {
    final bootstrapPlayer = _bootstrapPlayer;
    if (bootstrapPlayer == null) return _buildLoadingSpinner();

    // Linux creates the texture before its EGL/mpv render bootstrap can be
    // proven. Mount the provisional surface so Flutter drives one texture
    // copy, while retaining the black loading cover until playback itself
    // reports its first frame.
    return Stack(
      fit: StackFit.expand,
      children: [
        Video(player: bootstrapPlayer, hasFirstFrame: _hasFirstFrame),
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _buildInitializationError(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: .min,
              children: [
                const AppIcon(Symbols.error_rounded, color: Colors.white70, size: 44, fill: 1),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    FocusableButton(
                      autofocus: true,
                      onPressed: _retryPlayerInitialization,
                      child: FilledButton(onPressed: _retryPlayerInitialization, child: Text(t.common.retry)),
                    ),
                    const SizedBox(width: 12),
                    FocusableButton(
                      onPressed: () => unawaited(_handleBackButton()),
                      child: OutlinedButton(
                        onPressed: () => unawaited(_handleBackButton()),
                        child: Text(t.common.back),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMobileZoomGesture() {
    final filterManager = _videoFilterManager;
    if (filterManager == null || _isPinchZooming) return;

    _isPinchZooming = true;
    _pinchZoomActivationUpdateCount = 0;
    _pinchZoomChanged = false;
    _pinchStartZoomScale = filterManager.zoomScale;
  }

  void _clearMobileZoomGesture() {
    _isPinchZooming = false;
    _pinchZoomActivationUpdateCount = 0;
    _pinchZoomChanged = false;
    _pinchStartZoomScale = null;
  }

  Widget _buildVideoPlayer(BuildContext context) {
    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);
    final hideChromeOnMouseExit = !(isMobile && !PlatformDetector.isTV());

    // Back handling (sheet-close + player exit) is owned by the OverlaySheetHost
    // that wraps this widget — see video_player_screen.dart (canPop/onSystemBack).
    return Scaffold(
      // Use transparent background on macOS when native video layer is active
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent, // Allow taps to pass through to controls
        onScaleStart: (details) {
          if (!isMobile) return;
          if (details.pointerCount >= 2) _startMobileZoomGesture();
        },
        onScaleUpdate: (details) {
          if (!isMobile) return;
          if (details.pointerCount < 2) return;
          if (!_isPinchZooming) _startMobileZoomGesture();

          final startZoom = _pinchStartZoomScale;
          final filterManager = _videoFilterManager;
          if (!_isPinchZooming || startZoom == null || filterManager == null) return;
          final nextZoomScale = VideoFilterManager.normalizeZoomScale(startZoom * details.scale);

          if (!_pinchZoomChanged) {
            if ((details.scale - 1.0).abs() <= _pinchZoomActivationThreshold) {
              _pinchZoomActivationUpdateCount = 0;
              return;
            }

            _pinchZoomActivationUpdateCount++;
            if (_pinchZoomActivationUpdateCount < _pinchZoomActivationUpdateThreshold) return;
            if (nextZoomScale == filterManager.zoomScale) return;

            _pinchZoomChanged = true;
            _ambientLightingService?.disable();
          }

          filterManager.setZoomScale(nextZoomScale);
        },
        onScaleEnd: (details) {
          if (!isMobile) return;
          if (!_isPinchZooming) return;
          if (!_pinchZoomChanged) {
            _clearMobileZoomGesture();
            return;
          }

          final zoomScale = _videoFilterManager?.zoomScale ?? 1.0;
          _showZoomToast(zoomScale);
          _clearMobileZoomGesture();
          _setPlayerState(() {});
        },
        child: PlayerChromeInteractionRegion(
          controller: _chromeController,
          hideOnExit: hideChromeOnMouseExit,
          child: Stack(
            children: [
              // macOS PiP placeholder — video is in PiP window, show background with icon
              // Placed before Video so controls render on top
              if (Platform.isMacOS) const VideoPlayerMacPipPlaceholder(),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final newSize = Size(constraints.maxWidth, constraints.maxHeight);
                    _scheduleVideoLayoutUpdate(newSize);

                    var authority = (canControlPlayback: true, canNavigateMediaItems: true);
                    try {
                      authority = context
                          .select<WatchTogetherProvider, ({bool canControlPlayback, bool canNavigateMediaItems})>(
                            (wt) => (
                              canControlPlayback: !wt.isInSession || wt.canControl(),
                              canNavigateMediaItems: !wt.isInSession || wt.isHost,
                            ),
                          );
                    } catch (_) {
                      // Watch Together is optional outside the main app shell.
                    }
                    if (_lastMediaControlAuthority != authority) {
                      _lastMediaControlAuthority = authority;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) unawaited(_syncMediaControlsAvailability());
                      });
                    }

                    VoidCallback? onNext;
                    if (widget.isLive) {
                      onNext = _hasNextChannel ? () => _switchLiveChannel(1) : null;
                    } else {
                      onNext = (_nextEpisode != null && authority.canNavigateMediaItems) ? _playNext : null;
                    }

                    VoidCallback? onPrevious;
                    if (widget.isLive) {
                      onPrevious = _hasPreviousChannel ? () => _switchLiveChannel(-1) : null;
                    } else {
                      final canRestartOrPrevious = _currentMetadata.isEpisode || _previousEpisode != null;
                      onPrevious = (canRestartOrPrevious && authority.canNavigateMediaItems)
                          ? _restartOrPlayPrevious
                          : null;
                    }

                    final sourceAudioTracks = _currentMediaInfo?.audioTracks ?? const <MediaAudioTrack>[];
                    final sourceSubtitleSidecars = _sourceSubtitleSidecarsForControls();
                    final sourceSubtitleTracks = _sourceSubtitleTracksForControls();

                    return Video(
                      player: player!,
                      hasFirstFrame: _hasFirstFrame,
                      controls: (context) => PlexVideoControls(
                        player: player!,
                        volumeController: _volumeController!,
                        metadata: _currentMetadata,
                        onNext: onNext,
                        onPrevious: onPrevious,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: _effectiveSelectedMediaIndex,
                        selectedQualityPreset: _selectedQualityPreset,
                        serverSupportsTranscoding: _serverSupportsTranscoding,
                        isTranscoding: _isTranscoding,
                        isOfflinePlayback: _isOfflinePlayback,
                        sourceAudioTracks: sourceAudioTracks,
                        selectedAudioStreamId: _selectedAudioStreamId,
                        sourceSubtitleTracks: sourceSubtitleTracks,
                        selectedSubtitleChoice: _selectedSourceSubtitleChoiceForControls(sourceSubtitleTracks),
                        selectedSecondarySubtitleStreamId: _playbackSession?.subtitleSelection.secondarySourceStreamId,
                        sourceSubtitleSidecars: sourceSubtitleSidecars,
                        sourcePartId: _currentMediaInfo?.partId,
                        onPlaybackSourceChanged: _switchPlaybackSource,
                        onTogglePIPMode: _togglePIPMode,
                        boxFitMode: _videoFilterManager?.boxFitMode ?? 0,
                        videoZoomScale: _videoFilterManager?.zoomScale ?? 1.0,
                        onCycleBoxFitMode: _cycleBoxFitMode,
                        onVideoZoomChanged: _setVideoZoom,
                        onZoomIn: _zoomVideoIn,
                        onZoomOut: _zoomVideoOut,
                        onResetVideoZoom: _resetVideoZoom,
                        onCycleAudioTrack: _cycleAudioTrack,
                        onCycleSubtitleTrack: _cycleSubtitleTrack,
                        onAudioTrackChanged: _onAudioTrackChanged,
                        onSubtitleTrackChanged: _onSubtitleTrackChanged,
                        onSecondarySubtitleTrackChanged: _onSecondarySubtitleTrackChanged,
                        onSeekRequested: _seekPlayback,
                        onPlayPauseRequested: () => _playOrPauseWithPlaybackIntent(player!),
                        onSeekCompleted: _notifyWatchTogetherSeek,
                        onBack: _handleBackButton,
                        onReachedEnd: ({skipAutoPlayCountdown = false}) =>
                            _onVideoCompleted(true, skipAutoPlayCountdown: skipAutoPlayCountdown),
                        canControl: authority.canControlPlayback,
                        canNavigateMediaItems: authority.canNavigateMediaItems,
                        hasFirstFrame: _hasFirstFrame,
                        playNextFocusNode: _showPlayNextDialog ? _playNextConfirmFocusNode : null,
                        chromeController: _chromeController,
                        shaderService: _shaderService,
                        // ignore: no-empty-block - state update triggers rebuild to reflect shader change
                        onShaderChanged: () => _setPlayerState(() {}),
                        thumbnailDataBuilder: _scrubPreviewSource?.isAvailable == true ? _getThumbnailData : null,
                        isLive: widget.isLive,
                        liveChannelName: _live.channelName,
                        captureBuffer: _live.captureBuffer,
                        isAtLiveEdge: _live.atLiveEdge,
                        streamStartEpoch: _live.streamStartEpoch,
                        currentPositionEpoch: widget.isLive ? _currentPositionEpoch : null,
                        onLiveSeek: _live.captureBuffer != null ? _seekLiveToEpoch : null,
                        onLiveSeekBy: _live.captureBuffer != null ? _liveSeek.seekBy : null,
                        onJumpToLive: _live.captureBuffer != null && !_live.atLiveEdge ? _jumpToLiveEdge : null,
                        isAmbientLightingEnabled: _ambientLightingService?.isEnabled ?? false,
                        onToggleAmbientLighting: _ambientLightingService?.isSupported == true
                            ? _toggleAmbientLighting
                            : null,
                        toastController: _toastController,
                      ),
                    );
                  },
                ),
              ),
              // Netflix-style auto-play overlay (hidden in PiP mode)
              VideoPlayerPlayNextOverlay(
                visible: _showPlayNextDialog,
                nextEpisode: _nextEpisode,
                autoPlayCountdown: _autoPlayCountdown,
                cancelFocusNode: _playNextCancelFocusNode,
                confirmFocusNode: _playNextConfirmFocusNode,
                chromeController: _chromeController,
                onCancel: _cancelAutoPlay,
                onPlayNext: _playNext,
              ),
              // "Still watching?" overlay (hidden in PiP mode)
              VideoPlayerStillWatchingOverlay(
                visible: _showStillWatchingPrompt,
                countdown: _stillWatchingCountdown,
                pauseFocusNode: _stillWatchingPauseFocusNode,
                continueFocusNode: _stillWatchingContinueFocusNode,
                chromeController: _chromeController,
                onPause: _onStillWatchingPause,
                onContinue: _onStillWatchingContinue,
              ),
              // Buffering indicator (also shows during initial load, but not when exiting)
              // Hidden in PiP mode
              VideoPlayerBufferingOverlay(
                isBuffering: _isBuffering,
                hasFirstFrame: _hasFirstFrame,
                isExiting: _isExiting,
              ),
              // Watch Together overlays (isolated from video surface repaints)
              const VideoPlayerWatchTogetherOverlays(),
              // Black overlay during exit (no spinner - just covers transparency)
              VideoPlayerExitOverlay(isExiting: _isExiting),
            ],
          ),
        ),
      ),
    );
  }
}
