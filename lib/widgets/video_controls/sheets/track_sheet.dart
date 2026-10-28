import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, ValueListenableBuilder;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;

import '../../../media/media_source_info.dart';
import '../../../media/media_kind.dart';
import '../../../media/ids.dart';
import '../../../services/settings_service.dart';
import '../../../mpv/mpv.dart';
import '../../../services/file_picker_service.dart';
import '../../../services/incoming_subtitle_share_service.dart';
import '../../../services/playback_subtitle_resolver.dart';
import '../../../services/subtitle_archive_importer.dart';
import '../../../services/subtitle_ai_service.dart';
import '../../../services/track_selection_service.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/formatters.dart';
import '../../../utils/language_codes.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/track_label_builder.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import 'sheet_selection_column.dart';
import 'sheet_split_columns.dart';
import 'subtitle_search_sheet.dart';
import 'subtitle_ai_sheet.dart';
import 'subtitle_style_sheet.dart';
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
    final sheet = StreamBuilder<Tracks>(
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
                    isTranscoding: state.isTranscoding,
                    selection: sel,
                    mpvAudioTracks: tracks?.audio ?? const <AudioTrack>[],
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
                    selection: sel,
                    player: player,
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
                return SheetSplitColumns(
                  start: FocusTraversalGroup(child: audioColumnFor(selection, true)),
                  end: FocusTraversalGroup(child: subtitleColumnFor(selection, true)),
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
    if (const {TargetPlatform.android, TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows}
        .contains(defaultTargetPlatform)) {
      return DropTarget(
        onDragDone: (details) => unawaited(_stageDroppedSubtitleFiles(context, player, details.files)),
        child: sheet,
      );
    }
    return sheet;
  }
}

class _SourceAudioColumn extends StatelessWidget {
  final List<MediaAudioTrack> tracks;
  final int? selectedStreamId;

  /// Whether the audio is baked into a server rendition rather than picked by
  /// the engine; decides which side is allowed to answer "what is playing".
  final bool isTranscoding;

  /// Engine truth (`player.streams.track`) and the raw engine audio list, used
  /// to map mpv's `aid` back onto a source row on a direct play.
  final TrackSelection selection;
  final List<AudioTrack> mpvAudioTracks;
  final Future<void> Function(int) onSelected;
  final bool showHeader;

  const _SourceAudioColumn({
    required this.tracks,
    required this.selectedStreamId,
    required this.isTranscoding,
    required this.selection,
    required this.mpvAudioTracks,
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
    // On a transcode the chosen row is baked into the rendition — mpv carries a
    // single audio track that is no particular source stream — so the server's
    // `selected` flag is the only answer that exists. On a direct play with
    // external source audio this column is still used but mpv owns the choice,
    // and that flag is the server's *request*, free to disagree with `aid`.
    if (isTranscoding) {
      for (final track in tracks) {
        if (track.selected) return track.id;
      }
      return null;
    }
    return playingSourceAudioTrack(
      selectedMpvTrack: selection.audio,
      mpvTracks: mpvAudioTracks,
      sourceTracks: tracks,
    )?.id;
  }
}

class _SourceSubtitleColumn extends StatelessWidget {
  final List<MediaSubtitleTrack> tracks;
  final TrackControlsState trackControlsState;

  /// Engine truth (`player.streams.track`), so the tick can be cross-checked
  /// against what mpv is actually playing rather than only what was requested.
  final TrackSelection selection;
  final Player player;
  final bool showHeader;

