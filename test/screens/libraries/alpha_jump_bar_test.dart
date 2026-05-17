import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_first_character.dart';
import 'package:plezy/screens/libraries/alpha_jump_bar.dart';

void main() {
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
