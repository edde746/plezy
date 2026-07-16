import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/completion_latch.dart';

void main() {
  CompletionLatch latch() => CompletionLatch(rearmWindowMs: 2000);

  CompletionLatchSignal tick(
    CompletionLatch l,
    int positionMs, {
    int durationMs = 60000,
    bool promptVisible = false,
    bool countdownActive = false,
  }) {
    return l.classifyPosition(
      positionMs: positionMs,
      durationMs: durationMs,
      promptVisible: promptVisible,
      countdownActive: countdownActive,
    );
  }

  test('position ticks near the end do not signal completion', () {
    final l = latch();
    expect(tick(l, 58000), CompletionLatchSignal.none);
    expect(tick(l, 59200), CompletionLatchSignal.none);
    expect(tick(l, 60000), CompletionLatchSignal.none);
  });

  test('stays quiet while latched at EOF', () {
    final l = latch();
    l.latch();
    expect(tick(l, 59400), CompletionLatchSignal.none);
    expect(l.triggered, isTrue);
  });

  test('ignores ticks with no known duration', () {
    final l = latch();
    expect(tick(l, 59500, durationMs: 0), CompletionLatchSignal.none);
  });

  test('re-arms only after moving back past the rearm window', () {
    final l = latch();
    l.latch();
    // Inside the rearm window: no flap.
    expect(tick(l, 58500), CompletionLatchSignal.none);
    expect(l.triggered, isTrue);
    // Clearly out of the end region: re-armed.
    expect(tick(l, 50000), CompletionLatchSignal.rearmed);
    expect(l.triggered, isFalse);
    // Returning to the end stays quiet until the player emits EOF.
    expect(tick(l, 59500), CompletionLatchSignal.none);
  });

  test('refuses to re-arm while a prompt or countdown is active', () {
    final l = latch();
    l.latch();
    expect(tick(l, 50000, promptVisible: true), CompletionLatchSignal.none);
    expect(l.triggered, isTrue);
    expect(tick(l, 50000, countdownActive: true), CompletionLatchSignal.none);
    expect(l.triggered, isTrue);
    expect(tick(l, 50000), CompletionLatchSignal.rearmed);
  });

  test('reset clears unconditionally', () {
    final l = latch();
    l.latch();
    l.reset();
    expect(l.triggered, isFalse);
  });

  test('rearmIfClear honors prompt/countdown directly', () {
    final l = latch();
    l.latch();
    l.rearmIfClear(promptVisible: true, countdownActive: false);
    expect(l.triggered, isTrue);
    l.rearmIfClear(promptVisible: false, countdownActive: false);
    expect(l.triggered, isFalse);
  });

  group('classifyEofSignal', () {
    EofSignalClass classify(int positionMs, {int playerDurationMs = 0, int? metadataDurationMs}) => classifyEofSignal(
      positionMs: positionMs,
      playerDurationMs: playerDurationMs,
      metadataDurationMs: metadataDurationMs,
    );

    test('mid-file EOF is spurious (#1520)', () {
      expect(classify(600000, playerDurationMs: 2520000, metadataDurationMs: 2520000), EofSignalClass.spurious);
    });

    test('metadata anchors when player duration tracks the demuxer cache', () {
      // Chunked transcode: mpv's duration equals the parked position, which
      // alone would make the dead stream look genuinely finished.
      expect(classify(600000, playerDurationMs: 600000, metadataDurationMs: 2520000), EofSignalClass.spurious);
    });

    test('genuine at the exact end', () {
      expect(classify(2520000, playerDurationMs: 2520000, metadataDurationMs: 2520000), EofSignalClass.genuine);
    });

    test('genuine when the stream ends slightly short of metadata duration', () {
      expect(classify(2517000, playerDurationMs: 2517000, metadataDurationMs: 2520000), EofSignalClass.genuine);
    });

    test('player duration wins when metadata understates the file', () {
      // The 3b611a1e failure mode: a short metadata duration must not turn
      // the real end of a longer file into a spurious classification.
      expect(classify(2520000, playerDurationMs: 2520000, metadataDurationMs: 2400000), EofSignalClass.genuine);
    });

    test('classifies from metadata alone when player duration is unknown', () {
      expect(classify(600000, metadataDurationMs: 2520000), EofSignalClass.spurious);
      expect(classify(2515000, metadataDurationMs: 2520000), EofSignalClass.genuine);
    });

    test('unknown when no duration is available', () {
      expect(classify(600000), EofSignalClass.unknown);
      expect(classify(600000, metadataDurationMs: 0), EofSignalClass.unknown);
    });

    test('tolerance boundary is inclusive', () {
      expect(
        classify(2520000 - spuriousEofToleranceMs, playerDurationMs: 2520000, metadataDurationMs: null),
        EofSignalClass.genuine,
      );
      expect(
        classify(2520000 - spuriousEofToleranceMs - 1, playerDurationMs: 2520000, metadataDurationMs: null),
        EofSignalClass.spurious,
      );
    });
  });
}
