import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../media/media_source_info.dart';
import '../../../mpv/mpv.dart';
import '../../../services/playback_subtitle_resolver.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/track_label_builder.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'sheet_selection_column.dart';
import 'subtitle_search_sheet.dart';
import '../models/track_controls_state.dart';
import '../helpers/track_filter_helper.dart';
import '../helpers/track_selection_helper.dart';

/// Combined bottom sheet for selecting audio and subtitle tracks side-by-side.
class TrackSheet extends StatelessWidget {
  final Player player;
  final TrackControlsState trackControlsState;

  const TrackSheet({super.key, required this.player, required this.trackControlsState});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, tracksSnapshot) {
        final tracks = tracksSnapshot.data;
        final playerAudioTracks = TrackFilterHelper.extractAndFilterTracks<AudioTrack>(tracks, (t) => t?.audio ?? []);
        final subtitleTracks = TrackFilterHelper.extractAndFilterTracks<SubtitleTrack>(
          tracks,
          (t) => t?.subtitle ?? [],
        );

        final state = trackControlsState;
        final hasExternalSourceAudio = state.sourceAudioTracks.any((track) => track.isExternal);
        final useSourceAudio =
            (state.isTranscoding || hasExternalSourceAudio) &&
            state.sourceAudioTracks.length > 1 &&
            state.onSwitchAudioStreamId != null;
        final useSourceSubtitles = state.canUseSourceSubtitles;
        final showAudio = useSourceAudio || playerAudioTracks.length > 1;
        final showSubtitles = state.hasSubtitleControls(tracks);

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

              Widget audioColumnFor(TrackSelection sel, bool showHeader) {
                if (useSourceAudio) {
                  return _SourceAudioColumn(
                    tracks: state.sourceAudioTracks,
                    selectedStreamId: state.selectedAudioStreamId,
                    onSelected: state.onSwitchAudioStreamId!,
                    showHeader: showHeader,
                  );
                }
                return _AudioColumn(
                  tracks: playerAudioTracks,
                  selection: sel,
                  player: player,
                  onTrackChanged: state.onAudioTrackChanged,
                  showHeader: showHeader,
                );
              }

              Widget subtitleColumnFor(TrackSelection sel, bool showHeader) {
                if (useSourceSubtitles) {
                  return _SourceSubtitleColumn(
                    tracks: state.sourceSubtitleTracks,
                    trackControlsState: state,
                    showHeader: showHeader,
                  );
                }
                return _SubtitleColumn(
                  tracks: subtitleTracks,
                  selection: sel,
                  player: player,
                  supportsSecondary: supportsSecondary,
                  showHeader: showHeader,
                  trackControlsState: state,
                  sourceSidecars: state.directPlaySourceSidecars,
                );
              }

              if (showAudio && showSubtitles) {
                return Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(child: FocusTraversalGroup(child: audioColumnFor(selection, true))),
                    VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                    Expanded(child: FocusTraversalGroup(child: subtitleColumnFor(selection, true))),
                  ],
                );
              }

              if (showAudio) {
                return audioColumnFor(selection, false);
              }

              return subtitleColumnFor(selection, false);
            },
          ),
        );
      },
    );
  }
}

class _SourceAudioColumn extends StatelessWidget {
  final List<MediaAudioTrack> tracks;
  final int? selectedStreamId;
  final Future<void> Function(int) onSelected;
  final bool showHeader;

  const _SourceAudioColumn({
    required this.tracks,
    required this.selectedStreamId,
    required this.onSelected,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = _effectiveSelectedStreamId();
    final selectedIndex = selectedId == null ? null : tracks.indexWhere((t) => t.id == selectedId);

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.audioLabel : null,
      itemCount: tracks.length,
      initialIndex: selectedIndex,
      itemBuilder: (context, index, scope) {
        final track = tracks[index];
        return TrackSelectionHelper.buildTrackTile(
          context: context,
          key: scope.keyFor(index),
          label: track.label,
          isSelected: track.id == selectedId,
          onTap: () => scope.runExclusive(() => onSelected(track.id)),
        );
      },
    );
  }

  int? _effectiveSelectedStreamId() {
    final explicit = selectedStreamId;
    if (explicit != null && tracks.any((track) => track.id == explicit)) return explicit;
    for (final track in tracks) {
      if (track.selected) return track.id;
    }
    return null;
  }
}

