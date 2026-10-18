import 'package:flutter/material.dart';

/// Keeps list-tile ink (hover, focus, and tile colors) inside a bounded scroll
/// view that sits on a larger [Material], such as a dialog's.
///
/// [InkWell]s paint on the nearest [Material], and Flutter clips that ink only
/// to the Material's own bounds, not to the scroll views in between. Without
/// this boundary, a tile partly scrolled out of view paints its hover
/// highlight past the viewport edge, over a strip that no longer hit-tests to
/// the tile, so the tile looks clickable where it is not.
///
/// Wrap the scroll view, or the content inside it when the scroll view is not
/// ours (e.g. [SimpleDialog] children).
class ScrollInkBoundary extends StatelessWidget {
  final Widget child;

  const ScrollInkBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      // Material otherwise resets the inherited text style to bodyMedium.
      textStyle: DefaultTextStyle.of(context).style,
      child: child,
    );
  }
}
