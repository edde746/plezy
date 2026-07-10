import 'package:flutter/material.dart';

import 'focus_theme.dart';

/// Exposes the focus state of an enclosing focus wrapper to a descendant
/// [CardFocusBorder] that draws the focus border itself.
///
/// Wrappers ([FocusableWrapper]/[FocusBuilders.buildFocusableCard]) insert this
/// instead of painting a border when `delegateFocusBorder` is set, so cards can
/// put the border on the exact rect the design highlights (the poster image,
/// not the card-plus-captions rect — issue #1278). Only the [CardFocusBorder]
/// element registers a dependency, so a focus flip rebuilds just that border
/// box: a stable `child:` card subtree (e.g. the TV rail's MediaCard) is not
/// rebuilt.
class CardFocusScope extends InheritedWidget {
  const CardFocusScope({super.key, required this.showFocus, required super.child});

  /// Whether the enclosing wrapper currently shows focus visuals
  /// (focused while in keyboard/d-pad input mode).
  final bool showFocus;

  /// Null when no delegating wrapper is above (touch mode skips the focus
  /// wrappers entirely) — [CardFocusBorder] then renders its child bare.
  static bool? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CardFocusScope>()?.showFocus;

  @override
  bool updateShouldNotify(CardFocusScope oldWidget) => showFocus != oldWidget.showFocus;
}

/// Draws the focus border around its child based on the enclosing
/// [CardFocusScope], letting the card decide which rect gets highlighted.
///
/// Defaults to an outside stroke so the border hugs the child exactly like the
/// full-bleed card treatment (the child's own corner radius nests inside it).
/// Decoration only — never affects layout. Renders the child unchanged when no
/// scope is present.
class CardFocusBorder extends StatelessWidget {
  const CardFocusBorder({
    super.key,
    this.borderRadius = FocusTheme.defaultBorderRadius,
    this.borderRadii,
    this.strokeAlign = BorderSide.strokeAlignOutside,
    required this.child,
  });

  final double borderRadius;

  /// Per-corner radii; overrides [borderRadius] when set (M3E grouped cards).
  final BorderRadius? borderRadii;

  final double strokeAlign;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showFocus = CardFocusScope.maybeOf(context);
    if (showFocus == null) return child;

    return AnimatedContainer(
      duration: FocusTheme.getAnimationDuration(context),
      curve: Curves.easeOutCubic,
      foregroundDecoration: FocusTheme.focusDecoration(
        context,
        isFocused: showFocus,
        borderRadius: borderRadius,
        radii: borderRadii,
        borderStrokeAlign: strokeAlign,
      ),
      child: child,
    );
  }
}
