import '../../models/plex_metadata.dart';
import '../../models/trakt/trakt_ids.dart';
import '../plex_client.dart';

/// Resolves Plex rating keys to external IDs (imdb/tmdb/tvdb) for Trakt
/// matching. Caches per ratingKey for the duration of a play session.
///
/// Trakt prefers a show-IDs-plus-season/episode shape for episode scrobbles
/// rather than episode-IDs alone, so episode resolution requires a separate
/// fetch on `grandparentRatingKey` to get the show's GUIDs.
class TraktGuidResolver {
  final PlexClient _client;

  /// Cache of `ratingKey → TraktIds`. Holds both movies and shows.
  final Map<String, TraktIds> _cache = {};

  TraktGuidResolver(this._client);

  /// Resolve external IDs for a movie rating key.
  Future<TraktIds> resolveForMovie(String ratingKey) async {
    final cached = _cache[ratingKey];
    if (cached != null) return cached;

    final guids = await _client.fetchExternalGuids(ratingKey);
    final ids = TraktIds.fromPlexGuids(guids);
    _cache[ratingKey] = ids;
    return ids;
  }

  /// Resolve external IDs for an episode. Returns the show's GUIDs (Trakt's
  /// preferred shape); season/episode index live on the [PlexMetadata] itself.
  ///
  /// Returns null if the episode is missing `grandparentRatingKey` (in which
  /// case Trakt has no way to match the show).
  Future<TraktIds?> resolveShowForEpisode(PlexMetadata episode) async {
    final showRatingKey = episode.grandparentRatingKey;
    if (showRatingKey == null || showRatingKey.isEmpty) return null;

    final cached = _cache[showRatingKey];
    if (cached != null) return cached;

    final guids = await _client.fetchExternalGuids(showRatingKey);
    final ids = TraktIds.fromPlexGuids(guids);
    _cache[showRatingKey] = ids;
    return ids;
  }

  /// Drop all cached IDs. Called on stopPlayback / profile switch so a
  /// re-matched item gets fresh GUIDs the next time around.
  void clearCache() => _cache.clear();
}
