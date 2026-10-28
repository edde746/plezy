import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/games/steam_touch_controls.dart';
import 'package:plezy/theme/mono_theme.dart';

void main() {
  testWidgets('multi-touch buttons release independently and preserve accessible targets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final changes = <(String, bool)>[];
    var released = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.oled),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        ),
        home: Scaffold(
          body: SteamTouchControls(
            onButton: (key, down) => changes.add((key, down)),
            onStick: (_, _) {},
            onRelease: () => released++,
          ),
        ),
      ),
    );
    final a = find.byKey(const ValueKey('a')), b = find.byKey(const ValueKey('b'));
    expect(tester.getSize(a), const Size(48, 48));
    expect(tester.getSemantics(a), matchesSemantics(label: 'A', isButton: true, hasTapAction: true));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('leftBumper'))),
      matchesSemantics(label: 'Left shoulder button', isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('dpadLeft'))),
      matchesSemantics(label: 'Directional pad left', isButton: true, hasTapAction: true),
    );
    final first = await tester.startGesture(tester.getCenter(a), pointer: 1);
    final second = await tester.startGesture(tester.getCenter(b), pointer: 2);
    await tester.pump();
    expect(changes, [('a', true), ('b', true)]);
    await first.cancel();
    expect(changes.last, ('a', false));
    await second.up();
    expect(changes.last, ('b', false));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(released, 1);
    semantics.dispose();
  });

  testWidgets('sticks clamp their travel, neutralize on cancellation, and tiny panes explain resizing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final moves = <(String, Offset)>[];
    final clicks = <(String, bool)>[];
    Widget app() => MaterialApp(
      home: Scaffold(
        body: SteamTouchControls(
          onButton: (key, down) => clicks.add((key, down)),
          onStick: (key, value) => moves.add((key, value)),
          onRelease: () {},
        ),
      ),
    );
    await tester.pumpWidget(app());
    final center = tester.getCenter(find.byKey(const ValueKey('leftStick')));
    final touch = await tester.startGesture(center);
    await touch.moveBy(const Offset(300, -300));
    expect(moves.last.$1, 'leftStick');
    expect(moves.last.$2.distance, closeTo(1, .00001));
    await touch.cancel();
    expect(moves.last.$2, Offset.zero);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(clicks, [('leftStick', true), ('leftStick', false)]);
    final held = await tester.startGesture(center);
    await held.moveBy(const Offset(20, 10));
    await tester.binding.setSurfaceSize(const Size(320, 240));
    await tester.pump();
    await held.cancel();
    // The framework's double-tap recognizer keeps its minimum-tap timer even
    // when the control is removed during an active pointer sequence.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('a')), findsNothing);
    expect(find.textContaining('Enlarge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
