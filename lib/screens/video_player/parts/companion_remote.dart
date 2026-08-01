part of '../../video_player_screen.dart';

extension _VideoPlayerCompanionRemoteMethods on VideoPlayerScreenState {
  void _setupCompanionRemoteCallbacks() {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.playerHomeFallback ??= receiver.onHome;
    receiver.playerOwner = this;
    receiver.onStop = () {
      if (mounted) _handleBackButton();
    };
    receiver.onNextTrack = () {
      if (mounted && _nextEpisode != null) _playNext();
    };
    receiver.onPreviousTrack = () {
      if (mounted) unawaited(_restartOrPlayPrevious());
    };
    receiver.onSeekForward = () => _dispatchCompanionSeek(1);
    receiver.onSeekBackward = () => _dispatchCompanionSeek(-1);
    receiver.onVolumeUp = () => _dispatchCompanionVolume(10);
    receiver.onVolumeDown = () => _dispatchCompanionVolume(-10);
    receiver.onVolumeMute = _dispatchCompanionMute;
    receiver.onSubtitles = () {
      if (_canControlPlayback()) _cycleSubtitleTrack();
    };
    receiver.onAudioTracks = () {
      if (_canControlPlayback()) _cycleAudioTrack();
    };
    receiver.onFullscreen = _toggleFullscreen;

    // Override home to exit the player first. Replacements inherit the base
    // MainScreen callback rather than chaining through the outgoing player.
    _savedOnHome = receiver.playerHomeFallback;
    receiver.onHome = () {
      if (mounted) _handleHomeButton();
    };

    // Store provider reference for use in dispose and notify remote
    try {
      _companionRemoteProvider = context.read<CompanionRemoteProvider>();
      _companionRemoteProvider!.sendCommand(RemoteCommandType.syncState, data: {'playerActive': true});
    } catch (e) {
      appLogger.d('CompanionRemote provider unavailable', error: e);
    }
  }

  void _dispatchCompanionSeek(int direction) {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || !_canControlPlayback()) return;
    final settings = SettingsService.instance;
    final seconds = settings.read(SettingsService.seekTimeSmall) * direction;
    // _seekRelative captures the current player synchronously before its first
    // await, binding this command to the exact screen/player owner at receipt.
    unawaited(
      _seekRelative(Duration(seconds: seconds)).catchError((Object error, StackTrace stackTrace) {
        appLogger.w('Companion seek failed', error: error, stackTrace: stackTrace);
      }),
    );
  }

  void _dispatchCompanionVolume(double delta) {
    final currentPlayer = player;
    final controller = _volumeController;
    if (!mounted || currentPlayer == null || controller == null || !controller.ownsPlayer(currentPlayer)) {
      return;
    }
    controller.adjust(delta);
  }

  void _dispatchCompanionMute() {
    final currentPlayer = player;
    final controller = _volumeController;
    if (!mounted || currentPlayer == null || controller == null || !controller.ownsPlayer(currentPlayer)) {
      return;
    }
    controller.toggleMute();
  }

  void _cleanupCompanionRemoteCallbacks() {
    final receiver = CompanionRemoteReceiver.instance;
    if (!identical(receiver.playerOwner, this)) {
      _companionRemoteProvider = null;
      return;
    }
    receiver.onStop = null;
    receiver.onNextTrack = null;
    receiver.onPreviousTrack = null;
    receiver.onSeekForward = null;
    receiver.onSeekBackward = null;
    receiver.onVolumeUp = null;
    receiver.onVolumeDown = null;
    receiver.onVolumeMute = null;
    receiver.onSubtitles = null;
    receiver.onAudioTracks = null;
    receiver.onFullscreen = null;
    receiver.onHome = receiver.playerHomeFallback;
    receiver.playerHomeFallback = null;
    receiver.playerOwner = null;
    _savedOnHome = null;

    // Notify only when the active player owner exits.
    _companionRemoteProvider?.sendCommand(RemoteCommandType.syncState, data: {'playerActive': false});
    _companionRemoteProvider = null;
  }

  void _cycleSubtitleTrack() {
    final sourceTracks = _sourceSubtitleTracksForControls();
    if (!_isOfflinePlayback && sourceTracks.isNotEmpty) {
      _pendingSubtitleCycleCount++;
      if (!_subtitleCycleDrainActive) unawaited(_drainSubtitleCycles());
      return;
    }
    _trackManager?.cycleSubtitleTrack();
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
            _trackManager?.cycleSubtitleTrack();
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

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;
    await FullscreenStateManager().toggleFullscreen();
  }
}
