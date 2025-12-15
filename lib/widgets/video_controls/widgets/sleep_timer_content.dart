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

        return Column(
          children: [
            if (sleepTimer.isActive && remainingTime != null) ...[
              SleepTimerActiveStatus(sleepTimer: sleepTimer, remainingTime: remainingTime, onCancel: onCancel),
              const Divider(color: Colors.white24, height: 1),
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
