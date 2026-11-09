import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_merge.dart';
import '../media/media_item_types.dart';
import '../services/continue_watching_copy_resolver.dart';
import '../utils/focus_utils.dart';
import '../utils/formatters.dart';
import '../utils/media_server_http_client.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'focusable_list_tile.dart';

/// A scoped lookup that can be canceled without starting late playback.
class ContinueWatchingCopyDialog extends StatefulWidget {
  const ContinueWatchingCopyDialog({super.key, required this.resolve});

  final Future<ContinueWatchingCopyLookup> Function(AbortController abort) resolve;

  @override
  State<ContinueWatchingCopyDialog> createState() => _ContinueWatchingCopyDialogState();
}

class _ContinueWatchingCopyDialogState extends State<ContinueWatchingCopyDialog> {
  final _firstChoiceFocus = FocusNode();
  AbortController? _abort;
  ContinueWatchingCopyLookup? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final abort = _abort = AbortController();
    ContinueWatchingCopyLookup result;
    try {
      result = await widget.resolve(abort);
    } catch (_) {
      if (!mounted || abort.isAborted) return;
      result = (copies: const [], isComplete: false);
    }
    if (!mounted || abort.isAborted) return;
    setState(() => _result = result);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || abort.isAborted) return;
      if (result.copies.isNotEmpty && InputModeTracker.isKeyboardMode(context, listen: false)) {
        FocusUtils.requestFocusAfterBuild(this, _firstChoiceFocus);
      }
    });
  }

  @override
  void dispose() {
    _abort?.abort();
    _firstChoiceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final copies = result?.copies ?? const <MediaItem>[];
    final showEpisode = copies.map((copy) => (copy.parentIndex, copy.index)).toSet().length > 1;
    final theme = Theme.of(context);
    final serverGroups = <String?, List<MediaItem>>{};
    for (final copy in copies) {
      (serverGroups[copy.serverId] ??= []).add(copy);
    }
    String label(MediaItem copy) => [
      if (showEpisode && copy.isEpisode) ?formatSeasonEpisodeLabel(copy.parentIndex, copy.index),
      copy.libraryTitle ?? t.common.unknown,
    ].join(' • ');

    Widget copyTile(MediaItem copy) {
      final quality = libraryCopyQualityLabel(copy);
      return FocusableListTile(
        key: ValueKey(copy.globalKey),
        focusNode: identical(copy, copies.first) ? _firstChoiceFocus : null,
        title: Text(label(copy)),
        subtitle: quality == null ? null : Text(quality),
        onTap: () => Navigator.pop(context, copy),
      );
    }

    return AlertDialog(
      title: Text(t.mediaMenu.chooseLibraryCopy),
      content: SizedBox(
        width: 420,
        child: result == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(key: Key('continue-watching-copy-loading')),
                  const SizedBox(height: 16),
                  Text(t.common.loading),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (copies.isEmpty && result.isComplete) Text(t.messages.noItemsAvailable),
                    if (!result.isComplete)
                      Padding(padding: const EdgeInsets.all(12), child: Text(t.messages.searchPartialResults)),
                    for (final group in serverGroups.values) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, identical(group, serverGroups.values.first) ? 4 : 16, 12, 4),
                        child: Semantics(
                          header: true,
                          child: Row(
                            children: [
                              AppIcon(Symbols.dns_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  group.first.serverName ?? group.first.serverId ?? t.common.unknown,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final copy in group) copyTile(copy),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        if (result != null && !result.isComplete)
          DialogActionButton(
            label: t.common.retry,
            onPressed: () {
              setState(() => _result = null);
              unawaited(_load());
            },
          ),
        DialogActionButton(
          label: t.common.cancel,
          autofocus: true,
          onPressed: () {
            _abort?.abort();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
