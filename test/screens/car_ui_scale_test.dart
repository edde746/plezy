import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/main.dart' as app;
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/snackbar_helper.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(false);
    TvDetectionService.debugSetAutomotiveOverride(false);
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.debugSetAutomotiveOverride(null);
    SettingsService.resetForTesting();
  });

  testWidgets('a root snackbar is laid out inside the car scale, not outside it', (tester) async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    tester.view.physicalSize = const Size(1080, 600);
    tester.view.devicePixelRatio = 0.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: const SizedBox.expand(),
          builder: (context, child) => app.rootShellForTesting(child: child),
        ),
      ),
    );

    rootScaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(content: Text('scaled')));
    await tester.pumpAndSettle();

    // The unscaled surface is 1440 logical pixels wide; the default car scale renders into
    // 1440 / 1.35, so a snackbar outside the transform would measure the full width.
    final width = tester.getSize(find.byType(SnackBar)).width;
    expect(width, lessThan(1440 * 0.9), reason: 'a root snackbar must inherit the scaled viewport');
    expect(width, closeTo(1440 / 1.35, 1.0));
  });

  test('automotive UI scale defaults by form factor and honors a stored value', () async {
    final settings = SettingsService.instance;

    expect(settings.read(SettingsService.automotiveUiScale), 1.0);

    TvDetectionService.debugSetAutomotiveOverride(true);
    expect(settings.read(SettingsService.automotiveUiScale), AutomotiveUiScale.defaultValue);

    await settings.write(SettingsService.automotiveUiScale, 1.6);
    expect(settings.read(SettingsService.automotiveUiScale), 1.6);

    TvDetectionService.debugSetAutomotiveOverride(false);
    expect(settings.read(SettingsService.automotiveUiScale), 1.6);

    await settings.write(SettingsService.automotiveUiScale, 0.5);
    expect(settings.read(SettingsService.automotiveUiScale), AutomotiveUiScale.min);

    await settings.write(SettingsService.automotiveUiScale, 2.5);
    expect(settings.read(SettingsService.automotiveUiScale), AutomotiveUiScale.max);
  });

  testWidgets('automotive root scale rewrites MediaQuery and updates reactively', (tester) async {
    _configureCarViewport(tester);
    TvDetectionService.debugSetAutomotiveOverride(true);

    var effectiveSize = Size.zero;
    var effectiveDevicePixelRatio = 0.0;
    await _pumpScaleHarness(
      tester,
      onMediaQuery: (data) {
        effectiveSize = data.size;
        effectiveDevicePixelRatio = data.devicePixelRatio;
      },
    );

    expect(effectiveSize.width, closeTo(1440 / AutomotiveUiScale.defaultValue, 0.001));
    expect(effectiveSize.height, closeTo(800 / AutomotiveUiScale.defaultValue, 0.001));
    expect(effectiveDevicePixelRatio, closeTo(0.75 * AutomotiveUiScale.defaultValue, 0.001));

    await SettingsService.instance.write(SettingsService.automotiveUiScale, 1.5);
    await tester.pump();

    expect(effectiveSize, const Size(960, 800 / 1.5));
    expect(effectiveDevicePixelRatio, 1.125);
  });

  testWidgets('non-automotive root leaves MediaQuery unchanged', (tester) async {
    _configureCarViewport(tester);

    var effectiveSize = Size.zero;
    var effectiveDevicePixelRatio = 0.0;
    await _pumpScaleHarness(
      tester,
      onMediaQuery: (data) {
        effectiveSize = data.size;
        effectiveDevicePixelRatio = data.devicePixelRatio;
      },
    );

    expect(effectiveSize, const Size(1440, 800));
    expect(effectiveDevicePixelRatio, 0.75);
  });

  testWidgets('focusable list tile variants use standard density only on automotive', (tester) async {
    await _pumpListTiles(tester, automotive: false);
    _expectListTileDensities(tester, dense: true, visualDensity: const VisualDensity(vertical: -3));

    await _pumpListTiles(tester, automotive: true);
    _expectListTileDensities(tester, dense: false, visualDensity: VisualDensity.standard);
  });
}

void _configureCarViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 600);
  tester.view.devicePixelRatio = 0.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpScaleHarness(WidgetTester tester, {required ValueChanged<MediaQueryData> onMediaQuery}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: app.formFactorScaleForTesting(
          child: Builder(
            builder: (context) {
              onMediaQuery(MediaQuery.of(context));
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpListTiles(WidgetTester tester, {required bool automotive}) async {
  TvDetectionService.debugSetAutomotiveOverride(automotive);
  // Unmount first: the tiles below are `const`, so pumping the same tree twice
  // hands the framework identical widget instances and the subtree is never
  // rebuilt — it would keep the density of the previous form factor.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: RadioGroup<int>(
            groupValue: 1,
            onChanged: (_) {},
            child: Column(
              children: [
                const FocusableListTile(title: Text('List')),
                const FocusableRadioListTile<int>(value: 1, title: Text('Radio')),
                FocusableSwitchListTile(value: true, onChanged: (_) {}, title: const Text('Switch')),
                FocusableCheckboxListTile(value: true, onChanged: (_) {}, title: const Text('Checkbox')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _expectListTileDensities(WidgetTester tester, {required bool dense, required VisualDensity visualDensity}) {
  final listTile = tester.widget<ListTile>(
    find.descendant(of: find.byType(FocusableListTile), matching: find.byType(ListTile)),
  );
  final radioTile = tester.widget<RadioListTile<int>>(find.byType(RadioListTile<int>));
  final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
  final checkboxTile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));

  expect(listTile.dense, dense);
  expect(listTile.visualDensity, visualDensity);
  expect(radioTile.dense, dense);
  expect(radioTile.visualDensity, visualDensity);
  expect(switchTile.dense, dense);
  expect(switchTile.visualDensity, visualDensity);
  expect(checkboxTile.dense, dense);
  expect(checkboxTile.visualDensity, visualDensity);
}
