import 'package:flutter/material.dart';
import '../media/ids.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../database/app_database.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../services/settings_service.dart';
import '../services/sync_rule_executor.dart';
import '../widgets/background_download_warning_banner.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/focusable_list_tile.dart';
import 'app_logger.dart';
import 'content_utils.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';
import 'platform_detector.dart';
import 'snackbar_helper.dart';

@visibleForTesting
String? validateEpisodeCountInput(String text, {required bool allowZero}) {
  final count = int.tryParse(text);
  if (count == null || count < 0 || (!allowZero && count == 0)) {
    return t.downloads.invalidEpisodeCount;
  }
  return null;
}

/// Dialog option for the download picker. Typed to avoid stringly-typed values.
enum _DownloadChoice { all, unwatched, next5, next10, customUnwatched, customAny, delete }

/// Whether the user chose a one-time download or a persistent sync rule.
enum _SyncChoice { downloadOnce, keepSynced }

enum SyncRuleRemovalResult { ruleOnly, ruleAndDownloads }

String syncRuleRemovalMessage(SyncRuleRemovalResult result) => result == SyncRuleRemovalResult.ruleAndDownloads
    ? t.downloads.syncRuleAndDownloadsRemoved
    : t.downloads.syncRuleRemoved;

/// Result of the download dialog + queue operation.
class DownloadResult {
  final int count;
  final bool syncRuleCreated;
  final bool syncRuleUpdated;

  /// `true` when the rule targets a collection/playlist — affects the
  /// "created" snackbar wording (no "unwatched episodes" suffix).
  final bool isListRule;

  /// `true` when the queued leaves are tracks (album/artist/track download)
  /// — picks "tracks queued" over "episodes queued" wording.
  final bool isMusic;

  const DownloadResult({
    required this.count,
    this.syncRuleCreated = false,
    this.syncRuleUpdated = false,
    this.isListRule = false,
    this.isMusic = false,
  });

  String toSnackBarMessage() {
    if (syncRuleUpdated) return t.downloads.syncRuleUpdated;
    if (syncRuleCreated) {
      return isListRule ? t.downloads.syncRuleListCreated : t.downloads.syncRuleCreated(count: count.toString());
    }
    if (count > 1) return isMusic ? t.downloads.tracksQueued(count: count) : t.downloads.episodesQueued(count: count);
    return t.downloads.downloadQueued;
  }
}

