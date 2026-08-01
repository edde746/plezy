part of '../../plex_client.dart';

const _favoriteChannelsUrl = 'https://epg.provider.plex.tv/settings/favoriteChannels';
const _providerVersionHeader = {'X-Plex-Provider-Version': '5.1'};

mixin _PlexLiveTvClientMethods on _PlexClientInternals implements LiveTvSupport, LiveTvDvrSupport {
  PlexConfig get config;

  List<({String identifier, String gridEndpoint})> get _providerEpg;

  PlexMetadataDto _createTaggedMetadata(Map<String, dynamic> json);

  /// POST the tune endpoint with one retry on transient HTTP failure.
  Future<MediaServerResponse> _postTuneWithRetry(String path, String sessionIdentifier) async {
    final query = {'X-Plex-Session-Identifier': sessionIdentifier};
    try {
      return await _http.post(path, queryParameters: query, timeout: MediaServerTimeouts.tune);
    } on MediaServerHttpException catch (e) {
      if (!e.isTransient) rethrow;
      appLogger.w('Tune channel: transient failure, retrying once', error: e);
      return await _http.post(path, queryParameters: query, timeout: MediaServerTimeouts.tune);
    }
  }

  String? _activityUuid(MediaServerResponse response) => response.headers['x-plex-activity'];

  List<T> _extractContainerList<T>(
    MediaServerResponse response,
    Iterable<String> keys,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final container = _getMediaContainer(response);
    if (container == null) return const [];
    for (final key in keys) {
      final raw = container[key];
      final list = flexibleList(raw);
      if (list == null) continue;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) fromJson(item),
      ];
    }
    return const [];
  }

  T? _extractFirst<T>(MediaServerResponse response, Iterable<String> keys, T Function(Map<String, dynamic>) fromJson) {
    final list = _extractContainerList(response, keys, fromJson);
    return list.firstOrNull;
  }

  void _throwIfFailed(MediaServerResponse response) => throwIfHttpError(response);

  Future<void> _expectOk(Future<MediaServerResponse> Function() call) async {
    final response = await call();
    _throwIfFailed(response);
  }

  String _withQuery(String path, String query) => query.isEmpty ? path : '$path?$query';

  String _subscriptionCreateQuery(MediaSubscriptionCreateRequest request) {
    final parts = <String>[];
    final parameters = request.parameters;
    if (parameters != null && parameters.isNotEmpty) parts.add(parameters);

    final flat = <String, Object?>{
      'targetLibrarySectionID': request.targetLibrarySectionID,
      'targetSectionLocationID': request.targetSectionLocationID,
      'type': request.type,
      if (request.providers != null) 'providers': request.providers,
      for (final entry in request.hints.entries) 'hints[${entry.key}]': entry.value,
      for (final entry in request.prefs.entries) 'prefs[${entry.key}]': entry.value,
      for (final entry in request.params.entries) 'params[${entry.key}]': entry.value,
    };
    final encoded = encodeQueryParameters(flat);
    if (encoded.isNotEmpty) parts.add(encoded);
    return parts.join('&');
  }

  Map<String, dynamic> _prefQuery(String prefix, Map<String, Object?> values) => {
    for (final entry in values.entries) '$prefix[${entry.key}]': entry.value,
  };

  /// Send a live TV timeline heartbeat to keep the transcode session alive.
  ///
  /// Returns an updated [CaptureBuffer] if the response contains a
  /// `TranscodeSession` with seek-range data (used to expand the seekable
  /// window over time).
  Future<CaptureBuffer?> _updateLiveTimeline({
    required String ratingKey,
    required String sessionPath,
    required String sessionIdentifier,
    required String state,
    required int time,
    required int duration,
    required int playbackTime,
  }) async {
    final response = await _getWithFailover(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': sessionPath,
        'state': state,
        'hasMDE': '1',
        'time': time,
        'duration': duration,
        'playbackTime': playbackTime,
        'X-Plex-Session-Identifier': sessionIdentifier,
      },
      // A live timeline ping is a transcode-session keepalive, not a general
      // library fetch. If one ping hits a transient transport/DNS failure,
      // endpoint failover can close the client held by the active session; the
      // server then expires the tuner a few minutes later. Let the next
      // heartbeat retry the current session endpoint instead.
      allowEndpointFailover: false,
    );
    if (response.statusCode != 200) {
      appLogger.e('Live timeline returned ${response.statusCode}: ${response.data}');
      return null;
    }

    // Parse updated capture buffer from TranscodeSession in the response
    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final container = data['MediaContainer'] as Map<String, dynamic>? ?? data;

      // Try CaptureBuffer wrapper first, then TranscodeSession directly
      final captureBufferWrapper = container['CaptureBuffer'];
      if (captureBufferWrapper != null) {
        final cbMap = captureBufferWrapper is List
            ? captureBufferWrapper.firstOrNull as Map<String, dynamic>?
            : captureBufferWrapper as Map<String, dynamic>?;
        if (cbMap != null) {
          final ts = cbMap['TranscodeSession'];
          final tsMap = ts is List ? ts.firstOrNull as Map<String, dynamic>? : ts as Map<String, dynamic>?;
          if (tsMap != null) return CaptureBuffer.fromTranscodeSession(tsMap);
        }
      }

      final transcodeSessions = container['TranscodeSession'];
      if (transcodeSessions is List && transcodeSessions.isNotEmpty) {
        return CaptureBuffer.fromTranscodeSession(transcodeSessions.first as Map<String, dynamic>);
      } else if (transcodeSessions is Map<String, dynamic>) {
        return CaptureBuffer.fromTranscodeSession(transcodeSessions);
      }
    } catch (e) {
      // Parsing failure is non-fatal — just no updated seek range
    }
    return null;
  }

  /// Get all DVR devices configured on this server
  @override
  Future<List<LiveTvDvr>> fetchDvrs() async {
    return _wrapListApiCall<LiveTvDvr>(() => _http.get('/livetv/dvrs'), (response) {
      final container = _getMediaContainer(response);
      if (container != null && container['Dvr'] != null) {
        final rootMappings = container['ChannelMapping'];
        return (container['Dvr'] as List).map((json) {
          final map = Map<String, dynamic>.from(json as Map<String, dynamic>);
          map['ChannelMapping'] ??= rootMappings;
          return LiveTvDvr.fromJson(map);
        }).toList();
      }
      return [];
    }, 'Failed to get DVRs');
  }

  /// Check if this server has at least one DVR configured
  Future<bool> hasDvr() async {
    final dvrs = await fetchDvrs();
    return dvrs.isNotEmpty;
  }

  @override
  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId) async {
    final response = await _http.post('/livetv/dvrs/$dvrId/reloadGuide', timeout: MediaServerTimeouts.receive);
    _throwIfFailed(response);
    return LiveTvActivityResult(value: null, activityUuid: _activityUuid(response));
  }

  /// Get EPG channels using provider lineup endpoints (matches official Plex web client)
  Future<List<LiveTvChannel>> getEpgChannels({String? lineup}) async {
    List<LiveTvChannel> parseChannels(MediaServerResponse response) {
      final container = _getMediaContainer(response);
      if (container == null || (container['Channel'] == null && container['Metadata'] == null)) {
        appLogger.d('EPG channels: container keys=${container?.keys.toList()}, size=${container?['size']}');
        return [];
      }
      final rawChannels = container['Channel'];
      if (rawChannels is List && rawChannels.isNotEmpty) {
        appLogger.d('EPG channel sample: ${rawChannels.first}');
      }
      return _extractContainerList(
        response,
        const ['Channel', 'Metadata'],
        (json) => LiveTvChannel.fromJson(json).copyWith(serverId: serverId, serverName: serverName),
      ).where((ch) => ch.key.isNotEmpty).toList();
    }

    final allChannels = <LiveTvChannel>[];
    for (final provider in _epgProvidersForLineup(lineup)) {
      final isCloudGuide = provider.identifier.startsWith('tv.plex.providers.epg');
      final legacyEndpoint = '/${provider.identifier}/lineups/dvr/channels';

      if (isCloudGuide) {
        try {
          final response = await _getWithFailover('/lineups/plex/channels');
          final parsed = parseChannels(response);
          if (parsed.isNotEmpty) {
            allChannels.addAll(parsed);
            continue;
          }
        } catch (e) {
          appLogger.d(
            'Cloud channel endpoint /lineups/plex/channels unavailable, falling back to $legacyEndpoint',
            error: e,
          );
        }
      }

      try {
        final response = await _getWithFailover(legacyEndpoint);
        allChannels.addAll(parseChannels(response));
      } catch (e) {
        appLogger.e('Failed to get EPG channels from ${provider.identifier} via $legacyEndpoint', error: e);
      }
    }
    return allChannels;
  }

  /// Return EPG providers (already parsed from /media/providers during initialization)
  Future<List<({String identifier, String gridEndpoint})>> _discoverEpgProviders() async {
    return _providerEpg;
  }

  List<({String identifier, String gridEndpoint})> _epgProvidersForLineup(String? lineup) {
    if (lineup == null || lineup.isEmpty) return _providerEpg;
    final matching = _providerEpg.where((p) => p.identifier == lineup || p.gridEndpoint.contains(lineup)).toList();
    return matching.isNotEmpty ? matching : _providerEpg;
  }

  /// Parse a list of JSON items into [LiveTvProgram] objects, skipping any that fail.
  /// A single Metadata entry may carry multiple Media entries representing back-to-back
  /// airings of the same program on the same channel; emit one program per airing.
  List<LiveTvProgram> _parseLiveTvPrograms(List items, {String? providerIdentifier, String? liveDvrKey}) {
    final programs = <LiveTvProgram>[];
    for (final item in items) {
      try {
        final map = item as Map<String, dynamic>;
        final mediaList = (map['Media'] as List?)?.whereType<Map<String, dynamic>>().toList();
        if (mediaList != null && mediaList.length > 1) {
          for (final media in mediaList) {
            programs.add(
              LiveTvProgram.fromJson(map, mediaOverride: media).copyWith(
                serverId: serverId,
                serverName: serverName,
                liveDvrKey: liveDvrKey,
                providerIdentifier: providerIdentifier,
              ),
            );
          }
        } else {
          programs.add(
            LiveTvProgram.fromJson(map).copyWith(
              serverId: serverId,
              serverName: serverName,
              liveDvrKey: liveDvrKey,
              providerIdentifier: providerIdentifier,
            ),
          );
        }
      } catch (e, st) {
        appLogger.w('LiveTvProgram parse failed', error: e, stackTrace: st);
      }
    }
    return programs;
  }

  /// Get guide/program data for channels (EPG grid data)
  /// Discovers grid endpoints from /media/providers on first call and queries all providers
  Future<List<LiveTvProgram>> getEpgGrid({int? beginsAt, int? endsAt}) async {
    final providers = await _discoverEpgProviders();
    if (providers.isEmpty) return [];

    final queryParams = <String, dynamic>{};
    if (beginsAt != null) queryParams['endsAt>'] = beginsAt;
    if (endsAt != null) queryParams['beginsAt<'] = endsAt;

    final allPrograms = <LiveTvProgram>[];

    for (final provider in providers) {
      try {
        final programs = await _wrapListApiCall<LiveTvProgram>(
          () => _http.get(provider.gridEndpoint, queryParameters: queryParams),
          (response) => _parseEpgGridResponse(response, provider.identifier),
          'Failed to get EPG grid from ${provider.identifier}',
        );
        appLogger.d('EPG grid from ${provider.identifier}: ${programs.length} programs');
        allPrograms.addAll(programs);
      } catch (e) {
        appLogger.e('Failed to get EPG grid from provider ${provider.identifier}', error: e);
      }
    }

    return allPrograms;
  }

  /// Parse an EPG grid response into a list of [LiveTvProgram] objects.
  List<LiveTvProgram> _parseEpgGridResponse(MediaServerResponse response, String providerIdentifier) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] is List && (container['Metadata'] as List).isNotEmpty) {
      appLogger.d('EPG grid sample from $providerIdentifier: ${(container['Metadata'] as List).first}');
    }
    final programs = <LiveTvProgram>[];
    if (container != null && container['Metadata'] != null) {
      programs.addAll(_parseLiveTvPrograms(container['Metadata'] as List, providerIdentifier: providerIdentifier));
    }
    // Some responses nest programs inside Hub entries
    if (container != null && container['Hub'] != null) {
      for (final hub in container['Hub'] as List) {
        if (hub is Map && hub['Metadata'] != null) {
          programs.addAll(_parseLiveTvPrograms(hub['Metadata'] as List, providerIdentifier: providerIdentifier));
        }
      }
    }
    return programs;
  }

  /// Get live TV hubs (What's On Now, etc.) from all EPG providers' discover endpoints.
  /// Returns hubs with both display metadata and EPG timing/channel data per item.
  Future<List<LiveTvHubResult>> getLiveTvHubs({int count = 12}) async {
    final providers = await _discoverEpgProviders();
    if (providers.isEmpty) return [];

    final allHubs = <LiveTvHubResult>[];

    for (final provider in providers) {
      try {
        final response = await _getWithFailover(
          '/${provider.identifier}/hubs/discover',
          queryParameters: {
            'count': count,
            'includeStations': 1,
            'includeRecentChannels': 1,
            'includeMeta': 1,
            'includeExternalMetadata': 1,
          },
        );

        final container = _getMediaContainer(response);
        if (container == null || container['Hub'] == null) continue;

        for (final hubJson in container['Hub'] as List) {
          final hub = _parseLiveTvHub(hubJson, provider.identifier);
          if (hub != null) allHubs.add(hub);
        }
      } catch (e) {
        appLogger.e('Failed to get live TV hubs from provider ${provider.identifier}', error: e);
      }
    }

    return allHubs;
  }

  /// Parse a single hub JSON object into a [LiveTvHubResult], or null if parsing fails.
  LiveTvHubResult? _parseLiveTvHub(dynamic hubJson, String providerIdentifier) {
    try {
      final metadataList = hubJson['Metadata'] as List?;
      if (metadataList == null || metadataList.isEmpty) return null;

      final entries = <LiveTvHubEntry>[];
      for (final itemJson in metadataList) {
        if (itemJson is! Map<String, dynamic>) continue;
        _extractLiveTvImages(itemJson);
        final entry = _parseLiveTvHubEntry(itemJson, providerIdentifier);
        if (entry != null) entries.add(entry);
      }

      if (entries.isEmpty) return null;
      return LiveTvHubResult(
        title: hubJson['title'] as String? ?? t.liveTv.unknownHub,
        hubKey: hubJson['key'] as String? ?? '',
        entries: entries,
      );
    } catch (e) {
      appLogger.w('Failed to parse live TV hub', error: e);
      return null;
    }
  }

  /// Parse a single metadata item into a [LiveTvHubEntry], or null if parsing fails.
  LiveTvHubEntry? _parseLiveTvHubEntry(Map<String, dynamic> itemJson, String providerIdentifier) {
    try {
      final dto = PlexMetadataDto.fromJson(itemJson).copyWith(serverId: serverId, serverName: serverName);
      final metadata = PlexMappers.mediaItem(dto);
      final program = LiveTvProgram.fromJson(
        itemJson,
      ).copyWith(serverId: serverId, serverName: serverName, providerIdentifier: providerIdentifier);
      return LiveTvHubEntry(metadata: metadata, program: program);
    } catch (_) {
      return null;
    }
  }

  /// Extract poster/art URLs from the Image array in EPG metadata items.
  /// EPG items often have images only in the Image array (coverPoster, coverArt, etc.)
  /// rather than in the standard thumb/art fields.
  void _extractLiveTvImages(Map item) {
    final images = item['Image'] as List?;
    if (images == null) return;

    for (final img in images) {
      if (img is! Map) continue;
      final type = img['type'] as String?;
      final url = img['url'] as String?;
      if (url == null) continue;

      switch (type) {
        case 'coverPoster':
          // Always prefer coverPoster as thumb for poster display
          item['thumb'] = url;
          break;
        case 'coverArt':
          item['art'] ??= url;
          break;
        case 'background':
          item['art'] ??= url;
          break;
      }
    }
  }

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) async {
    final response = await _getWithFailover('/media/subscriptions/template', queryParameters: {'guid': guid});
    return _extractContainerList(response, const ['SubscriptionTemplate'], SubscriptionTemplate.fromJson);
  }

  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) async {
    final response = await _getWithFailover(
      '/media/subscriptions',
      queryParameters: {'includeGrabs': includeGrabs ? 1 : 0, 'includeStorage': includeStorage ? 1 : 0},
    );
    return _extractContainerList(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) async {
    final response = await _http.post(_withQuery('/media/subscriptions', _subscriptionCreateQuery(request)));
    _throwIfFailed(response);
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  @override
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs) async {
    final response = await _http.put(
      '/media/subscriptions/$subscriptionId',
      queryParameters: _prefQuery('prefs', prefs),
    );
    _throwIfFailed(response);
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  @override
  Future<void> deleteRecordingRule(String subscriptionId) =>
      _expectOk(() => _http.delete('/media/subscriptions/$subscriptionId'));

  @override
  Future<void> processRecordingRules() => _expectOk(() => _http.post('/media/subscriptions/process'));

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() async {
    final response = await _getWithFailover('/media/subscriptions/scheduled');
    return _extractContainerList(response, const ['MediaGrabOperation'], MediaGrabOperation.fromJson);
  }

  @override
  Future<void> cancelGrab(String operationId) {
    if (operationId.isEmpty) throw ArgumentError.value(operationId, 'operationId', 'must not be empty');
    final path = operationId.startsWith('/media/grabbers/operations/')
        ? operationId
        : operationId.startsWith('media/grabbers/operations/')
        ? '/$operationId'
        : '/media/grabbers/operations/$operationId';
    return _expectOk(() => _http.delete(path));
  }

  @override
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  }) async {
    if (ratingKeys.isEmpty) return const [];
    final response = await _getWithFailover(
      '/media/providers/$providerId/media/subscriptions/mapping/${ratingKeys.join(',')}',
      queryParameters: {'includeStorage': includeStorage ? 1 : 0},
    );
    return _extractContainerList(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  /// Tune to a live TV channel.
  ///
  /// POSTs to the tune endpoint and extracts metadata, session info, and
  /// capture buffer data from the response. Call [_buildLiveStreamPath] after
  /// to build the actual stream URL (with optional offset for time-shift).
  Future<
    ({
      PlexMetadataDto metadata,
      String sessionPath,
      String sessionIdentifier,
      CaptureBuffer? captureBuffer,
      int? beginsAt,
    })?
  >
  _tuneChannel(String dvrKey, String channelIdentifier) async {
    try {
      final sessionIdentifier = PlexClient.generateSessionIdentifier();

      final response = await _postTuneWithRetry(
        '/livetv/dvrs/$dvrKey/channels/$channelIdentifier/tune',
        sessionIdentifier,
      );

      if (response.statusCode >= 400) {
        appLogger.w('Tune channel returned status ${response.statusCode}');
        return null;
      }

      final container = _getMediaContainer(response);
      if (container == null) return null;

      final containerStatus = container['status'];
      final statusInt = flexibleInt(containerStatus);
      if (statusInt != null && statusInt != 0 && statusInt != 200) {
        final msg = container['message'] ?? t.liveTv.unknownError;
        appLogger.w('Tune channel error: $msg (status: $containerStatus)');
        throw Exception(msg);
      }

      // Metadata is nested: MediaSubscription[0].MediaGrabOperation[0].Metadata
      // Both may be a List or single Map depending on the response format.
      Map<String, dynamic>? metadataJson;
      int? beginsAt;
      final subscriptions = container['MediaSubscription'];
      final subList = subscriptions is List
          ? subscriptions
          : subscriptions is Map
          ? [subscriptions]
          : null;
      if (subList != null && subList.isNotEmpty) {
        final sub = subList.first as Map<String, dynamic>;

        final timeline = sub['Timeline'];

        // Safely extract the first element if it's a list, or the map itself
        final op = timeline is List
            ? (timeline.isNotEmpty ? timeline.first : null)
            : (timeline is Map ? timeline : null);

        if (op is Map) {
          if (op['Metadata'] case [final Map firstMetadata, ...]) {
            if (firstMetadata['Media'] case [final Map firstMedia, ...]) {
              beginsAt = flexibleInt(firstMedia['beginsAt']);
              appLogger.d('beginsAt=$beginsAt');
            }
          }
        }

        final ops = sub['MediaGrabOperation'];
        final opList = ops is List
            ? ops
            : ops is Map
            ? [ops]
            : null;
        if (opList != null && opList.isNotEmpty) {
          final op = opList.first as Map<String, dynamic>;
          final nested = op['Metadata'];
          if (nested is Map<String, dynamic>) {
            metadataJson = nested;
          } else if (nested is List && nested.isNotEmpty) {
            metadataJson = nested.first as Map<String, dynamic>;
          }
        }
      }
      if (metadataJson == null) {
        final fallback = container['Metadata'];
        if (fallback is List && fallback.isNotEmpty) {
          metadataJson = fallback.first as Map<String, dynamic>;
        } else if (fallback is Map<String, dynamic>) {
          metadataJson = fallback;
        }
      }

      if (metadataJson == null) {
        appLogger.w(
          'Tune channel failed: ${container['message'] ?? 'no metadata'} (status: ${container['status']}, keys: ${container.keys.toList()})',
        );
        return null;
      }

      // Tune response may return XML-style string values where fromJson expects nums.
      PlexClient._coerceNumericFields(metadataJson);

      final metadata = _createTaggedMetadata(metadataJson);

      final sessionPath = metadataJson['key'] as String?;
      if (sessionPath == null) {
        appLogger.w('Tune channel: no session path in metadata key');
        return null;
      }

      // Extract capture buffer from TranscodeSession.
      // May be at the container level OR inside the Metadata object.
      CaptureBuffer? captureBuffer;
      final tsSource = container['TranscodeSession'] ?? metadataJson['TranscodeSession'];
      if (tsSource is List && tsSource.isNotEmpty) {
        captureBuffer = CaptureBuffer.fromTranscodeSession(tsSource.first as Map<String, dynamic>);
      } else if (tsSource is Map<String, dynamic>) {
        captureBuffer = CaptureBuffer.fromTranscodeSession(tsSource);
      }

      // beginsAt may also be on the Media items (not just the GrabOperation)
      // This value is the start of the requested stream, not the current program. So it will effectively be the current time
      if (beginsAt == null) {
        final media = metadataJson['Media'];
        if (media is List && media.isNotEmpty) {
          final firstMedia = media.first;
          if (firstMedia is Map<String, dynamic>) {
            beginsAt = flexibleInt(firstMedia['beginsAt']);
          }
        }
      }

      return (
        metadata: metadata,
        sessionPath: sessionPath,
        sessionIdentifier: sessionIdentifier,
        captureBuffer: captureBuffer,
        beginsAt: beginsAt,
      );
    } catch (e, st) {
      appLogger.e('Failed to tune channel', error: e, stackTrace: st);
      return null;
    }
  }

  /// Build a live TV HLS stream URL (decision + start path).
  ///
  /// [sessionPath] and [sessionIdentifier] come from [_tuneChannel].
  /// [transcodeSessionId] should be reused across seeks within the same
  /// viewing session so the server reuses its capture buffer.
  /// [offsetSeconds] positions the stream at that many seconds from the
  /// capture buffer origin (for time-shift / watch-from-start).
  Future<String?> _buildLiveStreamPath({
    required String sessionPath,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? offsetSeconds,
    bool directStream = true,
    bool directStreamAudio = true,
  }) async {
    try {
      final allParams = <String, String>{
        'hasMDE': '1',
        'path': sessionPath,
        'mediaIndex': '0',
        'partIndex': '0',
        'protocol': _plexVideoHlsProtocol,
        'fastSeek': '1',
        'directPlay': '0',
        'directStream': directStream ? '1' : '0',
        'subtitleSize': '100',
        'audioBoost': '100',
        'location': 'lan',
        'addDebugOverlay': '0',
        'autoAdjustQuality': '0',
        'directStreamAudio': directStreamAudio ? '1' : '0',
        'mediaBufferSize': '157286',
        'session': transcodeSessionId,
        // Prevent Plex from auto-selecting and burning tuner captions into the video.
        // Captions that survive direct stream remain player-selectable text tracks.
        'subtitles': 'none',
        'copyts': '0',
        'Accept-Language': 'en',
        'X-Plex-Session-Identifier': sessionIdentifier,
        'X-Plex-Client-Profile-Extra': _buildPlexHlsClientProfileExtra(),
        'X-Plex-Incomplete-Segments': '1',
        'X-Plex-Product': config.product,
        'X-Plex-Version': config.version,
        'X-Plex-Client-Identifier': config.clientIdentifier,
        'X-Plex-Platform': 'Generic',
        'X-Plex-Client-Profile-Name': 'Generic',
        if (offsetSeconds != null) 'offset': offsetSeconds.toString(),
        if (config.token != null) 'X-Plex-Token': config.token!,
      };

      // '%20' for spaces as Plex requires — not `Uri.queryParameters`, which
      // emits `+`.
      final queryString = encodeQueryParameters(allParams);

      // Decision — wrapper around the same transport so no default X-Plex-*
      // HTTP headers leak through (everything travels in the query string).
      // Not closed: the underlying client is owned by `_http`.
      final decisionClient = MediaServerHttpClient(
        client: _http.inner,
        connectTimeout: MediaServerTimeouts.connect,
        receiveTimeout: MediaServerTimeouts.receive,
        defaultHeaders: {'Accept-Language': 'en'},
      );
      final decisionUrl = '${config.baseUrl}$_plexVideoTranscodeBaseEndpoint/decision?$queryString';
      final decisionResponse = await decisionClient.get(decisionUrl);

      if (decisionResponse.statusCode != 200) {
        appLogger.w('Decision returned ${decisionResponse.statusCode}');
        return null;
      }

      // Log decision response for diagnostics (the web client parses this XML
      // to extract generalDecisionCode, mdeDecisionCode, transcodeDecisionCode).
      final decisionBody = decisionResponse.data?.toString() ?? '';
      if (decisionBody.isNotEmpty) {
        appLogger.d(
          'Decision response: ${decisionBody.length > 500 ? '${decisionBody.substring(0, 500)}...' : decisionBody}',
        );
      }

      // Token is added by the caller via .withPlexToken()
      final startParams = Map<String, String>.from(allParams)..remove('X-Plex-Token');
      final startQuery = encodeQueryParameters(startParams);

      return '$_plexVideoHlsStartEndpoint?$startQuery';
    } catch (e, st) {
      appLogger.e('Failed to build live stream path', error: e, stackTrace: st);
      return null;
    }
  }

  /// Compose a fully-qualified live stream URL from a relative
  /// [streamPath] (returned by [_buildLiveStreamPath]) by prefixing the
  /// configured base URL and appending the Plex token. Centralizes the
  /// `'${config.baseUrl}$streamPath'.withPlexToken(config.token)` pattern
  /// so token placement / base-URL handling lives in one place.
  String _buildLiveStreamUrl(String streamPath) {
    return '${config.baseUrl}$streamPath'.withPlexToken(config.token);
  }

  /// Build the source URI for favorite channels: `server://{machineIdentifier}/{providerIdentifier}`
  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async {
    final providers = _epgProvidersForLineup(lineup);
    final providerIdentifier = providers.isNotEmpty ? providers.first.identifier : 'tv.plex.provider.epg';
    final machineId = config.machineIdentifier ?? serverId;
    return 'server://$machineId/$providerIdentifier';
  }

  /// Get favorite channels from the Plex cloud.
  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() async {
    final response = await _http.get(_favoriteChannelsUrl, headers: _providerVersionHeader);
    _throwIfFailed(response);
    final container = _getMediaContainer(response);
    if (container == null) {
      throw const FormatException('Plex favorite-channel response is missing MediaContainer');
    }
    final rows = container['FavoriteChannel'];
    if (rows == null) return const [];
    if (rows is! List) {
      throw const FormatException('Plex FavoriteChannel must be a list');
    }
    return rows.map((json) => FavoriteChannel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Update favorite channels on the Plex cloud.
  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    try {
      await _expectOk(
        () => _http.put(
          _favoriteChannelsUrl,
          body: channels.map((c) => c.toJson()).toList(),
          headers: _providerVersionHeader,
        ),
      );
    } catch (e, stackTrace) {
      appLogger.e('Failed to update favorite channels', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  LiveTvSupport get liveTv => this as LiveTvSupport;

  @override
  LiveTvDvrSupport get dvr => this as LiveTvDvrSupport;

  @override
  Future<bool> isAvailable() => hasDvr();

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => getEpgChannels(lineup: lineup);

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return getEpgGrid(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async => null;

  @override
  Future<LiveTvPlaybackSession?> startPlayback(String channelKey, {String? dvrKey}) {
    if (dvrKey == null) {
      appLogger.w('Plex live playback requires a dvrKey to tune $channelKey');
      return Future.value(null);
    }
    return _PlexLiveTvPlaybackSession.start(this as PlexClient, dvrKey: dvrKey, channelKey: channelKey);
  }

  @override
  String get favoriteStoreKey => 'plex:${config.clientIdentifier}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.sharedFullList;
}

/// A tuned Plex DVR transcode session. Holds the tune outputs
/// (`sessionPath` / `sessionIdentifier`) plus the `transcodeSessionId` that
/// must be reused across time-shift rebuilds so the server reuses its
/// capture buffer.
class _PlexLiveTvPlaybackSession implements LiveTvPlaybackSession {
  final PlexClient _client;
  final String _dvrKey;
  final String _channelKey;
  final String _sessionPath;
  final String _sessionIdentifier;
  final String _transcodeSessionId;

  /// Degradation flags are session state (a recovered session keeps its
  /// degraded profile for every URL it builds), not per-call options.
  final bool _directStream;
  final bool _directStreamAudio;

  @override
  final LiveProgramInfo program;

  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.retainSession;

  @override
  final CaptureBuffer? captureBuffer;

  _PlexLiveTvPlaybackSession._(
    this._client,
    this._dvrKey,
    this._channelKey,
    this._sessionPath,
    this._sessionIdentifier,
    this._transcodeSessionId,
    this._directStream,
    this._directStreamAudio, {
    required this.program,
    required this.captureBuffer,
  });

  /// Tune [channelKey] on [dvrKey]. The stream URL is built lazily via
  /// [streamUrlAt] so a watch-from-start decision between tune and first
  /// open doesn't cost an extra transcode-decision round-trip.
  static Future<_PlexLiveTvPlaybackSession?> start(
    PlexClient client, {
    required String dvrKey,
    required String channelKey,
    bool directStream = true,
    bool directStreamAudio = true,
  }) async {
    final tuneResult = await client._tuneChannel(dvrKey, channelKey);
    if (tuneResult == null) return null;

    return _PlexLiveTvPlaybackSession._(
      client,
      dvrKey,
      channelKey,
      tuneResult.sessionPath,
      tuneResult.sessionIdentifier,
      PlexClient.generateSessionIdentifier(),
      directStream,
      directStreamAudio,
      program: LiveProgramInfo(
        id: tuneResult.metadata.ratingKey,
        durationMs: tuneResult.metadata.duration,
        beginsAt: tuneResult.beginsAt,
      ),
      captureBuffer: tuneResult.captureBuffer,
    );
  }

  @override
  bool get canTimeShift => captureBuffer != null;

  @override
  Future<String?> streamUrlAt({int? offsetSeconds}) async {
    final streamPath = await _client._buildLiveStreamPath(
      sessionPath: _sessionPath,
      sessionIdentifier: _sessionIdentifier,
      transcodeSessionId: _transcodeSessionId,
      offsetSeconds: offsetSeconds,
      directStream: _directStream,
      directStreamAudio: _directStreamAudio,
    );
    return streamPath == null ? null : _client._buildLiveStreamUrl(streamPath);
  }

  @override
  Future<CaptureBuffer?> reportTimeline({required String state, required int positionMs, required int durationMs}) {
    // Plex rejects timeline pings where time > duration; grow duration to
    // match — otherwise Tunarr-style short synthetic programs 400 mid-stream.
    final duration = durationMs >= positionMs ? durationMs : positionMs;
    return _client._updateLiveTimeline(
      // The program ratingKey from tune metadata, not the channel key.
      ratingKey: program.id ?? _channelKey,
      sessionPath: _sessionPath,
      sessionIdentifier: _sessionIdentifier,
      state: state,
      time: positionMs,
      duration: duration,
      playbackTime: positionMs,
    );
  }

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) {
    // Re-tune for a fresh capture session — the previous one expires while
    // the player exhausts its reconnect attempts.
    return start(
      _client,
      dvrKey: _dvrKey,
      channelKey: _channelKey,
      directStream: directStream,
      directStreamAudio: directStreamAudio,
    );
  }
}
