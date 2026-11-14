import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/library_browse_grouping.dart';
import 'package:plezy/services/library_query_translator.dart';

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

    test('music libraries group by artists, albums, and tracks', () {
      final library = _library(kind: MediaKind.artist);

      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: false), const [
        browseGroupingArtists,
        browseGroupingAlbums,
        browseGroupingTracks,
      ]);
      expect(libraryBrowseGroupingOptions(library, canGroupByFolders: true), const [
        browseGroupingArtists,
        browseGroupingAlbums,
        browseGroupingTracks,
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

    test('music libraries default to artists and keep a saved music grouping', () {
      final library = _library(kind: MediaKind.artist);

      expect(normalizeLibraryBrowseGrouping(library, null, canGroupByFolders: false), browseGroupingArtists);
      expect(
        normalizeLibraryBrowseGrouping(library, browseGroupingTracks, canGroupByFolders: false),
        browseGroupingTracks,
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

    test('clip libraries default to folders when available (#966)', () {
      final library = _library(kind: MediaKind.clip);

      expect(normalizeLibraryBrowseGrouping(library, null, canGroupByFolders: true), browseGroupingFolders);
      expect(normalizeLibraryBrowseGrouping(library, null, canGroupByFolders: false), browseGroupingAll);
    });

    test('clip libraries keep an explicitly saved flat grouping', () {
      final library = _library(kind: MediaKind.clip);

      expect(normalizeLibraryBrowseGrouping(library, browseGroupingAll, canGroupByFolders: true), browseGroupingAll);
    });
  });

  group('musicShuffleQuery', () {
    const electronic = LibraryFilter(field: 'genre', values: ['5194']);
    Map<String, dynamic> wire(LibraryQuery query) => const PlexLibraryQueryTranslator().toQueryParameters(query);

    test('a genre picked among artists shuffles tracks by those artists', () {
      expect(wire(musicShuffleQuery(browseGroupingArtists, [electronic])!), {
        'type': '10',
        'sort': 'random:desc',
        'artist.genre': '5194',
      });
    });

    test('a genre picked among albums shuffles tracks on those albums', () {
      expect(wire(musicShuffleQuery(browseGroupingAlbums, [electronic])!)['album.genre'], '5194');
    });

    test('a genre picked among tracks filters the tracks themselves', () {
      expect(wire(musicShuffleQuery(browseGroupingTracks, [electronic])!)['genre'], '5194');
    });

    test('an unfiltered view shuffles the whole library, a queue at a time', () {
      final query = musicShuffleQuery(browseGroupingArtists, const [])!;
      expect(wire(query), {'type': '10', 'sort': 'random:desc'});
      expect(query.limit, musicShuffleTrackCount);
    });

    test('folders have no set of tracks to shuffle', () {
      expect(musicShuffleQuery(browseGroupingFolders, const [electronic]), isNull);
      expect(musicShuffleQuery(browseGroupingAll, const []), isNull);
    });
  });

  group('musicRadioQuery', () {
    test('sticks to tracks people know', () {
      final query = musicRadioQuery(browseGroupingArtists, const [
        LibraryFilter(field: 'genre', values: ['9354']),
      ])!;
      expect(const PlexLibraryQueryTranslator().toQueryParameters(query), {
        'type': '10',
        'sort': 'random:desc',
        'artist.genre': '9354',
        'ratingCount>>': '$musicRadioMinListeners',
      });
    });

    test('folders have no radio', () {
      expect(musicRadioQuery(browseGroupingFolders, const []), isNull);
    });
  });

  group('spreadArtists', () {
    MediaItem track(String id, String artist) =>
        MediaItem.plex(id: id, serverId: 's', kind: MediaKind.track, grandparentId: artist, grandparentTitle: artist);
    List<String?> artists(List<MediaItem> tracks) => [for (final t in tracks) t.grandparentId];

    test('no artist gets more than its share', () {
      final tracks = [for (var i = 0; i < 10; i++) track('d$i', 'Dylan'), track('j', 'Joni'), track('n', 'Nick')];
      final spread = spreadArtists(tracks, count: 100);
      expect(artists(spread).where((a) => a == 'Dylan'), hasLength(musicRadioTracksPerArtist));
      expect(spread, hasLength(musicRadioTracksPerArtist + 2));
    });

    test('the same artist is not played twice in a row where it can be helped', () {
      final tracks = [track('d1', 'Dylan'), track('d2', 'Dylan'), track('j1', 'Joni'), track('j2', 'Joni')];
      expect(artists(spreadArtists(tracks, count: 100)), ['Dylan', 'Joni', 'Dylan', 'Joni']);
    });

    test('stops at count', () {
      final tracks = [for (var i = 0; i < 10; i++) track('$i', 'artist $i')];
      expect(spreadArtists(tracks, count: 4).map((t) => t.id), ['0', '1', '2', '3']);
    });
  });
}
