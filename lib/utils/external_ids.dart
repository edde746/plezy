/// Season of a parent series as numbered by each external provider.
///
/// Populated from the Fribb mapping's `season: {tvdb: N, tmdb: M}`.
class ExternalSeasonRef {
  final int? tvdb;
  final int? tmdb;

  const ExternalSeasonRef({this.tvdb, this.tmdb});

  bool get hasAny => tvdb != null || tmdb != null;

  /// True when this entry covers a later season under either provider.
  ///
  /// Independent of [agreedSeason]: it answers "is this a sequel at all",
  /// which stays knowable when the two providers disagree. Callers use it to
  /// drop the ±1 year window, because a sequel's catalog year is its own
  /// season's, not the parent show's.
  bool get isSequel => (tvdb ?? 0) > 1 || (tmdb ?? 0) > 1;

  /// The season number both providers mapped and agree on, else null.
  ///
  /// TVDB and TMDB disagree on split-cour / continuation seasons — a season
  /// the former numbers `2` the latter often folds into `1` at an episode
  /// offset. Which one a library follows is a server-side setting, not
  /// anything a dataset can tell us, and it is NOT inferable from which ids an
  /// item exposes (a Plex show carries all three regardless). So when the two
  /// disagree the honest answer is "cannot tell" and the caller must not gate.
  ///
  /// A missing number is not agreement either: `tvdb: 2, tmdb: null` means
  /// Fribb has no TMDB season mapping, and a TMDB-ordered server would number
  /// that season by the mapping we do not have. Holds for 1133 of the 1185
  /// gate-eligible Fribb rows; the other 52 simply go ungated.
  int? get agreedSeason => tvdb != null && tvdb == tmdb ? tvdb : null;

  Map<String, Object?> toJson() => {if (tvdb != null) 'tvdb': tvdb, if (tmdb != null) 'tmdb': tmdb};

  factory ExternalSeasonRef.fromJson(Map<String, Object?> json) =>
      ExternalSeasonRef(tvdb: json['tvdb'] as int?, tmdb: json['tmdb'] as int?);

  @override
  bool operator ==(Object other) => other is ExternalSeasonRef && other.tvdb == tvdb && other.tmdb == tmdb;

  @override
  int get hashCode => Object.hash(tvdb, tmdb);
}

/// External IDs (IMDb / TMDB / TVDB / AniDB) extracted from a media server's
/// metadata. Shared by the Trakt and tracker resolvers.
///
/// - **Plex** stores modern IDs in a `Guid` array (`imdb://tt123`,
///   `tmdb://456`, `tvdb://789`) and legacy agents expose one scalar `guid`
///   instead — the `Guid` array only exists for the Plex Movie / Plex TV
///   Series agents. Use [ExternalIds.fromGuids] and [fillFrom] with
///   [ExternalIds.fromLegacyPlexGuid] so both shapes are read.
/// - **Jellyfin** stores them inline as a `ProviderIds` map on every
///   `BaseItemDto`. Use [ExternalIds.fromJellyfinProviderIds].
class ExternalIds {
  final String? imdb;
  final int? tmdb;
  final int? tvdb;

  /// AniDB series id, only ever produced by Plex's HAMA agent. Separate from
  /// the three catalog ids because almost nothing accepts it: it names a Fribb
  /// row (and through it MAL/AniList/Simkl) but Trakt, Plex Discover, Seerr and
  /// the Anime-Lists episode mappings are all keyed the other way.
  final int? anidb;

  const ExternalIds({this.imdb, this.tmdb, this.tvdb, this.anidb});

  bool get hasAny => hasCatalogIds || anidb != null;

  /// The ids a title database can be queried with. Callers that can only search
  /// IMDb/TMDB/TVDB gate on this rather than [hasAny], so an AniDB-only item
  /// does not send them looking for something they cannot express.
  bool get hasCatalogIds => imdb != null || tmdb != null || tvdb != null;

  /// True when any id form matches [other]. Used to verify reverse-lookup
  /// candidates (never yields false positives; the two sides may carry
  /// different id subsets).
  bool intersects(ExternalIds other) =>
      (imdb != null && imdb == other.imdb) ||
      (tmdb != null && tmdb == other.tmdb) ||
      (tvdb != null && tvdb == other.tvdb) ||
      (anidb != null && anidb == other.anidb);

