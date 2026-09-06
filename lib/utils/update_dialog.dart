import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../services/android_update_service.dart';
import '../services/update_service.dart';
import '../widgets/dialog_action_button.dart';
import 'dialogs.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  Map<String, dynamic> updateInfo, {
  required String title,
  required String dismissLabel,
  bool showSkipVersion = false,
}) {
  final androidAsset = updateInfo['androidAsset'];
  if (androidAsset is AndroidUpdateAsset) {
    return showScopedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AndroidUpdateDialog(
        updateInfo: updateInfo,
        asset: androidAsset,
        title: title,
        dismissLabel: dismissLabel,
        showSkipVersion: showSkipVersion,
      ),
    );
  }

  return showScopedDialog<void>(
    context: context,
    builder: (dialogContext) {
      final latestVersion = updateInfo['latestVersion'] as String;
      final releaseUrl = updateInfo['releaseUrl'] as String;

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
              final url = Uri.parse(releaseUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            label: t.update.viewRelease,
            isPrimary: true,
          ),
        ],
      );
    },
  );
}

class _AndroidUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;
  final AndroidUpdateAsset asset;
  final String title;
  final String dismissLabel;
  final bool showSkipVersion;

  const _AndroidUpdateDialog({
    required this.updateInfo,
    required this.asset,
    required this.title,
    required this.dismissLabel,
    required this.showSkipVersion,
  });

  @override
  State<_AndroidUpdateDialog> createState() => _AndroidUpdateDialogState();
}

class _AndroidUpdateDialogState extends State<_AndroidUpdateDialog> {
  AndroidUpdateService? _updater;
  double? _progress;
  bool _failed = false;

  @override
  void dispose() {
    _updater?.cancel();
    super.dispose();
  }

  Future<void> _install() async {
    final updater = AndroidUpdateService();
    setState(() {
      _updater = updater;
      _progress = null;
      _failed = false;
    });
    try {
      await updater.downloadAndInstall(widget.asset, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (mounted) Navigator.pop(context);
    } on UpdateDownloadCancelled {
      // Closing the dialog cancels the request intentionally.
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _updater = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _updater != null;
    final version = widget.updateInfo['latestVersion'] as String;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(t.update.versionAvailable(version: version), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(t.update.currentVersion(version: widget.updateInfo['currentVersion']), style: Theme.of(context).textTheme.bodySmall),
          if (busy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_failed) ...[
            const SizedBox(height: 16),
            Text(t.downloads.errorDownloadFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        DialogActionButton(
          onPressed: () {
            _updater?.cancel();
            Navigator.pop(context);
          },
          label: busy ? t.common.cancel : widget.dismissLabel,
        ),
        if (!busy && widget.showSkipVersion)
          DialogActionButton(
            onPressed: () async {
              await UpdateService.skipVersion(version);
              if (context.mounted) Navigator.pop(context);
            },
            label: t.update.skipVersion,
          ),
        if (!busy)
          DialogActionButton(
            onPressed: () async {
              final url = Uri.parse(widget.updateInfo['releaseUrl'] as String);
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            label: t.update.viewRelease,
          ),
        DialogActionButton(
          onPressed: busy ? null : _install,
          label: _failed ? t.common.retry : t.downloads.downloadNow,
          isPrimary: true,
        ),
      ],
    );
  }
}
