import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/main.dart' as app;
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/custom_theme_editor_screen.dart';
import 'package:plezy/services/settings_service.dart' hide ThemeMode;
import 'package:plezy/services/settings_service.dart' as settings show ThemeMode;
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_bar_back_button.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

const _phone = Size(400, 900);
const _tv = Size(1280, 720);

/// Light with a white page, so text contrast lands on the textbook values:
/// #767676 on white is 4.54:1, #777777 is 4.48:1.
final _white = MonoPalette.light
    .withColor(MonoPaletteSlot.bg, const Color(0xFFFFFFFF))
    .withColor(MonoPaletteSlot.surface, const Color(0xFFFFFFFF));

Finder get _editor => find.byType(CustomThemeEditorScreen);
Finder get _hexField => find.byKey(const ValueKey('custom_theme_hex'));
Finder _slot(MonoPaletteSlot slot) => find.byKey(ValueKey('custom_theme_slot_${slot.id}'));
Finder _button(String name) => find.byKey(ValueKey('custom_theme_$name'));

/// The editor pushed over a launcher, under the root providers it reads and
/// the app's root shell, whose scaffold resizes for the keyboard.
Future<ThemeProvider> _pumpEditor(WidgetTester tester, MonoPalette initial, {Size size = _phone}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
  addTearDown(supporter.dispose);
  final theme = ThemeProvider(supporter: supporter);
  addTearDown(theme.dispose);

  await tester.pumpWidget(
    InputModeTracker(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<SupporterService>.value(value: supporter),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: MaterialApp(
          theme: monoTheme(MonoPalette.dark),
          builder: (context, child) => app.rootShell(child),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => CustomThemeEditorScreen(initialPalette: initial)),
                  ),
                  child: const Text('open editor'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open editor'));
  await tester.pumpAndSettle();
  return theme;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The phone layout builds its rows lazily, so a row scrolled far away is not
/// in the tree. Scrolls back to the top, then down until [finder] shows.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
  await tester.drag(list, const Offset(0, 5000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 120, scrollable: list);
  await tester.pumpAndSettle();
}

Future<void> _enterHex(WidgetTester tester, String hex) async {
  await tester.ensureVisible(_hexField);
  await tester.enterText(_hexField, hex);
  await tester.pumpAndSettle();
}

String _warning(String pair, String ratio, String minimum) =>
    t.themeEditor.lowContrast(pair: pair, ratio: ratio, minimum: minimum);

/// The `custom_theme_*` key of the control holding focus.
String? _focusedControl() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  String? found;
  void check(Element element) {
    final key = element.widget.key;
    if (found == null && key is ValueKey<String> && key.value.startsWith('custom_theme_')) found = key.value;
  }

  check(context as Element);
  context.visitAncestorElements((element) {
    check(element);
    return found == null;
  });
  return found;
}

settings.ThemeMode _storedMode() => SettingsService.instance.read(SettingsService.themeMode);
MonoPalette? _storedPalette() => SettingsService.instance.read(SettingsService.customThemePalette);

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final service = await SettingsService.getInstance();
    await service.write(SettingsService.themeMode, settings.ThemeMode.dark);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('lists the six colours with their values and shows a live preview', (tester) async {
    await _pumpEditor(tester, MonoPalette.ember);

    for (final slot in MonoPaletteSlot.values) {
      expect(_slot(slot), findsOneWidget, reason: slot.id);
    }
    final accentHex = '#${colorToArgbHex(MonoPalette.ember.accent).substring(3)}';
    expect(find.descendant(of: _slot(MonoPaletteSlot.accent), matching: find.text(accentHex)), findsOneWidget);
    expect(find.bySemanticsLabel(t.themeEditor.preview), findsOneWidget);
    expect(find.text(t.themeEditor.previewMutedText), findsOneWidget);
  });

  testWidgets('contrast warnings appear below the bar and clear at it, without blocking Save', (tester) async {
    await _pumpEditor(tester, _white);
    await _tapVisible(tester, _slot(MonoPaletteSlot.text));

    final onPage = _warning(t.themeEditor.contrast.textOnBg, '4.4', '4.5');
    final onCard = _warning(t.themeEditor.contrast.textOnSurface, '4.4', '4.5');
    expect(find.text(onPage), findsNothing);

    await _enterHex(tester, '#777777');
    expect(find.text(onPage), findsOneWidget);
    expect(find.text(onCard), findsOneWidget);
    // The colours the failing pairs are drawn from carry a marker.
    for (final slot in [MonoPaletteSlot.text, MonoPaletteSlot.bg, MonoPaletteSlot.surface]) {
      expect(find.descendant(of: _slot(slot), matching: find.byIcon(Symbols.warning_rounded)), findsOneWidget);
    }

    await _enterHex(tester, '#767676');
    expect(find.textContaining(t.themeEditor.contrast.textOnBg), findsNothing);
    expect(find.textContaining(t.themeEditor.contrast.textOnSurface), findsNothing);

    // An accent too close to the page warns against the 3:1 bar instead.
    await _tapVisible(tester, _slot(MonoPaletteSlot.accent));
    await _enterHex(tester, '#959595');
    expect(find.text(_warning(t.themeEditor.contrast.accentOnBg, '2.9', '3')), findsOneWidget);
    await _enterHex(tester, '#949494');
    expect(find.textContaining(t.themeEditor.contrast.accentOnBg), findsNothing);

    // A failing palette still saves.
    await _enterHex(tester, '#EEEEEE');
    expect(find.textContaining(t.themeEditor.contrast.accentOnBg), findsOneWidget);
    await tester.tap(_button('save'));
    await tester.pumpAndSettle();
    expect(_storedPalette()!.accent, const Color(0xFFEEEEEE));
  });

  testWidgets('Save stores the palette, selects Custom and closes', (tester) async {
    final theme = await _pumpEditor(tester, MonoPalette.forest);

    await _tapVisible(tester, _slot(MonoPaletteSlot.accent));
    await _enterHex(tester, '#80FF00AA');
    expect(_storedPalette(), isNull, reason: 'edits stay in the editor until Save');
    expect(theme.themeMode, settings.ThemeMode.dark);

    await tester.tap(_button('save'));
    await tester.pumpAndSettle();

    final expected = MonoPalette.forest.withColor(MonoPaletteSlot.accent, const Color(0x80FF00AA));
    expect(_storedPalette(), expected);
    expect(_storedMode(), settings.ThemeMode.custom);
    expect(theme.themeMode, settings.ThemeMode.custom);
    expect(theme.activePalette, expected);
    expect(_editor, findsNothing);
  });

  testWidgets('Cancel with unsaved changes asks; discarding stores nothing', (tester) async {
    await _pumpEditor(tester, MonoPalette.plum);
    await _tapVisible(tester, _slot(MonoPaletteSlot.bg));
    await _enterHex(tester, '#123456');

    await tester.tap(_button('cancel'));
    await tester.pumpAndSettle();
    expect(find.text(t.themeEditor.discardTitle), findsOneWidget);

    // Keep editing: the dialog closes and the draft survives.
    await tester.tap(find.text(t.common.cancel).last);
    await tester.pumpAndSettle();
    expect(_editor, findsOneWidget);
    await _scrollTo(tester, _slot(MonoPaletteSlot.bg));
    expect(find.descendant(of: _slot(MonoPaletteSlot.bg), matching: find.text('#123456')), findsOneWidget);

    await tester.tap(_button('cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.themeEditor.discard));
    await tester.pumpAndSettle();

    expect(_editor, findsNothing);
    expect(_storedPalette(), isNull);
    expect(_storedMode(), settings.ThemeMode.dark);
  });

  testWidgets('system back with unsaved changes asks too; without changes it just leaves', (tester) async {
    await _pumpEditor(tester, MonoPalette.paper);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
    expect(find.text(t.themeEditor.discardTitle), findsNothing);

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, _slot(MonoPaletteSlot.text));
    await _enterHex(tester, '#000000');

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(find.text(t.themeEditor.discardTitle), findsOneWidget);
    expect(_editor, findsOneWidget);
  });

  testWidgets('the app-bar back arrow with unsaved changes asks too; without changes it just leaves', (tester) async {
    await _pumpEditor(tester, MonoPalette.paper);

    await tester.tap(find.byType(AppBarBackButton));
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
    expect(find.text(t.themeEditor.discardTitle), findsNothing);

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, _slot(MonoPaletteSlot.text));
    await _enterHex(tester, '#000000');

    await tester.tap(find.byType(AppBarBackButton));
    await tester.pumpAndSettle();
    expect(find.text(t.themeEditor.discardTitle), findsOneWidget);
    expect(_editor, findsOneWidget);
  });

  testWidgets('Reset returns every colour to how the editor opened', (tester) async {
    await _pumpEditor(tester, MonoPalette.glacier);
    expect(tester.widget<FocusableButton>(_button('reset')).onPressed, isNull);

    await _tapVisible(tester, _slot(MonoPaletteSlot.surface));
    await _enterHex(tester, '#FF0000');
    await _scrollTo(tester, find.text(t.themeEditor.startFrom));
    await tester.tap(find.text(t.themeEditor.startFrom));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.emberTheme));
    await tester.pumpAndSettle();
    await _scrollTo(tester, _slot(MonoPaletteSlot.bg));
    final emberBg = '#${colorToArgbHex(MonoPalette.ember.bg).substring(3)}';
    expect(find.descendant(of: _slot(MonoPaletteSlot.bg), matching: find.text(emberBg)), findsOneWidget);

    await tester.tap(_button('reset'));
    await tester.pumpAndSettle();
    for (final slot in MonoPaletteSlot.values) {
      final color = MonoPalette.glacier[slot];
      final hex = color.toARGB32() >>> 24 == 0xFF ? '#${colorToArgbHex(color).substring(3)}' : colorToArgbHex(color);
      await _scrollTo(tester, _slot(slot));
      expect(
        find.descendant(of: _slot(slot), matching: find.text(hex)),
        findsOneWidget,
        reason: slot.id,
      );
    }

    // Nothing left to lose, so leaving does not ask.
    await tester.tap(_button('cancel'));
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
  });

  testWidgets('a quick swatch takes the colour another theme uses', (tester) async {
    await _pumpEditor(tester, MonoPalette.dark);
    await _tapVisible(tester, _slot(MonoPaletteSlot.accent));

    final emberAccent = find.byKey(ValueKey('custom_theme_swatch_${colorToArgbHex(MonoPalette.ember.accent)}'));
    await _tapVisible(tester, emberAccent);

    final hex = '#${colorToArgbHex(MonoPalette.ember.accent).substring(3)}';
    expect(
      tester.widget<EditableText>(find.descendant(of: _hexField, matching: find.byType(EditableText))).controller.text,
      hex,
    );
    await _scrollTo(tester, _slot(MonoPaletteSlot.accent));
    expect(find.descendant(of: _slot(MonoPaletteSlot.accent), matching: find.text(hex)), findsOneWidget);
  });

  testWidgets('typing on a small phone keeps the field and its warnings above the keyboard', (tester) async {
    // An iPhone SE-sized screen with a 260 dp software keyboard, reported on
    // the view the way the platform does.
    const screen = Size(375, 667);
    const keyboard = 260.0;
    await _pumpEditor(tester, MonoPalette.dark, size: screen);
    expect(find.bySemanticsLabel(t.themeEditor.preview), findsOneWidget);

    await _tapVisible(tester, _slot(MonoPaletteSlot.accent));
    await tester.ensureVisible(_hexField);
    await tester.showKeyboard(_hexField);
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(_hexField, '#202020');
    await tester.pumpAndSettle();

    // The pinned preview gives way to this colour's warnings.
    expect(find.bySemanticsLabel(t.themeEditor.preview), findsNothing);
    final barWarnings = find.byKey(const ValueKey('custom_theme_bar_warnings'));
    final keyboardTop = screen.height - keyboard;
    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    final barTop = tester.getRect(barWarnings).top;

    final field = tester.getRect(_hexField);
    expect(field.top, greaterThanOrEqualTo(appBarBottom), reason: 'field under the app bar');
    expect(field.bottom, lessThanOrEqualTo(barTop), reason: 'field under the bar');
    for (final pair in [t.themeEditor.contrast.accentOnBg, t.themeEditor.contrast.accentOnSurface]) {
      final warning = find.textContaining(pair);
      expect(warning, findsOneWidget, reason: pair);
      expect(
        find.descendant(of: barWarnings, matching: warning),
        findsOneWidget,
        reason: pair,
      );
      expect(tester.getRect(warning).bottom, lessThanOrEqualTo(keyboardTop), reason: pair);
    }
    expect(tester.getRect(_button('save')).bottom, lessThanOrEqualTo(keyboardTop));

    // Fixing the colour clears the warnings while still typing.
    await tester.enterText(_hexField, '#FF8A3D');
    await tester.pumpAndSettle();
    expect(barWarnings, findsNothing);
    expect(find.textContaining(t.themeEditor.contrast.accentOnBg), findsNothing);

    // With the keyboard gone the preview is back.
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(t.themeEditor.preview), findsOneWidget);
  });

  testWidgets('on a TV-sized screen the D-pad reaches every control and adjusts a slider', (tester) async {
    await _pumpEditor(tester, MonoPalette.dark, size: _tv);

    final reached = <String>{};
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      final control = _focusedControl();
      if (control != null) reached.add(control);
    }

    const actions = {'custom_theme_reset', 'custom_theme_cancel', 'custom_theme_save'};
    final swatchCount = find
        .byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('custom_theme_swatch_'),
        )
        .evaluate()
        .length;
    expect(swatchCount, greaterThan(1));

    // DOWN walks the column into the action bar. The swatches share a row,
    // so on reaching it LEFT and then RIGHT sweep the whole row.
    Future<void> walkDownToActions() async {
      var sweptSwatches = false;
      for (var i = 0; i < 40 && !actions.contains(_focusedControl()); i++) {
        if (!sweptSwatches && (_focusedControl()?.startsWith('custom_theme_swatch_') ?? false)) {
          sweptSwatches = true;
          for (var j = 0; j < swatchCount; j++) {
            await press(LogicalKeyboardKey.arrowLeft);
          }
          for (var j = 0; j < swatchCount; j++) {
            await press(LogicalKeyboardKey.arrowRight);
          }
        }
        await press(LogicalKeyboardKey.arrowDown);
      }
    }

    await walkDownToActions();
    for (var i = 0; i < 3 && _focusedControl() != 'custom_theme_save'; i++) {
      await press(LogicalKeyboardKey.arrowRight);
    }

    expect(
      reached,
      containsAll(<String>[
        'custom_theme_start_from',
        for (final slot in MonoPaletteSlot.values) 'custom_theme_slot_${slot.id}',
        'custom_theme_hex',
        'custom_theme_hue',
        'custom_theme_saturation',
        'custom_theme_value',
        'custom_theme_alpha',
        'custom_theme_cancel',
        'custom_theme_save',
      ]),
    );
    expect(reached.where((key) => key.startsWith('custom_theme_swatch_')).length, swatchCount);
    // Reset has nothing to undo yet, so the D-pad skips it.
    expect(reached, isNot(contains('custom_theme_reset')));

    // LEFT/RIGHT move a focused slider; the colour follows.
    final valueSlider = find.byKey(const ValueKey('custom_theme_value'));
    Focus.of(tester.element(find.descendant(of: valueSlider, matching: find.byType(Slider)))).requestFocus();
    await tester.pumpAndSettle();
    expect(_focusedControl(), 'custom_theme_value');
    String hexNow() => tester
        .widget<EditableText>(find.descendant(of: _hexField, matching: find.byType(EditableText)))
        .controller
        .text;
    final before = hexNow();
    await press(LogicalKeyboardKey.arrowRight);
    expect(_focusedControl(), 'custom_theme_value');
    expect(hexNow(), isNot(before));

    // The edit enabled Reset, which the action bar now reaches too.
    await walkDownToActions();
    for (var i = 0; i < 3 && _focusedControl() != 'custom_theme_reset'; i++) {
      await press(LogicalKeyboardKey.arrowLeft);
    }
    expect(_focusedControl(), 'custom_theme_reset');

    // BACK with the change pending asks before leaving.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(t.themeEditor.discardTitle), findsOneWidget);
  });
}
