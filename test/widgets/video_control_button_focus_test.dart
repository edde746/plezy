import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/widgets/video_controls/video_control_button.dart';

import '../test_helpers/theme.dart';

/// A focused player control on top of video inverts (#2383): the icon turns
/// black on a solid disc instead of sitting on a faint translucent fill that
/// vanishes over a bright frame. The inversion is a D-pad/keyboard affordance
/// only, and it must not erase the dimming of an unavailable control.
void main() {
  late FocusNode node;

  setUp(() => node = FocusNode(debugLabel: 'control'));
  tearDown(() => node.dispose());

  Widget shell({Color? color, VoidCallback? onPressed}) => InputModeTracker(
    child: MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: Scaffold(
        body: Center(
          child: VideoControlButton(
            icon: Symbols.pause_rounded,
            color: color,
            focusNode: node,
            onPressed: onPressed ?? () {},
            semanticLabel: 'Pause',
          ),
        ),
      ),
    ),
  );

  Color? iconColor(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon)).color;

  Future<void> enterKeyboardMode(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
  }

  testWidgets('D-pad focus inverts the icon and blur restores it', (tester) async {
    await tester.pumpWidget(shell());
    await enterKeyboardMode(tester);
    // The arrow that armed keyboard mode may already have traversed onto the
    // only focusable; start from a known unfocused state.
    node.unfocus();
    await tester.pumpAndSettle();
    expect(iconColor(tester), Colors.white);

    node.requestFocus();
    await tester.pumpAndSettle();
    expect(iconColor(tester), Colors.black);

    node.unfocus();
    await tester.pumpAndSettle();
    expect(iconColor(tester), Colors.white);
  });

  testWidgets('an unavailable control stays dimmed on the disc', (tester) async {
    await tester.pumpWidget(shell(color: Colors.white54, onPressed: null));
    await enterKeyboardMode(tester);

    node.requestFocus();
    await tester.pumpAndSettle();

    final color = iconColor(tester)!;
    expect(color.a, closeTo(Colors.white54.a, 0.01), reason: 'dimming must survive the inversion');
    expect((color.r, color.g, color.b), (0.0, 0.0, 0.0));
  });

  testWidgets('focus in pointer mode draws no inversion', (tester) async {
    await tester.pumpWidget(shell());

    node.requestFocus();
    await tester.pumpAndSettle();

    expect(node.hasPrimaryFocus, isTrue);
    expect(iconColor(tester), Colors.white, reason: 'focus chrome is a keyboard/D-pad affordance only');
  });
}
