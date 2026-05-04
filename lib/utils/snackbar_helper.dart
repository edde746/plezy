import 'package:flutter/material.dart';

import 'layout_constants.dart';

/// Global key for the root ScaffoldMessenger, allowing snackbars to survive navigation.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Nested messenger inside MainScreen — its Scaffold owns the bottom NavigationBar
/// so floating snackbars auto-offset above the navbar.
final mainScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Types of snackbars available in the app
enum SnackBarType { info, success, error }

/// Utility functions for showing snackbars throughout the application

void showSnackBar(BuildContext context, String message, {SnackBarType type = SnackBarType.info, Duration? duration}) {
  if (!context.mounted) return;

  final (backgroundColor, defaultDuration) = switch (type) {
    SnackBarType.info => (null, AppDurations.snackBarDefault),
    SnackBarType.success => (Colors.green, AppDurations.snackBarDefault),
    SnackBarType.error => (Colors.red, AppDurations.snackBarLong),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: duration ?? defaultDuration),
  );
}

void showAppSnackBar(BuildContext context, String message, {Duration? duration}) {
  showSnackBar(context, message, type: SnackBarType.info, duration: duration);
}

void showErrorSnackBar(BuildContext context, String message) {
  showSnackBar(context, message, type: SnackBarType.error);
}

/// Shows an error snackbar using the root ScaffoldMessenger (survives navigation).
void showGlobalErrorSnackBar(String message) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red, duration: AppDurations.snackBarLong),
  );
}

/// Shows an info snackbar through the main-screen messenger when available
/// (so it floats above the mobile NavigationBar), falling back to the root
/// messenger when the main screen is not mounted.
void showMainSnackBar(String message, {Duration duration = AppDurations.snackBarDefault}) {
  final messenger = mainScaffoldMessengerKey.currentState ?? rootScaffoldMessengerKey.currentState;
  messenger
    ?..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: duration));
}

void showSuccessSnackBar(BuildContext context, String message) {
  showSnackBar(context, message, type: SnackBarType.success);
}
