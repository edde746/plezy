import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../focus/input_mode_tracker.dart';
import '../../models/companion_remote/remote_command.dart';
import '../../utils/app_logger.dart';
import '../../utils/key_event_simulator.dart';

class CompanionRemoteReceiver {
  CompanionRemoteReceiver._();

  static CompanionRemoteReceiver? _instance;

  static CompanionRemoteReceiver get instance {
    _instance ??= CompanionRemoteReceiver._();
    return _instance!;
  }

  /// Owners prevent a disposed screen from clearing callbacks installed by a
  /// replacement screen later in the same frame.
  Object? navigationOwner;
  Object? playerOwner;
  VoidCallback? playerHomeFallback;

  VoidCallback? onTabNext;
  VoidCallback? onTabPrevious;
  VoidCallback? onTabDiscover;
  VoidCallback? onTabLibraries;
  VoidCallback? onTabSearch;
  VoidCallback? onTabDownloads;
  VoidCallback? onTabSettings;
  VoidCallback? onHome;
  void Function(String? query)? onSearchAction;
  void Function(String serverId, String ratingKey, int? offset)? onPlayMediaAction;
  void Function(String serverId, String ratingKey)? onShuffleMediaAction;
  void Function(String serverId, String ratingKey, bool watched)? onSetWatchedAction;
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onPlayPause;
  VoidCallback? onNextTrack;
  VoidCallback? onPreviousTrack;
  VoidCallback? onStop;
  VoidCallback? onSkipIntro;
  VoidCallback? onSkipCredits;
  VoidCallback? onSeekForward;
  VoidCallback? onSeekBackward;
  void Function(int positionMs)? onSeekTo;
  VoidCallback? onVolumeUp;
  VoidCallback? onVolumeDown;
  VoidCallback? onVolumeMute;
  void Function(double volume)? onVolumeSet;
  VoidCallback? onSubtitles;
  VoidCallback? onAudioTracks;
  void Function(Map<String, dynamic> criteria)? onSetSubtitleTrack;
  void Function(Map<String, dynamic> criteria)? onSetAudioTrack;
  void Function(Map<String, dynamic> criteria)? onSetQuality;
  void Function(Map<String, dynamic> criteria)? onSetAudioDevice;
  void Function(Map<String, dynamic> criteria)? onSetSubtitleSync;
  void Function(Map<String, dynamic> criteria)? onSetAudioSync;
  void Function(Map<String, dynamic> criteria)? onSetSpeed;
  void Function(Map<String, dynamic> criteria)? onSetSecondarySubtitleTrack;
  void Function(Map<String, dynamic> criteria)? onSetZoom;
  VoidCallback? onFullscreen;
  void Function(bool enabled)? onSetFullscreen;

  /// Called after any command that could have changed playback state, so the
  /// active player can push a fresh state frame instead of leaving the
  /// controller to wait out the 5s heartbeat. Set only while a player owns the
  /// receiver. Purely informational commands do not reach it.
  VoidCallback? onCommandHandled;

