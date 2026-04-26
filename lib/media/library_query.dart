import 'media_kind.dart';

/// Sort order applied to a library query.
enum LibrarySortDirection { ascending, descending }

class LibrarySort {
  /// Backend-neutral sort field. Common values: `addedAt`, `originallyAvailableAt`,
  /// `lastViewedAt`, `title`, `rating`, `viewCount`, `random`.
  final String field;
  final LibrarySortDirection direction;

  const LibrarySort({required this.field, this.direction = LibrarySortDirection.descending});
}

/// A single filter clause. The semantics of `field` and `value` are
/// backend-translated — the neutral query just carries the intent.
class LibraryFilter {
  final String field;
  final String op; // "=", "!=", "contains", ">=", etc.
  final List<String> values;

  const LibraryFilter({required this.field, this.op = '=', required this.values});
}

/// Backend-neutral library content query. Each backend's adapter translates
/// these into its own query DSL (Plex `/library/sections/{id}/all?type=...`
/// or Jellyfin `/Items?ParentId=...&Filters=...`).
class LibraryQuery {
  /// Restrict to a single kind (e.g. `MediaKind.movie`). Null = library default.
  final MediaKind? kind;

  /// Pagination — zero-based offset.
  final int offset;
  final int limit;

  final LibrarySort? sort;
  final List<LibraryFilter> filters;

  /// Free-text search restricted to this library. Distinct from the global
  /// search endpoint.
  final String? search;

  /// Whether to include items the active user has already watched.
  final bool includeWatched;

  /// Restrict the result to items whose sort name starts with this string —
  /// the alpha-jump bar's filter UX. The literal `#` is a sentinel for
  /// "non-alphabetic" and translates to a `NameLessThan=A` query for backends
  /// that support it.
  final String? nameStartsWith;

  /// Genre filter — used by the per-library filter sheet. Backends that
  /// take multiple values (Jellyfin) AND/intersect; those that take one
  /// (Plex's existing flow) consult `filters` instead.
  final List<String>? genres;
  final List<String>? officialRatings;
  final List<int>? years;
  final List<String>? tags;

  const LibraryQuery({
    this.kind,
    this.offset = 0,
    this.limit = 50,
    this.sort,
    this.filters = const [],
    this.search,
    this.includeWatched = true,
    this.nameStartsWith,
    this.genres,
    this.officialRatings,
    this.years,
    this.tags,
  });

  LibraryQuery copyWith({
    MediaKind? kind,
    int? offset,
    int? limit,
    LibrarySort? sort,
    List<LibraryFilter>? filters,
    String? search,
    bool? includeWatched,
    String? nameStartsWith,
    List<String>? genres,
    List<String>? officialRatings,
    List<int>? years,
    List<String>? tags,
  }) {
    return LibraryQuery(
      kind: kind ?? this.kind,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
      search: search ?? this.search,
      includeWatched: includeWatched ?? this.includeWatched,
      nameStartsWith: nameStartsWith ?? this.nameStartsWith,
      genres: genres ?? this.genres,
      officialRatings: officialRatings ?? this.officialRatings,
      years: years ?? this.years,
      tags: tags ?? this.tags,
    );
  }
}

/// Page of items returned by [MediaServerClient.getLibraryContent].
/// Carries the total count so the UI can render correct pagination affordances.
class LibraryPage<T> {
  final List<T> items;
  final int totalCount;
  final int offset;

  const LibraryPage({required this.items, required this.totalCount, this.offset = 0});
}
