/// External IDs (IMDb / TMDB / TVDB) extracted from a media server's
/// metadata. Shared by the Trakt and tracker resolvers.
///
/// - **Plex** stores them in a `Guid` array (`imdb://tt123`,
///   `tmdb://456`, `tvdb://789`) — fetched via
///   [PlexClient.fetchExternalGuids]. Use [ExternalIds.fromGuids].
/// - **Jellyfin** stores them inline as a `ProviderIds` map on every
///   `BaseItemDto`. Use [ExternalIds.fromJellyfinProviderIds].
class ExternalIds {
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  const ExternalIds({this.imdb, this.tmdb, this.tvdb});

  bool get hasAny => imdb != null || tmdb != null || tvdb != null;

  /// Parse external IDs from a Plex primary GUID string.
  /// Handles the modern `imdb://tt123` form and the legacy Plex agent form
  /// `com.plexapp.agents.imdb://tt123/0/0`.
  static ExternalIds fromPrimaryGuid(String? guid) {
    if (guid == null || guid.isEmpty) return const ExternalIds();
    return ExternalIds.fromGuids([
      {'id': _normalizeLegacyGuid(guid)}
    ]);
  }

  /// Normalise a legacy `com.plexapp.agents.*` GUID to the standard scheme
  /// that [fromGuids] already handles.  Returns the string unchanged when it
  /// is already in standard form or unrecognised.
  static String _normalizeLegacyGuid(String guid) {
    const prefixes = <String, String>{
      'agents.imdb://': 'imdb://',
      'agents.themoviedb://': 'tmdb://',
      'agents.thetvdb://': 'tvdb://',
    };
    for (final entry in prefixes.entries) {
      final idx = guid.indexOf(entry.key);
      if (idx == -1) continue;
      final id = guid.substring(idx + entry.key.length).split('/').first;
      return '${entry.value}$id';
    }
    return guid;
  }

  factory ExternalIds.fromGuids(List<dynamic> guids) {
    String? imdb;
    int? tmdb;
    int? tvdb;
    for (final g in guids) {
      if (g is! Map) continue;
      final id = g['id'];
      if (id is! String) continue;
      if (id.startsWith('imdb://')) {
        imdb = id.substring(7);
      } else if (id.startsWith('tmdb://')) {
        tmdb = int.tryParse(id.substring(7));
      } else if (id.startsWith('tvdb://')) {
        tvdb = int.tryParse(id.substring(7));
      }
    }
    return ExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }

  /// Build from a Jellyfin `ProviderIds` map. Jellyfin stores external IDs
  /// directly on every `BaseItemDto` so no extra fetch is needed.
  /// Keys are case-insensitive in practice (`Tmdb`, `Imdb`, `Tvdb`).
  factory ExternalIds.fromJellyfinProviderIds(Map<String, Object?> providerIds) {
    String? imdb;
    int? tmdb;
    int? tvdb;
    providerIds.forEach((key, value) {
      if (value is! String || value.isEmpty) return;
      switch (key.toLowerCase()) {
        case 'imdb':
          imdb = value;
          break;
        case 'tmdb':
          tmdb = int.tryParse(value);
          break;
        case 'tvdb':
          tvdb = int.tryParse(value);
          break;
      }
    });
    return ExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }
}