  void handleCommand(RemoteCommand command, BuildContext? _) {
    appLogger.d('CompanionRemoteReceiver: Handling command: ${command.type}');

    // A paired phone cannot point, so any viewer command is evidence of a
    // pointerless device. Protocol frames are not viewer input: promoting on the
    // periodic ping would flip an idle desktop host into keyboard mode — and hide
    // its cursor — on every heartbeat.
    if (_isViewerInput(command.type)) {
      InputModeTracker.reportNonPointerInput();
      scheduleFrameIfIdle();
    }

    switch (command.type) {
      case RemoteCommandType.dpadUp:
        simulateKeyPress(LogicalKeyboardKey.arrowUp);
      case RemoteCommandType.dpadDown:
        simulateKeyPress(LogicalKeyboardKey.arrowDown);
      case RemoteCommandType.dpadLeft:
        simulateKeyPress(LogicalKeyboardKey.arrowLeft);
      case RemoteCommandType.dpadRight:
        simulateKeyPress(LogicalKeyboardKey.arrowRight);
      case RemoteCommandType.select:
        simulateKeyPress(LogicalKeyboardKey.enter);
      case RemoteCommandType.back:
        simulateKeyPress(LogicalKeyboardKey.gameButtonB);
      case RemoteCommandType.contextMenu:
        simulateKeyPress(LogicalKeyboardKey.contextMenu);

      case RemoteCommandType.play:
        _playbackOrSpace(onPlay);
      case RemoteCommandType.pause:
        _playbackOrSpace(onPause);
      case RemoteCommandType.playPause:
        _playbackOrSpace(onPlayPause);
      case RemoteCommandType.seekForward:
        onSeekForward?.call();
      case RemoteCommandType.seekBackward:
        onSeekBackward?.call();
      case RemoteCommandType.seekTo:
        final ms = (command.data?['positionMs'] as num?)?.toInt();
        if (ms != null && ms >= 0) onSeekTo?.call(ms);

      case RemoteCommandType.volumeUp:
        onVolumeUp?.call();
      case RemoteCommandType.volumeDown:
        onVolumeDown?.call();
      case RemoteCommandType.volumeMute:
        onVolumeMute?.call();
      case RemoteCommandType.volumeSet:
        final v = (command.data?['volume'] as num?)?.toDouble();
        if (v != null) onVolumeSet?.call(v);

      case RemoteCommandType.tabNext:
        onTabNext?.call();
      case RemoteCommandType.tabPrevious:
        onTabPrevious?.call();
      case RemoteCommandType.tabDiscover:
        onTabDiscover?.call();
      case RemoteCommandType.tabLibraries:
        onTabLibraries?.call();
      case RemoteCommandType.tabSearch:
        onTabSearch?.call();
      case RemoteCommandType.tabDownloads:
        onTabDownloads?.call();
      case RemoteCommandType.tabSettings:
        onTabSettings?.call();

      case RemoteCommandType.home:
        onHome?.call();
      case RemoteCommandType.search:
        final query = command.data?['query'] as String?;
        onSearchAction?.call(query);
      case RemoteCommandType.playMedia:
        final serverId = command.data?['serverId'] as String?;
        final ratingKey = command.data?['ratingKey'] as String?;
        final offset = (command.data?['offset'] as num?)?.toInt();
        if (serverId != null && ratingKey != null) {
          onPlayMediaAction?.call(serverId, ratingKey, offset);
        }
      case RemoteCommandType.shuffleMedia:
        {
          final shuffleServerId = command.data?['serverId'] as String?;
          final shuffleRatingKey = command.data?['ratingKey'] as String?;
          if (shuffleServerId != null && shuffleRatingKey != null) {
            onShuffleMediaAction?.call(shuffleServerId, shuffleRatingKey);
          }
        }
      case RemoteCommandType.markWatched:
      case RemoteCommandType.markUnwatched:
        {
          final watchServerId = command.data?['serverId'] as String?;
          final watchRatingKey = command.data?['ratingKey'] as String?;
          if (watchServerId != null && watchRatingKey != null) {
            onSetWatchedAction?.call(watchServerId, watchRatingKey, command.type == RemoteCommandType.markWatched);
          }
        }

      case RemoteCommandType.stop:
        onStop?.call();
      case RemoteCommandType.skipIntro:
        onSkipIntro?.call();
      case RemoteCommandType.skipCredits:
        onSkipCredits?.call();
      case RemoteCommandType.nextTrack:
        onNextTrack?.call();
      case RemoteCommandType.previousTrack:
        onPreviousTrack?.call();

      case RemoteCommandType.subtitles:
        onSubtitles?.call();
      case RemoteCommandType.audioTracks:
        onAudioTracks?.call();
      case RemoteCommandType.setSubtitleTrack:
        onSetSubtitleTrack?.call(command.data ?? const {});
      case RemoteCommandType.setAudioTrack:
        onSetAudioTrack?.call(command.data ?? const {});
      case RemoteCommandType.setQuality:
        onSetQuality?.call(command.data ?? const {});
      case RemoteCommandType.setAudioDevice:
        onSetAudioDevice?.call(command.data ?? const {});
      case RemoteCommandType.setSubtitleSync:
        onSetSubtitleSync?.call(command.data ?? const {});
      case RemoteCommandType.setAudioSync:
        onSetAudioSync?.call(command.data ?? const {});
      case RemoteCommandType.setSpeed:
        onSetSpeed?.call(command.data ?? const {});
      case RemoteCommandType.setSecondarySubtitleTrack:
        onSetSecondarySubtitleTrack?.call(command.data ?? const {});
      case RemoteCommandType.setZoom:
        onSetZoom?.call(command.data ?? const {});
      case RemoteCommandType.setFullscreen:
        // Absolute, idempotent counterpart to the stock `fullscreen` toggle:
        // {"enabled": true|false} drives the window to that exact state via the
        // app's own FullscreenStateManager — no focus grab, no accidental flip.
        final enabled = command.data?['enabled'] as bool?;
        if (enabled != null) onSetFullscreen?.call(enabled);

      case RemoteCommandType.fullscreen:
        if (onFullscreen != null) {
          onFullscreen!.call();
        } else {
          simulateKeyPress(LogicalKeyboardKey.keyF);
        }

      // Informational both ways — nothing changed, and answering an inbound
      // ack with a frame the controller may ack again would loop.
      case RemoteCommandType.ping:
      case RemoteCommandType.pong:
      case RemoteCommandType.ack:
      case RemoteCommandType.deviceInfo:
      case RemoteCommandType.disconnect:
      case RemoteCommandType.syncState:
        return;

      default:
        appLogger.w('CompanionRemoteReceiver: Unhandled command type: ${command.type}');
        return;
    }

    onCommandHandled?.call();
  }

