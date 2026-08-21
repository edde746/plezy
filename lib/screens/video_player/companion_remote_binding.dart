import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/companion_remote/remote_command.dart';
import '../../mpv/mpv.dart';
import '../../providers/companion_remote_provider.dart';
import '../../services/companion_remote/companion_remote_receiver.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../services/settings_service.dart';
import '../../services/video_volume_controller.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';

/// Wires the player screen into the [CompanionRemoteReceiver] callback slots
/// and owns the home-button fallback plus the provider handle used for
/// player-active sync notifications.
///
/// Plain State-owned helper. [bind] installs this instance as the receiver's
/// `playerOwner` token; [unbind] restores the slots only while this instance
/// still owns them, so a replacement screen's wiring survives the outgoing
/// screen's dispose. The player and volume controller are injected as
/// late-bound getters because both are re-created across playback attempts,
/// and volume/seek dispatch must bind to the player at command receipt.
class CompanionRemoteBinding {
  CompanionRemoteBinding({
    required this._player,
    required this._isMounted,
    required this._canControlPlayback,
    required this._volumeController,
    required this._hasNextEpisode,
    required this._onStop,
    required this._onPlayNext,
    required this._onPlayPrevious,
    required this._seekRelative,
    required this._onCycleSubtitles,
    required this._onCycleAudio,
    required this._onHome,
    required this._readProvider,
  });

  final Player? Function() _player;
  final bool Function() _isMounted;
  final bool Function() _canControlPlayback;
  final VideoVolumeController? Function() _volumeController;
  final bool Function() _hasNextEpisode;
  final void Function() _onStop;
  final void Function() _onPlayNext;
  final Future<void> Function() _onPlayPrevious;
  final Future<void> Function(Duration offset) _seekRelative;
  final void Function() _onCycleSubtitles;
  final void Function() _onCycleAudio;
  final void Function() _onHome;
  final CompanionRemoteProvider Function() _readProvider;

  CompanionRemoteProvider? _provider;
  VoidCallback? _savedOnHome;

  /// The MainScreen home callback saved while this screen overrides the
  /// receiver's home slot; the screen's home-button handler invokes it after
  /// popping back to the first route.
  VoidCallback? get savedOnHome => _savedOnHome;

  void bind() {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.playerHomeFallback ??= receiver.onHome;
    receiver.playerOwner = this;
    receiver.onStop = () {
      if (_isMounted()) _onStop();
    };
    receiver.onNextTrack = () {
      if (_isMounted() && _hasNextEpisode()) _onPlayNext();
    };
    receiver.onPreviousTrack = () {
      if (_isMounted()) unawaited(_onPlayPrevious());
    };
    receiver.onSeekForward = () => _dispatchSeek(1);
    receiver.onSeekBackward = () => _dispatchSeek(-1);
    receiver.onVolumeUp = () => _dispatchVolume(10);
    receiver.onVolumeDown = () => _dispatchVolume(-10);
    receiver.onVolumeMute = _dispatchMute;
    receiver.onSubtitles = () {
      if (_canControlPlayback()) _onCycleSubtitles();
    };
    receiver.onAudioTracks = () {
      if (_canControlPlayback()) _onCycleAudio();
    };
    receiver.onFullscreen = _toggleFullscreen;

    // Override home to exit the player first. Replacements inherit the base
    // MainScreen callback rather than chaining through the outgoing player.
    _savedOnHome = receiver.playerHomeFallback;
    receiver.onHome = () {
      if (_isMounted()) _onHome();
    };

    // Store provider reference for use in dispose and notify remote
    try {
      _provider = _readProvider();
      _provider!.sendCommand(RemoteCommandType.syncState, data: {'playerActive': true});
    } catch (e) {
      appLogger.d('CompanionRemote provider unavailable', error: e);
    }
  }

  void _dispatchSeek(int direction) {
    final currentPlayer = _player();
    if (!_isMounted() || currentPlayer == null || !_canControlPlayback()) return;
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

  void _dispatchVolume(double delta) {
    final currentPlayer = _player();
    final controller = _volumeController();
    if (!_isMounted() || currentPlayer == null || controller == null || !controller.ownsPlayer(currentPlayer)) {
      return;
    }
    controller.adjust(delta);
  }

  void _dispatchMute() {
    final currentPlayer = _player();
    final controller = _volumeController();
    if (!_isMounted() || currentPlayer == null || controller == null || !controller.ownsPlayer(currentPlayer)) {
      return;
    }
    controller.toggleMute();
  }

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;
    await FullscreenStateManager().toggleFullscreen();
  }

  void unbind() {
    final receiver = CompanionRemoteReceiver.instance;
    if (!identical(receiver.playerOwner, this)) {
      _provider = null;
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
    _provider?.sendCommand(RemoteCommandType.syncState, data: {'playerActive': false});
    _provider = null;
  }
}
