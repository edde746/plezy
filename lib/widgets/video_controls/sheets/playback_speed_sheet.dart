import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// Bottom sheet for selecting playback speed
class PlaybackSpeedSheet extends StatelessWidget {
  final Player player;

  const PlaybackSpeedSheet({super.key, required this.player});

  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  static void show(BuildContext context, Player player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
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

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Playback Speed',
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
                Expanded(
                  child: ListView.builder(
                    itemCount: speeds.length,
                    itemBuilder: (context, index) {
                      final speed = speeds[index];
                      final isSelected = (currentRate - speed).abs() < 0.01;

                      // Format speed label
                      final label = speed == 1.0
                          ? 'Normal'
                          : '${speed.toStringAsFixed(2)}x';

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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
