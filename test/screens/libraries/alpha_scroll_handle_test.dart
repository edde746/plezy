import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/library_first_character.dart';
import 'package:plezy/screens/libraries/alpha_scroll_handle.dart';

void main() {
  const characters = [
    LibraryFirstCharacter(key: 'A', title: 'A', size: 2),
    LibraryFirstCharacter(key: 'B', title: 'B', size: 3),
    LibraryFirstCharacter(key: 'C', title: 'C', size: 4),
  ];

  Widget buildHandle({required bool isScrolling, required ValueChanged<int> onJump}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 300,
            child: AlphaScrollHandle(
              firstCharacters: characters,
              currentLetter: 'B',
              isScrolling: isScrolling,
              onJump: onJump,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps adjustable semantics mounted while fully hidden', (tester) async {
    final semantics = tester.ensureSemantics();
    final jumps = <int>[];

    await tester.pumpWidget(buildHandle(isScrolling: false, onJump: jumps.add));

    final finder = find.bySemanticsLabel(t.accessibility.alphabetNavigation);
    expect(finder, findsOneWidget);
    final node = tester.getSemantics(finder);
    final data = node.getSemanticsData();
    expect(data.value, 'B');
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);
    expect(tester.widget<IgnorePointer>(find.byType(IgnorePointer).last).ignoring, isTrue);

    node.owner!.performAction(node.id, SemanticsAction.increase);
    expect(jumps, [5]);
    semantics.dispose();
  });

  testWidgets('announces the current letter and exposes bounded letter steps', (tester) async {
    final semantics = tester.ensureSemantics();
    final jumps = <int>[];

    await tester.pumpWidget(buildHandle(isScrolling: false, onJump: jumps.add));
    await tester.pumpWidget(buildHandle(isScrolling: true, onJump: jumps.add));
    await tester.pump(const Duration(milliseconds: 250));

    final finder = find.bySemanticsLabel(t.accessibility.alphabetNavigation);
    expect(finder, findsOneWidget);
    final node = tester.getSemantics(finder);
    final data = node.getSemanticsData();
    expect(data.value, 'B');
    expect(data.hint, t.accessibility.alphabetScrollHint);
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.increase);
    expect(jumps, [5]);
    node.owner!.performAction(node.id, SemanticsAction.decrease);
    expect(jumps, [5, 0]);
    semantics.dispose();
  });
}