  const _SourceSubtitleColumn({
    required this.tracks,
    required this.trackControlsState,
    required this.selection,
    required this.player,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final selectedChoice = _effectiveSelectedChoice();
    final selectedId = selectedChoice.sourceStreamId;
    final selectedIndex = selectedChoice.isOff ? 0 : tracks.indexWhere((t) => t.id == selectedId) + 1;

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.subtitlesLabel : null,
      itemCount: tracks.length + 1,
      initialIndex: selectedIndex,
      footer: _buildSubtitleFooter(context, trackControlsState, player),
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

  /// The row to tick.
  ///
  /// A requested source subtitle is not proof of a playing one: when
  /// [TrackManager] misses its resolve deadline the ladder falls through to off
  /// while the session keeps naming the track, so the picker claimed subtitles
  /// were on while mpv held `sid=no`. A source pick therefore only stands when
  /// the engine confirms it — or when there is nothing for the engine to
  /// confirm because the server burned the subtitle into the picture.
  PlaybackSourceSubtitleChoice _effectiveSelectedChoice() {
    const off = PlaybackSourceSubtitleChoice.off();
    final explicit = trackControlsState.selectedSubtitleChoice;
    if (explicit == null) return off;
    if (explicit.isOff) return explicit;
    if (!tracks.any((track) => track.id == explicit.sourceStreamId)) return off;
    if (trackControlsState.burnsSelectedSubtitle) return explicit;
    final engineSubtitle = selection.subtitle;
    return engineSubtitle != null && engineSubtitle.id != SubtitleTrack.off.id ? explicit : off;
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
          codecProfile: track.codecProfile,
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
    final attachedSourceSidecarIds = <int>{};
    for (final sidecar in trackControlsState.sourceSubtitleSidecars) {
      final sourceStreamId = sidecar.sourceStreamId;
      final uri = sidecar.track.uri;
      if (sourceStreamId == null || uri == null) continue;
      if (tracks.any((track) => track.isExternal && track.uri == uri)) {
        attachedSourceSidecarIds.add(sourceStreamId);
      }
    }
    final unloadedSourceSidecars = sourceSidecars
        .where(
          (track) =>
              !attachedSourceSidecarIds.contains(track.id) &&
              track.id != selectedSourceId &&
              track.id != selectedSecondarySourceId,
        )
        .toList(growable: false);

    // +1 for "Off". Source sidecars represented by native external tracks,
    // plus active source IDs awaiting native discovery, are not appended.
    final itemCount = tracks.length + unloadedSourceSidecars.length + 1;

    final selectedIndex = isOffSelected ? null : tracks.indexWhere((t) => t.id == selectedSub.id) + 1;

    return SheetSelectionColumn(
      headerLabel: showHeader ? t.videoControls.subtitlesLabel : null,
      itemCount: itemCount,
      initialIndex: selectedIndex,
      footer: _buildSubtitleFooter(context, trackControlsState, player),
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
            secondaryAction: supportsSecondary
                ? IconButton(
                    tooltip: 'Clear secondary subtitle',
                    onPressed: hasSecondary
                        ? () {
                            player.selectSecondarySubtitleTrack(SubtitleTrack.off);
                            trackControlsState.onSecondarySubtitleTrackChanged?.call(SubtitleTrack.off);
                          }
                        : null,
                    icon: const Icon(Icons.subtitles_off_outlined, size: 20),
                  )
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
          secondaryAction: supportsSecondary
              ? IconButton(
                  tooltip: isSecondary ? 'Clear secondary subtitle' : 'Select as secondary subtitle',
                  onPressed: isPrimary
                      ? null
                      : () {
                          final next = isSecondary ? SubtitleTrack.off : track;
                          player.selectSecondarySubtitleTrack(next);
                          trackControlsState.onSecondarySubtitleTrackChanged?.call(next);
                        },
                  icon: Icon(isSecondary ? Icons.subtitles_off_outlined : Icons.subtitles_outlined, size: 20),
                )
              : null,
        );
      },
    );
  }
}

Future<void> _configureSubtitleReplayPreroll(BuildContext context) async {
  final settings = SettingsService.instance;
  final pref = SettingsService.subtitleReplayPrerollMs;
  var selected = settings.read(pref).clamp(0, 2500).toDouble();
  final value = await showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Subtitle replay lead-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${selected.round()} ms before the cue'),
            Slider(
              value: selected,
              min: 0,
              max: 2500,
              divisions: 50,
              label: '${selected.round()} ms',
              onChanged: (value) => setDialogState(() => selected = value),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(selected.round()), child: const Text('Save')),
        ],
      ),
    ),
  );
  if (value == null || !context.mounted) return;
  await settings.write(pref, value.clamp(0, 2500).toInt());
  if (context.mounted) showSnackBar(context, 'Subtitle replay lead-in saved.');
}

