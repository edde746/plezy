import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/apple_tv_remote_touch_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleTvRemoteTouchService', () {
    test('a single fast flick emits exactly one swipe', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 490);
      await harness.send('move', x: 260, y: 490);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      // The flick's tail travel landed inside the repeat cooldown and must be
      // discarded: a near-stationary frame after the cooldown expires must not
      // release it as a second focus step.
      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 259, y: 490);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('sub-threshold cooldown travel plus lift drift does not fire a second swipe', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 390, y: 500);
      // 80pt tail inside the cooldown: below threshold, but banked it would
      // combine with the 70pt lift drift below to cross the 100pt threshold.
      await harness.send('move', x: 310, y: 500);

      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 240, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('a sustained drag keeps repeating after each repeat interval', () async {
      final harness = _Harness();

      await harness.send('started', x: 900, y: 500);
      await harness.send('move', x: 780, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      harness.advance(const Duration(milliseconds: 30));
      await harness.send('move', x: 700, y: 500);

      // A full fresh threshold is covered after the cooldown expires.
      harness.advance(const Duration(milliseconds: 31));
      await harness.send('move', x: 580, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);
    });

    test('uses the dominant vertical axis for swipes', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 540, y: 380);

      expect(harness.keys, [LogicalKeyboardKey.arrowUp]);
    });

    test('keeps horizontal axis through non-decisive vertical drift', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 380, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('continues horizontal swipes when drift is slightly vertical-dominant', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 260, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);
    });

    test('continues reversed horizontal swipes when drift is only slightly vertical-dominant', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 500, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]);
    });

    test('switches axis when the new direction clearly dominates the gesture', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 61));
      await harness.send('move', x: 380, y: 300);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]);
    });

    test('resets swipe axis hysteresis between touches', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);
      await harness.send('ended', x: 380, y: 500);
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 500, y: 380);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]);
    });

    test('short touch without a click event does not emit select', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('ended', x: 512, y: 504);

      expect(harness.keys, isEmpty);
    });

    test('short touch around a native directional key does not emit select', () async {
      final harness = _Harness();

      harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft));
      await harness.send('started', x: 500, y: 500);
      await harness.send('ended', x: 500, y: 500);

      expect(harness.keys, isEmpty);
    });

    test('swipe end does not also emit select', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);
      await harness.send('ended', x: 380, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('ended position past threshold opposite of the last move does not fire a reverse swipe', () async {
      final harness = _Harness();

      // User swipes left, then releases the finger. The final lift
      // position registers past the swipe threshold from the post-swipe
      // anchor in the *opposite* direction — natural finger pivot during
      // a lift. The previous implementation called _moveTouch on the
      // ended event and re-fired a stray arrowRight here.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);
      await harness.send('ended', x: 600, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('legacy click messages do not synthesize Select', () async {
      final harness = _Harness();

      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keys, isEmpty);
    });
    test('cancelled touch does not emit select on a later ended message', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('cancelled');
      await harness.send('ended', x: 500, y: 500);
      await harness.send('loc', x: 1, y: 0);

      expect(harness.keys, isEmpty);
    });

    test('a fast lift glides one extra step', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 50));
        // 120pt in 50ms = 2400pt/s at lift: past the glide velocity, below
        // the double-step velocity.
        harness.sendSync('move', x: 380, y: 500);
        harness.sendSync('ended', x: 380, y: 500);

        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

        async.elapse(const Duration(milliseconds: 70));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);

        async.elapse(const Duration(milliseconds: 300));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);
      });
    });

    test('a violent flick glides two extra steps', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        // 120pt in 8ms = 15000pt/s at lift: past the double-step velocity.
        harness.sendSync('move', x: 380, y: 500);
        harness.sendSync('ended', x: 380, y: 500);

        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

        async.elapse(const Duration(milliseconds: 140));
        expect(harness.keys, List.filled(3, LogicalKeyboardKey.arrowLeft));

        async.elapse(const Duration(milliseconds: 300));
        expect(harness.keys, List.filled(3, LogicalKeyboardKey.arrowLeft));
      });
    });

    test('a slow lift does not glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        // 100pt in 60ms = 1667pt/s at lift: below the glide velocity.
        harness.sendSync('move', x: 400, y: 500);
        harness.sendSync('ended', x: 400, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      });
    });

    test('a new touch cancels a pending glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 380, y: 500);
        harness.sendSync('ended', x: 380, y: 500);
        harness.sendSync('started', x: 500, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      });
    });

    test('a gesture that never produced a step does not glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        // Fast but sub-threshold: no step, so no established direction.
        harness.sendSync('move', x: 420, y: 500);
        harness.sendSync('ended', x: 420, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, isEmpty);
      });
    });

    test('a lift moving against the last step does not glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 50));
        harness.sendSync('move', x: 380, y: 500);

        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

        // Reversal pivot inside the cooldown: net window velocity points
        // right, against the emitted arrowLeft.
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 620, y: 500);
        harness.sendSync('ended', x: 620, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      });
    });
  });
}

class _Harness {
  _Harness();

  DateTime now = DateTime(2026, 5, 5, 12);
  final List<LogicalKeyboardKey> keys = [];

  late final AppleTvRemoteTouchService service = AppleTvRemoteTouchService(
    simulateKeyPress: keys.add,
    scheduleFrame: () {},
    now: () => now,
    swipeThreshold: 100,
  );

  Future<void> send(String type, {double x = 0, double y = 0}) {
    return service.handleMessage({'type': type, 'x': x, 'y': y});
  }

  /// Fire-and-forget variant for [fakeAsync] bodies, where awaiting would
  /// need manual microtask flushing; the handler body is synchronous.
  void sendSync(String type, {double x = 0, double y = 0}) {
    unawaited(service.handleMessage({'type': type, 'x': x, 'y': y}));
  }

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: logicalKey, timeStamp: Duration.zero);
}
