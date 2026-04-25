import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart' as settings;

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

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

      // Same value → no notify.
      await p.setThemeMode(next);
      expect(notified, 1);

      // Verify persisted via SettingsService.
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

    test('themeModeDisplayName and themeModeIcon match the active mode', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);

      await p.setThemeMode(settings.ThemeMode.light);
      expect(p.themeModeDisplayName, 'Light');
      expect(p.themeModeIcon, Symbols.light_mode_rounded);

      await p.setThemeMode(settings.ThemeMode.dark);
      expect(p.themeModeDisplayName, 'Dark');
      expect(p.themeModeIcon, Symbols.dark_mode_rounded);

      await p.setThemeMode(settings.ThemeMode.oled);
      expect(p.themeModeDisplayName, 'OLED');
      expect(p.themeModeIcon, Symbols.contrast_rounded);

      await p.setThemeMode(settings.ThemeMode.system);
      expect(p.themeModeDisplayName, 'System');
      expect(p.themeModeIcon, Symbols.brightness_auto_rounded);

      p.dispose();
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
      await first.setThemeMode(settings.ThemeMode.dark);
      first.dispose();

      // Reset only the cached singleton — backing store is preserved.
      BaseSharedPreferencesService.resetForTesting();

      final second = ThemeProvider();
      await Future.delayed(Duration.zero);
      expect(second.themeMode, settings.ThemeMode.dark);
      second.dispose();
    });

    test('safeNotifyListeners no-ops after dispose', () async {
      final p = ThemeProvider();
      await Future.delayed(Duration.zero);
      p.dispose();
      // Should not throw — reload calls safeNotifyListeners under the hood.
      await p.reload();
    });
  });
}
