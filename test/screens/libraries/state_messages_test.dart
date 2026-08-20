import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/libraries/state_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('StateMessageWidget forwards action focus behavior to FocusableButton', (tester) async {
    await _pump(
      tester,
      StateMessageWidget(
        message: 'Nothing here',
        actionLabel: 'Reload',
        onAction: () {},
        actionAutofocus: true,
        actionUseBackgroundFocus: true,
      ),
    );

    final button = tester.widget<FocusableButton>(find.byType(FocusableButton));
    expect(button.autofocus, isTrue);
    expect(button.useBackgroundFocus, isTrue);

    final focusedNode = FocusManager.instance.primaryFocus;
    expect(focusedNode, isNotNull);
    final focusedWidget = find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode == focusedNode);
    expect(focusedWidget, findsOneWidget);
    expect(find.ancestor(of: focusedWidget, matching: find.byType(FocusableButton)), findsOneWidget);
  });

  testWidgets('ErrorStateWidget retry supports D-pad and pointer activation', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      ErrorStateWidget(
        message: 'Could not load',
        retryLabel: 'Try again',
        onRetry: () => retries++,
        actionAutofocus: true,
        actionUseBackgroundFocus: true,
      ),
    );

    final button = tester.widget<FocusableButton>(find.byType(FocusableButton));
    expect(button.autofocus, isTrue);
    expect(button.useBackgroundFocus, isTrue);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(retries, 2);
  });

  group('ErrorStateWidget localized defaults', () {
    setUp(() async {
      await LocaleSettings.setLocale(AppLocale.es);
    });

    testWidgets('uses the localized default retry label', (tester) async {
      await _pump(tester, ErrorStateWidget(message: 'No se pudo cargar', onRetry: () {}));

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
