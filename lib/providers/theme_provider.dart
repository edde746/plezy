import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';

class ThemeProvider extends ChangeNotifier {
  late settings.SettingsService _settingsService;
  settings.ThemeMode _themeMode = settings.ThemeMode.system;
  late Brightness _systemBrightness;

  ThemeProvider() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _initializeSettings();

    // Listen to system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
  ThemeData get oledTheme => monoTheme(dark: true, oled: true);

  /// Returns the appropriate theme based on the current mode.
  /// For OLED mode, returns the OLED dark theme.
  ThemeData get currentDarkTheme {
    return _themeMode == settings.ThemeMode.oled ? oledTheme : darkTheme;
  }

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return ThemeMode.light;
      case settings.ThemeMode.dark:
      case settings.ThemeMode.oled:
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
      case settings.ThemeMode.oled:
        return true;
      case settings.ThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  bool get isOledMode => _themeMode == settings.ThemeMode.oled;

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
      case settings.ThemeMode.oled:
        return 'OLED Black';
      case settings.ThemeMode.system:
        return 'System';
    }
  }

  IconData get themeModeIcon {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return Symbols.light_mode_rounded;
      case settings.ThemeMode.dark:
        return Symbols.dark_mode_rounded;
      case settings.ThemeMode.oled:
        return Symbols.brightness_high_rounded;
      case settings.ThemeMode.system:
        return Symbols.brightness_auto_rounded;
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
        setThemeMode(settings.ThemeMode.oled);
        break;
      case settings.ThemeMode.oled:
        setThemeMode(settings.ThemeMode.system);
        break;
    }
  }
}
