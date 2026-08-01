import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/tv_color_picker.dart';
import 'package:plezy/widgets/tv_number_spinner.dart';

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.bg);
  });

  tearDown(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('number spinner exposes localized adjustment labels', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(body: TvNumberSpinner(value: 5, min: 0, max: 10, onChanged: (_) {})),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Намали'), findsOneWidget);
    expect(find.bySemanticsLabel('Увеличи'), findsOneWidget);
    expect(find.bySemanticsLabel('Decrease'), findsNothing);
    expect(find.bySemanticsLabel('Increase'), findsNothing);
    semantics.dispose();
  });

  testWidgets('color picker exposes localized channel and hex labels', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: TvColorPicker(initialColor: Colors.red, onColorChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Намали Нюанс'), findsOneWidget);
    expect(find.bySemanticsLabel('Увеличи Нюанс'), findsOneWidget);
    expect(find.bySemanticsLabel('Шестнадесетичен цвят'), findsOneWidget);
    expect(find.bySemanticsLabel('Decrease H'), findsNothing);
    expect(find.bySemanticsLabel('Increase H'), findsNothing);
    semantics.dispose();
  });
}
