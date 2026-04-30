import 'package:flutter/material.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../screens/collection_detail_screen.dart';
import '../screens/main_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/playlist/playlist_detail_screen.dart';
import '../utils/global_key_utils.dart';
import 'plex_library_section_helpers.dart';
import 'video_player_navigation.dart';

/// Result of media navigation indicating what action was taken
enum MediaNavigationResult {
  /// Navigation completed successfully
  navigated,

  /// Navigation completed, parent list should be refreshed (e.g., collection deleted)
  listRefreshNeeded,

  /// Item type not supported (e.g., music content)
  unsupported,

  /// Item is a library section — navigated to that library
  librarySelected,
}

/// Navigates to the appropriate screen based on the item type.
///
/// Accepts a [MediaItem] or a [MediaPlaylist] (typed as [Object] because Dart
/// has no nominal union type).
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
/// The [onRefresh] callback is invoked with the item's id after returning from
/// the detail screen, allowing the caller to refresh state.
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
  Object item, {
  void Function(String)? onRefresh,
  bool isOffline = false,
  bool playDirectly = false,
}) async {
  if (item is MediaPlaylist) {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlist: item)));
    return MediaNavigationResult.navigated;
  }

  if (item is! MediaItem) {
    return MediaNavigationResult.unsupported;
  }
  final mi = item;

  // Handle library section items (shared whole-library entries) — Plex-only;
  // [PlexLibrarySection.isLibrarySection] reads the stashed `key` from `raw`.
  if (mi.isLibrarySection) {
    final sectionKey = mi.librarySectionKey;
    if (sectionKey != null && mi.serverId != null) {
      final libraryGlobalKey = buildGlobalKey(mi.serverId!, sectionKey);
      MainScreenFocusScope.of(context)?.selectLibrary?.call(libraryGlobalKey);
      return MediaNavigationResult.librarySelected;
    }
    return MediaNavigationResult.unsupported;
  }

  switch (mi.kind) {
    case MediaKind.collection:
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => CollectionDetailScreen(collection: mi)),
      );
      // If collection was deleted, signal that list refresh is needed
      if (result == true) {
        return MediaNavigationResult.listRefreshNeeded;
      }
      return MediaNavigationResult.navigated;

    case MediaKind.artist:
    case MediaKind.album:
    case MediaKind.track:
      // Music types not supported
      return MediaNavigationResult.unsupported;

    case MediaKind.clip:
    case MediaKind.episode:
      // For episodes and clips (trailers/extras), start playback directly
      final result = await navigateToVideoPlayer(context, metadata: mi, isOffline: isOffline);
      if (result == true) {
        onRefresh?.call(mi.id);
      }
      return MediaNavigationResult.navigated;

    case MediaKind.movie:
      if (playDirectly) {
        // For movies in continue watching, start playback directly
        final result = await navigateToVideoPlayer(context, metadata: mi, isOffline: isOffline);
        if (result == true) {
          onRefresh?.call(mi.id);
        }
        return MediaNavigationResult.navigated;
      }
      return _showDetail(context, mi, isOffline, onRefresh);

    case MediaKind.season:
      // Navigate to the parent show with the season tab pre-selected
      if (mi.parentId != null) {
        final showStub = MediaItem(
          id: mi.parentId!,
          backend: mi.backend,
          kind: MediaKind.show,
          title: mi.grandparentTitle ?? mi.parentTitle ?? mi.displayTitle,
          thumbPath: mi.grandparentThumbPath ?? mi.parentThumbPath,
          artPath: mi.grandparentArtPath,
          serverId: mi.serverId,
          serverName: mi.serverName,
        );
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MediaDetailScreen(metadata: showStub, isOffline: isOffline, initialSeasonIndex: mi.index),
          ),
        );
        if (result == true) {
          onRefresh?.call(mi.id);
        }
        return MediaNavigationResult.navigated;
      }
      return _showDetail(context, mi, isOffline, onRefresh);

    default:
      return _showDetail(context, mi, isOffline, onRefresh);
  }
}

Future<MediaNavigationResult> _showDetail(
  BuildContext context,
  MediaItem mi,
  bool isOffline,
  void Function(String)? onRefresh,
) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => MediaDetailScreen(metadata: mi, isOffline: isOffline),
    ),
  );
  if (result == true) {
    onRefresh?.call(mi.id);
  }
  return MediaNavigationResult.navigated;
}
