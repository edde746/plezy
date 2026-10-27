import 'package:flutter/widgets.dart';

import '../profiles/profile_activation.dart';
import 'dialogs.dart';

/// Re-check the active local profile PIN before a user explicitly deletes
/// downloaded media. Plex Home PINs remain server-owned.
Future<bool> requestDownloadDeletionPin(BuildContext context) => requestActiveProfileActionPin(context);

/// Require the active profile PIN before showing the standard destructive
/// confirmation used by download deletion actions.
Future<bool> confirmDownloadDeletion(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
}) async {
  if (!context.mounted || !await requestDownloadDeletionPin(context) || !context.mounted) {
    return false;
  }
  return showDeleteConfirmation(context, title: title, message: message, confirmText: confirmText);
}
