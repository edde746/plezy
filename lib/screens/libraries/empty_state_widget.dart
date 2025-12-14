import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'state_message_widget.dart';

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
