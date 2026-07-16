import 'package:flutter/material.dart';

import 'app_icon.dart';

/// Small labeled pill (optionally with a leading icon): detail-screen stat
/// chips, request-sheet season status labels.
class StatChip extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;

  const StatChip({super.key, this.icon, this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[AppIcon(icon!, size: 14, fill: 1, color: iconColor), const SizedBox(width: 4)],
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
