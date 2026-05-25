part of '../../jellyfin_client.dart';

mixin _JellyfinPlaybackMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  MediaServerHttpClient get _http;

  /// Backend-neutral [PlaybackExtras] for [itemId]. Jellyfin exposes chapters
  /// at the item level (`raw['Chapters']`) and native skip segments through a
  /// separate `/MediaSegments/{itemId}` endpoint. Segment loading is best-effort
  /// so older servers still use chapter title fallback.
  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async {
    final item = await fetchItem(itemId);
    final markers = item == null ? const <MediaMarker>[] : await _fetchMediaSegmentMarkers(itemId);
    return jellyfinPlaybackExtrasFromRaw(
      item?.raw,
      itemId,
      introPattern: introPattern,
      creditsPattern: creditsPattern,
      forceChapterFallback: forceChapterFallback,
      markers: markers,
    );
  }

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async {
    final item = await cache.getMetadata(cacheServerId, itemId);
    if (item == null) return null;
    final markers = await _fetchCachedMediaSegmentMarkers(itemId);
    return jellyfinPlaybackExtrasFromRaw(
      item.raw,
      itemId,
      introPattern: introPattern,
      creditsPattern: creditsPattern,
      forceChapterFallback: forceChapterFallback,
      markers: markers,
    );
  }

  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(String itemId) async {
    final item = await cache.getMetadata(cacheServerId, itemId);
    final raw = item?.raw;
    if (raw is! Map<String, dynamic>) return null;
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final first = sources.first;
    if (first is! Map<String, dynamic>) return null;
    return jellyfinMediaSourceToMediaSourceInfo(first, chapters: raw['Chapters'], trickplay: raw['Trickplay']);
  }

  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async {
    if (!capabilities.scrubThumbnails) return null;
    final manifest = mediaSource.trickplayByWidth;
    if (manifest == null || manifest.isEmpty) return null;
    return JellyfinTrickplayService.create(
      client: this as JellyfinClient,
      itemId: item.id,
      mediaSourceId: mediaSource.mediaSourceId,
      manifest: manifest,
    );
  }

  Future<List<MediaMarker>> _fetchMediaSegmentMarkers(String itemId) async {
    final endpoint = JellyfinApiCache.mediaSegmentsEndpoint(itemId);
    try {
      return await fetchWithCacheFallback<List<MediaMarker>>(
            cacheKey: endpoint,
            networkCall: () async {
              final response = await _http.get(endpoint);
              if (response.statusCode == 404) {
                return MediaServerResponse(statusCode: 200, headers: response.headers, requestUri: response.requestUri);
              }
              throwIfHttpError(response);
              return response;
            },
            parseCache: jellyfinMediaSegmentsToMarkers,
            parseResponse: (response) => jellyfinMediaSegmentsToMarkers(response.data),
          ) ??
          const [];
    } on MediaServerHttpException catch (e) {
      if (e.statusCode != 404) {
        appLogger.d('JellyfinClient.fetchPlaybackExtras media segments unavailable', error: e);
      }
      return const [];
    } catch (e) {
      appLogger.d('JellyfinClient.fetchPlaybackExtras media segments unavailable', error: e);
      return const [];
    }
  }

  Future<List<MediaMarker>> _fetchCachedMediaSegmentMarkers(String itemId) async {
    try {
      final data = await cache.get(cacheServerId, JellyfinApiCache.mediaSegmentsEndpoint(itemId));
      return jellyfinMediaSegmentsToMarkers(data);
    } catch (e) {
      appLogger.d('JellyfinClient.fetchPlaybackExtras cached media segments unavailable', error: e);
      return const [];
    }
  }

  String _withApiKey(String urlOrPath) {
    final uri = JellyfinImageAbsolutizer.joinUri(baseUrl: connection.baseUrl, urlOrPath: urlOrPath);
    final params = Map<String, String>.from(uri.queryParameters)..['api_key'] = connection.accessToken;
    return uri.replace(queryParameters: params).toString();
  }

  /// Jellyfin playback URL resolution.
  ///
  /// Always POSTs `/Items/{id}/PlaybackInfo` so Jellyfin can resolve external
  /// audio/subtitle streams server-side. Uses the returned `TranscodingUrl` or
  /// `DirectStreamUrl` when present, otherwise falls back to a static direct
  /// stream URL (`/Videos/{id}/stream?Static=true&api_key=...`).
  ///
  /// The returned `MediaSourceInfo` is what the player uses for track-picker
  /// labels and auto-track selection by language.
  ///
  /// Throws [PlaybackException] when the item is missing or has no
  /// `MediaSources`.
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    final metadata = options.metadata;
    final bundle = await fetchPlaybackBundle(
      metadata.id,
      sourceIndex: options.selectedMediaIndex,
      sourceId: options.selectedMediaSourceId,
    );
    if (bundle == null) {
      throw PlaybackException('Item ${metadata.id} returned no MediaSources');
    }
    var mediaInfo = jellyfinMediaSourceToMediaSourceInfo(
      bundle.selectedSource,
      chapters: bundle.chapters,
      trickplay: bundle.trickplay,
    );
    var effectiveSourceId = bundle.selectedSourceId;
    var effectiveContainer = bundle.container;
    var includeExternalSubtitleDelivery = false;

    String? videoUrl;
    String? playSessionId;
    var playMethod = 'DirectPlay';
    var isTranscoding = false;
    TranscodeFallbackReason? fallbackReason;

    final preset = options.qualityPreset;
    final requestedAudioStreamId = _validJellyfinAudioStreamId(options.selectedAudioStreamId, mediaInfo);
    final int? maxStreamingBitrate = preset.isOriginal ? null : (preset.videoBitrateKbps ?? 100000) * 1000;
    final resumeOffsetMs = metadata.viewOffsetMs;
    final int? transcodeStartTimeTicks = !preset.isOriginal && resumeOffsetMs != null && resumeOffsetMs > 0
        ? msToJellyfinTicks(resumeOffsetMs)
        : null;
    final negotiation = await getPlaybackInfo(
      metadata.id,
      maxStreamingBitrate: maxStreamingBitrate,
      mediaSourceId: bundle.selectedSourceId,
      startTimeTicks: transcodeStartTimeTicks,
      audioStreamIndex: requestedAudioStreamId,
    );
    if (negotiation == null) {
      if (!preset.isOriginal) {
        fallbackReason = TranscodeFallbackReason.decisionFailed;
      }
    } else {
      final chosenSource = _selectNegotiatedMediaSource(negotiation['MediaSources'], bundle.selectedSourceId);
      if (chosenSource != null) {
        effectiveSourceId = chosenSource['Id'] as String? ?? effectiveSourceId;
        effectiveContainer = chosenSource['Container'] as String? ?? effectiveContainer;
        if (chosenSource['MediaStreams'] is List) {
          mediaInfo = jellyfinMediaSourceToMediaSourceInfo(
            chosenSource,
            chapters: bundle.chapters,
            trickplay: bundle.trickplay,
          );
        }

        final negotiatedPlaySessionId = negotiation['PlaySessionId'];
        void capturePlaySessionId(String urlOrPath) {
          playSessionId = Uri.tryParse(urlOrPath)?.queryParameters['PlaySessionId'];
          if ((playSessionId == null || playSessionId!.isEmpty) && negotiatedPlaySessionId is String) {
            playSessionId = negotiatedPlaySessionId;
          }
        }

        final transcodingUrl = chosenSource['TranscodingUrl'];
        final directStreamUrl = chosenSource['DirectStreamUrl'];
        if (!preset.isOriginal && transcodingUrl is String && transcodingUrl.isNotEmpty) {
          // TranscodingUrl is server-relative and already encodes container,
          // codecs, MediaSourceId, and PlaySessionId; we just append the
          // api_key for auth.
          capturePlaySessionId(transcodingUrl);
          videoUrl = _withApiKey(transcodingUrl);
          playMethod = 'Transcode';
          isTranscoding = true;
          includeExternalSubtitleDelivery = true;
        } else if (directStreamUrl is String && directStreamUrl.isNotEmpty) {
          capturePlaySessionId(directStreamUrl);
          videoUrl = _withApiKey(directStreamUrl);
          playMethod = 'DirectStream';
        } else {
          if (!preset.isOriginal) {
            fallbackReason = TranscodeFallbackReason.directPlayOnly;
          }
        }
      } else if (!preset.isOriginal) {
        fallbackReason = TranscodeFallbackReason.directPlayOnly;
      }
    }

    final effectiveAudioStreamId = _resolveJellyfinAudioStreamId(requestedAudioStreamId, mediaInfo);
    mediaInfo = _withSelectedJellyfinAudioStream(mediaInfo, effectiveAudioStreamId);
    final externalSubtitles = _buildExternalSubtitles(
      metadata.id,
      effectiveSourceId,
      mediaInfo,
      includeExternalDelivery: includeExternalSubtitleDelivery,
    );
    final pinnedSourceId = bundle.pinnedSourceIdForItem(metadata.id);
    videoUrl ??= buildDirectStreamUrl(metadata.id, container: effectiveContainer, mediaSourceId: pinnedSourceId);

    return PlaybackInitializationResult(
      availableVersions: bundle.availableVersions,
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      externalSubtitles: externalSubtitles,
      isOffline: false,
      isTranscoding: isTranscoding,
      fallbackReason: fallbackReason,
      activeAudioStreamId: requestedAudioStreamId,
      playSessionId: playSessionId,
      playMethod: playMethod,
    );
  }

  int? _validJellyfinAudioStreamId(int? explicit, MediaSourceInfo mediaInfo) {
    if (explicit == null) return null;
    return mediaInfo.audioTracks.any((track) => track.id == explicit) ? explicit : null;
  }

  Map<String, dynamic>? _selectNegotiatedMediaSource(Object? sources, String? selectedSourceId) {
    if (sources is! List || sources.isEmpty) return null;
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
    final first = sources.first;
    return first is Map<String, dynamic> ? first : null;
  }

  int? _resolveJellyfinAudioStreamId(int? explicit, MediaSourceInfo mediaInfo) {
    final validExplicit = _validJellyfinAudioStreamId(explicit, mediaInfo);
    if (validExplicit != null) return validExplicit;
    final defaultStreamIndex = mediaInfo.defaultAudioStreamIndex;
    if (defaultStreamIndex != null) return defaultStreamIndex;
    for (final track in mediaInfo.audioTracks) {
      if (track.selected) return track.id;
    }
    return null;
  }

  MediaSourceInfo _withSelectedJellyfinAudioStream(MediaSourceInfo mediaInfo, int? selectedStreamId) {
    if (selectedStreamId == null || !mediaInfo.audioTracks.any((track) => track.id == selectedStreamId)) {
      return mediaInfo;
    }
    return MediaSourceInfo(
      videoUrl: mediaInfo.videoUrl,
      audioTracks: [
        for (final track in mediaInfo.audioTracks)
          MediaAudioTrack(
            id: track.id,
            index: track.index,
            codec: track.codec,
            language: track.language,
            languageCode: track.languageCode,
            title: track.title,
            displayTitle: track.displayTitle,
            channels: track.channels,
            selected: track.id == selectedStreamId,
            external: track.external,
          ),
      ],
      subtitleTracks: mediaInfo.subtitleTracks,
      chapters: mediaInfo.chapters,
      partId: mediaInfo.partId,
      displayCriteria: mediaInfo.displayCriteria,
      mediaSourceId: mediaInfo.mediaSourceId,
      defaultAudioStreamIndex: mediaInfo.defaultAudioStreamIndex,
      defaultSubtitleStreamIndex: mediaInfo.defaultSubtitleStreamIndex,
      trickplayByWidth: mediaInfo.trickplayByWidth,
    );
  }

  String? _jellyfinSubtitleFallbackPath(String itemId, String? mediaSourceId, MediaSubtitleTrack track) {
    final sourceId = mediaSourceId;
    final streamIndex = track.index ?? track.id;
    final codec = track.codec;
    if (sourceId == null || codec == null || codec.isEmpty) return null;
    final path = Uri(
      pathSegments: ['Videos', itemId, sourceId, 'Subtitles', streamIndex.toString(), 'Stream.$codec'],
    ).path;
    return path.startsWith('/') ? path : '/$path';
  }

  List<SubtitleTrack> _buildExternalSubtitles(
    String itemId,
    String? mediaSourceId,
    MediaSourceInfo mediaInfo, {
    bool includeExternalDelivery = false,
  }) {
    final externalSubtitles = <SubtitleTrack>[];
    for (final track in mediaInfo.subtitleTracks) {
      if (!track.isExternalFile && !(includeExternalDelivery && track.usesExternalDelivery)) continue;
      final path = track.key ?? _jellyfinSubtitleFallbackPath(itemId, mediaSourceId, track);
      if (path == null) continue;
      // Jellyfin's subtitle URL is a path relative to baseUrl; build the
      // absolute URL with the api_key query param.
      final url = _withApiKey(path);
      externalSubtitles.add(
        SubtitleTrack.uri(
          url,
          title:
              cleanSubtitleTitle(track.displayTitle ?? track.title, codec: track.codec) ??
              cleanTrackMetadataValue(track.language),
          language: cleanTrackMetadataValue(track.languageCode),
        ),
      );
    }
    return externalSubtitles;
  }

  /// Internal accessor for [PlaybackInitializationService]. Returns the
  /// chosen `MediaSource` JSON, every available source's [MediaVersion],
  /// and the item's `Chapters` array. One round-trip vs. fetchItem + raw
  /// extraction at the call site.
  ///
  /// Returns `null` when the item doesn't exist or has no `MediaSources`.
  /// [sourceId] wins when present because Jellyfin plugins may reorder merged
  /// `MediaSources` between requests. [sourceIndex] is clamped to the valid
  /// range as a fallback to mirror Plex's `parseVideoPlaybackDataFromJson`.
  Future<JellyfinPlaybackBundle?> fetchPlaybackBundle(String itemId, {int sourceIndex = 0, String? sourceId}) async {
    final item = await fetchItem(itemId);
    final raw = item?.raw;
    if (raw is! Map<String, dynamic>) return null;
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final availableVersions = jellyfinSourcesToVersions(sources);
    var index = sourceIndex;
    final requestedSourceId = sourceId?.trim();
    if (requestedSourceId != null && requestedSourceId.isNotEmpty) {
      final byId = sources.indexWhere((source) => source is Map<String, dynamic> && source['Id'] == requestedSourceId);
      if (byId >= 0) index = byId;
    }
    if (index < 0 || index >= sources.length) index = 0;
    final source = sources[index];
    if (source is! Map<String, dynamic>) return null;
    final chapters = raw['Chapters'];
    return JellyfinPlaybackBundle(
      availableVersions: availableVersions,
      selectedSource: source,
      chapters: chapters is List ? chapters : const [],
      container: source['Container'] as String?,
      selectedSourceId: source['Id'] as String?,
      trickplay: raw['Trickplay'],
    );
  }

  /// Direct-stream URL for [itemId]. Best for files the device can play
  /// natively. Adds `?Static=true` to skip the transcoder and
  /// `&api_key=...` so the request authenticates without a header.
  ///
  /// Pass [mediaSourceId] to stream a non-default alternate version. When the
  /// item only has a single MediaSource, [mediaSourceId] equals [itemId] and
  /// can be omitted; for items with multiple versions Jellyfin uses the
  /// param to pick which file to serve.
  String buildDirectStreamUrl(
    String itemId, {
    String? container,
    String? mediaSourceId,
    String? playSessionId,
    String? liveStreamId,
    int? audioStreamIndex,
  }) {
    return buildJellyfinDirectStreamUrl(
      baseUrl: connection.baseUrl,
      accessToken: connection.accessToken,
      deviceId: connection.deviceId,
      itemId: itemId,
      container: container,
      mediaSourceId: mediaSourceId,
      playSessionId: playSessionId,
      liveStreamId: liveStreamId,
      audioStreamIndex: audioStreamIndex,
    );
  }

  /// Trickplay sprite-sheet URL. [width] picks one of the resolutions
  /// declared in `BaseItemDto.Trickplay`; [sheetIndex] is the zero-based
  /// sheet number (each sheet packs `tileWidth * tileHeight` thumbnails).
  /// Pass [mediaSourceId] when the item has more than one source so the
  /// server returns the matching version's tiles.
  String buildTrickplayTileUrl(String itemId, int width, int sheetIndex, {String? mediaSourceId}) {
    return buildJellyfinTrickplayTileUrl(
      baseUrl: connection.baseUrl,
      accessToken: connection.accessToken,
      deviceId: connection.deviceId,
      itemId: itemId,
      width: width,
      sheetIndex: sheetIndex,
      mediaSourceId: mediaSourceId,
    );
  }

  /// Negotiate playback: returns the parsed `MediaSources[]` array and the
  /// server's recommended `PlaySessionId`. Caller decides which media source
  /// to use and feeds the returned `TranscodingUrl` into the player.
  ///
  /// When non-null, [maxStreamingBitrate] is forwarded as both the top-level
  /// field and inside the `DeviceProfile` so the server caps direct-stream and
  /// transcode bitrate against the same ceiling. Original playback passes null
  /// to avoid capping high-bitrate files. [mediaSourceId] pins the negotiation
  /// to a specific version when the item has multiple sources.
  /// [startTimeTicks] is forwarded to Jellyfin's playback negotiation for
  /// resume-aware stream metadata. Our video transcode profile is HLS, and
  /// Jellyfin omits `StartTimeTicks` from the returned HLS URL, so the player
  /// still performs the initial seek.
  /// [audioStreamIndex] / [subtitleStreamIndex] tell the server which streams
  /// to pick for the transcode profile (Jellyfin's negotiation factors them in
  /// when picking codec compatibility).
  Future<Map<String, dynamic>?> getPlaybackInfo(
    String itemId, {
    int? maxStreamingBitrate = 100000000,
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
  }) async {
    try {
      final query = <String, String>{
        'userId': connection.userId,
        'MaxStreamingBitrate': ?maxStreamingBitrate?.toString(),
        'MediaSourceId': ?mediaSourceId,
        'LiveStreamId': ?liveStreamId,
        'StartTimeTicks': ?startTimeTicks?.toString(),
        'AudioStreamIndex': ?audioStreamIndex?.toString(),
        'SubtitleStreamIndex': ?subtitleStreamIndex?.toString(),
        'AutoOpenLiveStream': ?autoOpenLiveStream?.toString(),
        'EnableDirectPlay': ?enableDirectPlay?.toString(),
        'EnableDirectStream': ?enableDirectStream?.toString(),
        'EnableTranscoding': ?enableTranscoding?.toString(),
        'AllowVideoStreamCopy': ?allowVideoStreamCopy?.toString(),
        'AllowAudioStreamCopy': ?allowAudioStreamCopy?.toString(),
      };
      final response = await _http.post(
        '/Items/${_segment(itemId)}/PlaybackInfo',
        queryParameters: query,
        body: {
          'UserId': connection.userId,
          'MaxStreamingBitrate': ?maxStreamingBitrate,
          'MediaSourceId': ?mediaSourceId,
          'LiveStreamId': ?liveStreamId,
          'StartTimeTicks': ?startTimeTicks,
          'AudioStreamIndex': ?audioStreamIndex,
          'SubtitleStreamIndex': ?subtitleStreamIndex,
          'AutoOpenLiveStream': ?autoOpenLiveStream,
          'EnableDirectPlay': ?enableDirectPlay,
          'EnableDirectStream': ?enableDirectStream,
          'EnableTranscoding': ?enableTranscoding,
          'AllowVideoStreamCopy': ?allowVideoStreamCopy,
          'AllowAudioStreamCopy': ?allowAudioStreamCopy,
          'DeviceProfile': <String, Object?>{
            'Name': 'Plezy',
            'MaxStreamingBitrate': ?maxStreamingBitrate,
            'CodecProfiles': const <Map<String, Object?>>[],
            // Comma-separated codec lists are order-sensitive — first entry
            // wins when the server picks an output codec. HEVC is listed
            // ahead of H.264 so a server that has "Allow encoding in HEVC
            // format" enabled will actually emit HEVC instead of falling
            // back to H.264.
            'TranscodingProfiles': const <Map<String, Object?>>[
              {
                'Type': 'Video',
                'Container': 'ts',
                'Protocol': 'hls',
                'VideoCodec': 'hevc,h264',
                'AudioCodec': 'aac,mp3,ac3,eac3,flac,opus',
              },
            ],
            // Declaring HEVC in DirectPlayProfile.VideoCodec stops the server
            // from forcing a transcode for HEVC sources whose container we
            // already accept — mpv decodes HEVC natively on every platform
            // we ship.
            'DirectPlayProfiles': const <Map<String, Object?>>[
              {
                'Type': 'Video',
                'Container': 'mp4,mkv,m4v,webm,mov,ts',
                'VideoCodec': 'hevc,h264,h265,vp8,vp9,av1,mpeg4,mpeg2video',
                'AudioCodec': 'aac,mp3,mp2,ac3,eac3,flac,opus,vorbis,dts',
              },
            ],
            'SubtitleProfiles': const <Map<String, Object?>>[
              {'Format': 'srt', 'Method': 'External'},
              {'Format': 'ass', 'Method': 'External'},
              {'Format': 'ssa', 'Method': 'External'},
              {'Format': 'vtt', 'Method': 'External'},
              {'Format': 'pgssub', 'Method': 'External'},
              {'Format': 'dvdsub', 'Method': 'External'},
              {'Format': 'dvbsub', 'Method': 'External'},
            ],
          },
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      return data is Map<String, dynamic> ? data : null;
    } catch (e, st) {
      appLogger.w('JellyfinClient: getPlaybackInfo failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    final item = await fetchItem(itemId);
    final raw = item?.raw;
    final providerIds = raw is Map<String, dynamic> ? raw['ProviderIds'] : null;
    if (providerIds is Map<String, dynamic>) {
      return ExternalIds.fromJellyfinProviderIds(providerIds);
    }
    return const ExternalIds();
  }

  /// Jellyfin embeds the access token in the URL query string (`api_key=...`)
  /// rather than relying on headers, so the player needs no extra headers
  /// for direct streams.
  @override
  Map<String, String> get streamHeaders => const {};

  /// Tell the server the user has started playing [itemId]. Body shape
  /// mirrors the Jellyfin SDK's [PlaybackStartInfo] — Findroid sends the
  /// same fields, and Jellyfin's session tracker drops events that omit
  /// `PlayMethod` because it has no way to associate progress with an
  /// active session row.
  ///
  /// [duration] is accepted for interface symmetry with Plex but ignored —
  /// Jellyfin's `/Sessions/Playing` body has no slot for it. Stream indexes
  /// are still sent so the active session reflects the chosen tracks.
  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final response = await _http.post(
      '/Sessions/Playing',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'AudioStreamIndex': ?audioStreamIndex,
        'SubtitleStreamIndex': ?subtitleStreamIndex,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'CanSeek': true,
        'IsPaused': false,
        'IsMuted': false,
        'PlayMethod': playMethod ?? 'DirectPlay',
        'RepeatMode': 'RepeatNone',
        'PlaybackOrder': 'Default',
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }

  /// Periodic progress ping (5–10s cadence is typical). Server uses this to
  /// drive the resume position, detect idle sessions, and save remembered
  /// audio/subtitle stream indexes when enabled in Jellyfin user settings.
  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final response = await _http.post(
      '/Sessions/Playing/Progress',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'AudioStreamIndex': ?audioStreamIndex,
        'SubtitleStreamIndex': ?subtitleStreamIndex,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'CanSeek': true,
        'IsPaused': isPaused,
        'IsMuted': false,
        'PlayMethod': playMethod ?? 'DirectPlay',
        'RepeatMode': 'RepeatNone',
        'PlaybackOrder': 'Default',
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }

  /// End-of-playback signal. Final position becomes the resume bookmark.
  /// [duration] is accepted for interface symmetry with Plex but ignored.
  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) async {
    final response = await _http.post(
      '/Sessions/Playing/Stopped',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'Failed': false,
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }
}
