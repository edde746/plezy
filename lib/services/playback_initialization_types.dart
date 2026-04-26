import '../media/media_item.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/transcode_quality_preset.dart';
import '../mpv/mpv.dart';

/// Inputs for [MediaServerClient.getPlaybackInitialization]. Most fields
/// are backend-specific knobs (transcode preset, audio stream, session ids).
class PlaybackInitializationOptions {
  /// The item to play.
  final MediaItem metadata;

  /// Picks among multiple `MediaSources[]` versions when an item has them.
  final int selectedMediaIndex;

  /// Transcode preset. `original` means direct-play; anything else asks the
  /// server to transcode when supported.
  final TranscodeQualityPreset qualityPreset;

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
    this.qualityPreset = TranscodeQualityPreset.original,
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

  /// `true` when [videoUrl] is a Plex transcode start URL.
  final bool isTranscoding;

  /// Non-null when a non-original preset was requested but fallback kicked in.
  final TranscodeFallbackReason? fallbackReason;

  /// The Plex audio stream ID actually passed to the transcoder (`null` when
  /// not transcoding or when no audio stream was selectable).
  final int? activeAudioStreamId;

  /// Server playback session ID that must be echoed in progress/stop reports.
  /// Jellyfin returns this from `PlaybackInfo` / `TranscodingUrl`.
  final String? playSessionId;

  /// Backend playback method value to report with playback progress. Jellyfin
  /// expects one of `DirectPlay`, `DirectStream`, or `Transcode`.
  final String? playMethod;

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
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
