import 'dart:async';

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
    final saved = <HotKey?>[];
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
    expect(saved.single!.key, PhysicalKeyboardKey.keyK);
    expect(saved.single!.modifiers, isNull);
  });

  testWidgets('cleared assigned shortcut saves an explicit unassignment', (tester) async {
    final saved = <HotKey?>[];
    await _pumpRecorder(
      tester,
      saved: saved,
      currentHotKey: const HotKey(key: PhysicalKeyboardKey.keyJ, modifiers: [HotKeyModifier.shift]),
    );

    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();

    expect(_recorder(tester).enabled, isFalse);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyJ)), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.record');
    expect(_saveAction(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, t.common.save));
    await tester.pump();

    expect(saved, <HotKey?>[null]);
  });

  testWidgets('D-pad can save a cleared shortcut', (tester) async {
    final saved = <HotKey?>[];
    await _pumpRecorder(
      tester,
      saved: saved,
      currentHotKey: const HotKey(key: PhysicalKeyboardKey.keyJ),
    );

    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await _pumpFocusChange(tester);

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'HotKeyRecorder.save');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(saved, <HotKey?>[null]);
  });

  testWidgets('cancel and Escape discard a local clear', (tester) async {
    final saved = <HotKey?>[];
    var cancelCount = 0;
    const original = HotKey(key: PhysicalKeyboardKey.keyJ);
    await _pumpRecorder(tester, saved: saved, currentHotKey: original, onCancel: () => cancelCount++);

    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, t.common.cancel));
    expect(saved, isEmpty);
    expect(cancelCount, 1);

    await _pumpRecorder(tester, saved: saved, currentHotKey: original, onCancel: () => cancelCount++);
    expect(find.text(physicalKeyLabel(PhysicalKeyboardKey.keyJ)), findsOneWidget);
    await tester.tap(find.ancestor(of: find.byType(HotKeyRecorder), matching: find.byType(GestureDetector)).first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(saved, isEmpty);
    expect(cancelCount, 2);
  });

  testWidgets('save is single-flight and blocks cancellation', (tester) async {
    final gate = Completer<void>();
    var saveCount = 0;
    var cancelCount = 0;
    await _pumpRecorder(
      tester,
      saved: <HotKey?>[],
      currentHotKey: const HotKey(key: PhysicalKeyboardKey.keyJ),
      onCancel: () => cancelCount++,
      onSave: (_) {
        saveCount++;
        return gate.future;
      },
    );

    await tester.tap(find.widgetWithText(FilledButton, t.common.save));
    await tester.tap(find.widgetWithText(FilledButton, t.common.save), warnIfMissed: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(saveCount, 1);
    expect(cancelCount, 0);
    expect(_saveAction(tester).onPressed, isNull);
    expect(_cancelAction(tester).onPressed, isNull);

    gate.complete();
    await tester.pump();
    expect(_cancelAction(tester).onPressed, isNotNull);
  });

  testWidgets('modifier-first Control+P completes with the held modifier', (tester) async {
    final saved = <HotKey?>[];
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
    expect(saved.single!.key, PhysicalKeyboardKey.keyP);
    expect(saved.single!.modifiers, [HotKeyModifier.control]);
  });

  testWidgets('record control announces and updates its displayed chord', (tester) async {
    final semantics = tester.ensureSemantics();
    const initial = HotKey(key: PhysicalKeyboardKey.keyP, modifiers: [HotKeyModifier.control]);
    final initialValue = [
      physicalKeyLabel(PhysicalKeyboardKey.controlLeft),
      physicalKeyLabel(PhysicalKeyboardKey.keyP),
    ].join(' + ');
    expect(formatHotKeyDisplay(initial), initialValue);
    await _pumpRecorder(tester, saved: <HotKey?>[], currentHotKey: initial);

    Finder annotation(String label) =>
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

    var finder = annotation(t.hotkeys.pressToRecord);
    expect(finder, findsOneWidget);
    expect(tester.getSemantics(finder).getSemanticsData().value, initialValue);

    await tester.tap(find.byType(HotKeyRecorder));
    await tester.pump();
    finder = annotation(t.hotkeys.recordingShortcut);
    expect(finder, findsOneWidget);
    expect(tester.getSemantics(finder).getSemanticsData().value, initialValue);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyK, physicalKey: PhysicalKeyboardKey.keyK);
    await _pumpFocusChange(tester);

    const updated = HotKey(key: PhysicalKeyboardKey.keyK);
    final updatedValue = physicalKeyLabel(PhysicalKeyboardKey.keyK);
    expect(formatHotKeyDisplay(updated), updatedValue);
    finder = annotation(t.hotkeys.pressToRecord);
    expect(finder, findsOneWidget);
    expect(tester.getSemantics(finder).getSemanticsData().value, updatedValue);
    expect(find.bySemanticsLabel(updatedValue), findsNothing);
    semantics.dispose();
  });

  for (final entry in <(String, LogicalKeyboardKey, PhysicalKeyboardKey)>[
    ('Enter', LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter),
    ('select', LogicalKeyboardKey.select, PhysicalKeyboardKey.select),
  ]) {
    testWidgets('${entry.$1} completion does not rearm capture or activate Save on key-up', (tester) async {
      final saved = <HotKey?>[];
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
      expect(saved.single!.key, entry.$3);
      expect(saved.single!.modifiers, isNull);
    });
  }
}

Future<void> _pumpRecorder(
  WidgetTester tester, {
  required List<HotKey?> saved,
  HotKey? currentHotKey,
  VoidCallback? onCancel,
  FutureOr<void> Function(HotKey?)? onSave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HotKeyRecorderWidget(
          key: UniqueKey(),
          actionName: 'Play/Pause',
          currentHotKey: currentHotKey,
          onHotKeyRecorded: onSave ?? saved.add,
          onCancel: onCancel ?? () {},
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

DialogActionButton _cancelAction(WidgetTester tester) =>
    tester.widget(find.widgetWithText(DialogActionButton, t.common.cancel));
