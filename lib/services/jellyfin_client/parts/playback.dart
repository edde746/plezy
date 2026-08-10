part of '../../jellyfin_client.dart';

bool _canUseJellyfinStaticStreamFallback(Object error) {
  if (error is MediaServerAuthException) return false;
  if (error is MediaServerHttpException) {
    final status = error.statusCode;
    return !error.isCancellation && status != 401 && status != 403;
  }
  return true;
}

mixin _JellyfinPlaybackMethods on _JellyfinClientInternals {
  /// Backend-neutral [PlaybackExtras] for [itemId]. Both dialects expose
  /// chapters at the item level (`raw['Chapters']`), while only Jellyfin exposes
  /// native skip segments through `/MediaSegments/{itemId}`. Segment loading is
  /// best-effort so unsupported and older servers use chapter title fallback.
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
    final item = await cache.getMetadata(ServerId(cacheServerId), itemId);
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
    final item = await cache.getMetadata(ServerId(cacheServerId), itemId);
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
    // Emby 4.9.5 has neither the `Trickplay` field nor the tile route; its capabilities stop URL construction here.
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
    if (!dialect.supportsMediaSegments) {
      // Emby 4.9.5 returns 404 for `/MediaSegments/{itemId}`; empty markers preserve the chapter-name fallback.
      return const [];
    }
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
      final data = await cache.get(ServerId(cacheServerId), JellyfinApiCache.mediaSegmentsEndpoint(itemId));
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

  /// MediaBrowser playback URL resolution.
  ///
  /// Always POSTs `/Items/{id}/PlaybackInfo` so the server can resolve external
  /// audio/subtitle streams server-side. Uses the returned `TranscodingUrl`
  /// when the caller asked for a capped quality; otherwise — and on any
  /// DirectPlay decision — builds the shared static direct stream URL
  /// (`/Videos/{id}/stream?Static=true&api_key=...`) itself.
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
      preferredSignature: options.preferredVersionSignature,
    );
    if (bundle == null) {
      throw PlaybackException(t.messages.playbackNoMediaSources, reason: PlaybackFailureReason.noPlayableSource);
    }
    var mediaInfo = jellyfinMediaSourceToMediaSourceInfo(
      bundle.selectedSource,
      chapters: bundle.chapters,
      trickplay: bundle.trickplay,
    );
    var effectiveSourceId = bundle.selectedSourceId;
    var effectiveContainer = bundle.container;

    String? videoUrl;
    String? playSessionId;
    var playMethod = 'DirectPlay';
    var isTranscoding = false;
    TranscodeFallbackReason? fallbackReason;

    // Tracks negotiate with the audio device profile and ignore the
    // (video-shaped) [PlaybackInitializationOptions.qualityPreset]; capping
    // comes from [PlaybackInitializationOptions.audioQualityPreset] instead.
    // Original / null keeps the unlimited default so high-bitrate lossless
    // files direct-play uncapped.
    final isTrack = metadata.kind == MediaKind.track;
    final preset = options.qualityPreset;
    final audioPreset = options.audioQualityPreset ?? AudioQualityPreset.original;
    final wantsOriginal = isTrack ? audioPreset.isOriginal : preset.isOriginal;
    final requestedAudioStreamId = options.selectedAudioStreamId == null
        ? options.preferredAudioTrack == null
              ? null
              : findSourceAudioTrackForIntent(options.preferredAudioTrack!, mediaInfo.audioTracks)?.id
        : _validJellyfinAudioStreamId(options.selectedAudioStreamId, mediaInfo);
    final requestedSubtitleStreamId = _validJellyfinSubtitleStreamId(options.preferredSubtitleTrack, mediaInfo);
    // A real external subtitle file stays a file the client fetches, on a transcode as much as on
    // a direct play - it is the one case where the client genuinely holds it. Jellyfin decides
    // delivery from the profile and matches on format alone, never on whether a stream is embedded
    // or a file, so the two rules are only expressible per request: withhold `External` when the
    // selected stream is embedded (the server then burns it in), and offer it when the selection is
    // a file. Deciding it per selection is what lets both hold at once.
    //
    // The *effective* selection, not just an explicit one: the normal launch path sends no
    // preferred track and lets the server's `DefaultSubtitleStreamIndex` decide. Reading only the
    // explicit request would withhold `External` for a default that is a real file, so the server
    // would burn it while the client still fetched the same file as a sidecar - two copies on
    // screen, and a transcode nobody needed.
    final effectiveSubtitleStreamId = requestedSubtitleStreamId == -1
        ? null
        : requestedSubtitleStreamId ?? mediaInfo.defaultSubtitleStreamIndex;
    // Text only, because that is all the profile can actually deliver externally: a bitmap file
    // falls through to `Encode` and gets burned in whatever we ask for, so classifying one as
    // externally delivered would leave the client fetching a copy of pixels already in the video.
    final requestedSubtitleIsExternalFile =
        effectiveSubtitleStreamId != null &&
        mediaInfo.subtitleTracks.any(
          (track) =>
              track.id == effectiveSubtitleStreamId &&
              track.isExternalFile &&
              CodecUtils.isTextSubtitleCodec(track.codec),
        );
    final int? maxStreamingBitrate = wantsOriginal
        ? null
        : isTrack
        // Non-original audio presets always carry a bitrate by construction.
        ? audioPreset.bitrateKbps! * 1000
        : (preset.videoBitrateKbps ?? 100_000) * 1000;
    final resumeOffsetMs = metadata.viewOffsetMs;
    final int? transcodeStartTimeTicks = !wantsOriginal && resumeOffsetMs != null && resumeOffsetMs > 0
        ? msToJellyfinTicks(resumeOffsetMs)
        : null;
    Map<String, dynamic>? negotiation;
    Map<String, dynamic>? chosenSource;
    try {
      negotiation = await getPlaybackInfo(
        metadata.id,
        maxStreamingBitrate: maxStreamingBitrate,
        mediaSourceId: bundle.selectedSourceId,
        startTimeTicks: transcodeStartTimeTicks,
        audioStreamIndex: requestedAudioStreamId,
        subtitleStreamIndex: requestedSubtitleStreamId,
        audioProfile: isTrack,
        // A capped preset is the only way a transcode is asked for, and on one the server
        // burns the selected embedded stream in rather than serving it as a file the client
        // would fetch as well. A selected external *file* keeps `External`, so it is still
        // delivered as a file - the one case where the client genuinely holds it.
        burnSubtitles: !wantsOriginal && !requestedSubtitleIsExternalFile,
      );
      chosenSource = _selectNegotiatedMediaSource(negotiation['MediaSources'], bundle.selectedSourceId);
    } catch (error, stackTrace) {
      if (!_canUseJellyfinStaticStreamFallback(error)) {
        Error.throwWithStackTrace(classifyPlaybackFailure(error), stackTrace);
      }
      appLogger.w(
        'Jellyfin playback negotiation unavailable; using the static stream',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (chosenSource == null) {
      fallbackReason = TranscodeFallbackReason.decisionFailed;
      appLogger.w('Jellyfin playback negotiation returned no usable source; using the static stream');
    } else {
      final negotiatedSourceId = chosenSource['Id'];
      final negotiatedContainer = chosenSource['Container'];
      if (negotiatedSourceId is String) effectiveSourceId = negotiatedSourceId;
      if (negotiatedContainer is String) effectiveContainer = negotiatedContainer;
      if (chosenSource['MediaStreams'] is List) {
        mediaInfo = jellyfinMediaSourceToMediaSourceInfo(
          chosenSource,
          chapters: bundle.chapters,
          trickplay: bundle.trickplay,
        );
      }

      final transcodingUrl = chosenSource['TranscodingUrl'];
      if (!wantsOriginal && transcodingUrl is String && transcodingUrl.isNotEmpty) {
        // TranscodingUrl is server-relative and already encodes container,
        // codecs, MediaSourceId, and PlaySessionId; we just append the
        // api_key for auth.
        final urlSessionId = Uri.tryParse(transcodingUrl)?.queryParameters['PlaySessionId'];
        final negotiatedSessionId = negotiation!['PlaySessionId'];
        playSessionId = urlSessionId != null && urlSessionId.isNotEmpty
            ? urlSessionId
            : (negotiatedSessionId is String ? negotiatedSessionId : null);
        videoUrl = _withApiKey(transcodingUrl);
        playMethod = 'Transcode';
        isTranscoding = true;
      } else if (!wantsOriginal) {
        fallbackReason = TranscodeFallbackReason.directPlayOnly;
      }
    }

    final effectiveAudioStreamId = _resolveJellyfinAudioStreamId(requestedAudioStreamId, mediaInfo);
    mediaInfo = _withSelectedJellyfinAudioStream(mediaInfo, effectiveAudioStreamId);
    // Tracks have no subtitle streams to assemble (a `Lyric` stream may be
    // present, but lyrics flow through fetchLyrics, not the subtitle path).
    //
    // The burned row is excluded so it cannot be painted twice; the rest stay fetchable, which is
    // what keeps a secondary track renderable over a transcode.
    //
    // Recomputed against the negotiated `mediaInfo`: the request's own view came from the
    // pre-negotiation source, and when nothing was explicitly asked for it is the *server's*
    // default that decides, which the response can report differently. An explicit request still
    // wins, and an off request still burns nothing.
    final negotiatedSubtitleStreamId = requestedSubtitleStreamId == -1
        ? null
        : requestedSubtitleStreamId ?? mediaInfo.defaultSubtitleStreamIndex;
    final burnedSourceStreamId = isTranscoding && !requestedSubtitleIsExternalFile ? negotiatedSubtitleStreamId : null;
    final subtitleSidecars = isTrack
        ? const <PlaybackSubtitleSidecar>[]
        : _buildExternalSubtitles(
            metadata.id,
            effectiveSourceId,
            mediaInfo,
            isTranscoding: isTranscoding,
            burnedSourceStreamId: burnedSourceStreamId,
          );
    mediaInfo = _withSidecarBackedSubtitleIdentity(mediaInfo, subtitleSidecars);
    // Jellyfin's streaming endpoint resolves a blank MediaSourceId to its own
    // first sorted source, which for an item with alternate versions is a
    // different file. Pin the source the negotiation actually settled on, as
    // every official client does.
    final pinnedSourceId = _normalizedSourceId(effectiveSourceId);
    videoUrl ??= isTrack
        ? buildAudioDirectStreamUrl(metadata.id, container: effectiveContainer, mediaSourceId: pinnedSourceId)
        : buildDirectStreamUrl(metadata.id, container: effectiveContainer, mediaSourceId: pinnedSourceId);

    return PlaybackInitializationResult(
      availableVersions: bundle.availableVersions,
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      subtitleSidecars: subtitleSidecars,
      isOffline: false,
      isTranscoding: isTranscoding,
      fallbackReason: fallbackReason,
      activeAudioStreamId: requestedAudioStreamId,
      playSessionId: playSessionId,
      playMethod: playMethod,
      selectedMediaIndex: bundle.selectedSourceIndex,
    );
  }

  /// Source ids ride into `MediaSourceId=`, where Jellyfin compares them
  /// ordinally and, on a miss, parses them as a GUID. Only ever forward a
  /// non-empty id the server itself gave us; a blank one must stay absent.
  static String? _normalizedSourceId(String? sourceId) {
    final id = sourceId?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  int? _validJellyfinAudioStreamId(int? explicit, MediaSourceInfo mediaInfo) {
    if (explicit == null) return null;
    return mediaInfo.audioTracks.any((track) => track.id == explicit) ? explicit : null;
  }

  int? _validJellyfinSubtitleStreamId(SubtitlePreference? preferred, MediaSourceInfo mediaInfo) {
    switch (preferred) {
      case null:
        return null;
      case SubtitleOffPreference():
        return -1;
      case SubtitleIntentPreference(:final intent):
        return findSourceTrackForIntent(intent, mediaInfo.subtitleTracks)?.id;
      case SubtitleTrackPreference(:final track):
        const sourcePrefix = 'source:';
        final intent = SubtitleIntent.fromTrack(track);
        if (track.id.startsWith(sourcePrefix)) {
          final explicit = int.tryParse(track.id.substring(sourcePrefix.length));
          if (explicit != null && mediaInfo.subtitleTracks.any((row) => row.id == explicit)) {
            // A source id is authoritative only within one item. When semantic
            // metadata is available, re-derive the row through the hard-gated
            // intent match so a reused stream index cannot cross language or
            // forced-ness classes (#1716).
            final hasLanguage = intent?.language?.isNotEmpty ?? false;
            if (!hasLanguage) return explicit;
            return findSourceTrackForIntent(intent!, mediaInfo.subtitleTracks)?.id;
          }
        }
        return intent == null ? null : findSourceTrackForIntent(intent, mediaInfo.subtitleTracks)?.id;
    }
  }

  Map<String, dynamic>? _selectNegotiatedMediaSource(Object? sources, String? selectedSourceId) {
    if (sources is! List || sources.isEmpty) return null;
    final requestedSourceId = selectedSourceId?.trim();
    if (requestedSourceId != null && requestedSourceId.isNotEmpty) {
      for (final source in sources) {
        if (source is! Map<String, dynamic>) {
          throw const FormatException('Malformed Jellyfin PlaybackInfo media source');
        }
        final sourceId = source['Id'];
        if (sourceId is String && sourceId.toLowerCase() == requestedSourceId.toLowerCase()) {
          return source;
        }
      }
      return null;
    }
    final first = sources.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('Malformed Jellyfin PlaybackInfo media source');
    }
    final firstId = first['Id'];
    if (firstId != null && firstId is! String) {
      throw const FormatException('Malformed Jellyfin PlaybackInfo media source id');
    }
    return first;
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
    return mediaInfo.copyWith(
      audioTracks: [for (final track in mediaInfo.audioTracks) track.withSelected(track.id == selectedStreamId)],
    );
  }

  /// Restrict sidecar identity to the subtitle rows this open actually fetched
  /// as sidecars.
  ///
  /// Plezy's device profile declares every *text* subtitle format with
  /// `Method: External`, so Jellyfin returns `DeliveryMethod: External` and a
  /// `DeliveryUrl` even for text streams embedded in a direct-played container
  /// whose container cannot carry subtitles in the delivered form.
  /// [_buildExternalSubtitles] correctly skips those, and the native player
  /// reads them out of the container instead — but the leftover delivery URL
  /// makes the shared track matchers demand a sidecar that will never load,
  /// which leaves automatic subtitle selection permanently unresolved.
  ///
  /// `IsExternal` rows are left alone: a stream that lives in a separate file
  /// is absent from the container whether or not this open managed to build a
  /// sidecar URL for it, so it must never fuzzy-match a native track.
  MediaSourceInfo _withSidecarBackedSubtitleIdentity(
    MediaSourceInfo mediaInfo,
    List<PlaybackSubtitleSidecar> sidecars,
  ) {
    if (mediaInfo.subtitleTracks.isEmpty) return mediaInfo;
    final sidecarSourceIds = {for (final sidecar in sidecars) ?sidecar.sourceStreamId};
    return mediaInfo.copyWith(
      subtitleTracks: [
        for (final track in mediaInfo.subtitleTracks)
          track.isExternalFile || sidecarSourceIds.contains(track.id) ? track : track.withoutSidecarIdentity(),
      ],
    );
  }

  String? _jellyfinSubtitleFallbackPath(String itemId, String? mediaSourceId, MediaSubtitleTrack track) {
    final sourceId = mediaSourceId;
    final streamIndex = track.index ?? track.id;
    final codec = track.codec;
    if (sourceId == null || codec == null || codec.isEmpty) return null;
    // The endpoint keys off the *format*, not the codec name Jellyfin reports: it calls SRT streams
    // `subrip` and WebVTT ones `webvtt`, so the raw name would ask for `Stream.subrip` and get
    // nothing. Only load-bearing since extracted rows without a `DeliveryUrl` started coming
    // through here.
    final extension = CodecUtils.getSubtitleExtension(codec);
    final path = Uri(
      pathSegments: ['Videos', itemId, sourceId, 'Subtitles', streamIndex.toString(), 'Stream.$extension'],
    ).path;
    return path.startsWith('/') ? path : '/$path';
  }

  /// Sidecars this open should fetch.
  ///
  /// Never the row the server burned in, whatever its source: those pixels are already in the
  /// video, and fetching a copy would draw it twice.
  ///
  /// Never a bitmap on a transcode either. The profile only ever offers `External` for text, so a
  /// bitmap falls through to `Encode` and is burned whatever we ask for - an external bitmap *file*
  /// included, which is why this is not just an embedded-row rule.
  ///
  /// Otherwise: a real external file always, since it is a file whether the video is transcoded or
  /// not; and an embedded text row only on a transcode, where Jellyfin can extract it on demand.
  /// That is how a *secondary* track still renders over a transcode whose primary is painted into
  /// the picture. On a direct play embedded rows are absent on purpose - the native player reads
  /// them out of the container itself.
  List<PlaybackSubtitleSidecar> _buildExternalSubtitles(
    String itemId,
    String? mediaSourceId,
    MediaSourceInfo mediaInfo, {
    bool isTranscoding = false,
    int? burnedSourceStreamId,
  }) {
    final externalSubtitles = <PlaybackSubtitleSidecar>[];
    for (final track in mediaInfo.subtitleTracks) {
      if (burnedSourceStreamId != null && track.id == burnedSourceStreamId) continue;
      final isText = CodecUtils.isTextSubtitleCodec(track.codec);
      if (isTranscoding && !isText) continue;
      if (!track.isExternalFile && !isTranscoding) continue;
      final path = track.key ?? _jellyfinSubtitleFallbackPath(itemId, mediaSourceId, track);
      if (path == null) continue;
      // Jellyfin's subtitle URL is a path relative to baseUrl; build the
      // absolute URL with the api_key query param.
      final url = _withApiKey(path);
      externalSubtitles.add(
        PlaybackSubtitleSidecar(
          sourceStreamId: track.id,
          track: SubtitleTrack.uri(
            url,
            title:
                cleanSubtitleTitle(track.displayTitle ?? track.title, codec: track.codec) ??
                cleanTrackMetadataValue(track.language),
            language: cleanTrackMetadataValue(track.languageCode),
            codec: track.codec,
            isDefault: track.selected,
            isForced: track.forced,
          ),
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
  Future<JellyfinPlaybackBundle?> fetchPlaybackBundle(
    String itemId, {
    int sourceIndex = 0,
    String? sourceId,
    String? preferredSignature,
  }) async {
    final item = await fetchItem(itemId);
    final raw = item?.raw;
    if (raw is! Map<String, dynamic>) return null;
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final availableVersions = jellyfinSourcesToVersions(sources);
    var index = sourceIndex;
    final requestedSourceId = sourceId?.trim();
    var resolvedBySourceId = false;
    if (requestedSourceId != null && requestedSourceId.isNotEmpty) {
      final byId = sources.indexWhere((source) => source is Map<String, dynamic> && source['Id'] == requestedSourceId);
      if (byId >= 0) {
        index = byId;
        resolvedBySourceId = true;
      }
    }
    // Saved-preference signature: only meaningful when the id didn't pin a
    // source (Resume rows omit MediaSources, so launch passes a signature and
    // a stored index that may not fit this item's source ordering).
    if (!resolvedBySourceId && preferredSignature != null && preferredSignature.isNotEmpty) {
      final bySignature = MediaVersion.findMatchingIndex(availableVersions, {preferredSignature});
      if (bySignature != null) index = bySignature;
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
      selectedSourceIndex: index,
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

  /// Audio sibling of [buildDirectStreamUrl]: `/Audio/{id}/stream` with the
  /// same `Static=true` + `api_key` + `DeviceId` self-authentication. Used
  /// for track direct-play fallback, downloads, and external players.
  String buildAudioDirectStreamUrl(String itemId, {String? container, String? mediaSourceId}) {
    return buildJellyfinDirectStreamUrl(
      baseUrl: connection.baseUrl,
      accessToken: connection.accessToken,
      deviceId: connection.deviceId,
      itemId: itemId,
      mediaSegment: 'Audio',
      container: container,
      mediaSourceId: mediaSourceId,
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

  /// Negotiate playback and return a structurally valid successful response.
  /// Typed request/decode/cancellation failures propagate unchanged. A
  /// successful response must be a map with a list-valued `MediaSources`;
  /// the list may be empty for consumer-specific unavailable-stream policy.
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
  /// [audioProfile] extends the DeviceProfile with music direct-play and
  /// audio→mp3 transcode entries for track playback; the video profiles (and
  /// the request body when false) are untouched either way.
  Future<Map<String, dynamic>> getPlaybackInfo(
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

    /// Drop `External` subtitle delivery from the profile, so the server burns
    /// the selected subtitle into a transcode instead of serving it alongside.
    bool burnSubtitles = false,
  }) async {
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
          'TranscodingProfiles': <Map<String, Object?>>[
            const {
              'Type': 'Video',
              'Container': 'ts',
              'Protocol': 'hls',
              'VideoCodec': 'hevc,h264',
              'AudioCodec': 'aac,mp3,ac3,eac3,flac,opus',
            },
            // Track playback transcode target: stereo mp3 over plain http.
            // Appended after the video profile so the first-entry-wins
            // ordering for video output codecs is untouched.
            if (audioProfile)
              const {
                'Type': 'Audio',
                'Container': 'mp3',
                'AudioCodec': 'mp3',
                'Protocol': 'http',
                'Context': 'Streaming',
                'MaxAudioChannels': '2',
              },
          ],
          // Declaring HEVC in DirectPlayProfile.VideoCodec stops the server
          // from forcing a transcode for HEVC sources whose container we
          // already accept — mpv decodes HEVC natively on every platform
          // we ship.
          'DirectPlayProfiles': <Map<String, Object?>>[
            const {
              'Type': 'Video',
              'Container': 'mp4,mkv,m4v,webm,mov,ts',
              'VideoCodec': 'hevc,h264,h265,vp8,vp9,av1,mpeg4,mpeg2video',
              'AudioCodec': 'aac,mp3,mp2,ac3,eac3,flac,opus,vorbis,dts',
            },
            // Music containers/codecs mpv plays natively everywhere.
            if (audioProfile)
              const {
                'Type': 'Audio',
                'Container': 'flac,mp3,ogg,oga,opus,m4a,m4b,aac,alac,wav,aiff,wma,webma',
                'AudioCodec': 'flac,mp3,aac,alac,opus,vorbis,wav,wma',
              },
          ],
          // `Embed` covers direct play and an mkv remux, where the native
          // player reads the subtitle stream straight out of the container.
          // Jellyfin only offers it when the delivered container can carry
          // subtitles, so it is unreachable on an HLS transcode (ts/mp4) and
          // is listed for every format purely for the direct paths.
          //
          // `External` asks the server to extract a stream and serve it as a
          // subtitle file. It is offered only when the caller is not asking for
          // a transcode: on a transcode the owner decision is that the server
          // delivers the picture complete, so every subtitle is burned in and
          // the client fetches nothing alongside it. Jellyfin matches an
          // external profile by text-vs-image format and never consults whether
          // the stream is embedded or a real file, so the list cannot express
          // "files as files, embedded burned" - offering text `External` at all
          // is what made embedded text arrive as a sidecar.
          //
          // With no matching `External` entry the server finds no external
          // profile and falls through to `Encode`, which is also why image
          // formats never appear here: a bitmap handed over as a separate
          // stream alongside a transcode is not something the client can render.
          'SubtitleProfiles': <Map<String, Object?>>[
            const {'Format': 'srt', 'Method': 'Embed'},
            const {'Format': 'ass', 'Method': 'Embed'},
            const {'Format': 'ssa', 'Method': 'Embed'},
            const {'Format': 'vtt', 'Method': 'Embed'},
            const {'Format': 'pgssub', 'Method': 'Embed'},
            const {'Format': 'dvdsub', 'Method': 'Embed'},
            const {'Format': 'dvbsub', 'Method': 'Embed'},
            if (!burnSubtitles) ...const [
              {'Format': 'srt', 'Method': 'External'},
              {'Format': 'ass', 'Method': 'External'},
              {'Format': 'ssa', 'Method': 'External'},
              {'Format': 'vtt', 'Method': 'External'},
            ],
          ],
        },
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    if (data is! Map<String, dynamic> || data['MediaSources'] is! List) {
      throw MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        statusCode: response.statusCode,
        message: 'Malformed Jellyfin PlaybackInfo response',
      );
    }
    return data;
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

  /// Shared body for the `/Sessions/Playing[/Progress]` pair — only [path] and
  /// [isPaused] differ between start and progress. Shape mirrors the Jellyfin
  /// SDK's `PlaybackStartInfo`/`PlaybackProgressInfo`: Findroid sends the same
  /// fields, and Jellyfin's session tracker drops events that omit `PlayMethod`
  /// because it has no way to associate progress with an active session row.
  Future<void> _postPlayingState(
    String path, {
    required String itemId,
    required Duration position,
    required bool isPaused,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final response = await _http.post(
      path,
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
        'PlaySessionId': ?_resolvePlaySessionId(playSessionId, itemId),
        'LiveStreamId': ?liveStreamId,
      },
    );
    throwIfHttpError(response);
  }

  /// Session id for a `/Sessions/Playing*` body.
  ///
  /// Normally the caller forwards the id returned by the PlaybackInfo
  /// negotiation. Callers that never negotiated one — the offline
  /// watch-progress sync, which replays a recorded position — leave it null,
  /// which Emby rejects with HTTP 400 (see
  /// [MediaBrowserDialect.requiresPlaySessionId]). The synthesized id is
  /// derived from [itemId] so the started/progress/stopped triple of one replay
  /// lands on a single server-side session row instead of orphaning each call.
  String? _resolvePlaySessionId(String? playSessionId, String itemId) {
    if (playSessionId != null) return playSessionId;
    if (!dialect.requiresPlaySessionId) return null;
    return 'plezy-replay-$itemId';
  }

  /// Tell the server the user has started playing [itemId].
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
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) => _postPlayingState(
    '/Sessions/Playing',
    itemId: itemId,
    position: position,
    isPaused: false,
    playSessionId: playSessionId,
    playMethod: playMethod,
    liveStreamId: liveStreamId,
    mediaSourceId: mediaSourceId,
    audioStreamIndex: audioStreamIndex,
    subtitleStreamIndex: subtitleStreamIndex,
  );

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
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) => _postPlayingState(
    '/Sessions/Playing/Progress',
    itemId: itemId,
    position: position,
    isPaused: isPaused,
    playSessionId: playSessionId,
    playMethod: playMethod,
    liveStreamId: liveStreamId,
    mediaSourceId: mediaSourceId,
    audioStreamIndex: audioStreamIndex,
    subtitleStreamIndex: subtitleStreamIndex,
  );

  /// End-of-playback signal. Final position becomes the resume bookmark.
  /// [duration] is accepted for interface symmetry with Plex but ignored.
  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    final response = await _http.post(
      '/Sessions/Playing/Stopped',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'Failed': false,
        'PlaySessionId': ?_resolvePlaySessionId(playSessionId, itemId),
        'LiveStreamId': ?liveStreamId,
      },
    );
    throwIfHttpError(response);
  }
}
