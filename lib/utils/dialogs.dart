import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';

/// Utility functions for showing common dialogs

/// Shows a delete confirmation dialog
/// Returns true if user confirmed, false if cancelled
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(t.common.delete),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
