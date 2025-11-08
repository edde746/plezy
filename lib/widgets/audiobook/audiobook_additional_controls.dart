import 'package:flutter/material.dart';
import '../../services/sleep_timer_service.dart';

/// Additional controls for audiobook player (speed, sleep timer, chapters)
class AudiobookAdditionalControls extends StatelessWidget {
  final double playbackSpeed;
  final VoidCallback onSpeedPressed;
  final VoidCallback onSleepTimerPressed;
  final VoidCallback onChaptersPressed;

  const AudiobookAdditionalControls({
    super.key,
    required this.playbackSpeed,
    required this.onSpeedPressed,
    required this.onSleepTimerPressed,
    required this.onChaptersPressed,
  });

  @override
  Widget build(BuildContext context) {
    final sleepTimer = SleepTimerService();
    final isSleepTimerActive = sleepTimer.isActive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Playback speed
        _buildControlButton(
          label: '${playbackSpeed}x',
          onPressed: onSpeedPressed,
        ),

        // Sleep timer
        _buildControlButton(
          icon: isSleepTimerActive ? Icons.bedtime : Icons.bedtime_outlined,
          label: isSleepTimerActive ? 'Active' : 'Sleep',
          onPressed: onSleepTimerPressed,
        ),

        // Chapters
        _buildControlButton(
          icon: Icons.list,
          label: 'Chapters',
          onPressed: onChaptersPressed,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    IconData? icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}
