import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/mpv_config_models.dart';
import 'package:plezy/screens/settings/mpv_config_screen.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('typing burst coalesces to one full-document write', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);

    await tester.enterText(find.byType(TextField), 'vo');
    await tester.enterText(find.byType(TextField), 'vol');
    await tester.enterText(find.byType(TextField), 'volume=80');

    await tester.pump(const Duration(milliseconds: 399));
    expect(backend.configWrites, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(backend.configWrites, ['volume=80']);
    expect(backend.maxActiveConfigWrites, 1);

    backend.completeNextConfigWrite();
    await tester.pump();

    expect(backend.durableConfig, 'volume=80');
  });

  testWidgets('new revisions wait for the active write and only the latest follows', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);

    await tester.enterText(find.byType(TextField), 'first=1');
    await tester.pump(const Duration(milliseconds: 400));
    expect(backend.configWrites, ['first=1']);

    await tester.enterText(find.byType(TextField), 'second=2');
    await tester.enterText(find.byType(TextField), 'final=3');
    await tester.pump(const Duration(milliseconds: 400));

    expect(backend.configWrites, ['first=1']);
    expect(backend.activeConfigWrites, 1);

    backend.completeNextConfigWrite();
    await tester.pump();

    expect(backend.configWrites, ['first=1', 'final=3']);
    expect(backend.maxActiveConfigWrites, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'final=3');

    backend.completeNextConfigWrite();
    await tester.pump();

    expect(backend.durableConfig, 'final=3');
  });

  testWidgets('manual Enter insertion joins the debounced writer', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);

    await tester.enterText(find.byType(TextField), 'alpha=1');
    await tester.pump(const Duration(milliseconds: 400));
    backend.completeNextConfigWrite();
    await tester.pump();
    backend.configWrites.clear();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'alpha=1\n');

    await tester.pump(const Duration(milliseconds: 399));
    expect(backend.configWrites, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(backend.configWrites, ['alpha=1\n']);

    backend.completeNextConfigWrite();
    await tester.pump();
    expect(backend.durableConfig, 'alpha=1\n');
  });

  testWidgets('observed external replacement wins after an in-flight local write', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);
    final settings = SettingsService.instance;

    await tester.enterText(find.byType(TextField), 'local=old');
    await tester.pump(const Duration(milliseconds: 400));
    expect(backend.configWrites, ['local=old']);

    unawaited(settings.write(SettingsService.mpvConfigText, 'external=new'));
    await tester.pump();
    expect(backend.configWrites, ['local=old', 'external=new']);

    backend.completeConfigWriteAt(1);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'external=new');

    backend.completeNextConfigWrite();
    await tester.pump();
    expect(backend.configWrites, ['local=old', 'external=new', 'external=new']);

    backend.completeNextConfigWrite();
    await tester.pump();
    expect(backend.durableConfig, 'external=new');
  });

  testWidgets('focus loss flushes immediately and route pop waits for persistence', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);

    await tester.enterText(find.byType(TextField), 'profile=gpu-hq');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(backend.configWrites, ['profile=gpu-hq']);

    unawaited(tester.binding.handlePopRoute());
    await tester.pump();
    expect(find.byType(MpvConfigScreen), findsOneWidget);

    backend.completeNextConfigWrite();
    await tester.pumpAndSettle();

    expect(find.byType(MpvConfigScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(backend.durableConfig, 'profile=gpu-hq');
  });

  testWidgets('dispose flushes its captured edit without using disposed UI', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);

    await tester.enterText(find.byType(TextField), 'video-sync=display-resample');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(backend.configWrites, ['video-sync=display-resample']);

    backend.completeNextConfigWrite();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(backend.durableConfig, 'video-sync=display-resample');
  });

  testWidgets('failed flush stays retryable and does not pop until retry succeeds', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);
    const config = 'gpu-api=secret-test-value';

    await tester.enterText(find.byType(TextField), config);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    backend.completeNextConfigWrite(error: PlatformException(code: 'write_failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(t.settings.saveFailed), findsOneWidget);
    expect(find.textContaining('write_failed'), findsNothing);
    expect(backend.durableConfig, isNull);

    unawaited(tester.binding.handlePopRoute());
    await tester.pump();
    expect(backend.configWrites, [config, config]);
    expect(find.byType(MpvConfigScreen), findsOneWidget);

    backend.completeNextConfigWrite();
    await tester.pumpAndSettle();

    expect(find.byType(MpvConfigScreen), findsNothing);
    expect(backend.durableConfig, config);
  });

  testWidgets('saving a preset flushes the matching active text before success', (tester) async {
    final backend = await _pumpEditor(tester, holdConfigWrites: true);
    final settings = SettingsService.instance;

    await tester.enterText(find.byType(TextField), 'preset-source=yes');
    await tester.pump();
    final saveTile = tester.widget<FocusableListTile>(find.widgetWithText(FocusableListTile, t.mpvConfig.saveAsPreset));
    expect(saveTile.enabled, isTrue);
    saveTile.onTap!();
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final nameField = find.descendant(of: dialog, matching: find.byType(TextField));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Saved');
    await tester.tap(find.widgetWithText(DialogActionButton, t.common.save));
    await tester.pump();

    expect(settings.read(SettingsService.mpvPresets), isEmpty);
    expect(find.text(t.mpvConfig.presetSaved), findsNothing);

    backend.completeNextConfigWrite();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final presets = settings.read(SettingsService.mpvPresets);
    expect(presets, hasLength(1));
    expect(presets.single.name, 'Saved');
    expect(presets.single.text, 'preset-source=yes');
    expect(find.text(t.mpvConfig.presetSaved), findsOneWidget);
  });

  testWidgets('preset replacement waits behind an active edit and wins last', (tester) async {
    final preset = MpvPreset(name: 'Cinema', text: 'profile=gpu-hq', createdAt: DateTime(2026));
    final backend = await _pumpEditor(tester, holdConfigWrites: true, presets: [preset]);

    await tester.enterText(find.byType(TextField), 'old-edit=yes');
    await tester.pump(const Duration(milliseconds: 400));
    expect(backend.configWrites, ['old-edit=yes']);

    await tester.tap(find.text('Cinema'));
    await tester.pump();
    expect(backend.configWrites, ['old-edit=yes']);
    expect(find.text(t.mpvConfig.presetLoaded), findsNothing);

    backend.completeNextConfigWrite();
    await tester.pump();
    expect(backend.configWrites, ['old-edit=yes', 'profile=gpu-hq']);
    expect(backend.maxActiveConfigWrites, 1);

    backend.completeNextConfigWrite();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(t.mpvConfig.presetLoaded), findsOneWidget);
    expect(backend.durableConfig, 'profile=gpu-hq');
  });

  testWidgets('clean external settings update replaces the editor', (tester) async {
    final backend = await _pumpEditor(tester);
    final settings = SettingsService.instance;

    await settings.write(SettingsService.mpvConfigText, 'external=yes');
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'external=yes');
    expect(backend.durableConfig, 'external=yes');
  });
  group('TV line editor', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);
    });

    tearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      TvDetectionService.setForceTVSync(false);
    });

    testWidgets('renders one row per line and persists edits joined by newlines', (tester) async {
      final backend = await _pumpEditor(tester, initialConfig: 'hwdec=auto\n# comment');

      expect(_rowTexts(tester), ['hwdec=auto', '# comment']);

      await _openRow(tester, 1);
      await tester.enterText(_rowField(1), '# changed');
      await tester.pump(const Duration(milliseconds: 400));

      expect(backend.durableConfig, 'hwdec=auto\n# changed');
    });

    testWidgets('a pasted value with newlines splits into rows and continues on the last one', (tester) async {
      final backend = await _pumpEditor(tester, initialConfig: 'first\nlast');

      await _openRow(tester, 0);
      await tester.enterText(_rowField(0), 'first\r\ngpu-api=vulkan\nhwdec=auto');
      // One frame builds the rows; the post-frame open activates the input.
      await tester.pump();
      await tester.pump();

      expect(_rowTexts(tester), ['first', 'gpu-api=vulkan', 'hwdec=auto', 'last']);
      expect(_rowFocusNode(tester, 2).hasFocus, isTrue);
      expect(tester.widget<TextField>(_rowField(2)).readOnly, isFalse);

      await tester.pump(const Duration(milliseconds: 400));
      expect(backend.durableConfig, 'first\ngpu-api=vulkan\nhwdec=auto\nlast');
    });

    testWidgets('an IME action never inserts a row: it closes the input and hands focus down', (tester) async {
      await _pumpEditor(tester, initialConfig: 'a\nc');

      await _openRow(tester, 0);
      // FireTVIME reports Back as `previous`; the app cannot tell it from Done.
      await tester.testTextInput.receiveAction(TextInputAction.previous);
      await tester.pump();

      expect(_rowTexts(tester), ['a', 'c']);
      expect(tester.widget<TextField>(_rowField(0)).readOnly, isTrue);
      expect(_rowFocusNode(tester, 1).hasFocus, isTrue);
      expect(tester.widget<TextField>(_rowField(1)).readOnly, isTrue);

      await _openRow(tester, 1);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_rowTexts(tester), ['a', 'c']);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'mpv_config_add_line');
    });

    testWidgets('removing a row persists the rest and clearing the only row keeps an empty document', (tester) async {
      final backend = await _pumpEditor(tester, initialConfig: 'a\nb');

      await tester.tap(find.byTooltip(t.mpvConfig.removeLine).first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(_rowTexts(tester), ['b']);
      expect(backend.durableConfig, 'b');

      await tester.tap(find.byTooltip(t.mpvConfig.removeLine));
      await tester.pump(const Duration(milliseconds: 400));

      expect(_rowTexts(tester), ['']);
      expect(backend.durableConfig, '');
    });

    testWidgets('add line appends an open row and D-pad down from the last row reaches it', (tester) async {
      await _pumpEditor(tester, initialConfig: 'a');

      _rowFocusNode(tester, 0).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'mpv_config_add_line');

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.pump();

      expect(_rowTexts(tester), ['a', '']);
      expect(_rowFocusNode(tester, 1).hasFocus, isTrue);
      expect(tester.widget<TextField>(_rowField(1)).readOnly, isFalse);
    });

    testWidgets('loading a preset replaces the rows', (tester) async {
      await _pumpEditor(
        tester,
        initialConfig: 'old=1',
        presets: [MpvPreset(name: 'quality', text: 'profile=gpu-hq\ndeband=yes', createdAt: DateTime(2026))],
      );

      await tester.tap(find.widgetWithText(FocusableListTile, 'quality'));
      await tester.pumpAndSettle();

      expect(_rowTexts(tester), ['profile=gpu-hq', 'deband=yes']);
    });
  });
}

