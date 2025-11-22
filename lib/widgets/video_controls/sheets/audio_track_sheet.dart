import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../i18n/strings.g.dart';
import 'track_selection_sheet.dart';

/// Bottom sheet for selecting audio tracks
class AudioTrackSheet {
  static void show(
    BuildContext context,
    Player player, {
    Function(AudioTrack)? onTrackChanged,
  }) {
    TrackSelectionSheet.show<AudioTrack>(
      context: context,
      player: player,
      title: t.videoControls.audioLabel,
      icon: Icons.audiotrack,
      extractTracks: (tracks) => tracks?.audio ?? [],
      getCurrentTrack: (track) => track.audio,
      buildLabel: (audioTrack, index) {
        final parts = <String>[];
        if (audioTrack.title != null && audioTrack.title!.isNotEmpty) {
          parts.add(audioTrack.title!);
        }
        if (audioTrack.language != null && audioTrack.language!.isNotEmpty) {
          parts.add(audioTrack.language!.toUpperCase());
        }
        if (audioTrack.codec != null && audioTrack.codec!.isNotEmpty) {
          parts.add(audioTrack.codec!.toUpperCase());
        }
        if (audioTrack.channelscount != null) {
          parts.add('${audioTrack.channelscount}ch');
        }
        return parts.isEmpty ? 'Audio Track ${index + 1}' : parts.join(' · ');
      },
      setTrack: (track) => player.setAudioTrack(track),
      onTrackChanged: onTrackChanged,
    );
  }
}
