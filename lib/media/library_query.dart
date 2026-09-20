// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/media_server_http_client.dart' show AbortController;
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

/// Comparison carried by a [LibraryFilter].
///
/// [wireSuffix] is Plex's own operator spelling minus its trailing `=`, which
/// doubles as the query-string separator: `year>>=2015` is the key `year>>`
/// with the value `2015`. Percent-encoding the suffix is fine (Plex decodes
/// query keys); the separator itself must stay literal.
///
/// [id] is the persisted form; never rename it.
enum LibraryFilterOperator {
  /// Tag/boolean equality, or "contains" on a free-text field.
  is_('is', ''),

  /// Tag/boolean inequality, or "does not contain" on a free-text field.
  isNot('isNot', '!'),

  /// Numeric/date lower bound, inclusive.
  atLeast('atLeast', '>>'),

  /// Numeric/date upper bound, inclusive.
  atMost('atMost', '<<'),

  /// Free-text exact match.
  matches('matches', '='),

  /// Free-text exact mismatch.
  notMatches('notMatches', '!='),

  /// Free-text prefix match.
  beginsWith('beginsWith', '<'),

  /// Free-text suffix match.
  endsWith('endsWith', '>');

  const LibraryFilterOperator(this.id, this.wireSuffix);

  final String id;
  final String wireSuffix;

  /// Whether the operator excludes rather than includes its values.
  bool get isNegated => this == isNot || this == notMatches;

  static LibraryFilterOperator? fromId(String? id) {
    if (id == null) return null;
    for (final op in values) {
      if (op.id == id) return op;
    }
    return null;
  }
}

/// A single filter clause: one field, one comparison, one or more values.
///
/// Values inside a clause are OR-ed (Plex `genre=1,2`, Jellyfin `Genres=a|b`).
/// Separate clauses AND, including two clauses on the same field — that is how
/// a range (`year>>=2000` plus `year<<=2010`) and an intersection
/// (`genre=1&genre=2`) are expressed.
@freezed
sealed class LibraryFilter with _$LibraryFilter {
  const factory LibraryFilter({
    required String field,
    @Default(LibraryFilterOperator.is_) LibraryFilterOperator op,
    required List<String> values,
  }) = _LibraryFilter;

  const LibraryFilter._();

  /// Stable JSON form used by the persisted per-library selection.
  Map<String, Object?> toStorageJson() => {
    'field': field,
    if (op != LibraryFilterOperator.is_) 'op': op.id,
    'values': values,
  };

  static LibraryFilter? fromStorageJson(Object? raw) {
    if (raw is! Map) return null;
    final field = raw['field'];
    if (field is! String || field.isEmpty) return null;
    final values = (raw['values'] as List?)?.whereType<String>().where((v) => v.isNotEmpty).toList() ?? const [];
    if (values.isEmpty) return null;
    // A missing `op` is equality (toStorageJson omits it); a present but
    // unknown one came from a newer build, and silently downgrading an
    // exclusion to an include would show exactly what the user hid.
    final rawOp = raw['op'];
    if (rawOp != null && rawOp is! String) return null;
    final op = rawOp == null ? LibraryFilterOperator.is_ : LibraryFilterOperator.fromId(rawOp as String);
    if (op == null) return null;
    return LibraryFilter(field: field, op: op, values: values);
  }
}

/// Backend-neutral library content query. Each backend's adapter translates
/// these into its own query DSL (Plex `/library/sections/{id}/all?type=...`
/// or Jellyfin `/Items?ParentId=...&Filters=...`).
@freezed
sealed class LibraryQuery with _$LibraryQuery {
  const factory LibraryQuery({
    /// Restrict to a single kind (e.g. `MediaKind.movie`). Null = library default.
    MediaKind? kind,

    /// Restrict to multiple kinds when no single [kind] represents the browse
    /// surface. When non-empty, translators prefer this over [kind].
    @Default(<MediaKind>[]) List<MediaKind> includeKinds,

    /// Pagination — zero-based offset.
    @Default(0) int offset,
    @Default(50) int limit,

    LibrarySort? sort,

    /// Every filter clause the UI selected, in display order. Clauses AND.
    @Default(<LibraryFilter>[]) List<LibraryFilter> filters,

    /// Free-text search restricted to this library. Distinct from the global
    /// search endpoint.
    String? search,

    /// Restrict the result to items whose sort name starts with this string —
    /// the alpha-jump bar's filter UX. The literal `#` is a sentinel for
    /// "non-alphabetic" and translates to a `NameLessThan=A` query for backends
    /// that support it.
    String? nameStartsWith,
  }) = _LibraryQuery;
}

/// Page of items returned by [MediaServerClient.getLibraryContent].
/// Carries the total count so the UI can render correct pagination affordances.
@freezed
sealed class LibraryPage<T> with _$LibraryPage<T> {
  const factory LibraryPage({required List<T> items, required int totalCount, @Default(0) int offset}) =
      _LibraryPage<T>;
}

/// Conservative total for a page whose backend omitted an exact count. A full
/// page adds one sentinel item so callers keep pagination enabled without
/// claiming to know the real total.
int fallbackPageTotal({required int offset, required int itemCount, int? requestedSize}) {
  final fullPage = requestedSize != null && requestedSize > 0 && itemCount >= requestedSize;
  return offset + itemCount + (fullPage ? 1 : 0);
}

/// Walk every page of a paginated endpoint and concatenate the results.
///
/// [fetchPage] receives a zero-based offset and [pageSize] and is called until
/// a page comes back empty, the accumulated count reaches the page's
/// [LibraryPage.totalCount], or — when [stopOnShortPage] is set — a page comes
/// back shorter than [pageSize]. The short-page break is for backends whose
/// total is unreliable; leave it off when the total is authoritative.
///
/// [onPage] receives the accumulated items after each intermediate page —
/// i.e. only when another request will follow — so callers can render while
/// pagination continues. It never fires for single-page listings or the final
/// page; the returned list covers those.
///
/// [abort] is checked before and after every request. Errors propagate.
Future<List<T>> drainPages<T>(
  Future<LibraryPage<T>> Function(int start, int size) fetchPage, {
  required int pageSize,
  AbortController? abort,
  bool stopOnShortPage = false,
  void Function(List<T> accumulated)? onPage,
}) async {
  final all = <T>[];
  var start = 0;
  while (true) {
    abort?.throwIfAborted();
    final page = await fetchPage(start, pageSize);
    abort?.throwIfAborted();
    if (page.items.isEmpty) break;
    all.addAll(page.items);
    start += page.items.length;
    if (start >= page.totalCount) break;
    if (stopOnShortPage && page.items.length < pageSize) break;
    onPage?.call(all);
  }
  return all;
}
