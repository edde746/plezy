import 'package:flutter/material.dart';

import 'rasterized_gradient.dart';

/// Top-edge fade behind a toolbar that floats over content, keeping its
/// glyphs legible against artwork without a solid chrome bar.
///
/// The fade is pure black on dark schemes — a tinted surface reads as haze
/// over backdrop artwork — and the scheme surface otherwise. [child] is laid
/// out below the status bar with the standard chrome insets.
class ToolbarScrim extends StatelessWidget {
  const ToolbarScrim({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final colorScheme = Theme.of(context).colorScheme;
    final overlayColor = colorScheme.brightness == Brightness.dark ? Colors.black : colorScheme.surface;
    return RasterizedGradient(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          overlayColor.withValues(alpha: 0.7),
          overlayColor.withValues(alpha: 0.5),
          overlayColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight + 8, left: 16, right: 16, bottom: 16),
        child: child,
      ),
    );
  }
}
