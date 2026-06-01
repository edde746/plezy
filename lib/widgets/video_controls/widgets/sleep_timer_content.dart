import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../mpv/mpv.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/formatters.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import '../sheets/sheet_column_header.dart';
import 'sleep_timer_active_status.dart';

/// Shared UI for sleep timer selection and active status.
///
/// Layout mirrors the audio/subtitle [TrackSheet]: two side-by-side columns
/// inside a [Row], each in its own [FocusTraversalGroup] so D-pad navigation
/// stays inside the column the user is acting on.
///
///   * Left column ("Stop at") — event-based stop options. Today this is just
///     "End of current video"; the column is intentionally open-ended for
///     future event triggers (end of next episode, end of chapter, …).
///   * Right column ("Timer") — fixed-duration options (5/10/15/30/45/60/90/120
///     minutes, plus an optional default duration injected from settings).
class SleepTimerContent extends StatelessWidget {
  final Player player;
  final SleepTimerService sleepTimer;
  final int? defaultDuration;
  final VoidCallback? onCancel;

  const SleepTimerContent({
    super.key,
    required this.player,
    required this.sleepTimer,
    this.defaultDuration,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sleepTimer,
      builder: (context, _) {
        final remainingTime = sleepTimer.remainingTime;
        // Active status renders either with a countdown (duration timer) or
        // without (end-of-video mode). Both share the same widget.
        final showActiveStatus = sleepTimer.isActive && (remainingTime != null || sleepTimer.isEndOfVideoMode);

        return Column(
          children: [
            if (showActiveStatus) ...[
              SleepTimerActiveStatus(sleepTimer: sleepTimer, remainingTime: remainingTime, onCancel: onCancel),
              Divider(color: Theme.of(context).dividerColor, height: 1),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  Expanded(
                    child: FocusTraversalGroup(
                      child: _SleepTimerEventColumn(player: player, sleepTimer: sleepTimer),
                    ),
                  ),
                  VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                  Expanded(
                    child: FocusTraversalGroup(
                      child: _SleepTimerDurationColumn(
                        player: player,
                        sleepTimer: sleepTimer,
                        defaultDuration: defaultDuration,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SleepTimerEventColumn extends StatelessWidget {
  final Player player;
  final SleepTimerService sleepTimer;

  const _SleepTimerEventColumn({required this.player, required this.sleepTimer});

  @override
  Widget build(BuildContext context) {
    final label = t.videoControls.sleepTimerEndOfVideo;

    return Column(
      children: [
        SheetColumnHeader(label: t.videoControls.sleepTimerStopAtHeader),
        Expanded(
          child: ListView(
            children: [
              FocusableListTile(
                leading: AppIcon(
                  Symbols.hourglass_bottom_rounded,
                  fill: 1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(label),
                selected: sleepTimer.isEndOfVideoMode,
                onTap: () {
                  sleepTimer.armEndOfVideo(() {
                    // Pause playback when the current video ends
                    player.pause();
                  });
                  OverlaySheetController.closeAdaptive(context);

                  showSuccessSnackBar(context, t.messages.sleepTimerSet(label: label));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SleepTimerDurationColumn extends StatelessWidget {
  final Player player;
  final SleepTimerService sleepTimer;
  final int? defaultDuration;

  const _SleepTimerDurationColumn({required this.player, required this.sleepTimer, this.defaultDuration});

  @override
  Widget build(BuildContext context) {
    final durations = [5, 10, 15, 30, 45, 60, 90, 120];
    // Add default duration if provided and not already in list
    if (defaultDuration != null && !durations.contains(defaultDuration)) {
      durations.add(defaultDuration!);
      durations.sort();
    }

    // Highlight the currently running duration timer (end-of-video mode is
    // handled by the event column and intentionally does not light up here).
    final activeMinutes = sleepTimer.isActive && !sleepTimer.isEndOfVideoMode
        ? sleepTimer.originalDuration?.inMinutes
        : null;

    return Column(
      children: [
        SheetColumnHeader(label: t.videoControls.sleepTimerDurationHeader),
        Expanded(
          child: ListView.builder(
            itemCount: durations.length,
            itemBuilder: (context, index) {
              final minutes = durations[index];
              final label = formatDurationTextual(
                minutes * 60 * 1000, // Convert minutes to milliseconds
                abbreviated: false, // Use full format for better readability
              );

              return FocusableListTile(
                leading: AppIcon(Symbols.timer_rounded, fill: 1, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text(label),
                selected: minutes == activeMinutes,
                onTap: () {
                  sleepTimer.startTimer(Duration(minutes: minutes), () {
                    // Pause playback when timer completes
                    player.pause();
                  });
                  OverlaySheetController.closeAdaptive(context);

                  // Show confirmation snackbar
                  showSuccessSnackBar(context, t.messages.sleepTimerSet(label: label));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
