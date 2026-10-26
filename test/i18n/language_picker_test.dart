import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/settings_utils.dart';

void main() {
  Future<Future<DialogOption<String>?> Function()> host(WidgetTester tester, {double scale = 1}) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale), size: const Size(360, 640)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return () => showSelectionDialog<String>(
      context: context,
      title: 'Language',
      searchable: true,
      options: const [
        DialogOption(value: '', title: 'Follow system'),
        DialogOption(value: 'ar', title: 'العربية', subtitle: 'Arabic · ar'),
        DialogOption(value: 'fr', title: 'Français', subtitle: 'French · fr'),
        DialogOption(value: 'ja', title: '日本語', subtitle: 'Japanese · ja'),
      ],
      currentValue: 'ar',
    );
  }

  testWidgets('language search accepts endonyms, accents and locale identifiers', (tester) async {
    final open = await host(tester);
    unawaited(open());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'francais');
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('日本語'), findsNothing);
    await tester.enterText(find.byType(TextField), '日本');
    await tester.pumpAndSettle();
    expect(find.text('日本語'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ar');
    await tester.pumpAndSettle();
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('selection announces its checked state and keyboard search selects a result', (tester) async {
    final semantics = tester.ensureSemantics();
    final open = await host(tester);
    final result = open();
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('العربية')),
      matchesSemantics(
        label: 'العربية\nArabic · ar',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    await tester.enterText(find.byType(TextField), 'Japanese');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect((await result)?.value, 'ja');
    semantics.dispose();
  });

  testWidgets('empty search recovers through a localized clear action at large text size', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final open = await host(tester, scale: 2);
    unawaited(open());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no-language-matches');
    await tester.pumpAndSettle();
    expect(find.text(t.messages.noResultsFound), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(t.common.clear));
    await tester.pumpAndSettle();
    expect(find.text('Follow system'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
