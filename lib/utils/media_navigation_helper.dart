import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../screens/collection_detail_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../screens/playlist/playlist_detail_screen.dart';
import 'video_player_navigation.dart';

/// Result of media navigation indicating what action was taken
enum MediaNavigationResult {
  /// Navigation completed successfully
  navigated,

  /// Navigation completed, parent list should be refreshed (e.g., collection deleted)
  listRefreshNeeded,

  /// Item type not supported (e.g., music content)
  unsupported,
}

/// Navigates to the appropriate screen based on the item type.
///
/// For episodes, starts playback directly via video player.
/// For movies, starts playback directly if [playDirectly] is true, otherwise
/// navigates to media detail screen.
/// For seasons, navigates to season detail screen.
/// For playlists, navigates to playlist detail screen.
/// For collections, navigates to collection detail screen.
/// For other types (shows), navigates to media detail screen.
/// For music types (artist, album, track), returns [MediaNavigationResult.unsupported].
///
/// The [onRefresh] callback is invoked with the item's ratingKey after
/// returning from the detail screen, allowing the caller to refresh state.
///
/// Set [isOffline] to true for downloaded content without server access.
///
/// Set [playDirectly] to true to play movies immediately (e.g., from continue watching).
///
/// Returns a [MediaNavigationResult] indicating what action was taken:
/// - [MediaNavigationResult.navigated]: Navigation completed, item refresh handled
/// - [MediaNavigationResult.listRefreshNeeded]: Caller should refresh entire list
/// - [MediaNavigationResult.unsupported]: Item type not supported, caller should handle
Future<MediaNavigationResult> navigateToMediaItem(
  BuildContext context,
  dynamic item, {
  void Function(String)? onRefresh,
  bool isOffline = false,
  bool playDirectly = false,
}) async {
  // Handle playlists
  if (item is PlexPlaylist) {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlist: item)));
    return MediaNavigationResult.navigated;
  }

  final metadata = item as PlexMetadata;

  switch (metadata.mediaType) {
    case PlexMediaType.collection:
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => CollectionDetailScreen(collection: metadata)),
      );
      // If collection was deleted, signal that list refresh is needed
      if (result == true) {
        return MediaNavigationResult.listRefreshNeeded;
      }
      return MediaNavigationResult.navigated;

    case PlexMediaType.artist:
    case PlexMediaType.album:
    case PlexMediaType.track:
      // Music types not supported
      return MediaNavigationResult.unsupported;

    case PlexMediaType.clip:
    case PlexMediaType.episode:
      // For episodes and clips (trailers/extras), start playback directly
      final result = await navigateToVideoPlayer(context, metadata: metadata, isOffline: isOffline);
      if (result == true) {
        onRefresh?.call(metadata.ratingKey);
      }
      return MediaNavigationResult.navigated;

    case PlexMediaType.movie:
      if (playDirectly) {
        // For movies in continue watching, start playback directly
        final result = await navigateToVideoPlayer(context, metadata: metadata, isOffline: isOffline);
        if (result == true) {
          onRefresh?.call(metadata.ratingKey);
        }
        return MediaNavigationResult.navigated;
      }
      // Fall through to default case for detail screen
      continue defaultCase;

    case PlexMediaType.season:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeasonDetailScreen(season: metadata, isOffline: isOffline),
        ),
      );
      onRefresh?.call(metadata.ratingKey);
      return MediaNavigationResult.navigated;

    defaultCase:
    default:
      // For all other types (shows, movies), show detail screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(metadata: metadata, isOffline: isOffline),
        ),
      );
      if (result == true) {
        onRefresh?.call(metadata.ratingKey);
      }
      return MediaNavigationResult.navigated;
  }
}
