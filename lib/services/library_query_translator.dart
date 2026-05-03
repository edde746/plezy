import '../media/library_query.dart';
import '../media/media_kind.dart';
import 'plex_constants.dart';

/// Limit browse payload image tags to the artwork types the UI maps.
const jellyfinImageQueryParameters = <String, String>{
  'EnableImageTypes': 'Primary,Backdrop,Thumb,Logo',
  'ImageTypeLimit': '1',
};

/// Translates a backend-neutral [LibraryQuery] into the per-backend
/// query-parameter map that the corresponding `/library/sections/{id}/all`
/// (Plex) or `/Items` (Jellyfin) endpoint expects.
///
/// Pulled out of the clients so the translation can be unit-tested without
/// spinning up an HTTP layer, and so the per-backend filter/sort name
/// mappings live in one place.
abstract class LibraryQueryTranslator {
  Map<String, dynamic> toQueryParameters(LibraryQuery query);

  /// Parse a Plex-style sort string (`field` or `field:desc`) into the
  /// backend-neutral [LibrarySort] consumed by the translators. Returns
  /// `null` when the input is empty or the field portion is missing.
  static LibrarySort? parseSortParam(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    const descSuffix = ':desc';
    const ascSuffix = ':asc';
    final descending = raw.endsWith(descSuffix);
    final ascending = raw.endsWith(ascSuffix);
    final field = descending
        ? raw.substring(0, raw.length - descSuffix.length)
        : ascending
        ? raw.substring(0, raw.length - ascSuffix.length)
        : raw;
    if (field.isEmpty) return null;
    return LibrarySort(
      field: field,
      direction: descending ? LibrarySortDirection.descending : LibrarySortDirection.ascending,
    );
  }
}

/// Plex's `/library/sections/{id}/all` accepts a flat `key=value` map.
/// Numeric `type=` selects the result class (1=movie, 2=show, …);
/// `sort=titleSort:asc` chains field+direction; filters are passed
/// verbatim under their original Plex names.
class PlexLibraryQueryTranslator implements LibraryQueryTranslator {
  const PlexLibraryQueryTranslator();

  @override
  Map<String, String> toQueryParameters(LibraryQuery query) {
    final filters = <String, String>{};
    final kindNumber = _plexTypeNumberFor(query.kind);
    if (kindNumber != null) {
      filters['type'] = kindNumber.toString();
    }
    final sort = query.sort;
    if (sort != null) {
      final dir = sort.direction == LibrarySortDirection.descending ? ':desc' : ':asc';
      filters['sort'] = '${sort.field}$dir';
    }
    if (query.search != null && query.search!.isNotEmpty) {
      filters['title'] = query.search!;
    }
    if (!query.includeWatched) {
      filters['unwatched'] = '1';
    }
    // Typed slots: emit under the Plex API names so a `LibraryQuery` built
    // from the FiltersBottomSheet (which still hands the browse tab a
    // `Map<String,String>`) round-trips back to the same wire query that the
    // legacy `plexStyleFilters` parameter used to carry.
    if (query.genres != null && query.genres!.isNotEmpty) {
      filters['genre'] = query.genres!.join(',');
    }
    if (query.officialRatings != null && query.officialRatings!.isNotEmpty) {
      filters['contentRating'] = query.officialRatings!.join(',');
    }
    if (query.years != null && query.years!.isNotEmpty) {
      filters['year'] = query.years!.join(',');
    }
    if (query.tags != null && query.tags!.isNotEmpty) {
      filters['tag'] = query.tags!.join(',');
    }
    if (query.nameStartsWith != null && query.nameStartsWith!.isNotEmpty) {
      filters['alphaPrefix'] = query.nameStartsWith!;
    }
    for (final f in query.filters) {
      filters[f.field] = f.values.join(',');
    }
    return filters;
  }

