import 'package:flutter/material.dart';
import 'state_message_widget.dart';

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

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessageWidget(
      message: message,
      icon: icon,
      iconColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.error,
      onAction: onRetry,
      actionLabel: retryLabel ?? 'Retry',
      actionIcon: Icons.refresh,
    );
  }
}
