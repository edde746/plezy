import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../services/sleep_timer_service.dart';
import 'sleep_timer_active_status.dart';
import 'sleep_timer_duration_list.dart';

/// Shared UI for sleep timer selection and active status.
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
              child: SleepTimerDurationList(player: player, sleepTimer: sleepTimer, defaultDuration: defaultDuration),
            ),
          ],
        );
      },
    );
  }
}
