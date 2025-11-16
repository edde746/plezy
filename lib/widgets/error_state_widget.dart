import 'package:flutter/material.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
