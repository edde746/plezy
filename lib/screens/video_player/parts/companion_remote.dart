part of '../../video_player_screen.dart';

extension _VideoPlayerCompanionRemoteMethods on VideoPlayerScreenState {
  void _setupCompanionRemoteCallbacks() {
    final receiver = CompanionRemoteReceiver.instance;
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
      final newVolume = player!.state.volume > 0 ? 0.0 : 100.0;
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
    };
    receiver.onSubtitles = _cycleSubtitleTrack;
    receiver.onAudioTracks = _cycleAudioTrack;
    receiver.onFullscreen = _toggleFullscreen;

    // Override home to exit the player first (main screen handler runs after pop)
    _savedOnHome = receiver.onHome;
    receiver.onHome = () {
      if (mounted) _handleBackButton();
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
    receiver.onHome = _savedOnHome;
    _savedOnHome = null;

    // Notify remote that player is no longer active
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
