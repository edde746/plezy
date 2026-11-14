import '../../media/media_item.dart';
import '../../media/library_query.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';

const browseGroupingAll = 'all';
const browseGroupingMovies = 'movies';
const browseGroupingShows = 'shows';
const browseGroupingSeasons = 'seasons';
const browseGroupingEpisodes = 'episodes';
const browseGroupingArtists = 'artists';
const browseGroupingAlbums = 'albums';
const browseGroupingTracks = 'tracks';
const browseGroupingFolders = 'folders';
const browseGroupingLibrary = 'library';
const browseGroupingCollections = 'collections';

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
    MediaKind.artist => [
      browseGroupingArtists,
      browseGroupingAlbums,
      browseGroupingTracks,
      if (canGroupByFolders) browseGroupingFolders,
    ],
    _ => [browseGroupingAll, if (canGroupByFolders) browseGroupingFolders],
  };
}

String defaultLibraryBrowseGrouping(MediaLibrary library, {required bool canGroupByFolders}) {
  if (library.isShared) return browseGroupingAll;
  return switch (library.kind) {
    MediaKind.show => browseGroupingShows,
    MediaKind.movie => browseGroupingMovies,
    MediaKind.artist => browseGroupingArtists,
    // Home-video libraries are folder-organized on the server, so open them
    // grouped by folders like the official clients do (#966). An explicitly
    // saved grouping still wins — this is only the unset-preference fallback.
    MediaKind.clip when canGroupByFolders => browseGroupingFolders,
    _ => browseGroupingAll,
  };
}

String normalizeLibraryBrowseGrouping(MediaLibrary library, String? grouping, {required bool canGroupByFolders}) {
  final options = libraryBrowseGroupingOptions(library, canGroupByFolders: canGroupByFolders);
  if (grouping != null && options.contains(grouping)) return grouping;

  final fallback = defaultLibraryBrowseGrouping(library, canGroupByFolders: canGroupByFolders);
  return options.contains(fallback) ? fallback : options.first;
}

/// How many tracks a library shuffle queues. A genre can run to tens of
/// thousands of tracks, far more than a queue should hold, so the server picks
/// this many at random from all of them.
const musicShuffleTrackCount = 500;

/// The Plex track query behind shuffling a music view: every track belonging
/// to what the view shows, in random order. Null for a grouping with no such
/// set of tracks (folders, all).
///
/// [filters] were chosen against the grouping's own type, so they move onto
/// it: "Electronic" picked while viewing artists means tracks by Electronic
/// artists (`artist.genre`), which is several times the tracks Plex tags
/// Electronic themselves.
LibraryQuery? musicShuffleQuery(String grouping, List<LibraryFilter> filters) {
  final prefix = switch (grouping) {
    browseGroupingArtists => 'artist.',
    browseGroupingAlbums => 'album.',
    browseGroupingTracks => '',
    _ => null,
  };
  if (prefix == null) return null;
  return LibraryQuery(
    kind: MediaKind.track,
    limit: musicShuffleTrackCount,
    sort: const LibrarySort(field: 'random'),
    filters: [for (final filter in filters) filter.copyWith(field: '$prefix${filter.field}')],
  );
}

/// How many tracks a radio from a library view queues.
const musicRadioTrackCount = 100;

/// Plex keeps each track's Last.fm listener count. Radio sticks to tracks at
/// least this many people know, which is most of what sets it apart from a
/// shuffle: a shuffle of Folk is a fair share of B-sides and demos.
const musicRadioMinListeners = 5000;

/// The most tracks one artist gets in a radio queue. A plain random pick of
/// Folk is nearly a tenth Bob Dylan.
const musicRadioTracksPerArtist = 3;

/// Plex has no station for a genre or a filtered view, so radio from one is
/// [musicShuffleQuery] narrowed to well-known tracks, then [spreadArtists].
LibraryQuery? musicRadioQuery(String grouping, List<LibraryFilter> filters) {
  final query = musicShuffleQuery(grouping, filters);
  if (query == null) return null;
  return query.copyWith(
    filters: [
      ...query.filters,
      const LibraryFilter(field: 'ratingCount', op: LibraryFilterOperator.atLeast, values: ['$musicRadioMinListeners']),
    ],
  );
}

/// [tracks] with at most [perArtist] from any one artist, the same artist
/// never twice in a row where it can be helped, cut to [count].
List<MediaItem> spreadArtists(List<MediaItem> tracks, {int perArtist = musicRadioTracksPerArtist, required int count}) {
  String artistOf(MediaItem track) => track.grandparentId ?? track.grandparentTitle ?? track.id;
  final perArtistCount = <String, int>{};
  final kept = <MediaItem>[];
  for (final track in tracks) {
    final artist = artistOf(track);
    final seen = perArtistCount[artist] ?? 0;
    if (seen >= perArtist) continue;
    perArtistCount[artist] = seen + 1;
    kept.add(track);
    if (kept.length == count) break;
  }
  final spread = <MediaItem>[];
  while (kept.isNotEmpty) {
    final next = kept.indexWhere((t) => spread.isEmpty || artistOf(t) != artistOf(spread.last));
    spread.add(kept.removeAt(next < 0 ? 0 : next));
  }
  return spread;
}
