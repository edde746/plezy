part of '../../jellyfin_client.dart';

mixin _JellyfinLiveTvMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  FailoverHttpClient get _http;
  String? _absolutizeImagePath(String? path);
  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    // ignore: unused_element_parameter
    _HubRetryPolicy? retry,
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
      appLogger.d('Jellyfin Live TV probe failed', error: e);
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
  /// [endsAt] are epoch seconds and bound the time window — Jellyfin uses
  /// ISO 8601 strings on the wire.
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

/// Adapter from [LiveTvSupport] to Jellyfin channel/program helpers.
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
      enableDirectPlay: true,
      enableDirectStream: true,
      enableTranscoding: false,
      allowVideoStreamCopy: true,
      allowAudioStreamCopy: true,
    );
    final sources = info?['MediaSources'];
    final source = sources is List && sources.isNotEmpty && sources.first is Map<String, dynamic>
        ? sources.first as Map<String, dynamic>
        : null;
    if (source == null) return null;

    String? nonEmptyString(dynamic raw) => raw is String && raw.isNotEmpty ? raw : null;

    var playSessionId = nonEmptyString(info?['PlaySessionId']);
    var mediaSourceId = nonEmptyString(source['Id']);
    var liveStreamId = nonEmptyString(source['LiveStreamId']);
    final rawUrl = nonEmptyString(source['DirectStreamUrl']);
    final url = rawUrl != null
        ? _client._withApiKey(rawUrl)
        : _client.buildDirectStreamUrl(
            channelKey,
            container: nonEmptyString(source['Container']),
            mediaSourceId: mediaSourceId,
            playSessionId: playSessionId,
            liveStreamId: liveStreamId,
          );
    final query = Uri.tryParse(url)?.queryParameters;
    playSessionId ??= query?['PlaySessionId'];
    mediaSourceId ??= query?['MediaSourceId'];
    liveStreamId ??= query?['LiveStreamId'];
    return LiveTvStreamResolution(
      url: url,
      playSessionId: playSessionId,
      mediaSourceId: mediaSourceId,
      liveStreamId: liveStreamId,
    );
  }

  @override
  Future<LiveTvPlaybackSession?> startPlayback(String channelKey, {String? dvrKey}) async {
    final resolution = await resolveStreamUrl(channelKey, dvrKey: dvrKey);
    if (resolution == null) return null;
    return _JellyfinLiveTvPlaybackSession(_client, channelKey, resolution);
  }

  /// SharedPreferences key for the locally-persisted favorite-channel list.
  /// Keyed by the compound connection id (`{machineId}/{userId}`) so two
  /// Jellyfin users on the same server don't share favorites.
  String get _favoritesPrefsKey => 'jellyfin_fav_channels:${_client.connection.id}';

  /// Legacy bare-machineId key, kept for one-shot migration.
  String get _legacyFavoritesPrefsKey => 'jellyfin_fav_channels:${_client.serverId}';

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => 'server://${_client.serverId}/jellyfin';

  @override
  String get favoriteStoreKey => 'jellyfin:${_client.connection.id}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.serverSlice;

  /// Local list is the source of truth (preserves order + display fields).
  /// Server-side `IsFavorite` is mirrored on writes via [setFavoriteChannels].
  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() async {
    try {
      return await _client._favoritesRepository.read(key: _favoritesPrefsKey, legacyKey: _legacyFavoritesPrefsKey);
    } catch (e) {
      appLogger.e('Failed to read Jellyfin favorite channels', error: e);
      return const [];
    }
  }

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    try {
      final previous = await fetchFavoriteChannels();
      final previousIds = previous.map((c) => c.id).toSet();
      final newIds = channels.map((c) => c.id).toSet();

      for (final id in newIds.difference(previousIds)) {
        try {
          await _client._setItemFavorite(id, true);
        } catch (e) {
          appLogger.w('Failed to mark Jellyfin channel $id favorite: $e');
        }
      }
      for (final id in previousIds.difference(newIds)) {
        try {
          await _client._setItemFavorite(id, false);
        } catch (e) {
          appLogger.w('Failed to unmark Jellyfin channel $id favorite: $e');
        }
      }

      await _client._favoritesRepository.write(_favoritesPrefsKey, channels);
    } catch (e) {
      appLogger.e('Failed to save Jellyfin favorite channels', error: e);
    }
  }
}

/// A Jellyfin live playback session: one negotiated direct-stream URL plus
/// `/Sessions/Playing*` heartbeats via [JellyfinLiveSessionTracker]. No
/// program-scoped session and no time-shift — [recover] re-opens the same
/// session-less URL.
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