  /// Drive playback directly when a player is attached, so a controller that
  /// cannot see the screen gets a deterministic result. Falls back to the space
  /// hotkey elsewhere, keeping the focus-tree behaviour every other screen relies on.
  void _playbackOrSpace(VoidCallback? callback) {
    if (callback != null) {
      callback();
      return;
    }
    simulateKeyPress(LogicalKeyboardKey.space);
  }
}

/// Exhaustive by design: no default clause, so adding a [RemoteCommandType]
/// is a compile error until someone decides whether it counts as viewer input.
bool _isViewerInput(RemoteCommandType type) => switch (type) {
  RemoteCommandType.ping ||
  RemoteCommandType.pong ||
  RemoteCommandType.ack ||
  RemoteCommandType.deviceInfo ||
  RemoteCommandType.disconnect ||
  RemoteCommandType.syncState => false,
  RemoteCommandType.dpadUp ||
  RemoteCommandType.dpadDown ||
  RemoteCommandType.dpadLeft ||
  RemoteCommandType.dpadRight ||
  RemoteCommandType.select ||
  RemoteCommandType.back ||
  RemoteCommandType.contextMenu ||
  RemoteCommandType.play ||
  RemoteCommandType.pause ||
  RemoteCommandType.playPause ||
  RemoteCommandType.stop ||
  RemoteCommandType.seekForward ||
  RemoteCommandType.seekBackward ||
  RemoteCommandType.nextTrack ||
  RemoteCommandType.previousTrack ||
  RemoteCommandType.skipIntro ||
  RemoteCommandType.skipCredits ||
  RemoteCommandType.volumeUp ||
  RemoteCommandType.volumeDown ||
  RemoteCommandType.volumeMute ||
  RemoteCommandType.volumeSet ||
  RemoteCommandType.tabNext ||
  RemoteCommandType.tabPrevious ||
  RemoteCommandType.tabDiscover ||
  RemoteCommandType.tabLibraries ||
  RemoteCommandType.tabSearch ||
  RemoteCommandType.tabDownloads ||
  RemoteCommandType.tabSettings ||
  RemoteCommandType.home ||
  RemoteCommandType.search ||
  RemoteCommandType.subtitles ||
  RemoteCommandType.audioTracks ||
  RemoteCommandType.qualitySettings ||
  RemoteCommandType.fullscreen ||
  RemoteCommandType.playMedia ||
  RemoteCommandType.shuffleMedia ||
  RemoteCommandType.markWatched ||
  RemoteCommandType.markUnwatched ||
  RemoteCommandType.seekTo ||
  RemoteCommandType.setSubtitleTrack ||
  RemoteCommandType.setAudioTrack ||
  RemoteCommandType.setQuality ||
  RemoteCommandType.setAudioDevice ||
  RemoteCommandType.setSubtitleSync ||
  RemoteCommandType.setAudioSync ||
  RemoteCommandType.setSpeed ||
  RemoteCommandType.setSecondarySubtitleTrack ||
  RemoteCommandType.setZoom ||
  RemoteCommandType.setFullscreen => true,
};
