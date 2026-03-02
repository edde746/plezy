import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _updateSplashTheme(_themeMode);
    notifyListeners();
  }

  settings.ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => monoTheme(dark: false);
  ThemeData get darkTheme {
    if (_themeMode == settings.ThemeMode.oled) {
      return monoTheme(dark: true, oled: true);
    }
    return monoTheme(dark: true);
  }

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return ThemeMode.light;
      case settings.ThemeMode.dark:
        return ThemeMode.dark;
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
        return true;
      case settings.ThemeMode.oled:
        return true;
      case settings.ThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  static const _themeChannel = MethodChannel('app.plezy/theme');

  Future<void> setThemeMode(settings.ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _settingsService.setThemeMode(mode);
      _updateSplashTheme(mode);
      notifyListeners();
    }
  }

  void _updateSplashTheme(settings.ThemeMode mode) {
    if (!Platform.isAndroid) return;
    final name = switch (mode) {
      settings.ThemeMode.dark => 'dark',
      settings.ThemeMode.oled => 'oled',
      settings.ThemeMode.light => 'light',
      settings.ThemeMode.system => 'system',
    };
    _themeChannel.invokeMethod('setSplashTheme', {'mode': name});
  }

  String get themeModeDisplayName {
    switch (_themeMode) {
      case settings.ThemeMode.light:
        return 'Light';
      case settings.ThemeMode.dark:
        return 'Dark';
      case settings.ThemeMode.oled:
        return 'OLED';
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
        return Symbols.contrast_rounded;
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
