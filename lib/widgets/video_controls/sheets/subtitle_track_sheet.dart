import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../i18n/strings.g.dart';

/// Bottom sheet for selecting subtitle tracks
class SubtitleTrackSheet extends StatelessWidget {
  final Player player;

  const SubtitleTrackSheet({super.key, required this.player});

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
      builder: (context) => SubtitleTrackSheet(player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final subtitles = (tracks?.subtitle ?? [])
            .where((track) => track.id != 'auto' && track.id != 'no')
            .toList();

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.subtitles, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        t.videoControls.subtitlesLabel,
                        style: const TextStyle(
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
                if (subtitles.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No subtitles available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: StreamBuilder<Track>(
                      stream: player.stream.track,
                      initialData: player.state.track,
                      builder: (context, selectedSnapshot) {
                        // Use snapshot data or fall back to current state
                        final currentTrack =
                            selectedSnapshot.data ?? player.state.track;
                        final selectedTrack = currentTrack.subtitle;
                        final selectedId = selectedTrack.id;
                        final isOffSelected = selectedId == 'no';

                        return ListView.builder(
                          itemCount:
                              subtitles.length + 1, // +1 for "Off" option
                          itemBuilder: (context, index) {
                            // First item is "Off"
                            if (index == 0) {
                              return ListTile(
                                title: Text(
                                  'Off',
                                  style: TextStyle(
                                    color: isOffSelected
                                        ? Colors.blue
                                        : Colors.white,
                                  ),
                                ),
                                trailing: isOffSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  player.setSubtitleTrack(SubtitleTrack.no());
                                  Navigator.pop(context);
                                },
                              );
                            }

                            // Subsequent items are subtitle tracks
                            final subtitle = subtitles[index - 1];
                            final isSelected = subtitle.id == selectedId;

                            // Build label with available info
                            final parts = <String>[];
                            if (subtitle.title != null &&
                                subtitle.title!.isNotEmpty) {
                              parts.add(subtitle.title!);
                            }
                            if (subtitle.language != null &&
                                subtitle.language!.isNotEmpty) {
                              parts.add(subtitle.language!.toUpperCase());
                            }
                            if (subtitle.codec != null &&
                                subtitle.codec!.isNotEmpty) {
                              // Format codec names nicely
                              String codecName = subtitle.codec!.toUpperCase();
                              if (codecName == 'SUBRIP') {
                                codecName = 'SRT';
                              } else if (codecName == 'DVD_SUBTITLE') {
                                codecName = 'DVD';
                              } else if (codecName == 'ASS' ||
                                  codecName == 'SSA') {
                                codecName = codecName; // Keep as-is
                              } else if (codecName == 'WEBVTT') {
                                codecName = 'VTT';
                              }
                              parts.add(codecName);
                            }

                            final label = parts.isEmpty
                                ? 'Track $index'
                                : parts.join(' · ');

                            return ListTile(
                              title: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.white,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                player.setSubtitleTrack(subtitle);
                                Navigator.pop(context);
                              },
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
