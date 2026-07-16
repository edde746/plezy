import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/hotkey_model.dart';
import 'package:plezy/screens/settings/hotkey_recorder_widget.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/hotkey_recorder.dart';

void main() {
  tearDown(SelectKeyUpSuppressor.clearSuppression);

  testWidgets('initially unbound shortcut captures from a tap and saves', (tester) async {
    final saved = <HotKey>[];
    await _pumpRecorder(tester, saved: saved);

    expect(_recorder(tester).enabled, isFalse);
    expect(find.text(t.hotkeys.pressToRecord), findsNWidgets(2));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.record');
    expect(_saveAction(tester).onPressed, isNull);

    await tester.tap(find.byType(HotKeyRecorder));
    await tester.pump();

    expect(_recorder(tester).enabled, isTrue);
    expect(find.text(t.hotkeys.recordingShortcut), findsNWidgets(2));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.record');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyK, physicalKey: PhysicalKeyboardKey.keyK);
    await _pumpFocusChange(tester);

    expect(_recorder(tester).enabled, isFalse);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyK)), findsOneWidget);
    expect(find.text(t.hotkeys.pressToRecord), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');
    expect(saved, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, t.common.save));

    expect(saved, hasLength(1));
    expect(saved.single.key, PhysicalKeyboardKey.keyK);
    expect(saved.single.modifiers, isNull);
  });

  testWidgets('cleared shortcut can capture and save a replacement', (tester) async {
    final saved = <HotKey>[];
    await _pumpRecorder(
      tester,
      saved: saved,
      currentHotKey: const HotKey(key: PhysicalKeyboardKey.keyJ, modifiers: [HotKeyModifier.shift]),
    );

    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyJ)), findsOneWidget);
    expect(_saveAction(tester).onPressed, isNotNull);

    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();

    expect(_recorder(tester).enabled, isFalse);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyJ)), findsNothing);
    expect(find.text(t.hotkeys.pressToRecord), findsNWidgets(2));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.record');
    expect(_saveAction(tester).onPressed, isNull);

    await tester.tap(find.byType(HotKeyRecorder));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL, physicalKey: PhysicalKeyboardKey.keyL);
    await _pumpFocusChange(tester);

    expect(_recorder(tester).enabled, isFalse);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyL)), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');

    await tester.tap(find.widgetWithText(FilledButton, t.common.save));

    expect(saved, hasLength(1));
    expect(saved.single.key, PhysicalKeyboardKey.keyL);
    expect(saved.single.modifiers, isNull);
  });

  testWidgets('modifier-first Control+P completes with the held modifier', (tester) async {
    final saved = <HotKey>[];
    await _pumpRecorder(tester, saved: saved);
    await tester.tap(find.byType(HotKeyRecorder));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft, physicalKey: PhysicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(_recorder(tester).enabled, isTrue);
    expect(saved, isEmpty);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.controlLeft)), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP, physicalKey: PhysicalKeyboardKey.keyP);
    await _pumpFocusChange(tester);

    expect(_recorder(tester).enabled, isFalse);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.controlLeft)), findsOneWidget);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyP)), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP, physicalKey: PhysicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, physicalKey: PhysicalKeyboardKey.controlLeft);
    await tester.tap(find.widgetWithText(FilledButton, t.common.save));

    expect(saved, hasLength(1));
    expect(saved.single.key, PhysicalKeyboardKey.keyP);
    expect(saved.single.modifiers, [HotKeyModifier.control]);
  });

  for (final entry in <(String, LogicalKeyboardKey, PhysicalKeyboardKey)>[
    ('Enter', LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter),
    ('select', LogicalKeyboardKey.select, PhysicalKeyboardKey.select),
  ]) {
    testWidgets('${entry.$1} completion does not rearm capture or activate Save on key-up', (tester) async {
      final saved = <HotKey>[];
      await _pumpRecorder(tester, saved: saved);
      await tester.tap(find.byType(HotKeyRecorder));
      await tester.pump();

      await tester.sendKeyDownEvent(entry.$2, physicalKey: entry.$3);
      await _pumpFocusChange(tester);

      expect(_recorder(tester).enabled, isFalse);
      expect(find.text(t.hotkeys.recordingShortcut), findsNothing);
      expect(find.text(physicalKeyLabel(entry.$3)), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');
      expect(saved, isEmpty);

      await tester.sendKeyUpEvent(entry.$2, physicalKey: entry.$3);
      await tester.pump();

      expect(_recorder(tester).enabled, isFalse);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');
      expect(saved, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, t.common.save));

      expect(saved, hasLength(1));
      expect(saved.single.key, entry.$3);
      expect(saved.single.modifiers, isNull);
    });
  }
}

Future<void> _pumpRecorder(WidgetTester tester, {required List<HotKey> saved, HotKey? currentHotKey}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HotKeyRecorderWidget(
          actionName: 'Play/Pause',
          currentHotKey: currentHotKey,
          onHotKeyRecorded: saved.add,
          onCancel: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpFocusChange(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

HotKeyRecorder _recorder(WidgetTester tester) => tester.widget(find.byType(HotKeyRecorder));

DialogActionButton _saveAction(WidgetTester tester) =>
    tester.widget(find.widgetWithText(DialogActionButton, t.common.save));
