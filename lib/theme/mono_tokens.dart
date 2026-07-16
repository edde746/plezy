import 'dart:ui';
import 'package:flutter/material.dart';

MonoTokens tokens(BuildContext context) => Theme.of(context).extension<MonoTokens>()!;

@immutable
class MonoTokens extends ThemeExtension<MonoTokens> {
  /// Effectively-stadium radius for pill shapes; the renderer proportionally
  /// clamps oversized RRect radii (same trick as FocusableButton).
  static const double radiusFull = 100;

  final double radiusSm;
  final double radiusMd;

  /// Outer corners of M3E grouped-list cards and connected button groups.
  final double radiusLg;

  /// Inner corners between adjacent items of an M3E group.
  final double radiusXs;

  /// Gap between adjacent items of an M3E group.
  final double groupGap;

  final double space;
  final Duration fast;
  final Duration normal;
  final Duration slow;

  /// M3E shape-morph duration (segment square→pill and friends).
  final Duration expressive;
  final Color bg;
  final Color surface;
  final Color outline;
  final Color text;
  final Color textMuted;
  final InteractiveInkFeatureFactory? splashFactory;

  const MonoTokens({
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXs,
    required this.groupGap,
    required this.space,
    required this.fast,
    required this.normal,
    required this.slow,
    required this.expressive,
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
    double? radiusLg,
    double? radiusXs,
    double? groupGap,
    double? space,
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Duration? expressive,
    Color? bg,
    Color? surface,
    Color? outline,
    Color? text,
    Color? textMuted,
    InteractiveInkFeatureFactory? splashFactory,
  }) => MonoTokens(
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    radiusXs: radiusXs ?? this.radiusXs,
    groupGap: groupGap ?? this.groupGap,
    space: space ?? this.space,
    fast: fast ?? this.fast,
    normal: normal ?? this.normal,
    slow: slow ?? this.slow,
    expressive: expressive ?? this.expressive,
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
    Duration lerpD(Duration a, Duration b) =>
        Duration(milliseconds: lerpDouble(a.inMilliseconds.toDouble(), b.inMilliseconds.toDouble(), t)!.round());
    return MonoTokens(
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      groupGap: lerpDouble(groupGap, other.groupGap, t)!,
      space: lerpDouble(space, other.space, t)!,
      fast: lerpD(fast, other.fast),
      normal: lerpD(normal, other.normal),
      slow: lerpD(slow, other.slow),
      expressive: lerpD(expressive, other.expressive),
      bg: lerpC(bg, other.bg),
      surface: lerpC(surface, other.surface),
      outline: lerpC(outline, other.outline),
      text: lerpC(text, other.text),
      textMuted: lerpC(textMuted, other.textMuted),
      splashFactory: other.splashFactory,
    );
  }
}
