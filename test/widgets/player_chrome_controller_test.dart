import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';

void main() {
  group('PlayerChromeController', () {
    testWidgets('auto-hides visible controls while playing', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 100));
      controller.setPlaying(true);

      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 99));
      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.controlsVisible, isFalse);
    });

    testWidgets('visible holds suppress auto-hide until released', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 100));
      controller.setPlaying(true);
      controller.hold(PlayerChromeHold.promptInteraction);

      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.controlsVisible, isTrue);

      controller.release(PlayerChromeHold.promptInteraction);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.controlsVisible, isFalse);
    });

    testWidgets('releasing a hold while paused restarts paused auto-hide', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 100));
      controller.setPlaying(true);
      controller.setPlaying(false);
      controller.hold(PlayerChromeHold.promptInteraction);

      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.controlsVisible, isTrue);

      controller.release(PlayerChromeHold.promptInteraction);
      await tester.pump(const Duration(milliseconds: 99));
      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.controlsVisible, isFalse);
    });

    testWidgets('changing hide delay restarts paused auto-hide timer', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 200));
      controller.setPlaying(true);
      controller.setPlaying(false);

      await tester.pump(const Duration(milliseconds: 100));
      controller.configure(hideDelay: const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 299));
      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.controlsVisible, isFalse);
    });

    testWidgets('show while paused restarts paused auto-hide timer', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 100));
      controller.setPlaying(true);
      controller.setPlaying(false);

      await tester.pump(const Duration(milliseconds: 50));
      controller.show();

      await tester.pump(const Duration(milliseconds: 99));
      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.controlsVisible, isFalse);
    });

    testWidgets('pointer activity while paused restarts paused auto-hide timer', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.configure(hideDelay: const Duration(milliseconds: 100));
      controller.setPlaying(true);
      controller.setPlaying(false);

      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.recordPointerActivity(), isTrue);

      await tester.pump(const Duration(milliseconds: 99));
      expect(controller.controlsVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.controlsVisible, isFalse);
    });

    test('show stores play/pause focus request and notifies even when already visible', () {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.show(focusPlayPause: true);

      expect(notifications, 1);
      expect(controller.pendingPlayPauseFocus, isTrue);
      expect(controller.takePlayPauseFocus(), isTrue);
      expect(controller.takePlayPauseFocus(), isFalse);
    });

    test('hide keeps controls presented until the opacity animation completes', () {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.hide();

      expect(controller.controlsVisible, isFalse);
      expect(controller.controlsPresented, isTrue);

      controller.markControlsHidden();

      expect(controller.controlsPresented, isFalse);
    });

    test('hide before the chrome ever became opaque retires presentation immediately', () {
      final controller = PlayerChromeController(initiallyVisible: false);
      addTearDown(controller.dispose);

      // Desktop pointer-exit race: show and hide land in the same frame gap,
      // so the AnimatedOpacity mounts already at its hidden target, never
      // animates, and never fires onEnd → markControlsHidden.
      controller.show();
      expect(controller.controlsPresented, isTrue);

      expect(controller.hide(ignoreHolds: true), isTrue);

      expect(controller.controlsVisible, isFalse);
      expect(
        controller.controlsPresented,
        isFalse,
        reason: 'no fade-out will run, so back must resolve to the route pop, not hide-the-chrome',
      );
    });

    test('hide after the chrome became opaque still defers presentation to the fade-out', () {
      final controller = PlayerChromeController(initiallyVisible: false);
      addTearDown(controller.dispose);

      controller.show();
      controller.markControlsOpaque();
      controller.hide();

      expect(controller.controlsPresented, isTrue, reason: 'a real fade-out owns the presented flag until onEnd');

      controller.markControlsHidden();

      expect(controller.controlsPresented, isFalse);
    });

    test('a hidden start is also unpresented, so back is not classified as hide-the-chrome', () {
      final controller = PlayerChromeController(initiallyVisible: false);
      addTearDown(controller.dispose);

      expect(controller.controlsVisible, isFalse);
      expect(controller.controlsPresented, isFalse);
      expect(controller.hide(), isFalse, reason: 'there is nothing to hide, so back must fall through to the route');
    });

    test('showing after a hidden start restores both visibility and presentation', () {
      final controller = PlayerChromeController(initiallyVisible: false);
      addTearDown(controller.dispose);

      controller.show();

      expect(controller.controlsVisible, isTrue);
      expect(controller.controlsPresented, isTrue);
    });

    test('a stale fade-out completion cannot hide controls that were shown again', () {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);

      controller.hide();
      controller.show();
      controller.markControlsHidden();

      expect(controller.controlsVisible, isTrue);
      expect(controller.controlsPresented, isTrue);
    });

    test('silent release removes hold without notifying listeners', () {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);
      controller.hold(PlayerChromeHold.promptInteraction);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.release(PlayerChromeHold.promptInteraction, notify: false, restartAutoHide: false);

      expect(controller.isHeld(PlayerChromeHold.promptInteraction), isFalse);
      expect(notifications, 0);
    });

    testWidgets('interaction region shows on hover and hides on exit', (tester) async {
      final controller = PlayerChromeController();
      addTearDown(controller.dispose);
      controller.hide();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: PlayerChromeInteractionRegion(
                controller: controller,
                hideOnExit: true,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(250, 250));
      await tester.pump();
      await mouse.moveTo(const Offset(20, 20));
      await tester.pump();
      expect(controller.controlsVisible, isTrue);

      await mouse.moveTo(const Offset(250, 250));
      await tester.pump();
      expect(controller.controlsVisible, isFalse);
    });
  });
}
