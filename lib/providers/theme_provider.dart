import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart' show windowManager;
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/native_window_service.dart';
import '../services/settings_binding_owner.dart';
import '../services/settings_service.dart' as settings;
import '../theme/mono_theme.dart';
import '../utils/app_logger.dart';

class ThemeProvider extends ChangeNotifier with DisposableChangeNotifierMixin, WidgetsBindingObserver {
  late final SettingsBindingOwner _settingsBinding;
  settings.ThemeMode _themeMode = settings.ThemeMode.system;
  late Brightness _systemBrightness;
  bool? _windowChromeDark;

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
    _syncWindowChrome();
  }

  @override
  void didChangePlatformBrightness() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_themeMode == settings.ThemeMode.system) {
      _syncWindowChrome();
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
    _syncWindowChrome();
    if (changed || forceNotify) safeNotifyListeners();
  }

  settings.ThemeMode get themeMode => _themeMode;

  /// The fixed palette [mode] paints with, or null for [settings.ThemeMode.system],
  /// which follows the platform between Light and Dark.
  static MonoPalette? paletteFor(settings.ThemeMode mode) => switch (mode) {
    settings.ThemeMode.system => null,
    settings.ThemeMode.light => MonoPalette.light,
    settings.ThemeMode.dark => MonoPalette.dark,
    settings.ThemeMode.oled => MonoPalette.oled,
    settings.ThemeMode.ember => MonoPalette.ember,
    settings.ThemeMode.glacier => MonoPalette.glacier,
    settings.ThemeMode.forest => MonoPalette.forest,
    settings.ThemeMode.plum => MonoPalette.plum,
    settings.ThemeMode.paper => MonoPalette.paper,
  };

  /// Light-slot theme for [mode]: its own palette when that palette is light,
  /// otherwise Light (the System theme's light half).
  ///
  /// Static, like [darkThemeFor], so the pre-provider startup frame resolves
  /// the same theme this provider will settle on (#1833).
  static ThemeData lightThemeFor(settings.ThemeMode mode) {
    final palette = paletteFor(mode);
    return monoTheme(palette?.brightness == Brightness.light ? palette! : MonoPalette.light);
  }

  /// Dark-slot theme for [mode]: its own palette when that palette is dark,
  /// otherwise Dark (the System theme's dark half).
  ///
  /// Static so the pre-provider startup frame can resolve the same theme this
  /// provider will settle on, instead of guessing from platform brightness
  /// and flashing when the two disagree (#1833).
  static ThemeData darkThemeFor(settings.ThemeMode mode) {
    final palette = paletteFor(mode);
    return monoTheme(palette?.brightness == Brightness.dark ? palette! : MonoPalette.dark);
  }

  /// Material equivalent of the app's own [settings.ThemeMode]: system for
  /// System, otherwise the brightness of the fixed palette.
  static ThemeMode materialThemeModeFor(settings.ThemeMode mode) => switch (paletteFor(mode)?.brightness) {
    null => ThemeMode.system,
    Brightness.light => ThemeMode.light,
    Brightness.dark => ThemeMode.dark,
  };

  ThemeData get lightTheme => lightThemeFor(_themeMode);
  ThemeData get darkTheme => darkThemeFor(_themeMode);

  ThemeMode get materialThemeMode => materialThemeModeFor(_themeMode);

  /// Whether [mode] resolves to a dark theme when the platform reports [platformBrightness].
  static bool isDarkFor(settings.ThemeMode mode, Brightness platformBrightness) =>
      (paletteFor(mode)?.brightness ?? platformBrightness) == Brightness.dark;

  bool get isDarkMode => isDarkFor(_themeMode, _systemBrightness);

  /// Themes the native window frame, which Flutter does not paint, to match the app.
  ///
  /// Neither desktop frame follows the app on its own: the GTK3 title bar on Linux keeps the GTK theme's light
  /// variant even under GNOME's dark style, and the Windows caption follows the OS app theme (#2622). macOS needs
  /// nothing: its title bar is transparent over Flutter content. Best-effort, because a frame left in the platform's
  /// own theme is the correct fallback.
  ///
  /// Static so startup can theme the frame as soon as settings load, before this provider exists.
  static void applyWindowChromeBrightness(bool dark) {
    final Future<void> applied;
    if (Platform.isLinux) {
      applied = windowManager.setBrightness(dark ? Brightness.dark : Brightness.light);
    } else if (Platform.isWindows) {
      applied = NativeWindowService.setDarkMode(dark);
    } else {
      return;
    }
    unawaited(
      applied.catchError((Object error, StackTrace stackTrace) {
        appLogger.d('Window frame theme not applied', error: error, stackTrace: stackTrace);
      }),
    );
  }

  void _syncWindowChrome() {
    if (isDisposed) return;
    final dark = isDarkMode;
    if (_windowChromeDark == dark) return;
    _windowChromeDark = dark;
    applyWindowChromeBrightness(dark);
  }

  static const _themeChannel = MethodChannel('com.plezy/theme');

  @visibleForTesting
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
    _themeChannel.invokeMethod('setSplashTheme', {'mode': nativeSplashMode(mode)});
  }

  /// Launch-screen mode the Android side understands. It only knows the
  /// built-in launch colours (`ThemeHelper.themeColor` and the `SplashTheme_*`
  /// styles), so a preset launches on the nearest built-in: the dark presets
  /// on Dark, Paper on Light. The first Flutter frame then paints the preset.
  @visibleForTesting
  static String nativeSplashMode(settings.ThemeMode mode) => switch (mode) {
    settings.ThemeMode.system => 'system',
    settings.ThemeMode.light || settings.ThemeMode.paper => 'light',
    settings.ThemeMode.dark ||
    settings.ThemeMode.ember ||
    settings.ThemeMode.glacier ||
    settings.ThemeMode.forest ||
    settings.ThemeMode.plum => 'dark',
    settings.ThemeMode.oled => 'oled',
  };

  IconData get themeModeIcon => switch (_themeMode) {
    settings.ThemeMode.light => Symbols.light_mode_rounded,
    settings.ThemeMode.dark => Symbols.dark_mode_rounded,
    settings.ThemeMode.oled => Symbols.contrast_rounded,
    settings.ThemeMode.system => Symbols.brightness_auto_rounded,
    settings.ThemeMode.ember ||
    settings.ThemeMode.glacier ||
    settings.ThemeMode.forest ||
    settings.ThemeMode.plum ||
    settings.ThemeMode.paper => Symbols.palette_rounded,
  };
}
