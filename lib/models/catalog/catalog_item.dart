import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_rating.dart';
import '../../utils/external_ids.dart';
import 'catalog_cast_member.dart';
import 'catalog_metadata.dart';

/// External catalog providers that can back the Explore tab.
enum CatalogSourceId { plex, trakt, mal, anilist, simkl, seerr, mdblist }

/// Normalized airing/production status across providers (Trakt `status`,
/// MAL `status`). Null when unknown or uninteresting (released movies).
enum CatalogAirStatus { airing, ended, canceled, upcoming }

/// External ids identifying a catalog item across providers and media
/// servers. A superset of [ExternalIds] that also carries provider-native
/// ids (Plex rating key, Trakt id/slug, MAL, AniList, and Simkl).
class CatalogItemIds {
  final String? plex;
  final int? trakt;
  final String? slug;
  final int? mal;
  final int? anilist;
  final int? simkl;
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  const CatalogItemIds({
    this.plex,
    this.trakt,
    this.slug,
    this.mal,
    this.anilist,
    this.simkl,
    this.imdb,
    this.tmdb,
    this.tvdb,
  });

  factory CatalogItemIds.fromExternal(ExternalIds ids) =>
      CatalogItemIds(imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb);

  bool get hasAny =>
      imdb != null ||
      tmdb != null ||
      tvdb != null ||
      mal != null ||
      anilist != null ||
      simkl != null ||
      plex != null ||
      trakt != null ||
      slug != null;

  /// Stable identity key preferring globally-unique ids. Callers must
  /// namespace it by [MediaKind] (tmdb movie/show ids can collide).
  String? get canonicalKey {
    if (imdb != null) return 'imdb:$imdb';
    if (tmdb != null) return 'tmdb:$tmdb';
    if (tvdb != null) return 'tvdb:$tvdb';
    if (mal != null) return 'mal:$mal';
    if (anilist != null) return 'anilist:$anilist';
    if (simkl != null) return 'simkl:$simkl';
    if (plex != null) return 'plex:$plex';
    if (trakt != null) return 'trakt:$trakt';
    if (slug != null) return 'slug:$slug';
    return null;
  }

  /// Identity of *this* entry, preferring provider-native entry ids over the
  /// series ids it shares with its own other seasons.
  ///
  /// [canonicalKey] deliberately prefers imdb/tmdb/tvdb so two sources
  /// describing the same title agree; that is exactly wrong for anything
  /// season-specific, because every MAL/AniList season of one series carries
  /// the same series ids. All five Mushoku Tensei entries collapse to
  /// `imdb:tt13293588` under [canonicalKey].
  String? get entryKey {
    if (mal != null) return 'mal:$mal';
    if (anilist != null) return 'anilist:$anilist';
    if (simkl != null) return 'simkl:$simkl';
    if (trakt != null) return 'trakt:$trakt';
    if (plex != null) return 'plex:$plex';
    if (slug != null) return 'slug:$slug';
    return canonicalKey;
  }

  /// Every id-form key. Membership checks match on any of these so that two
  /// sides carrying different id subsets (e.g. Jellyfin tmdb-only vs a Trakt
  /// entry keyed by imdb) still intersect.
  List<String> get allKeys => [
    if (imdb != null) 'imdb:$imdb',
    if (tmdb != null) 'tmdb:$tmdb',
    if (tvdb != null) 'tvdb:$tvdb',
    if (mal != null) 'mal:$mal',
    if (anilist != null) 'anilist:$anilist',
    if (simkl != null) 'simkl:$simkl',
    if (plex != null) 'plex:$plex',
    if (trakt != null) 'trakt:$trakt',
    if (slug != null) 'slug:$slug',
  ];

