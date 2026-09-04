part of '../../jellyfin_client.dart';

mixin _JellyfinLiveTvMethods on _JellyfinClientInternals {
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
  /// dialects use ISO 8601 strings on the wire. The lower bound is sent as
  /// `minEndDate` (programme still running at window start), not
  /// `minStartDate` (started inside the window), so a currently-airing
  /// programme that began before the window still overlaps it.
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
      if (beginsAt != null) 'minEndDate': toDt(beginsAt)!.toIso8601String(),
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
    // TimerId is only present while a recording is actually scheduled/running
    // (the server omits it for cancelled timers). SeriesTimerId alone means a
    // series rule exists but skips this airing, so the series key is only
    // stamped when the airing really records — recordingRuleKey drives both
    // the guide's red dot and the Manage action.
    final timerId = json['TimerId'] as String?;
    final seriesTimerId = json['SeriesTimerId'] as String?;
    final recording = timerId != null && timerId.isNotEmpty;
    return LiveTvProgram(
      key: id,
      ratingKey: id,
      // The program id doubles as the recording seed: getSubscriptionTemplate
      // feeds it to /LiveTv/Timers/Defaults?programId=.
      guid: id,
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
      subscriptionId: recording ? '$_jfTimerRuleKeyPrefix$timerId' : null,
      grandparentSubscriptionId: recording && seriesTimerId != null && seriesTimerId.isNotEmpty
          ? '$_jfSeriesRuleKeyPrefix$seriesTimerId'
          : null,
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

  /// Release a live stream that the PlaybackInfo negotiation opened
  /// (`AutoOpenLiveStream`) but no playback session will ever stop-report.
  /// Without it the server's consumer count never drops and the tuner slot
  /// leaks until an idle timeout (#2198). The server wants `liveStreamId` in
  /// the query string (400 when in the body) and answers 204. Best-effort:
  /// a failure only defers to the server's own reclaim.
  Future<void> _closeLiveStream(String liveStreamId) async {
    try {
      final response = await _http.post('/LiveStreams/Close', queryParameters: {'liveStreamId': liveStreamId});
      throwIfHttpError(response);
    } catch (error, stackTrace) {
      appLogger.w('Failed to close a ${dialect.productName} live stream', error: error, stackTrace: stackTrace);
    }
  }

  @override
  LiveTvSupport get liveTv => _JellyfinLiveTvSupport(this as JellyfinClient);
}

/// Adapter from [LiveTvSupport] to MediaBrowser channel/program helpers.
class _JellyfinLiveTvSupport implements LiveTvSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvSupport(this._client);

  @override
  LiveTvDvrSupport? get dvr => _JellyfinLiveTvDvrSupport(_client);

  @override
  Future<bool> isAvailable() => _client.hasLiveTv();

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.fetchLiveTvChannels();

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.fetchLiveTvPrograms(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  /// Negotiate a stream URL + session identity for [channelKey].
  /// Jellyfin-only: Plex live URLs are only valid after a tune, so the shared
  /// entry point is [startPlayback].
  ///
  /// The server yields one of two real outcomes — HTTP direct *stream* is
  /// hard-disabled server-side, so `SupportsDirectStream` never comes back
  /// without `SupportsDirectPlay`:
  ///
  /// - **DirectPlay**: no `TranscodingUrl`; the client streams the source
  ///   through `/Videos/{id}/stream.{container}?Static=true`. Granted only
  ///   when [quality] is `original` (the server treats an unknown live
  ///   bitrate as 40 Mbps, so any real `MaxStreamingBitrate` cap would deny
  ///   it anyway) and the source matches a `DirectPlayProfiles` entry.
  /// - **Transcode**: an HLS `TranscodingUrl`, capped by the preset's
  ///   bitrate when one is set.
  Future<LiveTvStreamResolution?> _resolveStreamUrl(
    String channelKey, {
    required TranscodeQualityPreset quality,
    bool forceTranscode = false,
  }) async {
    final wantsDirect = quality.isOriginal && !forceTranscode;
    final info = await _client.getPlaybackInfo(
      channelKey,
      // Original sends no ceiling, mirroring the VOD path: a cap below the
      // assumed 40 Mbps live bitrate silently forbids direct play.
      maxStreamingBitrate: quality.isOriginal ? null : (quality.videoBitrateKbps ?? 100_000) * 1000,
      autoOpenLiveStream: true,
      enableDirectPlay: wantsDirect,
      enableDirectStream: wantsDirect,
      enableTranscoding: true,
      allowVideoStreamCopy: true,
      allowAudioStreamCopy: true,
    );
    final sources = info['MediaSources'] as List;
    if (sources.isEmpty) return null;
    final firstSource = sources.first;
    if (firstSource is! Map<String, dynamic>) {
      throw PlaybackException(
        t.liveTv.invalidPlaybackData(product: _client.dialect.productName),
        reason: PlaybackFailureReason.invalidPlaybackData,
      );
    }
    final source = firstSource;

    String? nonEmptyString(dynamic raw) => raw is String && raw.isNotEmpty ? raw : null;

    var playSessionId = nonEmptyString(info['PlaySessionId']);
    var mediaSourceId = nonEmptyString(source['Id']);
    var liveStreamId = nonEmptyString(source['LiveStreamId']);

    final container = nonEmptyString(source['Container']);
    if (wantsDirect && source['SupportsDirectPlay'] == true && container != null) {
      // The server-proxied direct URL jellyfin-web builds (raw tuner `Path`
      // needs client-side reachability probing, so it is deliberately not
      // used). No PlaySessionId in the URL — it travels in the heartbeats.
      final query = <String, String>{
        'Static': 'true',
        'MediaSourceId': ?mediaSourceId,
        'LiveStreamId': ?liveStreamId,
        'DeviceId': _client.connection.deviceId,
      };
      final directPath = Uri(
        path: '/Videos/${_segment(channelKey)}/stream.$container',
        queryParameters: query,
      ).toString();
      return LiveTvStreamResolution(
        url: _client._withApiKey(directPath),
        playSessionId: playSessionId,
        mediaSourceId: mediaSourceId,
        liveStreamId: liveStreamId,
        playMethod: 'DirectPlay',
      );
    }

    final rawUrl = nonEmptyString(source['TranscodingUrl']);
    final rawUri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (rawUrl == null || rawUri == null || !rawUri.path.toLowerCase().endsWith('.m3u8')) {
      appLogger.w('${_client.dialect.productName} Live TV negotiation returned no HLS transcode URL');
      // AutoOpenLiveStream already opened the tuner; bailing without a
      // session means no stop report will ever release it.
      if (liveStreamId != null) {
        unawaited(_client._closeLiveStream(liveStreamId));
      }
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
  Future<LiveTvPlaybackSession?> startPlayback(
    String channelKey, {
    String? dvrKey,
    TranscodeQualityPreset quality = TranscodeQualityPreset.original,
  }) async {
    final resolution = await _resolveStreamUrl(channelKey, quality: quality);
    if (resolution == null) return null;
    return _JellyfinLiveTvPlaybackSession(_client, channelKey, quality, resolution);
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

/// A MediaBrowser live playback session: one negotiated stream URL — direct
/// play or HLS transcode — plus `/Sessions/Playing*` heartbeats via
/// [JellyfinLiveSessionTracker]. No program-scoped session and no time-shift.
class _JellyfinLiveTvPlaybackSession implements LiveTvPlaybackSession {
  final JellyfinClient _client;
  final String _channelKey;
  final TranscodeQualityPreset _quality;
  final String _url;
  final String? _playMethod;
  final String? _liveStreamId;
  final JellyfinLiveSessionTracker _tracker;

  _JellyfinLiveTvPlaybackSession(this._client, this._channelKey, this._quality, LiveTvStreamResolution resolution)
    : _url = resolution.url,
      _playMethod = resolution.playMethod,
      _liveStreamId = resolution.liveStreamId,
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

  /// Intentionally unsupported: the session plays one URL negotiated at
  /// start, so there is no rebuild through which a server-side subtitle
  /// selection could be delivered. Jellyfin's live transcode profile decides
  /// subtitle handling on its own.
  @override
  List<MediaSubtitleTrack> get subtitleTracks => const [];

  @override
  bool get canTimeShift => false;

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) async =>
      offsetSeconds == null && subtitleTrack == null ? _url : null;

  @override
  Future<LiveTimelineUpdate?> reportTimeline({
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

  /// A transcode session returns itself so its negotiated HLS URL is
  /// re-opened — the server rebuilds the transcode job for the same
  /// PlaySessionId. A direct-play session asked to drop [directStream]
  /// re-negotiates a forced transcode instead: that negotiation opens its own
  /// live stream, and the player adopts the replacement without ever
  /// stop-reporting this session, so the old stream is released here. On a
  /// failed re-negotiation this session stays current and is stop-reported by
  /// the normal teardown, which also closes its stream. [directStreamAudio]
  /// has no server-side lever beyond the transcode fallback and is ignored.
  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) async {
    if (_playMethod != 'DirectPlay' || directStream) return this;
    final replacement = await _JellyfinLiveTvSupport(
      _client,
    )._resolveStreamUrl(_channelKey, quality: _quality, forceTranscode: true);
    if (replacement == null) return null;
    final liveStreamId = _liveStreamId;
    if (liveStreamId != null) {
      unawaited(_client._closeLiveStream(liveStreamId));
    }
    return _JellyfinLiveTvPlaybackSession(_client, _channelKey, _quality, replacement);
  }
}
