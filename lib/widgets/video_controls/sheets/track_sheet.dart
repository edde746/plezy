import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../media/media_source_info.dart';
import '../../../mpv/mpv.dart';
import '../../../services/playback_subtitle_resolver.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/scroll_utils.dart';
import '../../../utils/track_label_builder.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'sheet_column_header.dart';
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

class _SourceAudioColumn extends StatefulWidget {
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
  State<_SourceAudioColumn> createState() => _SourceAudioColumnState();
}

class _SourceAudioColumnState extends State<_SourceAudioColumn> {
  final _initialScroll = InitialItemScrollController();
  bool _selectionPending = false;

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  Future<void> _select(int streamId) async {
    if (_selectionPending) return;
    setState(() => _selectionPending = true);
    try {
      await widget.onSelected(streamId);
      if (mounted) OverlaySheetController.of(context).close();
    } finally {
      if (mounted) setState(() => _selectionPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _effectiveSelectedStreamId();
    final selectedIndex = selectedId == null ? null : widget.tracks.indexWhere((t) => t.id == selectedId);
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.audioLabel),
        if (_selectionPending) const LinearProgressIndicator(minHeight: 2),
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
                onTap: () => unawaited(_select(track.id)),
              );
            },
          ),
        ),
      ],
    );
  }

  int? _effectiveSelectedStreamId() {
    final explicit = widget.selectedStreamId;
    if (explicit != null && widget.tracks.any((track) => track.id == explicit)) return explicit;
    for (final track in widget.tracks) {
      if (track.selected) return track.id;
    }
    return null;
  }
}

class _SourceSubtitleColumn extends StatefulWidget {
  final List<MediaSubtitleTrack> tracks;
  final TrackControlsState trackControlsState;
  final bool showHeader;

  const _SourceSubtitleColumn({required this.tracks, required this.trackControlsState, required this.showHeader});

  @override
  State<_SourceSubtitleColumn> createState() => _SourceSubtitleColumnState();
}

class _SourceSubtitleColumnState extends State<_SourceSubtitleColumn> {
  final _initialScroll = InitialItemScrollController();
  bool _selectionPending = false;

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  Future<void> _select(PlaybackSourceSubtitleChoice choice) async {
    if (_selectionPending) return;
    setState(() => _selectionPending = true);
    try {
      await widget.trackControlsState.onSwitchSubtitle!(choice);
      if (mounted) OverlaySheetController.of(context).close();
    } finally {
      if (mounted) setState(() => _selectionPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedChoice = _effectiveSelectedChoice();
    final selectedId = selectedChoice.sourceStreamId;
    final selectedIndex = selectedChoice.isOff ? 0 : widget.tracks.indexWhere((t) => t.id == selectedId) + 1;
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.subtitlesLabel),
        if (_selectionPending) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: widget.tracks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  context: context,
                  key: _initialScroll.firstItemKey,
                  isSelected: selectedChoice.isOff,
                  onTap: () => unawaited(_select(const PlaybackSourceSubtitleChoice.off())),
                );
              }

