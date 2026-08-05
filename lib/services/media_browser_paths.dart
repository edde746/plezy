import '../media/media_browser_dialect.dart';

/// Route builders for the endpoints where the Jellyfin and Emby dialects of the
/// MediaBrowser API diverge.
///
/// Jellyfin 10.9 renamed a batch of user-scoped routes to unprefixed forms
/// (`/Users/{uid}/PlayedItems/{id}` → `/UserPlayedItems/{id}`) and introduced
/// `/Users/Me`. Emby only ever shipped the user-scoped spellings and fails on
/// the new ones — `/Users/Me` returns 500 `Unrecognized Guid format` because
/// `Me` is bound as a user id, and the rest 404. Keeping every divergent route
/// here lets the client parts stay dialect-agnostic.
///
/// Routes that are identical on both dialects (`/Items`, `/Users/{uid}/Views`,
/// `/Users/{uid}/Items/{id}`, `/Users/{uid}/Items/Latest`, `/Shows/*`,
/// `/Sessions/Playing*`, `/Items/{id}/PlaybackInfo`, image and stream routes)
/// deliberately do not appear here.
class MediaBrowserPaths {
  const MediaBrowserPaths({required this.dialect, required this.userId});

  final MediaBrowserDialect dialect;
  final String userId;

  String get _user => '/Users/${Uri.encodeComponent(userId)}';

  static String _id(String itemId) => Uri.encodeComponent(itemId);

  /// The authenticated user's own DTO — health probe and user-preference read.
  String get currentUser => dialect.requiresUserScopedItemRoutes ? _user : '/Users/Me';

  /// Continue Watching / resumable items.
  String get resumeItems => dialect.requiresUserScopedItemRoutes ? '$_user/Items/Resume' : '/UserItems/Resume';

  /// Played flag write route (`POST` to mark, `DELETE` to unmark).
  String playedItem(String itemId) =>
      dialect.requiresUserScopedItemRoutes ? '$_user/PlayedItems/${_id(itemId)}' : '/UserPlayedItems/${_id(itemId)}';

  /// Favourite flag write route (`POST` to add, `DELETE` to remove).
  String favoriteItem(String itemId) => dialect.requiresUserScopedItemRoutes
      ? '$_user/FavoriteItems/${_id(itemId)}'
      : '/UserFavoriteItems/${_id(itemId)}';

  /// Thumbs-up/down write route (`POST ?Likes=`, `DELETE` to clear).
  String itemRating(String itemId) =>
      dialect.requiresUserScopedItemRoutes ? '$_user/Items/${_id(itemId)}/Rating' : '/UserItems/${_id(itemId)}/Rating';

  /// Trailers attached to a movie/series.
  String localTrailers(String itemId) => dialect.requiresUserScopedItemRoutes
      ? '$_user/Items/${_id(itemId)}/LocalTrailers'
      : '/Items/${_id(itemId)}/LocalTrailers';

  /// Extras/behind-the-scenes children.
  String specialFeatures(String itemId) => dialect.requiresUserScopedItemRoutes
      ? '$_user/Items/${_id(itemId)}/SpecialFeatures'
      : '/Items/${_id(itemId)}/SpecialFeatures';

  /// Hide an item from Continue Watching without touching its playback
  /// position (`?Hide=true` to hide, `?Hide=false` to restore).
  ///
  /// Emby-only: Jellyfin 10.11 has no equivalent under either spelling
  /// (measured 404 for both `/UserItems/{id}/HideFromResume` and the
  /// user-scoped form), which is why [ServerCapabilities.jellyfin] leaves
  /// `continueWatchingRemoval` false while [ServerCapabilities.emby] sets it.
  String hideFromResume(String itemId) => '$_user/Items/${_id(itemId)}/HideFromResume';
}
