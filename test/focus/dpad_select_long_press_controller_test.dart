import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/dpad_select_long_press_controller.dart';

const _down = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration.zero,
);
const _secondDown = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration(milliseconds: 400),
);
const _repeat = KeyRepeatEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration(milliseconds: 400),
);
const _up = KeyUpEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration(milliseconds: 450),
);

/// One controller plus the presses it reported. Each scenario keeps its own
/// event order and elapsed intervals at the call site; only the counters and
/// the always-active owner wiring are shared.
class _PressRecorder {
  final controller = DpadSelectLongPressController();
  int shortPresses = 0;
  int longPresses = 0;

  KeyEventResult handle(KeyEvent event) => controller.handleKeyEvent(
    event,
    isOwnerActive: () => true,
    onShortPress: () => shortPresses++,
    onLongPress: () => longPresses++,
  );
}

void main() {
  // Long-press fire arms SelectKeyUpSuppressor, whose hardware observer
  // registers on HardwareKeyboard.instance - that needs a live binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SelectKeyUpSuppressor.clearSuppression);

  test('initial down starts once and down/repeat events do not restart it', () {
    fakeAsync((async) {
      final presses = _PressRecorder();

      expect(presses.handle(_down), KeyEventResult.handled);
      async.elapse(const Duration(milliseconds: 400));
      expect(presses.handle(_secondDown), KeyEventResult.handled);
      expect(presses.handle(_repeat), KeyEventResult.handled);
      expect(presses.shortPresses, 0);
      expect(presses.longPresses, 0);

      async.elapse(const Duration(milliseconds: 100));
      expect(presses.longPresses, 1);
      expect(presses.shortPresses, 0);
      expect(presses.handle(_up), KeyEventResult.handled);
      expect(presses.shortPresses, 0);
    });
  });

  test('key up before the deadline fires one short press and cancels long press', () {
    fakeAsync((async) {
      final presses = _PressRecorder();

      presses.handle(_down);
      async.elapse(const Duration(milliseconds: 450));
      expect(presses.handle(_up), KeyEventResult.handled);
      async.elapse(const Duration(seconds: 1));

      expect(presses.shortPresses, 1);
      expect(presses.longPresses, 0);
    });
  });

  test('focus-loss reset cancels a pending press and clears key-down state', () {
    fakeAsync((async) {
      final presses = _PressRecorder();

      presses.handle(_down);
      presses.controller.reset();
      async.elapse(const Duration(seconds: 1));
      presses.handle(_up);

      expect(presses.shortPresses, 0);
      expect(presses.longPresses, 0);

      presses.handle(_down);
      async.elapse(DpadSelectLongPressController.defaultDuration);
      expect(presses.longPresses, 1);
    });
  });

  test('disposal cancels the timer and prevents later key-up activation', () {
    fakeAsync((async) {
      final presses = _PressRecorder();

      presses.handle(_down);
      presses.controller.dispose();
      async.elapse(const Duration(seconds: 1));
      presses.handle(_up);

      expect(presses.shortPresses, 0);
      expect(presses.longPresses, 0);
    });
  });
}