  /// This set with every absent id taken from [other].
  ///
  /// Used to read a Plex item that carries both shapes: the modern `Guid` array
  /// wins per field and the legacy scalar `guid` only fills what it left null.
  ExternalIds fillFrom(ExternalIds other) => ExternalIds(
    imdb: imdb ?? other.imdb,
    tmdb: tmdb ?? other.tmdb,
    tvdb: tvdb ?? other.tvdb,
    anidb: anidb ?? other.anidb,
  );

  /// Round-trips through the persisted tracker write queue. Absent ids stay
  /// absent so a re-read yields the same [hasAny]/[intersects] answers.
  Map<String, Object?> toJson() => {
    if (imdb != null) 'imdb': imdb,
    if (tmdb != null) 'tmdb': tmdb,
    if (tvdb != null) 'tvdb': tvdb,
    if (anidb != null) 'anidb': anidb,
  };

  factory ExternalIds.fromJson(Map<String, Object?> json) => ExternalIds(
    imdb: json['imdb'] as String?,
    tmdb: (json['tmdb'] as num?)?.toInt(),
    tvdb: (json['tvdb'] as num?)?.toInt(),
    anidb: (json['anidb'] as num?)?.toInt(),
  );

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

  /// Build from a legacy Plex item's scalar `guid`.
  ///
  /// HAMA composes its guid as `<source>-<id>` over
  /// `anidb|anidb2..9|tvdb|tvdb2..9|tmdb|tsdb|imdb`. Only plain `anidb-` is
  /// mapped: `anidb2`..`anidb9` are HAMA's grouping modes, where several AniDB
  /// entries share one Plex show under TVDB-shaped seasons, so the guid names
  /// the root entry only and would mislabel every later season.
  factory ExternalIds.fromLegacyPlexGuid(Object? guid) {
    if (guid is! String || guid.isEmpty) return const ExternalIds();

    final uri = Uri.tryParse(guid);
    if (uri == null || !uri.hasAuthority || uri.path.isNotEmpty) return const ExternalIds();

    final value = uri.host;
    switch (uri.scheme.toLowerCase()) {
      case 'com.plexapp.agents.imdb':
        return ExternalIds(imdb: _normalizeImdb(value, allowBareDigits: false));
      case 'com.plexapp.agents.themoviedb':
        return ExternalIds(tmdb: _parseNumericId(value));
      case 'com.plexapp.agents.thetvdb':
        return ExternalIds(tvdb: _parseNumericId(value));
      case 'com.plexapp.agents.hama':
        final separator = value.indexOf('-');
        if (separator <= 0 || separator == value.length - 1) return const ExternalIds();
        final source = value.substring(0, separator).toLowerCase();
        final id = value.substring(separator + 1);
        if (source == 'imdb') {
          return ExternalIds(imdb: _normalizeImdb(id, allowBareDigits: true));
        }
        if (source == 'anidb') {
          return ExternalIds(anidb: _parseNumericId(id));
        }
        if (source == 'tmdb' || source == 'tsdb') {
          return ExternalIds(tmdb: _parseNumericId(id));
        }
        if (_hamaTvdbSource.hasMatch(source)) {
          return ExternalIds(tvdb: _parseNumericId(id));
        }
    }
    return const ExternalIds();
  }

  static final RegExp _decimalId = RegExp(r'^[0-9]+$');
  static final RegExp _hamaTvdbSource = RegExp(r'^tvdb(?:[2-9])?$');

  static int? _parseNumericId(String value) => _decimalId.hasMatch(value) ? int.tryParse(value) : null;

  static String? _normalizeImdb(String value, {required bool allowBareDigits}) {
    final normalized = value.toLowerCase();
    if (normalized.startsWith('tt')) {
      final digits = normalized.substring(2);
      return _decimalId.hasMatch(digits) ? 'tt$digits' : null;
    }
    return allowBareDigits && _decimalId.hasMatch(normalized) ? 'tt$normalized' : null;
  }

  /// Every raw Jellyfin item whose inline `ProviderIds` intersect [ids], in
  /// response order. Pure helper so the reverse-lookup verification stays
  /// unit-testable (its call site lives in a part file).
  ///
  /// Plural because one title can own several library items — a 4K library
  /// and an HD library hold separate items for the same movie (#1754) — and
  /// the caller shows the user every copy.
  static List<Map<String, dynamic>> jellyfinCandidatesMatching(List<Map<String, dynamic>> candidates, ExternalIds ids) {
    return [
      for (final item in candidates)
        if (item['ProviderIds'] case final Map<dynamic, dynamic> providerIds)
          if (ids.intersects(ExternalIds.fromJellyfinProviderIds(providerIds.cast<String, Object?>()))) item,
    ];
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
