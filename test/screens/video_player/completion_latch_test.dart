import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/screens/video_player/completion_latch.dart';

void main() {
  CompletionLatch latch() => CompletionLatch(triggerWindowMs: 1000, rearmWindowMs: 2000);

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

  test('signals completed once inside the trigger window, then stays quiet while latched', () {
    final l = latch();
    expect(tick(l, 58000), CompletionLatchSignal.none);
    expect(tick(l, 59200), CompletionLatchSignal.completed);
    // The handler latches on success; until then ticks keep retrying.
    expect(tick(l, 59300), CompletionLatchSignal.completed);
    l.latch();
    expect(tick(l, 59400), CompletionLatchSignal.none);
  });

  test('does not fire while a prompt is visible', () {
    final l = latch();
    expect(tick(l, 59500, promptVisible: true), CompletionLatchSignal.none);
  });

  test('ignores ticks with no known duration', () {
    final l = latch();
    expect(tick(l, 59500, durationMs: 0), CompletionLatchSignal.none);
  });

  test('re-arms only after moving back past the rearm window', () {
    final l = latch();
    l.latch();
    // Inside the hysteresis gap (between trigger and rearm windows): no flap.
    expect(tick(l, 58500), CompletionLatchSignal.none);
    expect(l.triggered, isTrue);
    // Clearly out of the end region: re-armed.
    expect(tick(l, 50000), CompletionLatchSignal.rearmed);
    expect(l.triggered, isFalse);
    // Returning to the end can fire again.
    expect(tick(l, 59500), CompletionLatchSignal.completed);
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
}
