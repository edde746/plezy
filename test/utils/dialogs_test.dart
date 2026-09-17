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

  testWidgets('owned dialog cancels before its first build without removing its page', (tester) async {
    final hostContext = await _pumpHost(tester);
    final owner = ModalRoute.of(hostContext)!;
    final result = showScopedDialog<String>(
      context: hostContext,
      builder: (_) => const AlertDialog(title: Text('Pending owned dialog')),
    );

    dismissDialogsOwnedBy(owner);
    await tester.pumpAndSettle();

    await expectLater(result, completion(isNull));
    expect(find.text('Pending owned dialog'), findsNothing);
    expect(owner.isCurrent, isTrue);
    dismissDialogsOwnedBy(owner);
    expect(owner.isCurrent, isTrue);
  });

  testWidgets('owner cancellation releases a loading controller before its first build', (tester) async {
    final hostContext = await _pumpHost(tester);
    final controller = ScopedLoadingDialogController();
    var disposed = false;
    controller.show(
      hostContext,
      builder: (_) => const AlertDialog(title: Text('Pending loading dialog')),
      onDisposed: () => disposed = true,
    );
    final dismissal = controller.dismiss();

    dismissDialogsOwnedBy(ModalRoute.of(hostContext)!);
    await tester.pumpAndSettle();

    await expectLater(controller.ready, completes);
    await expectLater(dismissal, completes);
    expect(controller.isVisible, isFalse);
    expect(disposed, isTrue);
    expect(find.text('Pending loading dialog'), findsNothing);
    expect(ModalRoute.of(hostContext)!.isCurrent, isTrue);
  });

  testWidgets('owner cancellation includes nested dialogs', (tester) async {
    final hostContext = await _pumpHost(tester);
    late BuildContext outerContext;
    final outerResult = showScopedDialog<String>(
      context: hostContext,
      builder: (context) {
        outerContext = context;
        return const AlertDialog(title: Text('Outer owned dialog'));
      },
    );
    await tester.pumpAndSettle();
    final innerResult = showScopedDialog<String>(
      context: outerContext,
      builder: (_) => const AlertDialog(title: Text('Inner owned dialog')),
    );
    await tester.pumpAndSettle();

    dismissDialogsOwnedBy(ModalRoute.of(hostContext)!);
    await tester.pumpAndSettle();

    await expectLater(outerResult, completion(isNull));
    await expectLater(innerResult, completion(isNull));
    expect(find.byType(AlertDialog), findsNothing);
    expect(ModalRoute.of(hostContext)!.isCurrent, isTrue);
  });

  testWidgets('nested dialog retains ownership after its parent completes', (tester) async {
    final hostContext = await _pumpHost(tester);
    late BuildContext outerContext;
    final outerResult = showScopedDialog<String>(
      context: hostContext,
      builder: (context) {
        outerContext = context;
        return const AlertDialog(title: Text('Outer owned dialog'));
      },
    );
    await tester.pumpAndSettle();
    final innerResult = showScopedDialog<String>(
      context: outerContext,
      builder: (_) => const AlertDialog(title: Text('Inner owned dialog')),
    );
    await tester.pumpAndSettle();
    Navigator.of(outerContext).removeRoute(ModalRoute.of(outerContext)!, 'Parent result');
    await tester.pumpAndSettle();
    await expectLater(outerResult, completion('Parent result'));

    dismissDialogsOwnedBy(ModalRoute.of(hostContext)!);
    await tester.pumpAndSettle();

    await expectLater(innerResult, completion(isNull));
    expect(find.byType(AlertDialog), findsNothing);
    expect(ModalRoute.of(hostContext)!.isCurrent, isTrue);
  });

  testWidgets('owner cancellation preserves unrelated dialogs and intervening pages', (tester) async {
    final hostContext = await _pumpHost(tester);
    final owner = ModalRoute.of(hostContext)!;
    final ownedResult = showScopedDialog<String>(
      context: hostContext,
      builder: (_) => const AlertDialog(title: Text('Owned dialog')),
    );
    await tester.pumpAndSettle();
    late BuildContext pageContext;
    final pageResult = Navigator.of(hostContext).push<String>(
      MaterialPageRoute(
        builder: (context) {
          pageContext = context;
          return const Scaffold(body: Text('Unrelated page'));
        },
      ),
    );
    await tester.pumpAndSettle();
    final unrelatedResult = showScopedDialog<String>(
      context: pageContext,
      builder: (context) => AlertDialog(
        title: const Text('Unrelated dialog'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop('Dialog result'), child: const Text('Keep result')),
        ],
      ),
    );
    await tester.pumpAndSettle();

    dismissDialogsOwnedBy(owner);
    await tester.pumpAndSettle();

    await expectLater(ownedResult, completion(isNull));
    expect(find.text('Owned dialog', skipOffstage: false), findsNothing);
    expect(find.text('Unrelated dialog'), findsOneWidget);
    await tester.tap(find.text('Keep result'));
    await tester.pumpAndSettle();
    await expectLater(unrelatedResult, completion('Dialog result'));
    expect(find.text('Unrelated page'), findsOneWidget);
    Navigator.of(pageContext).pop('Page result');
    await tester.pumpAndSettle();
    await expectLater(pageResult, completion('Page result'));
    expect(owner.isCurrent, isTrue);
  });

  testWidgets('owner cancellation leaves another navigator dialog open', (tester) async {
    late BuildContext leftContext;
    late BuildContext rightContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) {
                    leftContext = context;
                    return const Scaffold(body: Text('Left page'));
                  },
                ),
              ),
            ),
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) {
                    rightContext = context;
                    return const Scaffold(body: Text('Right page'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final leftResult = showScopedDialog<String>(
      context: leftContext,
      builder: (_) => const AlertDialog(title: Text('Left dialog')),
    );
    final rightResult = showScopedDialog<String>(
      context: rightContext,
      builder: (context) => AlertDialog(
        title: const Text('Right dialog'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop('Right result'), child: const Text('Keep right')),
        ],
      ),
    );
    await tester.pumpAndSettle();

    dismissDialogsOwnedBy(ModalRoute.of(leftContext)!);
    await tester.pumpAndSettle();

    await expectLater(leftResult, completion(isNull));
    expect(find.text('Left dialog'), findsNothing);
    expect(find.text('Right dialog'), findsOneWidget);
    expect(find.text('Left page'), findsOneWidget);
    await tester.tap(find.text('Keep right'));
    await tester.pumpAndSettle();
    await expectLater(rightResult, completion('Right result'));
    expect(find.text('Right page'), findsOneWidget);
  });

  testWidgets('scoped dialog captures its source theme and keeps keyboard traversal inside', (tester) async {
    final firstFocus = FocusNode();
    final lastFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(lastFocus.dispose);
    late BuildContext hostContext;
    const sourceColor = Colors.deepPurple;
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: sourceColor, primary: sourceColor),
          ),
          child: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: TextField());
            },
          ),
        ),
      ),
    );
    final result = showScopedDialog<String>(
      context: hostContext,
      builder: (context) => AlertDialog(
        title: Text('Themed dialog', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        actions: [
          TextButton(autofocus: true, focusNode: firstFocus, onPressed: () {}, child: const Text('First')),
          TextButton(
            focusNode: lastFocus,
            onPressed: () => Navigator.of(context).pop('Selected'),
            child: const Text('Last'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('Themed dialog')).style!.color, sourceColor);
    expect(firstFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(lastFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(firstFocus.hasPrimaryFocus, isTrue);
    await tester.tap(find.text('Last'));
    await tester.pumpAndSettle();
    await expectLater(result, completion('Selected'));
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