  static int? _plexTypeNumberFor(MediaKind? kind) {
    if (kind == null) return null;
    return switch (kind) {
      MediaKind.movie => PlexMetadataType.movie,
      MediaKind.show => PlexMetadataType.show,
      MediaKind.season => PlexMetadataType.season,
      MediaKind.episode => PlexMetadataType.episode,
      MediaKind.artist => PlexMetadataType.artist,
      MediaKind.album => PlexMetadataType.album,
      MediaKind.track => PlexMetadataType.track,
      _ => null,
    };
  }
}

/// Inverse of [PlexLibraryQueryTranslator.toQueryParameters]: build a neutral
/// [LibraryQuery] from the legacy Plex-style `Map<String,String>` filter map.
///
/// Lives here so the round-trip stays in one file and the test that pins
/// equivalence (`map → LibraryQuery → Plex map` byte-for-byte) can import a
/// single symbol.
///
/// Recognised keys map to their typed [LibraryQuery] slots (genre/year/
/// contentRating/tag/unwatched/sort/type/alphaPrefix). Anything else carries
/// over as a generic [LibraryFilter] entry so Plex's verbatim-pass-through
/// behaviour for ad-hoc keys (director, writer, label, …) is preserved.
///
/// `libraryKind` overrides any `type=` entry — both can be sources of truth
/// in the existing browse tab and the explicit argument wins.
LibraryQuery libraryQueryFromPlexMap({
  required Map<String, String> map,
  MediaKind? libraryKind,
  int offset = 0,
  int limit = 50,
}) {
  const knownKeys = {
    'genre',
    'year',
    'contentRating',
    'tag',
    'unwatched',
    'sort',
    'type',
    'alphaPrefix',
    'includeCollections',
    'title',
  };

  String? nonEmpty(String? raw) => (raw == null || raw.isEmpty) ? null : raw;

  // libraryKind has priority; otherwise derive from `type` (single numeric
  // value only — multi-value `type` like "1,4" stays in the generic filter
  // bucket so Plex still receives it verbatim).
  final typeRaw = nonEmpty(map['type']);
  final kindFromMap = (typeRaw != null && !typeRaw.contains(',')) ? _plexTypeMediaKind(typeRaw) : null;
  final kind = libraryKind ?? kindFromMap;

  final unknownFilters = <LibraryFilter>[];
  for (final entry in map.entries) {
    if (knownKeys.contains(entry.key) || entry.value.isEmpty) continue;
    unknownFilters.add(LibraryFilter(field: entry.key, values: entry.value.split(',')));
  }
  // Multi-value `type` couldn't fold into `kind`; preserve it as a generic
  // filter entry so Plex still gets it on the wire.
  if (typeRaw != null && typeRaw.contains(',')) {
    unknownFilters.add(LibraryFilter(field: 'type', values: typeRaw.split(',')));
  }

  List<String>? singleton(String? raw) => raw == null ? null : [raw];

  final yearRaw = nonEmpty(map['year']);
  final years = yearRaw?.split(',').map(int.tryParse).whereType<int>().toList();

  return LibraryQuery(
    kind: (kind == null || kind == MediaKind.unknown) ? null : kind,
    offset: offset,
    limit: limit,
    includeWatched: nonEmpty(map['unwatched']) != '1',
    nameStartsWith: nonEmpty(map['alphaPrefix']),
    search: nonEmpty(map['title']),
    genres: singleton(nonEmpty(map['genre'])),
    officialRatings: singleton(nonEmpty(map['contentRating'])),
    tags: singleton(nonEmpty(map['tag'])),
    years: (years == null || years.isEmpty) ? null : years,
    sort: LibraryQueryTranslator.parseSortParam(nonEmpty(map['sort'])),
    filters: unknownFilters,
  );
}

MediaKind? _plexTypeMediaKind(String typeNumber) {
  return switch (typeNumber) {
    '1' => MediaKind.movie,
    '2' => MediaKind.show,
    '3' => MediaKind.season,
    '4' => MediaKind.episode,
    '8' => MediaKind.artist,
    '9' => MediaKind.album,
    '10' => MediaKind.track,
    _ => null,
  };
}

