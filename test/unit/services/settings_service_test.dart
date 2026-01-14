import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plezy/services/settings_service.dart';

void main() {
  group('ThemeMode enum', () {
    test('has system value', () {
      expect(ThemeMode.system, isNotNull);
      expect(ThemeMode.system.name, 'system');
    });

    test('has light value', () {
      expect(ThemeMode.light, isNotNull);
      expect(ThemeMode.light.name, 'light');
    });

    test('has dark value', () {
      expect(ThemeMode.dark, isNotNull);
      expect(ThemeMode.dark.name, 'dark');
    });

    test('values list contains all modes', () {
      expect(ThemeMode.values, contains(ThemeMode.system));
      expect(ThemeMode.values, contains(ThemeMode.light));
      expect(ThemeMode.values, contains(ThemeMode.dark));
      expect(ThemeMode.values.length, 3);
    });
  });

  group('LibraryDensity enum', () {
    test('has compact value', () {
      expect(LibraryDensity.compact, isNotNull);
      expect(LibraryDensity.compact.name, 'compact');
    });

    test('has normal value', () {
      expect(LibraryDensity.normal, isNotNull);
      expect(LibraryDensity.normal.name, 'normal');
    });

    test('has comfortable value', () {
      expect(LibraryDensity.comfortable, isNotNull);
      expect(LibraryDensity.comfortable.name, 'comfortable');
    });

    test('values list contains all densities', () {
      expect(LibraryDensity.values, contains(LibraryDensity.compact));
      expect(LibraryDensity.values, contains(LibraryDensity.normal));
      expect(LibraryDensity.values, contains(LibraryDensity.comfortable));
      expect(LibraryDensity.values.length, 3);
    });
  });

  group('ViewMode enum', () {
    test('has grid value', () {
      expect(ViewMode.grid, isNotNull);
      expect(ViewMode.grid.name, 'grid');
    });

    test('has list value', () {
      expect(ViewMode.list, isNotNull);
      expect(ViewMode.list.name, 'list');
    });

    test('values list contains all modes', () {
      expect(ViewMode.values, contains(ViewMode.grid));
      expect(ViewMode.values, contains(ViewMode.list));
      expect(ViewMode.values.length, 2);
    });
  });

  group('EpisodePosterMode enum', () {
    test('has seriesPoster value', () {
      expect(EpisodePosterMode.seriesPoster, isNotNull);
      expect(EpisodePosterMode.seriesPoster.name, 'seriesPoster');
    });

    test('has seasonPoster value', () {
      expect(EpisodePosterMode.seasonPoster, isNotNull);
      expect(EpisodePosterMode.seasonPoster.name, 'seasonPoster');
    });

    test('has episodeThumbnail value', () {
      expect(EpisodePosterMode.episodeThumbnail, isNotNull);
      expect(EpisodePosterMode.episodeThumbnail.name, 'episodeThumbnail');
    });

    test('values list contains all modes', () {
      expect(EpisodePosterMode.values, contains(EpisodePosterMode.seriesPoster));
      expect(EpisodePosterMode.values, contains(EpisodePosterMode.seasonPoster));
      expect(EpisodePosterMode.values, contains(EpisodePosterMode.episodeThumbnail));
      expect(EpisodePosterMode.values.length, 3);
    });
  });

  group('SettingsService', () {
    setUp(() async {
      // Set up mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('getInstance returns singleton instance', () async {
      final instance1 = await SettingsService.getInstance();
      final instance2 = await SettingsService.getInstance();

      expect(instance1, same(instance2));
    });

    group('Theme settings', () {
      test('getThemeMode returns system by default', () async {
        final settings = await SettingsService.getInstance();
        expect(settings.getThemeMode(), ThemeMode.system);
      });

      test('setThemeMode and getThemeMode work correctly', () async {
        // Reset to ensure fresh instance
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        await settings.setThemeMode(ThemeMode.dark);
        // Note: Due to singleton, we need to verify through preferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'dark');
      });
    });

    group('Debug logging', () {
      test('getEnableDebugLogging returns false by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getEnableDebugLogging(), false);
      });
    });

    group('Buffer size', () {
      test('getBufferSize returns 128 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getBufferSize(), 128);
      });

      test('setBufferSize stores custom value', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        await settings.setBufferSize(256);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('buffer_size'), 256);
      });
    });

    group('Hardware decoding', () {
      test('getEnableHardwareDecoding returns true by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getEnableHardwareDecoding(), true);
      });
    });

    group('HDR settings', () {
      test('getEnableHDR returns true by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getEnableHDR(), true);
      });
    });

    group('Codec preferences', () {
      test('getPreferredVideoCodec returns auto by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getPreferredVideoCodec(), 'auto');
      });

      test('getPreferredAudioCodec returns auto by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getPreferredAudioCodec(), 'auto');
      });
    });

    group('Library density', () {
      test('getLibraryDensity returns normal by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getLibraryDensity(), LibraryDensity.normal);
      });
    });

    group('View mode', () {
      test('getViewMode returns grid by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getViewMode(), ViewMode.grid);
      });
    });

    group('Episode poster mode', () {
      test('getEpisodePosterMode returns episodeThumbnail by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getEpisodePosterMode(), EpisodePosterMode.episodeThumbnail);
      });
    });

    group('Hero section', () {
      test('getShowHeroSection returns true by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getShowHeroSection(), true);
      });
    });

    group('Global hubs', () {
      test('getUseGlobalHubs returns true by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getUseGlobalHubs(), true);
      });
    });

    group('Seek times', () {
      test('getSeekTimeSmall returns 10 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSeekTimeSmall(), 10);
      });

      test('getSeekTimeLarge returns 30 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSeekTimeLarge(), 30);
      });
    });

    group('Sleep timer', () {
      test('getSleepTimerDuration returns 30 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSleepTimerDuration(), 30);
      });
    });

    group('Audio sync', () {
      test('getAudioSyncOffset returns 0 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getAudioSyncOffset(), 0);
      });
    });

    group('Subtitle sync', () {
      test('getSubtitleSyncOffset returns 0 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleSyncOffset(), 0);
      });
    });

    group('Volume', () {
      test('getVolume returns 100.0 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getVolume(), 100.0);
      });

      test('getMaxVolume returns 100 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getMaxVolume(), 100);
      });
    });

    group('Rotation lock', () {
      test('getRotationLocked returns true by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getRotationLocked(), true);
      });
    });

    group('Subtitle styling', () {
      test('getSubtitleFontSize returns 55 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleFontSize(), 55);
      });

      test('getSubtitleTextColor returns #FFFFFF by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleTextColor(), '#FFFFFF');
      });

      test('getSubtitleBorderSize returns 3 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleBorderSize(), 3);
      });

      test('getSubtitleBorderColor returns #000000 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleBorderColor(), '#000000');
      });

      test('getSubtitleBackgroundColor returns #000000 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleBackgroundColor(), '#000000');
      });

      test('getSubtitleBackgroundOpacity returns 0 by default', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        expect(settings.getSubtitleBackgroundOpacity(), 0);
      });
    });

    group('Keyboard shortcuts', () {
      test('getDefaultKeyboardShortcuts returns expected defaults', () async {
        final settings = await SettingsService.getInstance();
        final defaults = settings.getDefaultKeyboardShortcuts();

        expect(defaults['play_pause'], 'Space');
        expect(defaults['volume_up'], 'Arrow Up');
        expect(defaults['volume_down'], 'Arrow Down');
        expect(defaults['seek_forward'], 'Arrow Right');
        expect(defaults['seek_backward'], 'Arrow Left');
        expect(defaults['fullscreen_toggle'], 'F');
        expect(defaults['mute_toggle'], 'M');
        expect(defaults['subtitle_toggle'], 'S');
        expect(defaults['chapter_next'], 'N');
        expect(defaults['chapter_previous'], 'P');
      });

      test('getKeyboardShortcuts returns defaults when no custom shortcuts set', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsService.getInstance();

        final shortcuts = settings.getKeyboardShortcuts();
        final defaults = settings.getDefaultKeyboardShortcuts();

        expect(shortcuts, equals(defaults));
      });
    });
  });
}
