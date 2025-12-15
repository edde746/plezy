import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/formatters.dart';
import '../../../utils/snackbar_helper.dart';
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
          leading: const AppIcon(
            Symbols.timer_rounded,
            fill: 1,
            color: Colors.white70,
          ),
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
                showSuccessSnackBar(context, t.videoControls.sleepTimerCompleted);
              }
            });
            Navigator.pop(context);

            // Show confirmation snackbar
            showSuccessSnackBar(context, t.messages.sleepTimerSet(label: label));
          },
        );
      },
    );
  }
}