  ExternalIds toExternalIds() => ExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);

  /// Union of both id sets, preferring this one per key. A row entry and a
  /// detail body routinely carry different subsets of the same identity.
  CatalogItemIds mergedWith(CatalogItemIds other) => CatalogItemIds(
    plex: plex ?? other.plex,
    trakt: trakt ?? other.trakt,
    slug: slug ?? other.slug,
    mal: mal ?? other.mal,
    anilist: anilist ?? other.anilist,
    simkl: simkl ?? other.simkl,
    imdb: imdb ?? other.imdb,
    tmdb: tmdb ?? other.tmdb,
    tvdb: tvdb ?? other.tvdb,
  );

  Map<String, Object?> toJson() => {
    if (plex != null) 'plex': plex,
    if (trakt != null) 'trakt': trakt,
    if (slug != null) 'slug': slug,
    if (mal != null) 'mal': mal,
    if (anilist != null) 'anilist': anilist,
    if (simkl != null) 'simkl': simkl,
    if (imdb != null) 'imdb': imdb,
    if (tmdb != null) 'tmdb': tmdb,
    if (tvdb != null) 'tvdb': tvdb,
  };

  factory CatalogItemIds.fromJson(Map<String, Object?> json) => CatalogItemIds(
    plex: json['plex'] as String?,
    trakt: json['trakt'] as int?,
    slug: json['slug'] as String?,
    mal: json['mal'] as int?,
    anilist: json['anilist'] as int?,
    simkl: json['simkl'] as int?,
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

  /// Other titles the same entry is known by (MAL `alternative_titles`,
  /// AniList `romaji`/`native`/`synonyms`). Media servers index one localized
  /// title each, so these widen the reverse lookup without weakening it —
  /// candidates are still verified by exact external id.
  final List<String> altTitles;

  /// Season of the parent series this entry maps to, when the provider covers
  /// one season of a longer show (Fribb `season`). Null for whole-series
  /// entries and every non-anime source.
  final ExternalSeasonRef? season;
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

  /// Absolute https URLs served by the provider's CDN. These stay the default
  /// asset for every surface; see [posterVariants] for size selection.
  final String? posterUrl;
  final String? backdropUrl;

  /// Width-keyed alternates for [posterUrl] and [backdropUrl], keyed by the
  /// asset's real pixel width.
  ///
  /// Providers serve the same artwork at several sizes (TMDB `w342`/`w500`,
  /// Simkl's suffixed variants). The mapper cannot pick correctly because it
  /// does not know the surface: a 92-pixel search thumbnail and a 340-pixel
  /// high-DPR TV card have opposite needs. Mappers publish what exists,
  /// widgets choose with [posterFor]/[backdropFor] once they have measured.
  final Map<int, String>? posterVariants;
  final Map<int, String>? backdropVariants;

  /// Transparent title treatment (Trakt `images.logo`), for spotlight art.
  final String? logoUrl;

  /// Wide banner art (Plex `banner`), distinct from the 16:9 backdrop.
  final String? bannerUrl;

  /// Dominant cover colour as `#rrggbb` (AniList `coverImage.color`), for
  /// per-card accent tinting.
  final String? accentColor;

  /// Scores beyond [rating], each with its own source label.
  final List<MediaRatingSource>? ratings;

  /// Leaderboard positions. A list because providers return several windows
  /// at once (all-time and seasonal).
  final List<CatalogRank>? ranks;

  /// Community-size counters; null when the provider returns none.
  final CatalogAudience? audience;

  /// Recurring weekly slot. Never render this as a next-episode date.
  final CatalogBroadcast? broadcast;

  /// The next episode's actual air time, when the provider knows it.
  final CatalogNextEpisode? nextEpisode;

  /// What the user's own servers have, and what has been requested.
  final CatalogServerState? serverState;

  /// Exact premiere/release date; [year] stays the coarse fallback.
  final DateTime? releaseDate;

  /// Home-media release (Simkl movie `released_dvd`).
  final DateTime? physicalReleaseDate;

  /// Final air date for an ended show.
  final DateTime? endDate;

  /// When the user added it to the list this item came from (Trakt
  /// `listed_at`, Simkl watchlist `added_to_watchlist`).
  final DateTime? addedAt;

  /// The user's own score, 0-10, on providers that return it with the list.
  final double? userRating;

  /// Native-language or production title when it differs from [title].
  final String? originalTitle;

  final String? tagline;

  /// Anime broadcast season — "Fall 2025".
  ///
  /// Distinct from [season], which records *which season of a parent series*
  /// an entry maps to for library matching. This one is a calendar window.
  final CatalogSeasonInfo? broadcastSeason;

  /// Finer-grained release format than [kind] (OVA, ONA, TV short, ...).
  final CatalogFormat? format;

  /// What the title was adapted from.
  final CatalogSourceMaterial? sourceMaterial;

  /// Production studios. [network] remains the single broadcast network.
  final List<String>? studios;

  /// ISO 3166-1 alpha-2 country codes.
  final List<String>? countries;

  /// ISO 639-1 language codes; the first is the original language.
  final List<String>? languages;

  /// Directors, writers and producers from a detail payload.
  final List<CatalogCredit>? credits;

  /// Ranked descriptive tags, spoilers included and flagged.
  final List<CatalogTag>? tags;

  /// Provider and streaming links.
  final List<CatalogLink>? links;

  /// Episodes announced but not yet broadcast (Simkl
  /// `not_aired_episodes_count`). Distinct from [episodeCount], which counts
  /// what exists, and from any watched count.
  final int? unairedEpisodeCount;

  /// Who recommended this title and why (Trakt `favorited_by` /
  /// `recommended_by` on personalised rows). The provenance is the point of a
  /// social recommendation, so this is a list of people, not a count.
  final List<CatalogRecommender>? recommenders;

  /// Age-appropriateness prose beyond [certification] (Plex Common Sense).
  final String? contentAdvisory;

  /// Production budget and box-office revenue in USD.
  final int? budget;
  final int? revenue;

  /// Provider-flagged adult content (MAL `nsfw`, TMDB `adult`).
  final bool? isAdult;

  /// How many users recommended this item *from another item*. Only set on
  /// entries returned by a related/recommendation call.
  final int? recommendationCount;

  /// Share of users who recommended this item *from another item*, 0-1
  /// (Simkl `users_percent`, sent as a percentage and normalized by the
  /// mapper). Independent of [recommendationCount]: a count and a share
  /// answer different questions and neither can be derived from the other.
  final double? recommendationPercent;

  /// Provider search relevance. Ordering input only — never rendered.
  final double? relevance;

  /// Production/background prose (MAL `background`) — trivia about how the
  /// title came to exist, distinct from the plot [overview].
  final String? background;

  /// Cast carried on the row item itself, for providers whose row query can
  /// select it without an extra request (AniList). Lets a detail screen skip
  /// its lazy cast call; null means "not known yet", not "no cast".
  final List<CatalogCastMember>? cast;

  const CatalogItem({
    required this.source,
    required this.kind,
    required this.title,
    this.altTitles = const [],
    this.season,
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
    this.posterVariants,
    this.backdropVariants,
    this.logoUrl,
    this.bannerUrl,
    this.accentColor,
    this.ratings,
    this.ranks,
    this.audience,
    this.broadcast,
    this.nextEpisode,
    this.serverState,
    this.releaseDate,
    this.physicalReleaseDate,
    this.endDate,
    this.addedAt,
    this.userRating,
    this.originalTitle,
    this.tagline,
    this.broadcastSeason,
    this.format,
    this.sourceMaterial,
    this.studios,
    this.countries,
    this.languages,
    this.credits,
    this.tags,
    this.links,
    this.contentAdvisory,
    this.budget,
    this.revenue,
    this.isAdult,
    this.recommendationCount,
    this.recommendationPercent,
    this.relevance,
    this.background,
    this.cast,
    this.unairedEpisodeCount,
    this.recommenders,
  });

  /// Returns this row item enriched by a [detail] payload for the same title.
  ///
  /// Detail wins for descriptive content: a detail body carries the untruncated
  /// overview, the full rating and ids the row object never had. The row wins
  /// only for values that exist *because of the row it came from* — leaderboard
  /// position, recommendation provenance, when the user listed it, their own
  /// score, and search relevance — none of which a detail endpoint knows.
  /// Ids merge per key so a row's imdb id survives a detail body that only
  /// returns tmdb.
  CatalogItem enrichedWith(CatalogItem detail) => CatalogItem(
    source: source,
    kind: kind,
    title: detail.title.isNotEmpty ? detail.title : title,
    year: detail.year ?? year,
    overview: detail.overview ?? overview,
    runtimeMinutes: detail.runtimeMinutes ?? runtimeMinutes,
    rating: detail.rating ?? rating,
    votes: detail.votes ?? votes,
    genres: detail.genres ?? genres,
    certification: detail.certification ?? certification,
    trailerUrl: detail.trailerUrl ?? trailerUrl,
    airStatus: detail.airStatus ?? airStatus,
    episodeCount: detail.episodeCount ?? episodeCount,
    network: detail.network ?? network,
    ids: ids.mergedWith(detail.ids),
    posterUrl: detail.posterUrl ?? posterUrl,
    backdropUrl: detail.backdropUrl ?? backdropUrl,
    posterVariants: detail.posterVariants ?? posterVariants,
    backdropVariants: detail.backdropVariants ?? backdropVariants,
    logoUrl: detail.logoUrl ?? logoUrl,
    bannerUrl: detail.bannerUrl ?? bannerUrl,
    accentColor: detail.accentColor ?? accentColor,
    ratings: detail.ratings ?? ratings,
    // Union rather than replace: the row and the detail body each carry
    // counters the other omits.
    audience: audience?.mergedWith(detail.audience ?? const CatalogAudience()) ?? detail.audience,
    broadcast: detail.broadcast ?? broadcast,
    nextEpisode: detail.nextEpisode ?? nextEpisode,
    serverState: detail.serverState ?? serverState,
    releaseDate: detail.releaseDate ?? releaseDate,
    physicalReleaseDate: detail.physicalReleaseDate ?? physicalReleaseDate,
    endDate: detail.endDate ?? endDate,
    originalTitle: detail.originalTitle ?? originalTitle,
    altTitles: altTitles.isNotEmpty ? altTitles : detail.altTitles,
    tagline: detail.tagline ?? tagline,
    broadcastSeason: detail.broadcastSeason ?? broadcastSeason,
    format: detail.format ?? format,
    sourceMaterial: detail.sourceMaterial ?? sourceMaterial,
    studios: detail.studios ?? studios,
    countries: detail.countries ?? countries,
    languages: detail.languages ?? languages,
    credits: detail.credits ?? credits,
    tags: detail.tags ?? tags,
    links: detail.links ?? links,
    contentAdvisory: detail.contentAdvisory ?? contentAdvisory,
    budget: detail.budget ?? budget,
    revenue: detail.revenue ?? revenue,
    isAdult: detail.isAdult ?? isAdult,
    unairedEpisodeCount: detail.unairedEpisodeCount ?? unairedEpisodeCount,
    // Row-only context: a detail endpoint cannot know these.
    ranks: ranks ?? detail.ranks,
    addedAt: addedAt ?? detail.addedAt,
    userRating: userRating ?? detail.userRating,
    recommendationCount: recommendationCount ?? detail.recommendationCount,
    recommendationPercent: recommendationPercent ?? detail.recommendationPercent,
    relevance: relevance ?? detail.relevance,
    background: detail.background ?? background,
    cast: detail.cast ?? cast,
    recommenders: recommenders ?? detail.recommenders,
  );

  /// Kind-namespaced identity key for caches and dedupe.
  String get identityKey => '${kind.id}/${ids.canonicalKey}';

  /// The narrowest poster at least [targetPx] wide, falling back to the
  /// widest variant and finally to [posterUrl].
  String? posterFor(int targetPx) => _variantFor(posterUrl, posterVariants, targetPx);

  /// The narrowest backdrop at least [targetPx] wide, falling back to the
  /// widest variant and finally to [backdropUrl].
  String? backdropFor(int targetPx) => _variantFor(backdropUrl, backdropVariants, targetPx);

  /// Cache key for anything whose answer is season-specific — see
  /// [CatalogItemIds.entryKey], which [identityKey] deliberately does not use.
  String get entryIdentityKey => '${kind.id}/${ids.entryKey}';

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
    ratings: ratings,
    genres: genres,
    thumbPath: posterUrl,
    artPath: backdropUrl,
    raw: {rawKey: toJson()},
  );

  Map<String, Object?> toJson() => {
    'source': source.name,
    'kind': kind.id,
    'title': title,
    if (altTitles.isNotEmpty) 'altTitles': altTitles,
    if (season != null) 'season': season!.toJson(),
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
    if (posterVariants != null) 'posterVariants': {for (final e in posterVariants!.entries) '${e.key}': e.value},
    if (backdropVariants != null) 'backdropVariants': {for (final e in backdropVariants!.entries) '${e.key}': e.value},
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (bannerUrl != null) 'bannerUrl': bannerUrl,
    if (accentColor != null) 'accentColor': accentColor,
    if (ratings != null) 'ratings': [for (final r in ratings!) r.toJson()],
    if (ranks != null) 'ranks': [for (final r in ranks!) r.toJson()],
    if (audience != null) 'audience': audience!.toJson(),
    if (broadcast != null) 'broadcast': broadcast!.toJson(),
    if (nextEpisode != null) 'nextEpisode': nextEpisode!.toJson(),
    if (serverState != null) 'serverState': serverState!.toJson(),
    if (releaseDate != null) 'releaseDate': releaseDate!.toIso8601String(),
    if (physicalReleaseDate != null) 'physicalReleaseDate': physicalReleaseDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
    if (userRating != null) 'userRating': userRating,
    if (originalTitle != null) 'originalTitle': originalTitle,
    if (tagline != null) 'tagline': tagline,
    if (broadcastSeason != null) 'broadcastSeason': broadcastSeason!.toJson(),
    if (format != null) 'format': format!.name,
    if (sourceMaterial != null) 'sourceMaterial': sourceMaterial!.name,
    if (studios != null) 'studios': studios,
    if (countries != null) 'countries': countries,
    if (languages != null) 'languages': languages,
    if (credits != null) 'credits': [for (final c in credits!) c.toJson()],
    if (tags != null) 'tags': [for (final t in tags!) t.toJson()],
    if (links != null) 'links': [for (final l in links!) l.toJson()],
    if (unairedEpisodeCount != null) 'unairedEpisodeCount': unairedEpisodeCount,
    if (recommenders != null) 'recommenders': [for (final r in recommenders!) r.toJson()],
    if (contentAdvisory != null) 'contentAdvisory': contentAdvisory,
    if (budget != null) 'budget': budget,
    if (revenue != null) 'revenue': revenue,
    if (isAdult != null) 'isAdult': isAdult,
    if (recommendationCount != null) 'recommendationCount': recommendationCount,
    if (recommendationPercent != null) 'recommendationPercent': recommendationPercent,
    if (relevance != null) 'relevance': relevance,
    if (background != null) 'background': background,
    if (cast != null) 'cast': [for (final c in cast!) c.toJson()],
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
    altTitles: (json['altTitles'] as List?)?.cast<String>() ?? const [],
    season: switch (json['season']) {
      final Map<String, Object?> s => ExternalSeasonRef.fromJson(s),
      final Map s => ExternalSeasonRef.fromJson(s.cast<String, Object?>()),
      _ => null,
    },
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
    posterVariants: _decodeVariants(json['posterVariants']),
    backdropVariants: _decodeVariants(json['backdropVariants']),
    logoUrl: json['logoUrl'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    accentColor: json['accentColor'] as String?,
    ratings: decodeCatalogList(json['ratings'], MediaRatingSource.fromJson),
    ranks: decodeCatalogList(json['ranks'], CatalogRank.fromJson),
    audience: _decodeObject(json['audience'], CatalogAudience.fromJson),
    broadcast: _decodeObject(json['broadcast'], CatalogBroadcast.fromJson),
    nextEpisode: _decodeObject(json['nextEpisode'], CatalogNextEpisode.fromJson),
    serverState: _decodeObject(json['serverState'], CatalogServerState.fromJson),
    releaseDate: _decodeDate(json['releaseDate']),
    physicalReleaseDate: _decodeDate(json['physicalReleaseDate']),
    endDate: _decodeDate(json['endDate']),
    addedAt: _decodeDate(json['addedAt']),
    userRating: (json['userRating'] as num?)?.toDouble(),
    originalTitle: json['originalTitle'] as String?,
    tagline: json['tagline'] as String?,
    broadcastSeason: _decodeObject(json['broadcastSeason'], CatalogSeasonInfo.fromJson),
    format: CatalogFormat.values.asNameMap()[json['format']],
    sourceMaterial: CatalogSourceMaterial.values.asNameMap()[json['sourceMaterial']],
    studios: (json['studios'] as List?)?.cast<String>(),
    countries: (json['countries'] as List?)?.cast<String>(),
    languages: (json['languages'] as List?)?.cast<String>(),
    credits: decodeCatalogList(json['credits'], CatalogCredit.fromJson),
    tags: decodeCatalogList(json['tags'], CatalogTag.fromJson),
    links: decodeCatalogList(json['links'], CatalogLink.fromJson),
    contentAdvisory: json['contentAdvisory'] as String?,
    budget: json['budget'] as int?,
    revenue: json['revenue'] as int?,
    isAdult: json['isAdult'] as bool?,
    recommendationCount: json['recommendationCount'] as int?,
    recommendationPercent: (json['recommendationPercent'] as num?)?.toDouble(),
    unairedEpisodeCount: json['unairedEpisodeCount'] as int?,
    recommenders: decodeCatalogList(json['recommenders'], CatalogRecommender.fromJson),
    relevance: (json['relevance'] as num?)?.toDouble(),
    background: json['background'] as String?,
    cast: decodeCatalogList(json['cast'], CatalogCastMember.fromJson),
  );
}

