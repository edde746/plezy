import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/track_label_builder.dart';
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
      icon: Symbols.subtitles_rounded,
      extractTracks: (tracks) => tracks?.subtitle ?? [],
      getCurrentTrack: (track) => track.subtitle,
      buildLabel: (subtitle, index) => TrackLabelBuilder.buildSubtitleLabel(
        title: subtitle.title,
        language: subtitle.language,
        codec: subtitle.codec,
        index: index,
      ),
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
