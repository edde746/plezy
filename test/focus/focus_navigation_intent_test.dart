import 'dart:ui' show KeyEventDeviceType;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show FocusNode;
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_navigation_intent.dart';
import 'package:plezy/utils/platform_detector.dart';

/// Executable spec for the one predicate that decides both whether the app
/// switches to keyboard mode and whether a key may hand focus to the player
/// chrome. Every row is a key the app can actually receive; the table is the
/// contract, so widening it is a deliberate edit rather than an accident.
///
/// `WidgetTester.sendKeyEvent` always reports `deviceType == keyboard`, so rows
/// that vary the device construct the event directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  KeyDownEvent down(LogicalKeyboardKey key, {KeyEventDeviceType deviceType = KeyEventDeviceType.keyboard}) {
    return KeyDownEvent(
      logicalKey: key,
      physicalKey: PhysicalKeyboardKey.f13,
      timeStamp: Duration.zero,
      deviceType: deviceType,
    );
  }

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  group('off TV', () {
    setUp(() => TvDetectionService.debugSetAppleTVOverride(false));

    final promotes = <String, KeyEvent>{
      'tab': down(LogicalKeyboardKey.tab),
      'contextMenu': down(LogicalKeyboardKey.contextMenu),
      'gameButtonX': down(LogicalKeyboardKey.gameButtonX),
      'select': down(LogicalKeyboardKey.select),
      'select reported as a keyboard device (tvOS engine shape)': down(
        LogicalKeyboardKey.select,
        deviceType: KeyEventDeviceType.keyboard,
      ),
      'gameButtonA': down(LogicalKeyboardKey.gameButtonA),
      'gameButtonB': down(LogicalKeyboardKey.gameButtonB),
      'goBack': down(LogicalKeyboardKey.goBack),
      'enter from a gamepad': down(LogicalKeyboardKey.enter, deviceType: KeyEventDeviceType.gamepad),
      'escape from a d-pad': down(LogicalKeyboardKey.escape, deviceType: KeyEventDeviceType.directionalPad),
    };

    final ignores = <String, KeyEvent>{
      'enter from a physical keyboard': down(LogicalKeyboardKey.enter),
      'numpadEnter from a physical keyboard': down(LogicalKeyboardKey.numpadEnter),
      'escape from a physical keyboard': down(LogicalKeyboardKey.escape),
      'browserBack (media keyboards emit it)': down(LogicalKeyboardKey.browserBack),
      'space': down(LogicalKeyboardKey.space),
      'a letter': down(LogicalKeyboardKey.keyF),
      'mediaPlayPause': down(LogicalKeyboardKey.mediaPlayPause),
    };

    promotes.forEach((name, event) {
      test('$name requests focus navigation', () {
        expect(eventRequestsFocusNavigation(event), isTrue);
      });
    });

    ignores.forEach((name, event) {
      test('$name does not request focus navigation', () {
        expect(eventRequestsFocusNavigation(event), isFalse);
      });
    });

    test('only key-down counts', () {
      const up = KeyUpEvent(
        logicalKey: LogicalKeyboardKey.tab,
        physicalKey: PhysicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      const repeat = KeyRepeatEvent(
        logicalKey: LogicalKeyboardKey.arrowDown,
        physicalKey: PhysicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );

      expect(eventRequestsFocusNavigation(up), isFalse);
      expect(eventRequestsFocusNavigation(repeat), isFalse);
    });
  });

  group('on TV', () {
    setUp(() => TvDetectionService.debugSetAppleTVOverride(true));

    test('a remote OK that arrives as a keyboard enter still requests navigation', () {
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.enter)), isTrue);
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.numpadEnter)), isTrue);
    });

    test('escape from a physical keyboard still only dismisses', () {
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.escape)), isFalse);
    });
  });

  group('arrows ask the focused node', () {
    setUp(() => TvDetectionService.debugSetAppleTVOverride(false));

    test('an ordinary node means arrows traverse', () {
      final node = FocusNode(debugLabel: 'plain');
      addTearDown(node.dispose);

      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowDown), focused: node), isTrue);
    });

    test('a node that owns arrows suppresses promotion', () {
      final node = DirectionalShortcutFocusNode(debugLabel: 'surface', consumesDirectionalKeys: (_) => true);
      addTearDown(node.dispose);

      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowDown), focused: node), isFalse);
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowRight), focused: node), isFalse);
    });

    test('a node can own one axis and leave the other as traversal', () {
      final node = DirectionalShortcutFocusNode(
        debugLabel: 'surface',
        consumesDirectionalKeys: (key) => key.isLeftKey || key.isRightKey,
      );
      addTearDown(node.dispose);

      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowLeft), focused: node), isFalse);
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowUp), focused: node), isTrue);
    });

    test('a node that has stopped owning arrows lets them traverse again', () {
      var owns = true;
      final node = DirectionalShortcutFocusNode(debugLabel: 'surface', consumesDirectionalKeys: (_) => owns);
      addTearDown(node.dispose);

      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowDown), focused: node), isFalse);
      owns = false;
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.arrowDown), focused: node), isTrue);
    });

    test('select is unaffected by who owns arrows', () {
      final node = DirectionalShortcutFocusNode(debugLabel: 'surface', consumesDirectionalKeys: (_) => true);
      addTearDown(node.dispose);

      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.select), focused: node), isTrue);
      expect(eventRequestsFocusNavigation(down(LogicalKeyboardKey.enter), focused: node), isFalse);
    });
  });
}
