import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'gapped_track_shape.dart';
import 'mono_tokens.dart';

/// One of the six colours a [MonoPalette] holds. [id] is the key the custom
/// theme persists the colour under.
enum MonoPaletteSlot {
  bg('bg'),
  surface('surface'),
  outline('outline'),
  text('text'),
  textMuted('textMuted'),
  accent('accent');

  const MonoPaletteSlot(this.id);

  final String id;
}

/// [color] as `#AARRGGBB`, upper case.
String colorToArgbHex(Color color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

final _hexColorPattern = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

/// Parses `#RRGGBB` (opaque) or `#AARRGGBB`, with or without the `#`. Null
/// for anything else.
Color? tryParseHexColor(String input) {
  final match = _hexColorPattern.firstMatch(input.trim());
  if (match == null) return null;
  final digits = match.group(1)!;
  final value = int.parse(digits, radix: 16);
  return Color(digits.length == 6 ? 0xFF000000 | value : value);
}

/// The six colours a theme is built from.
///
/// [accent] carries interactive and selected state; body text stays [text].
/// Brightness follows [bg] and the colour drawn on [accent] is derived, so a
/// palette states nothing else.
@immutable
class MonoPalette {
  const MonoPalette({
    required this.bg,
    required this.surface,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.accent,
  });

  final Color bg;
  final Color surface;
  final Color outline;
  final Color text;
  final Color textMuted;

  /// Primary, filled buttons, switches, sliders, progress, selection and the
  /// focus ring. The built-ins set it to [text], which keeps them monochrome.
  final Color accent;

  // Neutral greys tuned for crisp contrast.
  static const light = MonoPalette(
    bg: Color(0xFFF7F7F8),
    surface: Color(0xFFFFFFFF),
    outline: Color(0x19000000),
    text: Color(0xFF111111),
    textMuted: Color(0x99111111),
    accent: Color(0xFF111111),
  );
  static const dark = MonoPalette(
    bg: Color(0xFF0E0F12),
    surface: Color(0xFF15171C),
    outline: Color(0x1FFFFFFF),
    text: Color(0xFFEDEDED),
    textMuted: Color(0x99EDEDED),
    accent: Color(0xFFEDEDED),
  );
  static const oled = MonoPalette(
    bg: Color(0xFF000000), // Pure black for OLED
    surface: Color(0xFF0A0A0A),
    outline: Color(0x1FFFFFFF),
    text: Color(0xFFEDEDED),
    textMuted: Color(0x99EDEDED),
    accent: Color(0xFFEDEDED),
  );

  // Presets keep bg/surface low-chroma so artwork stays the loudest thing on
  // screen; the character is in the tint and the accent. Every accent clears
  // 4.5:1 against bg and surface, because primary is also used as text.

  /// Warm charcoal with the brand orange.
  static const ember = MonoPalette(
    bg: Color(0xFF14110F),
    surface: Color(0xFF1D1916),
    outline: Color(0x1FF2EBE6),
    text: Color(0xFFF2EBE6),
    textMuted: Color(0xA3F2EBE6),
    accent: Color(0xFFFF7E57),
  );

  /// Cool blue-grey with an ice-blue accent.
  static const glacier = MonoPalette(
    bg: Color(0xFF0E1319),
    surface: Color(0xFF151C25),
    outline: Color(0x1FE6EDF5),
    text: Color(0xFFE6EDF5),
    textMuted: Color(0xA3E6EDF5),
    accent: Color(0xFF7CC4FF),
  );

  /// Green-black with a mint accent.
  static const forest = MonoPalette(
    bg: Color(0xFF0E1411),
    surface: Color(0xFF151D18),
    outline: Color(0x1FE5EFE8),
    text: Color(0xFFE5EFE8),
    textMuted: Color(0xA3E5EFE8),
    accent: Color(0xFF6BD6A0),
  );

  /// Aubergine with an orchid accent.
  static const plum = MonoPalette(
    bg: Color(0xFF151118),
    surface: Color(0xFF1E1823),
    outline: Color(0x1FF0E9F4),
    text: Color(0xFFF0E9F4),
    textMuted: Color(0xA3F0E9F4),
    accent: Color(0xFFE29BF0),
  );

  /// Warm off-white paper with a deep teal accent; the light preset.
  static const paper = MonoPalette(
    bg: Color(0xFFF3F0E9),
    surface: Color(0xFFFBF9F4),
    outline: Color(0x1F1F1C17),
    text: Color(0xFF1F1C17),
    textMuted: Color(0xAD1F1C17),
    accent: Color(0xFF1F6B6B),
  );

  Brightness get brightness => ThemeData.estimateBrightnessForColor(bg);

  /// [bg] or white, whichever contrasts more with [accent]. The pair is never
  /// worse than [accent] against [bg], so an accent that reads on the page
  /// keeps a readable label.
  Color get onAccent {
    const white = Color(0xFFFFFFFF);
    final accentLuminance = accent.computeLuminance();
    return _contrastRatio(accentLuminance, bg.computeLuminance()) >=
            _contrastRatio(accentLuminance, white.computeLuminance())
        ? bg
        : white;
  }

  static double _contrastRatio(double a, double b) => (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

  /// WCAG 2 contrast ratio between two colours, ignoring alpha: composite a
  /// translucent colour over its background first.
  static double contrastRatio(Color a, Color b) => _contrastRatio(a.computeLuminance(), b.computeLuminance());

  Color operator [](MonoPaletteSlot slot) => switch (slot) {
    MonoPaletteSlot.bg => bg,
    MonoPaletteSlot.surface => surface,
    MonoPaletteSlot.outline => outline,
    MonoPaletteSlot.text => text,
    MonoPaletteSlot.textMuted => textMuted,
    MonoPaletteSlot.accent => accent,
  };

  /// This palette with [slot] replaced by [color].
  MonoPalette withColor(MonoPaletteSlot slot, Color color) => MonoPalette(
    bg: slot == MonoPaletteSlot.bg ? color : bg,
    surface: slot == MonoPaletteSlot.surface ? color : surface,
    outline: slot == MonoPaletteSlot.outline ? color : outline,
    text: slot == MonoPaletteSlot.text ? color : text,
    textMuted: slot == MonoPaletteSlot.textMuted ? color : textMuted,
    accent: slot == MonoPaletteSlot.accent ? color : accent,
  );

  /// `{"bg": "#AARRGGBB", …}`, keyed by [MonoPaletteSlot.id].
  Map<String, String> toJson() => {for (final slot in MonoPaletteSlot.values) slot.id: colorToArgbHex(this[slot])};

  /// Reads the [toJson] shape. Throws [FormatException] unless every slot
  /// holds a hex colour, so a partial or corrupt value never yields a palette
  /// mixing stored and made-up colours. Unknown keys are ignored.
  factory MonoPalette.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Expected a palette object');
    Color read(MonoPaletteSlot slot) {
      final value = json[slot.id];
      final color = value is String ? tryParseHexColor(value) : null;
      if (color == null) throw FormatException('Missing or invalid "${slot.id}" colour');
      return color;
    }

    return MonoPalette(
      bg: read(MonoPaletteSlot.bg),
      surface: read(MonoPaletteSlot.surface),
      outline: read(MonoPaletteSlot.outline),
      text: read(MonoPaletteSlot.text),
      textMuted: read(MonoPaletteSlot.textMuted),
      accent: read(MonoPaletteSlot.accent),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MonoPalette &&
      other.bg == bg &&
      other.surface == surface &&
      other.outline == outline &&
      other.text == text &&
      other.textMuted == textMuted &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(bg, surface, outline, text, textMuted, accent);
}

final Map<({MonoPalette palette, TargetPlatform platform}), ThemeData> _monoThemeCache = {};

ThemeData monoTheme(MonoPalette palette) {
  // ThemeData derives several defaults from defaultTargetPlatform.
  final key = (palette: palette, platform: defaultTargetPlatform);
  final cached = _monoThemeCache[key];
  if (cached != null) return cached;

  final theme = _buildMonoTheme(palette, platform: key.platform);
  _monoThemeCache[key] = theme;
  return theme;
}

/// [monoTheme] without the cache, for a palette that changes every frame: the
/// custom theme editor's live preview would otherwise keep every intermediate
/// palette's theme alive.
ThemeData monoThemeUncached(MonoPalette palette) => _buildMonoTheme(palette, platform: defaultTargetPlatform);

ThemeData _buildMonoTheme(MonoPalette c, {required TargetPlatform platform}) {
  final brightness = c.brightness;
  final onAccent = c.onAccent;
  final clickableCursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled) ? MouseCursor.defer : SystemMouseCursors.click,
  );

  // Disabled buttons use the Material disabled opacities over the text colour;
  // a flat colour for every state made them look pressable.
  final buttonStyle = ButtonStyle(
    mouseCursor: clickableCursor,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? c.text.withValues(alpha: 0.12) : c.accent,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? c.text.withValues(alpha: 0.38) : onAccent,
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  );

  final base = ThemeData(
    platform: platform,
    useMaterial3: true,
    brightness: brightness,
    // Linux resolves UI text through fontconfig, which on a minimal desktop
    // may have no CJK font at all; the bundled subtitle fonts (pubspec
    // `fonts:`) cover it. Other platforms keep their native CJK fonts.
    fontFamilyFallback: platform == TargetPlatform.linux ? const ['Go Noto Current', 'Go Noto Current Hangul'] : null,
    colorScheme: ColorScheme(
      brightness: brightness,
      // Accent: everything Material derives from primary (switches, sliders,
      // progress, checkboxes, text selection, text buttons, selected list
      // tiles) plus the widgets that read primary for selection and focus.
      primary: c.accent,
      onPrimary: onAccent,
      // Elevation tint stays on the neutral text colour so dialogs and menus
      // keep the palette's surfaces rather than picking up the accent hue.
      surfaceTint: c.text,
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
    // Explicit mono-derived tile highlights: ListTile's native focus/hover
    // fill is the dpad focus visual inside M3E grouped-list cards.
    focusColor: c.text.withValues(alpha: 0.12),
    hoverColor: c.text.withValues(alpha: 0.05),
    dividerColor: c.outline,
    scaffoldBackgroundColor: c.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.text,
      titleTextStyle: TextStyle(color: c.text, fontSize: 18, fontWeight: .w700, letterSpacing: -0.2),
    ),
    textTheme: Typography.englishLike2021
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          displayLarge: const TextStyle(fontWeight: .w700, letterSpacing: -0.5),
          titleMedium: const TextStyle(fontWeight: .w600),
          bodyMedium: TextStyle(color: c.text),
          bodySmall: TextStyle(color: c.textMuted),
        ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: .zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    inputDecorationTheme: _inputDecorationTheme(c.text, c.textMuted),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    iconButtonTheme: IconButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    sliderTheme: SliderThemeData(
      // The mono scheme maps surfaceContainerHighest (the M3 default inactive
      // track) to the same color as surface cards, which makes the inactive
      // track invisible inside grouped-list items.
      inactiveTrackColor: c.text.withValues(alpha: 0.12),
      trackHeight: 16,
      trackGap: 6,
      thumbSize: const WidgetStatePropertyAll(Size(4, 20)),
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      // ignore: deprecated_member_use — opting into the 2024 slider appearance until the default flips
      year2023: false,
    ),
    dividerTheme: DividerThemeData(space: 0, thickness: 1, color: c.outline),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: c.text,
      textColor: c.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: c.textMuted, fontSize: 11)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(opacity: active ? 1 : 0.6, size: 22, color: active ? c.accent : c.text);
      }),
    ),
    // Floating snackbars auto-offset above the Scaffold's bottom NavigationBar,
    // so they don't cover it on mobile. Background color tracks the theme to
    // avoid jarring brightness on HDR playback / dark mode.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface,
      contentTextStyle: TextStyle(color: c.text),
      actionTextColor: c.text,
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      insetPadding: const EdgeInsets.all(16),
    ),
  );

  return base.copyWith(
    extensions: [
      MonoTokens(
        radiusSm: 8,
        radiusMd: 12,
        radiusLg: 20,
        radiusXs: 5,
        groupGap: 2,
        space: 12,
        fast: const Duration(milliseconds: 120),
        normal: const Duration(milliseconds: 200),
        slow: const Duration(milliseconds: 300),
        expressive: const Duration(milliseconds: 350),
        bg: c.bg,
        surface: c.surface,
        outline: c.outline,
        text: c.text,
        textMuted: c.textMuted,
        accent: c.accent,
      ),
    ],
  );
}

/// Brighter fill on focus so input focus is visible inside TV overscan.
InputDecorationTheme _inputDecorationTheme(Color text, Color textMuted) {
  final unfocusedFill = text.withValues(alpha: 0.08);
  final focusedFill = text.withValues(alpha: 0.18);
  const border = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none);
  return InputDecorationTheme(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusedFill : unfocusedFill,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    hintStyle: TextStyle(color: textMuted),
  );
}
