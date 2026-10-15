import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/settings_utils.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/theme/mono_theme.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('ThemeProvider', () {
    test('exposes a non-null themeMode immediately and flips after init', () async {
      final p = ThemeProvider();
      // The constructor synchronously sets _themeMode to system.
      expect(p.themeMode, settings.ThemeMode.system);

      // After init the value reflects what's persisted (default).
      // First-run default is computed by the EnumPref; it is one of the four
      // ThemeMode values regardless of whether we're on TV or not.
      // Wait a microtask for _initializeSettings() to finish.
      await Future.delayed(Duration.zero);
      expect(settings.ThemeMode.values, contains(p.themeMode));

      p.dispose();
    });

    test('setThemeMode persists, notifies, and is a no-op for same value', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      var notified = 0;
      p.addListener(() => notified++);

      // Pick a mode that is guaranteed different from default `system`/`oled`
      // on either pathway: cycle through values until we hit one that differs.
      final initial = p.themeMode;
      final next = settings.ThemeMode.values.firstWhere((m) => m != initial);
      await p.setThemeMode(next);
      expect(p.themeMode, next);
      expect(notified, 1);

      await p.setThemeMode(next);
      expect(notified, 1);

      final svc = await settings.SettingsService.getInstance();
      expect(svc.read(settings.SettingsService.themeMode), next);

      p.dispose();
    });

    test('materialThemeMode maps each ThemeMode value correctly', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(p.materialThemeMode, material.ThemeMode.light);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(p.materialThemeMode, material.ThemeMode.dark);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.materialThemeMode, material.ThemeMode.dark);

      await p.setThemeMode(settings.ThemeMode.system);
      expect(p.materialThemeMode, material.ThemeMode.system);

      p.dispose();
    });

    test('isDarkMode reflects mode for explicit settings', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(p.isDarkMode, isFalse);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(p.isDarkMode, isTrue);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.isDarkMode, isTrue);

      p.dispose();
    });

    test('darkTheme variants differ between dark and oled', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.dark);
      final dark = p.darkTheme;
      await p.setThemeMode(settings.ThemeMode.oled);
      final oled = p.darkTheme;

      // OLED must be a true black canvas; regular dark uses a non-black surface.
      expect(oled.scaffoldBackgroundColor, const material.Color(0xFF000000));
      expect(dark.scaffoldBackgroundColor, isNot(const material.Color(0xFF000000)));

      p.dispose();
    });

    test('a dark preset paints the dark slot and leaves the light slot on Light', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.ember);
      expect(p.materialThemeMode, material.ThemeMode.dark);
      expect(p.isDarkMode, isTrue);
      expect(p.darkTheme.scaffoldBackgroundColor, MonoPalette.ember.bg);
      expect(p.darkTheme.colorScheme.primary, MonoPalette.ember.accent);
      expect(identical(p.lightTheme, monoTheme(MonoPalette.light)), isTrue);

      p.dispose();
    });

    test('the light preset paints the light slot and leaves the dark slot on Dark', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.paper);
      expect(p.materialThemeMode, material.ThemeMode.light);
      expect(p.isDarkMode, isFalse);
      expect(p.lightTheme.scaffoldBackgroundColor, MonoPalette.paper.bg);
      expect(p.lightTheme.colorScheme.primary, MonoPalette.paper.accent);
      expect(identical(p.darkTheme, monoTheme(MonoPalette.dark)), isTrue);

      p.dispose();
    });

    test('a fixed choice ignores platform brightness; System follows it', () {
      for (final mode in settings.ThemeMode.values) {
        final palette = ThemeProvider.paletteFor(mode);
        for (final platform in material.Brightness.values) {
          final expected = (palette?.brightness ?? platform) == material.Brightness.dark;
          expect(ThemeProvider.isDarkFor(mode, platform), expected, reason: '${mode.name} on ${platform.name}');
        }
      }
      expect(ThemeProvider.paletteFor(settings.ThemeMode.system), isNull);
    });

    test('every theme choice launches on a native splash mode Android knows', () {
      // MainActivity / ThemeHelper only map these four; anything else would
      // leave the launch window on the platform default.
      const known = {'system', 'light', 'dark', 'oled'};
      for (final mode in settings.ThemeMode.values) {
        final native = ThemeProvider.nativeSplashMode(mode);
        expect(known, contains(native), reason: mode.name);
        final palette = ThemeProvider.paletteFor(mode);
        if (palette != null) {
          expect(native == 'light', palette.brightness == material.Brightness.light, reason: mode.name);
        }
      }
      expect(ThemeProvider.nativeSplashMode(settings.ThemeMode.oled), 'oled');
      expect(ThemeProvider.nativeSplashMode(settings.ThemeMode.dark), 'dark');
    });

    test('an unknown persisted theme id falls back to the default', () async {
      // A preset id written by a newer build, read by this one.
      resetSharedPreferencesForTest(initialAsync: {settings.SettingsService.themeMode.key: 'neon'});
      final svc = await settings.SettingsService.getInstance();
      expect(svc.read(settings.SettingsService.themeMode), settings.SettingsService.themeMode.resolvedDefault);
    });

    test('themeModeLabel and themeModeIcon match the active mode', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(themeModeLabel(p.themeMode), t.settings.lightTheme);
      expect(p.themeModeIcon, Symbols.light_mode_rounded);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(themeModeLabel(p.themeMode), t.settings.darkTheme);
      expect(p.themeModeIcon, Symbols.dark_mode_rounded);

      await p.setThemeMode(settings.ThemeMode.glacier);
      expect(themeModeLabel(p.themeMode), t.settings.glacierTheme);
      expect(p.themeModeIcon, Symbols.palette_rounded);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(themeModeLabel(p.themeMode), t.settings.oledTheme);
      expect(p.themeModeIcon, Symbols.contrast_rounded);

      await p.setThemeMode(settings.ThemeMode.system);
      expect(themeModeLabel(p.themeMode), t.settings.systemTheme);
      expect(p.themeModeIcon, Symbols.brightness_auto_rounded);

      p.dispose();
    });

    test('themeModeLabel follows a non-English locale for every mode', () async {
      await LocaleSettings.setLocale(AppLocale.de);
      try {
        expect(themeModeLabel(settings.ThemeMode.system), 'System');
        expect(themeModeLabel(settings.ThemeMode.light), 'Hell');
        expect(themeModeLabel(settings.ThemeMode.dark), 'Dunkel');
        expect(themeModeLabel(settings.ThemeMode.oled), 'OLED');
        // Preset names are untranslated and fall back to English.
        expect(themeModeLabel(settings.ThemeMode.ember), 'Ember');
      } finally {
        LocaleSettings.setLocaleSync(AppLocale.en);
      }
    });

    test('reload re-reads after external mutation', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      // Mutate the persisted theme out-of-band.
      final svc = await settings.SettingsService.getInstance();
      await svc.write(settings.SettingsService.themeMode, settings.ThemeMode.light);

      var notified = 0;
      p.addListener(() => notified++);

      await p.reload();
      expect(p.themeMode, settings.ThemeMode.light);
      expect(notified, 1);

      p.dispose();
    });

    test('persists across provider instances via SharedPreferences', () async {
      final first = ThemeProvider();
      await Future.delayed(Duration.zero);
      await first.setThemeMode(settings.ThemeMode.forest);
      first.dispose();

      // Reset only the cached singleton — backing store is preserved.
      BaseSharedPreferencesService.resetForTesting();

      final second = ThemeProvider();
      await Future.delayed(Duration.zero);
      expect(second.themeMode, settings.ThemeMode.forest);
      second.dispose();
    });

    test('safeNotifyListeners no-ops after dispose', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);
      p.dispose();
      await p.reload();
    });
  });

  testWidgets('regex dialog localizes its field label and validation error', (tester) async {
    // `runAsync`: a deferred locale library loads on the real event loop, and
    // the widget tester's fake async never pumps it. Awaiting the load
    // directly hangs the test whenever the library is not already resident —
    // running this file alone, under a name filter, or sharded away from the
    // `themeModeLabel` test above that happens to load `de` first.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.de));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

    await tester.pumpWidget(
      material.MaterialApp(
        home: material.Scaffold(
          body: material.Builder(
            builder: (context) => material.TextButton(
              onPressed: () => showRegexInputDialog(
                context: context,
                title: 'Muster',
                currentValue: '^intro',
                defaultValue: '',
                onSave: (_) async {},
              ),
              child: const material.Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Regulärer Ausdruck'), findsOneWidget);

    await tester.enterText(find.byType(material.TextField), '[');
    await tester.pump();
    expect(find.text('Ungültiger regulärer Ausdruck'), findsOneWidget);
  });
}
