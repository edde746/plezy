import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../media/media_stream.dart';
import '../media/media_version.dart';
import '../mpv/mpv.dart';
import 'playback_subtitle_resolver.dart';
import 'track_selection_service.dart';

/// What the player will do with an item's tracks, decided before playback by
/// the same selection ladder the player runs ([TrackSelectionService]) over
/// the server's own stream rows. Two ladder inputs are genuinely unknowable
/// here — a manual choice carried from a previous episode, and a Plex
/// transcode decision — everything else is the real thing.
class PlaybackTrackPreview {
  final MediaVersion version;

  /// The version's audio and subtitle rows, as the player will see them.
  final MediaSourceInfo source;

  /// The audio row the ladder picks; null when the file carries no audio rows.
  final MediaAudioTrack? audio;

  /// The subtitle row the ladder picks; null means subtitles start off.
  final MediaSubtitleTrack? subtitle;

  const PlaybackTrackPreview({
    required this.version,
    required this.source,
    required this.audio,
    required this.subtitle,
  });
}

/// Whether [version] carries per-stream rows. Plex listings sometimes describe
/// a file only by its container summary (`Media.audioCodec`); those synthetic
/// rows have no stream index and no per-track identity, so a preview built on
/// them would name tracks the file does not have.
bool mediaVersionHasProbedStreams(MediaVersion version) {
  for (final part in version.parts) {
    for (final stream in part.streams) {
      if ((stream.kind == MediaStreamKind.audio || stream.kind == MediaStreamKind.subtitle) && stream.index != null) {
        return true;
      }
    }
  }
  return false;
}

/// The audio and subtitle rows of [version] in the shape the playback pipeline
/// uses, plus the player-side descriptors the ladder ranks. Null when the
/// version has no probed streams (see [mediaVersionHasProbedStreams]).
///
/// The descriptors' `isDefault` is the container's own flag, which is what
/// the player sees on its native tracks; the server's `selected` rides on the
/// rows, where the ladder's server-selected tier reads it.
_VersionTracks? _versionTracks(MediaVersion version) {
  if (!mediaVersionHasProbedStreams(version)) return null;

  final audioRows = <MediaAudioTrack>[];
  final subtitleRows = <MediaSubtitleTrack>[];
  final audioTracks = <AudioTrack>[];
  final subtitleTracks = <SubtitleTrack>[];
  for (final part in version.parts) {
    for (final stream in part.streams) {
      final id = int.tryParse(stream.id) ?? stream.index;
      if (id == null) continue;
      switch (stream.kind) {
        case MediaStreamKind.audio:
          final row = MediaAudioTrack(
            id: id,
            index: stream.index,
            codec: stream.codec,
            language: stream.language,
            languageCode: stream.languageCode,
            title: stream.title,
            displayTitle: stream.displayTitle,
            channels: stream.channels,
            selected: stream.selected,
          );
          audioRows.add(row);
          audioTracks.add(PlaybackSubtitleResolver.audioTrackForSource(row).copyWith(isDefault: stream.isDefault));
        case MediaStreamKind.subtitle:
          final row = MediaSubtitleTrack(
            id: id,
            index: stream.index,
            codec: stream.codec,
            language: stream.language,
            languageCode: stream.languageCode,
            title: stream.title,
            displayTitle: stream.displayTitle,
            selected: stream.selected,
            forced: stream.forced,
            key: stream.sidecarPath,
            external: stream.isExternal,
          );
          subtitleRows.add(row);
          subtitleTracks.add(
            PlaybackSubtitleResolver.subtitleTrackForSource(row).copyWith(isDefault: stream.isDefault),
          );
        case MediaStreamKind.video:
        case MediaStreamKind.image:
        case MediaStreamKind.data:
        case MediaStreamKind.lyric:
        case MediaStreamKind.unknown:
          break;
      }
    }
  }
  return _VersionTracks(
    source: MediaSourceInfo(videoUrl: '', audioTracks: audioRows, subtitleTracks: subtitleRows, chapters: const []),
    audioTracks: audioTracks,
    subtitleTracks: subtitleTracks,
  );
}

class _VersionTracks {
  final MediaSourceInfo source;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;

  const _VersionTracks({required this.source, required this.audioTracks, required this.subtitleTracks});
}

/// Run the player's selection ladder for [item] ahead of playback.
///
/// Returns null when [item] has no version at [versionIndex] or the version
/// has no probed streams — the caller shows nothing rather than a guess.
PlaybackTrackPreview? previewPlaybackTracks(MediaItem item, {int versionIndex = 0, MediaServerUserProfile? profile}) {
  final versions = item.mediaVersions;
  if (versions == null || versions.isEmpty) return null;
  final version = versionIndex >= 0 && versionIndex < versions.length ? versions[versionIndex] : versions.first;
  final tracks = _versionTracks(version);
  if (tracks == null) return null;
  final source = tracks.source;
  final service = TrackSelectionService(profileSettings: profile, metadata: item, plexMediaInfo: source);

  final audioResult = service.selectAudioTrack(tracks.audioTracks, null);
  final audio = audioResult == null ? null : _sourceAudioRow(source, audioResult.track);
  final subtitleResult = service.selectSubtitleTrack(
    tracks.subtitleTracks,
    null,
    audioResult?.track,
    waitForPendingSource: false,
  );
  final subtitle = subtitleResult == null ? null : _sourceSubtitleRow(source, subtitleResult.track);

  return PlaybackTrackPreview(version: version, source: source, audio: audio, subtitle: subtitle);
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
