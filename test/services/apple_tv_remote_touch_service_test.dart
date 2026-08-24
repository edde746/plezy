import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_navigation_intent.dart';
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

    test('prices a step by the focused item extent plus the travel margin', () async {
      final harness = _Harness()..focusedRect = const Rect.fromLTWH(0, 0, 245, 10);

      // Horizontal: 245pt extent + 155pt margin = 400pt per step.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 101, y: 500);
      expect(harness.keys, isEmpty);
      await harness.send('move', x: 100, y: 500);
      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      // Vertical: 10pt extent prices at the 200pt floor, not at 165pt.
      harness.advance(const Duration(milliseconds: 61));
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 500, y: 301);
      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      await harness.send('move', x: 500, y: 300);
      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]);
    });

    test('a wide-flat control steps vertically once the finger covers its height', () async {
      final harness = _Harness()..focusedRect = const Rect.fromLTWH(0, 0, 900, 45);

      // Width prices at the 700pt cap; height at 45+155 = 200pt. A larger raw
      // horizontal delta still resolves vertical because axis progress is
      // normalized by the per-axis thresholds, like the native engine.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 250, y: 290);
      expect(harness.keys, [LogicalKeyboardKey.arrowUp]);
    });

    testWidgets('a locked-focus row prices by its selected item, not its row-wide node', (tester) async {
      final node = LockedFocusRowNode(debugLabel: 'row', focusedItemRect: () => const Rect.fromLTWH(0, 0, 245, 345));
      addTearDown(node.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(focusNode: node, child: const SizedBox(width: 1700, height: 400)),
        ),
      );
      node.requestFocus();
      await tester.pump();

      final keys = <LogicalKeyboardKey>[];
      // No injected geometry: exercises the default primary-focus resolution,
      // which must consult the node's item rect (245+155 = 400pt per step)
      // instead of its 1700pt-wide row rect (the 700pt travel cap).
      final service = AppleTvRemoteTouchService(simulateKeyPress: keys.add, scheduleFrame: () {});
      await service.handleMessage({'type': 'started', 'x': 500.0, 'y': 500.0});
      await service.handleMessage({'type': 'move', 'x': 101.0, 'y': 500.0});
      expect(keys, isEmpty);
      await service.handleMessage({'type': 'move', 'x': 100.0, 'y': 500.0});
      expect(keys, [LogicalKeyboardKey.arrowLeft]);
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

    test('a fast single-step flick does not glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        // 120pt in 8ms = 15000pt/s: far past both glide velocities, but the
        // gesture emitted only one step. Ungated, every deliberate single
        // swipe glided into a second step (issue #2006).
        harness.sendSync('move', x: 380, y: 500);
        harness.sendSync('ended', x: 380, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      });
    });

    test('a fast lift after a sustained drag glides one extra step', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 50));
        harness.sendSync('move', x: 380, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 260, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        // 120pt in the last 8ms: ~3500pt/s over the velocity window — past
        // the glide velocity, below the double-step velocity.
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 140, y: 500);
        harness.sendSync('ended', x: 140, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        async.elapse(const Duration(milliseconds: 70));
        expect(harness.keys, List.filled(3, LogicalKeyboardKey.arrowLeft));

        async.elapse(const Duration(milliseconds: 300));
        expect(harness.keys, List.filled(3, LogicalKeyboardKey.arrowLeft));
      });
    });

    test('a violent lift after a sustained drag still glides only one extra step', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 1));
        harness.sendSync('move', x: 380, y: 500);
        harness.advance(const Duration(milliseconds: 61));
        harness.sendSync('move', x: 260, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        // The drag steps age out of the velocity window; the final
        // sub-threshold segment covers 64pt in 5ms = 12800pt/s. The native
        // engine never coasts more than one step no matter how violent the
        // lift (FocusProbe capture: 101 sessions, lifts up to ~11400pt/s,
        // never a second coast step).
        harness.advance(const Duration(milliseconds: 103));
        harness.sendSync('move', x: 244, y: 500);
        harness.advance(const Duration(milliseconds: 5));
        harness.sendSync('move', x: 180, y: 500);
        harness.sendSync('ended', x: 180, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, List.filled(3, LogicalKeyboardKey.arrowLeft));
      });
    });

    test('a slow lift after a sustained drag does not glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 400, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 300, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        // Sub-threshold 90pt in 60ms = 1500pt/s at lift: the drag satisfies
        // the glide gate, but the lift stays below the glide velocity.
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 210, y: 500);
        harness.sendSync('ended', x: 210, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));
      });
    });

    test('a new touch cancels a pending glide', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 50));
        harness.sendSync('move', x: 380, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 260, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 140, y: 500);
        harness.sendSync('ended', x: 140, y: 500);
        harness.sendSync('started', x: 500, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));
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
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 260, y: 500);

        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));

        // Reversal pivot inside the cooldown: net window velocity points
        // right, against the emitted arrowLeft.
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 500, y: 500);
        harness.sendSync('ended', x: 500, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, List.filled(2, LogicalKeyboardKey.arrowLeft));
      });
    });

    test('a direction reversal resets the glide gate', () {
      fakeAsync((async) {
        final harness = _Harness();

        harness.sendSync('started', x: 500, y: 500);
        harness.advance(const Duration(milliseconds: 50));
        harness.sendSync('move', x: 380, y: 500);
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 260, y: 500);
        // Reverse: one fast rightward step, then a fast rightward lift. The
        // gesture emitted three steps, but only one in the lift direction,
        // so a correction never glides past its target.
        harness.advance(const Duration(milliseconds: 60));
        harness.sendSync('move', x: 380, y: 500);
        harness.advance(const Duration(milliseconds: 8));
        harness.sendSync('move', x: 500, y: 500);
        harness.sendSync('ended', x: 500, y: 500);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.keys, [
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
        ]);
      });
    });
  });
}

class _Harness {
  _Harness();

  DateTime now = DateTime(2026, 5, 5, 12);
  Rect? focusedRect;
  final List<LogicalKeyboardKey> keys = [];

  late final AppleTvRemoteTouchService service = AppleTvRemoteTouchService(
    simulateKeyPress: keys.add,
    scheduleFrame: () {},
    now: () => now,
    swipeThreshold: 100,
    focusedItemRect: () => focusedRect,
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
