import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Base widget for displaying state messages (empty, error, etc.)
/// Provides a consistent UI pattern for showing icons, messages, and actions
class StateMessageWidget extends StatelessWidget {
  /// The message to display
  final String message;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional color for the icon
  final Color? iconColor;

  /// Optional color for the message text
  final Color? textColor;

  /// Optional callback for action button
  final VoidCallback? onAction;

  /// Optional label for the action button
  final String? actionLabel;

  /// Optional icon for the action button
  final IconData? actionIcon;

  const StateMessageWidget({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
    this.textColor,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon, fill: 1, size: 64, color:
                    iconColor ??
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    textColor ??
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: AppIcon(actionIcon ?? Symbols.refresh_rounded, fill: 1),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
