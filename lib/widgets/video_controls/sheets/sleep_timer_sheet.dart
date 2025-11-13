import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../services/settings_service.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../i18n/strings.g.dart';

/// Bottom sheet for sleep timer configuration
class SleepTimerSheet extends StatelessWidget {
  final Player player;
  final int defaultDuration;

  const SleepTimerSheet({
    super.key,
    required this.player,
    required this.defaultDuration,
  });

  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  static void show(BuildContext context, Player player) async {
    final settingsService = await SettingsService.getInstance();
    final defaultDuration = settingsService.getSleepTimerDuration();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
      builder: (context) =>
          SleepTimerSheet(player: player, defaultDuration: defaultDuration),
    );
  }

  String _formatSleepTimerDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepTimer = SleepTimerService();

    return ListenableBuilder(
      listenable: sleepTimer,
      builder: (context, _) {
        final durations = [5, 10, 15, 30, 45, 60, 90, 120];
        // Add default duration if not in list
        if (!durations.contains(defaultDuration)) {
          durations.add(defaultDuration);
          durations.sort();
        }
        final remainingTime = sleepTimer.remainingTime;

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        sleepTimer.isActive
                            ? Icons.bedtime
                            : Icons.bedtime_outlined,
                        color: sleepTimer.isActive
                            ? Colors.amber
                            : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sleep Timer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // Show current timer status if active
                if (sleepTimer.isActive && remainingTime != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.amber.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        const Text(
                          'Timer Active',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Playback will pause in ${_formatSleepTimerDuration(remainingTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                t.videoControls.addTime(
                                  amount: "15",
                                  unit: " min",
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              onPressed: () {
                                sleepTimer.extendTimer(
                                  const Duration(minutes: 15),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.cancel),
                              label: Text(t.common.cancel),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                sleepTimer.cancelTimer();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                ],

                // Duration selection list
                Expanded(
                  child: ListView.builder(
                    itemCount: durations.length,
                    itemBuilder: (context, index) {
                      final minutes = durations[index];
                      final label = minutes < 60
                          ? '$minutes minutes'
                          : '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} ${minutes == 60 ? 'hour' : 'hours'}';

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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
