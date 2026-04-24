/// External IDs parsed from a Plex `Guid` array (as returned by
/// `?includeGuids=1`). Shared by the Trakt and tracker resolvers.
///
/// Plex GUIDs look like `imdb://tt123`, `tmdb://456`, `tvdb://789`. Callers
/// fetch the raw array via [PlexClient.fetchExternalGuids] and pass it here.
class PlexExternalIds {
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  const PlexExternalIds({this.imdb, this.tmdb, this.tvdb});

  bool get hasAny => imdb != null || tmdb != null || tvdb != null;

  factory PlexExternalIds.fromGuids(List<dynamic> guids) {
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
    return PlexExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }
}