List<Widget> _buildSubtitleFooter(BuildContext context, TrackControlsState state, Player player) {
  final actions = <Widget>[];
  if (player.supportsSecondarySubtitles) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.replay_rounded),
        title: const Text('Replay current subtitle'),
        onTap: () => _replayCurrentSubtitle(context, player),
      ),
    );
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.replay_rounded),
        title: const Text('Replay current secondary subtitle'),
        onTap: () => _replayCurrentSubtitle(context, player, secondary: true),
      ),
    );
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.timer_rounded),
        title: const Text('Subtitle replay lead-in'),
        subtitle: Text('${SettingsService.instance.read(SettingsService.subtitleReplayPrerollMs).clamp(0, 2500).toInt()} ms before the cue'),
        onTap: () => unawaited(_configureSubtitleReplayPreroll(context)),
      ),
    );
  }

  if (state.canSearchSubtitles) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.search_rounded),
        title: Text(t.videoControls.searchSubtitles),
        onTap: () {
          OverlaySheetController.of(context).push(
            builder: (_) => SubtitleSearchSheet(
              ratingKey: state.ratingKey,
              serverId: state.serverId!,
              mediaIndex: state.selectedMediaIndex,
              mediaTitle: state.mediaTitle,
              onSubtitleDownloaded: state.onSubtitleDownloaded,
            ),
          );
        },
      ),
    );
  }

  actions.add(
    ValueListenableBuilder<int>(
      valueListenable: IncomingSubtitleShareService.pendingCount,
      builder: (context, count, _) {
        if (count == 0 || defaultTargetPlatform != TargetPlatform.android) return const SizedBox.shrink();
        return FocusableListTile(
          leading: const AppIcon(Symbols.move_to_inbox_rounded),
          title: Text('Import shared subtitle ($count)'),
          onTap: () => _importSharedSubtitleFiles(context, player),
        );
      },
    ),
  );

  if (player.supportedLocalSubtitleExtensions.isNotEmpty) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.file_open_rounded),
        title: Text(t.videoControls.loadSubtitleFile),
        onTap: () => _loadSubtitleFile(context, player),
      ),
    );
  }

  if (SubtitleAiService.supportedPlatform && player.supportedLocalSubtitleExtensions.contains('srt')) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.auto_awesome_rounded),
        title: const Text('Generate, sync, or translate subtitles'),
        subtitle: const Text('Generate, sync, and translate WAV-based subtitle tracks'),
        onTap: () => OverlaySheetController.of(context).push(
          builder: (_) => SubtitleAiSheet(
            player: player,
            serverId: state.serverId,
            ratingKey: state.ratingKey.isEmpty ? null : state.ratingKey,
            mediaIndex: state.selectedMediaIndex,
            seriesKey: state.metadata?.seriesGlobalKey ??
                (state.metadata?.kind == MediaKind.show ? state.metadata?.globalKey : null),
          ),
        ),
      ),
    );
  }

  if (state.serverId != null && state.ratingKey.isNotEmpty) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.cloud_upload_rounded),
        title: const Text('Attach subtitle to server library'),
        onTap: () => _attachSubtitleFile(context, state),
      ),
    );
  }

  if (player.supportsSubtitleStyleControls) {
    actions.add(
      FocusableListTile(
        leading: const AppIcon(Symbols.format_size_rounded),
        title: Text(t.screens.subtitleStyling),
        onTap: () => OverlaySheetController.of(context).push(builder: (_) => InPlayerSubtitleStyleSheet(player: player)),
      ),
    );
  }

  if (actions.isEmpty) return const [];
  return [Divider(height: 1, color: Theme.of(context).dividerColor), ...actions];
}

