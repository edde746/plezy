import 'package:flutter/material.dart';

/// A standardized placeholder container used for loading states,
/// error states, and missing images throughout the app.
///
/// Uses the theme's surfaceContainerHighest color by default.
class PlaceholderContainer extends StatelessWidget {
  final Widget? child;

  final Color? color;

  final BorderRadius? borderRadius;

  const PlaceholderContainer({super.key, this.child, this.color, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: borderRadius != null ? null : (color ?? Theme.of(context).colorScheme.surfaceContainerHighest),
      decoration: borderRadius != null
          ? BoxDecoration(
              color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: borderRadius,
            )
          : null,
      child: child != null ? Center(child: child) : null,
    );
  }
}
