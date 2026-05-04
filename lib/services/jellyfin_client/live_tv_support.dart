part of '../jellyfin_client.dart';

/// Jellyfin implementation of [LiveTvSupport]. Wraps the existing
/// `fetchLiveTvChannels` / `fetchLiveTvPrograms` / `buildDirectStreamUrl`.
class _JellyfinLiveTvSupport implements LiveTvSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvSupport(this._client);

  Future<T> _unsupported<T>() async => throw UnimplementedError('Jellyfin DVR recording API is not implemented');

  Never _unsupportedSync() => throw UnimplementedError('Jellyfin DVR recording API is not implemented');

  @override
  Future<bool> isAvailable() => _client.hasLiveTv();

  @override
  Future<List<LiveTvDvr>> fetchDvrs() async => const [];

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.fetchLiveTvChannels();

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.fetchLiveTvPrograms(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async {
    final info = await _client.getPlaybackInfo(channelKey);
    final sources = info?['MediaSources'];
    final source = sources is List && sources.isNotEmpty && sources.first is Map<String, dynamic>
        ? sources.first as Map<String, dynamic>
        : null;
    if (source == null) return null;

    final rawUrl = source['TranscodingUrl'] ?? source['DirectStreamUrl'];
    final url = rawUrl is String && rawUrl.isNotEmpty
        ? _client._withApiKey(rawUrl)
        : _client.buildDirectStreamUrl(channelKey);
    var playSessionId = info?['PlaySessionId'] as String?;
    playSessionId ??= Uri.tryParse(url)?.queryParameters['PlaySessionId'];
    return LiveTvStreamResolution(url: url, playSessionId: playSessionId);
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

  @override
  Future<LiveTvServerStatus> fetchLiveTvServerStatus() => _unsupported();

  @override
  Future<LiveTvDvr?> fetchDvr(String dvrId) => _unsupported();

  @override
  Future<LiveTvActivityResult<LiveTvDvr?>> createDvr({
    required List<String> devices,
    required List<String> lineups,
    String? language,
    String? country,
    String? postalCode,
  }) => _unsupported();

  @override
  Future<void> deleteDvr(String dvrId) => _unsupported();

  @override
  Future<void> updateDvrPrefs(String dvrId, Map<String, Object?> prefs) => _unsupported();

  @override
  Future<void> attachDeviceToDvr(String dvrId, String deviceId) => _unsupported();

  @override
  Future<void> detachDeviceFromDvr(String dvrId, String deviceId) => _unsupported();

  @override
  Future<void> addLineupToDvr(String dvrId, String lineupUri) => _unsupported();

  @override
  Future<void> removeLineupFromDvr(String dvrId, String lineupUri) => _unsupported();

  @override
  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId) => _unsupported();

  @override
  Future<void> cancelGuideReload(String dvrId) => _unsupported();

  @override
  Future<List<MediaGrabber>> fetchGrabbers({String? protocol}) => _unsupported();

  @override
  Future<List<MediaGrabberDevice>> fetchGrabberDevices() => _unsupported();

  @override
  Future<LiveTvActivityResult<List<MediaGrabberDevice>>> discoverGrabberDevices() => _unsupported();

  @override
  Future<MediaGrabberDevice?> fetchGrabberDevice(String deviceId) => _unsupported();

  @override
  Future<MediaGrabberDevice?> addGrabberDevice(String uri, {String? grabberId}) => _unsupported();

  @override
  Future<void> updateGrabberDevice(String deviceId, {bool? enabled, String? title}) => _unsupported();

  @override
  Future<void> deleteGrabberDevice(String deviceId) => _unsupported();

  @override
  Future<List<MediaGrabberDeviceChannel>> fetchGrabberDeviceChannels(String deviceId) => _unsupported();

  @override
  Future<LiveTvActivityResult<MediaGrabberDevice?>> scanGrabberDevice(
    String deviceId, {
    String? source,
    Map<String, Object?> prefs = const {},
    String? network,
    String? country,
  }) => _unsupported();

  @override
  Future<MediaGrabberDevice?> cancelGrabberDeviceScan(String deviceId) => _unsupported();

  @override
  Future<MediaGrabberDevice?> saveGrabberDeviceChannelMap(String deviceId, MediaGrabberChannelMapRequest request) =>
      _unsupported();

  @override
  Future<void> updateGrabberDevicePrefs(String deviceId, Map<String, Object?> prefs) => _unsupported();

  @override
  String buildGrabberDeviceThumbUrl(String deviceId, int version) => _unsupportedSync();

  @override
  Future<List<LiveTvCountry>> fetchEpgCountries() => _unsupported();

  @override
  Future<List<LiveTvLanguage>> fetchEpgLanguages() => _unsupported();

  @override
  Future<List<LiveTvRegion>> fetchEpgRegions(String country, String epgId) => _unsupported();

  @override
  Future<LiveTvLineupResult> fetchEpgLineups(String country, String epgId, {String? postalCode, String? region}) =>
      _unsupported();

  @override
  Future<List<LiveTvChannel>> fetchEpgChannelsForLineup(String lineupUri) => _unsupported();

  @override
  Future<List<LiveTvLineup>> fetchEpgChannelsForLineups(List<String> lineupUris) => _unsupported();

  @override
  Future<List<ChannelMapping>> computeEpgChannelMap({required String deviceUri, required String lineupUri}) =>
      _unsupported();

  @override
  Future<LiveTvActivityResult<Map<String, dynamic>?>> findBestLineup({
    required String deviceUri,
    required String lineupGroupUri,
  }) => _unsupported();

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) => _unsupported();

  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) =>
      _unsupported();

  @override
  Future<MediaSubscription?> fetchRecordingRule(
    String subscriptionId, {
    bool includeGrabs = true,
    bool includeStorage = true,
  }) => _unsupported();

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) => _unsupported();

  @override
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs) => _unsupported();

  @override
  Future<void> deleteRecordingRule(String subscriptionId) => _unsupported();

  @override
  Future<MediaSubscription?> moveRecordingRule(String subscriptionId, {String? afterSubscriptionId}) => _unsupported();

  @override
  Future<void> processRecordingRules() => _unsupported();

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() => _unsupported();

  @override
  Future<void> cancelGrab(String operationId) => _unsupported();

  @override
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  }) => _unsupported();

  @override
  Future<List<MediaProviderInfo>> fetchMediaProviders() => _unsupported();

  @override
  Future<void> registerMediaProvider(String url) => _unsupported();

  @override
  Future<void> refreshMediaProviders() => _unsupported();

  @override
  Future<void> unregisterMediaProvider(String providerId) => _unsupported();

  @override
  Future<List<LiveTvSession>> fetchLiveTvSessionsDetailed() => _unsupported();

  @override
  Future<LiveTvSession?> fetchLiveTvSession(String sessionId) => _unsupported();

  @override
  Uri buildNotificationWebSocketUri({List<String>? filters}) => _unsupportedSync();

  @override
  Uri buildNotificationEventSourceUri({List<String>? filters}) => _unsupportedSync();
}
