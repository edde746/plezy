part of '../jellyfin_client.dart';

/// Jellyfin implementation of [LiveTvSupport]. Wraps the existing
/// `fetchLiveTvChannels` / `fetchLiveTvPrograms` / `buildDirectStreamUrl`.
class _JellyfinLiveTvSupport implements LiveTvSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvSupport(this._client);

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
}
