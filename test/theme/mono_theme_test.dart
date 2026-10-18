import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/mono_tokens.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Every fixed palette a theme choice can paint with.
final _palettes = {for (final mode in settings.ThemeMode.values) mode.name: ?ThemeProvider.paletteFor(mode)};

const _builtIns = {'light': MonoPalette.light, 'dark': MonoPalette.dark, 'oled': MonoPalette.oled};

/// `monoTheme` builds a full `ColorScheme`, an applied+copyWith'd Typography
/// `TextTheme`, ~14 sub-theme objects, and then clones the whole `ThemeData`
/// again via `copyWith(extensions:)`. It used to run five times per cold start —
/// two of them before `runApp`, on the critical path to first frame — and twice
/// more on every app-shell rebuild. It is memoized now, so these tests pin the
/// two properties that make that safe: stable identity per palette, and a cache
/// key that includes every input the builder actually reads.
void main() {
  test('repeated calls return the identical instance per palette', () {
    for (final palette in _palettes.values) {
      expect(identical(monoTheme(palette), monoTheme(palette)), isTrue);
    }
  });

  test('the three built-in palettes are distinct instances', () {
    final light = monoTheme(MonoPalette.light);
    final dark = monoTheme(MonoPalette.dark);
    final oled = monoTheme(MonoPalette.oled);

    expect(identical(light, dark), isFalse);
    expect(identical(dark, oled), isFalse);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    // OLED is the pure-black variant, which is the whole reason it exists.
    expect(oled.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(dark.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
  });

  test('the cache keys on palette colours, not instance identity', () {
    // A palette built at runtime (a future custom theme) must reuse the
    // cached theme of an equal palette instead of growing the cache.
    final copy = MonoPalette(
      bg: MonoPalette.dark.bg,
      surface: MonoPalette.dark.surface,
      outline: MonoPalette.dark.outline,
      text: MonoPalette.dark.text,
      textMuted: MonoPalette.dark.textMuted,
      accent: MonoPalette.dark.accent,
    );
    expect(identical(monoTheme(copy), monoTheme(MonoPalette.dark)), isTrue);
  });

  test('palette colours are unchanged by memoization', () {
    // Guards against a cache key that accidentally collapses two palettes.
    final light = monoTheme(MonoPalette.light);
    final dark = monoTheme(MonoPalette.dark);

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.scaffoldBackgroundColor, isNot(dark.scaffoldBackgroundColor));
    expect(light.colorScheme.onSurface, isNot(dark.colorScheme.onSurface));
  });

  test('filled and elevated buttons look disabled when disabled', () {
    for (final palette in _palettes.values) {
      final theme = monoTheme(palette);
      for (final style in [theme.filledButtonTheme.style!, theme.elevatedButtonTheme.style!]) {
        final enabledBackground = style.backgroundColor!.resolve(const {});
        final disabledBackground = style.backgroundColor!.resolve(const {WidgetState.disabled});
        final enabledForeground = style.foregroundColor!.resolve(const {});
        final disabledForeground = style.foregroundColor!.resolve(const {WidgetState.disabled});

        expect(disabledBackground, isNot(enabledBackground));
        expect(disabledForeground, isNot(enabledForeground));
        expect(disabledBackground!.a, lessThan(enabledBackground!.a));
      }
    }
  });

  test('built-in palettes stay monochrome: accent is the text colour', () {
    for (final MapEntry(key: name, value: palette) in _builtIns.entries) {
      final theme = monoTheme(palette);
      final tokens = theme.extension<MonoTokens>()!;
      final button = theme.filledButtonTheme.style!;
      expect(palette.accent, palette.text, reason: name);
      expect(tokens.accent, tokens.text, reason: name);
      expect(theme.colorScheme.primary, palette.text, reason: name);
      expect(button.backgroundColor!.resolve(const {}), palette.text, reason: name);
      expect(theme.colorScheme.surfaceTint, palette.text, reason: name);
    }
    // The colour drawn on a filled button is unchanged: page background on
    // the dark built-ins, white on Light.
    expect(monoTheme(MonoPalette.dark).colorScheme.onPrimary, MonoPalette.dark.bg);
    expect(monoTheme(MonoPalette.oled).colorScheme.onPrimary, MonoPalette.oled.bg);
    expect(monoTheme(MonoPalette.light).colorScheme.onPrimary, const Color(0xFFFFFFFF));
  });

  test('a preset accent drives interactive colour while body text stays neutral', () {
    const palette = MonoPalette.ember;
    final theme = monoTheme(palette);
    final navIcon = theme.navigationBarTheme.iconTheme!;

    expect(theme.colorScheme.primary, palette.accent);
    expect(theme.colorScheme.onPrimary, palette.onAccent);
    expect(theme.filledButtonTheme.style!.backgroundColor!.resolve(const {}), palette.accent);
    expect(theme.filledButtonTheme.style!.foregroundColor!.resolve(const {}), palette.onAccent);
    expect(theme.elevatedButtonTheme.style!.backgroundColor!.resolve(const {}), palette.accent);
    expect(navIcon.resolve(const {WidgetState.selected})!.color, palette.accent);
    expect(navIcon.resolve(const {})!.color, palette.text);
    expect(theme.extension<MonoTokens>()!.accent, palette.accent);

    expect(theme.textTheme.bodyMedium!.color, palette.text);
    expect(theme.colorScheme.onSurface, palette.text);
    expect(theme.colorScheme.surfaceTint, palette.text);
    expect(theme.scaffoldBackgroundColor, palette.bg);
  });

  test('brightness follows the background', () {
    for (final MapEntry(key: name, value: palette) in _palettes.entries) {
      final expected = palette.bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;
      expect(palette.brightness, expected, reason: name);
      expect(monoTheme(palette).brightness, expected, reason: name);
    }
  });

  test('every palette meets the contrast targets', () {
    for (final MapEntry(key: name, value: p) in _palettes.entries) {
      for (final (layer, background) in [('bg', p.bg), ('surface', p.surface)]) {
        final where = '$name $layer';
        expect(_contrast(p.text, background), greaterThanOrEqualTo(7), reason: '$where text');
        expect(
          _contrast(Color.alphaBlend(p.textMuted, background), background),
          greaterThanOrEqualTo(4.5),
          reason: '$where textMuted',
        );
        // 4.5 rather than the 3:1 non-text floor: primary is also used as text.
        expect(_contrast(p.accent, background), greaterThanOrEqualTo(4.5), reason: '$where accent');
      }
      expect(_contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5), reason: '$name onAccent');
    }
  });

  group('target platform is part of the cache key', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('each platform gets a theme carrying that platform', () {
      // ThemeData() derives platform defaults (tap target size, visual density,
      // typography) from defaultTargetPlatform. Keying only on the palette would
      // hand an Android-derived theme to a test or debug run overriding to iOS.
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(monoTheme(MonoPalette.dark).platform, platform);
      }
    });

    test('two platforms do not share an instance, and returning restores identity', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = monoTheme(MonoPalette.dark);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = monoTheme(MonoPalette.dark);
      expect(identical(android, ios), isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(identical(monoTheme(MonoPalette.dark), android), isTrue);
    });

    test('only Linux falls back to the bundled CJK fonts', () {
      // Linux resolves UI text through fontconfig, which on a minimal desktop
      // has no CJK font; the bundled fallback must reach the styles widgets
      // read, including the ones mono_theme replaces via copyWith, despite the
      // explicit textTheme being merged over ThemeData's platform defaults.
      const bundled = ['Go Noto Current', 'Go Noto Current Hangul'];
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final linux = monoTheme(MonoPalette.dark).textTheme;
      expect(linux.bodyMedium!.fontFamilyFallback, bundled);
      expect(linux.titleMedium!.fontFamilyFallback, bundled);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(monoTheme(MonoPalette.dark).textTheme.bodyMedium!.fontFamilyFallback, isNull);
    });
  });
}
