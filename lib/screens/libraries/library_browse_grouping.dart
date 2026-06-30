import '../../media/media_kind.dart';
import '../../media/media_library.dart';

const browseGroupingAll = 'all';
const browseGroupingMovies = 'movies';
const browseGroupingShows = 'shows';
const browseGroupingSeasons = 'seasons';
const browseGroupingEpisodes = 'episodes';
const browseGroupingFolders = 'folders';

List<String> libraryBrowseGroupingOptions(MediaLibrary library, {required bool canGroupByFolders}) {
  if (library.isShared) {
    return const [
      browseGroupingAll,
      browseGroupingMovies,
      browseGroupingShows,
      browseGroupingSeasons,
      browseGroupingEpisodes,
    ];
  }

  return switch (library.kind) {
    MediaKind.show => [
      browseGroupingShows,
      browseGroupingSeasons,
      browseGroupingEpisodes,
      if (canGroupByFolders) browseGroupingFolders,
    ],
    MediaKind.movie => [browseGroupingMovies, if (canGroupByFolders) browseGroupingFolders],
    _ => [browseGroupingAll, if (canGroupByFolders) browseGroupingFolders],
  };
}

String defaultLibraryBrowseGrouping(MediaLibrary library) {
  if (library.isShared) return browseGroupingAll;
  return switch (library.kind) {
    MediaKind.show => browseGroupingShows,
    MediaKind.movie => browseGroupingMovies,
    _ => browseGroupingAll,
  };
}

String normalizeLibraryBrowseGrouping(MediaLibrary library, String? grouping, {required bool canGroupByFolders}) {
  final options = libraryBrowseGroupingOptions(library, canGroupByFolders: canGroupByFolders);
  if (grouping != null && options.contains(grouping)) return grouping;

  final fallback = defaultLibraryBrowseGrouping(library);
  return options.contains(fallback) ? fallback : options.first;
}
