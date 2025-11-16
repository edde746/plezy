import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for selecting playback speed
class PlaybackSpeedSheet extends StatelessWidget {
  final Player player;

  const PlaybackSpeedSheet({super.key, required this.player});

  static void show(BuildContext context, Player player) {
    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) => PlaybackSpeedSheet(player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.stream.rate,
      initialData: player.state.rate,
      builder: (context, snapshot) {
        final currentRate = snapshot.data ?? 1.0;

        // Define available playback speeds
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0];

        return BaseVideoControlSheet(
          title: 'Playback Speed',
          icon: Icons.speed,
          child: ListView.builder(
            itemCount: speeds.length,
            itemBuilder: (context, index) {
              final speed = speeds[index];
              final isSelected = (currentRate - speed).abs() < 0.01;

              // Format speed label
              final label =
                  speed == 1.0 ? 'Normal' : '${speed.toStringAsFixed(2)}x';

              return ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  player.setRate(speed);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}
