part of '../../music_assistant_client.dart';

/// Synthesised discovery rows.
///
/// Music Assistant has no hubs endpoint and no recommendation engine, so these
/// rows are built from ordinary `library_items` queries. They exist because a
/// flat alphabetical wall of 33,000 albums whose first entries are `@`, `!!!!!!!`
/// and `...` is not something anyone scrolls: the library may as well be empty
/// until there is a way in that is not the letter A.
mixin _MusicAssistantDiscoveryMethods on _MusicAssistantClientInternals {
  /// What the user actually listened to, newest first.
  ///
  /// Deliberately sourced from `music/recently_played_items` rather than
  /// `library_items … order_by: last_played_desc` — see
  /// [MusicAssistantLibrary.getRecentlyPlayed] for the measurement that rules
  /// the ordered form out. First row because on a collection this size "carry
  /// on where I left off" beats every other way in; it drops out of the way on
  /// a server nothing has been played on yet.
  static const String recentlyPlayedHubId = 'ma:recentlyPlayed';

  /// Newest additions. On a library still being scanned this is the single most
  /// useful row there is.
  static const String recentlyAddedHubId = 'ma:recentlyAdded';

  /// Everything the user starred, albums before tracks.
  static const String favoritesHubId = 'ma:favorites';

  /// A genuine server-side shuffle (`order_by: random`), not a window at a
  /// random offset — the whole collection is in play on every request.
  static const String randomAlbumsHubId = 'ma:randomAlbums';

  static const List<String> hubIds = [recentlyPlayedHubId, recentlyAddedHubId, favoritesHubId, randomAlbumsHubId];

  /// Rows whose length is decided by the data rather than by [limit], so
  /// reporting "there is more" would be a lie:
  ///
  /// - a shuffle's "see more" would only reshuffle;
  /// - the play log is *everything* the server has, so a full-looking row is
  ///   the whole history, not the first page of it.
  static const Set<String> _unpageableHubIds = {randomAlbumsHubId, recentlyPlayedHubId};

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) => _buildHubs(limit);

  /// Identical to [fetchGlobalHubs]: there is only one library, so a
  /// library-scoped row and a global one are the same row. [libraryName] is not
  /// baked into the titles for that reason — `Recently Added in <server>` would
  /// only restate the server the row is already grouped under.
  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) => _buildHubs(limit);

  Future<List<MediaHub>> _buildHubs(int limit) async {
    // Issued together: independent reads, and the home screen should not pay
    // for them serially.
    final rows = await Future.wait([for (final id in hubIds) _hubItems(id, limit: limit)]);
    final hubs = <MediaHub>[];
    for (var i = 0; i < hubIds.length; i++) {
      final items = rows[i];
      // An empty row is dropped rather than rendered as a titled blank strip —
      // a server with no favourites should show no Favourites row at all.
      if (items.isEmpty) continue;
      hubs.add(_hub(hubIds[i], items, limit: limit));
    }
    return hubs;
  }

  MediaHub _hub(String hubId, List<MediaItem> items, {required int limit}) {
    return MediaHub(
      id: hubId,
      identifier: hubId,
      title: _hubTitle(hubId),
      type: hubId == favoritesHubId || hubId == recentlyPlayedHubId ? 'mixed' : MediaKind.album.id,
      items: items,
      size: items.length,
      more: !_unpageableHubIds.contains(hubId) && items.length >= limit,
      libraryId: musicAssistantLibraryId,
      serverId: serverId,
      serverName: serverName,
    );
  }

  static String _hubTitle(String hubId) => switch (hubId) {
    recentlyPlayedHubId => t.discover.recentlyPlayed,
    recentlyAddedHubId => t.discover.recentlyAdded,
    favoritesHubId => t.libraries.filterCategories.favorites,
    _ => t.discover.randomAlbums,
  };

  Future<List<MediaItem>> _hubItems(String hubId, {required int limit, int offset = 0}) async {
    switch (hubId) {
      case recentlyPlayedHubId:
        // No offset: the command has none, and the play log is short enough
        // that everything it holds is already on the row.
        return offset > 0 ? const [] : mapItems(await guard(() => music.getRecentlyPlayed(limit: limit)));
      case recentlyAddedHubId:
        return mapItems(
          await guard(
            () => music.getPage(MaLibraryType.albums, limit: limit, offset: offset, orderBy: MaOrder.newestFirst),
          ),
        );
      case randomAlbumsHubId:
        return mapItems(await guard(() => music.getPage(MaLibraryType.albums, limit: limit, orderBy: MaOrder.random)));
      case favoritesHubId:
        return _favorites(limit: limit, offset: offset);
      default:
        return const [];
    }
  }

  /// Favourite albums followed by favourite tracks, as one row.
  ///
  /// Two reads rather than one because the server has no cross-type favourites
  /// query. They are combined instead of split into two rows so a user with a
  /// handful of starred items sees one populated row rather than two thin ones.
  Future<List<MediaItem>> _favorites({required int limit, int offset = 0}) async {
    final albums = await guard(() => music.getPage(MaLibraryType.albums, limit: offset + limit, favorite: true));
    final tracks = offset + limit > albums.length
        ? await guard(() => music.getPage(MaLibraryType.tracks, limit: offset + limit - albums.length, favorite: true))
        : const <MaItem>[];
    return mapItems([...albums, ...tracks].skip(offset).take(limit));
  }

  /// Music Assistant reports no per-item playback position, so nothing is ever
  /// "in progress". Empty rather than an error: this is polled for every
  /// connected server on the home screen.
  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) async =>
      const [];

  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) =>
      _hubItems(hubId, limit: limit ?? MusicAssistantLibrary.defaultPageSize);

  /// Only "Recently added" pages for real — it is an ordinary ordered library
  /// read, so an offset means what it says and the total comes from
  /// `music/albums/count`. Favourites has no server-side total, paging a
  /// shuffle would repeat and skip rows, and the play log has no offset
  /// argument at all, so the rest return a single page.
  @override
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(
    String hubId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    abort?.throwIfAborted();
    final offset = start ?? 0;
    final limit = size ?? MusicAssistantLibrary.defaultPageSize;
    final items = await _hubItems(hubId, limit: limit, offset: hubId == randomAlbumsHubId ? 0 : offset);
    abort?.throwIfAborted();
    final total = hubId == recentlyAddedHubId
        ? await guard(() => music.getCount(MaLibraryType.albums))
        : fallbackPageTotal(offset: offset, itemCount: items.length, requestedSize: limit);
    return LibraryPage(items: items, totalCount: total, offset: offset);
  }
}
