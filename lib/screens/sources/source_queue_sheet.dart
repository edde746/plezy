import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_action_bar.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../services/music/music_playback_service.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/music/repeat_mode.dart';
import '../../widgets/overlay_sheet.dart';
import 'source_widgets.dart';

Future<void> showSourceQueueSheet(BuildContext context, SourcePlayback playback) {
  return OverlaySheetController.showAdaptive<void>(
    context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SourceQueueSheet(playback: playback),
  );
}

/// Browses a direct local or network queue inside the shared adaptive sheet.
class SourceQueueSheet extends StatelessWidget {
  const SourceQueueSheet({super.key, required this.playback});

  final SourcePlayback playback;

  String _fileLabel(PublicationFile file) {
    final value = file.name.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasAuthority && uri.host.isNotEmpty) {
      final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      return isolateDisplayText(lastSegment.isEmpty ? uri.host : lastSegment);
    }
    return isolateDisplayText(value.replaceAll('\\', '/').split('/').last);
  }

  void _select(BuildContext context, int fileIndex) {
    final overlay = OverlaySheetController.maybeOf(context);
    if (overlay != null) {
      overlay.close();
    } else {
      Navigator.of(context).pop();
    }
    if (fileIndex != playback.fileIndex) unawaited(playback.selectQueueFile(fileIndex));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tk = tokens(context);

    return AnimatedBuilder(
      animation: playback,
      builder: (context, _) {
        final queue = playback.queueFileIndices;
        final current = playback.fileIndex;
        final trackCountLabel = t.music.trackCount(n: queue.length);
        final compactTrackCount = MediaQuery.textScalerOf(context).scale(13) > 20;
        final trackCountText = Text(
          compactTrackCount ? formatCount(queue.length) : trackCountLabel,
          style: TextStyle(fontSize: 13, color: tk.textMuted),
        );
        return BottomSheetPageScaffold(
          title: t.music.queue,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: compactTrackCount
                    ? Semantics(
                        label: trackCountLabel,
                        child: ExcludeSemantics(child: trackCountText),
                      )
                    : trackCountText,
              ),
              FocusableActionBar(
                actions: [
                  FocusableAction(
                    icon: Symbols.shuffle_rounded,
                    iconColor: playback.queueShuffled ? theme.colorScheme.primary : tk.textMuted,
                    iconSize: 20,
                    tooltip: t.common.shuffle,
                    isSelected: playback.queueShuffled,
                    onPressed: playback.canUseDirectQueueControls
                        ? () => unawaited(playback.toggleQueueShuffle())
                        : null,
                  ),
                  FocusableAction(
                    icon: repeatModeIcon(playback.queueRepeatMode),
                    iconColor: playback.queueRepeatMode == MusicRepeatMode.off
                        ? tk.textMuted
                        : theme.colorScheme.primary,
                    iconSize: 20,
                    tooltip: repeatModeLabel(playback.queueRepeatMode),
                    isSelected: playback.queueRepeatMode != MusicRepeatMode.off,
                    onPressed: playback.canUseDirectQueueControls
                        ? () => unawaited(playback.setQueueRepeatMode(nextRepeatMode(playback.queueRepeatMode)))
                        : null,
                  ),
                ],
              ),
            ],
          ),
          child: queue.isEmpty
              ? Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
                  child: Text(t.messages.noItemsAvailable, style: TextStyle(fontSize: 13, color: tk.textMuted)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final fileIndex = queue[index];
                    final file = playback.files[fileIndex];
                    final isCurrent = fileIndex == current;
                    return Semantics(
                      selected: isCurrent,
                      child: SourceTile(
                        key: ValueKey('source-queue-$fileIndex'),
                        title: _fileLabel(file),
                        subtitle: isCurrent ? t.music.nowPlaying : null,
                        leading: AppIcon(
                          isCurrent
                              ? Symbols.equalizer_rounded
                              : playback.video
                              ? Symbols.movie_rounded
                              : Symbols.music_note_rounded,
                          color: isCurrent ? theme.colorScheme.primary : null,
                          size: 26,
                        ),
                        onTap: () => _select(context, fileIndex),
                        index: index,
                        count: queue.length,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
