import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../media/media_source_info.dart';
import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/scroll_utils.dart';
import '../../../utils/track_label_builder.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'sheet_column_header.dart';
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

  /// When true, the audio column renders the Plex [sourceAudioTracks] list
  /// and taps are routed to [onSwitchAudioStreamId] instead of using the
  /// player's in-stream audio selection (the transcoded stream only has one
  /// audio track).
  final bool isTranscoding;
  final List<MediaAudioTrack> sourceAudioTracks;
  final int? selectedAudioStreamId;
  final ValueChanged<int>? onSwitchAudioStreamId;

  /// Whether OpenSubtitles search is supported by the active server. Plex
  /// proxies the OpenSubtitles plugin; Jellyfin doesn't expose an
  /// equivalent today.
  final bool subtitleSearchSupported;

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
    this.isTranscoding = false,
    this.sourceAudioTracks = const [],
    this.selectedAudioStreamId,
    this.onSwitchAudioStreamId,
    this.subtitleSearchSupported = true,
  });

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

        final useSourceAudio = isTranscoding && sourceAudioTracks.length > 1 && onSwitchAudioStreamId != null;
        final showAudio = useSourceAudio || playerAudioTracks.length > 1;
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

              Widget audioColumnFor(TrackSelection sel, bool showHeader) {
                if (useSourceAudio) {
                  return _SourceAudioColumn(
                    tracks: sourceAudioTracks,
                    selectedStreamId: selectedAudioStreamId,
                    onSelected: onSwitchAudioStreamId!,
                    showHeader: showHeader,
                  );
                }
                return _AudioColumn(
                  tracks: playerAudioTracks,
                  selection: sel,
                  player: player,
                  onTrackChanged: onAudioTrackChanged,
                  showHeader: showHeader,
                );
              }

              if (showAudio && showSubtitles) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: FocusTraversalGroup(child: audioColumnFor(selection, true))),
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
                          subtitleSearchSupported: subtitleSearchSupported,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (showAudio) {
                return audioColumnFor(selection, false);
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
                subtitleSearchSupported: subtitleSearchSupported,
              );
            },
          ),
        );
      },
    );
  }
}

class _SourceAudioColumn extends StatefulWidget {
  final List<MediaAudioTrack> tracks;
  final int? selectedStreamId;
  final ValueChanged<int> onSelected;
  final bool showHeader;

  const _SourceAudioColumn({
    required this.tracks,
    required this.selectedStreamId,
    required this.onSelected,
    required this.showHeader,
  });

  @override
  State<_SourceAudioColumn> createState() => _SourceAudioColumnState();
}

class _SourceAudioColumnState extends State<_SourceAudioColumn> {
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedStreamId;
    final selectedIndex = selectedId == null ? null : widget.tracks.indexWhere((t) => t.id == selectedId);
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.audioLabel),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: widget.tracks.length,
            itemBuilder: (context, index) {
              final track = widget.tracks[index];
              final isSelected = track.id == selectedId;
              return TrackSelectionHelper.buildTrackTile<AudioTrack>(
                context: context,
                key: index == 0 ? _initialScroll.firstItemKey : null,
                label: track.label,
                isSelected: isSelected,
                onTap: () {
                  OverlaySheetController.of(context).close();
                  widget.onSelected(track.id);
                },
              );
            },
          ),
        ),
      ],
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
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selection.audio?.id ?? '';
    final selectedIndex = widget.tracks.indexWhere((t) => t.id == selectedId);
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.audioLabel),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
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
                key: index == 0 ? _initialScroll.firstItemKey : null,
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
  final bool subtitleSearchSupported;

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
    this.subtitleSearchSupported = true,
  });

  @override
  State<_SubtitleColumn> createState() => _SubtitleColumnState();
}

class _SubtitleColumnState extends State<_SubtitleColumn> {
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
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

    final selectedIndex = isOffSelected ? null : widget.tracks.indexWhere((t) => t.id == selectedSub.id) + 1;
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.subtitlesLabel),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // "Off" row
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  context: context,
                  key: _initialScroll.firstItemKey,
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
        if (widget.ratingKey.isNotEmpty && widget.subtitleSearchSupported) ...[
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
