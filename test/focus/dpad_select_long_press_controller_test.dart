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

void main() {
  tearDown(SelectKeyUpSuppressor.clearSuppression);

  test('initial down starts once and down/repeat events do not restart it', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var shortPresses = 0;
      var longPresses = 0;

      KeyEventResult handle(KeyEvent event) => controller.handleKeyEvent(
        event,
        isOwnerActive: () => true,
        onShortPress: () => shortPresses++,
        onLongPress: () => longPresses++,
      );

      expect(handle(_down), KeyEventResult.handled);
      async.elapse(const Duration(milliseconds: 400));
      expect(handle(_secondDown), KeyEventResult.handled);
      expect(handle(_repeat), KeyEventResult.handled);
      expect(shortPresses, 0);
      expect(longPresses, 0);

      async.elapse(const Duration(milliseconds: 100));
      expect(longPresses, 1);
      expect(shortPresses, 0);
      expect(handle(_up), KeyEventResult.handled);
      expect(shortPresses, 0);
    });
  });

  test('key up before the deadline fires one short press and cancels long press', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var shortPresses = 0;
      var longPresses = 0;

      controller.handleKeyEvent(
        _down,
        isOwnerActive: () => true,
        onShortPress: () => shortPresses++,
        onLongPress: () => longPresses++,
      );
      async.elapse(const Duration(milliseconds: 450));
      expect(
        controller.handleKeyEvent(
          _up,
          isOwnerActive: () => true,
          onShortPress: () => shortPresses++,
          onLongPress: () => longPresses++,
        ),
        KeyEventResult.handled,
      );
      async.elapse(const Duration(seconds: 1));

      expect(shortPresses, 1);
      expect(longPresses, 0);
    });
  });

  test('focus-loss reset cancels a pending press and clears key-down state', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var shortPresses = 0;
      var longPresses = 0;

      void handle(KeyEvent event) => controller.handleKeyEvent(
        event,
        isOwnerActive: () => true,
        onShortPress: () => shortPresses++,
        onLongPress: () => longPresses++,
      );

      handle(_down);
      controller.reset();
      async.elapse(const Duration(seconds: 1));
      handle(_up);

      expect(shortPresses, 0);
      expect(longPresses, 0);

      handle(_down);
      async.elapse(DpadSelectLongPressController.defaultDuration);
      expect(longPresses, 1);
    });
  });

  test('disposal cancels the timer and prevents later key-up activation', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var shortPresses = 0;
      var longPresses = 0;

      void handle(KeyEvent event) => controller.handleKeyEvent(
        event,
        isOwnerActive: () => true,
        onShortPress: () => shortPresses++,
        onLongPress: () => longPresses++,
      );

      handle(_down);
      controller.dispose();
      async.elapse(const Duration(seconds: 1));
      handle(_up);

      expect(shortPresses, 0);
      expect(longPresses, 0);
    });
  });
}
