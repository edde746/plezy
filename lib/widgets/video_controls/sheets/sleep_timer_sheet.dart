import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/settings_service.dart';
import '../../../services/sleep_timer_service.dart';
import 'base_video_control_sheet.dart';
import '../widgets/sleep_timer_content.dart';

/// Bottom sheet for sleep timer configuration
class SleepTimerSheet extends StatelessWidget {
  final Player player;
  final int defaultDuration;

  const SleepTimerSheet({
    super.key,
    required this.player,
    required this.defaultDuration,
  });

  static void show(BuildContext context, Player player) async {
    final settingsService = await SettingsService.getInstance();
    final defaultDuration = settingsService.getSleepTimerDuration();

    if (!context.mounted) return;

    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) =>
          SleepTimerSheet(player: player, defaultDuration: defaultDuration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sleepTimer = SleepTimerService();

    return ListenableBuilder(
      listenable: sleepTimer,
      builder: (context, _) {
        return BaseVideoControlSheet(
          title: t.videoControls.sleepTimer,
          icon: sleepTimer.isActive ? Icons.bedtime : Icons.bedtime_outlined,
          iconColor: sleepTimer.isActive ? Colors.amber : null,
          child: SleepTimerContent(
            player: player,
            sleepTimer: sleepTimer,
            defaultDuration: defaultDuration,
            onCancel: () => Navigator.pop(context),
          ),
        );
      },
    );
  }
}
