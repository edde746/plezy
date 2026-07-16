import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/media/library_first_character.dart';
import 'package:plezy/screens/libraries/alpha_jump_bar.dart';
import 'package:plezy/utils/platform_detector.dart';

const _backKeys = [
  _BackKeyCase('Escape', LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape),
  _BackKeyCase('GoBack', LogicalKeyboardKey.goBack, PhysicalKeyboardKey.escape),
  _BackKeyCase('BrowserBack', LogicalKeyboardKey.browserBack, PhysicalKeyboardKey.browserBack),
  _BackKeyCase('GameButtonB', LogicalKeyboardKey.gameButtonB, PhysicalKeyboardKey.enter),
];

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

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyUpSuppressor.clearSuppression();
    BackKeyCoordinator.clear();
  });

  for (final backKey in _backKeys) {
    testWidgets('${backKey.label} runs back once on key up and consumes the normal press', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(false);
      final harness = await _pumpBackHarness(tester);

      final downHandled = _sendKeyDown(tester, backKey);
      expect(downHandled, isTrue);
      expect(harness.jumpBarBacks, 0);
      expect(harness.ancestorEvents, 0);

      final repeatHandled = _sendKeyRepeat(tester, backKey);
      expect(repeatHandled, isTrue);
      expect(harness.jumpBarBacks, 0);
      expect(harness.ancestorEvents, 0);

      final upHandled = _sendKeyUp(tester, backKey);
      expect(upHandled, isTrue);
      expect(harness.jumpBarBacks, 1);
      expect(harness.ancestorEvents, 0);
      expect(harness.ancestorBacks, 0);

      await tester.pump();
      harness.moveFocusOnBack = true;

      final movingDownHandled = _sendKeyDown(tester, backKey);
      final movingRepeatHandled = _sendKeyRepeat(tester, backKey);
      final movingUpHandled = _sendKeyUp(tester, backKey);

      expect(movingDownHandled, isTrue);
      expect(movingRepeatHandled, isTrue);
      expect(movingUpHandled, isTrue);
      expect(harness.jumpBarBacks, 2);
      expect(harness.ancestorEvents, 0);
      expect(harness.ancestorBacks, 0);
      await tester.pump();
      expect(harness.nextFocusNode.hasFocus, isTrue);
    });

    testWidgets('${backKey.label} runs back once on Apple TV key down and consumes key up', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      final harness = await _pumpBackHarness(tester);

      final downHandled = _sendKeyDown(tester, backKey);
      expect(downHandled, isTrue);
      expect(harness.jumpBarBacks, 1);
      expect(harness.ancestorEvents, 0);

      final repeatHandled = _sendKeyRepeat(tester, backKey);
      expect(repeatHandled, isTrue);
      expect(harness.jumpBarBacks, 1);
      expect(harness.ancestorEvents, 0);

      final upHandled = _sendKeyUp(tester, backKey);
      expect(upHandled, isTrue);
      expect(harness.jumpBarBacks, 1);
      expect(harness.ancestorEvents, 0);
      expect(harness.ancestorBacks, 0);

      await tester.pump();
      harness.moveFocusOnBack = true;

      final movingDownHandled = _sendKeyDown(tester, backKey);
      expect(movingDownHandled, isTrue);
      expect(harness.jumpBarBacks, 2);
      expect(harness.ancestorEvents, 0);
      await tester.pump();
      expect(harness.nextFocusNode.hasFocus, isTrue);

      final movingRepeatHandled = _sendKeyRepeat(tester, backKey);
      final movingUpHandled = _sendKeyUp(tester, backKey);

      expect(movingRepeatHandled, isTrue);
      expect(movingUpHandled, isTrue);
      expect(harness.jumpBarBacks, 2);
      expect(harness.ancestorEvents, 2);
      expect(harness.ancestorBacks, 0);
    });
  }

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

class _BackKeyCase {
  final String label;
  final LogicalKeyboardKey logicalKey;
  final PhysicalKeyboardKey physicalKey;

  const _BackKeyCase(this.label, this.logicalKey, this.physicalKey);
}

class _BackHarness {
  final jumpBarFocusNode = FocusNode(debugLabel: 'test_alpha_jump_bar_back');
  final nextFocusNode = FocusNode(debugLabel: 'test_alpha_jump_bar_back_destination');
  final ancestorFocusNode = FocusNode(debugLabel: 'test_alpha_jump_bar_back_ancestor');

  var jumpBarBacks = 0;
  var ancestorEvents = 0;
  var ancestorBacks = 0;
  var moveFocusOnBack = false;

  void dispose() {
    jumpBarFocusNode.dispose();
    nextFocusNode.dispose();
    ancestorFocusNode.dispose();
  }
}

Future<_BackHarness> _pumpBackHarness(WidgetTester tester) async {
  final harness = _BackHarness();
  addTearDown(harness.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Focus(
          focusNode: harness.ancestorFocusNode,
          onKeyEvent: (_, event) {
            harness.ancestorEvents++;
            return handleBackKeyAction(event, () => harness.ancestorBacks++);
          },
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: AlphaJumpBar(
                  firstCharacters: const [
                    LibraryFirstCharacter(key: 'A', title: 'A', size: 3),
                    LibraryFirstCharacter(key: 'B', title: 'B', size: 4),
                    LibraryFirstCharacter(key: 'C', title: 'C', size: 2),
                  ],
                  currentLetter: 'B',
                  focusNode: harness.jumpBarFocusNode,
                  onJump: (_) {},
                  onBack: () {
                    harness.jumpBarBacks++;
                    if (harness.moveFocusOnBack) {
                      harness.nextFocusNode.requestFocus();
                    }
                  },
                ),
              ),
              Focus(focusNode: harness.nextFocusNode, child: const SizedBox(width: 1, height: 1)),
            ],
          ),
        ),
      ),
    ),
  );

  harness.jumpBarFocusNode.requestFocus();
  await tester.pump();
  expect(harness.jumpBarFocusNode.hasFocus, isTrue);
  return harness;
}

bool _sendKeyDown(WidgetTester _, _BackKeyCase backKey) {
  return _dispatchKeyEvent(
    KeyDownEvent(physicalKey: backKey.physicalKey, logicalKey: backKey.logicalKey, timeStamp: Duration.zero),
  );
}

bool _sendKeyRepeat(WidgetTester _, _BackKeyCase backKey) {
  return _dispatchKeyEvent(
    KeyRepeatEvent(
      physicalKey: backKey.physicalKey,
      logicalKey: backKey.logicalKey,
      timeStamp: const Duration(milliseconds: 1),
    ),
  );
}

bool _sendKeyUp(WidgetTester _, _BackKeyCase backKey) {
  return _dispatchKeyEvent(
    KeyUpEvent(
      physicalKey: backKey.physicalKey,
      logicalKey: backKey.logicalKey,
      timeStamp: const Duration(milliseconds: 2),
    ),
  );
}

bool _dispatchKeyEvent(KeyEvent event) {
  final handled = HardwareKeyboard.instance.handleKeyEvent(event);
  FocusNode? node = FocusManager.instance.primaryFocus;
  while (node != null) {
    final result = node.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    if (result == KeyEventResult.handled) return true;
    if (result == KeyEventResult.skipRemainingHandlers) return handled;
    node = node.parent;
  }
  return handled;
}
