import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/music/repeat_mode.dart';
import '../../widgets/music/track_row.dart';
import '../../widgets/overlay_sheet.dart';

/// Open the play-queue sheet. The caller's screen must have an
/// [OverlaySheetHost] ancestor (all now-playing layouts do) so TV back
/// handling stays centralized in the host.
Future<void> showQueueSheet(BuildContext context) {
  return OverlaySheetController.of(context).show<void>(showDragHandle: true, builder: (_) => const QueueSheet());
}

/// Sheet chrome around [QueueList]: header with track count, shuffle/repeat
/// toggles mirroring the service state, and Clear (upcoming) action.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final service = context.watch<MusicPlaybackService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: .min,
      children: [
        BottomSheetHeader(
          title: t.music.queue,
          action: Row(
            mainAxisSize: .min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  t.music.trackCount(n: service.queue.length),
                  style: TextStyle(fontSize: 13, color: tk.textMuted),
                ),
              ),
              FocusableActionBar(
                actions: [
                  FocusableAction(
                    icon: Symbols.shuffle_rounded,
                    iconColor: service.shuffled ? colorScheme.primary : tk.textMuted,
                    iconSize: 20,
                    tooltip: t.common.shuffle,
                    onPressed: service.toggleShuffle,
                  ),
                  FocusableAction(
                    icon: repeatModeIcon(service.repeatMode),
                    iconColor: service.repeatMode == MusicRepeatMode.off ? tk.textMuted : colorScheme.primary,
                    iconSize: 20,
                    tooltip: repeatModeLabel(service.repeatMode),
                    onPressed: () => service.setRepeatMode(nextRepeatMode(service.repeatMode)),
                  ),
                  FocusableAction(
                    icon: Symbols.clear_all_rounded,
                    iconColor: tk.textMuted,
                    iconSize: 20,
                    tooltip: t.music.clearQueue,
                    onPressed: service.clearUpcoming,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Flexible(child: QueueList(autofocusCurrent: true)),
      ],
    );
  }
}

/// The queue body: the full play queue in playback order — history, the
/// current track (equalizer row, dimmed rows above are already played),
/// then upcoming — YouTube-Music style. Opens scrolled so the current track
/// sits at the top, and follows track changes while the user is near the
/// playback position. Reused verbatim by the desktop now-playing layout as
/// an inline panel.
///
/// Touch: long-press drag to reorder (delayed drag listener — TrackRow's
/// context menu is disabled here so the gesture arena stays clean), swipe to
/// remove, tap to jump. D-pad: rows are focusable, SELECT jumps, RIGHT
/// reaches a dedicated remove button; reordering is intentionally not
/// offered on TV. With [autofocusCurrent] (the sheet) initial focus lands on
/// the current track's row instead of the first history row.
class QueueList extends StatefulWidget {
  /// Land initial d-pad/keyboard focus on the current track's row,
  /// overriding the overlay host's focus-first-descendant default. The
  /// inline desktop panel keeps this off so building the now-playing screen
  /// never steals focus.
  final bool autofocusCurrent;

  const QueueList({super.key, this.autofocusCurrent = false});

  @override
  State<QueueList> createState() => _QueueListState();
}

class _QueueListState extends State<QueueList> {
  ScrollController? _scrollController;
  final _currentRowFocusNode = FocusNode(debugLabel: 'QueueCurrentRowFocus');
  int _lastCurrentIndex = -1;

  /// Content offset that puts the row at [index] at the top of the viewport
  /// (its top gap scrolled away, the list's own padding still visible).
  /// Rows are fixed-extent, so this is exact — the shared
  /// measure-the-first-item scroll helper can't be used because only the
  /// first row lacks a leading gap.
  double _rowOffset(int index, double gap) => index * (TrackRow.height + gap);

  @override
  void initState() {
    super.initState();
    if (widget.autofocusCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Timer.run(() {
          if (!mounted || !InputModeTracker.isKeyboardMode(context, listen: false)) return;
          // Schedule after the overlay host's _autoFocus second callback so
          // we override its focus-first-descendant default.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_currentRowFocusNode.context != null) _currentRowFocusNode.requestFocus();
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _currentRowFocusNode.dispose();
    super.dispose();
  }

  /// Keep the current track at the top while playback advances, but only
  /// when the list is still parked where the previous track was anchored —
  /// once the user scrolls away to browse, moving rows under their pointer
  /// invites mis-taps on remove/jump.
  void _followCurrentTrack(int currentIndex, double gap) {
    if (currentIndex == _lastCurrentIndex) return;
    final fromIndex = _lastCurrentIndex;
    _lastCurrentIndex = currentIndex;
    // First build: the initial scroll offset already targets the row.
    if (fromIndex < 0 || currentIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _scrollController;
      if (!mounted || controller == null || !controller.hasClients) return;
      final position = controller.position;
      final anchor = _rowOffset(fromIndex, gap).clamp(0.0, position.maxScrollExtent);
      if ((anchor - position.pixels).abs() > (TrackRow.height + gap) * 1.5) return;
      final target = _rowOffset(currentIndex, gap).clamp(0.0, position.maxScrollExtent);
      unawaited(controller.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final service = context.watch<MusicPlaybackService>();
    final queue = service.queue;
    final currentIndex = service.currentIndex;

    if (queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Text(t.messages.noItemsAvailable, style: TextStyle(fontSize: 13, color: tk.textMuted)),
      );
    }

    _scrollController ??= ScrollController(initialScrollOffset: _rowOffset(currentIndex, tk.groupGap));
    _followCurrentTrack(currentIndex, tk.groupGap);

    // Stable per-item keys that survive reorders; the same track can appear
    // more than once, so disambiguate repeats by occurrence.
    final seen = <String, int>{};
    final itemKeys = [
      for (final item in queue) '${item.globalKey}#${seen.update(item.globalKey, (v) => v + 1, ifAbsent: () => 0)}',
    ];

    final allowTouchEditing = !PlatformDetector.isTV();

    return ReorderableListView.builder(
      scrollController: _scrollController,
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.all(12),
      itemCount: queue.length,
      // onReorderItem already adjusts newIndex for the removal.
      onReorderItem: (oldIndex, newIndex) {
        if (oldIndex == newIndex) return;
        service.reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = queue[index];
        final isCurrent = index == currentIndex;

        Widget row = TrackRow(
          item: item,
          showArtist: true,
          isFirst: index == 0,
          isLast: index == queue.length - 1,
          enableContextMenu: false,
          isCurrent: isCurrent,
          dimmed: index < currentIndex,
          showTrackNumber: false,
          focusNode: isCurrent ? _currentRowFocusNode : null,
          trailingIcon: Symbols.close_rounded,
          onTrailingTap: () => service.removeAt(index),
          onTap: () => unawaited(service.jumpTo(index)),
        );

        if (allowTouchEditing) {
          row = ReorderableDelayedDragStartListener(index: index, child: row);
          row = Dismissible(
            key: ValueKey('dismiss:${itemKeys[index]}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: .centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const AppIcon(Symbols.delete_rounded, fill: 1, color: Colors.white, size: 20),
            ),
            onDismissed: (_) => service.removeAt(index),
            child: row,
          );
        }

        return Padding(
          key: ValueKey(itemKeys[index]),
          padding: EdgeInsets.only(top: index == 0 ? 0 : tk.groupGap),
          child: row,
        );
      },
    );
  }
}
