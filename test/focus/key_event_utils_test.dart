import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/focus/dpad_navigator.dart';
import 'package:vibe_stream/focus/focusable_action_bar.dart';
import 'package:vibe_stream/focus/key_event_utils.dart';
import 'package:vibe_stream/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyUpSuppressor.clearSuppression();
  });

  testWidgets('tvOS physical keyboard back runs on key down and suppresses key up', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    var backs = 0;

    final downResult = handleBackKeyAction(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
      () => backs++,
    );

    final upResult = handleBackKeyAction(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
      () => backs++,
    );

    expect(downResult, KeyEventResult.handled);
    expect(upResult, KeyEventResult.handled);
    expect(backs, 1);
  });

  group('dpadKeyHandler trapHorizontalEdges', () {
    testWidgets('consumes edge LEFT/RIGHT so focus cannot escape the group', (tester) async {
      final trapped = FocusNode(debugLabel: 'trapped');
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(trapped.dispose);
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(
                  focusNode: trapped,
                  onKeyEvent: dpadKeyHandler(trapHorizontalEdges: true),
                  child: const SizedBox(width: 50, height: 50),
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      trapped.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');
    });

    testWidgets('default (no trap) still lets edge RIGHT pass through to the framework', (tester) async {
      final node = FocusNode(debugLabel: 'node');
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(node.dispose);
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(focusNode: node, onKeyEvent: dpadKeyHandler(), child: const SizedBox(width: 50, height: 50)),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'outside');
    });
  });

  group('FocusableActionBar edge trapping', () {
    testWidgets('traps LEFT/RIGHT at row edges when no horizontal nav is wired', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                FocusableActionBar(
                  key: key,
                  actions: [
                    FocusableAction(icon: Icons.add, onPressed: () {}),
                    FocusableAction(icon: Icons.remove, onPressed: () {}),
                  ],
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      // Interior RIGHT moves to the next button.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');

      // RIGHT at the last button is trapped — must NOT escape to 'outside'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');

      // LEFT back to the first, then LEFT again is trapped.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');
    });

    testWidgets('still invokes onNavigateLeft at the left edge when wired', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      final leftTarget = FocusNode(debugLabel: 'left-target');
      addTearDown(leftTarget.dispose);
      var navigatedLeft = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(focusNode: leftTarget, child: const SizedBox(width: 50, height: 50)),
                FocusableActionBar(
                  key: key,
                  onNavigateLeft: () {
                    navigatedLeft = true;
                    leftTarget.requestFocus();
                  },
                  actions: [FocusableAction(icon: Icons.add, onPressed: () {})],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(navigatedLeft, isTrue);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'left-target');
    });

    testWidgets('invokes custom child action on select', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      var activations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusableActionBar(
              key: key,
              actions: [FocusableAction(onPressed: () => activations++, child: const SizedBox(width: 48, height: 48))],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(activations, 1);
    });

    testWidgets('moves through detail actions when trailer is inserted before shuffle', (tester) async {
      final play = FocusNode(debugLabel: 'detail_play');
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(play.dispose);
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                FocusableActionBar(
                  actions: [
                    FocusableAction(
                      debugLabel: 'unused_play_label',
                      focusNode: play,
                      icon: Icons.play_arrow,
                      onPressed: () {},
                    ),
                    FocusableAction(debugLabel: 'detail_trailer', icon: Icons.theaters, onPressed: () {}),
                    FocusableAction(debugLabel: 'detail_shuffle', icon: Icons.shuffle, onPressed: () {}),
                    FocusableAction(debugLabel: 'detail_download', icon: Icons.download, onPressed: () {}),
                    FocusableAction(debugLabel: 'detail_watched', icon: Icons.check, onPressed: () {}),
                    FocusableAction(debugLabel: 'detail_more', icon: Icons.more_vert, onPressed: () {}),
                  ],
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      play.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_play');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_trailer');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_shuffle');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_download');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_watched');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_more');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail_more');
    });
  });
}
