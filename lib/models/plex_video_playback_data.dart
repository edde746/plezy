import 'plex_media_info.dart';
import 'plex_media_version.dart';

/// Consolidated data model containing all information needed for video playback.
/// This model combines data from multiple Plex API endpoints to reduce redundant requests.
class PlexVideoPlaybackData {
  /// Direct video URL for playback
  final String? videoUrl;

  /// Media information including audio/subtitle tracks and chapters
  final PlexMediaInfo? mediaInfo;

  /// Available media versions/qualities for this content
  final List<PlexMediaVersion> availableVersions;

  PlexVideoPlaybackData({
    required this.videoUrl,
    required this.mediaInfo,
    required this.availableVersions,
  });

  /// Returns true if this playback data has a valid video URL
  bool get hasValidVideoUrl => videoUrl != null && videoUrl!.isNotEmpty;

  /// Returns true if media info is available
  bool get hasMediaInfo => mediaInfo != null;

  /// Returns true if there are multiple media versions available
  bool get hasMultipleVersions => availableVersions.length > 1;
}