/// Shows download options dialog for shows/seasons, then queues the download.
/// For movies/episodes, queues directly without a dialog.
/// Returns a [DownloadResult], or null if cancelled.
///
/// When [onDelete] is provided (i.e. the item already has downloads), a
/// "Delete download" row is appended to the show/season options dialog so the
/// completed-download button can double as a "download more / delete" menu.
/// Selecting it runs [onDelete] and returns null.
Future<DownloadResult?> showDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem metadata,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
  Future<void> Function()? onDelete,
}) async {
  if (!await confirmBackgroundDownloadRestrictions(context) || !context.mounted) return null;

  final kind = metadata.kind;

  var filter = DownloadFilter.all;
  int? maxCount;
  bool keepSynced = false;
  bool randomEpisodes = false;
  // Remembered "Include Specials" choice; the toggle is only shown for whole
  // shows (a single season has no Specials to drop).
  final settings = SettingsService.instanceOrNull;
  bool includeSpecials = settings?.read(SettingsService.downloadIncludeSpecials) ?? true;

  if (kind == MediaKind.show || kind == MediaKind.season) {
    int? customCount;
    final options = <({IconData? icon, String label, _DownloadChoice value})>[
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: _DownloadChoice.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: _DownloadChoice.unwatched),
      (icon: Symbols.filter_5_rounded, label: t.downloads.nextNUnwatched(count: 5), value: _DownloadChoice.next5),
      (
        icon: Symbols.filter_9_plus_rounded,
        label: t.downloads.nextNUnwatched(count: 10),
        value: _DownloadChoice.next10,
      ),
      (icon: Symbols.tune_rounded, label: t.downloads.customAmount, value: _DownloadChoice.customUnwatched),
      (icon: Symbols.tune_rounded, label: t.downloads.customAmountAny, value: _DownloadChoice.customAny),
    ];
    // Already-downloaded show/season: offer deletion as the last row.
    if (onDelete != null) {
      options.add((icon: Symbols.delete_rounded, label: t.downloads.deleteDownload, value: _DownloadChoice.delete));
    }
    final selected = await showOptionPickerDialog<_DownloadChoice>(
      context,
      title: t.downloads.downloadNow,
      options: options,
      toggles: [
        // Specials only exist across a whole show; a single season has none to drop.
        if (kind == MediaKind.show)
          (
            label: t.downloads.includeSpecials,
            icon: Symbols.star_rounded,
            value: includeSpecials,
            onChanged: (value) => includeSpecials = value,
          ),
        (
          label: t.downloads.randomEpisodes,
          icon: Symbols.shuffle_rounded,
          value: randomEpisodes,
          onChanged: (value) => randomEpisodes = value,
        ),
      ],
      onBeforeClose: (value) async {
        if (value != _DownloadChoice.customUnwatched && value != _DownloadChoice.customAny) return value;
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
      case _DownloadChoice.customUnwatched:
        filter = DownloadFilter.unwatched;
        maxCount = customCount;
      case _DownloadChoice.customAny:
        filter = DownloadFilter.all;
        maxCount = customCount;
      case _DownloadChoice.delete:
        if (onDelete != null) await onDelete();
        return null;
    }

    // Keep-synced is offered for every choice except "All episodes" (which has
    // no quota to maintain), and only for shows.
    if (selected != _DownloadChoice.all && kind == MediaKind.show && context.mounted) {
      final syncChoice = await _showSyncChoiceDialog(context);
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
    final syncCount = maxCount ?? 0; // 0 means "all candidates" for the rule
    final filterString = filter == DownloadFilter.all ? SyncRuleFilter.all : SyncRuleFilter.unwatched;
    final ruleKey = downloadProvider.syncRuleKeyFor(ServerId(metadata.serverId ?? client.serverId), metadata.id);
    syncRuleUpdated = downloadProvider.hasSyncRule(ruleKey);

    await downloadProvider.createSyncRule(
      serverId: ServerId(metadata.serverId ?? client.serverId),
      ratingKey: metadata.id,
      targetType: metadata.kind.id.isNotEmpty ? metadata.kind.id : ContentTypes.show,
      episodeCount: syncCount,
      mediaIndex: versionConfig.mediaIndex,
      downloadFilter: filterString,
      randomEpisodes: randomEpisodes,
      includeSpecials: includeSpecials,
      targetMetadata: metadata,
    );
  }

  // Remember the toggle for next time (only shown, and thus meaningful, for shows).
  if (kind == MediaKind.show) {
    await settings?.write(SettingsService.downloadIncludeSpecials, includeSpecials);
  }

  final count = await downloadProvider.queueDownload(
    metadata,
    client,
    versionConfig: versionConfig,
    filter: filter,
    maxCount: maxCount,
    random: randomEpisodes,
    includeSpecials: includeSpecials,
  );

  return DownloadResult(
    count: count,
    syncRuleCreated: keepSynced && !syncRuleUpdated,
    syncRuleUpdated: syncRuleUpdated,
    isMusic: kind.isMusic,
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

  if (!await confirmBackgroundDownloadRestrictions(context) || !context.mounted) return null;

  final selectedFilter = await showOptionPickerDialog<DownloadFilter>(
    context,
    title: t.downloads.downloadNow,
    options: _filterOptions(DownloadFilter.all, DownloadFilter.unwatched),
  );

  if (selectedFilter == null || !context.mounted) return null;

  final syncChoice = await _showSyncChoiceDialog(context);
  if (syncChoice == null || !context.mounted) return null;

  final serverId = rootMetadata.serverId ?? client.serverId;
  final filterString = selectedFilter == DownloadFilter.unwatched ? SyncRuleFilter.unwatched : SyncRuleFilter.all;

  bool syncRuleCreated = false;
  bool syncRuleUpdated = false;
  SyncRuleItem? syncRule;

  if (syncChoice == _SyncChoice.keepSynced) {
    final ruleKey = downloadProvider.syncRuleKeyFor(ServerId(serverId), rootMetadata.id);
    if (downloadProvider.hasSyncRule(ruleKey)) {
      await downloadProvider.updateSyncRuleFilter(ruleKey, filterString);
      syncRuleUpdated = true;
    } else {
      await downloadProvider.createSyncRule(
        serverId: ServerId(serverId),
        ratingKey: rootMetadata.id,
        targetType: targetType,
        episodeCount: 0,
        mediaIndex: 0,
        downloadFilter: filterString,
        targetMetadata: rootMetadata,
      );
      syncRuleCreated = true;
    }
    syncRule = downloadProvider.getSyncRule(ruleKey);
  }

  final count = await downloadProvider.queueListDownload(items, client, filter: selectedFilter, syncRule: syncRule);

  return DownloadResult(
    count: count,
    syncRuleCreated: syncRuleCreated,
    syncRuleUpdated: syncRuleUpdated,
    isListRule: true,
  );
}

/// The all/unwatched option rows, shared by the pickers that differ only in
/// how they spell those two values.
List<({IconData? icon, String label, T value})> _filterOptions<T>(T all, T unwatched) => [
  (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: all),
  (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: unwatched),
];

/// Asks whether to download once or keep the target synced.
Future<_SyncChoice?> _showSyncChoiceDialog(BuildContext context) => showOptionPickerDialog<_SyncChoice>(
  context,
  title: t.downloads.downloadNow,
  options: [
    (icon: Symbols.download_rounded, label: t.downloads.downloadOnce, value: _SyncChoice.downloadOnce),
    (icon: Symbols.sync_rounded, label: t.downloads.keepSynced, value: _SyncChoice.keepSynced),
  ],
);

Future<int?> _showEpisodeCountDialog(
  BuildContext context, {
  String? title,
  String? hintText,
  bool allowZero = false,
}) async {
  final result = await showTextInputDialog(
    context,
    title: title ?? t.downloads.howManyEpisodes,
    labelText: '',
    hintText: hintText ?? '',
    confirmText: t.common.ok,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (text) => validateEpisodeCountInput(text, allowZero: allowZero),
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
  String? displayTitle,
}) async {
  final count = await _showEpisodeCountDialog(
    context,
    title: t.downloads.editEpisodeCount,
    hintText: currentCount.toString(),
    allowZero: true,
  );
  if (count == null || !context.mounted) return false;

  if (count == 0) {
    final removed = await confirmAndRemoveSyncRule(
      context,
      downloadProvider: downloadProvider,
      globalKey: globalKey,
      displayTitle: displayTitle ?? globalKey,
    );
    if (removed != null && context.mounted) {
      showSuccessSnackBar(context, syncRuleRemovalMessage(removed));
    }
    return false;
  }

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
    options: _filterOptions(SyncRuleFilter.all, SyncRuleFilter.unwatched),
  );
  if (selected == null || selected == currentFilter || !context.mounted) return false;

  await downloadProvider.updateSyncRuleFilter(globalKey, selected);
  return true;
}

/// Shows a confirmation dialog to remove a sync rule.
Future<SyncRuleRemovalResult?> confirmAndRemoveSyncRule(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required String displayTitle,
}) async {
  final rule = downloadProvider.getSyncRule(globalKey);
  if (rule == null) return null;

  final bool deleteDownloads;
  if (rule.isListRule) {
    final choice = await _showListSyncRuleRemovalDialog(context, displayTitle);
    if (choice == null || !context.mounted) return null;
    deleteDownloads = choice;
  } else {
    final confirmed = await showConfirmDialog(
      context,
      title: t.downloads.removeSyncRule,
      message: t.downloads.removeSyncRuleConfirm(title: displayTitle),
      confirmText: t.downloads.removeSyncRule,
    );
    if (!confirmed || !context.mounted) return null;
    deleteDownloads = false;
  }

  try {
    if (deleteDownloads) {
      final serverManager = context.read<MultiServerProvider>().serverManager;
      await downloadProvider.deleteSyncRuleAndDownloads(globalKey, serverManager);
      return SyncRuleRemovalResult.ruleAndDownloads;
    }
    await downloadProvider.deleteSyncRule(globalKey);
    return SyncRuleRemovalResult.ruleOnly;
  } on SyncRuleCleanupBusyException {
    if (context.mounted) showErrorSnackBar(context, t.downloads.syncRuleCleanupBusy);
    return null;
  } on SyncRuleCleanupUnavailableException {
    if (context.mounted) showErrorSnackBar(context, t.downloads.syncRuleCleanupUnavailable);
    return null;
  } catch (error, stackTrace) {
    appLogger.e('Failed to remove sync rule', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      showErrorSnackBar(context, t.messages.errorLoading(error: error.toString()));
    }
    return null;
  }
}

