import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    GamepadService.debugNativeTextInputFocusHandler = null;
    // TV back tests arm the suppressor on KeyDown; a test ending mid-press
    // would leak the armed state into the next test (flutter_test clears the
    // hardware observer that would otherwise end it with the press).
    BackKeyUpSuppressor.clearSuppression();
    BackKeyCoordinator.clear();
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
              child: FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
              ),
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

  testWidgets('TV virtual keyboard closes when its owning field unmounts', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    Future<void> pumpField({required bool present}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: present
                ? FocusableTextField(
                    controller: controller,
                    focusNode: fieldFocusNode,
                    tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }

    await pumpField(present: true);
    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    // Swap the field out while the keyboard is up — the keyboard must follow.
    await pumpField(present: false);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
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
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
          ),
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

  testWidgets('Apple TV automatic single-line input uses the platform field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_name_field');
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
    await _raiseNativeInput(tester);

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
  });

  testWidgets('Apple TV native Done deactivates input before D-pad navigation', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final nextFocusNode = FocusNode(debugLabel: 'save_button');
    var completed = 0;
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
                textInputAction: TextInputAction.done,
                onEditingComplete: () => completed++,
                onNavigateDown: nextFocusNode.requestFocus,
              ),
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(completed, 1);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(nextFocusNode.hasPrimaryFocus, isTrue);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
  });

  testWidgets('Apple TV native Go submits once and deactivates input', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController(text: 'https://jellyfin.example.com');
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final submissions = <String>[];
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextFormField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.platform,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: submissions.add,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    expect(submissions, ['https://jellyfin.example.com']);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);

    tester.testTextInput.closeConnection();
    await tester.pump();
    expect(submissions, ['https://jellyfin.example.com']);
  });

  testWidgets('Apple TV native submit fires both onEditingComplete and onSubmitted', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController(text: 'https://jellyfin.example.com');
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final submissions = <String>[];
    var completed = 0;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextFormField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.platform,
            textInputAction: TextInputAction.go,
            onEditingComplete: () => completed++,
            onFieldSubmitted: submissions.add,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    // EditableText calls the two independently; withholding onSubmitted from
    // the widget on the native path must not collapse them into an either/or.
    expect(completed, 1);
    expect(submissions, ['https://jellyfin.example.com']);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('Apple TV keeps field focus when the platform dismisses the keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final nextFocusNode = FocusNode(debugLabel: 'save_button');
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
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    // UIKit dismissing the tvOS keyboard closes the connection with no
    // performAction; EditableText.connectionClosed then unfocuses the field.
    tester.testTextInput.log.clear();
    tester.testTextInput.closeConnection();
    await tester.pumpAndSettle();

    expect(fieldFocusNode.hasPrimaryFocus, isTrue, reason: 'dismissal must not strand focus');
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    final afterDismissal = tester.testTextInput.log.map((call) => call.method);
    expect(afterDismissal, isNot(contains('TextInput.setClient')));
    expect(afterDismissal, isNot(contains('TextInput.show')));

    // The field is still usable: Select raises input again, D-pad still leaves.
    await _raiseNativeInput(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(nextFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('Apple TV dismissal does not steal focus from a scope claimed meanwhile', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final rivalScope = FocusScopeNode(debugLabel: 'rival_sheet_scope');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(rivalScope.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(controller: controller, focusNode: fieldFocusNode),
              FocusScope(node: rivalScope, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    // The connection closes and another scope — a sheet or dialog — becomes
    // primary before the restore callback runs. `primaryFocus is FocusScopeNode`
    // would be satisfied by that rival scope; only identity with the field's
    // own enclosing scope may trigger a restore.
    tester.testTextInput.closeConnection();
    rivalScope.requestFocus();
    await tester.pumpAndSettle();

    expect(rivalScope.hasFocus, isTrue);
    expect(fieldFocusNode.hasPrimaryFocus, isFalse, reason: 'must not steal focus from the rival scope');
  });

  testWidgets('Apple TV first focus opens once, dismissal and refocus stay closed, Select reopens', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_field');
    final otherFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(otherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Defaulted: exercises `automatic` opening only on first focus.
              FocusableTextField(controller: controller, focusNode: fieldFocusNode),
              Focus(focusNode: otherFocusNode, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    bool readOnly() => tester.widget<TextField>(find.byType(TextField)).readOnly;
    List<String> drain() {
      final methods = tester.testTextInput.log.map((call) => call.method).toList();
      tester.testTextInput.log.clear();
      return methods;
    }

    // 1. First focus raises input once.
    drain();
    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(readOnly(), isFalse, reason: 'first focus should open');
    expect(drain().where((m) => m == 'TextInput.show'), hasLength(1));

    // 2. UIKit dismissal keeps focus and does not reopen.
    tester.testTextInput.closeConnection();
    await tester.pumpAndSettle();
    expect(fieldFocusNode.hasPrimaryFocus, isTrue, reason: 'dismissal must not strand focus');
    expect(readOnly(), isTrue);
    expect(drain(), isNot(contains('TextInput.show')));

    // 3. Navigating away and back stays closed.
    otherFocusNode.requestFocus();
    await tester.pumpAndSettle();
    drain();
    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(readOnly(), isTrue, reason: 'refocus must not reopen');
    expect(drain(), isNot(contains('TextInput.show')));

    // 4. Select always reopens.
    await _raiseNativeInput(tester);
    expect(readOnly(), isFalse);
  });

  testWidgets('Apple TV controller closes native input without losing field focus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final textInputController = TvTextInputController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputController: textInputController,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    textInputController.closeTextInput();
    await tester.pump();

    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('Apple TV navigation resumes after native keyboard dismissal', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final nextFocusNode = FocusNode(debugLabel: 'save_button');
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
              FilledButton(focusNode: nextFocusNode, onPressed: () {}, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    final result = fieldFocusNode.onKeyEvent!(fieldFocusNode, _remoteKey(LogicalKeyboardKey.arrowDown));
    await tester.pumpAndSettle();

    expect(result, KeyEventResult.handled);
    expect(nextFocusNode.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('Apple TV Menu dismissal does not also invoke app back', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    var backCount = 0;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(controller: controller, focusNode: fieldFocusNode, onBack: () => backCount++),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _raiseNativeInput(tester);

    final result = fieldFocusNode.onKeyEvent!(fieldFocusNode, _remoteKey(LogicalKeyboardKey.goBack));
    await tester.pumpAndSettle();

    expect(result, KeyEventResult.handled);
    expect(backCount, 0);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    final secondResult = fieldFocusNode.onKeyEvent!(fieldFocusNode, _remoteKey(LogicalKeyboardKey.goBack));
    await tester.pump();

    expect(secondResult, KeyEventResult.handled);
    expect(backCount, 1);
  });

  testWidgets('Apple TV Select reopens native input after dismissal', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
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
    // Raise input first; the Select below is the one that reproduces a UIKit
    // dismissal arriving while Flutter still believes input is active.
    await _raiseNativeInput(tester);

    final result = fieldFocusNode.onKeyEvent!(fieldFocusNode, _remoteKey(LogicalKeyboardKey.select));
    await tester.pump();

    expect(result, KeyEventResult.handled);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });

  testWidgets('Apple TV after-first-focus waits for explicit Select', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
  });

  testWidgets('Apple TV after-first-focus auto-opens on refocus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_url_field');
    final otherFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(otherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
              ),
              Focus(focusNode: otherFocusNode, child: const SizedBox(width: 1, height: 1)),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    otherFocusNode.requestFocus();
    await tester.pumpAndSettle();
    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });

  testWidgets('Apple TV automatic auto-open fires once, then stays closed on every refocus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'native_field');
    final otherFocusNode = FocusNode(debugLabel: 'next_button');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(otherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // No tvTextInputAutoOpenBehavior: exercises the `automatic`
              // default, which opens only on first focus on native tvOS.
              FocusableTextField(controller: controller, focusNode: fieldFocusNode),
              Focus(focusNode: otherFocusNode, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    bool readOnly() => tester.widget<TextField>(find.byType(TextField)).readOnly;

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(readOnly(), isFalse, reason: 'first focus should raise input');

    // Every later entry stays closed. Reopening on every focus entry is what
    // made D-pad traversal of a form unusable; `afterFirstFocus` would also
    // reopen from entry 2 onwards.
    for (var entry = 2; entry <= 4; entry++) {
      otherFocusNode.requestFocus();
      await tester.pumpAndSettle();
      fieldFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(readOnly(), isTrue, reason: 'focus entry $entry must not raise the system keyboard');
    }

    await _raiseNativeInput(tester);
    expect(readOnly(), isFalse);
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
                tvTextInputPresentation: TvTextInputPresentation.platform,
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

  testWidgets('Android TV automatic single-line input uses the platform field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
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

    // `automatic` opens the docked native IME on focus: the read-only
    // activation gate lifts and no Flutter overlay may appear.
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
  });

  testWidgets('Android TV automatic multiline input uses the platform field', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController();
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
            maxLines: 4,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();

    // Unlike Apple TV's modal fullscreen keyboard, the docked Android IME
    // hosts multiline input natively — no Flutter overlay.
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
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
                tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
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
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
            tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
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

  testWidgets('Android TV dismissed-keyboard remote keys navigate, reopen, and consume back', (tester) async {
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
                tvTextInputPresentation: TvTextInputPresentation.platform,
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

    // `automatic` auto-open activates the native session on focus.
    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    final handler = fieldFocusNode.onKeyEvent!;

    // Remote keys reach Flutter only when the IME is not consuming them
    // (keyboard dismissed, or a broken key session already repaired and eaten
    // by MainActivity). Back closes the session and is consumed once so the
    // same press cannot also pop the route underneath.
    final backResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.goBack));
    await tester.pump();
    expect(backResult, KeyEventResult.handled);
    expect(backs, 0);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);

    // Session closed: the next back reaches the field's own onBack.
    final secondBackResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.goBack));
    await tester.pump();
    expect(secondBackResult, KeyEventResult.handled);
    expect(backs, 1);

    // Select re-raises the keyboard (activation), not onSelect.
    final selectResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.select));
    await tester.pump();
    expect(selectResult, KeyEventResult.handled);
    expect(selects, 0);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    // Chromecast remotes report Select with a keyboard deviceType; while the
    // session is live it must still read as a reopen request, not onSelect.
    final synthesizedSelectResult = handler(
      fieldFocusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.select,
        logicalKey: LogicalKeyboardKey.select,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(synthesizedSelectResult, KeyEventResult.handled);
    expect(selects, 0);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    // Down while the session is live navigates instead of dead-ending behind
    // a keyboard that is not there (#1079's trap).
    final downResult = handler(fieldFocusNode, _remoteKey(LogicalKeyboardKey.arrowDown));
    await tester.pump();
    expect(downResult, KeyEventResult.handled);
    expect(nextFocusNode.hasPrimaryFocus, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Android TV back that moves focus off the field cannot double-fire on the orphaned KeyUp', (
    tester,
  ) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    addTearDown(BackKeyCoordinator.clear);
    addTearDown(BackKeyUpSuppressor.clearSuppression);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    final sidebarFocusNode = FocusNode(debugLabel: 'sidebar');
    var fieldBacks = 0;
    var sidebarBacks = 0;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);
    addTearDown(sidebarFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.platform,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.never,
                onBack: () {
                  fieldBacks++;
                  sidebarFocusNode.requestFocus();
                },
              ),
              // The destination focus chain runs the shared handler's KeyUp
              // semantics — the SearchScreen sidebar shape.
              Focus(
                focusNode: sidebarFocusNode,
                onKeyEvent: (node, event) => handleBackKeyAction(event, () => sidebarBacks++),
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();

    // TV back acts on KeyDown; onBack leaves the empty field for the sidebar.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fieldBacks, 1);
    expect(sidebarFocusNode.hasPrimaryFocus, isTrue);

    // The matching KeyUp is delivered to the NEW focus chain and must be
    // swallowed there — one press, one action.
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sidebarBacks, 0, reason: 'the KeyUp of a press the field already handled must not run a second back');

    // Anti-pinning: a full follow-up press works normally on the sidebar.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(sidebarBacks, 1);
    expect(fieldBacks, 1);
  });

  testWidgets('Android TV stale back suppression never swallows the next press', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    addTearDown(BackKeyCoordinator.clear);
    addTearDown(BackKeyUpSuppressor.clearSuppression);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    final buttonFocusNode = FocusNode(debugLabel: 'plain_button');
    var fieldBacks = 0;
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
                tvTextInputPresentation: TvTextInputPresentation.platform,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.never,
                onBack: () {
                  fieldBacks++;
                  buttonFocusNode.requestFocus();
                },
              ),
              // No suppressor-aware handler here: the armed state goes stale
              // because the KeyUp is never consumed anywhere.
              FilledButton(focusNode: buttonFocusNode, onPressed: () {}, child: const Text('Plain')),
            ],
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fieldBacks, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    // The stale armed suppressor must clear itself on the next KeyDown
    // without consuming it — the second press still runs onBack.
    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fieldBacks, 2, reason: 'a stray armed suppressor must never swallow a fresh press');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
  });

  testWidgets('Android TV platform focus hint tracks activation, not focus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    const channel = MethodChannel('com.plezy/text_input');
    final sentStates = <bool>[];
    GamepadService.debugNativeTextInputFocusHandler = (_) async {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setNativeTextInputFocused') sentStates.add(call.arguments as bool);
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
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.platform,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
              ),
              Focus(focusNode: otherFocusNode, child: const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    // First focus is suppressed by afterFirstFocus: no live input session, so
    // the platform hint stays silent — MainActivity keeps the pre-IME D-pad
    // intercept and the gamepad bridge active for plain navigation.
    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(sentStates, isEmpty);

    // An explicit Select opens the session: only now does the platform learn
    // about it (arming the soft-input show-retry in MainActivity).
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump();
    expect(sentStates, [true]);

    otherFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(sentStates, [true, false]);
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
              FocusableTextFormField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.platform,
              ),
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
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
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
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
          ),
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

  testWidgets('tvOS synthesized Select opens an explicit Flutter overlay', (tester) async {
    // The custom Flutter tvOS engine emits Siri Remote center-dpad presses
    // as `LogicalKeyboardKey.select` with `deviceType=keyboard` (via the
    // legacy `flutter/keyevent` path). Fields that explicitly retain Plezy's
    // Flutter overlay must open it rather than submit the form.
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
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
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
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
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

  testWidgets('TV hardware input replaces a reversed text selection', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final controller = TextEditingController(text: 'ab')
      ..selection = const TextSelection(baseOffset: 2, extentOffset: 0);
    final fieldFocusNode = FocusNode(debugLabel: 'selection_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
    await tester.pump();

    expect(controller.text, 'c');
    expect(controller.selection, const TextSelection.collapsed(offset: 1));
  });

  testWidgets('TV hardware caret and deletion stay on grapheme boundaries', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    final controller = TextEditingController();
    final fieldFocusNode = FocusNode(debugLabel: 'grapheme_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
            tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.never,
          ),
        ),
      ),
    );
    fieldFocusNode.requestFocus();
    await tester.pump();

    for (final grapheme in ['😀', 'e\u0301', '🇯🇵', '👨‍👩‍👧‍👦']) {
      final text = 'A${grapheme}B';
      final graphemeEnd = 1 + grapheme.length;

      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: graphemeEnd),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(controller.selection, TextSelection.collapsed(offset: graphemeEnd));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(controller.selection, TextSelection.collapsed(offset: text.length));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(controller.selection, TextSelection.collapsed(offset: text.length));

      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(controller.selection, TextSelection.collapsed(offset: graphemeEnd));

      controller.value = TextEditingValue(text: text, selection: const TextSelection.collapsed(offset: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.text, text);
      expect(controller.selection, const TextSelection.collapsed(offset: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(controller.text, '${grapheme}B');
      expect(controller.selection, const TextSelection.collapsed(offset: 0));

      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: graphemeEnd),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.text, 'AB');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));

      controller.value = TextEditingValue(text: text, selection: const TextSelection.collapsed(offset: 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(controller.text, 'AB');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));

      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: graphemeEnd - 1, extentOffset: 1),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.text, 'AB');
      expect(controller.selection, const TextSelection.collapsed(offset: 1));
    }
  });

  testWidgets('grapheme deletion preserves formatter and callback ordering', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    const grapheme = '👨‍👩‍👧‍👦';
    final text = 'A${grapheme}B';
    final controller = TextEditingController(text: text);
    final fieldFocusNode = FocusNode(debugLabel: 'formatted_grapheme_field');
    final formatterCandidates = <TextEditingValue>[];
    final changes = <String>[];
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
            tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.never,
            maxLength: 8,
            inputFormatters: [
              TextInputFormatter.withFunction((_, nextValue) {
                formatterCandidates.add(nextValue);
                return nextValue;
              }),
            ],
            onChanged: changes.add,
          ),
        ),
      ),
    );
    fieldFocusNode.requestFocus();
    await tester.pump();
    controller.selection = TextSelection.collapsed(offset: 1 + grapheme.length);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);

    expect(formatterCandidates.single.text, 'AB');
    expect(controller.text, 'AB');
    expect(controller.selection, const TextSelection.collapsed(offset: 1));
    expect(changes, ['AB']);
  });
  testWidgets('TV keyboard done resolves callbacks against the latest field widget', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController(text: 'query');
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    var navigateDownCalls = 0;
    VoidCallback? onNavigateDown;
    late StateSetter rebuild;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                textInputAction: TextInputAction.search,
                onNavigateDown: onNavigateDown,
              );
            },
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    // Simulates search results arriving while the keyboard is open: the field
    // rebuilds and only now gains an onNavigateDown callback.
    rebuild(() => onNavigateDown = () => navigateDownCalls++);
    await tester.pump();

    await tester.tap(_tvKeyboardDoneKey(Symbols.search_rounded));
    await tester.pumpAndSettle();

    expect(navigateDownCalls, 1);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(controller.text, 'query');
  });

  testWidgets('TV keyboard done prefers the latest onSubmitted over navigation', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController(text: 'query');
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    String? submitted;
    var navigateDownCalls = 0;
    ValueChanged<String>? onSubmitted;
    VoidCallback? onNavigateDown;
    late StateSetter rebuild;
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FocusableTextField(
                controller: controller,
                focusNode: fieldFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
                onNavigateDown: onNavigateDown,
              );
            },
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    rebuild(() {
      onSubmitted = (value) => submitted = value;
      onNavigateDown = () => navigateDownCalls++;
    });
    await tester.pump();

    await tester.tap(_tvKeyboardDoneKey(Symbols.search_rounded));
    await tester.pumpAndSettle();

    expect(submitted, 'query');
    expect(navigateDownCalls, 0);
  });

  testWidgets('TV keyboard stays closed when done keeps field focus', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    await _setTvSurfaceSize(tester);
    final controller = TextEditingController(text: 'query');
    final fieldFocusNode = FocusNode(debugLabel: 'search_field');
    addTearDown(controller.dispose);
    addTearDown(fieldFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableTextField(
            controller: controller,
            focusNode: fieldFocusNode,
            tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
            textInputAction: TextInputAction.search,
            onEditingComplete: () {},
          ),
        ),
      ),
    );

    fieldFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    await tester.tap(_tvKeyboardDoneKey(Symbols.search_rounded));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(fieldFocusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
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

Finder _tvKeyboardDoneKey(IconData icon) {
  return find.descendant(of: find.byKey(const Key('tv_virtual_keyboard_panel')), matching: find.byIcon(icon));
}

/// Native tvOS input no longer auto-opens on focus — `automatic` resolves to
/// `never` there, because the system keyboard is modal and would make D-pad
/// traversal of a form impossible. An explicit Select raises it, as on device.
Future<void> _raiseNativeInput(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.select);
  await tester.pumpAndSettle();
}

KeyDownEvent _remoteKey(LogicalKeyboardKey key) {
  return KeyDownEvent(
    physicalKey: _physicalKeyFor(key),
    logicalKey: key,
    timeStamp: Duration.zero,
    deviceType: ui.KeyEventDeviceType.directionalPad,
  );
}

PhysicalKeyboardKey _physicalKeyFor(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowDown) return PhysicalKeyboardKey.arrowDown;
  if (key == LogicalKeyboardKey.goBack) return PhysicalKeyboardKey.escape;
  if (key == LogicalKeyboardKey.select) return PhysicalKeyboardKey.select;
  throw ArgumentError.value(key, 'key', 'Unsupported remote key');
}
