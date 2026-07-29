part of '../../jellyfin_client.dart';

mixin _JellyfinFileInfoMethods on _JellyfinClientInternals {
  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async {
    // Lightweight browse responses omit `MediaSources`; detail and some cached
    // entries still include them, otherwise fetch the full item on demand.
    final raw = item.raw is Map<String, dynamic> ? item.raw as Map<String, dynamic> : null;
    Map<String, dynamic>? itemJson = raw;
    if (itemJson == null || itemJson['MediaSources'] is! List) {
      final fresh = await fetchItem(item.id);
      itemJson = fresh?.raw is Map<String, dynamic> ? fresh!.raw as Map<String, dynamic> : null;
    }
    if (itemJson == null) return null;
    return parseJellyfinFileInfoFromJson(itemJson);
  }
}

/// Map every `MediaSources` entry of a Jellyfin item response. Jellyfin folds
/// the file into the source, so each version yields exactly one part.
///
/// Pure sibling of [parsePlexFileInfoFromJson]; kept top-level so the mapping
/// is testable without a live client.
MediaFileInfo? parseJellyfinFileInfoFromJson(Map<String, dynamic> json) {
  final sources = json['MediaSources'];
  if (sources is! List || sources.isEmpty) return null;

  final versions = <MediaFileVersion>[];
  for (final source in sources) {
    if (source is! Map<String, dynamic>) continue;
    // One unusable source must not cost the user the others.
    try {
      versions.add(_jellyfinFileVersion(source));
    } catch (error, stackTrace) {
      appLogger.w('Skipping malformed Jellyfin media source', error: error, stackTrace: stackTrace);
    }
  }
  return versions.isEmpty ? null : MediaFileInfo(versions: versions);
}

MediaStreamDetails? _firstStreamOfKind(List<MediaStreamDetails> streams, MediaStreamKind kind) {
  for (final stream in streams) {
    if (stream.kind == kind) return stream;
  }
  return null;
}

MediaFileVersion _jellyfinFileVersion(Map<String, dynamic> source) {
  final streams = _jellyfinStreamDetailList(source['MediaStreams']);
  final video = _firstStreamOfKind(streams, MediaStreamKind.video);
  final audio = _firstStreamOfKind(streams, MediaStreamKind.audio);

  final width = video?.width;
  final height = video?.height;
  final durationMs = jellyfinTicksToMs(flexibleInt(source['RunTimeTicks']));

  return MediaFileVersion(
    id: _jellyfinText(source['Id']),
    title: _jellyfinText(source['Name']),
    container: _jellyfinText(source['Container']),
    // Jellyfin reports bitrates in bps; the app standard is kbps.
    bitrateKbps: bitrateKbpsFromBps(flexibleInt(source['Bitrate'])),
    durationMs: durationMs,
    width: width,
    height: height,
    aspectRatio: _jellyfinAspectRatio(video?.aspectRatio, width, height),
    videoResolutionLabel: resolutionLabelFromDimensions(width, height),
    videoCodec: video?.codec,
    videoProfile: video?.profile,
    videoFrameRateLabel: video?.frameRateFormatted,
    audioCodec: audio?.codec,
    audioProfile: audio?.profile,
    audioChannels: audio?.channels,
    protocol: _jellyfinText(source['Protocol']),
    videoType: _jellyfinText(source['VideoType']),
    sourceType: _jellyfinText(source['Type']),
    isRemote: flexibleBoolNullable(source['IsRemote']),
    isInfiniteStream: flexibleBoolNullable(source['IsInfiniteStream']),
    supportsDirectPlay: flexibleBoolNullable(source['SupportsDirectPlay']),
    supportsDirectStream: flexibleBoolNullable(source['SupportsDirectStream']),
    supportsTranscoding: flexibleBoolNullable(source['SupportsTranscoding']),
    eTag: _jellyfinText(source['ETag']),
    transportStreamTimestamp: _jellyfinText(source['Timestamp']),
    defaultAudioStreamIndex: flexibleInt(source['DefaultAudioStreamIndex']),
    defaultSubtitleStreamIndex: flexibleInt(source['DefaultSubtitleStreamIndex']),
    parts: [
      MediaFilePart(
        id: _jellyfinText(source['Id']),
        filePath: _jellyfinText(source['Path']),
        fileSize: flexibleInt(source['Size']),
        container: _jellyfinText(source['Container']),
        durationMs: durationMs,
        streams: streams,
      ),
    ],
    attachments: _jellyfinAttachmentList(source['MediaAttachments']),
  );
}

/// Prefer the server's declared display ratio (`2.35:1`), falling back to the
/// probed dimensions.
double? _jellyfinAspectRatio(String? declared, int? width, int? height) {
  if (declared != null && declared.contains(':')) {
    final parts = declared.split(':');
    final numerator = flexibleDouble(parts.first);
    final denominator = flexibleDouble(parts[1]);
    if (numerator != null && denominator != null && denominator != 0) return numerator / denominator;
  }
  if (width != null && height != null && height != 0) return width / height;
  return null;
}

/// Trim and drop empties; tolerate a server that sends a non-string scalar.
String? _jellyfinText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<MediaStreamDetails> _jellyfinStreamDetailList(Object? rawStreams) {
  if (rawStreams is! List) return const [];
  final streams = <MediaStreamDetails>[];
  final ordinals = <MediaStreamKind, int>{};
  for (final raw in rawStreams) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      final kind = jellyfinStreamKind(raw);
      final ordinal = (ordinals[kind] ?? 0) + 1;
      ordinals[kind] = ordinal;
      streams.add(jellyfinStreamDetails(raw, ordinal));
    } catch (error, stackTrace) {
      appLogger.w('Skipping malformed Jellyfin stream metadata', error: error, stackTrace: stackTrace);
    }
  }
  return streams;
}

List<MediaFileAttachment> _jellyfinAttachmentList(Object? rawAttachments) {
  if (rawAttachments is! List) return const [];
  final attachments = <MediaFileAttachment>[];
  for (final raw in rawAttachments) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      attachments.add(jellyfinAttachment(raw));
    } catch (error, stackTrace) {
      appLogger.w('Skipping malformed Jellyfin attachment metadata', error: error, stackTrace: stackTrace);
    }
  }
  return attachments;
}
