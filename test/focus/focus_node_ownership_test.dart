import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/focus/focusable_wrapper.dart';

void main() {
  testWidgets('FocusableWrapper never disposes caller-owned nodes across swaps', (tester) async {
    final first = _TrackingFocusNode();
    final second = _TrackingFocusNode();
    late StateSetter rebuild;
    var node = first;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return FocusableWrapper(focusNode: node, child: const SizedBox(width: 10, height: 10));
          },
        ),
      ),
    );

    rebuild(() => node = second);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(first.disposeCalls, 0);
    expect(second.disposeCalls, 0);
    first.dispose();
    second.dispose();
  });

  testWidgets('FocusableActionBar never disposes caller-owned nodes across swaps', (tester) async {
    final first = _TrackingFocusNode();
    final second = _TrackingFocusNode();
    late StateSetter rebuild;
    var node = first;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return FocusableActionBar(
              actions: [FocusableAction(focusNode: node, onPressed: () {})],
            );
          },
        ),
      ),
    );

    rebuild(() => node = second);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(first.disposeCalls, 0);
    expect(second.disposeCalls, 0);
    first.dispose();
    second.dispose();
  });

  testWidgets('FocusableTextField never disposes caller-owned nodes across swaps', (tester) async {
    final first = _TrackingFocusNode();
    final second = _TrackingFocusNode();
    final controller = TextEditingController();
    late StateSetter rebuild;
    var node = first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FocusableTextField(controller: controller, focusNode: node, enableTvKeyboard: false);
            },
          ),
        ),
      ),
    );

    rebuild(() => node = second);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(first.disposeCalls, 0);
    expect(second.disposeCalls, 0);
    first.dispose();
    second.dispose();
    controller.dispose();
  });
}

class _TrackingFocusNode extends FocusNode {
  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}
