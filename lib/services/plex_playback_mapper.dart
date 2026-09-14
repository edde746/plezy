import '../media/media_file_info.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/plex/plex_video_playback_data.dart';
import '../utils/app_logger.dart';
import '../utils/json_utils.dart';
import '../utils/plex_url_helper.dart';
import 'file_info_parser.dart';
import 'plex_mappers.dart';

void _logMalformedStream(Object error, StackTrace stackTrace, Map<String, dynamic> _) {
  appLogger.w('Skipping malformed Plex stream metadata', error: error, stackTrace: stackTrace);
}

List<Map> _mapList(Object? raw) {
  final values = flexibleList(raw);
  if (values == null || values.isEmpty) return const [];
  return [
    for (final value in values)
      if (value is Map) value,
  ];
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
  String? selectedMediaSourceId,
  String? preferredVersionSignature,
  void Function(int requestedIndex, int fallbackIndex)? onVersionFallback,
}) {
  String? videoUrl;
  MediaSourceInfo? mediaInfo;
  List<MediaVersion> availableVersions = [];
  var selectedMediaIndex = 0;
  var selectedPartIndex = 0;

  if (metadataJson != null) {
    final selection = resolvePlexPlaybackSelection(
      metadataJson,
      mediaIndex: mediaIndex,
      mediaSourceId: selectedMediaSourceId,
      preferredVersionSignature: preferredVersionSignature,
      onVersionFallback: onVersionFallback,
    );
    if (selection != null) {
      availableVersions = selection.versions;
      selectedMediaIndex = selection.mediaIndex;
      selectedPartIndex = selection.partIndex;
      final partList = _mapList(selection.media[selectedMediaIndex]['Part']);
      if (partList.isNotEmpty) {
        _logPartSelection(selection.media, availableVersions, selectedMediaIndex, selectedPartIndex);
        final partKey = partList[selectedPartIndex]['key']?.toString();
        if (partKey != null) {
          videoUrl = '$baseUrl$partKey'.withPlexToken(token);
          mediaInfo = plexMediaSourceInfoForSelection(metadataJson, selection, videoUrl: videoUrl);
        }
      }
    }
  }

  return PlexVideoPlaybackData(
    videoUrl: videoUrl,
    mediaInfo: mediaInfo,
    availableVersions: availableVersions,
    selectedMediaIndex: selectedMediaIndex,
    selectedPartIndex: selectedPartIndex,
  );
}

/// Build the file-info payload from a `/library/metadata/{id}` response.
///
/// Every `Media` (version) and every `Part` (file) is mapped — split files and
/// multi-version libraries both produce more than one, and the sheet shows all
/// of them.
MediaFileInfo? parsePlexFileInfoFromJson(Map<String, dynamic>? metadataJson) {
  final mediaList = _mapList(metadataJson?['Media']);
  if (mediaList.isEmpty) return null;

  final versions = <MediaFileVersion>[
    for (final media in mediaList) _plexFileVersion(Map<String, dynamic>.from(media)),
  ];
  return MediaFileInfo(versions: versions);
}

/// `Media.proxyType` value Plex uses for an optimized version.
const _plexOptimizedProxyType = 42;

DateTime? _plexEpochSeconds(Object? value) {
  final seconds = flexibleInt(value);
  return seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

MediaFileVersion _plexFileVersion(Map<String, dynamic> media) {
  return MediaFileVersion(
    id: media['id']?.toString(),
    title: media['title'] as String?,
    container: media['container'] as String?,
    bitrateKbps: flexibleInt(media['bitrate']),
    durationMs: flexibleInt(media['duration']),
    width: flexibleInt(media['width']),
    height: flexibleInt(media['height']),
    aspectRatio: flexibleDouble(media['aspectRatio']),
    videoResolutionLabel: media['videoResolution'] as String?,
    videoCodec: media['videoCodec'] as String?,
    videoProfile: media['videoProfile'] as String?,
    videoFrameRateLabel: media['videoFrameRate'] as String?,
    audioCodec: media['audioCodec'] as String?,
    audioProfile: media['audioProfile'] as String?,
    audioChannels: flexibleInt(media['audioChannels']),
    optimizedForStreaming: flexibleBoolNullable(media['optimizedForStreaming']),
    has64bitOffsets: flexibleBoolNullable(media['has64bitOffsets']),
    // Plex marks a server-generated optimized copy with proxyType 42 and
    // names the profile that produced it in `target`.
    isOptimizedVersion: media['proxyType'] == null ? null : flexibleInt(media['proxyType']) == _plexOptimizedProxyType,
    optimizationTarget: media['target'] as String?,
    deletedAt: _plexEpochSeconds(media['deletedAt']),
    displayOffsetPercent: flexibleInt(media['displayOffset']),
    parts: [for (final part in _mapList(media['Part'])) _plexFilePart(Map<String, dynamic>.from(part))],
  );
}

MediaFilePart _plexFilePart(Map<String, dynamic> part) {
  return MediaFilePart(
    id: part['id']?.toString(),
    filePath: part['file'] as String?,
    fileSize: flexibleInt(part['size']),
    container: part['container'] as String?,
    durationMs: flexibleInt(part['duration']),
    optimizedForStreaming: flexibleBoolNullable(part['optimizedForStreaming']),
    has64bitOffsets: flexibleBoolNullable(part['has64bitOffsets']),
    hasThumbnail: flexibleBoolNullable(part['hasThumbnail']),
    indexes: part['indexes'] as String?,
    packetLength: flexibleInt(part['packetLength']),
    previewFailureCode: flexibleInt(part['failureBIFResultCode']),
    previewRetryCount: flexibleInt(part['failureBIFRetryCount']),
    exists: flexibleBoolNullable(part['exists']),
    accessible: flexibleBoolNullable(part['accessible']),
    streamKey: part['key'] as String?,
    streams: _plexStreamDetails(part['Stream']),
  );
}

/// One malformed stream must not discard the rest of the table, so each entry
/// is projected independently.
List<MediaStreamDetails> _plexStreamDetails(Object? rawStreams) {
  final streams = <MediaStreamDetails>[];
  final ordinals = <MediaStreamKind, int>{};
  for (final raw in _mapList(rawStreams)) {
    try {
      final stream = Map<String, dynamic>.from(raw);
      final kind = plexStreamKind(stream);
      final ordinal = (ordinals[kind] ?? 0) + 1;
      ordinals[kind] = ordinal;
      streams.add(plexStreamDetails(stream, ordinal));
    } catch (error, stackTrace) {
      _logMalformedStream(error, stackTrace, const <String, dynamic>{});
    }
  }
  return streams;
}
