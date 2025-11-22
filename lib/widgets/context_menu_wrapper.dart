import 'package:flutter/material.dart';

/// A menu action item for context menus
class ContextMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final bool requiresConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.requiresConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
    this.isDestructive = false,
  });
}
