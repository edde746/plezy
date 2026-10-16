import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/settings_utils.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/supporter_store_fakes.dart';

/// A saved Custom palette, distinct from every fixed one.
const _custom = MonoPalette(
  bg: material.Color(0xFF101820),
  surface: material.Color(0xFF1B2733),
  outline: material.Color(0x33FFFFFF),
  text: material.Color(0xFFF2F2F2),
  textMuted: material.Color(0xB3F2F2F2),
  accent: material.Color(0xFFFFB000),
);

SupporterService _supporter(SupporterAvailability availability, {bool purchased = false}) {
  final service = SupporterService.forTesting(availability: availability, purchased: purchased);
  addTearDown(service.dispose);
  return service;
}

/// A provider disposed at teardown, unlocked unless [supporter] says otherwise.
ThemeProvider _provider([SupporterService? supporter]) {
  final provider = ThemeProvider(supporter: supporter ?? _supporter(SupporterAvailability.free));
  addTearDown(provider.dispose);
  return provider;
}

Future<settings.SettingsService> _store(settings.ThemeMode mode, {MonoPalette? custom}) async {
  final service = await settings.SettingsService.getInstance();
  await service.write(settings.SettingsService.themeMode, mode);
  if (custom != null) await service.write(settings.SettingsService.customThemePalette, custom);
  return service;
}

