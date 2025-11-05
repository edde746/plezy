import 'package:flutter/material.dart';

/// A standardized button for video player controls with improved tap targets.
///
/// This widget ensures consistent tap target sizing across all video control
/// buttons without changing their visual appearance. The larger tap area makes
/// buttons easier to interact with, especially on mobile devices.
class VideoControlButton extends StatelessWidget {
  /// The icon to display in the button.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  /// Optional tooltip text shown on hover or long press.
  final String? tooltip;

  /// Whether this button represents an active state (e.g., a feature is enabled).
  /// When true, the icon color defaults to amber instead of white.
  final bool isActive;

  const VideoControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the effective color: explicit color > active amber > default white
    final effectiveColor = color ?? (isActive ? Colors.amber : Colors.white);

    return IconButton(
      icon: Icon(icon, color: effectiveColor),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 56),
    );
  }
}
