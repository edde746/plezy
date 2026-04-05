import 'plex_media_info.dart';
import 'plex_playback_quality.dart';
import 'plex_playback_session.dart';
import 'plex_media_version.dart';

/// Consolidated data model containing all information needed for video playback.
/// This model combines data from multiple Plex API endpoints to reduce redundant requests.
class PlexVideoPlaybackData {
  /// Direct video URL for playback
  final String? videoUrl;

  /// Session details for the chosen playback route (direct play, direct stream, transcode)
  final PlexPlaybackSession? playbackSession;

  /// Media information including audio/subtitle tracks and chapters
  final PlexMediaInfo? mediaInfo;

  /// Available media versions/qualities for this content
  final List<PlexMediaVersion> availableVersions;

  /// Markers for intro/credits skip functionality
  final List<PlexMarker> markers;

  /// Quality choices supported by the current Plex server for this item
  final List<PlexPlaybackQualityOption> qualityOptions;

  /// The quality used to produce [videoUrl] / [playbackSession]
  final PlexPlaybackQualityOption? selectedQuality;

  PlexVideoPlaybackData({
    required this.videoUrl,
    this.playbackSession,
    required this.mediaInfo,
    required this.availableVersions,
    this.markers = const [],
    this.qualityOptions = const [],
    this.selectedQuality,
  });

  /// Returns true if this playback data has a valid video URL
  bool get hasValidVideoUrl => effectiveVideoUrl != null && effectiveVideoUrl!.isNotEmpty;

  /// The effective playback URL, preferring the active playback session when present.
  String? get effectiveVideoUrl => playbackSession?.streamUrl ?? videoUrl;

  /// Returns true if media info is available
  bool get hasMediaInfo => mediaInfo != null;
}