Future<void> _loadSubtitleFile(BuildContext context, Player player) async {
  final supportedExtensions = player.supportedLocalSubtitleExtensions.toList()..sort();
  final result = await FilePickerService.instance.pickFiles(
    type: FileType.custom,
    allowedExtensions: {...supportedExtensions, if (!kIsWeb) 'zip'}.toList()..sort(),
  );
  if (result == null || result.files.isEmpty || !context.mounted) return;
  final pickedFile = result.files.first;

  try {
    final selectedPath = p.extension(pickedFile.name).toLowerCase() == '.zip'
        ? await _selectArchivedSubtitle(context, pickedFile, supportedExtensions)
        : pickedFile.path;
    if (selectedPath == null || !context.mounted) return;
    await player.command(['sub-add', selectedPath, 'select']);
    if (context.mounted) OverlaySheetController.of(context).close();
  } catch (error, stackTrace) {
    appLogger.w('Could not load local subtitle file', error: error, stackTrace: stackTrace);
    if (context.mounted) showErrorSnackBar(context, t.videoControls.subtitleLoadFailed);
  }
}

Future<void> _attachSubtitleFile(BuildContext context, TrackControlsState state) async {
  final result = await FilePickerService.instance.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['ass', 'srt', 'ssa', 'vtt'],
  );
  if (result == null || result.files.isEmpty || !context.mounted) return;
  final file = result.files.first;
  final format = p.extension(file.name).toLowerCase().replaceFirst('.', '');
  if (!const {'srt', 'vtt', 'ass', 'ssa'}.contains(format)) {
    showErrorSnackBar(context, 'Choose an SRT, VTT, ASS, or SSA subtitle.');
    return;
  }

  try {
    final bytes = await SubtitleArchiveImporter.readPickedArchive(file);
    if (bytes.isEmpty || bytes.lengthInBytes > 20 * 1024 * 1024) {
      showErrorSnackBar(context, 'Subtitle files must be smaller than 20 MiB.');
      return;
    }

    final settings = SettingsService.instanceOrNull;
    final systemCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final defaultLanguage = LanguageCodes.getIso6391Code(
      settings?.read(SettingsService.subtitleSearchLanguage) ?? systemCode,
    ) ?? 'en';
    final languageController = TextEditingController(text: defaultLanguage);
    var forced = RegExp(r'(^|[._ -])forced([._ -]|$)', caseSensitive: false).hasMatch(file.name);
    var hearingImpaired = RegExp(r'(^|[._ -])(sdh|cc)([._ -]|$)', caseSensitive: false).hasMatch(file.name);
    String? languageError;
    final options = await showDialog<({String language, bool forced, bool hearingImpaired})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Attach subtitle to server library'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                TextField(
                  controller: languageController,
                  decoration: InputDecoration(
                    labelText: 'Language code',
                    helperText: 'ISO 639-1, for example en or ja',
                    errorText: languageError,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Forced subtitles'),
                  value: forced,
                  onChanged: (value) => setDialogState(() => forced = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SDH / closed captions'),
                  value: hearingImpaired,
                  onChanged: (value) => setDialogState(() => hearingImpaired = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () {
                final language = LanguageCodes.getIso6391Code(languageController.text.trim());
                if (language == null) {
                  setDialogState(() => languageError = 'Enter a valid ISO 639-1 language code.');
                  return;
                }
                Navigator.of(dialogContext).pop((
                  language: language,
                  forced: forced,
                  hearingImpaired: hearingImpaired,
                ));
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
    languageController.dispose();
    if (options == null || !context.mounted) return;

    final client = context.tryGetMediaClientForServer(ServerId(state.serverId!));
    if (client == null) {
      showErrorSnackBar(context, 'The media server is no longer available.');
      return;
    }
    final uploaded = await client.attachSubtitle(
      state.ratingKey,
      bytes: bytes,
      fileName: file.name,
      format: format,
      language: options.language,
      forced: options.forced,
      hearingImpaired: options.hearingImpaired,
      mediaIndex: state.selectedMediaIndex,
    );
    if (!context.mounted) return;
    if (!uploaded) {
      showErrorSnackBar(context, 'The media server did not accept this subtitle.');
      return;
    }

    SubtitleDownloadApplyOutcome? outcome;
    try {
      outcome = await state.onSubtitleDownloaded?.call(
        serverId: state.serverId!,
        ratingKey: state.ratingKey,
        preferredLanguageCode: options.language,
      );
    } catch (error, stackTrace) {
      appLogger.w('Subtitle uploaded but playback refresh did not complete', error: error, stackTrace: stackTrace);
    }
    if (!context.mounted) return;
    if (outcome == SubtitleDownloadApplyOutcome.applied) {
      showSuccessSnackBar(context, t.videoControls.subtitleDownloaded);
    } else {
      showSuccessSnackBar(context, 'Subtitle uploaded. Refresh playback to load it.');
    }
    OverlaySheetController.of(context).close();
  } catch (error, stackTrace) {
    appLogger.w('Could not attach subtitle to media library', error: error, stackTrace: stackTrace);
    if (context.mounted) showErrorSnackBar(context, 'Could not attach subtitle to the server library.');
  }
}

Future<void> _replayCurrentSubtitle(
  BuildContext context,
  Player player, {
  bool secondary = false,
}) async {
  try {
    final prefix = secondary ? 'secondary-sub' : 'sub';
    final text = (await player.getProperty('$prefix-text'))?.trim() ?? '';
    final start = double.tryParse(await player.getProperty('$prefix-start') ?? '');
    final end = double.tryParse(await player.getProperty('$prefix-end') ?? '');
    if (text.isEmpty || start == null || !start.isFinite || end == null || !end.isFinite || end <= start) {
      if (context.mounted) showSnackBar(context, 'No active text subtitle cue is available to replay.');
      return;
    }
    if (!player.state.seekable) {
      if (context.mounted) showSnackBar(context, 'This player cannot seek to replay the subtitle.');
      return;
    }
    final startMs = (start * 1000).round();
    final prerollMs = SettingsService.instance.read(SettingsService.subtitleReplayPrerollMs).clamp(0, 2500).toInt();
    await player.seek(Duration(milliseconds: (startMs - prerollMs).clamp(0, 1 << 31).toInt()));
  } catch (error, stackTrace) {
    appLogger.w('Could not replay the active subtitle cue', error: error, stackTrace: stackTrace);
    if (context.mounted) showSnackBar(context, 'This player does not expose the active subtitle cue timing.');
  }
}

Future<void> _stageDroppedSubtitleFiles(
  BuildContext context,
  Player player,
  List<DropItemFile> files,
) async {
  final supported = player.supportedLocalSubtitleExtensions;
  final candidates = files.where((file) {
    final extension = p.extension(file.name).toLowerCase().replaceFirst('.', '');
    return extension == 'zip' || supported.contains(extension);
  }).take(12);
  if (candidates.isEmpty) return;

  final staged = <String>[];
  final batchPrefix = DateTime.now().microsecondsSinceEpoch;
  final directory = await getTemporaryDirectory();
  final targetDirectory = Directory(p.join(directory.path, 'plezyng_subtitle_drop'));
  await targetDirectory.create(recursive: true);
  for (final file in candidates) {
    final extension = p.extension(file.name).toLowerCase();
    final maximumBytes = extension == '.zip' ? 50 * 1024 * 1024 : 32 * 1024 * 1024;
    final bookmark = file.extraAppleBookmark;
    var accessed = false;
    try {
      if (bookmark != null && bookmark.isNotEmpty) {
        accessed = await DesktopDrop.instance.startAccessingSecurityScopedResource(bookmark: bookmark);
        if (!accessed) continue;
      }
      final length = await file.length();
      if (length <= 0 || length > maximumBytes) continue;
      final name = p.basename(file.name).replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
      final destination = p.join(
        targetDirectory.path,
        '${batchPrefix}_$name',
      );
      await file.saveTo(destination);
      staged.add(destination);
    } catch (error, stackTrace) {
      appLogger.w('Could not stage dropped subtitle', error: error, stackTrace: stackTrace);
    } finally {
      if (accessed && bookmark != null) {
        await DesktopDrop.instance.stopAccessingSecurityScopedResource(bookmark: bookmark);
      }
    }
  }
  await _importSubtitlePaths(context, player, staged);
}

Future<void> _importSharedSubtitleFiles(BuildContext context, Player player) async {
  final paths = await IncomingSubtitleShareService.instance.takeAll();
  await _importSubtitlePaths(context, player, paths);
}

Future<void> _importSubtitlePaths(BuildContext context, Player player, List<String> paths) async {
  if (paths.isEmpty || !context.mounted) return;
  final supported = player.supportedLocalSubtitleExtensions.toList()..sort();
  final candidates = <({String path, String name})>[];
  for (final path in paths) {
    final name = p.basename(path);
    final extension = p.extension(name).toLowerCase().replaceFirst('.', '');
    if (extension == 'zip') {
      final file = File(path);
      final size = await file.length();
      final extracted = await _selectArchivedSubtitle(
        context,
        PlatformFile(name: name, path: path, size: size),
        supported,
      );
      if (extracted != null) candidates.add((path: extracted, name: name));
    } else if (supported.contains(extension)) {
      candidates.add((path: path, name: name));
    }
    if (!context.mounted) return;
  }
  final idxStems = candidates
      .where((candidate) => p.extension(candidate.path).toLowerCase() == '.idx')
      .map((candidate) => p.basenameWithoutExtension(candidate.path).toLowerCase())
      .toSet();
  final subStems = candidates
      .where((candidate) => p.extension(candidate.path).toLowerCase() == '.sub')
      .map((candidate) => p.basenameWithoutExtension(candidate.path).toLowerCase())
      .toSet();
  candidates.removeWhere((candidate) {
    final extension = p.extension(candidate.path).toLowerCase();
    final stem = p.basenameWithoutExtension(candidate.path).toLowerCase();
    if (extension == '.idx') return !subStems.contains(stem);
    return extension == '.sub' && idxStems.contains(stem);
  });
  if (candidates.isEmpty) {
    showErrorSnackBar(context, 'No subtitle in the shared files is supported by this player.');
    return;
  }

  final chosen = candidates.length == 1
      ? candidates.single
      : await showDialog<({String path, String name})>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Choose a subtitle'),
            content: SizedBox(
              width: 520,
              height: 420,
              child: ListView(
                children: [
                  for (final candidate in candidates)
                    ListTile(
                      title: Text(candidate.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(dialogContext).pop(candidate),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.cancel),
              ),
            ],
          ),
        );
  if (chosen == null || !context.mounted) return;
  try {
    await player.command(['sub-add', chosen.path, 'select']);
    if (context.mounted) OverlaySheetController.of(context).close();
  } catch (error, stackTrace) {
    appLogger.w('Could not import shared subtitle', error: error, stackTrace: stackTrace);
    if (context.mounted) showErrorSnackBar(context, t.videoControls.subtitleLoadFailed);
  }
}

Future<String?> _selectArchivedSubtitle(
  BuildContext context,
  PlatformFile pickedFile,
  List<String> supportedExtensions,
) async {
  final bytes = await SubtitleArchiveImporter.readPickedArchive(pickedFile);
  final document = SubtitleArchiveImporter.open(
    bytes,
    supportedExtensions: supportedExtensions.toSet(),
  );
  if (!context.mounted) return null;

  final selected = document.candidates.length == 1
      ? document.candidates.single
      : await showDialog<SubtitleArchiveCandidate>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(t.videoControls.loadSubtitleFile),
            content: SizedBox(
              width: 520,
              height: 420,
              child: ListView.builder(
                itemCount: document.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = document.candidates[index];
                  return ListTile(
                    title: Text(
                      isolateDisplayText(candidate.displayName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(dialogContext).pop(candidate),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.cancel),
              ),
            ],
          ),
        );
  if (selected == null || !context.mounted) return null;
  final paths = await document.materialize(selected);
  if (paths.isEmpty) return null;
  return paths.first;
}
