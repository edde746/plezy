import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../services/background_work_diagnostics_service.dart';
import '../services/settings_service.dart';
import '../utils/notification_permission.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';

/// Community-maintained per-vendor instructions for OEM background-work
/// settings. The site root asks the user to pick their manufacturer, which is
/// more reliable than us guessing a slug from `Build.MANUFACTURER`.
const _dontKillMyAppUrl = 'https://dontkillmyapp.com';

/// Banner shown at the top of the Downloads screen when the OS is expected to
/// stop downloads the moment the app is backgrounded.
///
/// Deliberately conditional on there being something to download: an idle
/// Downloads screen should not nag, and a warning users learn to dismiss is
/// worse than no warning. Collapses to nothing when the verdict is healthy or
/// the platform cannot answer.
class BackgroundDownloadWarningBanner extends StatelessWidget {
  const BackgroundDownloadWarningBanner({super.key, required this.hasPendingDownloads, this.service});

  /// Whether anything is queued or in flight. The restriction only matters
  /// while there is a transfer for it to kill.
  final bool hasPendingDownloads;

  final BackgroundWorkDiagnosticsService? service;

  BackgroundWorkDiagnosticsService get _service => service ?? BackgroundWorkDiagnosticsService.instance;

  @override
  Widget build(BuildContext context) {
    if (!hasPendingDownloads || !_service.isSupported) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final status = _service.status;
        if (status.isHealthy) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final blocked = status.isBlocked;
        final background = blocked ? scheme.errorContainer : scheme.tertiaryContainer;
        final foreground = blocked ? scheme.onErrorContainer : scheme.onTertiaryContainer;

        return Material(
          color: background,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                AppIcon(blocked ? Symbols.battery_alert_rounded : Symbols.info_rounded, fill: 1, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    blocked
                        ? t.downloads.backgroundWarning.bannerBlocked
                        : t.downloads.backgroundWarning.bannerDegraded,
                    style: theme.textTheme.bodyMedium?.copyWith(color: foreground, fontWeight: .w500),
                  ),
                ),
                const SizedBox(width: 8),
                FocusableButton(
                  onPressed: () => showBackgroundDownloadWarningDialog(context, service: _service),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(backgroundColor: foreground, foregroundColor: background),
                    onPressed: () => showBackgroundDownloadWarningDialog(context, service: _service),
                    child: Text(t.downloads.backgroundWarning.bannerAction),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-flight gate before a user-initiated download.
///
/// Returns whether to proceed with queueing. Interrupts at most once per
/// install — the persistent Downloads-screen banner covers repeat offenders,
/// and a dialog on every download would only teach users to dismiss it.
/// Only [BackgroundWorkVerdict.blocked] is worth interrupting for; a Data Saver
/// warning can wait for the banner.
Future<bool> confirmBackgroundDownloadRestrictions(
  BuildContext context, {
  BackgroundWorkDiagnosticsService? service,
  Future<void> Function()? notificationPermissionRequester,
}) async {
  final diagnostics = service ?? BackgroundWorkDiagnosticsService.instance;
  if (!diagnostics.isSupported) return true;

  await (notificationPermissionRequester ?? NotificationPermission.ensure)();
  if (!context.mounted) return false;

  final settings = SettingsService.instanceOrNull;
  if (settings?.read(SettingsService.backgroundDownloadWarningAcknowledged) ?? false) return true;

  await diagnostics.refresh();
  if (!diagnostics.status.isBlocked) return true;
  if (!context.mounted) return false;

  // Recorded before the dialog resolves: whichever button the user picks, they
  // have now been told, and the banner takes over from here.
  await settings?.write(SettingsService.backgroundDownloadWarningAcknowledged, true);
  if (!context.mounted) return false;
  return showBackgroundDownloadWarningDialog(context, preFlight: true, service: diagnostics);
}

/// Explains the detected restrictions and routes to the Settings screen that
/// fixes them.
///
/// When [preFlight] is set the dialog is interrupting a download the user just
/// asked for, so it offers "Download anyway" and returns whether to proceed.
/// Otherwise it is informational and always resolves to true.
Future<bool> showBackgroundDownloadWarningDialog(
  BuildContext context, {
  bool preFlight = false,
  BackgroundWorkDiagnosticsService? service,
  Future<bool> Function(Uri uri)? externalUrlLauncher,
}) async {
  final diagnostics = service ?? BackgroundWorkDiagnosticsService.instance;
  final status = diagnostics.status;
  if (status.isHealthy) return true;

  final proceed = await showScopedDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(
          preFlight
              ? t.downloads.backgroundWarning.dialogTitle
              : status.isBlocked
              ? t.downloads.backgroundWarning.sheetTitle
              : t.downloads.backgroundWarning.sheetTitleDegraded,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Text(
                status.isBlocked
                    ? t.downloads.backgroundWarning.sheetIntro
                    : t.downloads.backgroundWarning.sheetIntroDegraded,
              ),
              for (final reason in status.reasons) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: const AppIcon(Symbols.chevron_right_rounded, fill: 1, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_describeReason(reason))),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text(t.downloads.backgroundWarning.stillNotWorking, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(t.downloads.backgroundWarning.stillNotWorkingDescription, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Align(
                alignment: .centerLeft,
                child: FocusableButton(
                  onPressed: () => _openDontKillMyApp(dialogContext, launcher: externalUrlLauncher),
                  child: TextButton.icon(
                    onPressed: () => _openDontKillMyApp(dialogContext, launcher: externalUrlLauncher),
                    icon: const AppIcon(Symbols.open_in_new_rounded, fill: 1, size: 18),
                    label: const Text('dontkillmyapp.com'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (preFlight)
            DialogActionButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              label: t.downloads.backgroundWarning.dialogDownloadAnyway,
            )
          else
            DialogActionButton(onPressed: () => Navigator.pop(dialogContext, true), label: t.common.close),
          DialogActionButton(
            autofocus: true,
            isPrimary: true,
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messengerContext = dialogContext;
              if (status.reasons.contains(BackgroundWorkReason.oemUnknown)) {
                await diagnostics.clearStallEvidence();
              }
              final opened = await diagnostics.openSettings(status.remedyTarget);
              if (!opened && messengerContext.mounted) {
                showErrorSnackBar(messengerContext, t.downloads.backgroundWarning.settingsUnavailable);
              }
              if (navigator.mounted) navigator.pop(preFlight ? false : true);
            },
            label: preFlight
                ? t.downloads.backgroundWarning.dialogFixFirst
                : t.downloads.backgroundWarning.openSettings,
          ),
        ],
      );
    },
  );

  return proceed ?? !preFlight;
}

String _describeReason(BackgroundWorkReason reason) => switch (reason) {
  BackgroundWorkReason.backgroundRestricted => t.downloads.backgroundWarning.reasonBackgroundRestricted,
  BackgroundWorkReason.standbyRestricted => t.downloads.backgroundWarning.reasonStandbyRestricted,
  BackgroundWorkReason.downloadChannelBlocked => t.downloads.backgroundWarning.reasonDownloadChannelBlocked,
  BackgroundWorkReason.notificationsDisabled => t.downloads.backgroundWarning.reasonNotificationsDisabled,
  BackgroundWorkReason.dataSaver => t.downloads.backgroundWarning.reasonDataSaver,
  BackgroundWorkReason.oemUnknown => t.downloads.backgroundWarning.reasonOemUnknown,
};

Future<void> _openDontKillMyApp(BuildContext context, {Future<bool> Function(Uri uri)? launcher}) async {
  var opened = false;
  try {
    final uri = Uri.parse(_dontKillMyAppUrl);
    opened = await (launcher?.call(uri) ?? launchUrl(uri, mode: LaunchMode.externalApplication));
  } catch (_) {
    // Reported below using the same user-facing fallback as a false result.
  }
  if (!opened && context.mounted) {
    showErrorSnackBar(context, t.downloads.backgroundWarning.linkUnavailable);
  }
}
