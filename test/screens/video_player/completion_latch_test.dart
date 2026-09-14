import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/completion_latch.dart';
import 'package:plezy/services/playback_initialization_types.dart';

void main() {
  CompletionLatch latch() => CompletionLatch(rearmWindowMs: 2000);

  void tick(
    CompletionLatch l,
    int positionMs, {
    int durationMs = 60000,
    bool promptVisible = false,
    bool countdownActive = false,
  }) {
    l.classifyPosition(
      positionMs: positionMs,
      durationMs: durationMs,
      promptVisible: promptVisible,
      countdownActive: countdownActive,
    );
  }

  test('position ticks never latch by themselves', () {
    final l = latch();
    tick(l, 58000);
    tick(l, 59200);
    tick(l, 60000);
    expect(l.triggered, isFalse);
  });

  test('stays latched while parked at EOF', () {
    final l = latch();
    l.latch();
    tick(l, 59400);
    expect(l.triggered, isTrue);
  });

  test('ignores ticks with no known duration', () {
    final l = latch();
    l.latch();
    tick(l, 59500, durationMs: 0);
    expect(l.triggered, isTrue);
  });

  test('re-arms only after moving back past the rearm window', () {
    final l = latch();
    l.latch();
    // Inside the rearm window: no flap.
    tick(l, 58500);
    expect(l.triggered, isTrue);
    // Clearly out of the end region: re-armed.
    tick(l, 50000);
    expect(l.triggered, isFalse);
    // Returning to the end stays quiet until the player emits EOF.
    tick(l, 59500);
    expect(l.triggered, isFalse);
  });

  test('refuses to re-arm while a prompt or countdown is active', () {
    final l = latch();
    l.latch();
    tick(l, 50000, promptVisible: true);
    expect(l.triggered, isTrue);
    tick(l, 50000, countdownActive: true);
    expect(l.triggered, isTrue);
    tick(l, 50000);
    expect(l.triggered, isFalse);
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

  group('completionNavigationAction', () {
    test('presents a resolved next item', () {
      expect(
        completionNavigationAction(hasNext: true, adjacentStatus: QueueNavigationStatus.found),
        CompletionNavigationAction.presentNext,
      );
    });

    test('retries queued movie adjacency instead of exiting after a load failure', () {
      expect(
        completionNavigationAction(hasNext: false, adjacentStatus: QueueNavigationStatus.failed),
        CompletionNavigationAction.retryAdjacent,
      );
    });

    test('exits a standalone movie after adjacency resolves unavailable', () {
      expect(
        completionNavigationAction(hasNext: false, adjacentStatus: QueueNavigationStatus.unavailable),
        CompletionNavigationAction.exit,
      );
    });

    test('exits only after the queue boundary was resolved', () {
      expect(
        completionNavigationAction(hasNext: false, adjacentStatus: QueueNavigationStatus.boundary),
        CompletionNavigationAction.exit,
      );
    });
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

  group('playNextRetryPresentation', () {
    PlayNextRetryPresentation resolve({
      bool wasAtCompletion = true,
      PlaybackFailureReason? failureReason = PlaybackFailureReason.serverUnavailable,
      bool hasNext = true,
      bool autoPlayEnabled = true,
      bool inWatchTogetherSession = false,
      int autoRetriesUsed = 0,
    }) {
      return playNextRetryPresentation(
        wasAtCompletion: wasAtCompletion,
        failureReason: failureReason,
        hasNext: hasNext,
        autoPlayEnabled: autoPlayEnabled,
        inWatchTogetherSession: inWatchTogetherSession,
        autoRetriesUsed: autoRetriesUsed,
      );
    }

    test('transient failure at EOF re-presents with a countdown', () {
      expect(resolve(), PlayNextRetryPresentation.countdown);
    });

    test('a mid-episode Next press keeps the plain failure handling', () {
      // The rolled-back stream is still valid and playing there — no prompt.
      expect(resolve(wasAtCompletion: false), PlayNextRetryPresentation.none);
    });

    test('non-transient failures never retry-loop', () {
      for (final reason in PlaybackFailureReason.values) {
        if (reason == PlaybackFailureReason.serverUnavailable) continue;
        expect(resolve(failureReason: reason), PlayNextRetryPresentation.none, reason: '$reason');
      }
      // Pre-classification throws carry no reason at all.
      expect(resolve(failureReason: null), PlayNextRetryPresentation.none);
    });

    test('no next episode means nothing to re-present', () {
      expect(resolve(hasNext: false), PlayNextRetryPresentation.none);
    });

    test('the countdown budget exhausts into a manual prompt', () {
      expect(resolve(autoRetriesUsed: maxPlayNextTransientRetries - 1), PlayNextRetryPresentation.countdown);
      expect(resolve(autoRetriesUsed: maxPlayNextTransientRetries), PlayNextRetryPresentation.manual);
    });

    test('auto-play off presents the prompt without a countdown', () {
      expect(resolve(autoPlayEnabled: false), PlayNextRetryPresentation.manual);
    });

    test('Watch Together sessions never auto-retry but keep the manual prompt', () {
      expect(resolve(inWatchTogetherSession: true), PlayNextRetryPresentation.manual);
    });
  });
}
