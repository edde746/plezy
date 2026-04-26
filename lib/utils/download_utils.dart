import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../database/app_database.dart';
import '../providers/download_provider.dart';
import '../services/sync_rule_executor.dart';
import 'content_utils.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';
import 'snackbar_helper.dart';

/// Dialog option for the download picker. Typed to avoid stringly-typed values.
enum _DownloadChoice { all, unwatched, next5, next10, custom }

/// Whether the user chose a one-time download or a persistent sync rule.
enum _SyncChoice { downloadOnce, keepSynced }

/// Result of the download dialog + queue operation.
class DownloadResult {
  final int count;
  final bool syncRuleCreated;
  final bool syncRuleUpdated;

  /// `true` when the rule targets a collection/playlist — affects the
  /// "created" snackbar wording (no "unwatched episodes" suffix).
  final bool isListRule;

  const DownloadResult({
    required this.count,
    this.syncRuleCreated = false,
    this.syncRuleUpdated = false,
    this.isListRule = false,
  });

  String toSnackBarMessage() {
    if (syncRuleUpdated) return t.downloads.syncRuleUpdated;
    if (syncRuleCreated) {
      return isListRule ? t.downloads.syncRuleListCreated : t.downloads.syncRuleCreated(count: count.toString());
    }
    if (count > 1) return t.downloads.episodesQueued(count: count);
    return t.downloads.downloadQueued;
  }
}

/// Shows download options dialog for shows/seasons, then queues the download.
/// For movies/episodes, queues directly without a dialog.
/// Returns a [DownloadResult], or null if cancelled.
Future<DownloadResult?> showDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem metadata,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
}) async {
  final kind = metadata.kind;

  var filter = DownloadFilter.all;
  int? maxCount;
  bool keepSynced = false;

  if (kind == MediaKind.show || kind == MediaKind.season) {
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
    if (filter == DownloadFilter.unwatched && kind == MediaKind.show && context.mounted) {
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
    final syncCount = maxCount ?? 0; // 0 means "all unwatched" for the rule
    final ruleKey = downloadProvider.syncRuleKeyFor(metadata.serverId ?? client.serverId, metadata.id);
    syncRuleUpdated = downloadProvider.hasSyncRule(ruleKey);

    await downloadProvider.createSyncRule(
      serverId: metadata.serverId ?? client.serverId,
      ratingKey: metadata.id,
      targetType: metadata.kind.id.isNotEmpty ? metadata.kind.id : ContentTypes.show,
      episodeCount: syncCount,
      mediaIndex: versionConfig.mediaIndex,
      targetMetadata: metadata,
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

/// Shows download options dialog for a collection or playlist, then queues
/// the download. Offers both one-time download and "Keep Synced" (creates or
/// updates a sync rule for the target).
///
/// [rootMetadata] is the collection or playlist itself — used to persist the
/// title/thumb for the sync rule and build the rule's global key.
/// [targetType] must be [ContentTypes.collection] or [ContentTypes.playlist].
Future<DownloadResult?> showListDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem rootMetadata,
  required String targetType,
  required List<MediaItem> items,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
}) async {
  assert(targetType == ContentTypes.collection || targetType == ContentTypes.playlist);

  final selectedFilter = await showOptionPickerDialog<DownloadFilter>(
    context,
    title: t.downloads.downloadNow,
    options: [
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: DownloadFilter.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: DownloadFilter.unwatched),
    ],
  );

  if (selectedFilter == null || !context.mounted) return null;

  final syncChoice = await showOptionPickerDialog<_SyncChoice>(
    context,
    title: t.downloads.downloadNow,
    options: [
      (icon: Symbols.download_rounded, label: t.downloads.downloadOnce, value: _SyncChoice.downloadOnce),
      (icon: Symbols.sync_rounded, label: t.downloads.keepSynced, value: _SyncChoice.keepSynced),
    ],
  );
  if (syncChoice == null || !context.mounted) return null;

  final serverId = rootMetadata.serverId ?? client.serverId;
  final filterString = selectedFilter == DownloadFilter.unwatched ? SyncRuleFilter.unwatched : SyncRuleFilter.all;

  bool syncRuleCreated = false;
  bool syncRuleUpdated = false;

  if (syncChoice == _SyncChoice.keepSynced) {
    final ruleKey = downloadProvider.syncRuleKeyFor(serverId, rootMetadata.id);
    if (downloadProvider.hasSyncRule(ruleKey)) {
      await downloadProvider.updateSyncRuleFilter(ruleKey, filterString);
      syncRuleUpdated = true;
    } else {
      await downloadProvider.createSyncRule(
        serverId: serverId,
        ratingKey: rootMetadata.id,
        targetType: targetType,
        episodeCount: 0,
        mediaIndex: 0,
        downloadFilter: filterString,
        targetMetadata: rootMetadata,
      );
      syncRuleCreated = true;
    }
  }

  final count = await downloadProvider.queueListDownload(items, client, filter: selectedFilter);

  return DownloadResult(
    count: count,
    syncRuleCreated: syncRuleCreated,
    syncRuleUpdated: syncRuleUpdated,
    isListRule: true,
  );
}

/// Shows the shared list-download dialog for a playlist.
Future<DownloadResult?> showPlaylistDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem playlistMetadata,
  required List<MediaItem> items,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
}) => showListDownloadOptionsAndQueue(
  context,
  rootMetadata: playlistMetadata,
  targetType: ContentTypes.playlist,
  items: items,
  client: client,
  downloadProvider: downloadProvider,
);