Finder _rowField(int index) => find.byType(TextField).at(index);

List<String> _rowTexts(WidgetTester tester) =>
    tester.widgetList<TextField>(find.byType(TextField)).map((field) => field.controller!.text).toList();

FocusNode _rowFocusNode(WidgetTester tester, int index) => tester.widget<TextField>(_rowField(index)).focusNode!;

/// Rows never open their keyboard on focus; Select does, as on a remote.
Future<void> _openRow(WidgetTester tester, int index) async {
  _rowFocusNode(tester, index).requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.select);
  await tester.pump();
  expect(tester.widget<TextField>(_rowField(index)).readOnly, isFalse);
}

Future<_ControlledPreferences> _pumpEditor(
  WidgetTester tester, {
  bool holdConfigWrites = false,
  List<MpvPreset> presets = const [],
  String? initialConfig,
}) async {
  resetSharedPreferencesForTest();
  final initial = <String, Object>{
    if (presets.isNotEmpty)
      SettingsService.mpvPresets.key: jsonEncode(presets.map((preset) => preset.toJson()).toList()),
    SettingsService.mpvConfigText.key: ?initialConfig,
  };
  final backend = _ControlledPreferences(initial)..holdConfigWrites = holdConfigWrites;
  SharedPreferencesAsyncPlatform.instance = backend;
  BaseSharedPreferencesService.resetForTesting();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    InputModeTracker(
      child: TranslationProvider(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: monoTheme(dark: true),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    ),
  );
  unawaited(navigatorKey.currentState!.push<void>(MaterialPageRoute<void>(builder: (_) => const MpvConfigScreen())));
  await tester.pumpAndSettle();
  return backend;
}

base class _ControlledPreferences extends InMemorySharedPreferencesAsync {
  _ControlledPreferences(super.data) : super.withData();

  bool holdConfigWrites = false;
  final List<String> configWrites = [];
  final List<Completer<void>> _configWriteGates = [];
  int activeConfigWrites = 0;
  int maxActiveConfigWrites = 0;
  String? durableConfig;

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (key != SettingsService.mpvConfigText.key) return super.setString(key, value, options);

    configWrites.add(value);
    activeConfigWrites++;
    if (activeConfigWrites > maxActiveConfigWrites) maxActiveConfigWrites = activeConfigWrites;
    try {
      if (holdConfigWrites) {
        final gate = Completer<void>();
        _configWriteGates.add(gate);
        await gate.future;
      }
      final result = await super.setString(key, value, options);
      durableConfig = value;
      return result;
    } finally {
      activeConfigWrites--;
    }
  }

  void completeNextConfigWrite({Object? error}) {
    completeConfigWriteAt(0, error: error);
  }

  void completeConfigWriteAt(int index, {Object? error}) {
    final gate = _configWriteGates.removeAt(index);
    if (error == null) {
      gate.complete();
    } else {
      gate.completeError(error);
    }
  }
}
