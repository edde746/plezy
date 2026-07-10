import '../media/media_item.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/audio_quality_preset.dart';
import '../models/transcode_quality_preset.dart';
import '../mpv/mpv.dart';

/// Inputs for [MediaServerClient.getPlaybackInitialization]. Most fields
/// are backend-specific knobs (transcode preset, audio stream, session ids).
class PlaybackInitializationOptions {
  /// The item to play.
  final MediaItem metadata;

  /// Picks among multiple `MediaSources[]` versions when an item has them.
  final int selectedMediaIndex;

  /// Stable backend source id for the selected media version. Jellyfin merged
  /// versions can reorder between item fetches, so this wins over index there.
  final String? selectedMediaSourceId;

  /// Version signature ("res:codec:container") of a saved preference whose
  /// [selectedMediaIndex] is a guess (stored index, or resolved on another
  /// episode's version list). Backends re-match it against the authoritative
  /// list. Never set alongside an explicit user selection — the priority is
  /// sourceId > signature > index > backend fallback.
  final String? preferredVersionSignature;

  /// Transcode preset. `original` means direct-play; anything else asks the
  /// server to transcode when supported.
  final TranscodeQualityPreset qualityPreset;

  /// Music transcode preset, consulted only when [metadata] is a
  /// [MediaKind.track]. `original` (or null) direct-plays; anything else asks
  /// for a bitrate-capped audio transcode. [qualityPreset] is ignored for
  /// tracks — video presets are resolution-shaped.
  final AudioQualityPreset? audioQualityPreset;

  /// Audio stream id forwarded to the transcoder. `null` means "let the
  /// server pick".
  final int? selectedAudioStreamId;

  /// Plex transcode `X-Plex-Session-Identifier`. Required for Plex transcode.
  final String? sessionIdentifier;

  /// Plex transcode `playSessionId`. Same as [sessionIdentifier] — required
  /// for Plex transcode.
  final String? transcodeSessionId;

  const PlaybackInitializationOptions({
    required this.metadata,
    required this.selectedMediaIndex,
    this.selectedMediaSourceId,
    this.preferredVersionSignature,
    this.qualityPreset = TranscodeQualityPreset.original,
    this.audioQualityPreset,
    this.selectedAudioStreamId,
    this.sessionIdentifier,
    this.transcodeSessionId,
  });
}

/// Reason the transcode branch fell back to direct play.
enum TranscodeFallbackReason {
  /// Plex decision said only direct-play is available.
  directPlayOnly,

  /// The decision endpoint errored (HTTP error, code >= 2000, parse failure).
  decisionFailed,
}

/// Result of playback initialization
class PlaybackInitializationResult {
  final List<MediaVersion> availableVersions;
  final String? videoUrl;
  final MediaSourceInfo? mediaInfo;
  final List<SubtitleTrack> externalSubtitles;
  final bool isOffline;

  /// `true` when [videoUrl] points at a backend transcoding stream.
  final bool isTranscoding;

  /// Non-null when a non-original preset was requested but fallback kicked in.
  final TranscodeFallbackReason? fallbackReason;

  /// Source audio stream ID selected by the backend (`null` when unknown).
  final int? activeAudioStreamId;

  /// Server playback session ID that must be echoed in progress/stop reports.
  /// Jellyfin returns this from `PlaybackInfo` / `TranscodingUrl`.
  final String? playSessionId;

  /// Backend playback method value to report with playback progress. Jellyfin
  /// expects one of `DirectPlay`, `DirectStream`, or `Transcode`.
  final String? playMethod;

  /// Effective media version after backend clamping/fallback.
  final int selectedMediaIndex;

  /// Stable source id of the effective media version, when known without a
  /// version list. Set by the offline path (where [availableVersions] is
  /// empty) so the session reflects the downloaded version actually played,
  /// even when it differs from the requested one. Online backends leave this
  /// null and the id is derived from [availableVersions] instead.
  final String? selectedMediaSourceId;

  /// True when [videoUrl] points at a downloaded/local copy. This is a media
  /// source detail, not a statement about whether server reporting is possible.
  bool get usesLocalMedia => isOffline;

  /// The [MediaVersion] selected by [selectedMediaIndex], or null when no
  /// version metadata is available (e.g. cached offline flows).
  MediaVersion? get selectedVersion => selectedMediaIndex >= 0 && selectedMediaIndex < availableVersions.length
      ? availableVersions[selectedMediaIndex]
      : null;

  PlaybackInitializationResult({
    required this.availableVersions,
    this.videoUrl,
    this.mediaInfo,
    this.externalSubtitles = const [],
    this.isOffline = false,
    this.isTranscoding = false,
    this.fallbackReason,
    this.activeAudioStreamId,
    this.playSessionId,
    this.playMethod,
    this.selectedMediaIndex = 0,
    this.selectedMediaSourceId,
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
