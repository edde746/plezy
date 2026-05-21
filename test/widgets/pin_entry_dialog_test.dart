import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/screens/profile/pin_entry_dialog.dart';
import 'package:vibe_stream/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('mobile PIN entry keeps one focused text field while entering digits', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false);
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showPinEntryDialog(context, 'Protected Profile');
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);

    final focusNode = tester.widget<TextField>(field).focusNode;
    expect(focusNode, isNotNull);
    expect(focusNode!.hasFocus, isTrue);

    await tester.enterText(field, '1');
    await tester.pump();

    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode, same(focusNode));
    expect(focusNode.hasFocus, isTrue);

    await tester.enterText(field, '12');
    await tester.pump();

    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode, same(focusNode));
    expect(focusNode.hasFocus, isTrue);

    await tester.enterText(field, '1234');
    await tester.pumpAndSettle();

    expect(result, '1234');
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('mobile duplicate submit does not pop route below PIN dialog', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false);
    String? pinResult;
    bool? boolRouteResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  boolRouteResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (routeContext) {
                        return Scaffold(
                          body: Column(
                            children: [
                              const Text('Bool Route'),
                              TextButton(
                                onPressed: () async {
                                  pinResult = await showPinEntryDialog(routeContext, 'Protected Profile');
                                },
                                child: const Text('Open PIN'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open Bool Route'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Bool Route'));
    await tester.pumpAndSettle();

    expect(find.text('Bool Route'), findsOneWidget);

    await tester.tap(find.text('Open PIN'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.showKeyboard(field);
    await tester.enterText(field, '1234');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(pinResult, '1234');
    expect(boolRouteResult, isNull);
    expect(find.text('Bool Route'), findsOneWidget);
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('D-pad keypad enters and submits PIN', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    String? result;

    await _pumpPinDialogLauncher(tester, onResult: (pin) => result = pin);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);

    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 1
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 2
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 3
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 4
    await tester.pumpAndSettle();

    expect(result, '1234');
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('Android TV keyboard-mapped enter/select activates highlighted PIN key', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    String? result;

    await _pumpPinDialogLauncher(tester, onResult: (pin) => result = pin);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter); // 1
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 2
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter); // 3
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 4
    await tester.pumpAndSettle();

    expect(result, '1234');
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('TV PIN keypad reclaims focus after activation', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final underlyingFocusNode = FocusNode(debugLabel: 'UnderlyingProfileScreen');
    final leakedKeys = <LogicalKeyboardKey>[];
    String? result;
    addTearDown(underlyingFocusNode.dispose);

    await _pumpPinDialogLauncher(
      tester,
      onResult: (pin) => result = pin,
      underlyingFocusNode: underlyingFocusNode,
      onUnderlyingKey: (_, event) {
        if (event is KeyDownEvent) leakedKeys.add(event.logicalKey);
        return KeyEventResult.handled;
      },
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter); // 1
    underlyingFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 2
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 3
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressKeyboardMappedKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select); // 4
    await tester.pumpAndSettle();

    expect(result, '1234');
    expect(leakedKeys, isEmpty);
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('non-mobile PIN entry accepts physical keyboard digits', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    String? result;

    await _pumpPinDialogLauncher(tester, onResult: (pin) => result = pin);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _pressKey(tester, LogicalKeyboardKey.digit1);
    await _pressKey(tester, LogicalKeyboardKey.digit2);
    await _pressKey(tester, LogicalKeyboardKey.backspace);
    await _pressKey(tester, LogicalKeyboardKey.digit3);
    await _pressKey(tester, LogicalKeyboardKey.digit4);
    await _pressKey(tester, LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();

    expect(result, '1345');
    expect(find.byType(PinEntryDialog), findsNothing);
  });

  testWidgets('D-pad close key cancels PIN dialog', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    var completed = false;
    String? result = 'unchanged';

    await _pumpPinDialogLauncher(
      tester,
      onResult: (pin) {
        completed = true;
        result = pin;
      },
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _pressDpadKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressDpadKey(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await _pressDpadKey(tester, LogicalKeyboardKey.select, PhysicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(PinEntryDialog), findsNothing);
  });
}

Future<void> _pumpPinDialogLauncher(
  WidgetTester tester, {
  required ValueChanged<String?> onResult,
  FocusNode? underlyingFocusNode,
  FocusOnKeyEventCallback? onUnderlyingKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          Widget body = TextButton(
            onPressed: () async {
              onResult(await showPinEntryDialog(context, 'Protected Profile'));
            },
            child: const Text('Open'),
          );
          if (underlyingFocusNode != null) {
            body = Focus(focusNode: underlyingFocusNode, onKeyEvent: onUnderlyingKey, child: body);
          }
          return Scaffold(body: body);
        },
      ),
    ),
  );
}

Future<void> _pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _pressDpadKey(WidgetTester tester, LogicalKeyboardKey logicalKey, PhysicalKeyboardKey physicalKey) async {
  _dispatchKey(
    KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration.zero,
      deviceType: ui.KeyEventDeviceType.directionalPad,
    ),
  );
  await tester.pump();
}

Future<void> _pressKeyboardMappedKey(
  WidgetTester tester,
  LogicalKeyboardKey logicalKey,
  PhysicalKeyboardKey physicalKey,
) async {
  _dispatchKey(
    KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration.zero,
      deviceType: ui.KeyEventDeviceType.keyboard,
    ),
  );
  await tester.pump();
}

KeyEventResult _dispatchKey(KeyEvent event) {
  FocusNode? node = FocusManager.instance.primaryFocus;
  while (node != null) {
    final result = node.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    if (result == KeyEventResult.handled) return result;
    node = node.parent;
  }
  return KeyEventResult.ignored;
}
