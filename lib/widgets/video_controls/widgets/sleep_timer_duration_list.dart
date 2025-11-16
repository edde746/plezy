import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../services/sleep_timer_service.dart';
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

  String _formatLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    }
    final hours = minutes / 60;
    final isWholeHour = minutes % 60 == 0;
    return '${hours.toStringAsFixed(isWholeHour ? 0 : 1)} ${minutes == 60 ? 'hour' : 'hours'}';
  }

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
        final label = _formatLabel(minutes);

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
                  const SnackBar(
                    content: Text(
                      'Sleep timer completed - playback paused',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
            Navigator.pop(context);

            // Show confirmation snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.messages.sleepTimerSet(label: label),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
