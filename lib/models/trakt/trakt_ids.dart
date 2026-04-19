/// External IDs for matching Plex items against Trakt's catalog.
///
/// Trakt prefers (in order): trakt > slug > imdb > tmdb > tvdb. Movies use
/// imdb/tmdb; episodes use the show's tvdb/tmdb/imdb plus season/episode index.
class TraktIds {
  final int? trakt;
  final String? slug;
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  const TraktIds({this.trakt, this.slug, this.imdb, this.tmdb, this.tvdb});

  /// True when at least one external ID is set (i.e. usable for Trakt matching).
  bool get hasAny => imdb != null || tmdb != null || tvdb != null || trakt != null || slug != null;

  Map<String, dynamic> toJson() => {
    if (trakt != null) 'trakt': trakt,
    if (slug != null) 'slug': slug,
    if (imdb != null) 'imdb': imdb,
    if (tmdb != null) 'tmdb': tmdb,
    if (tvdb != null) 'tvdb': tvdb,
  };

  factory TraktIds.fromJson(Map<String, dynamic> json) => TraktIds(
    trakt: (json['trakt'] as num?)?.toInt(),
    slug: json['slug'] as String?,
    imdb: json['imdb'] as String?,
    tmdb: (json['tmdb'] as num?)?.toInt(),
    tvdb: (json['tvdb'] as num?)?.toInt(),
  );

  /// Parse a Plex GUID array (`[{id: 'imdb://tt123'}, {id: 'tmdb://456'}, ...]`)
  /// into a [TraktIds] struct. The Plex `Guid` field is unparsed in
  /// `PlexMetadata`; this parser reads the array returned by `?includeGuids=1`.
  factory TraktIds.fromPlexGuids(List<dynamic> guids) {
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
    return TraktIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }
}