              final track = widget.tracks[index - 1];
              return TrackSelectionHelper.buildTrackTile<SubtitleTrack>(
                context: context,
                label: track.labelForIndex(index - 1),
                isSelected: track.id == selectedId,
                onTap: () => unawaited(_select(PlaybackSourceSubtitleChoice.source(track.id))),
              );
            },
          ),
        ),
        ..._buildSubtitleSearchFooter(context, widget.trackControlsState),
      ],
    );
  }

  PlaybackSourceSubtitleChoice _effectiveSelectedChoice() {
    final explicit = widget.trackControlsState.selectedSubtitleChoice;
    if (explicit != null && (explicit.isOff || widget.tracks.any((track) => track.id == explicit.sourceStreamId))) {
      return explicit;
    }
    for (final track in widget.tracks) {
      if (track.selected) return PlaybackSourceSubtitleChoice.source(track.id);
    }
    return const PlaybackSourceSubtitleChoice.off();
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
              final label = TrackLabelBuilder.audioLabel(
                title: track.title,
                language: track.language,
                codec: track.codec,
                channels: track.channelsCount,
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
  State<_SubtitleColumn> createState() => _SubtitleColumnState();
}

class _SubtitleColumnState extends State<_SubtitleColumn> {
  final _initialScroll = InitialItemScrollController();
  bool _selectionPending = false;

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  Future<void> _selectSourceSidecar(int streamId) async {
    if (_selectionPending) return;
    setState(() => _selectionPending = true);
    try {
      await widget.trackControlsState.onSwitchSubtitle!(PlaybackSourceSubtitleChoice.source(streamId));
      if (mounted) OverlaySheetController.of(context).close();
    } finally {
      if (mounted) setState(() => _selectionPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSub = widget.selection.subtitle;
    final secondarySub = widget.selection.secondarySubtitle;
    final isOffSelected = selectedSub == null || selectedSub.id == 'no';
    final hasSecondary = widget.supportsSecondary && secondarySub != null;
    final selectedSourceId = widget.trackControlsState.selectedSubtitleChoice?.sourceStreamId;
    final selectedSecondarySourceId = widget.trackControlsState.selectedSecondarySubtitleStreamId;
    final attachedSourceSidecarIds = <int>{};
    for (final sidecar in widget.trackControlsState.sourceSubtitleSidecars) {
      final sourceStreamId = sidecar.sourceStreamId;
      final uri = sidecar.track.uri;
      if (sourceStreamId == null || uri == null) continue;
      if (widget.tracks.any((track) => track.isExternal && track.uri == uri)) {
        attachedSourceSidecarIds.add(sourceStreamId);
      }
    }
    final unloadedSourceSidecars = widget.sourceSidecars
        .where(
          (track) =>
              !attachedSourceSidecarIds.contains(track.id) &&
              track.id != selectedSourceId &&
              track.id != selectedSecondarySourceId,
        )
        .toList(growable: false);

    // +1 for "Off". Source sidecars represented by native external tracks,
    // plus active source IDs awaiting native discovery, are not appended.
    final itemCount = widget.tracks.length + unloadedSourceSidecars.length + 1;

    final selectedIndex = isOffSelected ? null : widget.tracks.indexWhere((t) => t.id == selectedSub.id) + 1;
    _initialScroll.maybeScrollTo(selectedIndex);

    return Column(
      children: [
        if (widget.showHeader) SheetColumnHeader(label: t.videoControls.subtitlesLabel),
        if (_selectionPending) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.builder(
            controller: _initialScroll.controller,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return TrackSelectionHelper.buildOffTile<SubtitleTrack>(
                  context: context,
                  key: _initialScroll.firstItemKey,
                  isSelected: isOffSelected,
                  onTap: () {
                    // Turning off primary also clears secondary
                    if (hasSecondary) {
                      widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                      widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                    }
                    widget.player.selectSubtitleTrack(SubtitleTrack.off);
                    widget.trackControlsState.onSubtitleTrackChanged?.call(SubtitleTrack.off);
                    OverlaySheetController.of(context).close();
                  },
                  onLongPress: widget.supportsSecondary && hasSecondary
                      ? () {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                  onSecondaryTap: widget.supportsSecondary && hasSecondary
                      ? () {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                        }
                      : null,
                );
              }

              final trackIndex = index - 1;
              if (trackIndex >= widget.tracks.length) {
                final sourceIndex = trackIndex - widget.tracks.length;
                final sourceTrack = unloadedSourceSidecars[sourceIndex];
                return TrackSelectionHelper.buildTrackTile<SubtitleTrack>(
                  context: context,
                  label: sourceTrack.labelForIndex(trackIndex),
                  isSelected: false,
                  onTap: () => unawaited(_selectSourceSidecar(sourceTrack.id)),
                );
              }

              final track = widget.tracks[trackIndex];
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
                    widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                  }
                  widget.player.selectSubtitleTrack(track);
                  widget.trackControlsState.onSubtitleTrackChanged?.call(track);
                  OverlaySheetController.of(context).close();
                },
                onLongPress: widget.supportsSecondary
                    ? () {
                        if (isSecondary) {
                          // Already secondary — clear it
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          // Set as secondary (don't close sheet so user sees badge update)
                          widget.player.selectSecondarySubtitleTrack(track);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(track);
                        }
                      }
                    : null,
                onSecondaryTap: widget.supportsSecondary
                    ? () {
                        if (isSecondary) {
                          widget.player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                        } else if (!isPrimary) {
                          widget.player.selectSecondarySubtitleTrack(track);
                          widget.trackControlsState.onSecondarySubtitleTrackChanged?.call(track);
                        }
                      }
                    : null,
              );
            },
          ),
        ),
        ..._buildSubtitleSearchFooter(context, widget.trackControlsState),
      ],
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
