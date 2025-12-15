import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/formatters.dart';

/// Widget displaying active sleep timer status with extend/cancel actions
class SleepTimerActiveStatus extends StatelessWidget {
  final SleepTimerService sleepTimer;
  final Duration remainingTime;
  final VoidCallback? onCancel;

  const SleepTimerActiveStatus({super.key, required this.sleepTimer, required this.remainingTime, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.amber.withValues(alpha: 0.1),
      child: Column(
        children: [
          Text(
            t.videoControls.timerActive,
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            t.videoControls.playbackWillPauseIn(duration: formatDurationWithSeconds(remainingTime)),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const AppIcon(Symbols.add_rounded, fill: 1),
                label: Text(t.videoControls.addTime(amount: "15", unit: " min")),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () {
                  sleepTimer.extendTimer(const Duration(minutes: 15));
                },
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const AppIcon(Symbols.cancel_rounded, fill: 1),
                label: Text(t.common.cancel),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  sleepTimer.cancelTimer();
                  onCancel?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
