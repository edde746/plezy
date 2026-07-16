import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/services/current_playback_dispatcher.dart';

void main() {
  group('CurrentPlaybackDispatcher', () {
    test('success marks the key handled and suppresses re-dispatch', () async {
      final d = CurrentPlaybackDispatcher();
      expect(d.shouldDispatch('a'), isTrue);

      await d.dispatch('a', () async => true);
      expect(d.shouldDispatch('a'), isFalse); // Handled.
      expect(d.shouldDispatch('b'), isTrue); // Other keys unaffected.
    });

    test('failure frees the slot without marking handled (heartbeat retry)', () async {
      final d = CurrentPlaybackDispatcher();
      await d.dispatch('a', () async => false);
      expect(d.inFlightKey, isNull);
      expect(d.shouldDispatch('a'), isTrue); // Retryable.
    });

    test('a throwing callback is a failure, not an unhandled error', () async {
      final d = CurrentPlaybackDispatcher();
      await expectLater(d.dispatch('a', () async => throw StateError('boom')), completes);
      expect(d.shouldDispatch('a'), isTrue);
    });

    test('serializes: nothing dispatches while a key is in flight', () async {
      final d = CurrentPlaybackDispatcher();
      final gate = Completer<bool>();
      final dispatch = d.dispatch('a', () => gate.future);

      // The slot is claimed synchronously, before the first await.
      expect(d.inFlightKey, 'a');
      expect(d.shouldDispatch('a'), isFalse);
      expect(d.shouldDispatch('b'), isFalse);

      gate.complete(true);
      await dispatch;
      expect(d.inFlightKey, isNull);
      expect(d.shouldDispatch('b'), isTrue);
    });

    test('a hung callback times out as a failure and frees the slot', () {
      fakeAsync((async) {
        final d = CurrentPlaybackDispatcher();
        final never = Completer<bool>();
        unawaited(d.dispatch('a', () => never.future));

        async.elapse(CurrentPlaybackDispatcher.dispatchTimeout - const Duration(seconds: 1));
        expect(d.inFlightKey, 'a');

        async.elapse(const Duration(seconds: 2));
        expect(d.inFlightKey, isNull);
        expect(d.shouldDispatch('a'), isTrue); // Timed out ⇒ unhandled.

        // A late success from the original callback changes nothing.
        never.complete(true);
        async.flushMicrotasks();
        expect(d.shouldDispatch('a'), isTrue);
      });
    });

    test('reset() mid-flight discards the stale completion', () async {
      final d = CurrentPlaybackDispatcher();
      final gateA = Completer<bool>();
      final dispatchA = d.dispatch('a', () => gateA.future);

      d.reset(); // Host exited / session left.
      expect(d.inFlightKey, isNull);

      // A newer dispatch claims the slot under the new generation.
      final gateB = Completer<bool>();
      final dispatchB = d.dispatch('b', () => gateB.future);

      // The stale completion must neither mark 'a' handled nor free 'b'.
      gateA.complete(true);
      await dispatchA;
      expect(d.shouldDispatch('a'), isFalse); // 'b' still occupies the slot...
      expect(d.inFlightKey, 'b'); // ...untouched by the stale completion.

      gateB.complete(true);
      await dispatchB;
      expect(d.shouldDispatch('a'), isTrue); // 'a' was never marked handled.
      expect(d.shouldDispatch('b'), isFalse);
    });

    test('markHandled suppresses a key without a dispatch (user-initiated join)', () {
      final d = CurrentPlaybackDispatcher();
      d.markHandled('a');
      expect(d.shouldDispatch('a'), isFalse);
      expect(d.shouldDispatch('b'), isTrue);
    });

    test('null keys never dispatch', () {
      final d = CurrentPlaybackDispatcher();
      expect(d.shouldDispatch(null), isFalse);
    });
  });
}
