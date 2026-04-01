import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/scroll_utils.dart';
import '../../../utils/track_label_builder.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'subtitle_search_sheet.dart';
import '../helpers/track_filter_helper.dart';
import '../helpers/track_selection_helper.dart';

/// Combined bottom sheet for selecting audio and subtitle tracks side-by-side.
class TrackSheet extends StatelessWidget {
  final Player player;
  final String ratingKey;
  final String serverId;
  final String? mediaTitle;
  final Future<void> Function()? onSubtitleDownloaded;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;

  const TrackSheet({
    super.key,
    required this.player,
    this.ratingKey = '',
    this.serverId = '',
    this.mediaTitle,
    this.onSubtitleDownloaded,
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
                          ratingKey: ratingKey,
                          serverId: serverId,
                          mediaTitle: mediaTitle,
                          onSubtitleDownloaded: onSubtitleDownloaded,
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
                ratingKey: ratingKey,
                serverId: serverId,
                mediaTitle: mediaTitle,
                onSubtitleDownloaded: onSubtitleDownloaded,
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

class _AudioColumn extends StatefulWidget {
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
  State<_AudioColumn> createState() => _AudioColumnState();
}

class _AudioColumnState extends State<_AudioColumn> {
  final _firstItemKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selection.audio?.id ?? '';

    if (!_didInitialScroll) {
      final selectedIndex = widget.tracks.indexWhere((t) => t.id == selectedId);
      if (selectedIndex > 0) {
        _didInitialScroll = true;
        scrollToCurrentItem(_scrollController, _firstItemKey, selectedIndex);
      }
    }

    return Column(
      children: [
        if (widget.showHeader) _ColumnHeader(label: t.videoControls.audioLabel),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.tracks.length,
            itemBuilder: (context, index) {
              final track = widget.tracks[index];
              final label = TrackLabelBuilder.buildAudioLabel(
                title: track.title,
                language: track.language,
                codec: track.codec,
                channelsCount: track.channelsCount,
                index: index,
              );
              return TrackSelectionHelper.buildTrackTile<AudioTrack>(
                context: context,
                key: index == 0 ? _firstItemKey : null,
                label: label,
                isSelected: track.id == selectedId,
                onTap: () {
                  widget.player.selectAudioTrack(track);
                  widget.onTrackChanged?.call(track);
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

class _SubtitleColumn extends StatefulWidget {
  final List<SubtitleTrack> tracks;
  final TrackSelection selection;
  final Player player;
  final String ratingKey;
  final String serverId;
  final String? mediaTitle;
  final Future<void> Function()? onSubtitleDownloaded;
  final Function(SubtitleTrack)? onTrackChanged;
  final Function(SubtitleTrack)? onSecondaryTrackChanged;
  final bool supportsSecondary;
  final bool showHeader;

  const _SubtitleColumn({
    required this.tracks,
    required this.selection,
    required this.player,
    this.ratingKey = '',
    this.serverId = '',
    this.mediaTitle,
    this.onSubtitleDownloaded,
    this.onTrackChanged,
    this.onSecondaryTrackChanged,
    this.supportsSecondary = false,
    required this.showHeader,
  });

  @override
  State<_SubtitleColumn> createState() => _SubtitleColumnState();
}

class _SubtitleColumnState extends State<_SubtitleColumn> {
  final _firstItemKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSub = widget.selection.subtitle;
    final secondarySub = widget.selection.secondarySubtitle;
    final isOffSelected = selectedSub == null || selectedSub.id == 'no';
    final hasSecondary = widget.supportsSecondary && secondarySub != null;

    // +1 for "Off" row
    final itemCount = widget.tracks.length + 1;

    if (!_didInitialScroll && !isOffSelected) {
      // +1 because index 0 is the "Off" row
      final selectedIndex = widget.tracks.indexWhere((t) => t.id == selectedSub.id) + 1;
      if (selectedIndex > 0) {
        _didInitialScroll = true;
        scrollToCurrentItem(_scrollController, _firstItemKey, selectedIndex);
      }
    }

    return Column(
      children: [
        if (widget.showHeader) _ColumnHeader(label: t.videoControls.subtitlesLabel),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // "Off" row
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  context: context,
                  key: _firstItemKey,
                  isSelected: isOffSelected,
                  onTap: () {
                    // Turning off primary also clears secondary
                    if (hasSecondary) {
                      widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                      widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                    }
                    widget.player.selectSubtitleTrack(SubtitleTrack.off);
                    widget.onTrackChanged?.call(SubtitleTrack.off);
                    OverlaySheetController.of(context).close();
                  },
                  onLongPress: widget.supportsSecondary && hasSecondary
                      ? () {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                  onSecondaryTap: widget.supportsSecondary && hasSecondary
                      ? () {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                );
              }

              final track = widget.tracks[index - 1];
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
              if (widget.supportsSecondary && hasSecondary) {
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
                    widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                    widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                  }
                  widget.player.selectSubtitleTrack(track);
                  widget.onTrackChanged?.call(track);
                  OverlaySheetController.of(context).close();
                },
                onLongPress: widget.supportsSecondary
                    ? () {
                        if (isSecondary) {
                          // Already secondary — clear it
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          // Set as secondary (don't close sheet so user sees badge update)
                          widget.player.selectSecondarySubtitleTrack(track);
                          widget.onSecondaryTrackChanged?.call(track);
                        }
                      }
                    : null,
                onSecondaryTap: widget.supportsSecondary
                    ? () {
                        if (isSecondary) {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.onSecondaryTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          widget.player.selectSecondarySubtitleTrack(track);
                          widget.onSecondaryTrackChanged?.call(track);
                        }
                      }
                    : null,
              );
            },
          ),
        ),
        if (widget.ratingKey.isNotEmpty) ...[
          Divider(height: 1, color: Theme.of(context).dividerColor),
          FocusableListTile(
            leading: const AppIcon(Symbols.search_rounded),
            title: Text(t.videoControls.searchSubtitles),
            onTap: () {
              OverlaySheetController.of(context).push(
                builder: (_) => SubtitleSearchSheet(
                  ratingKey: widget.ratingKey,
                  serverId: widget.serverId,
                  mediaTitle: widget.mediaTitle,
                  onSubtitleDownloaded: widget.onSubtitleDownloaded,
                ),
              );
            },
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
