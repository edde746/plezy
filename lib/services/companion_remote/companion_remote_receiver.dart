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
  VoidCallback? onNextTrack;
  VoidCallback? onPreviousTrack;
  VoidCallback? onStop;
  VoidCallback? onSeekForward;
  VoidCallback? onSeekBackward;
  VoidCallback? onVolumeUp;
  VoidCallback? onVolumeDown;
  VoidCallback? onVolumeMute;
  VoidCallback? onSubtitles;
  VoidCallback? onAudioTracks;
  VoidCallback? onFullscreen;

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
        simulateKeyPress(LogicalKeyboardKey.space);
      case RemoteCommandType.pause:
        simulateKeyPress(LogicalKeyboardKey.space);
      case RemoteCommandType.playPause:
        simulateKeyPress(LogicalKeyboardKey.space);
      case RemoteCommandType.seekForward:
        onSeekForward?.call();
      case RemoteCommandType.seekBackward:
        onSeekBackward?.call();

      case RemoteCommandType.volumeUp:
        onVolumeUp?.call();
      case RemoteCommandType.volumeDown:
        onVolumeDown?.call();
      case RemoteCommandType.volumeMute:
        onVolumeMute?.call();

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

      case RemoteCommandType.stop:
        onStop?.call();
      case RemoteCommandType.nextTrack:
        onNextTrack?.call();
      case RemoteCommandType.previousTrack:
        onPreviousTrack?.call();

      case RemoteCommandType.subtitles:
        onSubtitles?.call();
      case RemoteCommandType.audioTracks:
        onAudioTracks?.call();

      case RemoteCommandType.fullscreen:
        if (onFullscreen != null) {
          onFullscreen!.call();
        } else {
          simulateKeyPress(LogicalKeyboardKey.keyF);
        }

      case RemoteCommandType.ping:
      case RemoteCommandType.pong:
      case RemoteCommandType.ack:
      case RemoteCommandType.deviceInfo:
      case RemoteCommandType.disconnect:
      case RemoteCommandType.syncState:
        break;

      default:
        appLogger.w('CompanionRemoteReceiver: Unhandled command type: ${command.type}');
    }
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
  RemoteCommandType.fullscreen => true,
};
