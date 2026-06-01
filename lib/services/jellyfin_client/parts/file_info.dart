part of '../../jellyfin_client.dart';

mixin _JellyfinFileInfoMethods on MediaServerCacheMixin {
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
    return _buildFileInfoFromJellyfinItem(itemJson);
  }

  MediaFileInfo? _buildFileInfoFromJellyfinItem(Map<String, dynamic> json) {
    final sources = json['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final source = sources.first;
    if (source is! Map<String, dynamic>) return null;

    final parsed = walkStreams(source['MediaStreams'] as List?, const JellyfinFileInfoStreamReader());
    final videoStream = parsed.videoStream;
    final audioStream = parsed.audioStream;
    final audioTracks = parsed.audioTracks;
    final subtitleTracks = parsed.subtitleTracks;

    final width = videoStream?['Width'] as int?;
    final height = videoStream?['Height'] as int?;
    final aspectRatioString = videoStream?['AspectRatio'] as String?;
    double? aspectRatio;
    if (aspectRatioString != null && aspectRatioString.contains(':')) {
      final parts = aspectRatioString.split(':');
      final num = double.tryParse(parts.first);
      final den = double.tryParse(parts[1]);
      if (num != null && den != null && den != 0) aspectRatio = num / den;
    }
    aspectRatio ??= (width != null && height != null && height != 0) ? width / height : null;

    final runtimeTicks = source['RunTimeTicks'] as int?;
    final durationMs = runtimeTicks != null ? (runtimeTicks ~/ 10_000) : null;

    final bitrateBps = source['Bitrate'] as int?;
    final videoBitrateBps = videoStream?['BitRate'] as int?;

    return MediaFileInfo(
      container: source['Container'] as String?,
      videoCodec: videoStream?['Codec'] as String?,
      videoResolution: resolutionLabelFromDimensions(width, height),
      videoFrameRate: videoStream?['RealFrameRate']?.toString() ?? videoStream?['AverageFrameRate']?.toString(),
      videoProfile: videoStream?['Profile'] as String?,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      // Plex stores bitrate as kbps; Jellyfin returns bps. Normalise to kbps.
      bitrate: bitrateBps != null ? bitrateBps ~/ 1000 : null,
      duration: durationMs,
      audioCodec: audioStream?['Codec'] as String?,
      audioProfile: audioStream?['Profile'] as String?,
      audioChannels: audioStream?['Channels'] as int?,
      filePath: source['Path'] as String?,
      fileSize: source['Size'] as int?,
      colorSpace: videoStream?['ColorSpace'] as String?,
      colorRange: videoStream?['ColorRange'] as String?,
      colorPrimaries: videoStream?['ColorPrimaries'] as String?,
      chromaSubsampling: null,
      frameRate:
          (videoStream?['RealFrameRate'] as num?)?.toDouble() ?? (videoStream?['AverageFrameRate'] as num?)?.toDouble(),
      bitDepth: videoStream?['BitDepth'] as int?,
      videoBitrate: videoBitrateBps != null ? videoBitrateBps ~/ 1000 : null,
      audioChannelLayout: audioStream?['ChannelLayout'] as String?,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
    );
  }
}
