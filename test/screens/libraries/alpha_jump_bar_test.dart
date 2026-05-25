import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_first_character.dart';
import 'package:plezy/screens/libraries/alpha_jump_bar.dart';

void main() {
  const alphabetCharacters = [
    LibraryFirstCharacter(key: '#', title: '#', size: 1),
    LibraryFirstCharacter(key: 'A', title: 'A', size: 1),
    LibraryFirstCharacter(key: 'B', title: 'B', size: 1),
    LibraryFirstCharacter(key: 'C', title: 'C', size: 1),
    LibraryFirstCharacter(key: 'D', title: 'D', size: 1),
    LibraryFirstCharacter(key: 'E', title: 'E', size: 1),
    LibraryFirstCharacter(key: 'F', title: 'F', size: 1),
    LibraryFirstCharacter(key: 'G', title: 'G', size: 1),
    LibraryFirstCharacter(key: 'H', title: 'H', size: 1),
    LibraryFirstCharacter(key: 'I', title: 'I', size: 1),
    LibraryFirstCharacter(key: 'J', title: 'J', size: 1),
    LibraryFirstCharacter(key: 'K', title: 'K', size: 1),
    LibraryFirstCharacter(key: 'L', title: 'L', size: 1),
    LibraryFirstCharacter(key: 'M', title: 'M', size: 1),
    LibraryFirstCharacter(key: 'N', title: 'N', size: 1),
    LibraryFirstCharacter(key: 'O', title: 'O', size: 1),
    LibraryFirstCharacter(key: 'P', title: 'P', size: 1),
    LibraryFirstCharacter(key: 'Q', title: 'Q', size: 1),
    LibraryFirstCharacter(key: 'R', title: 'R', size: 1),
    LibraryFirstCharacter(key: 'S', title: 'S', size: 1),
    LibraryFirstCharacter(key: 'T', title: 'T', size: 1),
    LibraryFirstCharacter(key: 'U', title: 'U', size: 1),
    LibraryFirstCharacter(key: 'V', title: 'V', size: 1),
    LibraryFirstCharacter(key: 'W', title: 'W', size: 1),
    LibraryFirstCharacter(key: 'X', title: 'X', size: 1),
    LibraryFirstCharacter(key: 'Y', title: 'Y', size: 1),
    LibraryFirstCharacter(key: 'Z', title: 'Z', size: 1),
  ];

  testWidgets('keeps the full alphabet visible in a short TV-height bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 420,
            child: AlphaJumpBar(firstCharacters: alphabetCharacters, currentLetter: '#', onJump: (_) {}),
          ),
        ),
      ),
    );

    expect(find.text('#'), findsOneWidget);
    expect(find.text('U'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets('Enter jumps to the highlighted letter', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test_alpha_jump_bar');
    addTearDown(focusNode.dispose);

    int? jumpedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: AlphaJumpBar(
              firstCharacters: const [
                LibraryFirstCharacter(key: 'A', title: 'A', size: 3),
                LibraryFirstCharacter(key: 'B', title: 'B', size: 4),
                LibraryFirstCharacter(key: 'C', title: 'C', size: 2),
              ],
              currentLetter: 'B',
              focusNode: focusNode,
              onJump: (index) => jumpedTo = index,
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(jumpedTo, 3);
  });

  testWidgets('Enter jumps to the descending title offset', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test_alpha_jump_bar_desc');
    addTearDown(focusNode.dispose);

    int? jumpedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: AlphaJumpBar(
              firstCharacters: const [
                LibraryFirstCharacter(key: 'A', title: 'A', size: 3),
                LibraryFirstCharacter(key: 'B', title: 'B', size: 4),
                LibraryFirstCharacter(key: 'C', title: 'C', size: 2),
              ],
              currentLetter: 'B',
              descending: true,
              focusNode: focusNode,
              onJump: (index) => jumpedTo = index,
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(jumpedTo, 2);
  });
}
