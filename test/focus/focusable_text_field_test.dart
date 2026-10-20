import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/key_event_utils.dart';

void main() {
  testWidgets('unwired single-line fields traverse with arrow keys', (tester) async {
    final first = FocusNode(debugLabel: 'first');
    final second = FocusNode(debugLabel: 'second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    addTearDown(c1.dispose);
    addTearDown(c2.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: c1,
                focusNode: first,
                tvTextInputPresentation: TvTextInputPresentation.platform,
              ),
              FocusableTextField(
                controller: c2,
                focusNode: second,
                tvTextInputPresentation: TvTextInputPresentation.platform,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    first.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'first');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'second');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'first');
  });

  testWidgets('unwired multiline field keeps arrow keys for the caret', (tester) async {
    final first = FocusNode(debugLabel: 'multiline');
    final second = FocusNode(debugLabel: 'below');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final c1 = TextEditingController(text: 'line1\nline2');
    final c2 = TextEditingController();
    addTearDown(c1.dispose);
    addTearDown(c2.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: c1,
                focusNode: first,
                maxLines: 4,
                tvTextInputPresentation: TvTextInputPresentation.platform,
              ),
              FocusableTextField(
                controller: c2,
                focusNode: second,
                tvTextInputPresentation: TvTextInputPresentation.platform,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    first.requestFocus();
    c1.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'multiline');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'multiline');
  });

  testWidgets('back on a field with onBack fires once on key up and marks the frame handled', (tester) async {
    // The field must route back through the shared handler like every other
    // focusable: consume KeyDown, run onBack on KeyUp, and mark the frame so
    // a parallel back dispatch (the layer focus lands on next) dedupes.
    addTearDown(BackKeyCoordinator.clear);
    final node = FocusNode(debugLabel: 'field');
    addTearDown(node.dispose);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var backs = 0;

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: Scaffold(
            body: FocusableTextField(
              controller: controller,
              focusNode: node,
              onBack: () => backs++,
              tvTextInputPresentation: TvTextInputPresentation.platform,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    node.requestFocus();
    await tester.pump();
    // Enter keyboard mode; the sole field has no neighbour so focus stays put.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(backs, 0, reason: 'KeyDown is consumed without firing so a pop cannot double-run on KeyUp');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    expect(backs, 1);
    // Same-frame dedupe mark: assert before pumping, which runs the
    // coordinator's post-frame clear.
    expect(BackKeyCoordinator.consumeIfHandled(), isTrue);
    await tester.pump();
  });

  testWidgets('a field remounted within one frame keeps handling keys once the replaced host is disposed', (
    tester,
  ) async {
    // A remount builds the replacement host before the old one is disposed at
    // the end of the frame, so both briefly sit on the caller's node.
    final baseDowns = <LogicalKeyboardKey>[];
    KeyEventResult baseHandler(FocusNode _, KeyEvent event) {
      if (event is KeyDownEvent) baseDowns.add(event.logicalKey);
      return KeyEventResult.ignored;
    }

    final node = FocusNode(debugLabel: 'field', onKeyEvent: baseHandler);
    addTearDown(node.dispose);
    final original = node.onKeyEvent;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final downs = <int>[];
    var generation = 0;
    var showField = true;
    late StateSetter setShellState;

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setShellState = setState;
                if (!showField) return const SizedBox.shrink();
                final built = generation;
                return FocusableTextField(
                  key: ValueKey(built),
                  controller: controller,
                  focusNode: node,
                  onNavigateDown: () => downs.add(built),
                  tvTextInputPresentation: TvTextInputPresentation.platform,
                );
              },
            ),
          ),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();
    // Enter keyboard mode; the first host handles this press.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(downs, [0]);

    setShellState(() => generation++);
    await tester.pump();
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(downs, [0, 1], reason: 'only the live host handles the press');
    expect(baseDowns, [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown]);

    setShellState(() => showField = false);
    await tester.pump();
    expect(node.onKeyEvent, same(original));
  });

  for (final newerLeavesFirst in [false, true]) {
    final (first, second) = newerLeavesFirst ? ('newer', 'older') : ('older', 'newer');
    testWidgets('hosts sharing a focus node hand it over when the $first one leaves first', (tester) async {
      // Presses go through the node's handler directly: once the newer field
      // leaves, the framework detaches the shared node from the tree, so no
      // real press can reach it — yet its handler must be the survivor's.
      KeyEventResult baseHandler(FocusNode _, KeyEvent _) => KeyEventResult.ignored;
      final node = FocusNode(debugLabel: 'shared', onKeyEvent: baseHandler);
      addTearDown(node.dispose);
      final original = node.onKeyEvent;
      const labels = ['older', 'newer'];
      final controllers = {for (final label in labels) label: TextEditingController()};
      for (final controller in controllers.values) {
        addTearDown(controller.dispose);
      }
      final shown = {...labels};
      final downs = <String>[];
      late StateSetter setShellState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setShellState = setState;
                return Column(
                  children: [
                    for (final label in labels)
                      if (shown.contains(label))
                        FocusableTextField(
                          key: ValueKey(label),
                          controller: controllers[label]!,
                          focusNode: node,
                          onNavigateDown: () => downs.add(label),
                          tvTextInputPresentation: TvTextInputPresentation.platform,
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      KeyEventResult pressDown() => node.onKeyEvent!(
        node,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration.zero,
        ),
      );

      expect(pressDown(), KeyEventResult.handled);
      expect(downs, ['newer'], reason: 'the newest host owns the node');

      setShellState(() => shown.remove(first));
      await tester.pump();
      expect(pressDown(), KeyEventResult.handled);
      expect(downs, ['newer', second]);

      setShellState(() => shown.remove(second));
      await tester.pump();
      expect(node.onKeyEvent, same(original));
    });
  }
}
