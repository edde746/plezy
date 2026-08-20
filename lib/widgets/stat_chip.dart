import 'package:flutter/material.dart';

import 'app_icon.dart';

/// Small labeled pill (optionally with a leading icon): detail-screen stat
/// chips, request-sheet season status labels.
class StatChip extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;

  /// Leading artwork for chips whose source has a brand mark (rating badges).
  /// Takes precedence over [icon].
  final Widget? leading;

  /// Overrides the default fill. Needed where the chip sits on a surface that
  /// already uses `surfaceContainerHigh` — the mono theme collapses several
  /// container roles onto one colour, so the default would be invisible.
  final Color? backgroundColor;

  const StatChip({super.key, this.icon, this.iconColor, required this.label, this.leading, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            AppIcon(icon!, size: 14, fill: 1, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