Future<bool?> _showListSyncRuleRemovalDialog(BuildContext context, String displayTitle) {
  var deleteDownloads = false;
  return showScopedDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text(t.downloads.removeSyncRule),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.downloads.removeListSyncRuleConfirm(title: displayTitle)),
                const SizedBox(height: 12),
                FocusableSwitchListTile(
                  key: const ValueKey('delete_sync_rule_downloads'),
                  value: deleteDownloads,
                  onChanged: (value) => setState(() => deleteDownloads = value),
                  title: Text(t.downloads.deleteSyncRuleDownloads),
                  subtitle: Text(t.downloads.deleteSyncRuleDownloadsDescription),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              DialogActionButton(
                autofocus: true,
                onPressed: () => Navigator.pop(dialogContext),
                label: t.common.cancel,
              ),
              DialogActionButton(
                onPressed: () => Navigator.pop(dialogContext, deleteDownloads),
                label: t.downloads.removeSyncRule,
                isPrimary: true,
                style: deleteDownloads
                    ? FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError)
                    : null,
              ),
            ],
          );
        },
      );
    },
  );
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
  String? displayTitle,
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
      displayTitle: displayTitle ?? rule.ratingKey,
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
  if (removed != null && context.mounted) {
    showSuccessSnackBar(context, syncRuleRemovalMessage(removed));
  }
}

