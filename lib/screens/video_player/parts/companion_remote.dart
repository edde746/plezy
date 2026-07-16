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
    receiver.onSeekForward = () async {
      final settings = await SettingsService.getInstance();
      await _seekRelative(Duration(seconds: settings.read(SettingsService.seekTimeSmall)));
    };
    receiver.onSeekBackward = () async {
      final settings = await SettingsService.getInstance();
      await _seekRelative(Duration(seconds: -settings.read(SettingsService.seekTimeSmall)));
    };
    receiver.onVolumeUp = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.read(SettingsService.maxVolume).toDouble();
      final newVolume = (player!.state.volume + 10).clamp(0.0, maxVol);
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
    };
    receiver.onVolumeDown = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.read(SettingsService.maxVolume).toDouble();
      final newVolume = (player!.state.volume - 10).clamp(0.0, maxVol);
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
    };
    receiver.onVolumeMute = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final transition = settings.resolveMuteToggle(player!.state.volume);
      unawaited(player!.setVolume(transition.playerVolume));
      unawaited(settings.write(SettingsService.volume, transition.persistedVolume));
    };
    receiver.onSubtitles = _cycleSubtitleTrack;
    receiver.onAudioTracks = _cycleAudioTrack;
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

  void _cycleSubtitleTrack() => _trackManager?.cycleSubtitleTrack();

  void _cycleAudioTrack() => _trackManager?.cycleAudioTrack();

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;
    await FullscreenStateManager().toggleFullscreen();
  }
}
