import 'package:os_media_controls/os_media_controls.dart';

/// Authorization boundary for user-originated OS media commands, owned by
/// whoever holds the transport (the video screen, the music session).
///
/// Lifecycle/audio-route events are handled before this router: [route]
/// reports `false` for what it does not recognize. Recognized commands are
/// consumed even when denied so they cannot reach a background route or stale
/// player owner. Both gates stay required — every owner states its policy.
final class MediaControlRouter {
  const MediaControlRouter({
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

/// Which way an Apple TV fast-forward/rewind press points, or null for none.
///
/// tvOS reports the dedicated FF/RW buttons of IR and HDMI-CEC remotes as
/// `changePlaybackRateCommand` with a scan rate (positive for fast-forward,
/// negative for rewind, and a step back toward normal on the opposite button).
/// Applied as a playback speed, rewind pauses or plays in slow motion and
/// fast-forward races ahead, depending on what tvOS last saw. The player has
/// no scan mode, so on Apple TV a rate request is read as a direction
/// relative to the current speed; the in-app speed menu sets the rate
/// directly and never goes through this command.
bool? appleTvScanIsForward(double requestedRate, double currentRate) {
  if (requestedRate > currentRate) return true;
  if (requestedRate < currentRate) return false;
  return null;
}
