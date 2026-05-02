import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';

class ThemeProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  settings.SettingsService? _settingsService;
  ValueNotifier<settings.ThemeMode>? _themeModeListenable;
  settings.ThemeMode _themeMode = settings.ThemeMode.system;
  late Brightness _systemBrightness;

  ThemeProvider() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _initializeSettings();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = _onBrightnessChanged;
  }

  void _onBrightnessChanged() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_themeMode == settings.ThemeMode.system) {
      safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _themeModeListenable?.removeListener(_onThemeModeSettingChanged);
    if (WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged == _onBrightnessChanged) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    }
    super.dispose();
  }

  Future<void> _initializeSettings() async {
    final service = await settings.SettingsService.getInstance();
    if (_settingsService == service && _themeModeListenable != null) {
      _syncThemeMode(service.read(settings.SettingsService.themeMode));
      return;
    }

    _themeModeListenable?.removeListener(_onThemeModeSettingChanged);
    _settingsService = service;
    _themeModeListenable = service.listenable(settings.SettingsService.themeMode)
      ..addListener(_onThemeModeSettingChanged);
    _syncThemeMode(_themeModeListenable!.value);
  }

  void _onThemeModeSettingChanged() {
    final listenable = _themeModeListenable;
    if (listenable == null) return;
    _syncThemeMode(listenable.value);
  }

  void _syncThemeMode(settings.ThemeMode mode, {bool forceNotify = false}) {
    final changed = _themeMode != mode;
    _themeMode = mode;
    _updateSplashTheme(mode);
    if (changed || forceNotify) safeNotifyListeners();
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

  static const _themeChannel = MethodChannel('com.plezy/theme');

  Future<void> setThemeMode(settings.ThemeMode mode) async {
    if (_themeMode == mode) return;
    final service = _settingsService ?? await settings.SettingsService.getInstance();
    await service.write(settings.SettingsService.themeMode, mode);
    if (_themeModeListenable == null) _syncThemeMode(mode);
  }

  /// Re-read the theme mode from SharedPreferences. Used after imports or
  /// resets that change persisted settings outside this provider.
  Future<void> reload() async {
    await _initializeSettings();
    final service = _settingsService;
    if (service != null) _syncThemeMode(service.read(settings.SettingsService.themeMode), forceNotify: true);
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
}
