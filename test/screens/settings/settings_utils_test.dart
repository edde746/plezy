import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/settings_utils.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/dialog_action_button.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('settings text input survives TV keyboard back dismissal', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late BuildContext hostContext;
    final saved = <String>[];

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

    showRegexInputDialog(
      context: hostContext,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (value) async => saved.add(value),
    );
    await tester.pumpAndSettle();
    final fieldFinder = find.byType(TextField);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isFalse);
    await tester.showKeyboard(fieldFinder);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);
    expect(tester.takeException(), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings save helper reports platform failures and remains retryable', (tester) async {
    final context = await _pumpHost(tester);

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (_) async => throw PlatformException(code: 'write_failed'),
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.saveFailed), findsOneWidget);
  });

  testWidgets('settings save helper reports filesystem failures and remains retryable', (tester) async {
    final context = await _pumpHost(tester);

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (_) async => throw const FileSystemException('write failed'),
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.saveFailed), findsOneWidget);
  });

  testWidgets('settings save helper closes only after a successful save', (tester) async {
    final context = await _pumpHost(tester);
    var saved = false;

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (_) async => saved = true,
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('disposed settings save context does not present late feedback', (tester) async {
    final context = await _pumpHost(tester);
    final saveGate = Completer<void>();

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (_) async {
        await saveGate.future;
        throw PlatformException(code: 'late_write_failure');
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    saveGate.complete();
    await tester.pump();

    expect(find.text(t.settings.saveFailed), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-persisted blank pattern is rejected at save instead of round-tripping', (tester) async {
    final context = await _pumpHost(tester);
    final saved = <String>[];

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: '',
      defaultValue: '.*',
      onSave: (value) async => saved.add(value),
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(saved, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(t.settings.invalidRegex), findsOneWidget);
  });

  testWidgets('whitespace-only pattern is flagged while typing and rejected at save', (tester) async {
    final context = await _pumpHost(tester);
    final saved = <String>[];

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (value) async => saved.add(value),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(find.text(t.settings.invalidRegex), findsOneWidget);

    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(saved, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('non-blank pattern is persisted verbatim without trimming', (tester) async {
    final context = await _pumpHost(tester);
    final saved = <String>[];

    showRegexInputDialog(
      context: context,
      title: 'Regex',
      currentValue: 'abc',
      defaultValue: '.*',
      onSave: (value) async => saved.add(value),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), r' credits\s*roll ');
    await tester.pump();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(saved, [r' credits\s*roll ']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a select in a covered selection dialog leaves the dialog above it open (#3197)', (tester) async {
    final context = await _pumpHost(tester);
    final closed = <String>[];

    unawaited(
      showSelectionDialog<String>(
        context: context,
        title: 'Language',
        options: const [
          DialogOption(value: 'en', title: 'English'),
          DialogOption(value: 'de', title: 'Deutsch'),
        ],
        currentValue: 'en',
      ).then((option) => closed.add('language:${option?.value}')),
    );
    await tester.pumpAndSettle();
    unawaited(
      showSelectionDialog<int>(
        context: context,
        title: 'Tab',
        options: const [
          DialogOption(value: 1, title: 'Home'),
          DialogOption(value: 2, title: 'Libraries'),
        ],
        currentValue: 1,
      ).then((option) => closed.add('tab:${option?.value}')),
    );
    await tester.pumpAndSettle();

    // Focus left on a tile of the covered dialog, where a gamepad select
    // landed: a blind pop handed its option to the dialog above.
    final covered = Focus.of(tester.element(find.text('Deutsch')));
    covered.requestFocus();
    await tester.pump();
    expect(covered.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(closed, isEmpty);
    expect(find.text('Libraries'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.tap(find.text('Libraries'));
    await tester.pumpAndSettle();
    expect(closed, ['tab:2']);

    // Uncovered, the same select closes its own dialog.
    covered.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(closed, ['tab:2', 'language:de']);
  });
}

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (hostContext) {
              context = hostContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return context;
}

Finder _saveButton() => find.widgetWithText(DialogActionButton, t.common.save);
