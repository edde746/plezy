import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/driver_distraction.dart';
import 'package:plezy/services/media_control_router.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  setUp(TvDetectionService.debugReset);
  tearDown(TvDetectionService.debugReset);

  test('automotive background policy pauses independently of handheld and TV detection', () {
    expect(shouldPauseVideoForBackground(isHandheld: false, isTv: false, isAutomotive: true), isTrue);
    expect(shouldPauseVideoForBackground(isHandheld: true, isTv: false, isAutomotive: false), isTrue);
    expect(shouldPauseVideoForBackground(isHandheld: false, isTv: true, isAutomotive: false), isTrue);
    expect(shouldPauseVideoForBackground(isHandheld: false, isTv: false, isAutomotive: false), isFalse);
  });

  test('automotive playback is allowed only while resumed', () {
    expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.resumed), isTrue);
    expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.inactive), isFalse);
    expect(automotivePlaybackAllowed(isAutomotive: true, state: null), isFalse);
    expect(automotivePlaybackAllowed(isAutomotive: false, state: AppLifecycleState.inactive), isTrue);
  });

  testWidgets('automotive media controls block navigation but never swallow pause', (tester) async {
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    TvDetectionService.debugSetAutomotiveOverride(true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);

    final calls = <String>[];
    // Mirrors the production wiring in playback_services.dart: playback
    // authority is Watch Together's alone, and only the navigation gate carries
    // the automotive requirement. Starting playback is refused downstream by
    // the playback-intent wrappers, not here — `route` consumes a denied event,
    // so gating `canControlPlayback` would silently drop `PauseEvent`.
    final router = MediaControlRouter(
      canControlPlayback: () => true,
      canNavigateMediaItems: automotivePlaybackAllowedNow,
      onPlay: () => calls.add('play'),
      onPause: () => calls.add('pause'),
      onTogglePlayPause: () => calls.add('toggle'),
      onSeek: (_) => calls.add('seek'),
      onNext: () => calls.add('next'),
      onPrevious: () => calls.add('previous'),
      onStop: () => calls.add('stop'),
      onSkipForward: (_) => calls.add('forward'),
      onSkipBackward: (_) => calls.add('backward'),
      onSetSpeed: (_) => calls.add('speed'),
    );

    // Stopping audio must stay reachable while the vehicle restricts the app.
    expect(router.route(const PauseEvent()), isTrue);
    expect(router.route(const StopEvent()), isTrue);
    expect(calls, ['pause', 'stop']);

    // Queue navigation starts audio, so it is refused while restricted.
    expect(router.route(const NextTrackEvent()), isTrue);
    expect(router.route(const PreviousTrackEvent()), isTrue);
    expect(calls, ['pause', 'stop']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(router.route(const NextTrackEvent()), isTrue);
    expect(calls, ['pause', 'stop', 'next']);
  });
}
