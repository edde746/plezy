import 'package:flutter/material.dart';

/// Reusable media progress bar widget for displaying watch progress
///
/// Shows a linear progress indicator based on viewOffset and duration.
/// Uses theme defaults when colors are not provided.
class MediaProgressBar extends StatelessWidget {
  final int viewOffset; // Progress position in milliseconds
  final int duration; // Total duration in milliseconds
  final Color? backgroundColor;
  final Color? valueColor;
  final double? minHeight;

  const MediaProgressBar({
    super.key,
    required this.viewOffset,
    required this.duration,
    this.backgroundColor,
    this.valueColor,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress value (0.0 to 1.0)
    final progress = duration > 0 ? viewOffset / duration : 0.0;

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      valueColor: AlwaysStoppedAnimation<Color>(valueColor ?? Theme.of(context).colorScheme.primary),
      minHeight: minHeight ?? 4,
    );
  }
}