T? _decodeObject<T>(Object? raw, T? Function(Map<String, Object?>) decode) =>
    raw is Map ? decode(raw.cast<String, Object?>()) : null;

DateTime? _decodeDate(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

Map<int, String>? _decodeVariants(Object? raw) {
  if (raw is! Map) return null;
  final out = <int, String>{};
  for (final entry in raw.entries) {
    final width = int.tryParse('${entry.key}');
    final url = entry.value;
    if (width != null && url is String) out[width] = url;
  }
  return out.isEmpty ? null : out;
}

/// Picks the narrowest variant that still covers [targetPx].
///
/// When no variant is wide enough the default asset wins, because it is the
/// provider's canonical (usually largest) rendition and upscaling a too-small
/// image looks worse than spending a few extra kilobytes. Mappers that know
/// the default's own pixel width should register it in the map as well, so it
/// competes on equal terms instead of only being a last resort.
String? _variantFor(String? fallback, Map<int, String>? variants, int targetPx) {
  if (variants == null || variants.isEmpty) return fallback;
  int? best;
  for (final width in variants.keys) {
    if (width >= targetPx && (best == null || width < best)) best = width;
  }
  if (best == null) return fallback ?? variants[variants.keys.reduce((a, b) => a > b ? a : b)];
  return variants[best];
}
