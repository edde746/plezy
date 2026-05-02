import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../providers/download_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';

Future<bool> confirmAndDeleteProfile(
  BuildContext context, {
  required Profile profile,
  required String title,
  required String message,
  String? confirmText,
}) async {
  final confirmed = await showDeleteConfirmation(context, title: title, message: message, confirmText: confirmText);
  if (!confirmed || !context.mounted) return false;

  try {
    await deleteProfile(context, profile);
    return true;
  } catch (error, stackTrace) {
    appLogger.w('Failed to delete profile ${profile.id}', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      showErrorSnackBar(context, t.errors.failedToDeleteProfile(displayName: profile.displayName));
    }
    return false;
  }
}

Future<void> deleteProfile(BuildContext context, Profile profile) async {
  final pcRegistry = context.read<ProfileConnectionRegistry>();
  final profileRegistry = context.read<ProfileRegistry>();
  final downloadProvider = context.read<DownloadProvider>();
  final active = context.read<ActiveProfileProvider>();
  final wasActive = active.activeId == profile.id;

  await downloadProvider.deleteDownloadsForProfile(profile.id);
  await pcRegistry.removeAllForProfile(profile.id);
  await profileRegistry.remove(profile.id);

  if (!wasActive) return;
  final remaining = active.profiles.where((p) => p.id != profile.id).toList();
  if (remaining.isNotEmpty) {
    await active.activate(remaining.first);
  } else {
    await active.clearActiveProfile();
  }
}
