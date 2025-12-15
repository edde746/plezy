import 'dart:ui';
import 'package:flutter/material.dart';

/// Helper function to access MonoTokens from context
MonoTokens tokens(BuildContext context) => Theme.of(context).extension<MonoTokens>()!;

@immutable
class MonoTokens extends ThemeExtension<MonoTokens> {
  final double radiusSm;
  final double radiusMd;
  final double space;
  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Color bg;
  final Color surface;
  final Color outline;
  final Color text;
  final Color textMuted;
  final InteractiveInkFeatureFactory? splashFactory;

  const MonoTokens({
    required this.radiusSm,
    required this.radiusMd,
    required this.space,
    required this.fast,
    required this.normal,
    required this.slow,
    required this.bg,
    required this.surface,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.splashFactory,
  });

  @override
  MonoTokens copyWith({
    double? radiusSm,
    double? radiusMd,
    double? space,
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Color? bg,
    Color? surface,
    Color? outline,
    Color? text,
    Color? textMuted,
    InteractiveInkFeatureFactory? splashFactory,
  }) => MonoTokens(
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    space: space ?? this.space,
    fast: fast ?? this.fast,
    normal: normal ?? this.normal,
    slow: slow ?? this.slow,
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    outline: outline ?? this.outline,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    splashFactory: splashFactory ?? this.splashFactory,
  );

  @override
  ThemeExtension<MonoTokens> lerp(covariant MonoTokens? other, double t) {
    if (other == null) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    return MonoTokens(
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      space: lerpDouble(space, other.space, t)!,
      fast: Duration(
        milliseconds: lerpDouble(fast.inMilliseconds.toDouble(), other.fast.inMilliseconds.toDouble(), t)!.round(),
      ),
      normal: Duration(
        milliseconds: lerpDouble(normal.inMilliseconds.toDouble(), other.normal.inMilliseconds.toDouble(), t)!.round(),
      ),
      slow: Duration(
        milliseconds: lerpDouble(slow.inMilliseconds.toDouble(), other.slow.inMilliseconds.toDouble(), t)!.round(),
      ),
      bg: lerpC(bg, other.bg),
      surface: lerpC(surface, other.surface),
      outline: lerpC(outline, other.outline),
      text: lerpC(text, other.text),
      textMuted: lerpC(textMuted, other.textMuted),
      splashFactory: other.splashFactory,
    );
  }
}
