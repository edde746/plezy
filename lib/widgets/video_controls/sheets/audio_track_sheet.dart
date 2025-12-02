import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import 'track_selection_sheet.dart';

/// Bottom sheet for selecting audio tracks
class AudioTrackSheet {
  static void show(
    BuildContext context,
    MpvPlayer player, {
    Function(MpvAudioTrack)? onTrackChanged,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    TrackSelectionSheet.show<MpvAudioTrack>(
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
        if (audioTrack.channelsCount != null) {
          parts.add('${audioTrack.channelsCount}ch');
        }
        return parts.isEmpty ? 'Audio Track ${index + 1}' : parts.join(' · ');
      },
      setTrack: (track) => player.selectAudioTrack(track),
      onTrackChanged: onTrackChanged,
      onOpen: onOpen,
      onClose: onClose,
    );
  }
}
