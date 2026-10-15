import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/custom_theme_editor_screen.dart';
import 'package:plezy/screens/settings/theme_settings_screen.dart';
import 'package:plezy/services/settings_service.dart' hide ThemeMode;
import 'package:plezy/services/settings_service.dart' as settings show ThemeMode;
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

const _presetLabels = ['Ember', 'Glacier', 'Forest', 'Plum', 'Paper'];

class _Harness {
  _Harness(this.supporter, this.theme);

  final SupporterService supporter;
  final ThemeProvider theme;

  /// How often a locked perk opened the Supporter sheet.
  int sheetOpened = 0;

  settings.ThemeMode get stored => SettingsService.instance.read(SettingsService.themeMode);
}

/// The picker at the app root, themed by the provider the way MainApp is.
/// [purchaseInSheet] makes the Supporter sheet end with a purchase.
Future<_Harness> _pumpPicker(
  WidgetTester tester,
  SupporterAvailability availability, {
  bool purchaseInSheet = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 2000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final supporter = SupporterService.forTesting(availability: availability);
  addTearDown(supporter.dispose);
  final theme = ThemeProvider(supporter: supporter);
  addTearDown(theme.dispose);
  final harness = _Harness(supporter, theme);

  Future<void> openSheet(BuildContext context) async {
    harness.sheetOpened++;
    if (!purchaseInSheet) return;
    await SettingsService.instance.write(SettingsService.supporterEntitlementCached, true);
    await supporter.init();
  }

  await tester.pumpWidget(
    InputModeTracker(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<SupporterService>.value(value: supporter),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: Consumer<ThemeProvider>(
          builder: (_, provider, _) => MaterialApp(
            theme: provider.lightTheme,
            darkTheme: provider.darkTheme,
            themeMode: provider.materialThemeMode,
            home: ThemeSettingsScreen(openSupporterSheet: openSheet),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Finder _tile(settings.ThemeMode mode) => find.byKey(ValueKey(mode));

bool _isChecked(settings.ThemeMode mode) =>
    find.descendant(of: _tile(mode), matching: find.byIcon(Symbols.radio_button_checked_rounded)).evaluate().isNotEmpty;

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final service = await SettingsService.getInstance();
    await service.write(SettingsService.themeMode, settings.ThemeMode.dark);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('a build without the perks lists only the built-ins', (tester) async {
    await _pumpPicker(tester, SupporterAvailability.hidden);

    for (final label in [t.settings.systemTheme, t.settings.lightTheme, t.settings.darkTheme, t.settings.oledTheme]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in [..._presetLabels, t.themeEditor.custom, t.themeEditor.editCustom, t.themeEditor.presets]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.byIcon(Symbols.lock_rounded), findsNothing);
  });

  testWidgets('a locked build shows every perk with a lock and the sheet decides', (tester) async {
    final harness = await _pumpPicker(tester, SupporterAvailability.purchasable);

    for (final mode in [
      settings.ThemeMode.ember,
      settings.ThemeMode.glacier,
      settings.ThemeMode.forest,
      settings.ThemeMode.plum,
      settings.ThemeMode.paper,
      settings.ThemeMode.custom,
    ]) {
      expect(find.descendant(of: _tile(mode), matching: find.byIcon(Symbols.lock_rounded)), findsOneWidget);
    }
    for (final mode in [settings.ThemeMode.system, settings.ThemeMode.dark]) {
      expect(find.descendant(of: _tile(mode), matching: find.byIcon(Symbols.lock_rounded)), findsNothing);
    }

    await tester.tap(find.text('Ember'));
    await tester.pumpAndSettle();
    expect(harness.sheetOpened, 1);
    expect(harness.stored, settings.ThemeMode.dark);
    expect(harness.theme.themeMode, settings.ThemeMode.dark);

    await tester.tap(find.text(t.themeEditor.editCustom));
    await tester.pumpAndSettle();
    expect(harness.sheetOpened, 2);
    expect(find.byType(CustomThemeEditorScreen), findsNothing);

    // Built-ins never ask.
    await tester.tap(find.text(t.settings.oledTheme));
    await tester.pumpAndSettle();
    expect(harness.sheetOpened, 2);
    expect(harness.stored, settings.ThemeMode.oled);
  });

  testWidgets('a purchase in the sheet applies the locked pick and drops the locks', (tester) async {
    final harness = await _pumpPicker(tester, SupporterAvailability.purchasable, purchaseInSheet: true);

    await tester.tap(find.text('Glacier'));
    await tester.pumpAndSettle();

    expect(harness.sheetOpened, 1);
    expect(harness.stored, settings.ThemeMode.glacier);
    expect(harness.theme.themeMode, settings.ThemeMode.glacier);
    expect(Theme.of(tester.element(find.byType(ThemeSettingsScreen))).colorScheme.primary, MonoPalette.glacier.accent);
    expect(find.byIcon(Symbols.lock_rounded), findsNothing);
    expect(_isChecked(settings.ThemeMode.glacier), isTrue);
  });

  testWidgets('a stored perk that is locked shows System checked and stays stored', (tester) async {
    await SettingsService.instance.write(SettingsService.themeMode, settings.ThemeMode.forest);
    final harness = await _pumpPicker(tester, SupporterAvailability.purchasable);

    expect(_isChecked(settings.ThemeMode.system), isTrue);
    expect(_isChecked(settings.ThemeMode.forest), isFalse);
    expect(harness.stored, settings.ThemeMode.forest);
  });

  testWidgets('a free build applies every pick without the sheet', (tester) async {
    final harness = await _pumpPicker(tester, SupporterAvailability.free);
    expect(find.byIcon(Symbols.lock_rounded), findsNothing);

    for (final (label, mode, palette) in [
      ('Ember', settings.ThemeMode.ember, MonoPalette.ember),
      ('Paper', settings.ThemeMode.paper, MonoPalette.paper),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(harness.stored, mode);
      final screenTheme = Theme.of(tester.element(find.byType(ThemeSettingsScreen)));
      expect(screenTheme.scaffoldBackgroundColor, palette.bg);
    }
    expect(harness.sheetOpened, 0);
  });

  testWidgets('Custom with nothing saved opens the editor seeded from the theme on screen', (tester) async {
    final harness = await _pumpPicker(tester, SupporterAvailability.free);
    expect(find.text(t.themeEditor.customEmpty), findsOneWidget);

    await tester.tap(_tile(settings.ThemeMode.custom));
    await tester.pumpAndSettle();

    final editor = tester.widget<CustomThemeEditorScreen>(find.byType(CustomThemeEditorScreen));
    expect(editor.initialPalette, MonoPalette.dark);
    // Opening the editor selects nothing until it saves.
    expect(harness.stored, settings.ThemeMode.dark);
  });

  testWidgets('Edit opens the saved Custom palette', (tester) async {
    final saved = MonoPalette.forest.withColor(MonoPaletteSlot.accent, const Color(0xFFFF00AA));
    await SettingsService.instance.write(SettingsService.customThemePalette, saved);
    await _pumpPicker(tester, SupporterAvailability.free);
    expect(find.text(t.themeEditor.customEmpty), findsNothing);

    await tester.tap(find.text(t.themeEditor.editCustom));
    await tester.pumpAndSettle();

    expect(tester.widget<CustomThemeEditorScreen>(find.byType(CustomThemeEditorScreen)).initialPalette, saved);
  });

  testWidgets('the D-pad reaches a preset and SELECT applies it', (tester) async {
    final harness = await _pumpPicker(tester, SupporterAvailability.free);

    final emberNode = Focus.of(
      tester.element(find.descendant(of: _tile(settings.ThemeMode.ember), matching: find.text('Ember'))),
    );
    for (var i = 0; i < 12 && !emberNode.hasFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(emberNode.hasFocus, isTrue, reason: 'D-pad never reached Ember');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(harness.stored, settings.ThemeMode.ember);
  });
}
