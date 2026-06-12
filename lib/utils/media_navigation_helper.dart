import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../screens/collection_detail_screen.dart';
import '../screens/main_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/playlist/playlist_detail_screen.dart';
import '../services/settings_service.dart';
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

class MediaDetailNavigationTarget {
  final MediaItem metadata;
  final int? initialSeasonIndex;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const MediaDetailNavigationTarget({
    required this.metadata,
    this.initialSeasonIndex,
    this.initialSeasonId,
    this.initialEpisodeId,
  });
}

MediaDetailNavigationTarget mediaDetailNavigationTargetFor(MediaItem item, {MediaItem? metadataOverride}) {
  if (item.isEpisode && item.grandparentId != null) {
    return MediaDetailNavigationTarget(
      metadata:
          metadataOverride ??
          MediaItem(
            id: item.grandparentId!,
            backend: item.backend,
            kind: MediaKind.show,
            title: item.grandparentTitle ?? item.displayTitle,
            thumbPath: item.grandparentThumbPath,
            artPath: item.grandparentArtPath,
            libraryId: item.libraryId,
            libraryTitle: item.libraryTitle,
            serverId: item.serverId,
            serverName: item.serverName,
          ),
      initialSeasonIndex: item.parentIndex,
      initialSeasonId: item.parentId,
      initialEpisodeId: item.id,
    );
  }

  if (item.isEpisode && item.parentId != null) {
    return MediaDetailNavigationTarget(
      metadata:
          metadataOverride ??
          MediaItem(
            id: item.parentId!,
            backend: item.backend,
            kind: MediaKind.season,
            title: item.parentTitle ?? t.common.seasonNumber(number: item.parentIndex ?? ''),
            index: item.parentIndex,
            thumbPath: item.parentThumbPath,
            parentId: item.grandparentId,
            libraryId: item.libraryId,
            libraryTitle: item.libraryTitle,
            serverId: item.serverId,
            serverName: item.serverName,
          ),
      initialEpisodeId: item.id,
    );
  }

  if (item.isSeason && item.parentId != null) {
    return MediaDetailNavigationTarget(
      metadata:
          metadataOverride ??
          MediaItem(
            id: item.parentId!,
            backend: item.backend,
            kind: MediaKind.show,
            title: item.grandparentTitle ?? item.parentTitle ?? item.displayTitle,
            thumbPath: item.grandparentThumbPath ?? item.parentThumbPath,
            artPath: item.grandparentArtPath,
            libraryId: item.libraryId,
            libraryTitle: item.libraryTitle,
            serverId: item.serverId,
            serverName: item.serverName,
          ),
      initialSeasonIndex: item.index,
      initialSeasonId: item.id,
    );
  }

  return MediaDetailNavigationTarget(metadata: metadataOverride ?? item);
}

/// Navigates to the appropriate screen based on the item type.
///
/// Accepts a [MediaItem] or a [MediaPlaylist] (typed as [Object] because Dart
/// has no nominal union type).
///
/// For episodes, starts playback directly via video player unless [playDirectly]
/// is paired with the Continue Watching details setting.
/// For movies, starts playback directly if [playDirectly] is true and the
/// Continue Watching details setting is disabled; otherwise navigates to media
/// detail screen.
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
/// Set [playDirectly] to true for Continue Watching activation; the user's
/// Continue Watching action setting decides whether resumable movies/episodes
/// play immediately or open details first.
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
  final shouldOpenContinueWatchingDetails =
      playDirectly &&
      (SettingsService.instanceOrNull?.read(SettingsService.continueWatchingAction) ?? ContinueWatchingAction.play) ==
          ContinueWatchingAction.details;

  // Handle library section items (shared whole-library entries) — Plex-only;
  // [PlexLibrarySection.isLibrarySection] reads the stashed `key` from `raw`.
  if (mi.isLibrarySection) {
    final sectionKey = mi.librarySectionKey;
    if (sectionKey != null && mi.serverId != null) {
      final libraryGlobalKey = buildGlobalKey(ServerId(mi.serverId!), sectionKey);
      MainScreenFocusScope.of(context, listen: false)?.selectLibrary?.call(libraryGlobalKey);
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
      if (shouldOpenContinueWatchingDetails && mi.kind == MediaKind.episode) {
        return navigateToMediaItemDetails(context, mi, onRefresh: onRefresh, isOffline: isOffline);
      }
      final result = await navigateToVideoPlayer(context, metadata: mi, isOffline: isOffline);
      if (result == true && context.mounted) {
        onRefresh?.call(mi.id);
      }
      return MediaNavigationResult.navigated;

    case MediaKind.movie:
      if (playDirectly && !shouldOpenContinueWatchingDetails) {
        final result = await navigateToVideoPlayer(context, metadata: mi, isOffline: isOffline);
        if (result == true && context.mounted) {
          onRefresh?.call(mi.id);
        }
        return MediaNavigationResult.navigated;
      }
      return navigateToMediaItemDetails(context, mi, isOffline: isOffline, onRefresh: onRefresh);

    case MediaKind.season:
      return navigateToMediaItemDetails(context, mi, isOffline: isOffline, onRefresh: onRefresh);

    default:
      return navigateToMediaItemDetails(context, mi, isOffline: isOffline, onRefresh: onRefresh);
  }
}

Future<MediaNavigationResult> navigateToMediaItemDetails(
  BuildContext context,
  MediaItem mi, {
  bool isOffline = false,
  void Function(String)? onRefresh,
  MediaItem? metadataOverride,
}) async {
  final target = mediaDetailNavigationTargetFor(mi, metadataOverride: metadataOverride);
  final result = await Navigator.push<bool>(
    context,
    mediaDetailRoute(
      metadata: target.metadata,
      isOffline: isOffline,
      initialSeasonIndex: target.initialSeasonIndex,
      initialSeasonId: target.initialSeasonId,
      initialEpisodeId: target.initialEpisodeId,
    ),
  );
  if (result == true && context.mounted) {
    onRefresh?.call(mi.id);
  }
  return MediaNavigationResult.navigated;
}
