import '../media/library_query.dart';
import '../media/media_filter.dart';
import '../media/media_kind.dart';
import 'plex_constants.dart';

/// Browse responses retain up to three backdrops so hero surfaces can rotate
/// artwork without allowing image-tag payloads to grow without bound.
const jellyfinBackdropImageLimit = 3;

/// `Thumb` is deliberately absent: `JellyfinMappers` never reads
/// `ImageTags['Thumb']`, and `parentThumbPath`/`grandparentThumbPath` are built
/// from the season/series *Primary* tags. Asking for it added a dead image type
/// to ~40 requests and widened the server's inherited-image parent walk.
const jellyfinImageQueryParameters = <String, String>{
  'EnableImageTypes': 'Primary,Backdrop,Logo',
  'ImageTypeLimit': '$jellyfinBackdropImageLimit',
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

/// Plex's `/library/sections/{id}/all` accepts a flat `key=value` query.
/// Numeric `type=` selects the result class (1=movie, 2=show, …);
/// `sort=titleSort:asc` chains field+direction; filter clauses are lowered by
/// [plexFilterQueryParameters].
class PlexLibraryQueryTranslator implements LibraryQueryTranslator {
  const PlexLibraryQueryTranslator();

  @override
  Map<String, dynamic> toQueryParameters(LibraryQuery query) {
    final params = <String, dynamic>{};
    if (query.includeKinds.isNotEmpty) {
      final kindNumbers = query.includeKinds.map(PlexMetadataType.forKind).whereType<int>().join(',');
      if (kindNumbers.isNotEmpty) {
        params['type'] = kindNumbers;
      }
    } else {
      final kindNumber = PlexMetadataType.forKind(query.kind);
      if (kindNumber != null) {
        params['type'] = kindNumber.toString();
      }
    }
    final sort = query.sort;
    if (sort != null) {
      final dir = sort.direction == LibrarySortDirection.descending ? ':desc' : ':asc';
      params['sort'] = '${sort.field}$dir';
    }
    if (query.search != null && query.search!.isNotEmpty) {
      params['title'] = query.search!;
    }
    if (query.nameStartsWith != null && query.nameStartsWith!.isNotEmpty) {
      params['alphaPrefix'] = query.nameStartsWith!;
    }
    for (final entry in plexFilterQueryParameters(query.filters).entries) {
      final existing = params[entry.key];
      if (existing == null) {
        params[entry.key] = entry.value;
        continue;
      }
      // `title` can arrive from both the search box and a clause; Plex ANDs
      // repeated keys, so keep both instead of letting one win.
      params[entry.key] = <String>[
        ...existing is List<String> ? existing : <String>[existing as String],
        ...entry.value is List<String> ? entry.value as List<String> : <String>[entry.value as String],
      ];
    }
    return params;
  }
}

/// Lower filter clauses onto Plex's query vocabulary.
///
/// The operator lives in the query *key* (`year>>=2015` is key `year>>`,
/// value `2015`), values inside one clause are comma-joined and OR, and two
/// clauses that produce the same key repeat it, which Plex ANDs. Repeated
/// keys survive to the wire because `encodeQueryParameters` expands iterable
/// values into repeated pairs.
Map<String, dynamic> plexFilterQueryParameters(Iterable<LibraryFilter> clauses) {
  final params = <String, dynamic>{};
  for (final clause in clauses) {
    final values = clause.values.where((value) => value.isNotEmpty).toList();
    if (clause.field.isEmpty || values.isEmpty) continue;
    final key = '${clause.field}${clause.op.wireSuffix}';
    final value = values.join(',');
    final existing = params[key];
    if (existing == null) {
      params[key] = value;
    } else if (existing is List<String>) {
      existing.add(value);
    } else {
      params[key] = <String>[existing as String, value];
    }
  }
  return params;
}

/// Assemble the neutral [LibraryQuery] the library browse surfaces run.
///
/// [clauses] is the user's filter selection; [typeParam] is the grouping's
/// Plex metadata type (a single number folds into [LibraryQuery.kind], a CSV
/// stays a `type` clause so Plex still receives it verbatim); [sortParam] is
/// the Plex-style `field:desc` string the sort sheet produces.
///
/// `libraryKind` overrides any [typeParam] — both can be sources of truth in
/// the browse tab and the explicit argument wins.
LibraryQuery libraryQueryFromSelection({
  required List<LibraryFilter> clauses,
  MediaKind? libraryKind,
  String? typeParam,
  String? sortParam,
  String? alphaPrefix,
  String? search,
  int offset = 0,
  int limit = 50,
}) {
  String? nonEmpty(String? raw) => (raw == null || raw.isEmpty) ? null : raw;

  final typeRaw = nonEmpty(typeParam);
  final kindFromType = (typeRaw != null && !typeRaw.contains(','))
      ? PlexMetadataType.kindFor(int.tryParse(typeRaw))
      : null;
  final kind = libraryKind ?? kindFromType;

  final filters = <LibraryFilter>[
    ...clauses,
    // Multi-value `type` can't fold into `kind`; keep it as a clause.
    if (typeRaw != null && typeRaw.contains(',')) LibraryFilter(field: 'type', values: typeRaw.split(',')),
  ];

  return LibraryQuery(
    kind: (kind == null || kind == MediaKind.unknown) ? null : kind,
    offset: offset,
    limit: limit,
    nameStartsWith: nonEmpty(alphaPrefix),
    search: nonEmpty(search),
    sort: LibraryQueryTranslator.parseSortParam(nonEmpty(sortParam)),
    filters: filters,
  );
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
      'EnableTotalRecordCount': 'true',
      'IncludeItemTypes': _includeTypesFor(query),
      'Fields': fields,
      ...jellyfinImageQueryParameters,
    };
    _applyFilterClauses(query.filters, params);
    final sort = query.sort;
    if (sort != null) {
      params['SortBy'] = _sortFieldFor(sort.field, query.kind);
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

  /// Lower neutral clauses onto `/Items` parameters.
  ///
  /// MediaBrowser has no generic per-field negation, so only the two booleans
  /// support exclusion (`IsPlayed`, `isFavorite=false`) — that limit is
  /// declared per field in `fetchLibraryFiltersWithValues`, so the UI cannot
  /// build a clause this drops. Multi-value clauses OR, matching Plex.
  /// A second clause on the same field would have to AND, which `/Items`
  /// cannot express, so the first clause for a field wins.
  static void _applyFilterClauses(List<LibraryFilter> clauses, Map<String, dynamic> params) {
    final wireFilters = <String>[];
    final claimed = <String>{};
    for (final clause in clauses) {
      final values = clause.values.where((value) => value.isNotEmpty).toList();
      if (values.isEmpty || !claimed.add(clause.field)) continue;
      final negated = clause.op.isNegated;
      switch (clause.field) {
        case MediaFilterField.unwatched:
          if (values.first != '1') break;
          wireFilters.add(negated ? 'IsPlayed' : 'IsUnplayed');
        case MediaFilterField.favorite:
          // Equality only — see `fetchLibraryFiltersWithValues`. A negated
          // clause cannot be built through the editor and has no correct wire
          // form, so it is dropped rather than approximated.
          if (values.first != '1' || negated) break;
          wireFilters.add('IsFavorite');
        case MediaFilterField.genre:
          params['Genres'] = values.join('|');
        case MediaFilterField.contentRating:
          params['OfficialRatings'] = values.join('|');
        case MediaFilterField.tag:
          params['Tags'] = values.join('|');
        case MediaFilterField.year:
          final years = values.map(int.tryParse).whereType<int>().toList();
          if (years.isNotEmpty) params['Years'] = years.join(',');
      }
    }
    if (wireFilters.isNotEmpty) {
      params['Filters'] = wireFilters.join(',');
    }
  }

  static String _includeTypesFor(LibraryQuery query) {
    if (query.includeKinds.isNotEmpty) {
      return query.includeKinds.map(_includeTypesForKind).join(',');
    }
    return _includeTypesForKind(query.kind);
  }

  static String _includeTypesForKind(MediaKind? kind) {
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

  static String _sortFieldFor(String neutral, MediaKind? kind) {
    return switch (neutral) {
      'addedAt' => 'DateCreated',
      'episode.addedAt' => 'DateLastContentAdded,SortName',
      'dateCreated' => 'DateCreated',
      'originallyAvailableAt' => 'PremiereDate',
      'premiereDate' => 'PremiereDate',
      'lastViewedAt' || 'datePlayed' => kind == MediaKind.show ? 'SeriesDatePlayed' : 'DatePlayed',
      'title' => 'SortName',
      'name' => 'SortName',
      'rating' || 'communityRating' => 'CommunityRating',
      'viewCount' || 'playCount' => 'PlayCount',
      'productionYear' => 'ProductionYear',
      'runtime' => 'Runtime',
      'officialRating' => 'OfficialRating',
      'criticRating' => 'CriticRating',
      'startDate' => 'StartDate',
      'airTime' => 'AirTime',
      'studio' => 'Studio',
      'random' => 'Random',
      _ => neutral,
    };
  }
}
