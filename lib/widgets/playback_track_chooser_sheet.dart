import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_source_info.dart';
import '../mpv/mpv.dart';
import '../services/playback_subtitle_resolver.dart';
import '../services/playback_track_preview.dart';
import 'video_controls/helpers/track_selection_helper.dart';
import 'video_controls/sheets/base_video_control_sheet.dart';
import 'video_controls/sheets/sheet_selection_column.dart';
import 'video_controls/sheets/sheet_split_columns.dart';

/// Pre-play audio and subtitle picker for a detail screen: the same two
/// columns the player's track sheet shows, over the server's stream rows
/// instead of the live player's. Picking a row does not close the sheet —
/// both columns are usually visited — it reports the new choice through
/// [onChanged]; the caller keeps it and hands it to Play as the player's
/// highest-priority preference.
class PlaybackTrackChooserSheet extends StatefulWidget {
  final MediaSourceInfo source;

  /// The rows the ladder currently lands on, so the sheet opens with the
  /// effective selection marked even before the viewer has chosen anything.
  final MediaAudioTrack? effectiveAudio;
  final MediaSubtitleTrack? effectiveSubtitle;
  final PlaybackTrackChoice choice;
  final ValueChanged<PlaybackTrackChoice> onChanged;

  const PlaybackTrackChooserSheet({
    super.key,
    required this.source,
    required this.effectiveAudio,
    required this.effectiveSubtitle,
    required this.choice,
    required this.onChanged,
  });

  @override
  State<PlaybackTrackChooserSheet> createState() => _PlaybackTrackChooserSheetState();
}

class _PlaybackTrackChooserSheetState extends State<PlaybackTrackChooserSheet> {
  late int? _audioId = widget.effectiveAudio?.id;

  /// Null while subtitles start off.
  late int? _subtitleId = widget.effectiveSubtitle?.id;
  late PlaybackTrackChoice _choice = widget.choice;

  void _pickAudio(MediaAudioTrack row) {
    setState(() {
      _audioId = row.id;
      _choice = _choice.copyWith(audio: PlaybackSubtitleResolver.audioTrackForSource(row));
    });
    widget.onChanged(_choice);
  }

  void _pickSubtitle(MediaSubtitleTrack? row) {
    setState(() {
      _subtitleId = row?.id;
      _choice = _choice.copyWith(
        subtitle: row == null ? SubtitleTrack.off : PlaybackSubtitleResolver.subtitleTrackForSource(row),
      );
    });
    widget.onChanged(_choice);
  }

  @override
  Widget build(BuildContext context) {
    final audioRows = widget.source.audioTracks;
    final subtitleRows = widget.source.subtitleTracks;
    final showAudio = audioRows.length > 1;
    final showSubtitles = subtitleRows.isNotEmpty;
    // Focus opens on the row the ladder chose — the effective subtitle row
    // when subtitles are offered, else the effective audio row — not on the
    // first row, which the initial scroll may have pushed out of view. Bound
    // once, at open: the autofocus must not hop rows as the pick changes.
    final initialAudioId = widget.effectiveAudio?.id;
    final initialSubtitleId = widget.effectiveSubtitle?.id;

    final audioColumn = SheetSelectionColumn(
      headerLabel: showSubtitles ? t.videoControls.audioLabel : null,
      itemCount: audioRows.length,
      initialIndex: audioRows.indexWhere((row) => row.id == _audioId),
      itemBuilder: (context, index, scope) {
        final row = audioRows[index];
        return TrackSelectionHelper.buildTrackTile(
          context: context,
          key: scope.keyFor(index),
          autofocus: !showSubtitles && row.id == initialAudioId,
          label: row.label,
          isSelected: row.id == _audioId,
          onTap: () => _pickAudio(row),
        );
      },
    );

    // Row 0 is Off; source rows follow in server order.
    final subtitleColumn = SheetSelectionColumn(
      headerLabel: showAudio ? t.videoControls.subtitlesLabel : null,
      itemCount: subtitleRows.length + 1,
      initialIndex: _subtitleId == null ? 0 : subtitleRows.indexWhere((row) => row.id == _subtitleId) + 1,
      itemBuilder: (context, index, scope) {
        if (index == 0) {
          return TrackSelectionHelper.buildOffTile(
            context: context,
            key: scope.keyFor(index),
            autofocus: initialSubtitleId == null,
            isSelected: _subtitleId == null,
            onTap: () => _pickSubtitle(null),
          );
        }
        final row = subtitleRows[index - 1];
        return TrackSelectionHelper.buildTrackTile(
          context: context,
          key: scope.keyFor(index),
          autofocus: row.id == initialSubtitleId,
          label: row.labelForIndex(index - 1),
          isSelected: row.id == _subtitleId,
          onTap: () => _pickSubtitle(row),
        );
      },
    );

    final Widget body;
    if (showAudio && showSubtitles) {
      body = SheetSplitColumns(
        start: FocusTraversalGroup(child: audioColumn),
        end: FocusTraversalGroup(child: subtitleColumn),
      );
    } else if (showAudio) {
      body = audioColumn;
    } else {
      body = subtitleColumn;
    }

    return BaseVideoControlSheet(title: t.videoControls.tracksButton, icon: Symbols.subtitles_rounded, child: body);
  }
}
