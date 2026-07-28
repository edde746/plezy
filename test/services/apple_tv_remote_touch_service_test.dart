import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/apple_tv_remote_touch_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleTvRemoteTouchService', () {
    test('emits repeated horizontal swipes only after the repeat interval', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 490);
      await harness.send('move', x: 260, y: 490);

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);

      harness.advance(const Duration(milliseconds: 141));
      await harness.send('move', x: 260, y: 490);

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
  });
}

class _Harness {
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

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: logicalKey, timeStamp: Duration.zero);
}
