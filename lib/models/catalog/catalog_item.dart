import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../utils/external_ids.dart';

/// External catalog providers that can back the Explore tab.
enum CatalogSourceId { trakt, mal, seerr }

/// Normalized airing/production status across providers (Trakt `status`,
/// MAL `status`). Null when unknown or uninteresting (released movies).
enum CatalogAirStatus { airing, ended, canceled, upcoming }

/// External ids identifying a catalog item across providers and media
/// servers. A superset of [ExternalIds] that also carries provider-native
/// ids (Trakt id/slug, MAL id today).
class CatalogItemIds {
  final int? trakt;
  final String? slug;
  final int? mal;
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  const CatalogItemIds({this.trakt, this.slug, this.mal, this.imdb, this.tmdb, this.tvdb});

  factory CatalogItemIds.fromExternal(ExternalIds ids) =>
      CatalogItemIds(imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb);

  bool get hasAny => imdb != null || tmdb != null || tvdb != null || trakt != null || slug != null || mal != null;

  /// Stable identity key preferring globally-unique ids. Callers must
  /// namespace it by [MediaKind] (tmdb movie/show ids can collide).
  String? get canonicalKey {
    if (imdb != null) return 'imdb:$imdb';
    if (tmdb != null) return 'tmdb:$tmdb';
    if (tvdb != null) return 'tvdb:$tvdb';
    if (mal != null) return 'mal:$mal';
    if (trakt != null) return 'trakt:$trakt';
    if (slug != null) return 'slug:$slug';
    return null;
  }

  /// Every id-form key. Membership checks match on any of these so that two
  /// sides carrying different id subsets (e.g. Jellyfin tmdb-only vs a Trakt
  /// entry keyed by imdb) still intersect.
  List<String> get allKeys => [
    if (imdb != null) 'imdb:$imdb',
    if (tmdb != null) 'tmdb:$tmdb',
    if (tvdb != null) 'tvdb:$tvdb',
    if (mal != null) 'mal:$mal',
    if (trakt != null) 'trakt:$trakt',
    if (slug != null) 'slug:$slug',
  ];

  ExternalIds toExternalIds() => ExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);

  Map<String, Object?> toJson() => {
    if (trakt != null) 'trakt': trakt,
    if (slug != null) 'slug': slug,
    if (mal != null) 'mal': mal,
    if (imdb != null) 'imdb': imdb,
    if (tmdb != null) 'tmdb': tmdb,
    if (tvdb != null) 'tvdb': tvdb,
  };

  factory CatalogItemIds.fromJson(Map<String, Object?> json) => CatalogItemIds(
    trakt: json['trakt'] as int?,
    slug: json['slug'] as String?,
    mal: json['mal'] as int?,
    imdb: json['imdb'] as String?,
    tmdb: json['tmdb'] as int?,
    tvdb: json['tvdb'] as int?,
  );
}

/// A movie or show from an external catalog provider (Trakt trending, the
/// user's watchlist, ...). Not a library item: it has no server id and is
/// matched back to the user's libraries on demand.
class CatalogItem {
  /// Key under [MediaItem.raw] where a synthesized rendering item stashes its
  /// backing [CatalogItem] (see [toMediaItem]).
  static const String rawKey = 'plezyCatalog';

  final CatalogSourceId source;

  /// [MediaKind.movie] or [MediaKind.show].
  final MediaKind kind;
  final String title;
  final int? year;
  final String? overview;
  final int? runtimeMinutes;

  /// Provider community rating, 0–10.
  final double? rating;

  /// How many users the rating is based on (Trakt votes, MAL scoring users).
  final int? votes;
  final List<String>? genres;
  final String? certification;
  final String? trailerUrl;
  final CatalogAirStatus? airStatus;

  /// Aired episodes (Trakt) or total episodes (MAL); shows only.
  final int? episodeCount;

  /// TV network (Trakt) or animation studio (MAL).
  final String? network;
  final CatalogItemIds ids;

