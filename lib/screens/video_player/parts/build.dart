part of '../../video_player_screen.dart';

extension _VideoPlayerBuildMethods on VideoPlayerScreenState {
  static const double _videoLayoutSizeTolerance = 0.1;
  static const double _pinchZoomActivationThreshold = 0.015;

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

  int? _selectedSourceSubtitleStreamId(List<MediaSubtitleTrack> tracks) {
    if (tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.selected) return track.id;
    }
    return 0;
  }

  List<MediaSubtitleTrack> _sourceSubtitleTracksForControls() {
    final tracks = _currentMediaInfo?.subtitleTracks ?? const <MediaSubtitleTrack>[];
    if (!_isTranscoding) return tracks;
    return tracks
        .where((track) {
          final hasKey = track.key != null && track.key!.isNotEmpty;
          return hasKey || CodecUtils.isTextSubtitleCodec(track.codec);
        })
        .toList(growable: false);
  }

  Widget _buildLoadingSpinner() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
                      onPressed: () {
                        final playerToDispose = player;
                        player = null;
                        if (playerToDispose != null) unawaited(playerToDispose.dispose());
                        _setPlayerState(() {
                          _playerInitializationError = null;
                          _isPlayerInitialized = false;
                        });
                        unawaited(_initializePlayer());
                      },
                      child: FilledButton(
                        onPressed: () {
                          final playerToDispose = player;
                          player = null;
                          if (playerToDispose != null) unawaited(playerToDispose.dispose());
                          _setPlayerState(() {
                            _playerInitializationError = null;
                            _isPlayerInitialized = false;
                          });
                          unawaited(_initializePlayer());
                        },
                        child: Text(t.common.retry),
                      ),
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

    _ambientLightingService?.disable();
    _isPinchZooming = true;
    _pinchZoomChanged = false;
    _pinchStartZoomScale = filterManager.zoomScale;
  }

  void _clearMobileZoomGesture() {
    _isPinchZooming = false;
    _pinchZoomChanged = false;
    _pinchStartZoomScale = null;
  }

  Widget _buildVideoPlayer(BuildContext context) {
    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);
    final hideChromeOnMouseExit = !(isMobile && !PlatformDetector.isTV());

    return PopScope(
      canPop: false, // Disable swipe-back gesture to prevent interference with timeline scrubbing
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // If an overlay sheet is open, delegate back to it instead of
          // exiting the player. This prevents the double-pop on Android TV
          // where the system back gesture would otherwise reach both the
          // sheet and the player's PopScope.
          final sheetController = OverlaySheetController.maybeOf(context);
          if (sheetController != null && sheetController.isOpen) {
            sheetController.pop();
            return;
          }
          if (BackKeyCoordinator.consumeIfHandled()) return;
          BackKeyCoordinator.markHandled();
          _handleBackButton();
        }
      },
      child: Scaffold(
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
            if ((details.scale - 1.0).abs() <= _pinchZoomActivationThreshold && !_pinchZoomChanged) return;

            _pinchZoomChanged = true;
            filterManager.setZoomScale(startZoom * details.scale);
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

                      // Compute canControl from Watch Together provider (reactive)
                      bool canControl = true;
                      try {
                        canControl = context.select<WatchTogetherProvider, bool>(
                          (wt) => wt.isInSession ? wt.canControl() : true,
                        );
                      } catch (e) {
                        // Watch Together not available, default to can control
                      }

                      VoidCallback? onNext;
                      if (widget.isLive) {
                        onNext = _hasNextChannel ? () => _switchLiveChannel(1) : null;
                      } else {
                        onNext = (_nextEpisode != null && _canNavigateEpisodes()) ? _playNext : null;
                      }

                      VoidCallback? onPrevious;
                      if (widget.isLive) {
                        onPrevious = _hasPreviousChannel ? () => _switchLiveChannel(-1) : null;
                      } else {
                        final canRestartOrPrevious = _currentMetadata.isEpisode || _previousEpisode != null;
                        onPrevious = (canRestartOrPrevious && _canNavigateEpisodes()) ? _restartOrPlayPrevious : null;
                      }

                      final sourceAudioTracks = _currentMediaInfo?.audioTracks ?? const <MediaAudioTrack>[];
                      final sourceSubtitleTracks = _sourceSubtitleTracksForControls();

                      return Video(
                        player: player!,
                        controls: (context) => PlexVideoControls(
                          player: player!,
                          metadata: _currentMetadata,
                          onNext: onNext,
                          onPrevious: onPrevious,
                          availableVersions: _availableVersions,
                          selectedMediaIndex: _effectiveSelectedMediaIndex,
                          selectedMediaSourceId: widget.selectedMediaSourceId,
                          selectedQualityPreset: _selectedQualityPreset,
                          serverSupportsTranscoding: _serverSupportsTranscoding,
                          isTranscoding: _isTranscoding,
                          isOfflinePlayback: _isOfflinePlayback,
                          sourceAudioTracks: sourceAudioTracks,
                          selectedAudioStreamId: _selectedAudioStreamId,
                          sourceSubtitleTracks: sourceSubtitleTracks,
                          selectedSubtitleStreamId: _selectedSourceSubtitleStreamId(sourceSubtitleTracks),
                          sourcePartId: _currentMediaInfo?.partId,
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
                          onSeekCompleted: _notifyWatchTogetherSeek,
                          onBack: _handleBackButton,
                          onReachedEnd: ({skipAutoPlayCountdown = false}) =>
                              _onVideoCompleted(true, skipAutoPlayCountdown: skipAutoPlayCountdown),
                          canControl: canControl,
                          hasFirstFrame: _hasFirstFrame,
                          playNextFocusNode: _showPlayNextDialog ? _playNextConfirmFocusNode : null,
                          chromeController: _chromeController,
                          shaderService: _shaderService,
                          // ignore: no-empty-block - state update triggers rebuild to reflect shader change
                          onShaderChanged: () => _setPlayerState(() {}),
                          thumbnailDataBuilder: _scrubPreviewSource?.isAvailable == true ? _getThumbnailData : null,
                          isLive: widget.isLive,
                          liveChannelName: _liveChannelName,
                          captureBuffer: _captureBuffer,
                          isAtLiveEdge: _isAtLiveEdge,
                          streamStartEpoch: _streamStartEpoch,
                          currentPositionEpoch: widget.isLive ? _currentPositionEpoch : null,
                          onLiveSeek: _captureBuffer != null ? _seekLiveToEpoch : null,
                          onLiveSeekBy: _captureBuffer != null ? _liveSeek.seekBy : null,
                          onJumpToLive: _captureBuffer != null && !_isAtLiveEdge ? _jumpToLiveEdge : null,
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
      ),
    );
  }
}
