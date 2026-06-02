import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    GamepadService.debugNativeTextInputFocusHandler = null;
  });

  testWidgets('tab traversal focuses the text form field', (tester) async {
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    final buttonFocusNode = FocusNode(debugLabel: 'find_server_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(buttonFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(labelText: 'Server URL'),
              ),
              FilledButton(focusNode: buttonFocusNode, onPressed: () {}, child: const Text('Find server')),
            ],
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(buttonFocusNode.hasFocus, isFalse);
  });

  testWidgets('focused text form field still receives select handling', (tester) async {
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    var selects = 0;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextFormField(controller: controller, focusNode: fieldFocusNode, onSelect: () => selects++),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(selects, 1);
  });

  testWidgets('d-pad direction handlers are installed on the text field focus node', (tester) async {
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'name_field');
    final nextFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(nextFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                onNavigateDown: nextFocusNode.requestFocus,
              ),
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    final handler = fieldFocusNode.onKeyEvent;

    expect(handler, isNotNull);
    final result = handler!(
      fieldFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
    await tester.pump();

    expect(result, KeyEventResult.handled);
    expect(nextFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('existing focus node key handler is preserved before text field navigation', (tester) async {
    final controller = TextEditingController();
    final handledKeys = <LogicalKeyboardKey>[];
    final fieldFocusNode = FocusNode(
      debugLabel: 'custom_field',
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
          handledKeys.add(event.logicalKey);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    final nextFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(nextFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                onNavigateDown: nextFocusNode.requestFocus,
              ),
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    final handler = fieldFocusNode.onKeyEvent!;

    final customResult = handler(
      fieldFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
    final navigationResult = handler(
      fieldFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
    await tester.pump();

    expect(customResult, KeyEventResult.handled);
    expect(handledKeys, [LogicalKeyboardKey.arrowUp]);
    expect(navigationResult, KeyEventResult.handled);
    expect(nextFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('tvOS focus opens virtual keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(controller: controller, focusNode: fieldFocusNode),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('hidden TV text field does not auto-open virtual keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController(text: 'query');
    final fieldFocusNode = FocusNode(debugLabel: 'hidden_search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    Future<void> pumpField({required bool visible}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: visible,
              child: FocusableTextField(controller: controller, focusNode: fieldFocusNode),
            ),
          ),
        ),
      );
    }

    await pumpField(visible: false);
    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);

    await pumpField(visible: true);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('TV virtual keyboard does not immediately reopen after dismissal', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(controller: controller, focusNode: fieldFocusNode),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Android TV native keyboard done uses D-pad navigation', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'name_field');
    final nextFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(nextFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                enableTvKeyboard: false,
                textInputAction: TextInputAction.done,
                onNavigateDown: nextFocusNode.requestFocus,
              ),
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(nextFocusNode.hasPrimaryFocus, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Android TV focus opens the TV virtual keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextFormField(controller: controller, focusNode: fieldFocusNode),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('Android TV after-first-focus skips initial auto-open and opens on refocus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    final otherFocusNode = FocusNode(debugLabel: 'find_server_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(otherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvKeyboardAutoOpenBehavior: TvKeyboardAutoOpenBehavior.afterFirstFocus,
              ),
              Focus(focusNode: otherFocusNode, child: const SizedBox(width: 1, height: 1)),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    otherFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(otherFocusNode.hasPrimaryFocus, isTrue);

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('Android TV after-first-focus opens on explicit select', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextFormField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvKeyboardAutoOpenBehavior: TvKeyboardAutoOpenBehavior.afterFirstFocus,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('Android TV remote keys are passed to native text input', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    final nextFocusNode = FocusNode(debugLabel: 'find_server_button');
    var selects = 0;
    var backs = 0;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(nextFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                enableTvKeyboard: false,
                onNavigateDown: nextFocusNode.requestFocus,
                onSelect: () => selects++,
                onBack: () => backs++,
              ),
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Find server')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    final handler = fieldFocusNode.onKeyEvent!;

    final downResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.arrowDown));
    final selectResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.select));
    final backResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.goBack));
    final keyboardDownResult = handler(fieldFocusNode, _keyboardDpadKey(LogicalKeyboardKey.arrowDown));
    final synthesizedSelectResult = handler(
      fieldFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.select,
        logicalKey: LogicalKeyboardKey.select,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
    );
    final keyboardBackResult = handler(fieldFocusNode, _keyboardDpadKey(LogicalKeyboardKey.goBack));
    await tester.pump();

    expect(downResult, KeyEventResult.skipRemainingHandlers);
    expect(selectResult, KeyEventResult.skipRemainingHandlers);
    expect(backResult, KeyEventResult.skipRemainingHandlers);
    expect(keyboardDownResult, KeyEventResult.skipRemainingHandlers);
    expect(synthesizedSelectResult, KeyEventResult.skipRemainingHandlers);
    expect(keyboardBackResult, KeyEventResult.skipRemainingHandlers);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(nextFocusNode.hasFocus, isFalse);
    expect(selects, 0);
    expect(backs, 0);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Android TV native text input focus is reported to platform', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    const channel = MethodChannel('com.plezy/text_input');
    final calls = <MethodCall>[];
    final gamepadFocusStates = <bool>[];
    GamepadService.debugNativeTextInputFocusHandler = (focused) async {
      gamepadFocusStates.add(focused);
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );

    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'server_url_field');
    final otherFocusNode = FocusNode(debugLabel: 'other');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(otherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextFormField(controller: controller, focusNode: fieldFocusNode, enableTvKeyboard: false),
              Focus(focusNode: otherFocusNode, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(calls.last.method, 'setNativeTextInputFocused');
    expect(calls.last.arguments, isTrue);
    expect(gamepadFocusStates, [true]);

    otherFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(calls.last.method, 'setNativeTextInputFocused');
    expect(calls.last.arguments, isFalse);
    expect(gamepadFocusStates, [true, false]);
  });

  testWidgets('Android TV physical keyboard text keys edit the TV field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'name_field');
    String? submitted;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(controller.text, 'a');
    expect(find.byType(Dialog), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(submitted, 'a');
    expect(controller.text, 'a');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Android TV physical keyboard backspace deletes existing text from end', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController(text: 'query');
    controller.selection = const TextSelection.collapsed(offset: 0);
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(controller: controller, focusNode: fieldFocusNode),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(controller.text, 'quer');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('tvOS engine-synthesized select is handled by the virtual keyboard', (tester) async {
    // The custom Flutter tvOS engine emits Siri Remote center-dpad presses
    // as `LogicalKeyboardKey.select` with `deviceType=keyboard` (via the
    // legacy `flutter/keyevent` Android DPAD_CENTER path). On Apple TV this
    // must open the on-screen keyboard, not submit the form. Previously
    // `isPhysicalKeyboardEnter` matched select+keyboard and routed through
    // `_submitTextInput`, which silently triggered form submit on every
    // dpad center press (e.g. immediate validation error on empty fields).
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController(text: 'query');
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    String? submitted;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(submitted, isNull);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('tvOS text field handles physical keyboard text editing through virtual keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    final changes = <String>[];
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[ab]'))],
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(controller.text, 'a');
    expect(find.byType(Dialog), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
    await tester.pumpAndSettle();

    expect(controller.text, 'ab');
    expect(changes, ['a', 'ab']);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(controller.text, 'a');

    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('tvOS keyboard enter inserts newline for multiline text field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController(text: 'a');
    final fieldFocusNode = FocusNode(debugLabel: 'notes_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            keyboardType: TextInputType.multiline,
            maxLines: 2,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.text, 'a\n');
    expect(find.byType(Dialog), findsNothing);
  });
}

Future<void> _setTvSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

KeyDownEvent _remoteKey(LogicalKeyboardKey key) {
  return KeyDownEvent(
    physicalKey: _physicalKeyFor(key),
    logicalKey: key,
    timeStamp: Duration.zero,
    deviceType: ui.KeyEventDeviceType.directionalPad,
  );
}

KeyDownEvent _keyboardDpadKey(LogicalKeyboardKey key) {
  return KeyDownEvent(
    physicalKey: _physicalKeyFor(key),
    logicalKey: key,
    timeStamp: Duration.zero,
    deviceType: ui.KeyEventDeviceType.keyboard,
  );
}

PhysicalKeyboardKey _physicalKeyFor(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowDown) return PhysicalKeyboardKey.arrowDown;
  if (key == LogicalKeyboardKey.goBack) return PhysicalKeyboardKey.escape;
  if (key == LogicalKeyboardKey.select) return PhysicalKeyboardKey.select;
  throw ArgumentError.value(key, 'key', 'Unsupported remote key');
}
