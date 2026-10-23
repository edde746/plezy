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
import '../services/supporter/supporter_service.dart';
import '../theme/mono_theme.dart';
import '../utils/app_logger.dart';

/// What the app paints: the effective theme [mode] and its [palette], null for
/// System, which follows the platform between Light and Dark.
typedef ThemeChoice = ({settings.ThemeMode mode, MonoPalette? palette});

class ThemeProvider extends ChangeNotifier with DisposableChangeNotifierMixin, WidgetsBindingObserver {
  final SupporterService _supporter;
  late final SettingsBindingOwner _settingsBinding;
  settings.ThemeMode _storedMode = settings.ThemeMode.system;
  MonoPalette? _customPalette;
  late ThemeChoice _choice;
  late Brightness _systemBrightness;
  bool? _windowChromeDark;

  /// Gated by the [SupporterService]: a stored preset or Custom paints only
  /// while it is unlocked, and reappears as soon as it is.
  ThemeProvider({required this._supporter}) {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // Seed synchronously when settings are already loaded (main() initializes
    // them before runApp) so the first frame paints the persisted theme; the
    // async path below lands a microtask too late for the first build.
    final loaded = settings.SettingsService.instanceOrNull;
    if (loaded != null) _readStored(loaded);
    _choice = _resolve();
    _supporter.addListener(_apply);
    _settingsBinding = SettingsBindingOwner(
      prefs: [settings.SettingsService.themeMode, settings.SettingsService.customThemePalette],
      onRefresh: (service) {
        final previous = (_storedMode, _customPalette);
        _readStored(service);
        // A stored change that paints the same still changes what the picker
        // shows (the saved-but-locked marker, the Custom swatch).
        _apply(pushSplash: true, forceNotify: (_storedMode, _customPalette) != previous);
      },
    );
    unawaited(_settingsBinding.bind());
    WidgetsBinding.instance.addObserver(this);
    _syncWindowChrome();
  }

