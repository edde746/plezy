import '../../media/media_source_info.dart';
import '../../media/media_version.dart';

/// Consolidated data model containing all information needed for video playback.
/// This model combines data from multiple Plex API endpoints to reduce redundant requests.
class PlexVideoPlaybackData {
  final String? videoUrl;

  final MediaSourceInfo? mediaInfo;

  final List<MediaVersion> availableVersions;

  final int selectedMediaIndex;

  final int selectedPartIndex;

  PlexVideoPlaybackData({
    required this.videoUrl,
    required this.mediaInfo,
    required this.availableVersions,
    this.selectedMediaIndex = 0,
    this.selectedPartIndex = 0,
  });

  bool get hasValidVideoUrl => videoUrl != null && videoUrl!.isNotEmpty;
}
