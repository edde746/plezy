import 'package:flutter/material.dart';

/// A standardized placeholder container used for loading states,
/// error states, and missing images throughout the app.
///
/// Uses the theme's surfaceContainerHighest color by default.
class PlaceholderContainer extends StatelessWidget {
  /// Optional child widget to display inside the placeholder
  final Widget? child;

  /// Optional custom color (defaults to theme's surfaceContainerHighest)
  final Color? color;

  /// Optional border radius
  final BorderRadius? borderRadius;

  const PlaceholderContainer({
    super.key,
    this.child,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      color: borderRadius != null
          ? null
          : (color ?? Theme.of(context).colorScheme.surfaceContainerHighest),
      decoration: borderRadius != null
          ? BoxDecoration(
              color:
                  color ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: borderRadius,
            )
          : null,
      child: child != null ? Center(child: child) : null,
    );

    return container;
  }
}
