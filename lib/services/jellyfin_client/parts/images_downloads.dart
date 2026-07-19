part of '../../jellyfin_client.dart';

mixin _JellyfinImageDownloadMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  Future<JellyfinPlaybackBundle?> fetchPlaybackBundle(
    String itemId, {
    int sourceIndex = 0,
    String? sourceId,
    String? preferredSignature,
  });
  Future<JellyfinPlaybackBundle?> fetchPlaybackDiscoveryBundle(
    String itemId, {
    int sourceIndex = 0,
    String? sourceId,
    String? preferredSignature,
    AbortController? abort,
  });
  String buildDirectStreamUrl(
    String itemId, {
    String? container,
    String? mediaSourceId,
    String? playSessionId,
    String? liveStreamId,
    int? audioStreamIndex,
  });
  String buildAudioDirectStreamUrl(String itemId, {String? container, String? mediaSourceId});
  Future<Map<String, dynamic>?> getPlaybackInfo(
    String itemId, {
    int? maxStreamingBitrate = 100_000_000,
    String? mediaSourceId,
    String? liveStreamId,
    int? startTimeTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    bool? autoOpenLiveStream,
    bool? enableDirectPlay,
    bool? enableDirectStream,
    bool? enableTranscoding,
    bool? allowVideoStreamCopy,
    bool? allowAudioStreamCopy,
    bool audioProfile = false,
    Duration? timeout,
    AbortController? abort,
    bool waitIndefinitely = false,
    bool throwOnError = false,
  });
  String _withApiKey(String urlOrPath);
  Map<String, dynamic>? _selectNegotiatedMediaSource(Object? sources, String? selectedSourceId);

  @override
  String thumbnailUrl(String? path, {int? width, int? height}) {
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
  String externalImageUrl(String url, {int? width, int? height}) => url;

  @override
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async {
    // Tracks stream from /Audio/{id}/stream; the URL contract (Static=true,
    // api_key in the query string) is otherwise identical to the video one.
    final isTrack = item.kind == MediaKind.track;
    if (isTrack) {
      final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex, sourceId: mediaSourceId);
      if (bundle == null) return buildAudioDirectStreamUrl(item.id);
      return buildAudioDirectStreamUrl(
        item.id,
        container: bundle.container,
        mediaSourceId: bundle.pinnedSourceIdForItem(item.id),
      );
    }

    // Dynamic Remux/AIOStreams sources exist only in PlaybackInfo. Discover
    // them in server order, then pin the selected source in a second request
    // just like the internal player path.
    final bundle = await fetchPlaybackDiscoveryBundle(item.id, sourceIndex: mediaIndex, sourceId: mediaSourceId);
    if (bundle == null) {
      throw PlaybackException('Item ${item.id} returned no MediaSources');
    }
    final negotiation = await getPlaybackInfo(
      item.id,
      maxStreamingBitrate: null,
      mediaSourceId: bundle.selectedSourceId,
      timeout: MediaServerTimeouts.playbackNegotiation,
      throwOnError: true,
    );
    if (negotiation == null) {
      throw PlaybackException('Item ${item.id} returned invalid pinned PlaybackInfo');
    }
    final chosenSource = _selectNegotiatedMediaSource(negotiation['MediaSources'], bundle.selectedSourceId);
    if (chosenSource == null) {
      throw PlaybackException('Item ${item.id} returned no pinned MediaSource ${bundle.selectedSourceId ?? ''}');
    }

    final directStreamUrl = chosenSource['DirectStreamUrl'];
    if (directStreamUrl is String && directStreamUrl.isNotEmpty) {
      return _withApiKey(directStreamUrl);
    }
    final transcodingUrl = chosenSource['TranscodingUrl'];
    if (transcodingUrl is String && transcodingUrl.isNotEmpty) {
      return _withApiKey(transcodingUrl);
    }

    final effectiveSourceId = chosenSource['Id'] as String? ?? bundle.selectedSourceId;
    final pinnedSourceId =
        effectiveSourceId != null &&
            effectiveSourceId.isNotEmpty &&
            (bundle.availableVersions.length > 1 || effectiveSourceId != item.id)
        ? effectiveSourceId
        : null;
    return buildDirectStreamUrl(
      item.id,
      container: chosenSource['Container'] as String? ?? bundle.container,
      mediaSourceId: pinnedSourceId,
    );
  }

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0}) async {
    final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex);
    final selectedSourceId = bundle?.selectedSourceId;

    // Tracks download from the audio static-stream endpoint and have no
    // subtitle sidecars to enumerate.
    if (item.kind == MediaKind.track) {
      final audioUrl = buildAudioDirectStreamUrl(
        item.id,
        container: bundle?.container,
        mediaSourceId: bundle?.pinnedSourceIdForItem(item.id),
      );
      return DownloadResolution(videoUrl: audioUrl, mediaSourceId: selectedSourceId, externalSubtitles: const []);
    }

    // Direct-stream the selected original file. Jellyfin's `Static=true`
    // skips the transcoder so the byte-for-byte source lands on disk.
    final videoUrl = buildDirectStreamUrl(
      item.id,
      container: bundle?.container,
      mediaSourceId: bundle?.pinnedSourceIdForItem(item.id),
    );

    // External subtitle sidecars are listed in the per-source MediaStreams.
    // PlaybackInfo gives us the canonical view including DeliveryUrl when
    // the server has pre-computed one; fall back to the documented stream
    // URL pattern otherwise.
    final subtitles = <DownloadSubtitleSpec>[];
    final pbInfo = await getPlaybackInfo(item.id, mediaSourceId: selectedSourceId);
    if (pbInfo != null) {
      final sources = pbInfo['MediaSources'];
      if (sources is List && sources.isNotEmpty) {
        final source = _selectDownloadMediaSource(sources, selectedSourceId, mediaIndex);
        if (source != null) {
          final mediaSourceId = (source['Id'] as String?) ?? item.id;
          final streams = source['MediaStreams'];
          if (streams is List) {
            for (final raw in streams) {
              if (raw is! Map<String, dynamic>) continue;
              if (raw['Type'] != 'Subtitle') continue;
              final fields = parseJellyfinStreamFields(raw);
              if (!fields.isExternalFile) continue;
              final index = raw['Index'];
              if (index is! int) continue;
              final codec = fields.codec?.toLowerCase();
              final delivery = fields.deliveryUrl;
              final url = _withApiKey(
                delivery != null && delivery.isNotEmpty
                    ? delivery
                    : '/Videos/${_segment(item.id)}/${_segment(mediaSourceId)}/Subtitles/$index/${_segment('Stream.${codec ?? 'srt'}')}',
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
          }
        }
      }
    }

    return DownloadResolution(videoUrl: videoUrl, mediaSourceId: selectedSourceId, externalSubtitles: subtitles);
  }

  Map<String, dynamic>? _selectDownloadMediaSource(List<dynamic> sources, String? selectedSourceId, int mediaIndex) {
    final requestedSourceId = selectedSourceId?.trim();
    if (requestedSourceId != null && requestedSourceId.isNotEmpty) {
      for (final source in sources) {
        if (source is Map<String, dynamic> &&
            (source['Id'] as String?)?.toLowerCase() == requestedSourceId.toLowerCase()) {
          return source;
        }
      }
      return null;
    }
    final source = mediaIndex >= 0 && mediaIndex < sources.length ? sources[mediaIndex] : sources.first;
    return source is Map<String, dynamic> ? source : null;
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