void main() {
  setUp(resetSharedPreferencesForTest);
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('ThemeProvider', () {
    test('exposes a non-null themeMode immediately and flips after init', () async {
      final p = _provider();
      // The constructor synchronously sets _themeMode to system.
      expect(p.themeMode, settings.ThemeMode.system);

      // After init the value reflects what's persisted (default).
      // First-run default is computed by the EnumPref; it is one of the four
      // ThemeMode values regardless of whether we're on TV or not.
      // Wait a microtask for _initializeSettings() to finish.
      await Future.delayed(Duration.zero);
      expect(settings.ThemeMode.values, contains(p.themeMode));
    });

    test('setThemeMode persists, notifies, and is a no-op for same value', () async {
      final p = _provider();
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
    });

    test('materialThemeMode maps each ThemeMode value correctly', () async {
      final p = _provider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(p.materialThemeMode, material.ThemeMode.light);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(p.materialThemeMode, material.ThemeMode.dark);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.materialThemeMode, material.ThemeMode.dark);

      await p.setThemeMode(settings.ThemeMode.system);
      expect(p.materialThemeMode, material.ThemeMode.system);
    });

    test('isDarkMode reflects mode for explicit settings', () async {
      final p = _provider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(p.isDarkMode, isFalse);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(p.isDarkMode, isTrue);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.isDarkMode, isTrue);
    });

    test('darkTheme variants differ between dark and oled', () async {
      final p = _provider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.dark);
      final dark = p.darkTheme;
      await p.setThemeMode(settings.ThemeMode.oled);
      final oled = p.darkTheme;

      // OLED must be a true black canvas; regular dark uses a non-black surface.
      expect(oled.scaffoldBackgroundColor, const material.Color(0xFF000000));
      expect(dark.scaffoldBackgroundColor, isNot(const material.Color(0xFF000000)));
    });

    test('built-in Light, Dark and OLED paint their unchanged palettes', () async {
      final p = _provider(_supporter(SupporterAvailability.hidden));
      await Future.delayed(Duration.zero);

      for (final (mode, palette) in [
        (settings.ThemeMode.light, MonoPalette.light),
        (settings.ThemeMode.dark, MonoPalette.dark),
        (settings.ThemeMode.oled, MonoPalette.oled),
      ]) {
        await p.setThemeMode(mode);
        expect(p.themeMode, mode);
        final painted = palette.brightness == material.Brightness.light ? p.lightTheme : p.darkTheme;
        expect(identical(painted, monoTheme(palette)), isTrue, reason: mode.name);
      }
    });

    test('a dark preset paints the dark slot and leaves the light slot on Light', () async {
      final p = _provider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.ember);
      expect(p.materialThemeMode, material.ThemeMode.dark);
      expect(p.isDarkMode, isTrue);
      expect(p.darkTheme.scaffoldBackgroundColor, MonoPalette.ember.bg);
      expect(p.darkTheme.colorScheme.primary, MonoPalette.ember.accent);
      expect(identical(p.lightTheme, monoTheme(MonoPalette.light)), isTrue);
    });

    test('the light preset paints the light slot and leaves the dark slot on Dark', () async {
      final p = _provider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.paper);
      expect(p.materialThemeMode, material.ThemeMode.light);
      expect(p.isDarkMode, isFalse);
      expect(p.lightTheme.scaffoldBackgroundColor, MonoPalette.paper.bg);
      expect(p.lightTheme.colorScheme.primary, MonoPalette.paper.accent);
      expect(identical(p.darkTheme, monoTheme(MonoPalette.dark)), isTrue);
    });

    test('a fixed choice ignores platform brightness; System follows it', () {
      for (final mode in settings.ThemeMode.values) {
        final palette = ThemeProvider.resolve(mode, _custom, unlocked: true).palette;
        for (final platform in material.Brightness.values) {
          final expected = mode == settings.ThemeMode.system
              ? platform == material.Brightness.dark
              : palette!.brightness == material.Brightness.dark;
          expect(ThemeProvider.isDarkFor(palette, platform), expected, reason: '${mode.name} on ${platform.name}');
        }
      }
      expect(ThemeProvider.paletteFor(settings.ThemeMode.system), isNull);
    });

    test('every theme choice launches on a native splash mode Android knows', () {
      // PlezyActivity / ThemeHelper only map these four; anything else would
      // leave the launch window on the platform default.
      const known = {'system', 'light', 'dark', 'oled'};
      for (final mode in settings.ThemeMode.values) {
        final palette = ThemeProvider.resolve(mode, _custom, unlocked: true).palette;
        final native = ThemeProvider.nativeSplashMode(palette);
        expect(known, contains(native), reason: mode.name);
        if (palette != null) {
          expect(native == 'light', palette.brightness == material.Brightness.light, reason: mode.name);
        }
      }
      expect(ThemeProvider.nativeSplashMode(MonoPalette.oled), 'oled');
      expect(ThemeProvider.nativeSplashMode(MonoPalette.dark), 'dark');
      expect(ThemeProvider.nativeSplashMode(null), 'system');
    });

    test('an unknown persisted theme id falls back to the default', () async {
      // A preset id written by a newer build, read by this one.
      resetSharedPreferencesForTest(initialAsync: {settings.SettingsService.themeMode.key: 'neon'});
      final svc = await settings.SettingsService.getInstance();
      expect(svc.read(settings.SettingsService.themeMode), settings.SettingsService.themeMode.resolvedDefault);
    });

    test('themeModeLabel and themeModeIcon match the active mode', () async {
      final p = _provider();
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

      await _store(settings.ThemeMode.custom, custom: _custom);
      expect(themeModeLabel(p.themeMode), t.themeEditor.custom);
      expect(p.themeModeIcon, Symbols.format_paint_rounded);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(themeModeLabel(p.themeMode), t.settings.oledTheme);
      expect(p.themeModeIcon, Symbols.contrast_rounded);

      await p.setThemeMode(settings.ThemeMode.system);
      expect(themeModeLabel(p.themeMode), t.settings.systemTheme);
      expect(p.themeModeIcon, Symbols.brightness_auto_rounded);
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
      final p = _provider();
      await Future.delayed(Duration.zero);

      // Mutate the persisted theme out-of-band.
      final svc = await settings.SettingsService.getInstance();
      await svc.write(settings.SettingsService.themeMode, settings.ThemeMode.light);

      var notified = 0;
      p.addListener(() => notified++);

      await p.reload();
      expect(p.themeMode, settings.ThemeMode.light);
      expect(notified, 1);
    });

    test('persists across provider instances via SharedPreferences', () async {
      final supporter = _supporter(SupporterAvailability.free);
      final first = ThemeProvider(supporter: supporter);
      await Future.delayed(Duration.zero);
      await first.setThemeMode(settings.ThemeMode.forest);
      first.dispose();

      // Reset only the cached singleton — backing store is preserved.
      BaseSharedPreferencesService.resetForTesting();

      final second = _provider(supporter);
      await Future.delayed(Duration.zero);
      expect(second.themeMode, settings.ThemeMode.forest);
    });

    test('safeNotifyListeners no-ops after dispose', () async {
      final p = ThemeProvider(supporter: _supporter(SupporterAvailability.free));
      await Future.delayed(Duration.zero);
      p.dispose();
      await p.reload();
    });
  });

  group('Supporter gating', () {
    for (final (mode, palette) in [
      (settings.ThemeMode.ember, MonoPalette.ember),
      (settings.ThemeMode.paper, MonoPalette.paper),
      (settings.ThemeMode.custom, _custom),
    ]) {
      test('a locked ${mode.name} paints the default theme, keeps the stored choice and returns on unlock', () async {
        final svc = await _store(mode, custom: _custom);
        final supporter = _supporter(SupporterAvailability.purchasable);
        final p = _provider(supporter);
        await Future.delayed(Duration.zero);

        expect(p.themeMode, settings.ThemeMode.system);
        expect(p.materialThemeMode, material.ThemeMode.system);
        expect(identical(p.lightTheme, monoTheme(MonoPalette.light)), isTrue);
        expect(identical(p.darkTheme, monoTheme(MonoPalette.dark)), isTrue);
        expect(svc.read(settings.SettingsService.themeMode), mode);
        expect(svc.read(settings.SettingsService.customThemePalette), _custom);
        expect(p.lockedStoredThemeMode, mode);

        var notified = 0;
        p.addListener(() => notified++);
        await svc.write(settings.SettingsService.supporterEntitlementCached, true);
        await supporter.init();

        expect(supporter.isUnlocked, isTrue);
        expect(notified, 1);
        expect(p.themeMode, mode);
        expect(p.activePalette, palette);
        final painted = palette.brightness == material.Brightness.light ? p.lightTheme : p.darkTheme;
        expect(painted.scaffoldBackgroundColor, palette.bg);
        expect(painted.colorScheme.primary, palette.accent);
        expect(p.lockedStoredThemeMode, isNull);
      });
    }

    test('losing the entitlement falls back to System without touching the stored choice', () async {
      final svc = await _store(settings.ThemeMode.glacier);
      await svc.write(settings.SettingsService.supporterEntitlementCached, true);
      final platform = FakeInAppPurchasePlatform();
      addTearDown(platform.close);
      // Play answers the purchase query without the product: a confirmed refund.
      final supporter = SupporterService.forTesting(
        availability: SupporterAvailability.purchasable,
        store: FakePlayStore(platform).store,
      );
      addTearDown(supporter.dispose);
      final p = _provider(supporter);
      await Future.delayed(Duration.zero);
      expect(p.themeMode, settings.ThemeMode.glacier);

      await supporter.init();

      expect(supporter.isUnlocked, isFalse);
      expect(p.themeMode, settings.ThemeMode.system);
      expect(svc.read(settings.SettingsService.themeMode), settings.ThemeMode.glacier);
    });

    test('reports the saved choice only while the entitlement alone holds it back', () async {
      final svc = await _store(settings.ThemeMode.dark);
      final p = _provider(_supporter(SupporterAvailability.purchasable));
      await Future.delayed(Duration.zero);
      expect(p.lockedStoredThemeMode, isNull, reason: 'a built-in paints as saved');

      var notified = 0;
      p.addListener(() => notified++);
      await svc.write(settings.SettingsService.themeMode, settings.ThemeMode.glacier);
      expect(p.lockedStoredThemeMode, settings.ThemeMode.glacier);
      notified = 0;

      // Another locked perk paints the same System, but the saved choice moved.
      await svc.write(settings.SettingsService.themeMode, settings.ThemeMode.forest);
      expect(notified, 1);
      expect(p.themeMode, settings.ThemeMode.system);
      expect(p.lockedStoredThemeMode, settings.ThemeMode.forest);

      // Custom with nothing saved would paint System even if unlocked.
      await svc.write(settings.SettingsService.themeMode, settings.ThemeMode.custom);
      expect(p.lockedStoredThemeMode, isNull);
    });

    test('an unlocked saved perk is not reported as held back', () async {
      await _store(settings.ThemeMode.plum);
      final p = _provider();
      await Future.delayed(Duration.zero);
      expect(p.themeMode, settings.ThemeMode.plum);
      expect(p.lockedStoredThemeMode, isNull);
    });

    test('a build without the perks paints a stored preset as the default theme and built-ins as chosen', () async {
      final svc = await _store(settings.ThemeMode.forest);
      final p = _provider(_supporter(SupporterAvailability.hidden));
      await Future.delayed(Duration.zero);
      expect(p.themeMode, settings.ThemeMode.system);
      expect(svc.read(settings.SettingsService.themeMode), settings.ThemeMode.forest);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.themeMode, settings.ThemeMode.oled);
      expect(p.darkTheme.scaffoldBackgroundColor, MonoPalette.oled.bg);
    });

    test('Custom with no saved palette paints the default theme', () async {
      await _store(settings.ThemeMode.custom);
      final p = _provider();
      await Future.delayed(Duration.zero);
      expect(p.themeMode, settings.ThemeMode.system);
      expect(p.customPalette, isNull);
    });

    test('saving a new Custom palette repaints while Custom is selected', () async {
      final svc = await _store(settings.ThemeMode.custom, custom: _custom);
      final p = _provider();
      await Future.delayed(Duration.zero);
      expect(p.darkTheme.colorScheme.primary, _custom.accent);

      final edited = _custom.withColor(MonoPaletteSlot.accent, const material.Color(0xFF66CCFF));
      var notified = 0;
      p.addListener(() => notified++);
      await svc.write(settings.SettingsService.customThemePalette, edited);

      expect(notified, 1);
      expect(p.customPalette, edited);
      expect(p.darkTheme.colorScheme.primary, edited.accent);
    });

    test('the startup resolution matches what the provider settles on', () async {
      final cases = [
        (SupporterAvailability.hidden, false),
        (SupporterAvailability.purchasable, false),
        (SupporterAvailability.purchasable, true),
        (SupporterAvailability.free, false),
      ];
      for (final mode in [
        settings.ThemeMode.dark,
        settings.ThemeMode.plum,
        settings.ThemeMode.custom,
        settings.ThemeMode.system,
      ]) {
        final svc = await _store(mode, custom: _custom);
        for (final (availability, purchased) in cases) {
          final supporter = _supporter(availability, purchased: purchased);
          final p = _provider(supporter);
          await Future.delayed(Duration.zero);

          final startup = ThemeProvider.resolveStored(svc, unlocked: supporter.isUnlocked);
          final reason = '${mode.name} ${availability.name} purchased=$purchased';
          expect(startup.mode, p.themeMode, reason: reason);
          expect(ThemeProvider.materialThemeModeFor(startup.palette), p.materialThemeMode, reason: reason);
          expect(identical(ThemeProvider.lightThemeFor(startup.palette), p.lightTheme), isTrue, reason: reason);
          expect(identical(ThemeProvider.darkThemeFor(startup.palette), p.darkTheme), isTrue, reason: reason);
        }
      }

      // This build's own policy: the startup check and the provider's service
      // start from the same answer.
      final svc = await settings.SettingsService.getInstance();
      final live = SupporterService();
      addTearDown(live.dispose);
      await live.init();
      expect(SupporterService.startupUnlocked(svc), live.isUnlocked);
    });

    group('on TV, where a fresh install starts on OLED', () {
      setUp(() => TvDetectionService.debugSetAppleTVOverride(true));
      tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      test('a locked perk paints OLED and keeps the stored choice', () async {
        final svc = await _store(settings.ThemeMode.glacier);
        final p = _provider(_supporter(SupporterAvailability.purchasable));
        await Future.delayed(Duration.zero);

        expect(p.themeMode, settings.ThemeMode.oled);
        expect(p.materialThemeMode, material.ThemeMode.dark);
        expect(p.darkTheme.scaffoldBackgroundColor, MonoPalette.oled.bg);
        expect(p.lockedStoredThemeMode, settings.ThemeMode.glacier);
        expect(svc.read(settings.SettingsService.themeMode), settings.ThemeMode.glacier);
      });

      test('Custom with no saved palette paints OLED', () async {
        await _store(settings.ThemeMode.custom);
        final p = _provider();
        await Future.delayed(Duration.zero);

        expect(p.themeMode, settings.ThemeMode.oled);
        expect(p.lockedStoredThemeMode, isNull);
      });

      test('the startup resolution lands on the same OLED fallback', () async {
        final svc = await _store(settings.ThemeMode.ember);
        final p = _provider(_supporter(SupporterAvailability.purchasable));
        await Future.delayed(Duration.zero);

        final startup = ThemeProvider.resolveStored(svc, unlocked: false);
        expect(startup.mode, settings.ThemeMode.oled);
        expect(startup.mode, p.themeMode);
        expect(ThemeProvider.materialThemeModeFor(startup.palette), p.materialThemeMode);
        expect(identical(ThemeProvider.darkThemeFor(startup.palette), p.darkTheme), isTrue);
      });
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
