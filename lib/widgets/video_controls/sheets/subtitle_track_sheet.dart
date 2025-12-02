import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import 'track_selection_sheet.dart';

/// Bottom sheet for selecting subtitle tracks
class SubtitleTrackSheet {
  static void show(
    BuildContext context,
    Player player, {
    Function(SubtitleTrack)? onTrackChanged,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    TrackSelectionSheet.show<SubtitleTrack>(
      context: context,
      player: player,
      title: t.videoControls.subtitlesLabel,
      icon: Icons.subtitles,
      extractTracks: (tracks) => tracks?.subtitle ?? [],
      getCurrentTrack: (track) => track.subtitle,
      buildLabel: (subtitle, index) {
        final parts = <String>[];
        if (subtitle.title != null && subtitle.title!.isNotEmpty) {
          parts.add(subtitle.title!);
        }
        if (subtitle.language != null && subtitle.language!.isNotEmpty) {
          parts.add(subtitle.language!.toUpperCase());
        }
        if (subtitle.codec != null && subtitle.codec!.isNotEmpty) {
          // Format codec names nicely
          String codecName = subtitle.codec!.toUpperCase();
          if (codecName == 'SUBRIP') {
            codecName = 'SRT';
          } else if (codecName == 'DVD_SUBTITLE') {
            codecName = 'DVD';
          } else if (codecName == 'ASS' || codecName == 'SSA') {
            codecName = codecName; // Keep as-is
          } else if (codecName == 'WEBVTT') {
            codecName = 'VTT';
          }
          parts.add(codecName);
        }
        return parts.isEmpty ? 'Track ${index + 1}' : parts.join(' · ');
      },
      setTrack: (track) => player.selectSubtitleTrack(track),
      onTrackChanged: onTrackChanged,
      showOffOption: true,
      createOffTrack: () => SubtitleTrack.off,
      isOffTrack: (track) => track.id == 'no',
      onOpen: onOpen,
      onClose: onClose,
    );
  }
}
