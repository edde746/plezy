import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';

/// Shared "connect this tracker" launcher.
///
/// Handles the busy/already-connected guard, shows the service's code dialog
/// once `connect` hands us a payload, auto-launches the browser on pointer
/// platforms, closes the dialog when the flow resolves, and surfaces a failure
/// snack — but not for the user's own cancellation. Service-specific pieces
/// are supplied via [connect], [buildDialog], and [urlFor] so every
/// `TrackersProvider`-backed flow shares one code path.
Future<void> launchTrackerConnect<T>(
  BuildContext context, {
  required bool isBusyOrConnected,
  required String serviceName,
  required Future<bool> Function(void Function(T)) connect,
  required VoidCallback onCancel,
  required Widget Function(T payload, VoidCallback onCancel) buildDialog,
  required String Function(T payload) urlFor,
}) async {
  if (isBusyOrConnected) return;

  final autoLaunchBrowser = !InputModeTracker.isKeyboardMode(context);
  var dialogOpen = false;
  var cancelled = false;
  // Set before this launcher's own pop below, so the dialog route completing
  // for a resolved flow is not mistaken for the user dismissing it.
  var resultClosing = false;

  // The single cancel path. Reached from the dialog's own pop (Cancel button
  // and system back both route through its PopScope) and from route
  // completion; idempotent so those overlapping signals cancel exactly once.
  void cancelDialog() {
    if (cancelled || resultClosing) return;
    cancelled = true;
    // Flip synchronously so the post-await pop below is a no-op —
    // `whenComplete` fires a microtask later and loses the race otherwise.
    dialogOpen = false;
    onCancel();
  }

  final ok = await connect((payload) {
    if (!context.mounted) return;
    dialogOpen = true;
    showScopedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => buildDialog(payload, cancelDialog),
    ).whenComplete(() {
      // Any dismissal this launcher did not perform itself must abort the
      // poll, or the connect stays pending until the code expires and the
      // Connect row is dead the whole time.
      cancelDialog();
      dialogOpen = false;
    });
    if (autoLaunchBrowser) {
      unawaited(
        launchUrl(Uri.parse(urlFor(payload)), mode: LaunchMode.externalApplication).catchError((Object e) {
          appLogger.d('$serviceName: failed to auto-launch browser', error: e);
          return false;
        }),
      );
    }
  });

  if (!context.mounted) return;
  // Close the dialog iff we showed one and it's still up (not already popped
  // by the Cancel button or system back). `resultClosing` marks this pop as
  // the flow resolving, so neither the dialog's PopScope nor route completion
  // treats it as a cancellation.
  if (dialogOpen) {
    resultClosing = true;
    Navigator.of(context).pop();
  }
  // The user's own cancellation is not a connection failure.
  if (!ok && !cancelled) {
    showAppSnackBar(context, t.services.connectFailed(service: serviceName));
  }
}