  /// Absolute https URLs served by the provider's CDN.
  final String? posterUrl;
  final String? backdropUrl;

  const CatalogItem({
    required this.source,
    required this.kind,
    required this.title,
    this.year,
    this.overview,
    this.runtimeMinutes,
    this.rating,
    this.votes,
    this.genres,
    this.certification,
    this.trailerUrl,
    this.airStatus,
    this.episodeCount,
    this.network,
    required this.ids,
    this.posterUrl,
    this.backdropUrl,
  });

  /// Kind-namespaced identity key for caches and dedupe.
  String get identityKey => '${kind.id}/${ids.canonicalKey}';

  /// Synthesize a [MediaItem] so catalog items flow through the existing
  /// shelf/grid/card stack ([MediaHub.items] is `List<MediaItem>`).
  ///
  /// The result is rendering-only and must never be persisted or handed to
  /// server-backed paths: `serverId` stays null and taps are intercepted by
  /// the catalog branch in `navigateToMediaItem`. `backend` is an arbitrary
  /// tag required by the union type. Poster/backdrop are absolute URLs, which
  /// the image pipeline loads directly.
  MediaItem toMediaItem() => MediaItem(
    id: 'catalog:${source.name}:$identityKey',
    backend: MediaBackend.plex,
    kind: kind,
    title: title,
    summary: overview,
    year: year,
    contentRating: certification,
    durationMs: runtimeMinutes == null ? null : Duration(minutes: runtimeMinutes!).inMilliseconds,
    rating: rating,
    genres: genres,
    thumbPath: posterUrl,
    artPath: backdropUrl,
    raw: {rawKey: toJson()},
  );

  Map<String, Object?> toJson() => {
    'source': source.name,
    'kind': kind.id,
    'title': title,
    if (year != null) 'year': year,
    if (overview != null) 'overview': overview,
    if (runtimeMinutes != null) 'runtimeMinutes': runtimeMinutes,
    if (rating != null) 'rating': rating,
    if (votes != null) 'votes': votes,
    if (genres != null) 'genres': genres,
    if (certification != null) 'certification': certification,
    if (trailerUrl != null) 'trailerUrl': trailerUrl,
    if (airStatus != null) 'airStatus': airStatus!.name,
    if (episodeCount != null) 'episodeCount': episodeCount,
    if (network != null) 'network': network,
    'ids': ids.toJson(),
    if (posterUrl != null) 'posterUrl': posterUrl,
    if (backdropUrl != null) 'backdropUrl': backdropUrl,
  };

  factory CatalogItem.fromJson(Map<String, Object?> json) => CatalogItem(
    // Round-trips are same-session toJson output — an unknown source is a
    // bug, and defaulting it would bind watchlist/cast/related calls to the
    // wrong provider. Fail loudly instead.
    source:
        CatalogSourceId.values.asNameMap()[json['source']] ??
        (throw ArgumentError('Unknown catalog source: ${json['source']}')),
    kind: MediaKind.fromString(json['kind'] as String?),
    title: json['title'] as String? ?? '',
    year: json['year'] as int?,
    overview: json['overview'] as String?,
    runtimeMinutes: json['runtimeMinutes'] as int?,
    rating: (json['rating'] as num?)?.toDouble(),
    votes: json['votes'] as int?,
    genres: (json['genres'] as List?)?.cast<String>(),
    certification: json['certification'] as String?,
    trailerUrl: json['trailerUrl'] as String?,
    airStatus: CatalogAirStatus.values.asNameMap()[json['airStatus']],
    episodeCount: json['episodeCount'] as int?,
    network: json['network'] as String?,
    ids: CatalogItemIds.fromJson((json['ids'] as Map?)?.cast<String, Object?>() ?? const {}),
    posterUrl: json['posterUrl'] as String?,
    backdropUrl: json['backdropUrl'] as String?,
  );
}
