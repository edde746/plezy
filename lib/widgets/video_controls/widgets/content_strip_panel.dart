import 'package:flutter/material.dart';

import '../../app_icon.dart';
import '../video_control_button.dart';

/// Gradient scrim that hosts the content strip once it is on screen.
///
/// [chevron] points back at the controls the strip replaced — down for the
/// mobile swipe, up for D-pad focus. [padding] compensates for the strip's
/// own horizontal padding, which differs between touch and focus navigation.
class ContentStripPanel extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final IconData chevron;
  final Key? chevronKey;
  final String? chevronSemanticLabel;
  final VoidCallback? onChevronPressed;
  final Widget child;

  const ContentStripPanel({
    super.key,
    required this.padding,
    required this.chevron,
    this.chevronKey,
    this.chevronSemanticLabel,
    this.onChevronPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65), Colors.black.withValues(alpha: 0.7)],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          if (onChevronPressed == null)
            AppIcon(chevron, color: Colors.white38, size: 20)
          else
            SizedBox.square(
              key: chevronKey,
              dimension: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: VideoControlButton(
                  icon: chevron,
                  color: Colors.white38,
                  semanticLabel: chevronSemanticLabel,
                  onPressed: onChevronPressed,
                ),
              ),
            ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// Chevron pinned to the bottom of the controls hinting that the content
/// strip can be pulled into view. Must be placed directly in a [Stack].
class ContentStripHint extends StatelessWidget {
  final IconData chevron;
  final String? tooltip;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  const ContentStripHint(this.chevron, {super.key, this.tooltip, this.semanticLabel, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      return Positioned(left: 0, right: 0, bottom: 12, child: AppIcon(chevron, color: Colors.white24, size: 24));
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: SizedBox.square(
          dimension: 48,
          child: VideoControlButton(
            icon: chevron,
            color: Colors.white24,
            tooltip: tooltip,
            semanticLabel: semanticLabel,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
