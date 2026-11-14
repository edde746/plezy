import 'music_assistant_api.dart';
import 'music_assistant_models.dart';

/// Read-only repository over the `music/*` commands.
///
/// Stateless: it holds no page cache of its own so several screens can share
/// one instance without fighting over invalidation. Memoising and merging is
/// the caller's job — `MusicAssistantClient` keeps the short-lived count, `#`
/// block and child-list memos, and `PaginatedItemLoader` owns the sparse map
/// that has to survive offsets shifting underneath it during a scan.
class MusicAssistantLibrary {
  /// The server silently truncates a `library_items` request with no `limit` at
  /// 500 items no matter how large the library is, so every request here sends
  /// an explicit limit. 500 is also the point past which the truncation would
  /// have bitten, which makes it a safe default page size.
  static const int defaultPageSize = 500;

  static const int defaultSearchLimit = 50;

  final MusicAssistantApi _client;

  const MusicAssistantLibrary(this._client);

  /// Total number of items of [type] currently in the library.
  ///
  /// Worth re-reading between pages while a scan is running: this library grew
  /// 77% in 45 minutes during protocol testing.
  Future<int> getCount(MaLibraryType type) async {
    final result = await _client.sendCommand('music/${type.segment}/count');
    if (result is int) return result;
    if (result is num) return result.toInt();
    return 0;
  }

  /// One page of [type], in server order.
  ///
  /// Do not re-sort the result: the server orders by `sort_name`, which
  /// disagrees with `name` often enough (`The 100 Greatest Hits of Ella
  /// Fitzgerald` sorts under `1`) that client-side sorting by name makes rows
  /// jump as later pages land.
  /// [orderBy] is passed through verbatim and is **not validated by the
  /// server** — an unknown value returns 200 with the default ordering. Use
  /// [MaOrder] rather than a literal; in particular the descending form is a
  /// `_desc` suffix, and the space-separated `"timestamp_added DESC"` is
  /// accepted and then quietly ordered ascending.
  ///
  /// [favorite] filters to (or away from) items the user starred. `count` does
  /// not honour the same argument, so a favourites list has no server total.
  Future<List<MaItem>> getPage(
    MaLibraryType type, {
    int limit = defaultPageSize,
    int offset = 0,
    String? orderBy,
    bool? favorite,
  }) async {
    final result = await _client.sendCommand(
      'music/${type.segment}/library_items',
      args: {'limit': limit, 'offset': offset, 'order_by': ?orderBy, 'favorite': ?favorite},
    );
    return _itemsFromResult(result);
  }

  /// What was actually played, most recent first.
  ///
  /// A dedicated command rather than `library_items` with
  /// `order_by: last_played_desc`, and the difference matters. Measured on the
  /// reference server: of 33,369 albums exactly **10** carry any play data at
  /// all, and past those `play_count_desc` and `last_played_desc` return
  /// byte-identical lists — the remaining 33,359 tie at zero and fall back to
  /// insertion order. An ordered `library_items` row therefore shows ten real
  /// answers followed by ten arbitrary albums, with nothing to tell them apart.
  /// This command returns *only* rows that exist in the play log, so it is
  /// short when the history is short and never pads.
  ///
  /// [types] excludes `playlist`, `radio`, `podcast` and `audiobook`: the first
  /// has no square card silhouette and the rest have no neutral kind at all, so
  /// they would render as unknown items rather than music.
  ///
  /// The rows are **abbreviated** — name, uri, media type and a single `image`,
  /// with no `artists` and no `album`. They are deliberately not re-fetched
  /// through `music/item_by_uri` to fill those in: that command was measured
  /// hanging indefinitely (>25s, reproducibly, for `library://track/371883`
  /// and `library://album/923` on the reference server) while answering in
  /// ~22ms for its neighbours, so a row that fanned out over it would hang the
  /// whole home screen for the sake of a subtitle.
  Future<List<MaItem>> getRecentlyPlayed({
    int limit = 20,
    List<MaLibraryType> types = const [MaLibraryType.artists, MaLibraryType.albums, MaLibraryType.tracks],
  }) async {
    final result = await _client.sendCommand(
      'music/recently_played_items',
      args: {
        'limit': limit,
        'media_types': [for (final type in types) type.mediaType],
      },
    );
    return _itemsFromResult(result);
  }

  /// Searches the library.
  ///
  /// [libraryOnly] defaults to true and should stay that way: without it the
  /// server queries every configured provider live, which measured 8.42s for
  /// `love` against 0.09s with it. Everything in a self-hosted collection is
  /// already indexed, so the live query buys nothing.
  Future<MaSearchResults> search(
    String query, {
    List<MaLibraryType> types = MaLibraryType.values,
    int limit = defaultSearchLimit,
    bool libraryOnly = true,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const MaSearchResults();
    final result = await _client.sendCommand(
      'music/search',
      args: {
        'search_query': trimmed,
        'media_types': [for (final type in types) type.mediaType],
        'limit': limit,
        'library_only': libraryOnly,
      },
    );
    return MaSearchResults.fromJson(result);
  }

  Future<List<MaItem>> getAlbumTracks(MaItem album) => _children('music/albums/album_tracks', album);

  Future<List<MaItem>> getArtistAlbums(MaItem artist) => _children('music/artists/artist_albums', artist);

  Future<List<MaItem>> getArtistTracks(MaItem artist) => _children('music/artists/artist_tracks', artist);

  /// Every track of [playlist], in playlist order.
  ///
  /// Two server behaviours are handled here, both verified on 2.6.3:
  ///
  /// - The result arrives as chunked `partial` frames (500 items each) which
  ///   [MusicAssistantApi] reassembles, so this is the complete list rather
  ///   than a page. The command takes no `limit`/`offset` — a `page` argument
  ///   exists but returned the same first chunk for every value.
  /// - A playlist the server has not resolved yet answers with an empty list
  ///   and no error. `force_refresh: true` makes it resolve, so an empty first
  ///   answer is retried once that way. The two answers are indistinguishable,
  ///   so a genuinely empty playlist pays the extra round-trip too — bounded by
  ///   the caller's child-list memo, not by anything here. Without the retry,
  ///   every playlist looks empty until something else warms it.
  Future<List<MaItem>> getPlaylistTracks(MaItem playlist) async {
    final cached = await _children('music/playlists/playlist_tracks', playlist);
    if (cached.isNotEmpty) return cached;
    return _children('music/playlists/playlist_tracks', playlist, extraArgs: const {'force_refresh': true});
  }

  /// Stars or unstars the item at [uri].
  ///
  /// Takes the uri rather than an [MaItem] because that is all the command
  /// carries, and the caller holds a neutral `MediaItem` at that point.
  Future<void> setFavorite(String uri, {required bool favorite}) async {
    await _client.sendCommand(
      favorite ? 'music/favorites/add_item' : 'music/favorites/remove_item',
      args: {'item': uri},
    );
  }

  Future<List<MaItem>> _children(String command, MaItem parent, {Map<String, dynamic> extraArgs = const {}}) async {
    final result = await _client.sendCommand(
      command,
      // The parent's own `provider` is what the server wants here; for library
      // items that is the literal string `library`.
      args: {'item_id': parent.itemId, 'provider_instance_id_or_domain': parent.provider, ...extraArgs},
    );
    return _itemsFromResult(result);
  }

  /// 2.6.3 returns a bare array; other builds wrap it in `{"items": [...]}`.
  static List<MaItem> _itemsFromResult(Object? result) {
    if (result is List) return maItemsFromJson(result);
    if (result is Map<String, dynamic>) return maItemsFromJson(result['items']);
    return const [];
  }
}
