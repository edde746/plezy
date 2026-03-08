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
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;

  const TrackSheet({
    super.key,
    required this.player,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSecondarySubtitleTrackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, tracksSnapshot) {
        final tracks = tracksSnapshot.data;
        final audioTracks = TrackFilterHelper.extractAndFilterTracks<AudioTrack>(tracks, (t) => t?.audio ?? []);
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

              final supportsSecondary = player.supportsSecondarySubtitles;

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
                          onSecondaryTrackChanged: onSecondarySubtitleTrackChanged,
                          supportsSecondary: supportsSecondary,
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
                onSecondaryTrackChanged: onSecondarySubtitleTrackChanged,
                supportsSecondary: supportsSecondary,
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
                context: context,
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
  final Function(SubtitleTrack)? onSecondaryTrackChanged;
  final bool supportsSecondary;
  final bool showHeader;

  const _SubtitleColumn({
    required this.tracks,
    required this.selection,
    required this.player,
    this.onTrackChanged,
    this.onSecondaryTrackChanged,
    this.supportsSecondary = false,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSub = selection.subtitle;
    final secondarySub = selection.secondarySubtitle;
    final isOffSelected = selectedSub == null || selectedSub.id == 'no';
    final hasSecondary = supportsSecondary && secondarySub != null;

    // +1 for "Off" row
    final itemCount = tracks.length + 1;

    return Column(
      children: [
        if (showHeader) _ColumnHeader(label: t.videoControls.subtitlesLabel),
        Expanded(
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // "Off" row
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  context: context,
                  isSelected: isOffSelected,
                  onTap: () {
                    // Turning off primary also clears secondary
                    if (hasSecondary) {
                      player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                      onSecondaryTrackChanged?.call(SubtitleTrack.off);
                    }
                    player.selectSubtitleTrack(SubtitleTrack.off);
                    onTrackChanged?.call(SubtitleTrack.off);
                    OverlaySheetController.of(context).close();
                  },
                  onLongPress: supportsSecondary && hasSecondary
                      ? () {
                          player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                  onSecondaryTap: supportsSecondary && hasSecondary
                      ? () {
                          player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                );
              }

              final track = tracks[index - 1];
              final isPrimary = !isOffSelected && track.id == selectedSub.id;
              final isSecondary = hasSecondary && track.id == secondarySub.id;
              final label = TrackLabelBuilder.buildSubtitleLabel(
                title: track.title,
                language: track.language,
                codec: track.codec,
                index: index - 1,
              );

              // Determine badge
              Widget? badge;
              if (supportsSecondary && hasSecondary) {
                if (isPrimary) {
                  badge = TrackSelectionHelper.buildTrackBadge(context, 1);
                } else if (isSecondary) {
                  badge = TrackSelectionHelper.buildTrackBadge(context, 2);
                }
              }

              return TrackSelectionHelper.buildTrackTile<SubtitleTrack>(
                context: context,
                label: label,
                isSelected: isPrimary,
                badge: badge,
                onTap: () {
                  // If tapping a track that is currently the secondary, clear secondary first
                  if (isSecondary) {
                    player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    onSecondaryTrackChanged?.call(SubtitleTrack.off);
                  }
                  player.selectSubtitleTrack(track);
                  onTrackChanged?.call(track);
                  OverlaySheetController.of(context).close();
                },
                onLongPress: supportsSecondary
                    ? () {
                        if (isSecondary) {
                          // Already secondary — clear it
                          player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          // Set as secondary (don't close sheet so user sees badge update)
                          player.selectSecondarySubtitleTrack(track);
                          onSecondaryTrackChanged?.call(track);
                        }
                      }
                    : null,
                onSecondaryTap: supportsSecondary
                    ? () {
                        if (isSecondary) {
                          player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          player.selectSecondarySubtitleTrack(track);
                          onSecondaryTrackChanged?.call(track);
                        }
                      }
                    : null,
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
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
