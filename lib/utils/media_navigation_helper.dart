import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../screens/playlist/playlist_detail_screen.dart';
import 'video_player_navigation.dart';

/// Navigates to the appropriate screen based on the item type.
///
/// For episodes, starts playback directly via video player.
/// For seasons, navigates to season detail screen.
/// For playlists, navigates to playlist detail screen.
/// For other types (shows, movies), navigates to media detail screen.
///
/// The [onRefresh] callback is invoked with the item's ratingKey after
/// returning from the detail screen, allowing the caller to refresh state.
Future<void> navigateToMediaItem(
  BuildContext context,
  dynamic item, {
  void Function(String)? onRefresh,
}) async {
  // Handle playlists
  if (item is PlexPlaylist) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: item),
      ),
    );
    return;
  }

  final itemType = (item as PlexMetadata).type.toLowerCase();

  // For episodes, start playback directly
  if (itemType == 'episode') {
    final result = await navigateToVideoPlayer(context, metadata: item);
    if (result == true) {
      onRefresh?.call(item.ratingKey);
    }
  } else if (itemType == 'season') {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SeasonDetailScreen(season: item)),
    );
    onRefresh?.call(item.ratingKey);
  } else {
    // For all other types (shows, movies), show detail screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(metadata: item),
      ),
    );
    if (result == true) {
      onRefresh?.call(item.ratingKey);
    }
  }
}
