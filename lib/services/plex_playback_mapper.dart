import '../media/media_file_info.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/plex/plex_video_playback_data.dart';
import '../utils/json_utils.dart';
import '../utils/plex_url_helper.dart';
import 'file_info_parser.dart';
import 'plex_mappers.dart';

const _streamReader = PlexFileInfoStreamReader();

PlexVideoPlaybackData parsePlexVideoPlaybackDataFromJson(
  Map<String, dynamic>? metadataJson, {
  required String baseUrl,
  required String? token,
  int mediaIndex = 0,
  void Function(int requestedIndex, int fallbackIndex)? onVersionFallback,
}) {
  String? videoUrl;
  MediaSourceInfo? mediaInfo;
  List<MediaVersion> availableVersions = [];
  final markers = plexMarkersFromCacheJson(metadataJson);

  if (metadataJson != null) {
    if (metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      availableVersions = mediaList
          .map((media) => PlexMappers.mediaVersionFromJson(media as Map<String, dynamic>))
          .toList();

      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      if (!availableVersions[mediaIndex].isPlayable) {
        final fallback = availableVersions.indexWhere((v) => v.isPlayable);
        if (fallback >= 0) {
          onVersionFallback?.call(mediaIndex, fallback);
          mediaIndex = fallback;
        }
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          videoUrl = '$baseUrl$partKey'.withPlexToken(token);

          final streams = walkStreams(part['Stream'] as List<dynamic>?, _streamReader);
          final chapters = plexChaptersFromCacheJson(metadataJson);

          mediaInfo = MediaSourceInfo(
            videoUrl: videoUrl,
            audioTracks: streams.audioTracks,
            subtitleTracks: streams.subtitleTracks,
            chapters: chapters,
            partId: part['id'] as int?,
            frameRate: streams.frameRate,
          );
        }
      }
    }
  }

  return PlexVideoPlaybackData(
    videoUrl: videoUrl,
    mediaInfo: mediaInfo,
    availableVersions: availableVersions,
    markers: markers,
  );
}

MediaFileInfo? parsePlexFileInfoFromJson(Map<String, dynamic>? metadataJson) {
  if (metadataJson != null && metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
    final media = metadataJson['Media'][0];
    final part = media['Part'] != null && (media['Part'] as List).isNotEmpty ? media['Part'][0] : null;

    // One pass over the streams array, capturing both the raw video / audio
    // map pointers (for fields the parsed track classes don't carry —
    // colorSpace, bitDepth, …) and the parsed track lists.
    final parsedTracks = walkStreams(part?['Stream'] as List<dynamic>?, _streamReader);
    final videoStream = parsedTracks.videoStream;
    final audioStream = parsedTracks.audioStream;

    return MediaFileInfo(
      // Media level properties
      container: media['container'] as String?,
      videoCodec: media['videoCodec'] as String?,
      videoResolution: media['videoResolution'] as String?,
      videoFrameRate: media['videoFrameRate'] as String?,
      videoProfile: media['videoProfile'] as String?,
      width: media['width'] as int?,
      height: media['height'] as int?,
      aspectRatio: (media['aspectRatio'] as num?)?.toDouble(),
      bitrate: media['bitrate'] as int?,
      duration: media['duration'] as int?,
      audioCodec: media['audioCodec'] as String?,
      audioProfile: media['audioProfile'] as String?,
      audioChannels: media['audioChannels'] as int?,
      optimizedForStreaming: flexibleBool(media['optimizedForStreaming']),
      has64bitOffsets: flexibleBool(media['has64bitOffsets']),
      // Part level properties (file)
      filePath: part?['file'] as String?,
      fileSize: part?['size'] as int?,
      // Video stream details
      colorSpace: videoStream?['colorSpace'] as String?,
      colorRange: videoStream?['colorRange'] as String?,
      colorPrimaries: videoStream?['colorPrimaries'] as String?,
      chromaSubsampling: videoStream?['chromaSubsampling'] as String?,
      frameRate: (videoStream?['frameRate'] as num?)?.toDouble(),
      bitDepth: videoStream?['bitDepth'] as int?,
      videoBitrate: videoStream?['bitrate'] as int?,
      // Audio stream details
      audioChannelLayout: audioStream?['audioChannelLayout'] as String?,
      // All audio and subtitle tracks
      audioTracks: parsedTracks.audioTracks,
      subtitleTracks: parsedTracks.subtitleTracks,
    );
  }

  return null;
}
