import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/dialogs.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
  });

  testWidgets('text input dialog returns submitted text', (tester) async {
    final hostContext = await _pumpHost(tester);
    final result = showTextInputDialog(hostContext, title: 'Name', labelText: 'Name');

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New name');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await expectLater(result, completion('New name'));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('text input dialog returns null when cancelled', (tester) async {
    final hostContext = await _pumpHost(tester);
    final result = showTextInputDialog(hostContext, title: 'Name', labelText: 'Name');

    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await expectLater(result, completion(isNull));
  });

  testWidgets('text input dialog shows validation errors and stays open', (tester) async {
    final hostContext = await _pumpHost(tester);
    final result = showTextInputDialog(
      hostContext,
      title: 'Name',
      labelText: 'Name',
      validator: (value) => value.length < 3 ? 'Too short' : null,
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Too short'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'valid');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await expectLater(result, completion('valid'));
  });

  testWidgets('text input dialog seeds multiline initial value', (tester) async {
    final hostContext = await _pumpHost(tester);
    final result = showTextInputDialog(
      hostContext,
      title: 'Summary',
      labelText: 'Summary',
      initialValue: 'Line one\nLine two',
      allowEmpty: true,
      multiline: true,
    );

    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Line one\nLine two');
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.maxLines, 8);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await expectLater(result, completion('Line one\nLine two'));
  });

  testWidgets('TV back closes keyboard, restores field focus, then cancels dialog', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final hostContext = await _pumpHost(tester);
    final result = showTextInputDialog(hostContext, title: 'Name', labelText: 'Name', initialValue: 'TV value');

    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField, skipOffstage: false));
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(field.focusNode?.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await expectLater(result, completion(isNull));
    expect(find.byType(AlertDialog), findsNothing);
  });
}

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return hostContext;
}
