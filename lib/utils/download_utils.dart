import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../database/app_database.dart';
import '../providers/download_provider.dart';
import '../services/sync_rule_executor.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_list_tile.dart';
import 'content_utils.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';
import 'focus_utils.dart';
import 'snackbar_helper.dart';

/// Dialog option for the download picker. Typed to avoid stringly-typed values.
///
/// [custom] is a count of unwatched episodes; [customAll] is a count drawn from
/// every episode (watched and unwatched).
enum _DownloadChoice { all, unwatched, next5, next10, custom, customAll }

/// Whether the user chose a one-time download or a persistent sync rule.
enum _SyncChoice { downloadOnce, keepSynced }

/// What the show/season download dialog returns: the picked option, whether the
/// "random selection" toggle was on, whether the download is restricted to the
/// currently-viewed season, and (for the custom options) the entered count.
typedef _DownloadOptionsResult = ({_DownloadChoice choice, bool random, bool onlySeason, int? customCount});

/// Result of the download dialog + queue operation.
class DownloadResult {
  final int count;
  final bool syncRuleCreated;
  final bool syncRuleUpdated;

  /// `true` when the rule targets a collection/playlist — affects the
  /// "created" snackbar wording (no "unwatched episodes" suffix).
  final bool isListRule;

  /// `true` when the show/season rule is filter=all (the "Custom amount" row)
  /// — the snackbar drops the "unwatched" qualifier since the rule counts
  /// every episode, watched or not.
  final bool isFilterAllRule;

  const DownloadResult({
    required this.count,
    this.syncRuleCreated = false,
    this.syncRuleUpdated = false,
    this.isListRule = false,
    this.isFilterAllRule = false,
  });

  String toSnackBarMessage() {
    if (syncRuleUpdated) return t.downloads.syncRuleUpdated;
    if (syncRuleCreated) {
      if (isListRule) return t.downloads.syncRuleListCreated;
      if (isFilterAllRule) return t.downloads.syncRuleAllCreated(count: count.toString());
      return t.downloads.syncRuleCreated(count: count.toString());
    }
    if (count > 1) return t.downloads.episodesQueued(count: count);
    return t.downloads.downloadQueued;
  }
}

