import 'package:os_media_controls/os_media_controls.dart';

/// Screen-owned authorization boundary for user-originated OS media commands.
///
/// Lifecycle/audio-route events are handled before this router. Recognized
/// commands are consumed even when denied so they cannot reach a background
/// route or stale player owner.
final class VideoPlayerMediaControlRouter {
  const VideoPlayerMediaControlRouter({
    required this.canControlPlayback,
    required this.canNavigateMediaItems,
    required this.onPlay,
    required this.onPause,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onNext,
    required this.onPrevious,
    required this.onStop,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onSetSpeed,
  });

  final bool Function() canControlPlayback;
  final bool Function() canNavigateMediaItems;
  final void Function() onPlay;
  final void Function() onPause;
  final void Function() onTogglePlayPause;
  final void Function(Duration position) onSeek;
  final void Function() onNext;
  final void Function() onPrevious;
  final void Function() onStop;
  final void Function(Duration? interval) onSkipForward;
  final void Function(Duration? interval) onSkipBackward;
  final void Function(double speed) onSetSpeed;

  bool route(MediaControlEvent event) {
    if (event is StopEvent) {
      onStop();
      return true;
    }
    if (event is NextTrackEvent) {
      if (canNavigateMediaItems()) onNext();
      return true;
    }
    if (event is PreviousTrackEvent) {
      if (canNavigateMediaItems()) onPrevious();
      return true;
    }
    if (event is PlayEvent) {
      if (canControlPlayback()) onPlay();
      return true;
    }
    if (event is PauseEvent) {
      if (canControlPlayback()) onPause();
      return true;
    }
    if (event is TogglePlayPauseEvent) {
      if (canControlPlayback()) onTogglePlayPause();
      return true;
    }
    if (event is SeekEvent) {
      if (canControlPlayback()) onSeek(event.position);
      return true;
    }
    if (event is SkipForwardEvent) {
      if (canControlPlayback()) onSkipForward(event.interval);
      return true;
    }
    if (event is SkipBackwardEvent) {
      if (canControlPlayback()) onSkipBackward(event.interval);
      return true;
    }
    if (event is SetSpeedEvent) {
      if (canControlPlayback()) onSetSpeed(event.speed);
      return true;
    }
    return false;
  }
}
