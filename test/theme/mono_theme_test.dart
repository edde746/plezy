import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';

/// `monoTheme` builds a full `ColorScheme`, an applied+copyWith'd Typography
/// `TextTheme`, ~14 sub-theme objects, and then clones the whole `ThemeData`
/// again via `copyWith(extensions:)`. It used to run five times per cold start —
/// two of them before `runApp`, on the critical path to first frame — and twice
/// more on every app-shell rebuild. It is memoized now, so these tests pin the
/// two properties that make that safe: stable identity per palette, and a cache
/// key that includes every input the builder actually reads.
void main() {
  test('repeated calls return the identical instance per palette', () {
    expect(identical(monoTheme(dark: false), monoTheme(dark: false)), isTrue);
    expect(identical(monoTheme(dark: true), monoTheme(dark: true)), isTrue);
    expect(identical(monoTheme(dark: true, oled: true), monoTheme(dark: true, oled: true)), isTrue);
  });

  test('the three palettes are distinct instances', () {
    final light = monoTheme(dark: false);
    final dark = monoTheme(dark: true);
    final oled = monoTheme(dark: true, oled: true);

    expect(identical(light, dark), isFalse);
    expect(identical(dark, oled), isFalse);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    // OLED is the pure-black variant, which is the whole reason it exists.
    expect(oled.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(dark.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
  });

  test('oled normalizes dark, so it cannot produce a light OLED theme', () {
    // ThemeProvider.darkThemeFor only ever asks for oled alongside dark, but the
    // signature allows dark:false — collapsing it keeps the cache at three
    // palette states instead of four, and a light OLED theme is meaningless.
    expect(identical(monoTheme(dark: false, oled: true), monoTheme(dark: true, oled: true)), isTrue);
    expect(monoTheme(dark: false, oled: true).brightness, Brightness.dark);
  });

  test('palette colours are unchanged by memoization', () {
    // Guards against a cache key that accidentally collapses two palettes.
    final light = monoTheme(dark: false);
    final dark = monoTheme(dark: true);

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.scaffoldBackgroundColor, isNot(dark.scaffoldBackgroundColor));
    expect(light.colorScheme.onSurface, isNot(dark.colorScheme.onSurface));
  });

  group('target platform is part of the cache key', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('each platform gets a theme carrying that platform', () {
      // ThemeData() derives platform defaults (tap target size, visual density,
      // typography) from defaultTargetPlatform. Keying only on the palette would
      // hand an Android-derived theme to a test or debug run overriding to iOS.
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(monoTheme(dark: true).platform, platform);
      }
    });

    test('two platforms do not share an instance, and returning restores identity', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = monoTheme(dark: true);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = monoTheme(dark: true);
      expect(identical(android, ios), isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(identical(monoTheme(dark: true), android), isTrue);
    });
  });
}
