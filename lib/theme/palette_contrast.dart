import 'package:flutter/painting.dart';

import 'mono_theme.dart';

/// The WCAG 2 contrast pairs a custom theme is checked against. A failing pair
/// is a warning only: an unreadable palette is still the user's to save.
enum PaletteContrastCheck {
  textOnBg(4.5),
  textOnSurface(4.5),
  textMutedOnBg(4.5),
  textMutedOnSurface(4.5),
  accentOnBg(3),
  accentOnSurface(3),

  /// The derived [MonoPalette.onAccent] label on a filled accent button.
  labelOnAccent(4.5);

  const PaletteContrastCheck(this.minimum);

  /// Lowest passing ratio: 4.5:1 for text, 3:1 for the accent as a non-text
  /// indicator against the page.
  final double minimum;

  /// The colours this pair is drawn from: editing any of them can fix it, so
  /// the editor shows the warning with each. The label on the accent is
  /// derived from [MonoPalette.bg], so that pair involves the page too.
  List<MonoPaletteSlot> get slots => switch (this) {
    textOnBg => const [MonoPaletteSlot.text, MonoPaletteSlot.bg],
    textOnSurface => const [MonoPaletteSlot.text, MonoPaletteSlot.surface],
    textMutedOnBg => const [MonoPaletteSlot.textMuted, MonoPaletteSlot.bg],
    textMutedOnSurface => const [MonoPaletteSlot.textMuted, MonoPaletteSlot.surface],
    accentOnBg => const [MonoPaletteSlot.accent, MonoPaletteSlot.bg],
    accentOnSurface => const [MonoPaletteSlot.accent, MonoPaletteSlot.surface],
    labelOnAccent => const [MonoPaletteSlot.accent, MonoPaletteSlot.bg],
  };

  /// The ratio [palette] reaches for this pair, with translucent colours
  /// composited the way the app paints them: the page over black, cards over
  /// the page, and each foreground over its own background.
  double ratioIn(MonoPalette palette) {
    const black = Color(0xFF000000);
    final bg = Color.alphaBlend(palette.bg, black);
    final surface = Color.alphaBlend(palette.surface, bg);
    final (foreground, background) = switch (this) {
      textOnBg => (palette.text, bg),
      textOnSurface => (palette.text, surface),
      textMutedOnBg => (palette.textMuted, bg),
      textMutedOnSurface => (palette.textMuted, surface),
      accentOnBg => (palette.accent, bg),
      accentOnSurface => (palette.accent, surface),
      labelOnAccent => (palette.onAccent, Color.alphaBlend(palette.accent, bg)),
    };
    return MonoPalette.contrastRatio(Color.alphaBlend(foreground, background), background);
  }

  bool passes(MonoPalette palette) => ratioIn(palette) >= minimum;

  /// Every check [palette] fails, in declaration order.
  static List<PaletteContrastCheck> failing(MonoPalette palette) => [
    for (final check in values)
      if (!check.passes(palette)) check,
  ];
}
