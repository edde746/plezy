import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/completion_latch.dart';
import 'package:plezy/services/settings_service.dart';

import '../../test_helpers/prefs.dart';

/// Publishes a starting timeline the way `open()` does, without a platform
/// round-trip. The position stream is throttled to 4Hz, so the seed also keeps
/// the test off the wall clock.
class _SeededPlayerAndroid extends PlayerAndroid {
  void seedPosition(Duration position) => resetPlaybackProgress(position);
}

/// End-to-end contract for #1673: a player that runs past its duration without
/// ending is reported by the native side as an ordinary end of file, and the
/// Dart completion flow has to read it as the *real* end so Play Next / auto-play
/// runs. A misread routes into dead-stream recovery instead, leaving the black
/// screen and the "playing" timeline the issue is about.
///
/// The event sequence below is exactly what `ExoPlayerCore.emitPlaybackEofOnce`
/// sends, including the timeline pin that precedes the terminal event.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const durationMs = 2623668;
  const duration = Duration(milliseconds: durationMs);

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('a synthesized end of file completes the item at its duration', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.plezy/exo_player');
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final player = _SeededPlayerAndroid();
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

    // The renderers never ended; the native side pins the timeline at the end
    // and reports the file as finished.
    player.handlePropertyChange('time-pos', durationMs / 1000.0);
    player.handlePropertyChange('paused-for-cache', false);
    player.handlePropertyChange('pause', true);
    player.handlePropertyChange('eof-reached', true);
    player.handlePlayerEvent('end-file', const {'reason': 'eof'});
    await Future<void>.delayed(Duration.zero);

    // The pin lands on the unthrottled position immediately; the 4Hz state
    // snapshot may still carry the previous tick, which is why the classifier
    // below has to hold for both.
    expect(player.currentPosition, duration);
    expect(player.state.playing, isFalse);
    expect(player.state.completed, isTrue);
    expect(completions.last, isTrue);

    // What the screen does with that state: the EOF is genuine, so the item is
    // stopped at its duration and the next episode is presented.
    expect(
      classifyEofSignal(
        positionMs: player.state.position.inMilliseconds,
        playerDurationMs: player.state.duration.inMilliseconds,
        metadataDurationMs: durationMs,
      ),
      EofSignalClass.genuine,
    );
    expect(
      completionNavigationAction(hasNext: true, adjacentStatus: QueueNavigationStatus.found),
      CompletionNavigationAction.presentNext,
    );
  });

  test('the same event from a stale mid-file position stays a dead-stream signal', () {
    // Why the terminal path publishes the end position and the position loop
    // freezes after it: media3 has already stopped the player, and an EOF
    // carrying a stale position routes into spurious-EOF recovery instead.
    expect(
      classifyEofSignal(positionMs: 1200000, playerDurationMs: durationMs, metadataDurationMs: durationMs),
      EofSignalClass.spurious,
    );
  });
}
