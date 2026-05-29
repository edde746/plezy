import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/utils/platform_detector.dart';

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

  group('hasHorizontalNeighbor', () {
    testWidgets('reports interior vs. edge neighbors for a flat button row', (tester) async {
      final container = FocusNode(debugLabel: 'row', skipTraversal: true);
      final play = FocusNode(debugLabel: 'play');
      final download = FocusNode(debugLabel: 'download');
      final more = FocusNode(debugLabel: 'more');
      for (final node in [container, play, download, more]) {
        addTearDown(node.dispose);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: container,
              skipTraversal: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(focusNode: play, onPressed: () {}, child: const Text('Play')),
                  IconButton(focusNode: download, onPressed: () {}, icon: const Icon(Icons.download)),
                  IconButton(focusNode: more, onPressed: () {}, icon: const Icon(Icons.more_vert)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The ordinal helper assumes one traversal node per button, in reading
      // order. Assert it so a framework change that breaks the assumption fails
      // loudly here rather than silently re-opening the black hole.
      expect(container.traversalDescendants.length, 3);

      play.requestFocus();
      await tester.pump();
      expect(hasHorizontalNeighbor(container, TraversalDirection.left), isFalse);
      expect(hasHorizontalNeighbor(container, TraversalDirection.right), isTrue);

      download.requestFocus();
      await tester.pump();
      expect(hasHorizontalNeighbor(container, TraversalDirection.left), isTrue);
      expect(hasHorizontalNeighbor(container, TraversalDirection.right), isTrue);

      more.requestFocus();
      await tester.pump();
      expect(hasHorizontalNeighbor(container, TraversalDirection.right), isFalse);
      expect(hasHorizontalNeighbor(container, TraversalDirection.left), isTrue);
    });

    testWidgets('single-item row has no horizontal neighbor either way (rating-chip case)', (tester) async {
      final container = FocusNode(debugLabel: 'row', skipTraversal: true);
      final only = FocusNode(debugLabel: 'chip');
      addTearDown(container.dispose);
      addTearDown(only.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: container,
              skipTraversal: true,
              child: Focus(focusNode: only, child: const SizedBox(width: 50, height: 50)),
            ),
          ),
        ),
      );
      await tester.pump();
      only.requestFocus();
      await tester.pump();

      expect(hasHorizontalNeighbor(container, TraversalDirection.left), isFalse);
      expect(hasHorizontalNeighbor(container, TraversalDirection.right), isFalse);
    });

    testWidgets('returns false when focus is outside the container', (tester) async {
      final container = FocusNode(debugLabel: 'row');
      final inside = FocusNode(debugLabel: 'inside');
      final outside = FocusNode(debugLabel: 'outside');
      for (final node in [container, inside, outside]) {
        addTearDown(node.dispose);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(
                  focusNode: container,
                  child: Focus(focusNode: inside, child: const SizedBox(width: 40, height: 40)),
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 40, height: 40)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      outside.requestFocus();
      await tester.pump();

      expect(hasHorizontalNeighbor(container, TraversalDirection.left), isFalse);
      expect(hasHorizontalNeighbor(container, TraversalDirection.right), isFalse);
    });
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
  });
}
