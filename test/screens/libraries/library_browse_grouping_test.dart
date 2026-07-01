import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/library_browse_grouping.dart';

MediaLibrary _library({required MediaKind kind, bool isShared = false}) {
  return MediaLibrary(
    id: '1',
    backend: MediaBackend.plex,
    title: 'Library',
    kind: kind,
    isShared: isShared,
    serverId: 'server-1',
  );
}

void main() {
  group('libraryBrowseGroupingOptions', () {
    test('movie libraries optionally include folders', () {
      final library = _library(kind: MediaKind.movie);

      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: false), const [browseGroupingMovies]);
      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: true), const [
        browseGroupingMovies,
        browseGroupingFolders,
      ]);
    });

    test('show libraries include show hierarchy before folders', () {
      final library = _library(kind: MediaKind.show);

      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: true), const [
        browseGroupingShows,
        browseGroupingSeasons,
        browseGroupingEpisodes,
        browseGroupingFolders,
      ]);
    });

    test('shared libraries expose all video groupings and never folders', () {
      final library = _library(kind: MediaKind.movie, isShared: true);

      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: true), const [
        browseGroupingAll,
        browseGroupingMovies,
        browseGroupingShows,
        browseGroupingSeasons,
        browseGroupingEpisodes,
      ]);
    });
  });

  group('normalizeLibraryBrowseGrouping', () {
    test('keeps a valid saved grouping', () {
      final library = _library(kind: MediaKind.show);

      expect(
        normalizeLibraryBrowseGrouping(library, browseGroupingEpisodes, canGroupByFolders: false),
        browseGroupingEpisodes,
      );
    });

    test('falls back when saved folder grouping is no longer available', () {
      final library = _library(kind: MediaKind.movie);

      expect(
        normalizeLibraryBrowseGrouping(library, browseGroupingFolders, canGroupByFolders: false),
        browseGroupingMovies,
      );
    });

    test('shared libraries default to all', () {
      final library = _library(kind: MediaKind.movie, isShared: true);

      expect(normalizeLibraryBrowseGrouping(library, null, canGroupByFolders: true), browseGroupingAll);
    });

    test('shared libraries reject stale saved folder grouping', () {
      final library = _library(kind: MediaKind.movie, isShared: true);

      expect(
        normalizeLibraryBrowseGrouping(library, browseGroupingFolders, canGroupByFolders: true),
        browseGroupingAll,
      );
    });
  });
}
