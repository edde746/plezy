import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/covered_route_focus_boundary.dart';
import 'package:plezy/utils/focus_utils.dart';

void main() {
  testWidgets('a captured detached node cannot queue focus through its still-mounted former host', (tester) async {
    final key = GlobalKey<_RestorationHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _RestorationHarness(key: key)));
    final state = key.currentState!;
    state.original.requestFocus();
    await tester.pump();
    state.swapHost(true);
    state.replacement.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(state.original.context!.mounted, isTrue);
    expect(state.original.parent, isNull);
    expect(state.original.canRequestFocus, isTrue);

    FocusUtils.restoreFocusAfterBuild(state, state.original);
    await tester.pump();
    await tester.pump();
    expect(state.replacement.hasPrimaryFocus, isTrue);
    state.guard.requestFocus();
    await tester.pump();
    expect(state.guard.hasPrimaryFocus, isTrue);
    state.swapHost(false);
    await tester.pump();
    await tester.pump();
    expect(state.guard.hasPrimaryFocus, isTrue, reason: 'a stale restoration must not become a preattachment request');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'guard');
  });

  testWidgets('profile subtree disposal invalidates a queued captured restoration', (tester) async {
    final key = GlobalKey<_RestorationHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _RestorationHarness(key: key)));
    final state = key.currentState!;
    state.original.requestFocus();
    await tester.pump();
    FocusUtils.restoreFocusAfterBuild(state, state.original);
    final nextProfile = FocusNode();
    addTearDown(nextProfile.dispose);
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: nextProfile,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              selected = true;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: const Text('Next profile'),
        ),
      ),
    );
    await tester.pump();
    expect(key.currentState, isNull);
    expect(nextProfile.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captured restoration does not steal from a newly covering route', (tester) async {
    final key = GlobalKey<_RestorationHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _RestorationHarness(key: key)));
    final state = key.currentState!;
    state.original.requestFocus();
    await tester.pump();
    final cover = FocusNode();
    addTearDown(cover.dispose);
    unawaited(
      showDialog<void>(
        context: state.context,
        builder: (_) => AlertDialog(
          content: Focus(focusNode: cover, autofocus: true, child: const Text('Cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(state.original.canRequestFocus, isTrue, reason: 'ordinary covered routes only skip traversal');
    FocusUtils.restoreFocusAfterBuild(state, state.original);
    await tester.pump();
    await tester.pump();
    expect(cover.hasPrimaryFocus, isTrue);
    Navigator.of(cover.context!).pop();
    await tester.pumpAndSettle();
    expect(state.original.hasPrimaryFocus, isTrue);
  });

  testWidgets('captured nested-route restoration respects the outer covered boundary', (tester) async {
    final key = GlobalKey<_RestorationHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: CoveredRouteFocusBoundary(
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _RestorationHarness(key: key)),
          ),
        ),
      ),
    );
    final state = key.currentState!;
    state.original.requestFocus();
    await tester.pump();
    final cover = FocusNode();
    addTearDown(cover.dispose);
    unawaited(
      showDialog<void>(
        context: state.context,
        builder: (_) => AlertDialog(
          content: Focus(focusNode: cover, autofocus: true, child: const Text('Profile picker')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(ModalRoute.of(state.context)!.isCurrent, isTrue);
    expect(state.original.canRequestFocus, isFalse);
    FocusUtils.restoreFocusAfterBuild(state, state.original);
    await tester.pump();
    await tester.pump();
    expect(cover.hasPrimaryFocus, isTrue);
    Navigator.of(cover.context!).pop();
    await tester.pumpAndSettle();
    expect(state.original.hasPrimaryFocus, isTrue);
  });
}

class _RestorationHarness extends StatefulWidget {
  const _RestorationHarness({super.key});

  @override
  State<_RestorationHarness> createState() => _RestorationHarnessState();
}

class _RestorationHarnessState extends State<_RestorationHarness> {
  final original = FocusNode(debugLabel: 'original');
  final replacement = FocusNode(debugLabel: 'replacement');
  final guard = FocusNode(debugLabel: 'guard');
  bool useReplacement = false;
  String? selected;

  void swapHost(bool value) => setState(() => useReplacement = value);

  @override
  void dispose() {
    original.dispose();
    replacement.dispose();
    guard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Focus(focusNode: useReplacement ? replacement : original, child: const Text('Item')),
        Focus(
          focusNode: guard,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              selected = 'guard';
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: const Text('Guard'),
        ),
      ],
    ),
  );
}
