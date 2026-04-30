import '../../media/library_filter_result.dart';
import '../../media/media_filter.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../media/media_sort.dart';

/// Combined filter + sort listing loaded for a [MediaLibrary].
///
/// Plex returns categories from `/library/sections/{id}/filters` and sort
/// options from `/library/sections/{id}/sorts` separately, with values
/// fetched lazily per-category via `FiltersBottomSheet`. Jellyfin returns
/// categories *and* values together via `/Items/Filters` (so [cachedValues]
/// is populated up-front) and has no sort-listing endpoint, so its sorts
/// come from a client-side hardcoded list.
class LoadedFiltersAndSorts {
  final List<MediaFilter> filters;
  final List<MediaSort> sorts;
  final Map<String, List<MediaFilterValue>> cachedValues;

  const LoadedFiltersAndSorts({required this.filters, required this.sorts, this.cachedValues = const {}});
}

/// Loads filter categories and sort options for a [MediaLibrary] across both
/// backends through the unified [MediaServerClient] interface — Plex pulls
/// categories with no values (FiltersBottomSheet fetches lazily), Jellyfin
/// pre-populates [cachedValues] from `/Items/Filters`. [clientFor] resolves
/// the right concrete client for the library being loaded.
class LibraryFilterSortLoader {
  final MediaServerClient Function(MediaLibrary library) clientFor;

  LibraryFilterSortLoader({required this.clientFor});

  Future<LoadedFiltersAndSorts> load(MediaLibrary library) async {
    final client = clientFor(library);
    final results = await Future.wait([
      client.fetchLibraryFiltersWithValues(library.id),
      client.fetchSortOptions(library.id, libraryType: library.kind.id),
    ]);
    final filterResult = results[0] as LibraryFilterResult;
    final sorts = results[1] as List<MediaSort>;
    return LoadedFiltersAndSorts(filters: filterResult.filters, sorts: sorts, cachedValues: filterResult.cachedValues);
  }
}
