part of '../../jellyfin_client.dart';

mixin _JellyfinWatchStateMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  FailoverHttpClient get _http;

  @override
  Future<void> markWatched(MediaItem item) async {
    final response = await _http.post(
      '/UserPlayedItems/${_segment(item.id)}',
      queryParameters: {'userId': connection.userId},
    );
    throwIfHttpError(response);
  }

  @override
  Future<void> markUnwatched(MediaItem item) async {
    final response = await _http.delete(
      '/UserPlayedItems/${_segment(item.id)}',
      queryParameters: {'userId': connection.userId},
    );
    throwIfHttpError(response);
  }

  @override
  Future<void> removeFromContinueWatching(MediaItem item) async {
    throw UnsupportedError('Jellyfin does not support removing items from Continue Watching.');
  }

  @override
  Future<void> rate(MediaItem item, double rating) async {
    // Lossy mapping — Jellyfin only stores a binary like/dislike. Treat
    // a negative input as "clear the rating" (DELETE), >= 6/10 as a like
    // (POST Likes=true), and the rest as a dislike (POST Likes=false).
    // No longer reachable from the rate sheet, which uses [setFavorite]
    // for Jellyfin instead; kept as transport for the abstract member.
    final response = rating < 0
        ? await _http.delete('/UserItems/${_segment(item.id)}/Rating', queryParameters: {'userId': connection.userId})
        : await _http.post(
            '/UserItems/${_segment(item.id)}/Rating',
            queryParameters: {'userId': connection.userId, 'Likes': (rating >= 6.0).toString()},
          );
    throwIfHttpError(response);
  }

  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) => _setItemFavorite(item.id, isFavorite);

  /// Toggle the per-user `IsFavorite` flag for [itemId]. Backs [setFavorite]
  /// and the live-TV favorite-channel adapter; works on any Jellyfin item.
  Future<void> _setItemFavorite(String itemId, bool isFavorite) async {
    final path = '/UserFavoriteItems/${_segment(itemId)}';
    final response = isFavorite
        ? await _http.post(path, queryParameters: {'userId': connection.userId})
        : await _http.delete(path, queryParameters: {'userId': connection.userId});
    throwIfHttpError(response);
  }
}
