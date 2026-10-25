part of '../../jellyfin_client.dart';

mixin _JellyfinImageDownloadMethods on _JellyfinClientInternals implements ConvertedDownloadClient {
  /// [cover] is accepted for interface parity and ignored: `maxWidth`/
  /// `maxHeight` already scale the long axis to fit inside the box, so
  /// Jellyfin never overshoots the way Plex's `minSize=1` transcode does.
  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    if (path == null || path.isEmpty) return '';
    final uri = JellyfinImageAbsolutizer.joinUri(baseUrl: connection.baseUrl, urlOrPath: path);
    final params = Map<String, String>.from(uri.queryParameters);
    if (width != null && !params.containsKey('maxWidth') && !params.containsKey('MaxWidth')) {
      params['maxWidth'] = '$width';
    }
    if (height != null && !params.containsKey('maxHeight') && !params.containsKey('MaxHeight')) {
      params['maxHeight'] = '$height';
    }
    params.putIfAbsent('api_key', () => connection.accessToken);
    return uri.replace(queryParameters: params).toString();
  }

  /// Jellyfin doesn't expose an external-URL proxy endpoint comparable to
  /// Plex's `/photo/:/transcode?url=...`. External URLs pass through.
  @override
  String externalImageUrl(String url, {int? width, int? height, bool cover = true}) => url;

  /// Build a progressive MKV transcode URL for the selected video version.
  /// Jellyfin and Emby share this endpoint contract; each dialect contributes
  /// its own token query parameter through [buildDirectStreamUrl].
  @visibleForTesting
  String buildConvertedDownloadUrl({
    required String itemId,
    required String mediaSourceId,
    required TranscodeQualityPreset preset,
    required String playSessionId,
  }) {
    final bitrate = preset.videoBitrateKbps;
    if (bitrate == null || preset.isOriginal) {
      throw ArgumentError.value(preset, 'preset', 'Original quality does not require a transcode');
    }

    final uri = Uri.parse(
      buildDirectStreamUrl(
        itemId,
        container: 'mkv',
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
        containerExtension: true,
      ),
    );
    final parameters = Map<String, String>.from(uri.queryParameters)
      ..['Static'] = 'false'
      ..['DeviceId'] = connection.deviceId
      ..['MediaSourceId'] = mediaSourceId
      ..['PlaySessionId'] = playSessionId
      ..['VideoCodec'] = 'h264'
      ..['VideoBitrate'] = '${bitrate * 1000}'
      ..['AudioCodec'] = 'aac'
      ..['AudioBitrate'] = '192000'
      ..['SubtitleMethod'] = 'Embed';
    final maxHeight = preset.resolutionHeight;
    if (maxHeight != null) parameters['MaxHeight'] = '$maxHeight';
    return uri.replace(queryParameters: parameters).toString();
  }

  @override
  Future<ConvertedDownloadState> requestConvertedDownload(
    MediaItem item, {
    required int mediaIndex,
    String? mediaSourceId,
    required TranscodeQualityPreset preset,
  }) async {
    if (!item.kind.isVideo) {
      return const ConvertedDownloadFailed('Only video downloads can be converted');
    }
    final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex, sourceId: mediaSourceId);
    final selectedSourceId = bundle?.pinnedSourceId;
    if (selectedSourceId == null) {
      return const ConvertedDownloadFailed('The server did not identify the selected media source');
    }

    // A stable session id lets the downloader re-resolve the same transcode
    // after a retry instead of creating a new server session on every pass.
    final sessionKey = [
      connection.serverMachineId,
      connection.userId,
      connection.deviceId,
      item.id,
      selectedSourceId,
      preset.name,
    ].join(':');
    final sessionId = crypto.sha256.convert(utf8.encode(sessionKey)).toString().substring(0, 32);
    return ConvertedDownloadReady(
      url: buildConvertedDownloadUrl(
        itemId: item.id,
        mediaSourceId: selectedSourceId,
        preset: preset,
        playSessionId: sessionId,
      ),
      container: 'mkv',
      supportsRangeResume: false,
    );
  }

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async {
    final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex, sourceId: mediaSourceId);
    final selectedSourceId = bundle?.selectedSourceId;
    final requestedSourceId = mediaSourceId?.trim();
    if (requestedSourceId != null &&
        requestedSourceId.isNotEmpty &&
        selectedSourceId?.toLowerCase() != requestedSourceId.toLowerCase()) {
      throw StateError('Requested Jellyfin download source is no longer available');
    }

    // Tracks download from the audio static-stream endpoint and have no
    // subtitle sidecars to enumerate.
    if (item.kind == MediaKind.track) {
      final audioUrl = buildAudioDirectStreamUrl(
        item.id,
        container: bundle?.container,
        mediaSourceId: bundle?.pinnedSourceId,
      );
      return DownloadResolution(videoUrl: audioUrl, mediaSourceId: selectedSourceId, externalSubtitles: const []);
    }

    // Direct-stream the selected original file. Jellyfin's `Static=true`
    // skips the transcoder so the byte-for-byte source lands on disk.
    final videoUrl = buildDirectStreamUrl(item.id, container: bundle?.container, mediaSourceId: bundle?.pinnedSourceId);

    // External subtitle sidecars are listed in the per-source MediaStreams.
    // PlaybackInfo gives us the canonical view including DeliveryUrl when
    // the server has pre-computed one; fall back to the documented stream
    // URL pattern otherwise. Negotiation is enrichment only: the static
    // stream URL above remains valid without it.
    final subtitles = <DownloadSubtitleSpec>[];
    Map<String, dynamic> playbackInfo;
    try {
      playbackInfo = await getPlaybackInfo(item.id, mediaSourceId: selectedSourceId);
    } catch (error, stackTrace) {
      if (!_canUseJellyfinStaticStreamFallback(error)) rethrow;
      appLogger.w(
        'Jellyfin download subtitle enrichment unavailable; using the static stream',
        error: error,
        stackTrace: stackTrace,
      );
      return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitlesResolved: false);
    }

    final source = _selectDownloadMediaSource(playbackInfo['MediaSources'] as List, selectedSourceId, mediaIndex);
    if (source == null) {
      appLogger.w('Jellyfin download subtitle enrichment returned no usable source; using the static stream');
      return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitlesResolved: false);
    }
    if (source['MediaStreams'] is! List) {
      appLogger.w('Jellyfin download subtitle enrichment returned malformed streams; using the static stream');
      return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitlesResolved: false);
    }

    final streams = source['MediaStreams'] as List;
    final rawMediaSourceId = source['Id'];
    if (rawMediaSourceId != null && rawMediaSourceId is! String) {
      appLogger.w('Jellyfin download subtitle enrichment returned an invalid source id; using the static stream');
      return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitlesResolved: false);
    }
    final subtitleMediaSourceId = rawMediaSourceId as String? ?? item.id;
    for (final raw in streams) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['Type'] != 'Subtitle') continue;
      final fields = parseJellyfinStreamFields(raw);
      if (!fields.isExternalFile) continue;
      final index = raw['Index'];
      if (index is! int) continue;
      final codec = fields.codec?.toLowerCase();
      final delivery = fields.deliveryUrl;
      final streamFile = _segment('Stream.${CodecUtils.getSubtitleExtension(codec)}');
      final url = _withApiKey(
        delivery != null && delivery.isNotEmpty
            ? delivery
            : '/Videos/${_segment(item.id)}/${_segment(subtitleMediaSourceId)}/Subtitles/$index/$streamFile',
      );
      subtitles.add(
        DownloadSubtitleSpec(
          id: index,
          url: url,
          codec: codec,
          language: fields.language,
          languageCode: fields.languageCode,
          forced: fields.isForced,
          displayTitle: fields.displayTitle,
        ),
      );
    }

    return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitles: subtitles);
  }

  Map<String, dynamic>? _selectDownloadMediaSource(List<dynamic> sources, String? selectedSourceId, int mediaIndex) {
    if (sources.isEmpty) return null;
    final requestedSourceId = selectedSourceId?.trim();
    if (requestedSourceId != null && requestedSourceId.isNotEmpty) {
      for (final source in sources) {
        if (source is! Map<String, dynamic>) continue;
        final sourceId = source['Id'];
        if (sourceId is String && sourceId.toLowerCase() == requestedSourceId.toLowerCase()) {
          return source;
        }
      }
      return null;
    }
    final source = mediaIndex >= 0 && mediaIndex < sources.length ? sources[mediaIndex] : sources.first;
    if (source is! Map<String, dynamic>) return null;
    return source;
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    // Jellyfin paths flow through `_absolutizeImagePath` at the mapper
    // boundary, so artwork fields on the [MediaItem] are already absolute
    // URLs. buildArtworkSpecs strips auth query params from localKey so the
    // storage layer never hashes or persists access tokens.
    return buildArtworkSpecs(item, (path) => path);
  }
}
