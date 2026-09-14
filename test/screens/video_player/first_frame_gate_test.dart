import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/first_frame_gate.dart';

void main() {
  group('FirstFrameGate', () {
    test('markReady latches both reporting and UI readiness', () {
      final gate = FirstFrameGate();
      addTearDown(gate.dispose);

      gate.markReady();

      expect(gate.rendered, isTrue);
      expect(gate.uiReady.value, isTrue);
    });

    test('forceUiReadyOnFailure hides the spinner without latching rendered', () {
      final gate = FirstFrameGate();
      addTearDown(gate.dispose);

      gate.forceUiReadyOnFailure();

      expect(gate.uiReady.value, isTrue, reason: 'spinner must hide on a current startup failure');
      expect(gate.rendered, isFalse, reason: 'reporting readiness is stricter than UI readiness');
    });

    test('resetUiForOpen leaves the reporting latch untouched', () {
      final gate = FirstFrameGate()..markReady();
      addTearDown(gate.dispose);

      gate.resetUiForOpen();

      expect(gate.uiReady.value, isFalse);
      expect(gate.rendered, isTrue);
    });

    test('resetRenderedForAttempt leaves UI readiness untouched', () {
      final gate = FirstFrameGate()..markReady();
      addTearDown(gate.dispose);

      gate.resetRenderedForAttempt();

      expect(gate.rendered, isFalse);
      expect(gate.uiReady.value, isTrue);
    });

    test('reset clears both flags', () {
      final gate = FirstFrameGate()..markReady();
      addTearDown(gate.dispose);

      gate.reset();

      expect(gate.rendered, isFalse);
      expect(gate.uiReady.value, isFalse);
    });

    test('snapshot/restore round-trips a diverged state across a failed replacement', () {
      final gate = FirstFrameGate()..forceUiReadyOnFailure();
      addTearDown(gate.dispose);

      final snapshot = gate.snapshot();
      gate.reset();
      gate.restore(snapshot);

      expect(gate.uiReady.value, isTrue);
      expect(gate.rendered, isFalse);
    });

    test('uiReady keeps its identity so listeners survive resets', () {
      final gate = FirstFrameGate();
      addTearDown(gate.dispose);

      final notifier = gate.uiReady;
      var notifications = 0;
      notifier.addListener(() => notifications++);

      gate.markReady();
      gate.reset();
      gate.restore((uiReady: true, rendered: true));

      expect(identical(notifier, gate.uiReady), isTrue);
      expect(notifications, 3);
    });
  });
}
