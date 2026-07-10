// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_kind.dart';

part 'library_query.freezed.dart';

/// Sort order applied to a library query.
enum LibrarySortDirection { ascending, descending }

@freezed
sealed class LibrarySort with _$LibrarySort {
  /// Backend-neutral sort field. Common values: `addedAt`, `originallyAvailableAt`,
  /// `lastViewedAt`, `title`, `rating`, `viewCount`, `random`.
  const factory LibrarySort({
    required String field,
    @Default(LibrarySortDirection.descending) LibrarySortDirection direction,
  }) = _LibrarySort;
}

/// A single filter clause. The semantics of `field` and `value` are
/// backend-translated — the neutral query just carries the intent.
@freezed
sealed class LibraryFilter with _$LibraryFilter {
  const factory LibraryFilter({required String field, @Default('=') String op, required List<String> values}) =
      _LibraryFilter;
}

/// Backend-neutral library content query. Each backend's adapter translates
/// these into its own query DSL (Plex `/library/sections/{id}/all?type=...`
/// or Jellyfin `/Items?ParentId=...&Filters=...`).
@freezed
sealed class LibraryQuery with _$LibraryQuery {
  const factory LibraryQuery({
    /// Restrict to a single kind (e.g. `MediaKind.movie`). Null = library default.
    MediaKind? kind,

    /// Pagination — zero-based offset.
    @Default(0) int offset,
    @Default(50) int limit,

    LibrarySort? sort,
    @Default(<LibraryFilter>[]) List<LibraryFilter> filters,

    /// Free-text search restricted to this library. Distinct from the global
    /// search endpoint.
    String? search,

    /// Whether to include items the active user has already watched.
    @Default(true) bool includeWatched,

    /// Restrict to items the user marked favorite (Jellyfin `Filters=IsFavorite`).
    /// Plex has no equivalent; its translator ignores the flag.
    @Default(false) bool favoritesOnly,

    /// Restrict the result to items whose sort name starts with this string —
    /// the alpha-jump bar's filter UX. The literal `#` is a sentinel for
    /// "non-alphabetic" and translates to a `NameLessThan=A` query for backends
    /// that support it.
    String? nameStartsWith,

    /// Genre filter — used by the per-library filter sheet. Backends that
    /// take multiple values (Jellyfin) AND/intersect; those that take one
    /// (Plex's existing flow) consult `filters` instead.
    List<String>? genres,
    List<String>? officialRatings,
    List<int>? years,
    List<String>? tags,
  }) = _LibraryQuery;
}

/// Page of items returned by [MediaServerClient.getLibraryContent].
/// Carries the total count so the UI can render correct pagination affordances.
@freezed
sealed class LibraryPage<T> with _$LibraryPage<T> {
  const factory LibraryPage({required List<T> items, required int totalCount, @Default(0) int offset}) =
      _LibraryPage<T>;
}
