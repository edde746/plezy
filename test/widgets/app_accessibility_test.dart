import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/focus/focusable_slider.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/screens/settings/accessibility_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_motion.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/app_accessibility.dart';
import '../test_helpers/prefs.dart';

class _NonlinearScale extends TextScaler {
  const _NonlinearScale();
  @override
  double scale(double size) => size < 20 ? size * 2 : size * 1.5;
  @override
  double get textScaleFactor => 2;
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });
  test('additional text size preserves nonlinear system scaling', () {
    const scaler = MultipliedTextScaler(_NonlinearScale(), 1.5);
    expect(scaler.scale(12), 36);
    expect(scaler.scale(30), 67.5);
  });
  testWidgets('system accommodations remain on and high contrast reaches inherited tokens', (tester) async {
    late MediaQueryData media;
    late ThemeData theme;
    late Duration focus, fill;
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            highContrast: true,
            boldText: true,
            textScaler: TextScaler.linear(1.5),
          ),
          child: AppAccessibility(
            child: Builder(
              builder: (context) {
                media = MediaQuery.of(context);
                theme = Theme.of(context);
                focus = FocusTheme.getAnimationDuration(context);
                fill = MonoMotion.fill(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(media.disableAnimations, isTrue);
    expect(media.boldText, isTrue);
    expect(media.textScaler.scale(16), 24);
    expect(focus, Duration.zero);
    expect(fill, Duration.zero);
    expect(theme.extension<MonoTokens>()!.text, Colors.white);
    expect(theme.extension<MonoTokens>()!.outline, Colors.white);
  });
  testWidgets('shared sliders expose a named value and keyboard endpoints in RTL', (tester) async {
    var value = 50.0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: FocusableSlider(
                  autofocus: true,
                  value: value,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  semanticLabel: 'Volume',
                  semanticFormatterCallback: (v) => '${v.round()} percent',
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Volume')), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 45);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 100);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 0);
    semantics.dispose();
  });
  testWidgets('accessibility page remains usable on a narrow display at large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await SettingsService.instance.write(SettingsService.accessibilityTextScale, 2.0);
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.light),
        home: const AppAccessibility(child: AccessibilitySettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
