import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/track_label_builder.dart';
import 'track_selection_sheet.dart';

/// Bottom sheet for selecting audio tracks
class AudioTrackSheet {
  static void show(
    BuildContext context,
    Player player, {
    Function(AudioTrack)? onTrackChanged,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    TrackSelectionSheet.show<AudioTrack>(
      context: context,
      player: player,
      title: t.videoControls.audioLabel,
      icon: Symbols.audiotrack_rounded,
      extractTracks: (tracks) => tracks?.audio ?? [],
      getCurrentTrack: (track) => track.audio,
      buildLabel: (audioTrack, index) => TrackLabelBuilder.buildAudioLabel(
        title: audioTrack.title,
        language: audioTrack.language,
        codec: audioTrack.codec,
        channelsCount: audioTrack.channelsCount,
        index: index,
      ),
      setTrack: (track) => player.selectAudioTrack(track),
      onTrackChanged: onTrackChanged,
      onOpen: onOpen,
      onClose: onClose,
    );
  }
}
