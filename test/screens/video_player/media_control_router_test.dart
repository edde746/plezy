import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/screens/video_player/media_control_router.dart';

void main() {
  test('denied playback and media-item commands are consumed without mutation', () {
    var canControl = false;
    var canNavigate = false;
    final calls = <String>[];
    final router = _router(canControl: () => canControl, canNavigate: () => canNavigate, calls: calls);

    final denied = <MediaControlEvent>[
      const PlayEvent(),
      const PauseEvent(),
      const TogglePlayPauseEvent(),
      const SeekEvent(Duration(seconds: 8)),
      const SkipForwardEvent(Duration(seconds: 10)),
      const SkipBackwardEvent(null),
      const SetSpeedEvent(1.5),
      const NextTrackEvent(),
      const PreviousTrackEvent(),
    ];
    for (final event in denied) {
      expect(router.route(event), isTrue, reason: '$event must be consumed');
    }
    expect(calls, isEmpty);

    expect(router.route(const StopEvent()), isTrue);
    expect(calls, ['stop']);

    canControl = true;
    for (final event in denied) {
      router.route(event);
    }
    expect(calls, ['stop', 'play', 'pause', 'toggle', 'seek:8', 'forward:10', 'backward:null', 'speed:1.5']);

    canNavigate = true;
    router.route(const NextTrackEvent());
    router.route(const PreviousTrackEvent());
    expect(calls.sublist(calls.length - 2), ['next', 'previous']);
  });

  test('unknown lifecycle events are left to the screen lifecycle handler', () {
    final router = _router(canControl: () => false, canNavigate: () => false, calls: []);
    expect(router.route(const AudioInterruptionBeganEvent()), isFalse);
    expect(router.route(const AudioRouteOldDeviceUnavailableEvent()), isFalse);
  });
}

VideoPlayerMediaControlRouter _router({
  required bool Function() canControl,
  required bool Function() canNavigate,
  required List<String> calls,
}) {
  return VideoPlayerMediaControlRouter(
    canControlPlayback: canControl,
    canNavigateMediaItems: canNavigate,
    onPlay: () => calls.add('play'),
    onPause: () => calls.add('pause'),
    onTogglePlayPause: () => calls.add('toggle'),
    onSeek: (position) => calls.add('seek:${position.inSeconds}'),
    onNext: () => calls.add('next'),
    onPrevious: () => calls.add('previous'),
    onStop: () => calls.add('stop'),
    onSkipForward: (interval) => calls.add('forward:${interval?.inSeconds}'),
    onSkipBackward: (interval) => calls.add('backward:${interval?.inSeconds}'),
    onSetSpeed: (speed) => calls.add('speed:$speed'),
  );
}