  @override
  void didChangePlatformBrightness() {
    _systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_choice.palette == null) {
      _syncWindowChrome();
      safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsBinding.dispose();
    _supporter.removeListener(_apply);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _readStored(settings.SettingsService service) {
    _storedMode = service.read(settings.SettingsService.themeMode);
    _customPalette = service.read(settings.SettingsService.customThemePalette);
  }

  ThemeChoice _resolve() => resolve(_storedMode, _customPalette, unlocked: _supporter.isUnlocked);

  /// Re-resolves after the stored choice or the Supporter entitlement changed.
  /// The stored choice is never rewritten: losing the entitlement only changes
  /// what paints, and regaining it brings the choice back.
  void _apply({bool pushSplash = false, bool forceNotify = false}) {
    if (isDisposed) return;
    final next = _resolve();
    final changed = next != _choice;
    _choice = next;
    if (changed || pushSplash) _updateSplashTheme(next.palette);
    _syncWindowChrome();
    if (changed || forceNotify) safeNotifyListeners();
  }

  /// The effective theme: the stored choice, or the device's default theme
  /// (see [resolve]) while that choice is a locked Supporter perk.
  settings.ThemeMode get themeMode => _choice.mode;

  /// The palette on screen right now, with System resolved against the
  /// platform brightness.
  MonoPalette get activePalette => _choice.palette ?? (isDarkMode ? MonoPalette.dark : MonoPalette.light);

  /// The saved Custom palette, whether or not Custom is selected or unlocked.
  MonoPalette? get customPalette => _customPalette;

  /// The saved choice while only a missing Supporter entitlement keeps it off
  /// screen, so the picker can show it is still saved; null when the saved
  /// choice is what paints, or would not paint even if unlocked.
  settings.ThemeMode? get lockedStoredThemeMode {
    final ifUnlocked = resolve(_storedMode, _customPalette, unlocked: true).mode;
    return ifUnlocked == _choice.mode ? null : ifUnlocked;
  }

  /// What [stored] paints. A Supporter perk applies only while [unlocked], and
  /// Custom only once a palette is saved; otherwise the app paints the theme a
  /// fresh install gets on this device (System, OLED on TV), read from the
  /// pref's own default so the TV rule lives in one place.
  ///
  /// Static so the pre-provider startup frame resolves through the same rule
  /// and never flashes a locked perk or the fallback for an unlocked one. It
  /// runs after TV detection there, like the pref default it reads.
  static ThemeChoice resolve(settings.ThemeMode stored, MonoPalette? customPalette, {required bool unlocked}) {
    final locked = stored.isSupporterPerk && !unlocked;
    final missingCustom = stored == settings.ThemeMode.custom && customPalette == null;
    final mode = locked || missingCustom ? settings.SettingsService.themeMode.resolvedDefault : stored;
    return (mode: mode, palette: paletteFor(mode, customPalette: customPalette));
  }

  /// [resolve] for the choice stored in [service].
  static ThemeChoice resolveStored(settings.SettingsService service, {required bool unlocked}) => resolve(
    service.read(settings.SettingsService.themeMode),
    service.read(settings.SettingsService.customThemePalette),
    unlocked: unlocked,
  );

  /// The palette [mode] paints with: [customPalette] for Custom, null for
  /// System, which follows the platform between Light and Dark.
  static MonoPalette? paletteFor(settings.ThemeMode mode, {MonoPalette? customPalette}) => switch (mode) {
    settings.ThemeMode.system => null,
    settings.ThemeMode.light => MonoPalette.light,
    settings.ThemeMode.dark => MonoPalette.dark,
    settings.ThemeMode.oled => MonoPalette.oled,
    settings.ThemeMode.ember => MonoPalette.ember,
    settings.ThemeMode.glacier => MonoPalette.glacier,
    settings.ThemeMode.forest => MonoPalette.forest,
    settings.ThemeMode.plum => MonoPalette.plum,
    settings.ThemeMode.paper => MonoPalette.paper,
    settings.ThemeMode.custom => customPalette,
  };

  /// Light-slot theme for [palette]: the palette itself when it is light,
  /// otherwise Light (the System theme's light half).
  ///
  /// Static, like [darkThemeFor], so the pre-provider startup frame resolves
  /// the same theme this provider will settle on (#1833).
  static ThemeData lightThemeFor(MonoPalette? palette) =>
      monoTheme(palette?.brightness == Brightness.light ? palette! : MonoPalette.light);

  /// Dark-slot theme for [palette]: the palette itself when it is dark,
  /// otherwise Dark (the System theme's dark half).
  ///
  /// Static so the pre-provider startup frame can resolve the same theme this
  /// provider will settle on, instead of guessing from platform brightness
  /// and flashing when the two disagree (#1833).
  static ThemeData darkThemeFor(MonoPalette? palette) =>
      monoTheme(palette?.brightness == Brightness.dark ? palette! : MonoPalette.dark);

  /// Material equivalent of [palette]: system for System (null), otherwise
  /// the palette's brightness.
  static ThemeMode materialThemeModeFor(MonoPalette? palette) => switch (palette?.brightness) {
    null => ThemeMode.system,
    Brightness.light => ThemeMode.light,
    Brightness.dark => ThemeMode.dark,
  };

  ThemeData get lightTheme => lightThemeFor(_choice.palette);
  ThemeData get darkTheme => darkThemeFor(_choice.palette);

  ThemeMode get materialThemeMode => materialThemeModeFor(_choice.palette);

  /// Whether [palette] resolves to a dark theme when the platform reports [platformBrightness].
  static bool isDarkFor(MonoPalette? palette, Brightness platformBrightness) =>
      (palette?.brightness ?? platformBrightness) == Brightness.dark;

  bool get isDarkMode => isDarkFor(_choice.palette, _systemBrightness);

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
    final service = _settingsBinding.settings ?? await settings.SettingsService.getInstance();
    if (service.read(settings.SettingsService.themeMode) == mode) return;
    await service.write(settings.SettingsService.themeMode, mode);
    if (_settingsBinding.settings == null) {
      _readStored(service);
      _apply(pushSplash: true);
    }
  }

  Future<void> reload() async {
    await _settingsBinding.bind();
    final service = _settingsBinding.settings;
    if (service == null) return;
    _readStored(service);
    _apply(pushSplash: true, forceNotify: true);
  }

  void _updateSplashTheme(MonoPalette? palette) {
    if (!Platform.isAndroid) return;
    _themeChannel.invokeMethod('setSplashTheme', {'mode': nativeSplashMode(palette)});
  }

  /// Launch-screen mode the Android side understands for [palette]. It only
  /// knows the built-in launch colours (`ThemeHelper.themeColor` and the
  /// `SplashTheme_*` styles), so a preset or custom palette launches on the
  /// nearest built-in by brightness. The first Flutter frame then paints it.
  @visibleForTesting
  static String nativeSplashMode(MonoPalette? palette) {
    if (palette == null) return 'system';
    if (palette == MonoPalette.oled) return 'oled';
    return palette.brightness == Brightness.light ? 'light' : 'dark';
  }

  IconData get themeModeIcon => switch (_choice.mode) {
    settings.ThemeMode.light => Symbols.light_mode_rounded,
    settings.ThemeMode.dark => Symbols.dark_mode_rounded,
    settings.ThemeMode.oled => Symbols.contrast_rounded,
    settings.ThemeMode.system => Symbols.brightness_auto_rounded,
    settings.ThemeMode.ember ||
    settings.ThemeMode.glacier ||
    settings.ThemeMode.forest ||
    settings.ThemeMode.plum ||
    settings.ThemeMode.paper => Symbols.palette_rounded,
    settings.ThemeMode.custom => Symbols.format_paint_rounded,
  };
}
