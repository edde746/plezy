part of '../../jellyfin_client.dart';

mixin _JellyfinLiveTvMethods on _JellyfinClientInternals {
  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    // ignore: unused_element_parameter
    _HubRetryPolicy? retry,
    // ignore: unused_element_parameter
    AbortController? abort,
    // ignore: unused_element_parameter
    Duration? timeout,
    // ignore: unused_element_parameter
    bool allowEndpointFailover,
    // ignore: unused_element_parameter
    HubFetchDiagnostics? diagnostics,
  });

  /// Returns `true` when this server has Live TV configured (channels
  /// available). Probes `/LiveTv/Channels?limit=1`. Used by [MultiServerProvider]
  /// to gate the Live TV menu.
  Future<bool> hasLiveTv() async {
    try {
      final response = await _http.get(
        '/LiveTv/Channels',
        queryParameters: {'limit': '1', 'userId': connection.userId},
      );
      if (response.statusCode != 200) return false;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final total = data['TotalRecordCount'];
        if (total is int) return total > 0;
        final items = data['Items'];
        if (items is List) return items.isNotEmpty;
      }
      return false;
    } catch (e) {
      appLogger.d('${dialect.productName} Live TV probe failed', error: e);
      return false;
    }
  }

  /// Fetch the user's Live TV channel list. Each `BaseItemDto` of type
  /// `TvChannel` is mapped to a [LiveTvChannel].
  Future<List<LiveTvChannel>> fetchLiveTvChannels() async {
    final items = await _safeFetchItemsArray('/LiveTv/Channels', {
      'userId': connection.userId,
      'enableImages': 'true',
      'enableUserData': 'true',
      'sortBy': 'SortName',
      'sortOrder': 'Ascending',
    });
    return items.map(_channelFromJson).toList();
  }

  /// EPG / programs grid. [channelIds] scopes to specific channels (when
  /// empty, the server returns programs across all channels). [beginsAt] /
  /// [endsAt] are epoch seconds and bound the time window — both MediaBrowser
  /// dialects use ISO 8601 strings on the wire.
  Future<List<LiveTvProgram>> fetchLiveTvPrograms({
    List<String> channelIds = const [],
    int? beginsAt,
    int? endsAt,
  }) async {
    DateTime? toDt(int? epoch) => epoch == null ? null : DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
    final params = <String, dynamic>{
      'userId': connection.userId,
      'enableImages': 'true',
      'sortBy': 'StartDate',
      'sortOrder': 'Ascending',
      if (channelIds.isNotEmpty) 'channelIds': channelIds.join(','),
      if (beginsAt != null) 'minStartDate': toDt(beginsAt)!.toIso8601String(),
      if (endsAt != null) 'maxStartDate': toDt(endsAt)!.toIso8601String(),
    };
    final items = await _safeFetchItemsArray('/LiveTv/Programs', params);
    return items.map(_programFromJson).toList();
  }

  LiveTvProgram _programFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String?;

    final tags = json['ImageTags'];
    String? primaryTag;
    if (tags is Map<String, dynamic>) {
      primaryTag = tags['Primary'] as String?;
    }
    final thumbPath = (id != null && primaryTag != null)
        ? _absolutizeImagePath('/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(primaryTag)}')
        : null;
    return LiveTvProgram(
      key: id,
      ratingKey: id,
      guid: null,
      title: json['Name'] as String? ?? t.liveTv.unknownProgram,
      summary: json['Overview'] as String?,
      type: 'episode',
      year: (json['ProductionYear'] as num?)?.toInt(),
      beginsAt: jellyfinIsoToEpochSeconds(json['StartDate'] as String?),
      endsAt: jellyfinIsoToEpochSeconds(json['EndDate'] as String?),
      grandparentTitle: json['SeriesName'] as String?,
      parentTitle: json['SeasonName'] as String?,
      index: (json['IndexNumber'] as num?)?.toInt(),
      parentIndex: (json['ParentIndexNumber'] as num?)?.toInt(),
      thumb: thumbPath,
      art: null,
      channelIdentifier: json['ChannelId'] as String?,
      channelCallSign: json['ChannelCallSign'] as String? ?? json['ChannelName'] as String?,
      live: json['IsLive'] as bool?,
      premiere: json['IsPremiere'] as bool?,
      serverId: serverId,
      serverName: serverName,
    );
  }

  LiveTvChannel _channelFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String? ?? '';
    final name = json['Name'] as String?;
    final number = json['Number'] as String? ?? json['ChannelNumber'] as String?;
    final tags = json['ImageTags'];
    String? primaryTag;
    if (tags is Map<String, dynamic>) {
      primaryTag = tags['Primary'] as String?;
    }
    final thumbPath = primaryTag != null
        ? _absolutizeImagePath('/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(primaryTag)}')
        : null;
    return LiveTvChannel(
      key: id,
      identifier: id,
      callSign: json['CallSign'] as String?,
      title: name,
      thumb: thumbPath,
      art: null,
      number: number,
      hd: false,
      lineup: null,
      slug: null,
      drm: null,
      serverId: serverId,
      serverName: serverName,
    );
  }

  @override
  LiveTvSupport get liveTv => _JellyfinLiveTvSupport(this as JellyfinClient);
}

