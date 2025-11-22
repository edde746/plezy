import 'package:flutter/material.dart';
import 'state_message_widget.dart';

/// A reusable widget for displaying empty states throughout the app
class EmptyStateWidget extends StatelessWidget {
  /// The message to display
  final String message;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional callback for action button
  final VoidCallback? onAction;

  /// Optional label for the action button
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessageWidget(
      message: message,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
      actionIcon: Icons.add,
    );
  }
}