/// Shows download options dialog for shows/seasons, then queues the download.
/// For movies/episodes, queues directly without a dialog.
/// Returns a [DownloadResult], or null if cancelled.
/// [currentSeason] is the season currently being viewed on a show detail
/// screen, when one is resolvable. Passing it surfaces the season-restrict
/// toggle; when that toggle is on, the season — not the show — becomes the
/// effective download/sync target.
Future<DownloadResult?> showDownloadOptionsAndQueue(
  BuildContext context, {
  required MediaItem metadata,
  required MediaServerClient client,
  required DownloadProvider downloadProvider,
  MediaItem? currentSeason,
}) async {
  final kind = metadata.kind;

  var filter = DownloadFilter.all;
  int? maxCount;
  bool keepSynced = false;
  bool random = false;
  // The thing we actually download from. Defaults to the viewed item; the
  // season-restrict toggle swaps in the selected season below.
  MediaItem target = metadata;

  if (kind == MediaKind.show || kind == MediaKind.season) {
    final selected = await _showDownloadOptionsDialog(context, currentSeason: currentSeason);

    if (selected == null || !context.mounted) return null;

    random = selected.random;
    if (selected.onlySeason && currentSeason != null) {
      target = currentSeason;
    }
    // Whether to offer the Download once / Keep synced step. Every option
    // except the two uncapped ones (All episodes / Unwatched only without a
    // cap) — wait, "Unwatched only" *does* qualify because it pairs naturally
    // with a rolling unwatched window. Only the uncapped "All episodes" row
    // is left as one-time, by deliberate product choice.
    bool offerSync = false;
    switch (selected.choice) {
      case _DownloadChoice.all:
        break;
      case _DownloadChoice.unwatched:
        filter = DownloadFilter.unwatched;
        offerSync = true;
      case _DownloadChoice.next5:
        filter = DownloadFilter.unwatched;
        maxCount = 5;
        offerSync = true;
      case _DownloadChoice.next10:
        filter = DownloadFilter.unwatched;
        maxCount = 10;
        offerSync = true;
      case _DownloadChoice.custom:
        filter = DownloadFilter.unwatched;
        maxCount = selected.customCount;
        offerSync = true;
      case _DownloadChoice.customAll:
        filter = DownloadFilter.all;
        maxCount = selected.customCount;
        offerSync = true;
    }

    // Keep-synced applies to show/season episode containers. The rule remembers
    // the filter (unwatched-window vs total-N), so the executor knows whether
    // to count watched episodes toward the cap.
    final targetIsEpisodeContainer = target.kind == MediaKind.show || target.kind == MediaKind.season;
    if (offerSync && targetIsEpisodeContainer && context.mounted) {
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

  final versionConfig = await resolveDownloadVersion(context, target, client);
  if (versionConfig == null || !context.mounted) return null;

  // Create or update sync rule before queueing (so the rule exists even if queue fails)
  bool syncRuleUpdated = false;
  if (keepSynced) {
    final syncCount = maxCount ?? 0; // 0 means "all unwatched" for the rule
    final ruleKey = downloadProvider.syncRuleKeyFor(target.serverId ?? client.serverId, target.id);
    syncRuleUpdated = downloadProvider.hasSyncRule(ruleKey);

    await downloadProvider.createSyncRule(
      serverId: target.serverId ?? client.serverId,
      ratingKey: target.id,
      targetType: target.kind.id.isNotEmpty ? target.kind.id : ContentTypes.show,
      episodeCount: syncCount,
      mediaIndex: versionConfig.mediaIndex,
      downloadFilter: filter == DownloadFilter.unwatched ? SyncRuleFilter.unwatched : SyncRuleFilter.all,
      random: random,
      targetMetadata: target,
    );
  }

  final count = await downloadProvider.queueDownload(
    target,
    client,
    versionConfig: versionConfig,
    filter: filter,
    maxCount: maxCount,
    random: random,
  );

  return DownloadResult(
    count: count,
    syncRuleCreated: keepSynced && !syncRuleUpdated,
    syncRuleUpdated: syncRuleUpdated,
    isFilterAllRule: filter == DownloadFilter.all,
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

/// Shows the show/season download options menu: a "random selection" toggle, an
/// optional "only this season" toggle, and the scope choices. Returns null if
/// dismissed (or if the custom count sub-prompt is cancelled). Bespoke (rather
/// than [showOptionPickerDialog]) because it needs persistent toggles, per-row
/// dimming, and a compound result.
Future<_DownloadOptionsResult?> _showDownloadOptionsDialog(BuildContext context, {MediaItem? currentSeason}) {
  final focusFirstItem = InputModeTracker.isKeyboardMode(context);
  return showDialog<_DownloadOptionsResult>(
    context: context,
    builder: (context) => _DownloadOptionsDialog(focusFirstItem: focusFirstItem, currentSeason: currentSeason),
  );
}

/// Test-only handle to the show/season download options dialog so its toggles
/// and row-dimming behaviour can be widget-tested without the full queue flow.
@visibleForTesting
Widget debugDownloadOptionsDialog({bool focusFirstItem = false, MediaItem? currentSeason}) =>
    _DownloadOptionsDialog(focusFirstItem: focusFirstItem, currentSeason: currentSeason);

/// Display label for the season-restrict toggle, e.g. "Season 3".
String _seasonLabel(MediaItem season) => season.title ?? 'Season ${season.index ?? ''}'.trim();

class _DownloadOptionsDialog extends StatefulWidget {
  final bool focusFirstItem;

  /// When non-null, a season-restrict toggle is shown and its state is returned
  /// as `onlySeason`.
  final MediaItem? currentSeason;

  const _DownloadOptionsDialog({this.focusFirstItem = false, this.currentSeason});

  @override
  State<_DownloadOptionsDialog> createState() => _DownloadOptionsDialogState();
}

class _DownloadOptionsDialogState extends State<_DownloadOptionsDialog> {
  bool _random = false;
  bool _onlySeason = false;
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'DownloadOptionsInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  /// "Random" only changes which episodes a capped pick downloads, so the
  /// uncapped scopes are disabled while it's on.
  bool _isEnabled(_DownloadChoice choice) {
    if (!_random) return true;
    return choice != _DownloadChoice.all && choice != _DownloadChoice.unwatched;
  }

  Future<void> _select(_DownloadChoice choice) async {
    int? customCount;
    if (choice == _DownloadChoice.custom || choice == _DownloadChoice.customAll) {
      customCount = await _showEpisodeCountDialog(context);
      // Cancelled the count prompt — keep the options dialog open.
      if (customCount == null) return;
    }
    if (!mounted) return;
    Navigator.pop(context, (choice: choice, random: _random, onlySeason: _onlySeason, customCount: customCount));
  }

  @override
  Widget build(BuildContext context) {
    final options = <({IconData icon, String label, _DownloadChoice value})>[
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: _DownloadChoice.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: _DownloadChoice.unwatched),
      (icon: Symbols.filter_5_rounded, label: t.downloads.nextNUnwatched(count: 5), value: _DownloadChoice.next5),
      (icon: Symbols.filter_9_plus_rounded, label: t.downloads.nextNUnwatched(count: 10), value: _DownloadChoice.next10),
      (icon: Symbols.tune_rounded, label: t.downloads.customAmountUnwatched, value: _DownloadChoice.custom),
      (icon: Symbols.tune_rounded, label: t.downloads.customAmount, value: _DownloadChoice.customAll),
    ];

    final season = widget.currentSeason;

    return SimpleDialog(
      title: Text(t.downloads.downloadNow),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        FocusableSwitchListTile(
          value: _random,
          onChanged: (value) => setState(() => _random = value),
          secondary: const AppIcon(Symbols.shuffle_rounded, fill: 1, size: 24),
          title: Text(t.downloads.randomSelection),
          subtitle: Text(t.downloads.randomSelectionDescription),
        ),
        if (season != null)
          FocusableSwitchListTile(
            value: _onlySeason,
            onChanged: (value) => setState(() => _onlySeason = value),
            secondary: const AppIcon(Symbols.tv_rounded, fill: 1, size: 24),
            title: Text(t.downloads.downloadOnlyFromSeason(season: _seasonLabel(season))),
            subtitle: Text(t.downloads.downloadOnlyFromSeasonDescription),
          ),
        const Divider(height: 8),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final enabled = _isEnabled(option.value);
          return FocusableListTile(
            focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
            enabled: enabled,
            leading: AppIcon(option.icon, fill: 1, size: 24),
            title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            onTap: enabled ? () => _select(option.value) : null,
          );
        }),
      ],
    );
  }
}

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
    validator: (text) {
      final n = int.tryParse(text);
      if (n == null || n < 0 || (!allowZero && n == 0)) return '';
      return null;
    },
  );
  if (result == null) return null;
  return int.tryParse(result);
}