/// Adapter from [LiveTvSupport] to MediaBrowser channel/program helpers.
class _JellyfinLiveTvSupport implements LiveTvSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvSupport(this._client);

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  Future<bool> isAvailable() => _client.hasLiveTv();

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.fetchLiveTvChannels();

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.fetchLiveTvPrograms(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async {
    final info = await _client.getPlaybackInfo(
      channelKey,
      autoOpenLiveStream: true,
      enableDirectPlay: false,
      enableDirectStream: false,
      enableTranscoding: true,
      allowVideoStreamCopy: true,
      allowAudioStreamCopy: true,
    );
    final sources = info['MediaSources'] as List;
    if (sources.isEmpty) return null;
    final firstSource = sources.first;
    if (firstSource is! Map<String, dynamic>) {
      throw PlaybackException(
        '${_client.dialect.productName} returned invalid Live TV playback data',
        reason: PlaybackFailureReason.invalidPlaybackData,
      );
    }
    final source = firstSource;

    String? nonEmptyString(dynamic raw) => raw is String && raw.isNotEmpty ? raw : null;

    var playSessionId = nonEmptyString(info['PlaySessionId']);
    var mediaSourceId = nonEmptyString(source['Id']);
    var liveStreamId = nonEmptyString(source['LiveStreamId']);
    final rawUrl = nonEmptyString(source['TranscodingUrl']);
    if (rawUrl == null) {
      appLogger.w('${_client.dialect.productName} Live TV negotiation returned no HLS transcode URL');
      return null;
    }
    final rawUri = Uri.tryParse(rawUrl);
    if (rawUri == null || !rawUri.path.toLowerCase().endsWith('.m3u8')) {
      appLogger.w('${_client.dialect.productName} Live TV negotiation returned no HLS transcode URL');
      return null;
    }
    final url = _client._withApiKey(rawUrl);
    final query = Uri.tryParse(url)?.queryParameters;
    playSessionId ??= query?['PlaySessionId'];
    mediaSourceId ??= query?['MediaSourceId'];
    liveStreamId ??= query?['LiveStreamId'];
    return LiveTvStreamResolution(
      url: url,
      playSessionId: playSessionId,
      mediaSourceId: mediaSourceId,
      liveStreamId: liveStreamId,
      playMethod: 'Transcode',
    );
  }

  @override
  Future<LiveTvPlaybackSession?> startPlayback(String channelKey, {String? dvrKey}) async {
    final resolution = await resolveStreamUrl(channelKey, dvrKey: dvrKey);
    if (resolution == null) return null;
    return _JellyfinLiveTvPlaybackSession(_client, channelKey, resolution);
  }

  /// SharedPreferences key for the locally-persisted favorite-channel list.
  /// Keyed by the compound connection id (`{machineId}/{userId}`) so users on
  /// the same MediaBrowser server don't share favorites.
  // Keep the legacy prefix: the connection id isolates both dialects, and changing it would lose Jellyfin ordering.
  String get _favoritesPrefsKey => 'jellyfin_fav_channels:${_client.connection.id}';

  /// Legacy bare-machineId key, kept for one-shot migration.
  String get _legacyFavoritesPrefsKey => 'jellyfin_fav_channels:${_client.serverId}';

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => 'server://${_client.serverId}/jellyfin';

  @override
  String get favoriteStoreKey => 'jellyfin:${_client.connection.id}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.serverSlice;

  Future<List<FavoriteChannel>> _readPersistedFavoriteChannels() =>
      _client._favoritesRepository.read(key: _favoritesPrefsKey, legacyKey: _legacyFavoritesPrefsKey);

  /// Local list is the source of truth (preserves order + display fields).
  /// Server-side `IsFavorite` is mirrored on writes via [setFavoriteChannels].
  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() => _readPersistedFavoriteChannels();

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    final previous = await _readPersistedFavoriteChannels();
    final previousIds = previous.map((channel) => channel.id).toSet();
    final requestedIds = channels.map((channel) => channel.id).toSet();
    final confirmedIds = {...previousIds};
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> applyMutation(String id, bool isFavorite) async {
      try {
        await _client._setItemFavorite(id, isFavorite);
        if (isFavorite) {
          confirmedIds.add(id);
        } else {
          confirmedIds.remove(id);
        }
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        appLogger.w(
          'Failed to update a ${_client.dialect.productName} favorite channel',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    for (final id in requestedIds.difference(previousIds)) {
      await applyMutation(id, true);
    }
    for (final id in previousIds.difference(requestedIds)) {
      await applyMutation(id, false);
    }

    final confirmed = <FavoriteChannel>[
      for (final channel in channels)
        if (confirmedIds.contains(channel.id)) channel,
      for (final channel in previous)
        if (!requestedIds.contains(channel.id) && confirmedIds.contains(channel.id)) channel,
    ];
    await _client._favoritesRepository.write(_favoritesPrefsKey, confirmed);

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }
}

/// A MediaBrowser live playback session: one negotiated HLS transcode URL plus
/// `/Sessions/Playing*` heartbeats via [JellyfinLiveSessionTracker]. No
/// program-scoped session and no time-shift — [recover] re-opens the same
/// negotiated URL.
class _JellyfinLiveTvPlaybackSession implements LiveTvPlaybackSession {
  final JellyfinClient _client;
  final String _channelKey;
  final String _url;
  final JellyfinLiveSessionTracker _tracker;

  _JellyfinLiveTvPlaybackSession(this._client, this._channelKey, LiveTvStreamResolution resolution)
    : _url = resolution.url,
      _tracker = JellyfinLiveSessionTracker(
        playSessionId: resolution.playSessionId,
        mediaSourceId: resolution.mediaSourceId,
        liveStreamId: resolution.liveStreamId,
        playMethod: resolution.playMethod,
      );

  @override
  LiveProgramInfo get program => LiveProgramInfo.none;

  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.stopAndExit;

  @override
  CaptureBuffer? get captureBuffer => null;

  @override
  bool get canTimeShift => false;

  @override
  Future<String?> streamUrlAt({int? offsetSeconds}) async => offsetSeconds == null ? _url : null;

  @override
  Future<CaptureBuffer?> reportTimeline({
    required String state,
    required int positionMs,
    required int durationMs,
  }) async {
    await _tracker.report(
      client: _client,
      itemId: _channelKey,
      state: state,
      position: Duration(milliseconds: positionMs),
      duration: Duration(milliseconds: durationMs),
    );
    return null;
  }

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) async => this;
}
