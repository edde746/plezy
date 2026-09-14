import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/keyboard_shortcuts_screen.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/keyboard_shortcuts_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/hotkey_recorder.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  testWidgets('clear persists an unassigned row that can be rebound', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    await _pumpScreen(tester, service);

    await _openAction(tester, service, 'play_pause');
    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(service.getHotkey('play_pause'), isNull);
    expect(find.text(t.hotkeys.noShortcutSet), findsOneWidget);
    final stored =
        json.decode(SettingsService.instance.prefs.getString(SettingsService.keyboardHotkeys.key)!)
            as Map<String, dynamic>;
    expect(stored['play_pause'], {'disabled': true});

    await _openAction(tester, service, 'play_pause');
    expect(tester.widget<HotKeyRecorder>(find.byType(HotKeyRecorder)).initalHotKey, isNull);
    await tester.tap(_recorderSurface());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK, physicalKey: PhysicalKeyboardKey.keyK);
    await tester.pump();
    await tester.pump();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.keyK);
    expect(find.text(service.formatHotkey(service.getHotkey('play_pause'))), findsOneWidget);
  });

  testWidgets('clear then cancel keeps the persisted assignment', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    await _pumpScreen(tester, service);

    await _openAction(tester, service, 'play_pause');
    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, t.common.cancel));
    await tester.pumpAndSettle();

    expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
    expect(find.text(service.formatHotkey(service.getHotkey('play_pause'))), findsOneWidget);
  });

  testWidgets('conflicting recording is rejected without changing either action', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    await _pumpScreen(tester, service);

    await _openAction(tester, service, 'play_pause');
    await tester.tap(_recorderSurface());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp, physicalKey: PhysicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pump();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
    expect(service.getHotkey('volume_up')?.key, PhysicalKeyboardKey.arrowUp);
    expect(
      find.text(t.settings.shortcutAlreadyAssigned(action: service.getActionDisplayName('volume_up'))),
      findsOneWidget,
    );
  });

  testWidgets('persistence failure keeps the dialog retryable and the row unchanged', (tester) async {
    final preferences = _FailingHotkeyPreferences(const {});
    SharedPreferencesAsyncPlatform.instance = preferences;
    SettingsService.resetForTesting();
    BaseSharedPreferencesService.resetForTesting();
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    await _pumpScreen(tester, service);

    await _openAction(tester, service, 'play_pause');
    await tester.tap(find.byTooltip(t.hotkeys.clearShortcut));
    await tester.pump();
    preferences.failNextHotkeyWrite = true;
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
    expect(find.text(t.common.error), findsOneWidget);
    expect(
      tester.widget<DialogActionButton>(find.widgetWithText(DialogActionButton, t.common.save)).onPressed,
      isNotNull,
    );

    await tester.tap(_saveButton());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.getHotkey('play_pause'), isNull);
  });
}

Future<void> _pumpScreen(WidgetTester tester, KeyboardShortcutsService service) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: KeyboardShortcutsScreen(keyboardService: service),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openAction(WidgetTester tester, KeyboardShortcutsService service, String action) async {
  await tester.tap(find.widgetWithText(FocusableListTile, service.getActionDisplayName(action)));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

Finder _recorderSurface() =>
    find.ancestor(of: find.byType(HotKeyRecorder), matching: find.byType(GestureDetector)).first;

Finder _saveButton() => find.widgetWithText(FilledButton, t.common.save);

final class _FailingHotkeyPreferences extends InMemorySharedPreferencesAsync {
  _FailingHotkeyPreferences(super.data) : super.withData();

  bool failNextHotkeyWrite = false;

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) {
    if (key == SettingsService.keyboardHotkeys.key && failNextHotkeyWrite) {
      failNextHotkeyWrite = false;
      throw PlatformException(code: 'write_failed');
    }
    return super.setString(key, value, options);
  }
}
