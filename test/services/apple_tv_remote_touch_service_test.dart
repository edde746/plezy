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
      harness.advance(const Duration(milliseconds: 141));
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

      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 240, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('a sustained drag keeps repeating after each repeat interval', () async {
      final harness = _Harness();

      await harness.send('started', x: 900, y: 500);
      await harness.send('move', x: 780, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      harness.advance(const Duration(milliseconds: 70));
      await harness.send('move', x: 700, y: 500);

      // A full fresh threshold is covered after the cooldown expires.
      harness.advance(const Duration(milliseconds: 71));
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

      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 380, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('continues horizontal swipes when drift is slightly vertical-dominant', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 260, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);
    });

    test('continues reversed horizontal swipes when drift is only slightly vertical-dominant', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 500, y: 370);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]);
    });

    test('switches axis when the new direction clearly dominates the gesture', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      harness.advance(const Duration(milliseconds: 141));
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

    test('a small focused item lowers the swipe distance for a step', () async {
      final harness = _Harness(minSwipeThreshold: 40);
      harness.focusRect = const Rect.fromLTWH(0, 0, 60, 60);

      // 60pt extent × 0.55 gain = 33pt, min-clamped to the 40pt floor: fires
      // well below the 100pt fallback threshold.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 430, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('a large focused item demands a longer swipe for a step', () async {
      final harness = _Harness();
      harness.focusRect = const Rect.fromLTWH(0, 0, 300, 300);

      // 300pt extent × 0.55 gain = 165pt step: the fallback-sized 120pt move
      // that used to fire must not.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);

      expect(harness.keys, isEmpty);

      await harness.send('move', x: 160, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('the swipe distance is capped for oversized focused items', () async {
      final harness = _Harness();
      harness.focusRect = const Rect.fromLTWH(0, 0, 3000, 3000);

      await harness.send('started', x: 900, y: 500);
      await harness.send('move', x: 530, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
    });

    test('per-axis thresholds follow the focused item shape', () async {
      final harness = _Harness();
      harness.focusRect = const Rect.fromLTWH(0, 0, 300, 100);

      // Raw horizontal delta (200pt) dominates vertical (130pt), but only the
      // vertical axis crossed its threshold (55pt vs 165pt): the step must
      // go down, like dragging focus off a wide-flat tile natively.
      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 300, y: 630);

      expect(harness.keys, [LogicalKeyboardKey.arrowDown]);
    });

    test('a focus hop re-prices the next step from the new item', () async {
      final harness = _Harness(minSwipeThreshold: 40);
      harness.focusRect = const Rect.fromLTWH(0, 0, 60, 60);

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 430, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      // Focus landed on a large card: the next step costs its extent, not the
      // small chip's.
      harness.focusRect = const Rect.fromLTWH(0, 0, 300, 300);
      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 310, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      await harness.send('move', x: 95, y: 500);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft]);
    });
  });
}

class _Harness {
  _Harness({this.minSwipeThreshold = AppleTvRemoteTouchService.defaultMinSwipeThreshold});

  DateTime now = DateTime(2026, 5, 5, 12);
  final List<LogicalKeyboardKey> keys = [];
  final double minSwipeThreshold;

  /// Fake focus geometry; null exercises the fixed-threshold fallback.
  Rect? focusRect;

  late final AppleTvRemoteTouchService service = AppleTvRemoteTouchService(
    simulateKeyPress: keys.add,
    scheduleFrame: () {},
    now: () => now,
    swipeThreshold: 100,
    minSwipeThreshold: minSwipeThreshold,
    focusedItemRect: () => focusRect,
  );

  Future<void> send(String type, {double x = 0, double y = 0}) {
    return service.handleMessage({'type': type, 'x': x, 'y': y});
  }

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: logicalKey, timeStamp: Duration.zero);
}
