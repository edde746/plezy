import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/text_measure_cache.dart';

/// Material's own ceiling for navigation labels (`_kMaxLabelTextScaleFactor`
/// in `navigation_bar.dart`): the bar re-clamps the ambient scaler to this
/// before painting a label, so asking for more here would change nothing.
const double kNavigationLabelMaxScaleFactor = 1.3;

/// Smallest size a shrunk destination label may paint at. Below this the text
/// stops being readable at arm's length, so the ellipsis takes over instead.
const double kNavigationLabelMinFontSize = 9;

/// Breathing room the fitted label keeps inside its destination. Aiming at the
/// exact cell width lands the shrunk word on the boundary, where a hair of
/// shaping rounding still trips the ellipsis; 1dp per side both clears that
/// and keeps neighbouring labels from touching.
const double kNavigationLabelFitMargin = 2;

/// The largest text scale factor that keeps every entry of [labels] on one
/// line inside [labelWidth], never above [kNavigationLabelMaxScaleFactor] and
/// never below [minFontSize] worth of scaling.
///
/// A [NavigationBar] destination gets `barWidth / destinations` and no
/// horizontal padding, so a long localized label ("Téléchargement",
/// "Nedladdningar") or an enlarged system font overflows its cell. Shrinking
/// the label is what keeps the full word visible; the single-line clamp that
/// [NavigationTab.toDestination] installs is the guarantee that it stays on
/// one line regardless.
///
/// Returns the ambient factor (clamped to Material's ceiling) whenever the
/// labels already fit, so the common case paints exactly as before.
double navigationLabelScaleFactor({
  required Iterable<String> labels,
  required double labelWidth,
  required TextStyle style,
  required TextScaler textScaler,
  required TextDirection textDirection,
  double minFontSize = kNavigationLabelMinFontSize,
}) {
  final fontSize = style.fontSize;
  final ambient = fontSize == null || fontSize <= 0 ? null : textScaler.scale(fontSize) / fontSize;
  final ceiling = math.min(ambient ?? kNavigationLabelMaxScaleFactor, kNavigationLabelMaxScaleFactor);
  if (fontSize == null || fontSize <= 0 || !labelWidth.isFinite || labelWidth <= 0) return ceiling;

  final clamped = textScaler.clamp(maxScaleFactor: kNavigationLabelMaxScaleFactor);
  var widest = 0.0;
  for (final label in labels) {
    if (label.isEmpty) continue;
    final width = cachedSingleLineTextSize(
      label,
      style: style,
      textScaler: clamped,
      textDirection: textDirection,
    ).width;
    if (width > widest) widest = width;
  }
  final floor = math.min(minFontSize / fontSize, ceiling);
  final target = math.max(labelWidth - kNavigationLabelFitMargin, 1.0);
  if (widest <= 0 || widest <= target) return ceiling;

  // Text width is proportional to the painted font size, so the factor that
  // just fits the widest label is the current one scaled by how much it
  // overflows. The floor keeps a very long label legible and lets the
  // single-line clamp ellipsize the remainder.
  return (ceiling * target / widest).clamp(floor, ceiling);
}

/// The style a [NavigationBar] paints its destination labels with, resolved
/// the way [NavigationDestination] resolves it (theme first, Material 3
/// default second, over the ambient text style the bar's own [Material]
/// installs).
TextStyle navigationBarLabelStyle(BuildContext context) {
  final theme = Theme.of(context);
  final themed = NavigationBarTheme.of(context).labelTextStyle?.resolve(const <WidgetState>{});
  return (theme.textTheme.bodyMedium ?? const TextStyle()).merge(themed ?? theme.textTheme.labelMedium);
}

/// Shrinks the destination labels of the [NavigationBar] in [child] just
/// enough to keep them on one line.
///
/// The clamp is a [MediaQuery] override rather than a smaller font size so a
/// viewer who enlarged the system font still gets the largest text that fits,
/// and so nothing else about the bar's metrics moves.
class NavigationLabelScale extends StatelessWidget {
  const NavigationLabelScale({
    super.key,
    required this.labels,
    required this.labelWidth,
    required this.style,
    required this.child,
  });

  /// Every label the surface will paint; the widest one decides the factor.
  final List<String> labels;

  /// Width one label may occupy.
  final double labelWidth;

  /// Style the labels will be painted with (see [navigationBarLabelStyle]).
  final TextStyle style;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final factor = navigationLabelScaleFactor(
      labels: labels,
      labelWidth: labelWidth,
      style: style,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    );
    return MediaQuery.withClampedTextScaling(maxScaleFactor: factor, child: child);
  }
}
