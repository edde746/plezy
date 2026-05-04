part of '../../plex_client.dart';

const _favoriteChannelsUrl = 'https://epg.provider.plex.tv/settings/favoriteChannels';
const _providerVersionHeader = {'X-Plex-Provider-Version': '5.1'};

mixin _PlexLiveTvClientMethods on MediaServerCacheMixin {
  PlexConfig get config;
  MediaServerHttpClient get _http;

  @override
  String get serverId;

  @override
  String? get serverName;

  List<({String identifier, String gridEndpoint})> get _providerEpg;

  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    // ignore: unused_element_parameter
    Map<String, String>? headers,
    Duration? timeout,
    // ignore: unused_element_parameter
    AbortController? abort,
  });

  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response);
  PlexMetadataDto _createTaggedMetadata(Map<String, dynamic> json);
  List<PlexMetadataDto> _extractMetadataList(MediaServerResponse response);

  Future<List<T>> _wrapListApiCall<T>(
    Future<MediaServerResponse> Function() apiCall,
    List<T> Function(MediaServerResponse response) parseResponse,
    String errorMessage,
  );

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
    final encoded = MediaServerHttpClient.encodeQueryParameters(flat);
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
  Future<CaptureBuffer?> updateLiveTimeline({
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
  Future<List<LiveTvDvr>> getDvrs() async {
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
    final dvrs = await getDvrs();
    return dvrs.isNotEmpty;
  }

  Future<LiveTvServerStatus> getLiveTvServerStatus() async {
    final response = await _getWithFailover('/');
    final container = _getMediaContainer(response);
    return LiveTvServerStatus.fromJson(container ?? const <String, dynamic>{});
  }

  Future<LiveTvDvr?> getDvr(String dvrId) async {
    final response = await _getWithFailover('/livetv/dvrs/$dvrId');
    final container = _getMediaContainer(response);
    final rootMappings = container?['ChannelMapping'];
    return _extractFirst(response, const ['Dvr'], (json) {
      final map = Map<String, dynamic>.from(json)..putIfAbsent('ChannelMapping', () => rootMappings);
      return LiveTvDvr.fromJson(map);
    });
  }

  Future<LiveTvActivityResult<LiveTvDvr?>> createDvr({
    required List<String> devices,
    required List<String> lineups,
    String? language,
    String? country,
    String? postalCode,
  }) async {
    final response = await _http.post(
      '/livetv/dvrs',
      queryParameters: {
        'device': devices,
        'lineup': lineups,
        ...?(language == null ? null : {'language': language}),
        ...?(country == null ? null : {'country': country}),
        ...?(postalCode == null ? null : {'postalCode': postalCode}),
      },
      timeout: MediaServerTimeouts.receive,
    );
    _throwIfFailed(response);
    return LiveTvActivityResult(
      value: _extractFirst(response, const ['Dvr'], LiveTvDvr.fromJson),
      activityUuid: _activityUuid(response),
    );
  }

  Future<void> deleteDvr(String dvrId) => _expectOk(() => _http.delete('/livetv/dvrs/$dvrId'));

  Future<void> updateDvrPrefs(String dvrId, Map<String, Object?> prefs) =>
      _expectOk(() => _http.put('/livetv/dvrs/$dvrId/prefs', queryParameters: prefs));

  Future<void> attachDeviceToDvr(String dvrId, String deviceId) =>
      _expectOk(() => _http.put('/livetv/dvrs/$dvrId/devices/$deviceId'));

  Future<void> detachDeviceFromDvr(String dvrId, String deviceId) =>
      _expectOk(() => _http.delete('/livetv/dvrs/$dvrId/devices/$deviceId'));

  Future<void> addLineupToDvr(String dvrId, String lineupUri) =>
      _expectOk(() => _http.put('/livetv/dvrs/$dvrId/lineups', queryParameters: {'lineup': lineupUri}));

  Future<void> removeLineupFromDvr(String dvrId, String lineupUri) =>
      _expectOk(() => _http.delete('/livetv/dvrs/$dvrId/lineups', queryParameters: {'lineup': lineupUri}));

  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId) async {
    final response = await _http.post('/livetv/dvrs/$dvrId/reloadGuide', timeout: MediaServerTimeouts.receive);
    _throwIfFailed(response);
    return LiveTvActivityResult(value: null, activityUuid: _activityUuid(response));
  }

  Future<void> cancelGuideReload(String dvrId) => _expectOk(() => _http.delete('/livetv/dvrs/$dvrId/reloadGuide'));

  Future<List<MediaGrabber>> getGrabbers({String? protocol}) async {
    final response = await _getWithFailover(
      '/media/grabbers',
      queryParameters: {
        ...?(protocol == null ? null : {'protocol': protocol}),
      },
    );
    return _extractContainerList(response, const ['MediaGrabber'], MediaGrabber.fromJson);
  }

  Future<List<MediaGrabberDevice>> getGrabberDevices() async {
    final response = await _getWithFailover('/media/grabbers/devices');
    return _extractContainerList(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson);
  }

  Future<LiveTvActivityResult<List<MediaGrabberDevice>>> discoverGrabberDevices() async {
    final response = await _http.post('/media/grabbers/devices/discover', timeout: MediaServerTimeouts.receive);
    _throwIfFailed(response);
    return LiveTvActivityResult(
      value: _extractContainerList(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson),
      activityUuid: _activityUuid(response),
    );
  }

  Future<MediaGrabberDevice?> getGrabberDevice(String deviceId) async {
    final response = await _getWithFailover('/media/grabbers/devices/$deviceId');
    return _extractFirst(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson);
  }

  Future<MediaGrabberDevice?> addGrabberDevice(String uri, {String? grabberId}) async {
    final path = grabberId == null ? '/media/grabbers/devices' : '/media/grabbers/$grabberId/devices';
    final response = await _http.post(path, queryParameters: {'uri': uri});
    _throwIfFailed(response);
    return _extractFirst(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson);
  }

  Future<void> updateGrabberDevice(String deviceId, {bool? enabled, String? title}) => _expectOk(
    () => _http.put(
      '/media/grabbers/devices/$deviceId',
      queryParameters: {
        ...?(enabled == null ? null : {'enabled': enabled ? 1 : 0}),
        ...?(title == null ? null : {'title': title}),
      },
    ),
  );

  Future<void> deleteGrabberDevice(String deviceId) =>
      _expectOk(() => _http.delete('/media/grabbers/devices/$deviceId'));

  Future<List<MediaGrabberDeviceChannel>> getGrabberDeviceChannels(String deviceId) async {
    final response = await _getWithFailover('/media/grabbers/devices/$deviceId/channels');
    return _extractContainerList(response, const ['DeviceChannel'], MediaGrabberDeviceChannel.fromJson);
  }

  Future<LiveTvActivityResult<MediaGrabberDevice?>> scanGrabberDevice(
    String deviceId, {
    String? source,
    Map<String, Object?> prefs = const {},
    String? network,
    String? country,
  }) async {
    final response = await _http.post(
      '/media/grabbers/devices/$deviceId/scan',
      queryParameters: {
        ...?(source == null ? null : {'source': source}),
        for (final entry in prefs.entries) 'prefs[${entry.key}]': entry.value,
        ...?(network == null ? null : {'network': network}),
        ...?(country == null ? null : {'country': country}),
      },
      timeout: MediaServerTimeouts.receive,
    );
    _throwIfFailed(response);
    return LiveTvActivityResult(
      value: _extractFirst(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson),
      activityUuid: _activityUuid(response),
    );
  }

  Future<MediaGrabberDevice?> cancelGrabberDeviceScan(String deviceId) async {
    final response = await _http.delete('/media/grabbers/devices/$deviceId/scan');
    _throwIfFailed(response);
    return _extractFirst(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson);
  }

  Future<MediaGrabberDevice?> saveGrabberDeviceChannelMap(
    String deviceId,
    MediaGrabberChannelMapRequest request,
  ) async {
    final response = await _http.put(
      '/media/grabbers/devices/$deviceId/channelmap',
      queryParameters: {
        if (request.channelsEnabled.isNotEmpty) 'channelsEnabled': request.channelsEnabled.join(','),
        for (final entry in request.channelMapping.entries) 'channelMapping[${entry.key}]': entry.value,
        for (final entry in request.channelMappingByKey.entries) 'channelMappingByKey[${entry.key}]': entry.value,
      },
    );
    _throwIfFailed(response);
    return _extractFirst(response, const ['Device', 'Devices'], MediaGrabberDevice.fromJson);
  }

  Future<void> updateGrabberDevicePrefs(String deviceId, Map<String, Object?> prefs) =>
      _expectOk(() => _http.put('/media/grabbers/devices/$deviceId/prefs', queryParameters: prefs));

  String buildGrabberDeviceThumbUrl(String deviceId, int version) =>
      '${config.baseUrl}/media/grabbers/devices/$deviceId/thumb/$version'.withPlexToken(config.token);

  Future<List<LiveTvCountry>> getEpgCountries() async {
    final response = await _getWithFailover('/livetv/epg/countries');
    return _extractContainerList(response, const ['Country'], LiveTvCountry.fromJson);
  }

  Future<List<LiveTvLanguage>> getEpgLanguages() async {
    final response = await _getWithFailover('/livetv/epg/languages');
    return _extractContainerList(response, const ['Language'], LiveTvLanguage.fromJson);
  }

  Future<List<LiveTvRegion>> getEpgRegions(String country, String epgId) async {
    final response = await _getWithFailover('/livetv/epg/countries/$country/$epgId/regions');
    return _extractContainerList(response, const ['Region'], LiveTvRegion.fromJson);
  }

  Future<LiveTvLineupResult> getEpgLineups(String country, String epgId, {String? postalCode, String? region}) async {
    final path = region == null
        ? '/livetv/epg/countries/$country/$epgId/lineups'
        : '/livetv/epg/countries/$country/$epgId/regions/$region/lineups';
    final response = await _getWithFailover(
      path,
      queryParameters: {
        ...?(postalCode == null ? null : {'postalCode': postalCode}),
      },
    );
    final container = _getMediaContainer(response);
    return LiveTvLineupResult(
      lineupGroupUuid: container?['uuid'] as String?,
      lineups: _extractContainerList(response, const ['Lineup'], LiveTvLineup.fromJson),
    );
  }

  Future<List<LiveTvChannel>> getEpgChannelsForLineup(String lineupUri) async {
    final response = await _getWithFailover('/livetv/epg/channels', queryParameters: {'lineup': lineupUri});
    return _extractContainerList(response, const [
      'Channel',
    ], (json) => LiveTvChannel.fromJson(json).copyWith(serverId: serverId, serverName: serverName));
  }

  Future<List<LiveTvLineup>> getEpgChannelsForLineups(List<String> lineupUris) async {
    final response = await _getWithFailover('/livetv/epg/lineupchannels', queryParameters: {'lineup': lineupUris});
    return _extractContainerList(response, const ['Lineup'], LiveTvLineup.fromJson);
  }

  Future<List<ChannelMapping>> computeEpgChannelMap({required String deviceUri, required String lineupUri}) async {
    final response = await _getWithFailover(
      '/livetv/epg/channelmap',
      queryParameters: {'device': deviceUri, 'lineup': lineupUri},
    );
    return _extractContainerList(response, const ['ChannelMapping'], ChannelMapping.fromJson);
  }

  Future<LiveTvActivityResult<Map<String, dynamic>?>> findBestLineup({
    required String deviceUri,
    required String lineupGroupUri,
  }) async {
    final response = await _getWithFailover(
      '/livetv/epg/lineup',
      queryParameters: {'device': deviceUri, 'lineupGroup': lineupGroupUri},
      timeout: MediaServerTimeouts.receive,
    );
    return LiveTvActivityResult(value: _getMediaContainer(response), activityUuid: _activityUuid(response));
  }

  /// Get EPG channels using provider lineup endpoints (matches official Plex web client)
  Future<List<LiveTvChannel>> getEpgChannels({String? lineup}) async {
    List<LiveTvChannel> parseChannels(MediaServerResponse response) {
      final container = _getMediaContainer(response);
      if (container != null && container['Channel'] is List && (container['Channel'] as List).isNotEmpty) {
        appLogger.d('EPG channel sample: ${(container['Channel'] as List).first}');
      }
      if (container != null && container['Channel'] != null) {
        return (container['Channel'] as List)
            .map(
              (json) => LiveTvChannel.fromJson(
                json as Map<String, dynamic>,
              ).copyWith(serverId: serverId, serverName: serverName),
            )
            .where((ch) => ch.key.isNotEmpty)
            .toList();
      }
      if (container != null && container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map(
              (json) => LiveTvChannel.fromJson(
                json as Map<String, dynamic>,
              ).copyWith(serverId: serverId, serverName: serverName),
            )
            .where((ch) => ch.key.isNotEmpty)
            .toList();
      }
      appLogger.d('EPG channels: container keys=${container?.keys.toList()}, size=${container?['size']}');
      return [];
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
        title: hubJson['title'] as String? ?? 'Unknown',
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

  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) async {
    final response = await _getWithFailover('/media/subscriptions/template', queryParameters: {'guid': guid});
    return _extractContainerList(response, const ['SubscriptionTemplate'], SubscriptionTemplate.fromJson);
  }

  Future<List<MediaSubscription>> getRecordingRules({bool includeGrabs = true, bool includeStorage = true}) async {
    final response = await _getWithFailover(
      '/media/subscriptions',
      queryParameters: {'includeGrabs': includeGrabs ? 1 : 0, 'includeStorage': includeStorage ? 1 : 0},
    );
    return _extractContainerList(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  Future<MediaSubscription?> getRecordingRule(
    String subscriptionId, {
    bool includeGrabs = true,
    bool includeStorage = true,
  }) async {
    final response = await _getWithFailover(
      '/media/subscriptions/$subscriptionId',
      queryParameters: {'includeGrabs': includeGrabs ? 1 : 0, 'includeStorage': includeStorage ? 1 : 0},
    );
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) async {
    final response = await _http.post(_withQuery('/media/subscriptions', _subscriptionCreateQuery(request)));
    _throwIfFailed(response);
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs) async {
    final response = await _http.put(
      '/media/subscriptions/$subscriptionId',
      queryParameters: _prefQuery('prefs', prefs),
    );
    _throwIfFailed(response);
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  Future<void> deleteRecordingRule(String subscriptionId) =>
      _expectOk(() => _http.delete('/media/subscriptions/$subscriptionId'));

  Future<MediaSubscription?> moveRecordingRule(String subscriptionId, {String? afterSubscriptionId}) async {
    final response = await _http.put(
      '/media/subscriptions/$subscriptionId/move',
      queryParameters: {
        ...?(afterSubscriptionId == null ? null : {'after': afterSubscriptionId}),
      },
    );
    _throwIfFailed(response);
    return _extractFirst(response, const ['MediaSubscription'], MediaSubscription.fromJson);
  }

  Future<void> processRecordingRules() => _expectOk(() => _http.post('/media/subscriptions/process'));

  Future<List<MediaGrabOperation>> getScheduledRecordings() async {
    final response = await _getWithFailover('/media/subscriptions/scheduled');
    return _extractContainerList(response, const ['MediaGrabOperation'], MediaGrabOperation.fromJson);
  }

  Future<void> cancelGrab(String operationId) {
    if (operationId.isEmpty) throw ArgumentError.value(operationId, 'operationId', 'must not be empty');
    final path = operationId.startsWith('/media/grabbers/operations/')
        ? operationId
        : operationId.startsWith('media/grabbers/operations/')
        ? '/$operationId'
        : '/media/grabbers/operations/$operationId';
    return _expectOk(() => _http.delete(path));
  }

  Future<List<MediaSubscription>> getSubscriptionMapping({
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

  Future<List<MediaProviderInfo>> getMediaProviders() async {
    final response = await _getWithFailover('/media/providers');
    return _extractContainerList(response, const ['MediaProvider'], MediaProviderInfo.fromJson);
  }

  Future<void> registerMediaProvider(String url) =>
      _expectOk(() => _http.post('/media/providers', queryParameters: {'url': url}));

  Future<void> refreshMediaProviders() => _expectOk(() => _http.post('/media/providers/refresh'));

  Future<void> unregisterMediaProvider(String providerId) =>
      _expectOk(() => _http.delete('/media/providers/$providerId'));

  /// Tune to a live TV channel.
  ///
  /// POSTs to the tune endpoint and extracts metadata, session info, and
  /// capture buffer data from the response. Call [buildLiveStreamPath] after
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
  tuneChannel(String dvrKey, String channelIdentifier) async {
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
      final statusInt = containerStatus is num
          ? containerStatus.toInt()
          : containerStatus is String
          ? int.tryParse(containerStatus)
          : null;
      if (statusInt != null && statusInt != 0 && statusInt != 200) {
        final msg = container['message'] ?? 'Unknown error';
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
              final rawBeginsAt = firstMedia['beginsAt'];

              beginsAt = switch (rawBeginsAt) {
                final num n => n.toInt(),
                final String s => int.tryParse(s),
                _ => null,
              };

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
            final rawBeginsAt = firstMedia['beginsAt'];
            beginsAt = switch (rawBeginsAt) {
              final num n => n.toInt(),
              final String s => int.tryParse(s),
              _ => null,
            };
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

  /// Build a live TV stream URL (decision + start path).
  ///
  /// [sessionPath] and [sessionIdentifier] come from [tuneChannel].
  /// [transcodeSessionId] should be reused across seeks within the same
  /// viewing session so the server reuses its capture buffer.
  /// [offsetSeconds] positions the stream at that many seconds from the
  /// capture buffer origin (for time-shift / watch-from-start).
  Future<String?> buildLiveStreamPath({
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
        'protocol': 'http',
        'fastSeek': '1',
        'directPlay': '0',
        'directStream': directStream ? '1' : '0',
        'subtitleSize': '100',
        'audioBoost': '100',
        'location': 'lan',
        'addDebugOverlay': '0',
        'autoAdjustQuality': '0',
        'directStreamAudio': directStreamAudio ? '1' : '0',
        'advancedSubtitles': 'text',
        'mediaBufferSize': '157286',
        'session': transcodeSessionId,
        'subtitles': 'auto',
        'copyts': '0',
        'Accept-Language': 'en',
        'X-Plex-Session-Identifier': sessionIdentifier,
        'X-Plex-Chunked': '1',
        'X-Plex-Incomplete-Segments': '1',
        'X-Plex-Product': config.product,
        'X-Plex-Version': config.version,
        'X-Plex-Client-Identifier': config.clientIdentifier,
        'X-Plex-Platform': config.platform,
        'X-Plex-Client-Profile-Name': 'Plex Desktop',
        if (offsetSeconds != null) 'offset': offsetSeconds.toString(),
        if (config.token != null) 'X-Plex-Token': config.token!,
      };

      // Manual query encoding — use '%20' for spaces as Plex requires.
      final queryString = allParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Decision — separate client so no default X-Plex-* HTTP headers leak through.
      final decisionClient = MediaServerHttpClient(
        connectTimeout: MediaServerTimeouts.connect,
        receiveTimeout: MediaServerTimeouts.receive,
        defaultHeaders: {'Accept-Language': 'en'},
      );
      final decisionUrl = '${config.baseUrl}/video/:/transcode/universal/decision?$queryString';
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
      final startQuery = startParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      return '/video/:/transcode/universal/start?$startQuery';
    } catch (e, st) {
      appLogger.e('Failed to build live stream path', error: e, stackTrace: st);
      return null;
    }
  }

  /// Compose a fully-qualified live stream URL from a relative
  /// [streamPath] (returned by [buildLiveStreamPath]) by prefixing the
  /// configured base URL and appending the Plex token. Centralizes the
  /// `'${config.baseUrl}$streamPath'.withPlexToken(config.token)` pattern
  /// so token placement / base-URL handling lives in one place.
  String buildLiveStreamUrl(String streamPath) {
    return '${config.baseUrl}$streamPath'.withPlexToken(config.token);
  }

  /// Get active live TV sessions
  Future<List<PlexMetadataDto>> _getLiveTvSessions() {
    return _wrapListApiCall<PlexMetadataDto>(
      () => _http.get('/livetv/sessions'),
      _extractMetadataList,
      'Failed to get live TV sessions',
    );
  }

  Future<List<LiveTvSession>> getLiveTvSessionsDetailed() async {
    final response = await _getWithFailover('/livetv/sessions');
    return _extractContainerList(response, const [
      'LiveTVSession',
      'LiveTvSession',
      'Session',
      'Metadata',
    ], LiveTvSession.fromJson);
  }

  Future<LiveTvSession?> getLiveTvSession(String sessionId) async {
    final response = await _getWithFailover('/livetv/sessions/$sessionId');
    return _extractFirst(response, const [
      'LiveTVSession',
      'LiveTvSession',
      'Session',
      'Metadata',
    ], LiveTvSession.fromJson);
  }

  Uri buildNotificationWebSocketUri({List<String>? filters}) {
    final base = Uri.parse(config.baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/:/websocket/notifications',
      queryParameters: {
        if (config.token != null) 'X-Plex-Token': config.token!,
        if (filters != null) 'filters': filters.join(','),
      },
    );
  }

  Uri buildNotificationEventSourceUri({List<String>? filters}) {
    final base = Uri.parse(config.baseUrl);
    return base.replace(
      path: '/:/eventsource/notifications',
      queryParameters: {
        if (config.token != null) 'X-Plex-Token': config.token!,
        if (filters != null) 'filters': filters.join(','),
      },
    );
  }

  /// Build the source URI for favorite channels: `server://{machineIdentifier}/{providerIdentifier}`
  Future<String> buildFavoriteChannelSource({String? lineup}) async {
    final providers = _epgProvidersForLineup(lineup);
    final providerIdentifier = providers.isNotEmpty ? providers.first.identifier : 'tv.plex.provider.epg';
    final machineId = config.machineIdentifier ?? serverId;
    return 'server://$machineId/$providerIdentifier';
  }

  /// Get favorite channels from the Plex cloud.
  Future<List<FavoriteChannel>> getFavoriteChannels() async {
    try {
      final response = await _http.get(_favoriteChannelsUrl, headers: _providerVersionHeader);
      final container = _getMediaContainer(response);
      if (container != null && container['FavoriteChannel'] != null) {
        return (container['FavoriteChannel'] as List)
            .map((json) => FavoriteChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get favorite channels', error: e);
      return [];
    }
  }

  /// Update favorite channels on the Plex cloud.
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    try {
      await _http.put(
        _favoriteChannelsUrl,
        body: channels.map((c) => c.toJson()).toList(),
        headers: _providerVersionHeader,
      );
    } catch (e) {
      appLogger.e('Failed to update favorite channels', error: e);
    }
  }

  /// Plex-specific: live TV sessions (active recordings/playback).
  Future<List<MediaItem>> fetchLiveTvSessions() async {
    final raw = await _getLiveTvSessions();
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  LiveTvSupport get liveTv => _PlexLiveTvSupport(this as PlexClient);
}

/// Plex implementation of [LiveTvSupport] — wraps the existing per-DVR
/// methods. The legacy `tuneChannel` / `buildLiveStreamPath` flow remains on
/// [PlexClient] itself because the player consumes those rich session
/// outputs directly; [resolveStreamUrl] returns `null` so callers route
/// through `client + dvrKey`.
class _PlexLiveTvSupport implements LiveTvSupport {
  final PlexClient _client;
  _PlexLiveTvSupport(this._client);

  @override
  Future<bool> isAvailable() => _client.hasDvr();

  @override
  Future<List<LiveTvDvr>> fetchDvrs() => _client.getDvrs();

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.getEpgChannels(lineup: lineup);

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.getEpgGrid(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async => null;

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) => _client.buildFavoriteChannelSource(lineup: lineup);

  @override
  String get favoriteStoreKey => 'plex:${_client.config.clientIdentifier}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.sharedFullList;

  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() => _client.getFavoriteChannels();

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) => _client.setFavoriteChannels(channels);

  @override
  Future<LiveTvServerStatus> fetchLiveTvServerStatus() => _client.getLiveTvServerStatus();

  @override
  Future<LiveTvDvr?> fetchDvr(String dvrId) => _client.getDvr(dvrId);

  @override
  Future<LiveTvActivityResult<LiveTvDvr?>> createDvr({
    required List<String> devices,
    required List<String> lineups,
    String? language,
    String? country,
    String? postalCode,
  }) => _client.createDvr(
    devices: devices,
    lineups: lineups,
    language: language,
    country: country,
    postalCode: postalCode,
  );

  @override
  Future<void> deleteDvr(String dvrId) => _client.deleteDvr(dvrId);

  @override
  Future<void> updateDvrPrefs(String dvrId, Map<String, Object?> prefs) => _client.updateDvrPrefs(dvrId, prefs);

  @override
  Future<void> attachDeviceToDvr(String dvrId, String deviceId) => _client.attachDeviceToDvr(dvrId, deviceId);

  @override
  Future<void> detachDeviceFromDvr(String dvrId, String deviceId) => _client.detachDeviceFromDvr(dvrId, deviceId);

  @override
  Future<void> addLineupToDvr(String dvrId, String lineupUri) => _client.addLineupToDvr(dvrId, lineupUri);

  @override
  Future<void> removeLineupFromDvr(String dvrId, String lineupUri) => _client.removeLineupFromDvr(dvrId, lineupUri);

  @override
  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId) => _client.reloadGuide(dvrId);

  @override
  Future<void> cancelGuideReload(String dvrId) => _client.cancelGuideReload(dvrId);

  @override
  Future<List<MediaGrabber>> fetchGrabbers({String? protocol}) => _client.getGrabbers(protocol: protocol);

  @override
  Future<List<MediaGrabberDevice>> fetchGrabberDevices() => _client.getGrabberDevices();

  @override
  Future<LiveTvActivityResult<List<MediaGrabberDevice>>> discoverGrabberDevices() => _client.discoverGrabberDevices();

  @override
  Future<MediaGrabberDevice?> fetchGrabberDevice(String deviceId) => _client.getGrabberDevice(deviceId);

  @override
  Future<MediaGrabberDevice?> addGrabberDevice(String uri, {String? grabberId}) =>
      _client.addGrabberDevice(uri, grabberId: grabberId);

  @override
  Future<void> updateGrabberDevice(String deviceId, {bool? enabled, String? title}) =>
      _client.updateGrabberDevice(deviceId, enabled: enabled, title: title);

  @override
  Future<void> deleteGrabberDevice(String deviceId) => _client.deleteGrabberDevice(deviceId);

  @override
  Future<List<MediaGrabberDeviceChannel>> fetchGrabberDeviceChannels(String deviceId) =>
      _client.getGrabberDeviceChannels(deviceId);

  @override
  Future<LiveTvActivityResult<MediaGrabberDevice?>> scanGrabberDevice(
    String deviceId, {
    String? source,
    Map<String, Object?> prefs = const {},
    String? network,
    String? country,
  }) => _client.scanGrabberDevice(deviceId, source: source, prefs: prefs, network: network, country: country);

  @override
  Future<MediaGrabberDevice?> cancelGrabberDeviceScan(String deviceId) => _client.cancelGrabberDeviceScan(deviceId);

  @override
  Future<MediaGrabberDevice?> saveGrabberDeviceChannelMap(String deviceId, MediaGrabberChannelMapRequest request) =>
      _client.saveGrabberDeviceChannelMap(deviceId, request);

  @override
  Future<void> updateGrabberDevicePrefs(String deviceId, Map<String, Object?> prefs) =>
      _client.updateGrabberDevicePrefs(deviceId, prefs);

  @override
  String buildGrabberDeviceThumbUrl(String deviceId, int version) =>
      _client.buildGrabberDeviceThumbUrl(deviceId, version);

  @override
  Future<List<LiveTvCountry>> fetchEpgCountries() => _client.getEpgCountries();

  @override
  Future<List<LiveTvLanguage>> fetchEpgLanguages() => _client.getEpgLanguages();

  @override
  Future<List<LiveTvRegion>> fetchEpgRegions(String country, String epgId) => _client.getEpgRegions(country, epgId);

  @override
  Future<LiveTvLineupResult> fetchEpgLineups(String country, String epgId, {String? postalCode, String? region}) =>
      _client.getEpgLineups(country, epgId, postalCode: postalCode, region: region);

  @override
  Future<List<LiveTvChannel>> fetchEpgChannelsForLineup(String lineupUri) => _client.getEpgChannelsForLineup(lineupUri);

  @override
  Future<List<LiveTvLineup>> fetchEpgChannelsForLineups(List<String> lineupUris) =>
      _client.getEpgChannelsForLineups(lineupUris);

  @override
  Future<List<ChannelMapping>> computeEpgChannelMap({required String deviceUri, required String lineupUri}) =>
      _client.computeEpgChannelMap(deviceUri: deviceUri, lineupUri: lineupUri);

  @override
  Future<LiveTvActivityResult<Map<String, dynamic>?>> findBestLineup({
    required String deviceUri,
    required String lineupGroupUri,
  }) => _client.findBestLineup(deviceUri: deviceUri, lineupGroupUri: lineupGroupUri);

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) => _client.getSubscriptionTemplate(guid);

  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) =>
      _client.getRecordingRules(includeGrabs: includeGrabs, includeStorage: includeStorage);

  @override
  Future<MediaSubscription?> fetchRecordingRule(
    String subscriptionId, {
    bool includeGrabs = true,
    bool includeStorage = true,
  }) => _client.getRecordingRule(subscriptionId, includeGrabs: includeGrabs, includeStorage: includeStorage);

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) =>
      _client.createRecordingRule(request);

  @override
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs) =>
      _client.updateRecordingRule(subscriptionId, prefs);

  @override
  Future<void> deleteRecordingRule(String subscriptionId) => _client.deleteRecordingRule(subscriptionId);

  @override
  Future<MediaSubscription?> moveRecordingRule(String subscriptionId, {String? afterSubscriptionId}) =>
      _client.moveRecordingRule(subscriptionId, afterSubscriptionId: afterSubscriptionId);

  @override
  Future<void> processRecordingRules() => _client.processRecordingRules();

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() => _client.getScheduledRecordings();

  @override
  Future<void> cancelGrab(String operationId) => _client.cancelGrab(operationId);

  @override
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  }) => _client.getSubscriptionMapping(providerId: providerId, ratingKeys: ratingKeys, includeStorage: includeStorage);

  @override
  Future<List<MediaProviderInfo>> fetchMediaProviders() => _client.getMediaProviders();

  @override
  Future<void> registerMediaProvider(String url) => _client.registerMediaProvider(url);

  @override
  Future<void> refreshMediaProviders() => _client.refreshMediaProviders();

  @override
  Future<void> unregisterMediaProvider(String providerId) => _client.unregisterMediaProvider(providerId);

  @override
  Future<List<LiveTvSession>> fetchLiveTvSessionsDetailed() => _client.getLiveTvSessionsDetailed();

  @override
  Future<LiveTvSession?> fetchLiveTvSession(String sessionId) => _client.getLiveTvSession(sessionId);

  @override
  Uri buildNotificationWebSocketUri({List<String>? filters}) => _client.buildNotificationWebSocketUri(filters: filters);

  @override
  Uri buildNotificationEventSourceUri({List<String>? filters}) =>
      _client.buildNotificationEventSourceUri(filters: filters);
}
