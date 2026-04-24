import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';

/// Shared "connect this tracker" launcher.
///
/// Handles the busy/already-connected guard, shows the service's code dialog
/// once `connect` hands us a payload, auto-launches the browser on pointer
/// platforms, closes the dialog when the flow resolves, and surfaces a failure
/// snack. Service-specific pieces are supplied via [connect], [buildDialog],
/// and [urlFor] so both `TrackersProvider`-backed and `TraktAccountProvider`-
/// backed flows share one code path.
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

  final ok = await connect((payload) {
    if (!context.mounted) return;
    dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => buildDialog(payload, () {
        // Flip synchronously so the post-await guard below is a no-op —
        // `whenComplete` fires a microtask later and loses the race otherwise.
        dialogOpen = false;
        onCancel();
      }),
    ).whenComplete(() => dialogOpen = false);
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
  // Close the dialog iff we showed one and it's still up (not already closed by
  // the Cancel button). This is the ONLY site that dismisses the dialog —
  // popping here and having the dialog self-pop would pop the screen behind.
  if (dialogOpen) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  if (!ok) {
    showAppSnackBar(context, t.trackers.connectFailed(service: serviceName));
  }
}
