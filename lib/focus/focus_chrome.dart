import 'package:flutter/material.dart';

import 'card_focus_scope.dart';
import 'focus_glow_overlay.dart';
import 'focus_theme.dart';

/// Builds the focus border/glow chrome shared by [FocusableWrapper] and
/// [FocusBuilders.buildLockedFocusWrapper].
///
/// A function rather than a widget so it costs no element per card in dense TV
/// grids. Scale and input handling stay with the callers: the wrapper drives a
/// paint-only scale from its own controller and owns the [Focus] node, while
/// the locked builder scales implicitly and wraps gestures itself.
///
/// Callers pass the [duration] they already resolved via
/// [FocusTheme.getAnimationDuration] so a build resolves it once.
Widget buildFocusChrome(
  BuildContext context, {
  required bool showFocus,
  required Duration duration,
  double borderRadius = FocusTheme.defaultBorderRadius,
  BorderRadius? borderRadii,
  Color? focusColor,
  bool useBackgroundFocus = false,
  bool useFocusGlow = false,
  bool delegateFocusBorder = false,
  bool? showGlow,
  Size? glowSize,
  required Widget child,
}) {
  Widget card;
  if (delegateFocusBorder) {
    card = CardFocusScope(showFocus: showFocus, child: child);
  } else {
    final decoration = useBackgroundFocus
        ? FocusTheme.focusBackgroundDecoration(isFocused: showFocus, borderRadius: borderRadius, radii: borderRadii)
        : FocusTheme.focusDecoration(
            context,
            isFocused: showFocus,
            borderRadius: borderRadius,
            radii: borderRadii,
            color: focusColor,
          );
    card = AnimatedContainer(duration: duration, curve: Curves.easeOutCubic, decoration: decoration, child: child);
  }

  // Glow (full-bleed cards) renders in an overlay above siblings so it stays
  // symmetric; the in-card decoration only carries the border. [showGlow] lets
  // callers hold back just the glow (e.g. while a viewport scroll animates)
  // without touching the border or scale chrome.
  if (useFocusGlow) {
    card = FocusGlowOverlay(
      isFocused: showGlow ?? showFocus,
      borderRadius: borderRadius,
      color: focusColor ?? FocusTheme.getFocusBorderColor(context),
      glowSize: glowSize,
      child: card,
    );
  }

  return card;
}
