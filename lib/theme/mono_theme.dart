import 'package:flutter/material.dart';
import 'mono_tokens.dart';

/// Creates a theme with the specified mode.
///
/// [dark] - Whether to use dark mode colors
/// [oled] - Whether to use pure black for OLED displays (only applies when dark is true)
ThemeData monoTheme({required bool dark, bool oled = false}) {
  // neutral greys tuned for crisp contrast
  // OLED mode uses pure black for maximum battery savings on AMOLED displays
  final c = dark
      ? (oled
          ? (
              bg: const Color(0xFF000000), // Pure black for OLED
              surface: const Color(0xFF0A0A0A), // Near black surface
              outline: const Color(0x1FFFFFFF),
              text: const Color(0xFFEDEDED),
              textMuted: const Color(0x99EDEDED),
            )
          : (
              bg: const Color(0xFF0E0F12),
              surface: const Color(0xFF15171C),
              outline: const Color(0x1FFFFFFF),
              text: const Color(0xFFEDEDED),
              textMuted: const Color(0x99EDEDED),
            ))
      : (
          bg: const Color(0xFFF7F7F8),
          surface: const Color(0xFFFFFFFF),
          outline: const Color(0x19000000),
          text: const Color(0xFF111111),
          textMuted: const Color(0x99111111),
        );

  final buttonStyle = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(c.text),
    foregroundColor: WidgetStatePropertyAll(dark ? c.bg : Colors.white),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.text,
      onPrimary: dark ? const Color(0xFF0E0F12) : Colors.white,
      secondary: c.text,
      onSecondary: c.bg,
      surface: c.surface,
      onSurface: c.text,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      tertiary: c.text,
      onTertiary: c.bg,
      primaryContainer: c.surface,
      onPrimaryContainer: c.text,
      secondaryContainer: c.surface,
      onSecondaryContainer: c.text,
      surfaceContainerHighest: c.surface,
      surfaceContainerLow: c.bg,
      surfaceDim: c.bg,
      surfaceBright: c.surface,
      outline: c.outline,
      shadow: Colors.transparent,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.bg,
      inversePrimary: c.bg,
    ),
    // remove "Material feel"
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.outline,
    scaffoldBackgroundColor: c.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.text,
      titleTextStyle: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    ),
    textTheme: Typography.englishLike2021
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: c.text),
          bodySmall: TextStyle(color: c.textMuted),
        ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.text.withValues(alpha: 0.5)),
      ),
      hintStyle: TextStyle(color: c.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    dividerTheme: DividerThemeData(space: 0, thickness: 1, color: c.outline),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: c.text,
      textColor: c.text,
    ),
    // minimal bottom bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: c.textMuted, fontSize: 11)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(opacity: active ? 1 : .6, size: 22, color: c.text);
      }),
    ),
  );

  return base.copyWith(
    extensions: [
      MonoTokens(
        radiusSm: 8,
        radiusMd: 12,
        space: 12,
        fast: const Duration(milliseconds: 120),
        normal: const Duration(milliseconds: 200),
        slow: const Duration(milliseconds: 300),
        bg: c.bg,
        surface: c.surface,
        outline: c.outline,
        text: c.text,
        textMuted: c.textMuted,
        splashFactory: NoSplash.splashFactory,
      ),
    ],
  );
}
