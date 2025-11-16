import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../i18n/strings.g.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for selecting audio tracks
class AudioTrackSheet extends StatelessWidget {
  final Player player;
  final Function(AudioTrack)? onTrackChanged;

  const AudioTrackSheet({super.key, required this.player, this.onTrackChanged});

  static void show(
    BuildContext context,
    Player player, {
    Function(AudioTrack)? onTrackChanged,
  }) {
    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) =>
          AudioTrackSheet(player: player, onTrackChanged: onTrackChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final audioTracks = (tracks?.audio ?? [])
            .where((track) => track.id != 'auto' && track.id != 'no')
            .toList();

        return BaseVideoControlSheet(
          title: t.videoControls.audioLabel,
          icon: Icons.audiotrack,
          child: audioTracks.isEmpty
              ? const Center(
                  child: Text(
                    'No audio tracks available',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : StreamBuilder<Track>(
                  stream: player.stream.track,
                  initialData: player.state.track,
                  builder: (context, selectedSnapshot) {
                    // Use snapshot data or fall back to current state
                    final currentTrack =
                        selectedSnapshot.data ?? player.state.track;
                    final selectedTrack = currentTrack.audio;
                    final selectedId = selectedTrack.id;

                    return ListView.builder(
                      itemCount: audioTracks.length,
                      itemBuilder: (context, index) {
                        final audioTrack = audioTracks[index];
                        final isSelected = audioTrack.id == selectedId;

                        final parts = <String>[];
                        if (audioTrack.title != null &&
                            audioTrack.title!.isNotEmpty) {
                          parts.add(audioTrack.title!);
                        }
                        if (audioTrack.language != null &&
                            audioTrack.language!.isNotEmpty) {
                          parts.add(audioTrack.language!.toUpperCase());
                        }
                        if (audioTrack.codec != null &&
                            audioTrack.codec!.isNotEmpty) {
                          parts.add(audioTrack.codec!.toUpperCase());
                        }
                        if (audioTrack.channelscount != null) {
                          parts.add('${audioTrack.channelscount}ch');
                        }

                        final label = parts.isEmpty
                            ? 'Audio Track ${index + 1}'
                            : parts.join(' · ');

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
                            player.setAudioTrack(audioTrack);
                            onTrackChanged?.call(audioTrack);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