class _SourceSubtitleColumn extends StatelessWidget {
  final List<MediaSubtitleTrack> tracks;
  final TrackControlsState trackControlsState;
  final bool showHeader;

  const _SourceSubtitleColumn({required this.tracks, required this.trackControlsState, required this.showHeader});

  @override
  Widget build(BuildContext context) {
    final selectedChoice = _effectiveSelectedChoice();
    final selectedId = selectedChoice.sourceStreamId;
    final selectedIndex = selectedChoice.isOff ? 0 : tracks.indexWhere((t) => t.id == selectedId) + 1;

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.subtitlesLabel : null,
      itemCount: tracks.length + 1,
      initialIndex: selectedIndex,
      footer: _buildSubtitleSearchFooter(context, trackControlsState),
      itemBuilder: (context, index, scope) {
        if (index == 0) {
          return TrackSelectionHelper.buildOffTile(
            context: context,
            key: scope.keyFor(index),
            isSelected: selectedChoice.isOff,
            onTap: () => scope.runExclusive(
              () => trackControlsState.onSwitchSubtitle!(const PlaybackSourceSubtitleChoice.off()),
            ),
          );
        }

        final track = tracks[index - 1];
        return TrackSelectionHelper.buildTrackTile(
          context: context,
          label: track.labelForIndex(index - 1),
          isSelected: track.id == selectedId,
          onTap: () => scope.runExclusive(
            () => trackControlsState.onSwitchSubtitle!(PlaybackSourceSubtitleChoice.source(track.id)),
          ),
        );
      },
    );
  }

  PlaybackSourceSubtitleChoice _effectiveSelectedChoice() {
    final explicit = trackControlsState.selectedSubtitleChoice;
    if (explicit != null && (explicit.isOff || tracks.any((track) => track.id == explicit.sourceStreamId))) {
      return explicit;
    }
    for (final track in tracks) {
      if (track.selected) return PlaybackSourceSubtitleChoice.source(track.id);
    }
    return const PlaybackSourceSubtitleChoice.off();
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
    final selectedIndex = tracks.indexWhere((t) => t.id == selectedId);

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.audioLabel : null,
      itemCount: tracks.length,
      initialIndex: selectedIndex,
      itemBuilder: (context, index, scope) {
        final track = tracks[index];
        final label = TrackLabelBuilder.audioLabel(
          title: track.title,
          language: track.language,
          codec: track.codec,
          channels: track.channelsCount,
          index: index,
        );
        return TrackSelectionHelper.buildTrackTile(
          context: context,
          key: scope.keyFor(index),
          label: label,
          isSelected: track.id == selectedId,
          onTap: () {
            player.selectAudioTrack(track);
            onTrackChanged?.call(track);
            OverlaySheetController.of(context).close();
          },
        );
      },
    );
  }
}

class _SubtitleColumn extends StatelessWidget {
  final List<SubtitleTrack> tracks;
  final TrackSelection selection;
  final Player player;
  final bool supportsSecondary;
  final bool showHeader;
  final TrackControlsState trackControlsState;
  final List<MediaSubtitleTrack> sourceSidecars;

  const _SubtitleColumn({
    required this.tracks,
    required this.selection,
    required this.player,
    this.supportsSecondary = false,
    required this.showHeader,
    required this.trackControlsState,
    this.sourceSidecars = const [],
  });

