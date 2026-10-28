import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/trackers/device_code.dart';
import '../../providers/trackers_provider.dart';
import '../../services/file_picker_service.dart';
import '../../services/settings_service.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../services/trackers/trakt/trakt_letterboxd_export_service.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/device_code_dialog.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_page.dart';
import 'tracker_account_settings_body.dart';
import 'tracker_connect_launcher.dart';

Future<void> startTraktConnection(BuildContext context) {
  final account = context.read<TrackersProvider>();
  final name = t.trakt.title;
  return launchTrackerConnect<DeviceCode>(
    context,
    isBusyOrConnected: account.isConnecting(TrackerService.trakt) || account.isTraktConnected,
    serviceName: name,
    connect: (cb) => account.connectTrakt(onCodeReady: cb),
    onCancel: account.cancelConnect,
    buildDialog: (code, cancel) => DeviceCodeDialog(code: code, serviceName: name, onCancel: cancel),
    urlFor: (code) => code.verificationUrlComplete ?? code.verificationUrl,
  );
}

class TraktSettingsScreen extends StatelessWidget {
  const TraktSettingsScreen({super.key});

  Future<void> _exportLetterboxdHistory(BuildContext context, TrackersProvider account) async {
    final client = account.traktCatalogClient;
    if (client == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(t.trakt.historyExportLoading),
            content: const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );

    final TraktLetterboxdExport export;
    try {
      export = await TraktLetterboxdExportService.create(client);
    } catch (error) {
      if (navigator.mounted) navigator.pop();
      if (context.mounted) {
        final message = error is TraktLetterboxdExportException && error.isSizeLimit
            ? t.trakt.historyExportTooLarge
            : t.trakt.historyExportFailed;
        _showHistoryExportMessage(context, message);
      }
      return;
    }
    if (navigator.mounted) navigator.pop();
    if (!context.mounted) return;
    if (export.parts.isEmpty) {
      _showHistoryExportMessage(context, t.trakt.historyExportNoHistory);
      return;
    }

    final review = StringBuffer(
      t.trakt.historyExportReview(
        plays: export.playCount,
        movies: export.movieCount,
        files: export.parts.length,
      ),
    );
    if (export.skippedCount > 0) {
      review.write('\n\n');
      review.write(t.trakt.historyExportSkipped(count: export.skippedCount));
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.trakt.historyExportReviewTitle),
        content: SingleChildScrollView(child: Text(review.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Symbols.file_download_rounded),
            label: Text(t.trakt.historyExportSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var saved = 0;
    for (var index = 0; index < export.parts.length; index++) {
      final part = export.parts[index];
      final fileName = _letterboxdFileName(index, export.parts.length);
      try {
        final path = await FilePickerService.instance.saveFile(
          dialogTitle: export.parts.length == 1
              ? t.trakt.historyExportSave
              : t.trakt.historyExportPart(part: index + 1, total: export.parts.length),
          fileName: fileName,
          bytes: part.bytes,
          type: FileType.custom,
          allowedExtensions: const ['csv'],
        );
        if (path == null) break;
        saved++;
      } catch (_) {
        if (context.mounted) {
          final message = saved == 0
              ? t.trakt.historyExportSaveFailed
              : t.trakt.historyExportPartial(saved: saved, total: export.parts.length);
          _showHistoryExportMessage(context, message);
        }
        return;
      }
    }

    if (!context.mounted) return;
    if (saved == export.parts.length) {
      _showHistoryExportMessage(context, t.trakt.historyExportSaved(count: saved));
    } else if (saved > 0) {
      _showHistoryExportMessage(
        context,
        t.trakt.historyExportPartial(saved: saved, total: export.parts.length),
      );
    }
  }

  String _letterboxdFileName(int index, int total) {
    final date = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    if (total == 1) return 'plezyng-trakt-letterboxd-$date.csv';
    final part = (index + 1).toString().padLeft(2, '0');
    final count = total.toString().padLeft(2, '0');
    return 'plezyng-trakt-letterboxd-$date-part-$part-of-$count.csv';
  }

  void _showHistoryExportMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _disconnect(BuildContext context, TrackersProvider account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.trakt.disconnectConfirm,
      message: t.trakt.disconnectConfirmBody,
      confirmText: t.common.disconnect,
      isDestructive: true,
    );
    if (!confirmed) return;
    await account.disconnectTrakt();
    // build()'s post-frame handler pops the screen once the provider rebuilds
    // with isConnected == false — don't pop here too.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackersProvider>(
      builder: (context, account, _) {
        // Safety net: if we end up here while not connected (e.g. refresh failed
        // in the background and cleared the session), bail out. The settings
        // tile is the only supported entry point for the unauthed flow.
        if (!account.isTraktConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return SettingsPage.slivers(
            title: Text(t.trakt.title),
            slivers: const [SliverFillRemaining(child: SizedBox.shrink())],
          );
        }

        final username = account.traktUsername;
        return TrackerAccountSettingsBody(
          title: Text(t.trakt.title),
          accountTitle: username != null ? t.trakt.connectedAs(username: username) : t.trakt.connected,
          accountSubtitle: t.trakt.connected,
          service: TrackerService.trakt,
          accountActions: [
            FocusableListTile(
              leading: const AppIcon(Symbols.file_download_rounded, fill: 1),
              title: Text(t.trakt.historyExport),
              subtitle: Text(t.trakt.historyExportDescription),
              onTap: () => unawaited(_exportLetterboxdHistory(context, account)),
            ),
          ],
          toggles: [
            TrackerSettingsToggle(
              pref: SettingsService.scrobblePref(TrackerService.trakt),
              icon: Symbols.auto_timer_rounded,
              title: t.trakt.scrobble,
              subtitle: t.trakt.scrobbleDescription,
            ),
            TrackerSettingsToggle(
              pref: SettingsService.enableTraktWatchedSync,
              icon: Symbols.check_circle_rounded,
              title: t.trakt.watchedSync,
              subtitle: t.trakt.watchedSyncDescription,
            ),
          ],
          onDisconnect: () => _disconnect(context, account),
        );
      },
    );
  }
}
