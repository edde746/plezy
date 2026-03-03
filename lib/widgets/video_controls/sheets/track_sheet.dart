import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/track_label_builder.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import '../helpers/track_filter_helper.dart';
import '../helpers/track_selection_helper.dart';

/// Combined bottom sheet for selecting audio and subtitle tracks side-by-side.
class TrackSheet extends StatelessWidget {
  final Player player;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;

  const TrackSheet({
    super.key,
    required this.player,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, tracksSnapshot) {
        final tracks = tracksSnapshot.data;
        final audioTracks = TrackFilterHelper.extractAndFilterTracks<AudioTrack>(
          tracks,
          (t) => t?.audio ?? [],
        );
        final subtitleTracks = TrackFilterHelper.extractAndFilterTracks<SubtitleTrack>(
          tracks,
          (t) => t?.subtitle ?? [],
        );

        final showAudio = audioTracks.length > 1;
        final showSubtitles = subtitleTracks.isNotEmpty;

        // Determine title/icon based on what's shown
        final String title;
        final IconData icon;
        if (showAudio && showSubtitles) {
          title = t.videoControls.tracksButton;
          icon = Symbols.subtitles_rounded;
        } else if (showAudio) {
          title = t.videoControls.audioLabel;
          icon = Symbols.audiotrack_rounded;
        } else {
          title = t.videoControls.subtitlesLabel;
          icon = Symbols.subtitles_rounded;
        }

        return BaseVideoControlSheet(
          title: title,
          icon: icon,
          child: StreamBuilder<TrackSelection>(
            stream: player.streams.track,
            initialData: player.state.track,
            builder: (context, selSnapshot) {
              final selection = selSnapshot.data ?? player.state.track;

              if (showAudio && showSubtitles) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FocusTraversalGroup(
                        child: _AudioColumn(
                          tracks: audioTracks,
                          selection: selection,
                          player: player,
                          onTrackChanged: onAudioTrackChanged,
                          showHeader: true,
                        ),
                      ),
                    ),
                    VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                    Expanded(
                      child: FocusTraversalGroup(
                        child: _SubtitleColumn(
                          tracks: subtitleTracks,
                          selection: selection,
                          player: player,
                          onTrackChanged: onSubtitleTrackChanged,
                          showHeader: true,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (showAudio) {
                return _AudioColumn(
                  tracks: audioTracks,
                  selection: selection,
                  player: player,
                  onTrackChanged: onAudioTrackChanged,
                  showHeader: false,
                );
              }

              return _SubtitleColumn(
                tracks: subtitleTracks,
                selection: selection,
                player: player,
                onTrackChanged: onSubtitleTrackChanged,
                showHeader: false,
              );
            },
          ),
        );
      },
    );
  }
}

class _AudioColumn extends StatelessWidget {
  final List<AudioTrack> tracks;
  final TrackSelection selection;
  final Player player;
  final Function(AudioTrack)? onTrackChanged;
  final bool showHeader;

  const _AudioColumn({
    required this.tracks,
    required this.selection,
    required this.player,
    this.onTrackChanged,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = selection.audio?.id ?? '';

    return Column(
      children: [
        if (showHeader) _ColumnHeader(label: t.videoControls.audioLabel),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final label = TrackLabelBuilder.buildAudioLabel(
                title: track.title,
                language: track.language,
                codec: track.codec,
                channelsCount: track.channelsCount,
                index: index,
              );
              return TrackSelectionHelper.buildTrackTile<AudioTrack>(
                label: label,
                isSelected: track.id == selectedId,
                onTap: () {
                  player.selectAudioTrack(track);
                  onTrackChanged?.call(track);
                  OverlaySheetController.of(context).close();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubtitleColumn extends StatelessWidget {
  final List<SubtitleTrack> tracks;
  final TrackSelection selection;
  final Player player;
  final Function(SubtitleTrack)? onTrackChanged;
  final bool showHeader;

  const _SubtitleColumn({
    required this.tracks,
    required this.selection,
    required this.player,
    this.onTrackChanged,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSub = selection.subtitle;
    final isOffSelected = selectedSub == null || selectedSub.id == 'no';

    return Column(
      children: [
        if (showHeader) _ColumnHeader(label: t.videoControls.subtitlesLabel),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length + 1, // +1 for "Off"
            itemBuilder: (context, index) {
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  isSelected: isOffSelected,
                  onTap: () {
                    player.selectSubtitleTrack(SubtitleTrack.off);
                    onTrackChanged?.call(SubtitleTrack.off);
                    OverlaySheetController.of(context).close();
                  },
                );
              }

              final track = tracks[index - 1];
              final label = TrackLabelBuilder.buildSubtitleLabel(
                title: track.title,
                language: track.language,
                codec: track.codec,
                index: index - 1,
              );
              return TrackSelectionHelper.buildTrackTile<SubtitleTrack>(
                label: label,
                isSelected: !isOffSelected && track.id == (selectedSub?.id ?? ''),
                onTap: () {
                  player.selectSubtitleTrack(track);
                  onTrackChanged?.call(track);
                  OverlaySheetController.of(context).close();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final String label;

  const _ColumnHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
