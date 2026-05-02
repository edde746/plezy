part of '../../video_player_screen.dart';

extension _VideoPlayerBuildMethods on VideoPlayerScreenState {
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
              mainAxisSize: MainAxisSize.min,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
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
                      child: Text(t.common.retry),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => unawaited(_handleBackButton()), child: Text(t.common.back)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);

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
            // Initialize pinch gesture tracking (mobile only)
            if (!isMobile) return;
            if (_videoFilterManager != null) {
              _videoFilterManager!.isPinching = false;
            }
          },
          onScaleUpdate: (details) {
            // Track if this is a pinch gesture (2+ fingers) on mobile
            if (!isMobile) return;
            if (details.pointerCount >= 2 && _videoFilterManager != null) {
              _videoFilterManager!.isPinching = true;
            }
          },
          onScaleEnd: (details) {
            // Only toggle if we detected a pinch gesture on mobile
            if (!isMobile) return;
            if (_videoFilterManager != null && _videoFilterManager!.isPinching) {
              _toggleContainCover();
              _videoFilterManager!.isPinching = false;
            }
          },
          child: Stack(
            children: [
              // macOS PiP placeholder — video is in PiP window, show background with icon
              // Placed before Video so controls render on top
              if (Platform.isMacOS) const VideoPlayerMacPipPlaceholder(),
              // Video player
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Update player size when layout changes
                    final newSize = Size(constraints.maxWidth, constraints.maxHeight);

                    // Update player size in video filter manager, PiP manager, and native layer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && player != null) {
                        _videoFilterManager?.updatePlayerSize(newSize);
                        _videoPIPManager?.updatePlayerSize(newSize);
                        // Update ambient lighting shader if active (output aspect changed)
                        _updateAmbientLightingOnResize(newSize);
                        // Update Metal layer frame on iOS/macOS for rotation
                        player!.updateFrame();
                      }
                    });

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
                      onPrevious = (_previousEpisode != null && _canNavigateEpisodes()) ? _playPrevious : null;
                    }

                    return Video(
                      player: player!,
                      controls: (context) => plexVideoControlsBuilder(
                        player!,
                        _currentMetadata,
                        onNext: onNext,
                        onPrevious: onPrevious,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        selectedQualityPreset: _selectedQualityPreset,
                        serverSupportsTranscoding: _serverSupportsTranscoding,
                        isTranscoding: _isTranscoding,
                        isOfflinePlayback: _isOfflinePlayback,
                        sourceAudioTracks: _currentMediaInfo?.audioTracks ?? const [],
                        selectedAudioStreamId: _selectedAudioStreamId,
                        onTogglePIPMode: _togglePIPMode,
                        boxFitMode: _videoFilterManager?.boxFitMode ?? 0,
                        onCycleBoxFitMode: _cycleBoxFitMode,
                        onCycleAudioTrack: _cycleAudioTrack,
                        onCycleSubtitleTrack: _cycleSubtitleTrack,
                        onAudioTrackChanged: _onAudioTrackChanged,
                        onSubtitleTrackChanged: _onSubtitleTrackChanged,
                        onSecondarySubtitleTrackChanged: _onSecondarySubtitleTrackChanged,
                        onSeekCompleted: (position) {
                          // Notify Watch Together of seek for sync
                          // Note: canControl() check is done in sync manager, not here
                          // This matches play/pause behavior and avoids timing issues
                          try {
                            final watchTogether = this.context.read<WatchTogetherProvider>();
                            if (watchTogether.isInSession) {
                              watchTogether.onLocalSeek(position);
                            }
                          } catch (e) {
                            // Watch Together not available, ignore
                          }
                        },
                        onBack: _handleBackButton,
                        onReachedEnd: ({skipAutoPlayCountdown = false}) =>
                            _onVideoCompleted(true, skipAutoPlayCountdown: skipAutoPlayCountdown),
                        canControl: canControl,
                        hasFirstFrame: _hasFirstFrame,
                        playNextFocusNode: _showPlayNextDialog ? _playNextConfirmFocusNode : null,
                        controlsVisible: _controlsVisible,
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
                        onLiveSeek: _captureBuffer != null ? _seekLivePosition : null,
                        onJumpToLive: _captureBuffer != null && !_isAtLiveEdge ? _jumpToLiveEdge : null,
                        isAmbientLightingEnabled: _ambientLightingService?.isEnabled ?? false,
                        onToggleAmbientLighting: _toggleAmbientLighting,
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
                controlsVisible: _controlsVisible,
                onCancel: _cancelAutoPlay,
                onPlayNext: _playNext,
              ),
              // "Still watching?" overlay (hidden in PiP mode)
              VideoPlayerStillWatchingOverlay(
                visible: _showStillWatchingPrompt,
                countdown: _stillWatchingCountdown,
                pauseFocusNode: _stillWatchingPauseFocusNode,
                continueFocusNode: _stillWatchingContinueFocusNode,
                controlsVisible: _controlsVisible,
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