/// Shows a dialog to edit a sync rule's episode count and random flag. Entering
/// 0 removes the rule (after confirmation). Returns true if updated.
Future<bool> editSyncRuleCount(
  BuildContext context, {
  required DownloadProvider downloadProvider,
  required String globalKey,
  required int currentCount,
  required bool currentRandom,
  String? displayTitle,
}) async {
  final result = await showCountWithToggleDialog(
    context,
    title: t.downloads.editEpisodeCount,
    initialCount: currentCount,
    initialToggle: currentRandom,
    toggleTitle: t.downloads.randomSelection,
    toggleSubtitle: t.downloads.randomSelectionDescription,
    hintText: currentCount.toString(),
    allowZero: true,
  );
  if (result == null || !context.mounted) return false;

  if (result.count == 0) {
    final removed = await confirmAndRemoveSyncRule(
      context,
      downloadProvider: downloadProvider,
      globalKey: globalKey,
      displayTitle: displayTitle ?? globalKey,
    );
    if (removed && context.mounted) {
      showSuccessSnackBar(context, t.downloads.syncRuleRemoved);
    }
    return false;
  }

  await downloadProvider.updateSyncRuleCount(globalKey, result.count);
  if (result.toggle != currentRandom) {
    await downloadProvider.updateSyncRuleRandom(globalKey, result.toggle);
  }
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
      currentRandom: rule.random,
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
  if (removed && context.mounted) {
    showSuccessSnackBar(context, t.downloads.syncRuleRemoved);
  }
}
