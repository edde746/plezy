import 'package:flutter/material.dart';

/// Utility functions for showing snackbars throughout the application

/// Shows a standard snackbar with a message
///
/// [context] The build context
/// [message] The message to display
/// [duration] Optional duration, defaults to 3 seconds
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
    ),
  );
}

/// Shows an error snackbar with a message
///
/// [context] The build context
/// [message] The error message to display
void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Shows a success snackbar with a message
///
/// [context] The build context
/// [message] The success message to display
void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}
