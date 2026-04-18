import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../i18n/strings.g.dart';
import '../models/plex_metadata.dart';
import '../providers/download_provider.dart';
import '../services/plex_client.dart';
import 'content_utils.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';
import 'global_key_utils.dart';

/// Dialog option for the download picker. Typed to avoid stringly-typed values.
enum _DownloadChoice { all, unwatched, next5, next10, custom }

/// Whether the user chose a one-time download or a persistent sync rule.
enum _SyncChoice { downloadOnce, keepSynced }

/// Result of the download dialog + queue operation.
class DownloadResult {
  final int count;
  final bool syncRuleCreated;
  final bool syncRuleUpdated;
  const DownloadResult({required this.count, this.syncRuleCreated = false, this.syncRuleUpdated = false});

  String toSnackBarMessage() {
    if (syncRuleUpdated) return t.downloads.syncRuleUpdated;
    if (syncRuleCreated) return t.downloads.syncRuleCreated(count: count.toString());
    if (count > 1) return t.downloads.episodesQueued(count: count);
    return t.downloads.downloadQueued;
  }
}

/// Shows download options dialog for shows/seasons, then queues the download.
/// For movies/episodes, queues directly without a dialog.
/// Returns a [DownloadResult], or null if cancelled.
Future<DownloadResult?> showDownloadOptionsAndQueue(
  BuildContext context, {
  required PlexMetadata metadata,
  required PlexClient client,
  required DownloadProvider downloadProvider,
}) async {
  final mt = metadata.mediaType;

  var filter = DownloadFilter.all;
  int? maxCount;
  bool keepSynced = false;

  if (mt == PlexMediaType.show || mt == PlexMediaType.season) {
    int? customCount;
    final selected = await showOptionPickerDialog<_DownloadChoice>(
      context,
      title: t.downloads.downloadNow,
      options: [
        (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: _DownloadChoice.all),
        (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: _DownloadChoice.unwatched),
        (icon: Symbols.filter_5_rounded, label: t.downloads.nextNUnwatched(count: 5), value: _DownloadChoice.next5),
        (
          icon: Symbols.filter_9_plus_rounded,
          label: t.downloads.nextNUnwatched(count: 10),
          value: _DownloadChoice.next10,
        ),
        (icon: Symbols.tune_rounded, label: t.downloads.customAmount, value: _DownloadChoice.custom),
      ],
      onBeforeClose: (value) async {
        if (value != _DownloadChoice.custom) return value;
        customCount = await _showEpisodeCountDialog(context);
        return customCount != null ? value : null;
      },
    );

    if (selected == null || !context.mounted) return null;

    switch (selected) {
      case _DownloadChoice.all:
        break;
      case _DownloadChoice.unwatched:
        filter = DownloadFilter.unwatched;
      case _DownloadChoice.next5:
        filter = DownloadFilter.unwatched;
        maxCount = 5;
      case _DownloadChoice.next10:
        filter = DownloadFilter.unwatched;
        maxCount = 10;
      case _DownloadChoice.custom:
        filter = DownloadFilter.unwatched;
        maxCount = customCount;
    }

    // For unwatched-based options on shows, offer sync vs one-time download
    if (filter == DownloadFilter.unwatched && mt == PlexMediaType.show && context.mounted) {
      final syncChoice = await showOptionPickerDialog<_SyncChoice>(
        context,
        title: t.downloads.downloadNow,
        options: [
          (icon: Symbols.download_rounded, label: t.downloads.downloadOnce, value: _SyncChoice.downloadOnce),
          (icon: Symbols.sync_rounded, label: t.downloads.keepSynced, value: _SyncChoice.keepSynced),
        ],
      );
      if (syncChoice == null || !context.mounted) return null;
      keepSynced = syncChoice == _SyncChoice.keepSynced;
    }
  }

  if (!context.mounted) return null;

  final versionConfig = await resolveDownloadVersion(context, metadata, client);
  if (versionConfig == null || !context.mounted) return null;

  // Create or update sync rule before queueing (so the rule exists even if queue fails)
  bool syncRuleUpdated = false;
  if (keepSynced) {
    final globalKey = buildGlobalKey(metadata.serverId ?? client.serverId, metadata.ratingKey);
    syncRuleUpdated = downloadProvider.hasSyncRule(globalKey);

    final syncCount = maxCount ?? 0; // 0 means "all unwatched" for the rule
    await downloadProvider.createSyncRule(
      serverId: metadata.serverId ?? client.serverId,
      ratingKey: metadata.ratingKey,
      targetType: metadata.type ?? ContentTypes.show,
      episodeCount: syncCount,
      mediaIndex: versionConfig.mediaIndex,
    );
  }

  final count = await downloadProvider.queueDownload(
    metadata,
    client,
    versionConfig: versionConfig,
    filter: filter,
    maxCount: maxCount,
  );

  return DownloadResult(
    count: count,
    syncRuleCreated: keepSynced && !syncRuleUpdated,
    syncRuleUpdated: syncRuleUpdated,
  );
}

/// Shows download options dialog for playlists, then queues the download.
/// Returns the number of items queued, or null if cancelled.
Future<int?> showPlaylistDownloadOptionsAndQueue(
  BuildContext context, {
  required List<PlexMetadata> items,
  required PlexClient client,
  required DownloadProvider downloadProvider,
}) async {
  final selected = await showOptionPickerDialog<DownloadFilter>(
    context,
    title: t.downloads.downloadNow,
    options: [
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: DownloadFilter.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: DownloadFilter.unwatched),
    ],
  );

  if (selected == null || !context.mounted) return null;

  return await downloadProvider.queuePlaylistDownload(items, client, filter: selected);
}

Future<int?> _showEpisodeCountDialog(BuildContext context, {String? title, String? hintText}) async {
  final result = await showTextInputDialog(
    context,
    title: title ?? t.downloads.howManyEpisodes,
    labelText: '',
    hintText: hintText ?? '',
    confirmText: t.common.ok,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (text) {
      final n = int.tryParse(text);
      if (n == null || n <= 0) return '';
      return null;
    },
  );
  if (result == null) return null;
  return int.tryParse(result);
}

/// Shows a dialog to edit a sync rule's episode count. Returns true if updated.
Future<bool> editSyncRuleCount(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required int currentCount,
}) async {
  final count = await _showEpisodeCountDialog(
    context,
    title: t.downloads.editEpisodeCount,
    hintText: currentCount.toString(),
  );
  if (count == null || !context.mounted) return false;

  await downloadProvider.updateSyncRuleCount(globalKey, count);
  return true;
}

/// Shows a confirmation dialog to remove a sync rule. Returns true if removed.
Future<bool> confirmAndRemoveSyncRule(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required String displayTitle,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: t.downloads.removeSyncRule,
    message: t.downloads.removeSyncRuleConfirm(title: displayTitle),
    confirmText: t.downloads.removeSyncRule,
  );
  if (!confirmed || !context.mounted) return false;

  await downloadProvider.deleteSyncRule(globalKey);
  return true;
}
