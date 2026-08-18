part of '../../jellyfin_client.dart';

mixin _JellyfinWatchStateMethods on _JellyfinClientInternals {
  /// Marking played normally zeroes `UserData.PlaybackPositionTicks` server-side,
  /// which is what drops the row from Continue Watching — membership on this API
  /// is derived from the position alone, never from `Played` (verified on
  /// Jellyfin 10.11.10). Relying on that side effect is not enough: a stale
  /// playback report replayed from the offline queue, another client, or a
  /// server-side plugin can leave `Played` set *and* a position behind, and the
  /// row is then pinned to Continue Watching forever (#1812).
  ///
  /// So assert the postcondition instead of assuming it, using the
  /// `UserItemDataDto` the mark already returns. The follow-up write costs a
  /// request only when the invariant is actually broken.
  ///
  /// Folders (series/season) report their own position as 0 while the server
  /// resets their children recursively, so nothing extra is owed here.
  @override
  Future<void> markWatched(MediaItem item) async {
    final response = await _http.post(paths.playedItem(item.id), queryParameters: {'userId': connection.userId});
    throwIfHttpError(response);

    final data = response.data;
    final positionMs = data is Map<String, dynamic> ? jellyfinTicksToMs(data['PlaybackPositionTicks']) : null;
    if (positionMs == null || positionMs <= 0) return;

    appLogger.d('JellyfinClient: ${item.id} stayed resumable after mark-played; clearing its resume position');
    await _clearResumePosition(item.id);
  }

  /// Drop [itemId]'s resume bookmark without touching its played flag.
  Future<void> _clearResumePosition(String itemId) async {
    final response = await _http.post(
      paths.userItemData(itemId),
      queryParameters: {'userId': connection.userId},
      body: {'PlaybackPositionTicks': 0},
    );
    throwIfHttpError(response);
  }

  @override
  Future<void> markUnwatched(MediaItem item) async {
    final response = await _http.delete(paths.playedItem(item.id), queryParameters: {'userId': connection.userId});
    throwIfHttpError(response);
  }

  /// Hide [item] from Continue Watching while keeping its resume position.
  ///
  /// Emby-only. `POST /Users/{uid}/Items/{id}/HideFromResume?Hide=true` drops
  /// the row from `/Users/{uid}/Items/Resume` — the one listing that honours
  /// the flag, and therefore the route every Emby playback shelf reads (see
  /// [MediaBrowserDialect.resumeReturnsOnlyStartedItems]) — while leaving
  /// `UserData.PlaybackPositionTicks` untouched. Hiding a zero-position Next Up
  /// row also removes its series' entry, and reporting new playback clears the
  /// flag, so a removed item returns once the user actually resumes it (all
  /// verified on Emby 4.9.5). Jellyfin 10.11 has no equivalent route, so it
  /// keeps throwing and [ServerCapabilities.continueWatchingRemoval] keeps the
  /// affordance hidden.
  @override
  Future<void> removeFromContinueWatching(MediaItem item) async {
    if (!dialect.supportsContinueWatchingRemoval) {
      throw UnsupportedError('${dialect.productName} does not support removing items from Continue Watching.');
    }
    final response = await _http.post(paths.hideFromResume(item.id), queryParameters: {'Hide': 'true'});
    throwIfHttpError(response);
  }

  @override
  Future<void> rate(MediaItem item, double rating) async {
    // Lossy mapping — the MediaBrowser API only stores a binary like/dislike.
    // Treat a negative input as "clear the rating" (DELETE), >= 6/10 as a like
    // (POST Likes=true), and the rest as a dislike (POST Likes=false).
    // No longer reachable from the rate sheet, which uses [setFavorite]
    // for MediaBrowser servers instead; kept as transport for the abstract member.
    final response = rating < 0
        ? await _http.delete(paths.itemRating(item.id), queryParameters: {'userId': connection.userId})
        : await _http.post(
            paths.itemRating(item.id),
            queryParameters: {'userId': connection.userId, 'Likes': (rating >= 6.0).toString()},
          );
    throwIfHttpError(response);
  }

  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) => _setItemFavorite(item.id, isFavorite);

  /// Toggle the per-user `IsFavorite` flag for [itemId]. Backs [setFavorite]
  /// and the live-TV favorite-channel adapter; works on either MediaBrowser dialect.
  Future<void> _setItemFavorite(String itemId, bool isFavorite) async {
    final path = paths.favoriteItem(itemId);
    final response = isFavorite
        ? await _http.post(path, queryParameters: {'userId': connection.userId})
        : await _http.delete(path, queryParameters: {'userId': connection.userId});
    throwIfHttpError(response);
  }
}
