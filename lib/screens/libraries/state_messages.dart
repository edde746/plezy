import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Base widget for displaying state messages (empty, error, etc.)
/// Provides a consistent UI pattern for showing icons, messages, and actions
class StateMessageWidget extends StatelessWidget {
  /// The main message/title to display
  final String message;

  /// Optional subtitle/description below the message
  final String? subtitle;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional size for the icon (default: 64)
  final double iconSize;

  /// Optional color for the icon
  final Color? iconColor;

  /// Optional color for the message text
  final Color? textColor;

  /// Optional color for the subtitle text
  final Color? subtitleColor;

  /// Optional callback for action button
  final VoidCallback? onAction;

  /// Optional label for the action button
  final String? actionLabel;

  /// Optional icon for the action button
  final IconData? actionIcon;

  const StateMessageWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.iconSize = 64,
    this.iconColor,
    this.textColor,
    this.subtitleColor,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(
                icon,
                fill: 1,
                size: iconSize,
                color: iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor ?? theme.colorScheme.onSurfaceVariant),
              ),
            ],
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

/// A reusable widget for displaying empty states throughout the app
class EmptyStateWidget extends StatelessWidget {
  /// The message to display
  final String message;

  /// Optional subtitle/description below the message
  final String? subtitle;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional size for the icon
  final double iconSize;

  /// Optional callback for action button
  final VoidCallback? onAction;

  /// Optional label for the action button
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.iconSize = 64,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessageWidget(
      message: message,
      subtitle: subtitle,
      icon: icon,
      iconSize: iconSize,
      onAction: onAction,
      actionLabel: actionLabel,
      actionIcon: Symbols.add_rounded,
    );
  }
}

/// A reusable widget for displaying error states throughout the app
class ErrorStateWidget extends StatelessWidget {
  /// The error message to display
  final String message;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional callback for retry action
  final VoidCallback? onRetry;

  /// Optional label for the retry button
  final String? retryLabel;

  const ErrorStateWidget({super.key, required this.message, this.icon, this.onRetry, this.retryLabel});

  @override
  Widget build(BuildContext context) {
    return StateMessageWidget(
      message: message,
      icon: icon,
      iconColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.error,
      onAction: onRetry,
      actionLabel: retryLabel ?? 'Retry',
      actionIcon: Symbols.refresh_rounded,
    );
  }
}
