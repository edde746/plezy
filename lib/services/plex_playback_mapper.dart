import '../media/media_file_info.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/plex/plex_video_playback_data.dart';
import '../utils/app_logger.dart';
import '../utils/json_utils.dart';
import '../utils/plex_url_helper.dart';
import 'file_info_parser.dart';
import 'plex_mappers.dart';

const _streamReader = PlexFileInfoStreamReader();

List<Map> _mapList(Object? raw) {
  final values = flexibleList(raw);
  if (values == null || values.isEmpty) return const [];
  return [
    for (final value in values)
      if (value is Map) value,
  ];
}

int _firstPlayablePartIndex(MediaVersion version) {
  final parts = version.parts;
  if (parts.isEmpty) return 0;
  final playable = parts.indexWhere((part) => part.isPlayable);
  return playable >= 0 ? playable : 0;
}

void _logPartSelection(
  List<Map> mediaList,
  List<MediaVersion> versions,
  int selectedMediaIndex,
  int selectedPartIndex,
) {
  final candidateCount = mediaList.fold<int>(0, (count, media) => count + _mapList(media['Part']).length);
  if (candidateCount <= 1) return;

  final entries = <String>[];
  for (var mediaIndex = 0; mediaIndex < mediaList.length; mediaIndex++) {
    final partList = _mapList(mediaList[mediaIndex]['Part']);
    for (var partIndex = 0; partIndex < partList.length; partIndex++) {
      final part = partList[partIndex];
      final versionPart = mediaIndex < versions.length && partIndex < versions[mediaIndex].parts.length
          ? versions[mediaIndex].parts[partIndex]
          : null;
      final selected = mediaIndex == selectedMediaIndex && partIndex == selectedPartIndex ? ' selected' : '';
      entries.add(
        'Media[$mediaIndex].Part[$partIndex] '
        'id=${part['id']} key=${part['key']} '
        'exists=${versionPart?.exists} accessible=${versionPart?.accessible} '
        'playable=${versionPart?.isPlayable}$selected',
      );
    }
  }

  appLogger.d('Plex playback part selection: ${entries.join('; ')}');
}

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
  var selectedMediaIndex = 0;
  var selectedPartIndex = 0;
  final markers = plexMarkersFromCacheJson(metadataJson);

  if (metadataJson != null) {
    final mediaList = _mapList(metadataJson['Media']);
    if (mediaList.isNotEmpty) {
      availableVersions = mediaList
          .map((media) => PlexMappers.mediaVersionFromJson(Map<String, dynamic>.from(media)))
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

      selectedMediaIndex = mediaIndex;
      final media = mediaList[mediaIndex];
      final partList = _mapList(media['Part']);
      if (partList.isNotEmpty) {
        selectedPartIndex = _firstPlayablePartIndex(availableVersions[mediaIndex]);
        if (selectedPartIndex < 0 || selectedPartIndex >= partList.length) selectedPartIndex = 0;
        _logPartSelection(mediaList, availableVersions, selectedMediaIndex, selectedPartIndex);
        final part = partList[selectedPartIndex];
        final partKey = part['key']?.toString();

        if (partKey != null) {
          videoUrl = '$baseUrl$partKey'.withPlexToken(token);

          final streams = walkStreams(flexibleList(part['Stream']), _streamReader);
          final chapters = plexChaptersFromCacheJson(metadataJson);

          mediaInfo = MediaSourceInfo(
            videoUrl: videoUrl,
            audioTracks: streams.audioTracks,
            subtitleTracks: streams.subtitleTracks,
            chapters: chapters,
            partId: flexibleInt(part['id']),
            displayCriteria: PlexMappers.displayCriteriaFromJson(Map<String, dynamic>.from(media), streams.videoStream),
            videoAspectRatio: (media['aspectRatio'] as num?)?.toDouble(),
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
    selectedMediaIndex: selectedMediaIndex,
    selectedPartIndex: selectedPartIndex,
  );
}

MediaFileInfo? parsePlexFileInfoFromJson(Map<String, dynamic>? metadataJson) {
  final mediaList = _mapList(metadataJson?['Media']);
  if (mediaList.isNotEmpty) {
    final media = mediaList[0];
    final partList = _mapList(media['Part']);
    final version = PlexMappers.mediaVersionFromJson(Map<String, dynamic>.from(media));
    final partIndex = partList.isEmpty ? 0 : _firstPlayablePartIndex(version).clamp(0, partList.length - 1).toInt();
    final part = partList.isNotEmpty ? partList[partIndex] : null;

    // One pass over the streams array, capturing both the raw video / audio
    // map pointers (for fields the parsed track classes don't carry —
    // colorSpace, bitDepth, …) and the parsed track lists.
    final parsedTracks = walkStreams(flexibleList(part?['Stream']), _streamReader);
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
