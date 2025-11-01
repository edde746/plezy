import 'package:flutter/material.dart';
import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';

class ThemeProvider extends ChangeNotifier {
  late settings.SettingsService _settingsService;
  settings.ThemeMode _themeMode = settings.ThemeMode.system;
  late Brightness _systemBrightness;

  ThemeProvider() {
    _systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _initializeSettings();

    // Listen to system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          _systemBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          if (_themeMode == settings.ThemeMode.system) {
            notifyListeners();
          }
        };
  }

  Future<void> _initializeSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    _themeMode = _settingsService.getThemeMode();
    notifyListeners();
  }

  settings.ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => monoTheme(dark: false);
  ThemeData get darkTheme => monoTheme(dark: true);

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return ThemeMode.light;
      case settings.ThemeMode.dark:
        return ThemeMode.dark;
      case settings.ThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return false;
      case settings.ThemeMode.dark:
        return true;
      case settings.ThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  Future<void> setThemeMode(settings.ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _settingsService.setThemeMode(mode);
      notifyListeners();
    }
  }

  String get themeModeDisplayName {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return 'Light';
      case settings.ThemeMode.dark:
        return 'Dark';
      case settings.ThemeMode.system:
        return 'System';
    }
  }

  IconData get themeModeIcon {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return Icons.light_mode;
      case settings.ThemeMode.dark:
        return Icons.dark_mode;
      case settings.ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void toggleTheme() {
    switch (_themeMode) {
      case settings.ThemeMode.system:
        setThemeMode(settings.ThemeMode.light);
        break;
      case settings.ThemeMode.light:
        setThemeMode(settings.ThemeMode.dark);
        break;
      case settings.ThemeMode.dark:
        setThemeMode(settings.ThemeMode.system);
        break;
    }
  }
}
