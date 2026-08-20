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
}
