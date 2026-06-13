import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/services/apple_tv_remote_touch_service.dart';

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

    test('click events emit held select key down and up', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('ended', x: 500, y: 500);
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, [LogicalKeyboardKey.enter]);
      expect(harness.keyUps, [LogicalKeyboardKey.enter]);

      harness.advance(const Duration(milliseconds: 121));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, [LogicalKeyboardKey.enter, LogicalKeyboardKey.enter]);
      expect(harness.keyUps, [LogicalKeyboardKey.enter, LogicalKeyboardKey.enter]);
    });

    test('native select suppresses click fallback from physical remote path', () async {
      final harness = _Harness();

      harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.select));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, isEmpty);
      expect(harness.keyUps, isEmpty);

      harness.service.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.select));
      harness.advance(const Duration(milliseconds: 121));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, [LogicalKeyboardKey.enter]);
      expect(harness.keyUps, [LogicalKeyboardKey.enter]);
    });

    test('native select during click fallback is consumed and releases synthetic select', () async {
      final harness = _Harness();

      await harness.send('click_s');

      expect(harness.keyDowns, [LogicalKeyboardKey.enter]);
      expect(harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.enter)), isTrue);
      expect(harness.keyUps, isEmpty);

      expect(harness.service.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.enter)), isTrue);

      expect(harness.keyUps, [LogicalKeyboardKey.enter]);

      await harness.send('click_e');

      expect(harness.keyUps, [LogicalKeyboardKey.enter]);
    });

    test('native select burst consumes duplicate native pairs', () async {
      final harness = _Harness();

      expect(harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.select)), isFalse);
      expect(harness.service.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.select)), isFalse);

      expect(harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.select)), isTrue);
      expect(harness.service.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.select)), isTrue);

      harness.advance(const Duration(milliseconds: 121));

      expect(harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.select)), isFalse);
      expect(harness.service.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.select)), isFalse);
    });

    test('raw native enter suppresses click fallback from tvOS engine path', () async {
      final harness = _Harness();

      harness.service.handleNativeKeyEvent(_keyDown(_rawEnterKey));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, isEmpty);
      expect(harness.keyUps, isEmpty);
    });

    test('recent directional input suppresses click fallback', () async {
      final harness = _Harness();

      harness.service.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, isEmpty);
      expect(harness.keyUps, isEmpty);

      harness.advance(const Duration(milliseconds: 221));
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keyDowns, [LogicalKeyboardKey.enter]);
      expect(harness.keyUps, [LogicalKeyboardKey.enter]);
    });

    test('synthetic swipe suppresses click fallback', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('move', x: 380, y: 500);
      await harness.send('click_s');
      await harness.send('click_e');

      expect(harness.keys, [LogicalKeyboardKey.arrowLeft]);
      expect(harness.keyDowns, isEmpty);
      expect(harness.keyUps, isEmpty);
    });

    test('cancelled touch does not emit select on a later ended message', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      await harness.send('cancelled');
      await harness.send('ended', x: 500, y: 500);
      await harness.send('loc', x: 1, y: 0);

      expect(harness.keys, isEmpty);
    });

    test('isTouchActive and listenable track touch start and end', () async {
      final harness = _Harness();
      final seen = <bool>[];
      harness.service.touchActiveListenable.addListener(() => seen.add(harness.service.isTouchActive));

      expect(harness.service.isTouchActive, isFalse);

      await harness.send('started', x: 500, y: 500);
      expect(harness.service.isTouchActive, isTrue);

      await harness.send('ended', x: 500, y: 500);
      expect(harness.service.isTouchActive, isFalse);

      expect(seen, [true, false]);
    });

    test('cancelled touch clears touch-active state', () async {
      final harness = _Harness();

      await harness.send('started', x: 500, y: 500);
      expect(harness.service.isTouchActive, isTrue);

      await harness.send('cancelled');
      expect(harness.service.isTouchActive, isFalse);
    });
  });
}

class _Harness {
  DateTime now = DateTime(2026, 5, 5, 12);
  final List<LogicalKeyboardKey> keys = [];
  final List<LogicalKeyboardKey> keyDowns = [];
  final List<LogicalKeyboardKey> keyUps = [];

  late final AppleTvRemoteTouchService service = AppleTvRemoteTouchService(
    simulateKeyPress: keys.add,
    simulateKeyDown: keyDowns.add,
    simulateKeyUp: keyUps.add,
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

const _rawEnterKey = LogicalKeyboardKey(0x0d);

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: logicalKey, timeStamp: Duration.zero);
}

KeyUpEvent _keyUp(LogicalKeyboardKey logicalKey) {
  return KeyUpEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: logicalKey, timeStamp: Duration.zero);
}
