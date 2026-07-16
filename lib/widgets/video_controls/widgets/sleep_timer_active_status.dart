import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../focus/focusable_button.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/formatters.dart';

/// Widget displaying active sleep timer status with extend/cancel actions.
///
/// Supports two modes:
///   * Timed (default) — [remainingTime] is non-null; shows countdown and the
///     "+15 min" extend button.
///   * End-of-video — [remainingTime] is null; shows a static message and only
///     the cancel button (extending makes no sense here).
class SleepTimerActiveStatus extends StatelessWidget {
  final SleepTimerService sleepTimer;
  final Duration? remainingTime;
  final VoidCallback? onCancel;

  const SleepTimerActiveStatus({super.key, required this.sleepTimer, this.remainingTime, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isEndOfVideo = remainingTime == null;
    final subtitle = isEndOfVideo
        ? t.videoControls.playbackWillPauseAtEnd
        : t.videoControls.playbackWillPauseIn(duration: formatDurationWithSeconds(remainingTime!));

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.amber.withValues(alpha: 0.1),
      child: Column(
        children: [
          Text(
            t.videoControls.timerActive,
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: .bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: .center,
            children: [
              if (!isEndOfVideo) ...[
                FocusableButton(
                  onPressed: () {
                    sleepTimer.extendTimer(const Duration(minutes: 15));
                  },
                  child: OutlinedButton.icon(
                    icon: const AppIcon(Symbols.add_rounded, fill: 1),
                    label: Text(t.videoControls.addTime(amount: "15", unit: " min")),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    onPressed: () {
                      sleepTimer.extendTimer(const Duration(minutes: 15));
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              FocusableButton(
                onPressed: () {
                  sleepTimer.cancelTimer();
                  onCancel?.call();
                },
                useBackgroundFocus: true,
                child: FilledButton.icon(
                  icon: const AppIcon(Symbols.cancel_rounded, fill: 1),
                  label: Text(t.common.cancel),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    sleepTimer.cancelTimer();
                    onCancel?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
