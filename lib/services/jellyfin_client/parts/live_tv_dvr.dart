part of '../../jellyfin_client.dart';

/// Rule-key prefixes disambiguating the two MediaBrowser timer spaces behind
/// the single opaque rule-key channel the neutral contract exposes. A one-off
/// timer cancels via `DELETE /LiveTv/Timers/{id}` while a series rule deletes
/// via `DELETE /LiveTv/SeriesTimers/{id}`, but the UI hands both through
/// [LiveTvDvrSupport.deleteRecordingRule] — every key this adapter mints
/// carries its space so the dispatch stays inside the adapter.
const String _jfTimerRuleKeyPrefix = 'timer:';
const String _jfSeriesRuleKeyPrefix = 'series:';

String? _stripRuleKeyPrefix(String key, String prefix) =>
    key.startsWith(prefix) && key.length > prefix.length ? key.substring(prefix.length) : null;

/// MediaBrowser (Jellyfin/Emby) implementation of [LiveTvDvrSupport].
///
/// The neutral payload models are Plex wire shapes, so this adapter
/// synthesizes them from the timer APIs:
///
/// - A *rule* is a `SeriesTimerInfoDto` (`/LiveTv/SeriesTimers`).
/// - A *scheduled recording* (grab) is a non-cancelled `TimerInfoDto`
///   (`/LiveTv/Timers`).
/// - The *template* is `/LiveTv/Timers/Defaults?programId=` — the canonical
///   MediaBrowser flow is fetch-defaults, mutate, POST the whole object back
///   to `/LiveTv/Timers` (one airing) or `/LiveTv/SeriesTimers` (series).
///   The defaults payload travels JSON-encoded in the template entry's
///   opaque `parameters` field; setting ids are DTO field names, so the
///   template-driven record-options sheet renders and round-trips them
///   without knowing the backend.
///
/// Create/update POSTs answer 204 (200 on Emby) with an empty body — the
/// created timer id is only observable through a re-fetch, which the
/// recordings tab and guide badge refresh flows already do.
///
/// Emby divergences are absorbed here: no `isActive`/`isScheduled` filters on
/// `GET /LiveTv/Timers` (status is filtered client-side for both dialects)
/// and `Completed` tombstones that Jellyfin never returns.
class _JellyfinLiveTvDvrSupport implements LiveTvDvrSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvDvrSupport(this._client);

  /// Intentionally empty: MediaBrowser has no per-lineup DVR devices, and a
  /// non-empty result would replace the synthesized
  /// `LiveTvServerInfo(dvrKey: backend.id)` identity that channel fetches,
  /// favorites, and playback key off (see
  /// `MultiServerProvider.checkLiveTvAvailability`).
  @override
  Future<List<LiveTvDvr>> fetchDvrs() async => const [];

  /// No MediaBrowser equivalent of Plex's `reloadGuide`; guide refresh
  /// happens server-side on its own schedule. The refresh affordance still
  /// re-fetches channels and grid client-side.
  @override
  Future<void> reloadGuide(String dvrId) async {}

  @override
  bool get supportsRuleProcessing => false;

  @override
  Future<void> processRecordingRules() async {
    throw UnsupportedError('${_client.dialect.productName} has no recording-rule re-evaluation endpoint');
  }

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) async {
    if (guid.isEmpty) return const [];
    final response = await _client._http.get('/LiveTv/Timers/Defaults', queryParameters: {'programId': guid});
    throwIfHttpError(response);
    final defaults = response.data;
    if (defaults is! Map<String, dynamic>) return const [];
    final stash = jsonEncode(defaults);
    final entries = <MediaSubscription>[
      MediaSubscription(
        key: '',
        type: MediaSubscription.typeEpisode,
        title: t.liveTv.recordEpisode,
        selected: true,
        parameters: stash,
        settings: _timerSettings(defaults),
      ),
      // POST /LiveTv/SeriesTimers requires a program the server can resolve a
      // SeriesId for; offering the series variant on a non-series airing
      // would 500.
      if (await _programIsSeries(guid))
        MediaSubscription(
          key: '',
          type: MediaSubscription.typeSeries,
          title: t.liveTv.recordSeries,
          parameters: stash,
          settings: _seriesTimerSettings(defaults),
        ),
    ];
    return [SubscriptionTemplate(subscriptions: entries)];
  }

  /// Best-effort series probe for the template variants. On failure the
  /// template degrades to the episode-only entry instead of blocking the
  /// record flow.
  Future<bool> _programIsSeries(String programId) async {
    try {
      final response = await _client._http.get(
        '/LiveTv/Programs/${_segment(programId)}',
        queryParameters: {'userId': _client.connection.userId},
      );
      throwIfHttpError(response);
      final data = response.data;
      return data is Map<String, dynamic> && data['IsSeries'] == true;
    } catch (e) {
      appLogger.d('${_client.dialect.productName} program series probe failed', error: e);
      return false;
    }
  }

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) async {
    final stash = request.parameters;
    if (stash == null || stash.isEmpty) {
      throw ArgumentError.value(stash, 'request.parameters', 'missing the timer defaults payload');
    }
    final decoded = jsonDecode(stash);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError.value(stash, 'request.parameters', 'not a timer defaults object');
    }
    final body = Map<String, dynamic>.from(decoded);
    _applyPrefs(body, request.prefs);
    final isSeries = request.type == MediaSubscription.typeSeries;
    final path = isSeries ? '/LiveTv/SeriesTimers' : '/LiveTv/Timers';
    try {
      final response = await _client._http.post(path, body: body);
      throwIfHttpError(response);
    } on MediaServerHttpException catch (e) {
      // A duplicate one-off create answers 400 ("A scheduled recording
      // already exists for this program"), indistinguishable from a malformed
      // request by status alone — this call site owns that semantics.
      if (!isSeries && e.statusCode == 400) {
        throw const RecordingConflictException('A recording is already scheduled for this program');
      }
      rethrow;
    }
    // The POST body is empty; the created timer only becomes observable
    // through the next timers re-fetch.
    return null;
  }

  @override
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs) async {
    final id = _stripRuleKeyPrefix(subscriptionId, _jfSeriesRuleKeyPrefix);
    if (id == null) {
      // One-off timers have no edit surface (the UI only cancels them), and
      // the server would ignore everything but paddings anyway.
      throw ArgumentError.value(subscriptionId, 'subscriptionId', 'expected a "series:" rule key');
    }
    final response = await _client._http.get('/LiveTv/SeriesTimers/${_segment(id)}');
    throwIfHttpError(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw MediaServerHttpException(
        type: MediaServerHttpErrorType.unknown,
        message: 'Series timer $id not found',
        statusCode: 404,
      );
    }
    final body = Map<String, dynamic>.from(data);
    _applyPrefs(body, prefs);
    final post = await _client._http.post('/LiveTv/SeriesTimers/${_segment(id)}', body: body);
    throwIfHttpError(post);
    return null;
  }

  @override
  Future<void> deleteRecordingRule(String subscriptionId) async {
    final seriesId = _stripRuleKeyPrefix(subscriptionId, _jfSeriesRuleKeyPrefix);
    if (seriesId != null) {
      // Deleting the series rule hard-deletes every child timer server-side.
      final response = await _client._http.delete('/LiveTv/SeriesTimers/${_segment(seriesId)}');
      throwIfHttpError(response);
      return;
    }
    final timerId = _stripRuleKeyPrefix(subscriptionId, _jfTimerRuleKeyPrefix);
    if (timerId != null) {
      final response = await _client._http.delete('/LiveTv/Timers/${_segment(timerId)}');
      throwIfHttpError(response);
      return;
    }
    throw ArgumentError.value(subscriptionId, 'subscriptionId', 'expected a "timer:" or "series:" rule key');
  }

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() async {
    final timers = await _fetchActiveTimers();
    return [for (final dto in timers) _grabFromTimer(dto)];
  }

  @override
  Future<void> cancelGrab(String operationId) async {
    final id = _stripRuleKeyPrefix(operationId, _jfTimerRuleKeyPrefix) ?? operationId;
    if (id.isEmpty) throw ArgumentError.value(operationId, 'operationId', 'must not be empty');
    final response = await _client._http.delete('/LiveTv/Timers/${_segment(id)}');
    throwIfHttpError(response);
  }

  /// Unused on MediaBrowser: guide programs carry their rule keys inline
  /// (`TimerId`/`SeriesTimerId`), and the UI's mapping fallback requires the
  /// Plex-only `providerIdentifier`, which this backend never stamps.
  @override
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  }) async => const [];

  // includeStorage has no MediaBrowser meaning; rules have no storage totals.
  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) async {
    final response = await _client._http.get(
      '/LiveTv/SeriesTimers',
      queryParameters: {'sortBy': 'SortName', 'sortOrder': 'Ascending'},
    );
    throwIfHttpError(response);
    final rules = _itemsArray(response.data);
    var grabsBySeriesKey = const <String, List<MediaGrabOperation>>{};
    if (includeGrabs && rules.isNotEmpty) {
      final grouped = <String, List<MediaGrabOperation>>{};
      for (final dto in await _fetchActiveTimers()) {
        final seriesTimerId = dto['SeriesTimerId'] as String?;
        if (seriesTimerId == null || seriesTimerId.isEmpty) continue;
        grouped.putIfAbsent('$_jfSeriesRuleKeyPrefix$seriesTimerId', () => []).add(_grabFromTimer(dto));
      }
      grabsBySeriesKey = grouped;
    }
    return [
      for (final dto in rules)
        MediaSubscription(
          key: '$_jfSeriesRuleKeyPrefix${dto['Id']}',
          type: MediaSubscription.typeSeries,
          title: dto['Name'] as String?,
          settings: _seriesTimerSettings(dto),
          grabOperations: grabsBySeriesKey['$_jfSeriesRuleKeyPrefix${dto['Id']}'] ?? const [],
        ),
    ];
  }

  /// `GET /LiveTv/Timers` without status tombstones. Cancelled children of a
  /// series rule persist server-side as deliberate "skip this episode"
  /// markers, and Emby can also return `Completed` rows; neither is a
  /// scheduled recording.
  Future<List<Map<String, dynamic>>> _fetchActiveTimers() async {
    final response = await _client._http.get('/LiveTv/Timers');
    throwIfHttpError(response);
    return [
      for (final dto in _itemsArray(response.data))
        if (dto['Status'] != 'Cancelled' && dto['Status'] != 'Completed') dto,
    ];
  }

  /// One `TimerInfoDto` as a grab operation. The nested metadata map uses the
  /// Plex key shape `LiveTvProgram.fromJson` parses, so the recordings tab
  /// tiles and the guide's scheduled-key matching (`ratingKey`, channel+slot)
  /// work unchanged.
  MediaGrabOperation _grabFromTimer(Map<String, dynamic> dto) {
    final id = dto['Id'] as String? ?? '';
    final seriesTimerId = dto['SeriesTimerId'] as String?;
    final programInfo = dto['ProgramInfo'];
    return MediaGrabOperation(
      id: '$_jfTimerRuleKeyPrefix$id',
      status: switch (dto['Status'] as String?) {
        'InProgress' => 'grabbing',
        'Error' || 'ConflictedNotOk' => 'error',
        _ => 'scheduled',
      },
      metadata: {
        'title': dto['Name'] as String?,
        'summary': dto['Overview'] as String?,
        'ratingKey': dto['ProgramId'] as String?,
        'guid': dto['ProgramId'] as String?,
        'beginsAt': jellyfinIsoToEpochSeconds(dto['StartDate'] as String?),
        'endsAt': jellyfinIsoToEpochSeconds(dto['EndDate'] as String?),
        'channelIdentifier': dto['ChannelId'] as String?,
        'channelCallSign': dto['ChannelName'] as String?,
        'subscriptionID': '$_jfTimerRuleKeyPrefix$id',
        if (seriesTimerId != null && seriesTimerId.isNotEmpty)
          'grandparentSubscriptionID': '$_jfSeriesRuleKeyPrefix$seriesTimerId',
        if (programInfo is Map<String, dynamic>) ...{
          'grandparentTitle': programInfo['SeriesName'] as String?,
          'index': programInfo['IndexNumber'],
          'parentIndex': programInfo['ParentIndexNumber'],
        },
      },
    );
  }

  /// Overlay sheet prefs onto a timer DTO body. Pref ids are DTO field names;
  /// null values (a cleared numeric field) keep the server-supplied default.
  void _applyPrefs(Map<String, dynamic> body, Map<String, Object?> prefs) {
    for (final entry in prefs.entries) {
      final value = entry.value;
      if (value == null) continue;
      body[entry.key] = value;
    }
  }

  /// Settings honored by one-off timer creates (`TimerInfoDto` paddings).
  List<SubscriptionSetting> _timerSettings(Map<String, dynamic> dto) => [
    _intSetting('PrePaddingSeconds', t.liveTv.recordSettings.startEarly, dto),
    _intSetting('PostPaddingSeconds', t.liveTv.recordSettings.endLate, dto),
  ];

  /// Settings honored by series creates and `POST /LiveTv/SeriesTimers/{id}`
  /// updates.
  List<SubscriptionSetting> _seriesTimerSettings(Map<String, dynamic> dto) => [
    ..._timerSettings(dto),
    _boolSetting('RecordNewOnly', t.liveTv.recordSettings.newOnly, dto),
    _boolSetting('RecordAnyChannel', t.liveTv.recordSettings.anyChannel, dto),
    _boolSetting('RecordAnyTime', t.liveTv.recordSettings.anyTime, dto),
    _boolSetting('SkipEpisodesInLibrary', t.liveTv.recordSettings.skipInLibrary, dto),
    _intSetting('KeepUpTo', t.liveTv.recordSettings.keepUpTo, dto, summary: t.liveTv.recordSettings.keepUpToHint),
  ];

  SubscriptionSetting _intSetting(String id, String label, Map<String, dynamic> dto, {String? summary}) =>
      SubscriptionSetting(id: id, label: label, summary: summary, type: 'int', value: flexibleInt(dto[id]) ?? 0);

  SubscriptionSetting _boolSetting(String id, String label, Map<String, dynamic> dto) =>
      SubscriptionSetting(id: id, label: label, type: 'bool', value: dto[id] == true);
}
