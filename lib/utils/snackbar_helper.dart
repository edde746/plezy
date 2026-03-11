import 'package:flutter/material.dart';

/// Global key for the root ScaffoldMessenger, allowing snackbars to survive navigation.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Types of snackbars available in the app
enum SnackBarType {
  /// Standard informational snackbar
  info,

  /// Success snackbar (green background)
  success,

  /// Error snackbar (red background)
  error,
}

/// Utility functions for showing snackbars throughout the application

/// Shows a snackbar with the specified type
///
/// [context] The build context
/// [message] The message to display
/// [type] The type of snackbar (info, success, error)
/// [duration] Optional duration override
void showSnackBar(BuildContext context, String message, {SnackBarType type = SnackBarType.info, Duration? duration}) {
  if (!context.mounted) return;

  final (backgroundColor, defaultDuration) = switch (type) {
    SnackBarType.info => (null, const Duration(seconds: 3)),
    SnackBarType.success => (Colors.green, const Duration(seconds: 3)),
    SnackBarType.error => (Colors.red, const Duration(seconds: 4)),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: duration ?? defaultDuration),
  );
}

/// Shows a standard snackbar with a message
///
/// [context] The build context
/// [message] The message to display
/// [duration] Optional duration, defaults to 3 seconds
void showAppSnackBar(BuildContext context, String message, {Duration? duration}) {
  showSnackBar(context, message, type: SnackBarType.info, duration: duration);
}

/// Shows an error snackbar with a message
///
/// [context] The build context
/// [message] The error message to display
void showErrorSnackBar(BuildContext context, String message) {
  showSnackBar(context, message, type: SnackBarType.error);
}

/// Shows an error snackbar using the root ScaffoldMessenger (survives navigation).
void showGlobalErrorSnackBar(String message) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
  );
}

/// Shows a success snackbar with a message
///
/// [context] The build context
/// [message] The success message to display
void showSuccessSnackBar(BuildContext context, String message) {
  showSnackBar(context, message, type: SnackBarType.success);
}
