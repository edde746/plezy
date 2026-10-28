import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/completion_latch.dart';
import 'package:plezy/services/settings_service.dart';

import '../../test_helpers/prefs.dart';

/// Publishes a starting timeline the way `open()` does, without a platform
/// round-trip. The position stream is throttled to 4Hz, so the seed also keeps
/// the test off the wall clock.
class _SeededPlayerNative extends PlayerNative {
  void seedPosition(Duration position) => resetPlaybackProgress(position);
}

/// End-to-end contract for a natural end of file: the Dart completion flow has
/// to read it as the *real* end so Play Next / auto-play runs. A misread routes
/// into dead-stream recovery instead, leaving a black screen and a "playing"
/// timeline.
///
/// mpv runs with `keep-open=yes`, so a natural end of file sends no `end-file`
/// event: mpv parks on the last frame, pauses, and raises `eof-reached`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const durationMs = 2623668;
  const duration = Duration(milliseconds: durationMs);
  // The last frame's timestamp sits a frame short of the container duration.
  const lastFrame = Duration(milliseconds: durationMs - 42);

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('mpv parking on the last frame completes the item at its duration', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.plezy/mpv_player');
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final player = _SeededPlayerNative();
    final completions = <bool>[];
    final subscription = player.streams.completed.listen(completions.add);
    addTearDown(() async {
      await subscription.cancel();
      await player.dispose();
    });

    // Direct play a few seconds from the end: duration comes from the native
    // property, as it does when nothing overrides the timeline.
    player.seedPosition(const Duration(milliseconds: 2620000));
    player.handlePropertyChange('duration', durationMs / 1000.0);
    player.handlePropertyChange('pause', false);
    expect(player.state.duration, duration);
    expect(player.state.playing, isTrue);

    player.handlePropertyChange('time-pos', lastFrame.inMilliseconds / 1000.0);
    player.handlePropertyChange('pause', true);
    player.handlePropertyChange('eof-reached', true);
    await Future<void>.delayed(Duration.zero);

    // The last frame lands on the unthrottled position immediately; the 4Hz
    // state snapshot may still carry the previous tick, which is why the
    // classifier below has to hold for both.
    expect(player.currentPosition, lastFrame);
    expect(player.state.playing, isFalse);
    expect(player.state.completed, isTrue);
    expect(completions.last, isTrue);

    // What the screen does with that state: the EOF is genuine, so the item is
    // stopped at its duration and the next episode is presented.
    for (final position in [player.state.position, player.currentPosition]) {
      expect(
        classifyEofSignal(
          positionMs: position.inMilliseconds,
          playerDurationMs: player.state.duration.inMilliseconds,
          metadataDurationMs: durationMs,
        ),
        EofSignalClass.genuine,
        reason: '$position',
      );
    }
    expect(
      completionNavigationAction(hasNext: true, adjacentStatus: QueueNavigationStatus.found),
      CompletionNavigationAction.presentNext,
    );
  });

  test('the same event from a stale mid-file position stays a dead-stream signal', () {
    // An EOF carrying a stale mid-file position is not the end of the item: it
    // routes into spurious-EOF recovery instead.
    expect(
      classifyEofSignal(positionMs: 1200000, playerDurationMs: durationMs, metadataDurationMs: durationMs),
      EofSignalClass.spurious,
    );
  });
}
