import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';

void main() {
  group('monoTheme', () {
    group('light mode', () {
      test('creates light theme with correct brightness', () {
        final theme = monoTheme(dark: false);
        expect(theme.brightness, Brightness.light);
      });

      test('has light background color', () {
        final theme = monoTheme(dark: false);
        // Light theme has a light background
        expect(theme.scaffoldBackgroundColor.value, 0xFFF7F7F8);
      });
    });

    group('dark mode', () {
      test('creates dark theme with correct brightness', () {
        final theme = monoTheme(dark: true);
        expect(theme.brightness, Brightness.dark);
      });

      test('has dark background color', () {
        final theme = monoTheme(dark: true);
        // Dark theme has a dark grey background
        expect(theme.scaffoldBackgroundColor.value, 0xFF0E0F12);
      });
    });

    group('OLED mode', () {
      test('creates OLED theme with dark brightness', () {
        final theme = monoTheme(dark: true, oled: true);
        expect(theme.brightness, Brightness.dark);
      });

      test('has pure black background color', () {
        final theme = monoTheme(dark: true, oled: true);
        // OLED theme has pure black background
        expect(theme.scaffoldBackgroundColor.value, 0xFF000000);
      });

      test('has near-black surface color', () {
        final theme = monoTheme(dark: true, oled: true);
        // OLED theme has near-black surface
        expect(theme.colorScheme.surface.value, 0xFF0A0A0A);
      });

      test('oled parameter has no effect when dark is false', () {
        final theme = monoTheme(dark: false, oled: true);
        // Light theme should still be light even with oled: true
        expect(theme.brightness, Brightness.light);
        expect(theme.scaffoldBackgroundColor.value, 0xFFF7F7F8);
      });
    });

    group('theme tokens', () {
      test('dark theme has correct text color', () {
        final theme = monoTheme(dark: true);
        expect(theme.colorScheme.onSurface.value, 0xFFEDEDED);
      });

      test('OLED theme has same text color as dark theme', () {
        final darkTheme = monoTheme(dark: true);
        final oledTheme = monoTheme(dark: true, oled: true);
        expect(oledTheme.colorScheme.onSurface, darkTheme.colorScheme.onSurface);
      });
    });
  });
}