/// Shows the shared list-download dialog for a collection.
Future<DownloadResult?> showCollectionDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem collectionMetadata,
  required List<MediaItem> items,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
}) => showListDownloadOptionsAndQueue(
  context,
  rootMetadata: collectionMetadata,
  targetType: ContentTypes.collection,
  items: items,
  client: client,
  downloadProvider: downloadProvider,
);

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

/// Shows a dialog to edit a collection/playlist sync rule's filter. Returns
/// true if the filter changed.
Future<bool> editSyncRuleFilter(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required String currentFilter,
}) async {
  final selected = await showOptionPickerDialog<String>(
    context,
    title: t.downloads.editSyncFilter,
    options: [
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: SyncRuleFilter.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: SyncRuleFilter.unwatched),
    ],
  );
  if (selected == null || selected == currentFilter || !context.mounted) return false;

  await downloadProvider.updateSyncRuleFilter(globalKey, selected);
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

/// Whether this rule targets a collection or playlist (as opposed to a
/// show/season). Shared by detail screens, the sync rules screen, and the
/// context menu to dispatch between count vs. filter editing.
extension SyncRuleItemDispatch on SyncRuleItem {
  bool get isListRule => targetType == ContentTypes.collection || targetType == ContentTypes.playlist;
}

/// Open the right sync-rule edit dialog for [globalKey] and show a success
/// snackbar when anything changed. Used by both detail screens and the
/// context menu so they don't each reimplement the get-rule / edit / snack
/// dance.
Future<void> manageSyncRule(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
}) async {
  final rule = downloadProvider.getSyncRule(globalKey);
  if (rule == null) return;

  final bool updated;
  if (rule.isListRule) {
    updated = await editSyncRuleFilter(
      context,
      downloadProvider: downloadProvider,
      globalKey: globalKey,
      currentFilter: rule.downloadFilter,
    );
  } else {
    updated = await editSyncRuleCount(
      context,
      downloadProvider: downloadProvider,
      globalKey: globalKey,
      currentCount: rule.episodeCount,
    );
  }
  if (updated && context.mounted) {
    showSuccessSnackBar(context, t.downloads.syncRuleUpdated);
  }
}

/// Confirm + remove a sync rule and show a success snackbar.
Future<void> removeSyncRuleAndSnack(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required String displayTitle,
}) async {
  final removed = await confirmAndRemoveSyncRule(
    context,
    downloadProvider: downloadProvider,
    globalKey: globalKey,
    displayTitle: displayTitle,
  );
  if (removed && context.mounted) {
    showSuccessSnackBar(context, t.downloads.syncRuleRemoved);
  }
}