/// Jellyfin's `/Items` accepts a richer parameter set with separate keys
/// for filters (`Genres`, `OfficialRatings`, `Tags`, `Years`), sort
/// (`SortBy`/`SortOrder`), pagination (`StartIndex`/`Limit`), and
/// item-type narrowing (`IncludeItemTypes`).
///
/// The translator needs the calling user's id (every Jellyfin browse
/// query is user-scoped) and the parent library id; both are passed in
/// at construction time so the resulting map round-trips through
/// `_http.get('/Items', queryParameters: ...)` without further mutation.
class JellyfinLibraryQueryTranslator implements LibraryQueryTranslator {
  final String userId;
  final String parentId;
  final String fields;

  const JellyfinLibraryQueryTranslator({required this.userId, required this.parentId, required this.fields});

  @override
  Map<String, dynamic> toQueryParameters(LibraryQuery query) {
    final params = <String, dynamic>{
      'userId': userId,
      'ParentId': parentId,
      'Recursive': 'true',
      'StartIndex': query.offset.toString(),
      'Limit': query.limit.toString(),
      'IncludeItemTypes': _includeTypesFor(query.kind),
      'Fields': fields,
      ...jellyfinImageQueryParameters,
    };
    if (!query.includeWatched) {
      params['Filters'] = 'IsUnplayed';
    }
    if (query.genres != null && query.genres!.isNotEmpty) {
      // Jellyfin uses `|` as the multi-value separator for Genres.
      params['Genres'] = query.genres!.join('|');
    }
    if (query.officialRatings != null && query.officialRatings!.isNotEmpty) {
      params['OfficialRatings'] = query.officialRatings!.join('|');
    }
    if (query.years != null && query.years!.isNotEmpty) {
      params['Years'] = query.years!.join(',');
    }
    if (query.tags != null && query.tags!.isNotEmpty) {
      params['Tags'] = query.tags!.join('|');
    }
    final sort = query.sort;
    if (sort != null) {
      params['SortBy'] = _sortFieldFor(sort.field);
      params['SortOrder'] = sort.direction == LibrarySortDirection.descending ? 'Descending' : 'Ascending';
    }
    if (query.search != null && query.search!.isNotEmpty) {
      params['SearchTerm'] = query.search;
    }
    final prefix = query.nameStartsWith;
    if (prefix != null && prefix.isNotEmpty) {
      // `#` is the alpha-bar sentinel for "non-alphabetic" — match the JF
      // web client by asking for everything sorted before "A".
      if (prefix == '#') {
        params['NameLessThan'] = 'A';
      } else {
        params['NameStartsWith'] = prefix;
      }
    }
    return params;
  }

  static String _includeTypesFor(MediaKind? kind) {
    return switch (kind) {
      MediaKind.movie => 'Movie',
      MediaKind.show => 'Series',
      MediaKind.season => 'Season',
      MediaKind.episode => 'Episode',
      MediaKind.artist => 'MusicArtist',
      MediaKind.album => 'MusicAlbum',
      MediaKind.track => 'Audio',
      MediaKind.collection => 'BoxSet',
      MediaKind.playlist => 'Playlist',
      MediaKind.clip => 'Video,MusicVideo',
      MediaKind.photo => 'Photo',
      _ => 'Movie,Series,Episode,Audio',
    };
  }

  static String _sortFieldFor(String neutral) {
    return switch (neutral) {
      'addedAt' => 'DateCreated',
      'originallyAvailableAt' => 'PremiereDate',
      'lastViewedAt' => 'DatePlayed',
      'title' => 'SortName',
      'rating' => 'CommunityRating',
      'viewCount' => 'PlayCount',
      'random' => 'Random',
      _ => neutral,
    };
  }
}
