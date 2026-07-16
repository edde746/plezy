import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/settings_binding_owner.dart';
import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';

class ThemeProvider extends ChangeNotifier with DisposableChangeNotifierMixin, WidgetsBindingObserver {
  late final SettingsBindingOwner _settingsBinding;
  settings.ThemeMode _themeMode = settings.ThemeMode.system;
  late Brightness _systemBrightness;

  ThemeProvider() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // Seed synchronously when settings are already loaded (main() initializes
    // them before runApp) so the first frame paints the persisted theme; the
    // async path below lands a microtask too late for the first build.
    final loaded = settings.SettingsService.instanceOrNull;
    if (loaded != null) _themeMode = loaded.read(settings.SettingsService.themeMode);
    _settingsBinding = SettingsBindingOwner(
      prefs: const [settings.SettingsService.themeMode],
      onRefresh: (service) => _syncThemeMode(service.read(settings.SettingsService.themeMode)),
    );
    unawaited(_settingsBinding.bind());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_themeMode == settings.ThemeMode.system) {
      safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsBinding.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    final service = _settingsBinding.settings ?? await settings.SettingsService.getInstance();
    await service.write(settings.SettingsService.themeMode, mode);
    if (_settingsBinding.settings == null) _syncThemeMode(mode);
  }

  Future<void> reload() async {
    await _settingsBinding.bind();
    final service = _settingsBinding.settings;
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