/// The download / manage-sync-rule app-bar pair shared by the collection and
/// playlist detail screens: one entry that downloads (or edits the existing
/// rule) and, when a rule exists, one that removes it. Both are hidden on
/// Apple TV, which has no downloads UI.
///
/// [hasRule] stays caller-computed so each screen keeps its own
/// `context.select` short-circuit, and [showDownload] carries the screen's
/// own visibility predicate for the first entry.
List<FocusableAction> buildSyncRuleActions(
  BuildContext context, {
  required String ruleKey,
  required String displayTitle,
  required bool hasRule,
  required bool showDownload,
  required VoidCallback onDownload,
}) {
  if (PlatformDetector.isAppleTV()) return const [];
  return [
    if (showDownload)
      FocusableAction(
        icon: hasRule ? Symbols.sync_rounded : Symbols.download_rounded,
        tooltip: hasRule ? t.downloads.manageSyncRule : t.downloads.downloadNow,
        onPressed: hasRule
            ? () => manageSyncRule(context, downloadProvider: context.read<DownloadProvider>(), globalKey: ruleKey)
            : onDownload,
        iconColor: hasRule ? Colors.teal : null,
      ),
    if (hasRule)
      FocusableAction(
        icon: Symbols.sync_disabled_rounded,
        tooltip: t.downloads.removeSyncRule,
        onPressed: () => removeSyncRuleAndSnack(
          context,
          downloadProvider: context.read<DownloadProvider>(),
          globalKey: ruleKey,
          displayTitle: displayTitle,
        ),
      ),
  ];
}
