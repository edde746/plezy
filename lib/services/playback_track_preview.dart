import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../mpv/mpv.dart';
import 'playback_subtitle_resolver.dart';
import 'track_selection_service.dart';

/// What the player will do with an item's tracks, decided before playback by
/// the same selection ladder the player runs ([TrackSelectionService]) over
/// the same [MediaSourceInfo] playback consumes. Two ladder inputs are
/// genuinely unknowable here — a manual choice carried from a previous
/// episode, and a Plex transcode decision — everything else is the real thing.
class PlaybackTrackPreview {
  /// The source's audio and subtitle rows, as the player will see them.
  final MediaSourceInfo source;

  /// The audio row the ladder picks; null when the file carries no audio rows.
  final MediaAudioTrack? audio;

  /// The subtitle row the ladder picks; null means subtitles start off.
  final MediaSubtitleTrack? subtitle;

  const PlaybackTrackPreview({required this.source, required this.audio, required this.subtitle});
}

/// Whether [source] carries any audio or subtitle row. A cached source can
/// come back empty for a file the server has not probed; a preview built on
/// it would announce "Off" for tracks the file may well have.
bool mediaSourceHasTrackRows(MediaSourceInfo source) =>
    source.audioTracks.isNotEmpty || source.subtitleTracks.isNotEmpty;

/// Run the player's selection ladder for [item] over [source] ahead of
/// playback — the [MediaSourceInfo] the backend mapped for the version Play
/// will start, so the preview and the player read one set of rows and one
/// set of server defaults.
///
/// The ladder ranks the same source-derived descriptors
/// ([PlaybackSubtitleResolver.audioTracksForSource] and
/// [PlaybackSubtitleResolver.subtitleTrackForSource]) the playback resolver
/// ranks before the native player has produced its tracks.
///
/// Returns null when [source] has no track rows (see
/// [mediaSourceHasTrackRows]) — the caller shows nothing rather than a guess.
PlaybackTrackPreview? previewPlaybackTracks(MediaItem item, MediaSourceInfo source, {MediaServerUserProfile? profile}) {
  if (!mediaSourceHasTrackRows(source)) return null;
  final service = TrackSelectionService(profileSettings: profile, metadata: item, plexMediaInfo: source);

  final audioResult = service.selectAudioTrack(PlaybackSubtitleResolver.audioTracksForSource(source), null);
  final audio = audioResult == null ? null : _sourceAudioRow(source, audioResult.track);
  final subtitleResult = service.selectSubtitleTrack(
    [for (final row in source.subtitleTracks) PlaybackSubtitleResolver.subtitleTrackForSource(row)],
    null,
    audioResult?.track,
    waitForPendingSource: false,
  );
  final subtitle = subtitleResult == null ? null : _sourceSubtitleRow(source, subtitleResult.track);

  return PlaybackTrackPreview(source: source, audio: audio, subtitle: subtitle);
}

int? _sourceIdOf(String trackId) {
  const prefix = 'source:';
  return trackId.startsWith(prefix) ? int.tryParse(trackId.substring(prefix.length)) : null;
}

MediaAudioTrack? _sourceAudioRow(MediaSourceInfo source, AudioTrack track) {
  final id = _sourceIdOf(track.id);
  if (id == null) return null;
  for (final row in source.audioTracks) {
    if (row.id == id) return row;
  }
  return null;
}

MediaSubtitleTrack? _sourceSubtitleRow(MediaSourceInfo source, SubtitleTrack track) {
  final id = _sourceIdOf(track.id);
  if (id == null) return null;
  for (final row in source.subtitleTracks) {
    if (row.id == id) return row;
  }
  return null;
}
