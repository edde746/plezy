import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../services/android_self_update.dart';
import '../services/update_service.dart';
import '../widgets/dialog_action_button.dart';
import 'app_logger.dart';
import 'dialogs.dart';
import 'snackbar_helper.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  Map<String, dynamic> updateInfo, {
  required String title,
  required String dismissLabel,
  bool showSkipVersion = false,
}) async {
  // The GitHub Android build installs the release itself; elsewhere the dialog links to it.
  final selfUpdate = await AndroidSelfUpdate.isSupported();
  if (!context.mounted) return;

  return showScopedDialog<void>(
    context: context,
    builder: (dialogContext) {
      final latestVersion = updateInfo['latestVersion'] as String;
      final releaseUrl = updateInfo['releaseUrl'] as String;

      Future<void> openRelease() async {
        final url = Uri.parse(releaseUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }

      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              t.update.versionAvailable(version: latestVersion),
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.update.currentVersion(version: updateInfo['currentVersion']),
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: dismissLabel),
          if (showSkipVersion)
            DialogActionButton(
              onPressed: () async {
                await UpdateService.skipVersion(latestVersion);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              label: t.update.skipVersion,
            ),
          DialogActionButton(
            onPressed: () async {
              await openRelease();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            label: t.update.viewRelease,
            isPrimary: !selfUpdate,
          ),
          if (selfUpdate)
            DialogActionButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                unawaited(_runAndroidSelfUpdate(context, updateInfo));
              },
              label: t.update.install,
              isPrimary: true,
              autofocus: true,
            ),
        ],
      );
    },
  );
}

/// Download, check and hand the release APK to the system installer. Errors end as a snackbar on
/// [context], the screen that showed the update dialog.
Future<void> _runAndroidSelfUpdate(BuildContext context, Map<String, dynamic> updateInfo) async {
  try {
    final assets = updateInfo['assets'] as List<Object?>? ?? const [];
    final asset = AndroidSelfUpdate.selectAsset(assets, await AndroidSelfUpdate.abiInfo());
    if (asset == null) throw const AndroidSelfUpdateException(AndroidSelfUpdateError.noCompatibleAsset);

    // Ask for the install permission before downloading, so the user does not wait for a download
    // only to be sent to the settings.
    if (!await AndroidSelfUpdate.canRequestInstall()) {
      if (!context.mounted) return;
      final granted = await _askInstallPermission(context);
      if (!granted || !context.mounted) return;
    }

    if (!context.mounted) return;
    final outcome = await showScopedDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDownloadDialog(asset: asset),
    );
    if (outcome is! File) {
      if (outcome is Exception) throw outcome;
      return; // dismissed with the route (e.g. the profile session ended)
    }
    final apk = outcome;

    await AndroidSelfUpdate.verifyApk(apk);
    await AndroidSelfUpdate.install(apk);
  } on AndroidSelfUpdateException catch (e, stackTrace) {
    if (e.error == AndroidSelfUpdateError.cancelled) return;
    appLogger.w('Android self-update failed', error: e, stackTrace: stackTrace);
    if (context.mounted) showErrorSnackBar(context, _messageFor(e.error));
  } catch (e, stackTrace) {
    appLogger.e('Android self-update failed', error: e, stackTrace: stackTrace);
    if (context.mounted) showErrorSnackBar(context, t.update.downloadFailed);
  }
}

String _messageFor(AndroidSelfUpdateError error) => switch (error) {
  AndroidSelfUpdateError.noCompatibleAsset => t.update.noCompatibleApk,
  AndroidSelfUpdateError.download || AndroidSelfUpdateError.cancelled => t.update.downloadFailed,
  AndroidSelfUpdateError.corrupt => t.update.corrupt,
  AndroidSelfUpdateError.signatureMismatch => t.update.signatureMismatch,
  AndroidSelfUpdateError.installer => t.update.installerFailed,
};

/// Explains the "Install unknown apps" permission and opens its settings page. Resolves true once
/// the user comes back with the permission granted.
Future<bool> _askInstallPermission(BuildContext context) async {
  final open = await showScopedDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.update.installPermissionTitle),
      content: Text(t.update.installPermissionMessage),
      actions: [
        DialogActionButton(onPressed: () => Navigator.pop(dialogContext, false), label: t.common.cancel),
        DialogActionButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          label: t.update.openSettings,
          isPrimary: true,
          autofocus: true,
        ),
      ],
    ),
  );
  if (open != true) return false;

  final resumed = Completer<void>();
  final listener = AppLifecycleListener(
    onResume: () {
      if (!resumed.isCompleted) resumed.complete();
    },
  );
  try {
    if (!await AndroidSelfUpdate.openInstallPermissionSettings()) {
      throw const AndroidSelfUpdateException(AndroidSelfUpdateError.installer, 'No install permission settings');
    }
    await resumed.future;
  } finally {
    listener.dispose();
  }
  return AndroidSelfUpdate.canRequestInstall();
}

/// Downloads [asset] with a progress bar. Pops with the extracted APK [File], or with the
/// exception that stopped the download (an [AndroidSelfUpdateError.cancelled] one on cancel), so
/// the caller reports it on a screen that is still mounted.
class _UpdateDownloadDialog extends StatefulWidget {
  const _UpdateDownloadDialog({required this.asset});

  final AndroidUpdateAsset asset;

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  bool _cancelled = false;
  int _received = 0;
  int? _total;

  @override
  void initState() {
    super.initState();
    unawaited(_download());
  }

  Future<void> _download() async {
    try {
      final apk = await AndroidSelfUpdate.download(
        widget.asset,
        isCancelled: () => _cancelled,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (mounted) Navigator.pop<Object>(context, apk);
    } on Exception catch (e) {
      if (mounted) Navigator.pop<Object>(context, e);
    }
  }

  void _cancel() {
    // The download notices between chunks and pops the dialog itself.
    setState(() => _cancelled = true);
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final fraction = total != null && total > 0 ? (_received / total).clamp(0.0, 1.0) : null;
    final megabytes = (_received / (1024 * 1024)).toStringAsFixed(1);
    final totalMegabytes = total == null ? null : (total / (1024 * 1024)).toStringAsFixed(1);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: AlertDialog(
        title: Text(t.update.downloading),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            LinearProgressIndicator(value: _cancelled ? null : fraction),
            const SizedBox(height: 8),
            Text(
              totalMegabytes == null ? '$megabytes MB' : '$megabytes / $totalMegabytes MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [DialogActionButton(onPressed: _cancelled ? null : _cancel, label: t.common.cancel, autofocus: true)],
      ),
    );
  }
}
