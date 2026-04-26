import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/gamepad_service.dart';

void main() {
  group('GamepadDuplicateInputGuard', () {
    late DateTime now;
    late GamepadDuplicateInputGuard guard;

    setUp(() {
      now = DateTime(2026, 4, 26, 12);
      guard = GamepadDuplicateInputGuard(now: () => now, suppressionWindow: const Duration(milliseconds: 100));
    });

    test('suppresses a matching D-pad event after a native arrow key', () {
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.arrowRight));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.arrowRight), isTrue);
    });

    test('does not suppress D-pad input when no native key was seen', () {
      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.arrowRight), isFalse);
    });

    test('suppresses gamepad A while native enter is down and just after release', () {
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.enter));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.enter), isTrue);

      guard.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.enter));
      now = now.add(const Duration(milliseconds: 50));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.enter), isTrue);
    });

    test('suppression expires after the debounce window', () {
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.arrowRight));
      guard.handleNativeKeyEvent(_keyUp(LogicalKeyboardKey.arrowRight));

      now = now.add(const Duration(milliseconds: 101));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.arrowRight), isFalse);
    });

    test('unrelated native keys do not suppress controller input', () {
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.space));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.arrowRight), isFalse);
      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.enter), isFalse);
    });

    test('uses aliases for Steam Input mapped context menu and back keys', () {
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.contextMenu));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.gameButtonX), isTrue);

      guard.clear();
      guard.handleNativeKeyEvent(_keyDown(LogicalKeyboardKey.browserBack));

      expect(guard.shouldSuppressSyntheticKey(LogicalKeyboardKey.escape), isTrue);
    });
  });
}

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(
    physicalKey: _physicalKeyFor(logicalKey),
    logicalKey: logicalKey,
    timeStamp: const Duration(milliseconds: 1),
  );
}

KeyUpEvent _keyUp(LogicalKeyboardKey logicalKey) {
  return KeyUpEvent(
    physicalKey: _physicalKeyFor(logicalKey),
    logicalKey: logicalKey,
    timeStamp: const Duration(milliseconds: 1),
  );
}

PhysicalKeyboardKey _physicalKeyFor(LogicalKeyboardKey logicalKey) {
  if (logicalKey == LogicalKeyboardKey.arrowRight) return PhysicalKeyboardKey.arrowRight;
  if (logicalKey == LogicalKeyboardKey.enter) return PhysicalKeyboardKey.enter;
  if (logicalKey == LogicalKeyboardKey.space) return PhysicalKeyboardKey.space;
  if (logicalKey == LogicalKeyboardKey.contextMenu) return PhysicalKeyboardKey.contextMenu;
  if (logicalKey == LogicalKeyboardKey.browserBack) return PhysicalKeyboardKey.browserBack;
  return PhysicalKeyboardKey.enter;
}
