import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
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
    final fieldFinder = find.byType(TextField, skipOffstage: false);
    final field = tester.widget<TextField>(fieldFinder);
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(field.readOnly, isFalse);
    await tester.showKeyboard(fieldFinder);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(field.focusNode?.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await expectLater(result, completion(isNull));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('media-unreadable dialog names the server-side cause and cannot be dismissed by the barrier', (
    tester,
  ) async {
    final hostContext = await _pumpHost(tester);
    final result = showMediaUnreadableDialog(hostContext);
    await tester.pumpAndSettle();

    expect(find.text(t.messages.mediaUnreadableTitle), findsOneWidget);
    // The body has to say what a 404 on the stream actually means, because the
    // only recovery is on the server (#1750).
    expect(find.textContaining('HTTP 404'), findsOneWidget);
    expect(find.textContaining('could not read'), findsOneWidget);

    // Barrier taps must not strand the caller's future.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text(t.common.close));
    await tester.pumpAndSettle();
    await expectLater(result, completes);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('server-limit dialog stays distinct from the media-unreadable one', (tester) async {
    final hostContext = await _pumpHost(tester);
    final result = showServerLimitDialog(hostContext);
    await tester.pumpAndSettle();

    expect(find.text(t.messages.serverLimitTitle), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.text(t.messages.mediaUnreadableTitle), findsNothing);

    await tester.tap(find.text(t.common.close));
    await tester.pumpAndSettle();
    await expectLater(result, completes);
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