  @override
  Widget build(BuildContext context) {
    final selectedSub = selection.subtitle;
    final secondarySub = selection.secondarySubtitle;
    final isOffSelected = selectedSub == null || selectedSub.id == 'no';
    final hasSecondary = supportsSecondary && secondarySub != null;
    final selectedSourceId = trackControlsState.selectedSubtitleChoice?.sourceStreamId;
    final selectedSecondarySourceId = trackControlsState.selectedSecondarySubtitleStreamId;
    final unloadedSourceSidecars = sourceSidecars
        .where((track) => track.id != selectedSourceId && track.id != selectedSecondarySourceId)
        .toList(growable: false);

    // +1 for "Off" row. The selected direct-play sidecar is already present
    // in [tracks], so only the other server sidecars are appended.
    final itemCount = tracks.length + unloadedSourceSidecars.length + 1;

    final selectedIndex = isOffSelected ? null : tracks.indexWhere((t) => t.id == selectedSub.id) + 1;

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.subtitlesLabel : null,
      itemCount: itemCount,
      initialIndex: selectedIndex,
      footer: _buildSubtitleSearchFooter(context, trackControlsState),
      itemBuilder: (context, index, scope) {
        if (index == 0) {
          return TrackSelectionHelper.buildOffTile(
            context: context,
            key: scope.keyFor(index),
            isSelected: isOffSelected,
            onTap: () {
              // Turning off primary also clears secondary
              if (hasSecondary) {
                player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
              }
              player.selectSubtitleTrack(SubtitleTrack.off);
              trackControlsState.onSubtitleTrackChanged?.call(SubtitleTrack.off);
              OverlaySheetController.of(context).close();
            },
            onLongPress: supportsSecondary && hasSecondary
                ? () {
                    player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                  }
                : null,
            onSecondaryTap: supportsSecondary && hasSecondary
                ? () {
                    player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                  }
                : null,
          );
        }

        final trackIndex = index - 1;
        if (trackIndex >= tracks.length) {
          final sourceIndex = trackIndex - tracks.length;
          final sourceTrack = unloadedSourceSidecars[sourceIndex];
          return TrackSelectionHelper.buildTrackTile(
            context: context,
            label: sourceTrack.labelForIndex(trackIndex),
            isSelected: false,
            onTap: () => scope.runExclusive(
              () => trackControlsState.onSwitchSubtitle!(PlaybackSourceSubtitleChoice.source(sourceTrack.id)),
            ),
          );
        }

        final track = tracks[trackIndex];
        final isPrimary = !isOffSelected && track.id == selectedSub.id;
        final isSecondary = hasSecondary && track.id == secondarySub.id;
        final label = TrackLabelBuilder.subtitleLabel(
          title: track.title,
          language: track.language,
          codec: track.codec,
          forced: track.isForced,
          index: trackIndex,
        );

        Widget? badge;
        if (supportsSecondary && hasSecondary) {
          if (isPrimary) {
            badge = TrackSelectionHelper.buildTrackBadge(context, 1);
          } else if (isSecondary) {
            badge = TrackSelectionHelper.buildTrackBadge(context, 2);
          }
        }

        return TrackSelectionHelper.buildTrackTile(
          context: context,
          label: label,
          isSelected: isPrimary,
          badge: badge,
          onTap: () {
            // If tapping a track that is currently the secondary, clear secondary first
            if (isSecondary) {
              player.selectSecondarySubtitleTrack(SubtitleTrack.off);
              trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
            }
            player.selectSubtitleTrack(track);
            trackControlsState.onSubtitleTrackChanged?.call(track);
            OverlaySheetController.of(context).close();
          },
          onLongPress: supportsSecondary
              ? () {
                  if (isSecondary) {
                    // Already secondary — clear it
                    player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                  } else if (!isPrimary) {
                    // Set as secondary (don't close sheet so user sees badge update)
                    player.selectSecondarySubtitleTrack(track);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(track);
                  }
                }
              : null,
          onSecondaryTap: supportsSecondary
              ? () {
                  if (isSecondary) {
                    player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                  } else if (!isPrimary) {
                    player.selectSecondarySubtitleTrack(track);
                    trackControlsState.onSecondarySubtitleTrackChanged?.call(track);
                  }
                }
              : null,
        );
      },
    );
  }
}

List<Widget> _buildSubtitleSearchFooter(BuildContext context, TrackControlsState state) {
  if (!state.canSearchSubtitles) return const [];

  return [
    Divider(height: 1, color: Theme.of(context).dividerColor),
    FocusableListTile(
      leading: const AppIcon(Symbols.search_rounded),
      title: Text(t.videoControls.searchSubtitles),
      onTap: () {
        OverlaySheetController.of(context).push(
          builder: (_) => SubtitleSearchSheet(
            ratingKey: state.ratingKey,
            serverId: state.serverId!,
            mediaTitle: state.mediaTitle,
            onSubtitleDownloaded: state.onSubtitleDownloaded,
          ),
        );
      },
    ),
  ];
}
