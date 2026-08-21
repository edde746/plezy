import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_memory_tracker.dart';

void main() {
  testWidgets('tracks and restores focus without a rebuild callback', (tester) async {
    final tracker = FocusMemoryTracker(debugLabelPrefix: 'test');
    addTearDown(tracker.dispose);
    final first = tracker.get('first');
    final second = tracker.get('second');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Focus(focusNode: first, child: const SizedBox(width: 10, height: 10)),
              Focus(focusNode: second, child: const SizedBox(width: 10, height: 10)),
            ],
          ),
        ),
      ),
    );

    first.requestFocus();
    await tester.pump();
    expect(tracker.lastFocusedKey, 'first');
    expect(tracker.isFocused('first'), isTrue);

    second.requestFocus();
    await tester.pump();
    expect(tracker.lastFocusedKey, 'second');
    expect(tracker.isFocused('first'), isFalse);
    expect(tracker.isFocused('second'), isTrue);

    first.requestFocus();
    await tester.pump();
    second.unfocus();
    expect(tracker.restoreFocus(), isTrue);
    await tester.pump();
    expect(first.hasFocus, isTrue);
  });

  testWidgets('uses the fallback key before any item has been focused', (tester) async {
    final tracker = FocusMemoryTracker(debugLabelPrefix: 'test');
    addTearDown(tracker.dispose);
    final fallback = tracker.get('fallback');

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(focusNode: fallback, child: const SizedBox(width: 10, height: 10)),
      ),
    );

    expect(tracker.restoreFocus(fallbackKey: 'fallback'), isTrue);
    await tester.pump();
    expect(fallback.hasFocus, isTrue);
    expect(tracker.lastFocusedKey, 'fallback');
  });
}
