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

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_dialog')), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
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
