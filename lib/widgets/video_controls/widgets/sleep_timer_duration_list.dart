import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/duration_formatter.dart';
import '../../../i18n/strings.g.dart';

/// Widget displaying list of sleep timer durations for selection
class SleepTimerDurationList extends StatelessWidget {
  final Player player;
  final SleepTimerService sleepTimer;
  final int? defaultDuration;

  const SleepTimerDurationList({
    super.key,
    required this.player,
    required this.sleepTimer,
    this.defaultDuration,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [5, 10, 15, 30, 45, 60, 90, 120];
    // Add default duration if provided and not already in list
    if (defaultDuration != null && !durations.contains(defaultDuration)) {
      durations.add(defaultDuration!);
      durations.sort();
    }

    return ListView.builder(
      itemCount: durations.length,
      itemBuilder: (context, index) {
        final minutes = durations[index];
        final label = formatDurationTextual(
          minutes * 60 * 1000, // Convert minutes to milliseconds
          abbreviated: false, // Use full format for better readability
        );

        return ListTile(
          leading: const Icon(Icons.timer, color: Colors.white70),
          title: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
          onTap: () {
            sleepTimer.startTimer(Duration(minutes: minutes), () {
              // Pause playback when timer completes
              player.pause();

              // Show a snackbar notification
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.videoControls.sleepTimerCompleted),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
            Navigator.pop(context);

            // Show confirmation snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.messages.sleepTimerSet(label: label)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
