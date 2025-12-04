import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/collection_playlist_play_helper.dart';
import '../utils/keyboard_utils.dart';
import '../utils/library_refresh_notifier.dart';
import '../utils/video_player_navigation.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../widgets/file_info_bottom_sheet.dart';
import '../i18n/strings.g.dart';

/// Helper class to store menu action data
class _MenuAction {
  final String value;
  final IconData icon;
  final String label;

  _MenuAction({required this.value, required this.icon, required this.label});
}

/// A reusable wrapper widget that adds a context menu (long press / right click)
/// to any media item with appropriate actions based on the item type.
class MediaContextMenu extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh; // For refreshing list after deletion
  final VoidCallback? onTap;
  final Widget child;
  final bool isInContinueWatching;
  final String?
  collectionId; // The collection ID if displaying within a collection

  const MediaContextMenu({
    super.key,
    required this.item,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.onTap,
    required this.child,
    this.isInContinueWatching = false,
    this.collectionId,
  });

  @override
  State<MediaContextMenu> createState() => MediaContextMenuState();
}

class MediaContextMenuState extends State<MediaContextMenu> {
  Offset? _tapPosition;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  bool _openedFromKeyboard = false;

  /// Show the context menu programmatically.
  /// Used for keyboard/gamepad long-press activation.
  /// If [position] is null, the menu will appear at the center of this widget.
  void showContextMenu(BuildContext menuContext, {Offset? position}) {
    _openedFromKeyboard = true;
    if (position != null) {
      _tapPosition = position;
    } else {
      // Calculate center of the widget for keyboard activation
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final topLeft = renderBox.localToGlobal(Offset.zero);
        _tapPosition = Offset(
          topLeft.dx + size.width / 2,
          topLeft.dy + size.height / 2,
        );
      }
    }
    _showContextMenu(menuContext);
  }

  /// Get the correct PlexClient for this item's server
  PlexClient _getClientForItem() {
    String? serverId;

    // Get serverId from the item (could be PlexMetadata or PlexPlaylist)
    if (widget.item is PlexMetadata) {
      serverId = (widget.item as PlexMetadata).serverId;
    } else if (widget.item is PlexPlaylist) {
      serverId = (widget.item as PlexPlaylist).serverId;
    }

    // If serverId is null, fall back to first available server
    if (serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }
      serverId = multiServerProvider.onlineServerIds.first;
    }

    return context.getClientForServer(serverId);
  }

  void _showContextMenu(BuildContext context) async {
    final client = _getClientForItem();

    final isPlaylist = widget.item is PlexPlaylist;
    final metadata = isPlaylist ? null : widget.item as PlexMetadata;
    final itemType = isPlaylist ? 'playlist' : (metadata!.type.toLowerCase());
    final isCollection = itemType == 'collection';

    final isPartiallyWatched =
        !isPlaylist &&
        metadata!.viewedLeafCount != null &&
        metadata.leafCount != null &&
        metadata.viewedLeafCount! > 0 &&
        metadata.viewedLeafCount! < widget.item.leafCount!;

    // Check if we should use bottom sheet (on iOS and Android)
    final useBottomSheet = Platform.isIOS || Platform.isAndroid;

    // Build menu actions
    final menuActions = <_MenuAction>[];

    // Special actions for collections and playlists
    if (isCollection || isPlaylist) {
      // Play
      menuActions.add(
        _MenuAction(
          value: 'play',
          icon: Icons.play_arrow,
          label: t.discover.play,
        ),
      );

      // Shuffle
      menuActions.add(
        _MenuAction(
          value: 'shuffle',
          icon: Icons.shuffle,
          label: t.mediaMenu.shufflePlay,
        ),
      );

      // Delete
      menuActions.add(
        _MenuAction(
          value: 'delete',
          icon: Icons.delete,
          label: t.common.delete,
        ),
      );

      // Skip other menu items for collections and playlists
    } else {
      // Regular menu items for other types

      // Mark as Watched
      if (!metadata!.isWatched || isPartiallyWatched) {
        menuActions.add(
          _MenuAction(
            value: 'watch',
            icon: Icons.check_circle_outline,
            label: t.mediaMenu.markAsWatched,
          ),
        );
      }

      // Mark as Unwatched
      if (metadata.isWatched || isPartiallyWatched) {
        menuActions.add(
          _MenuAction(
            value: 'unwatch',
            icon: Icons.remove_circle_outline,
            label: t.mediaMenu.markAsUnwatched,
          ),
        );
      }

      // Remove from Continue Watching (only in continue watching section)
      if (widget.isInContinueWatching) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_continue_watching',
            icon: Icons.close,
            label: t.mediaMenu.removeFromContinueWatching,
          ),
        );
      }

      // Remove from Collection (only when viewing items within a collection)
      if (widget.collectionId != null) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_collection',
            icon: Icons.delete_outline,
            label: t.collections.removeFromCollection,
          ),
        );
      }

      // Go to Series (for episodes and seasons)
      if ((itemType == 'episode' || itemType == 'season') &&
          metadata.grandparentTitle != null) {
        menuActions.add(
          _MenuAction(
            value: 'series',
            icon: Icons.tv,
            label: t.mediaMenu.goToSeries,
          ),
        );
      }

      // Go to Season (for episodes)
      if (itemType == 'episode' && metadata.parentTitle != null) {
        menuActions.add(
          _MenuAction(
            value: 'season',
            icon: Icons.playlist_play,
            label: t.mediaMenu.goToSeason,
          ),
        );
      }

      // Shuffle Play (for shows and seasons)
      if (itemType == 'show' || itemType == 'season') {
        menuActions.add(
          _MenuAction(
            value: 'shuffle_play',
            icon: Icons.shuffle,
            label: t.mediaMenu.shufflePlay,
          ),
        );
      }

      // File Info (for episodes and movies)
      if (itemType == 'episode' || itemType == 'movie') {
        menuActions.add(
          _MenuAction(
            value: 'fileinfo',
            icon: Icons.info_outline,
            label: t.mediaMenu.fileInfo,
          ),
        );
      }

      // Add to... (for episodes, movies, shows, and seasons)
      if (itemType == 'episode' ||
          itemType == 'movie' ||
          itemType == 'show' ||
          itemType == 'season') {
        menuActions.add(
          _MenuAction(value: 'add_to', icon: Icons.add, label: t.common.addTo),
        );
      }
    } // End of regular menu items else block

    String? selected;

    final openedFromKeyboard = _openedFromKeyboard;
    _openedFromKeyboard = false;

    if (useBottomSheet) {
      // Show bottom sheet on mobile
      selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => _FocusableContextMenuSheet(
          title: widget.item.title,
          actions: menuActions,
          focusFirstItem: openedFromKeyboard,
        ),
      );
    } else {
      // Show custom focusable popup menu on larger screens
      // Use stored tap position or fallback to widget position
      final RenderBox? overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;

      Offset position;
      if (_tapPosition != null) {
        position = _tapPosition!;
      } else {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      }

      selected = await showDialog<String>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (dialogContext) => _FocusablePopupMenu(
          actions: menuActions,
          position: position,
          focusFirstItem: openedFromKeyboard,
        ),
      );
    }

    if (!context.mounted) return;

    switch (selected) {
      case 'watch':
        await _executeAction(
          context,
          () => client.markAsWatched(metadata!.ratingKey),
          t.messages.markedAsWatched,
        );
        break;

      case 'unwatch':
        await _executeAction(
          context,
          () => client.markAsUnwatched(metadata!.ratingKey),
          t.messages.markedAsUnwatched,
        );
        break;

      case 'remove_from_continue_watching':
        // Remove from Continue Watching without affecting watch status or progress
        // This preserves the progression for partially watched items
        // and doesn't mark unwatched next episodes as watched
        try {
          await client.removeFromOnDeck(metadata!.ratingKey);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.messages.removedFromContinueWatching)),
            );
            // Use specific callback if provided, otherwise fallback to onRefresh
            if (widget.onRemoveFromContinueWatching != null) {
              widget.onRemoveFromContinueWatching!();
            } else {
              widget.onRefresh?.call(metadata.ratingKey);
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.messages.errorLoading(error: e.toString())),
              ),
            );
          }
        }
        break;

      case 'remove_from_collection':
        await _handleRemoveFromCollection(context, metadata!);
        break;

      case 'series':
        await _navigateToRelated(
          context,
          metadata!.grandparentRatingKey,
          (metadata) => MediaDetailScreen(metadata: metadata),
          t.messages.errorLoadingSeries,
        );
        break;

      case 'season':
        await _navigateToRelated(
          context,
          metadata!.parentRatingKey,
          (metadata) => SeasonDetailScreen(
            season: metadata,
            focusFirstEpisode: _openedFromKeyboard,
          ),
          t.messages.errorLoadingSeason,
        );
        break;

      case 'fileinfo':
        await _showFileInfo(context);
        break;

      case 'add_to':
        await _showAddToSubmenu(context);
        break;

      case 'shuffle_play':
        await _handleShufflePlayWithQueue(context);
        break;

      case 'play':
        await _handlePlay(context, isCollection, isPlaylist);
        break;

      case 'shuffle':
        await _handleShuffle(context, isCollection, isPlaylist);
        break;

      case 'delete':
        await _handleDelete(context, isCollection, isPlaylist);
        break;
    }
  }

  /// Execute an action with error handling and refresh
  Future<void> _executeAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
    }
  }

  /// Navigate to a related item (series or season)
  Future<void> _navigateToRelated(
    BuildContext context,
    String? ratingKey,
    Widget Function(PlexMetadata) screenBuilder,
    String errorPrefix,
  ) async {
    if (ratingKey == null) return;

    final client = _getClientForItem();

    try {
      final metadata = await client.getMetadata(ratingKey);
      if (metadata != null && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenBuilder(metadata)),
        );
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$errorPrefix: $e')));
      }
    }
  }

  /// Show file info bottom sheet
  Future<void> _showFileInfo(BuildContext context) async {
    final client = _getClientForItem();

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Fetch file info
      final metadata = widget.item as PlexMetadata;
      final fileInfo = await client.getFileInfo(metadata.ratingKey);

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (fileInfo != null && context.mounted) {
        // Show file info bottom sheet
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              FileInfoBottomSheet(fileInfo: fileInfo, title: metadata.title),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.fileInfoNotAvailable)),
        );
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.messages.errorLoadingFileInfo(error: e.toString())),
          ),
        );
      }
    }
  }

  /// Handle shuffle play using play queues
  Future<void> _handleShufflePlayWithQueue(BuildContext context) async {
    final client = _getClientForItem();

    final metadata = widget.item as PlexMetadata;
    final playbackState = context.read<PlaybackStateProvider>();
    final itemType = metadata.type.toLowerCase();

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Determine the rating key for the play queue
      String showRatingKey;
      if (itemType == 'show') {
        showRatingKey = metadata.ratingKey;
      } else if (itemType == 'season') {
        // For seasons, we need the show's rating key
        // The season's parentRatingKey should point to the show
        if (metadata.parentRatingKey == null) {
          throw Exception('Season is missing parentRatingKey');
        }
        showRatingKey = metadata.parentRatingKey!;
      } else {
        throw Exception('Shuffle play only works for shows and seasons');
      }

      // Create a shuffled play queue for the show
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 1,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (playQueue == null ||
          playQueue.items == null ||
          playQueue.items!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.messages.noEpisodesFound)));
        }
        return;
      }

      // Initialize playback state with the play queue
      await playbackState.setPlaybackFromPlayQueue(
        playQueue,
        showRatingKey,
        serverId: metadata.serverId,
        serverName: metadata.serverName,
      );

      // Set the client for the playback state provider
      playbackState.setClient(client);

      // Navigate to the first episode in the shuffled queue
      final firstEpisode = playQueue.items!.first.copyWith(
        serverId: metadata.serverId,
        serverName: metadata.serverName,
      );

      if (context.mounted) {
        await navigateToVideoPlayer(context, metadata: firstEpisode);
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
    }
  }

  /// Show submenu for Add to... (Playlist or Collection)
  Future<void> _showAddToSubmenu(BuildContext context) async {
    final useBottomSheet = Platform.isIOS || Platform.isAndroid;

    final submenuActions = [
      _MenuAction(
        value: 'playlist',
        icon: Icons.playlist_play,
        label: t.playlists.playlist,
      ),
      _MenuAction(
        value: 'collection',
        icon: Icons.collections,
        label: t.collections.collection,
      ),
    ];

    String? selected;

    if (useBottomSheet) {
      // Show bottom sheet on mobile
      selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t.common.addTo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...submenuActions.map((action) {
                return ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  onTap: () => Navigator.pop(context, action.value),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } else {
      // Show popup menu on desktop
      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          _tapPosition?.dx ?? 0,
          _tapPosition?.dy ?? 0,
          _tapPosition?.dx ?? 0,
          _tapPosition?.dy ?? 0,
        ),
        items: submenuActions.map((action) {
          return PopupMenuItem<String>(
            value: action.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, size: 20),
                const SizedBox(width: 12),
                Text(action.label),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Handle the submenu selection
    if (selected == 'playlist' && context.mounted) {
      await _showAddToPlaylistDialog(context);
    } else if (selected == 'collection' && context.mounted) {
      await _showAddToCollectionDialog(context);
    }
  }

  /// Show dialog to select playlist and add item
  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final client = _getClientForItem();

    try {
      final metadata = widget.item as PlexMetadata;
      final itemType = metadata.type.toLowerCase();

      // Load playlists
      final playlists = await client.getPlaylists(playlistType: 'video');

      if (!context.mounted) return;

      // Show dialog to select playlist or create new
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _PlaylistSelectionDialog(playlists: playlists),
      );

      if (result == null || !context.mounted) return;

      // Build URI for the item (works for all types: movies, episodes, seasons, shows)
      // For seasons/shows, the Plex API should automatically expand to include all episodes
      final itemUri = await client.buildMetadataUri(metadata.ratingKey);
      appLogger.d('Built URI for $itemType: $itemUri');

      if (!context.mounted) return;

      if (result == '_create_new') {
        // Create new playlist flow
        final playlistName = await showDialog<String>(
          context: context,
          builder: (context) => _CreatePlaylistDialog(),
        );

        if (playlistName == null || playlistName.isEmpty || !context.mounted) {
          return;
        }

        // Create playlist with the item(s)
        appLogger.d(
          'Creating playlist "$playlistName" with URI length: ${itemUri.length}',
        );
        final newPlaylist = await client.createPlaylist(
          title: playlistName,
          uri: itemUri,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (newPlaylist != null) {
            appLogger.d('Successfully created playlist: ${newPlaylist.title}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.created)));
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
          } else {
            appLogger.e('Failed to create playlist - API returned null');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.errorCreating)));
          }
        }
      } else {
        // Add to existing playlist
        appLogger.d('Adding to playlist $result with URI: $itemUri');
        final success = await client.addToPlaylist(
          playlistId: result,
          uri: itemUri,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to playlist $result');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.itemAdded)));
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
          } else {
            appLogger.e(
              'Failed to add item(s) to playlist $result - API returned false',
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.errorAdding)));
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Error in add to playlist flow',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.playlists.errorLoading}: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Show dialog to select collection and add item
  Future<void> _showAddToCollectionDialog(BuildContext context) async {
    final client = _getClientForItem();

    try {
      final metadata = widget.item as PlexMetadata;
      final itemType = metadata.type.toLowerCase();

      // Get the library section ID from the item
      // First try from the metadata itself
      int? sectionId = metadata.librarySectionID;
      appLogger.d('Attempting to get section ID for ${metadata.title}');
      appLogger.d('  - librarySectionID: $sectionId');
      appLogger.d('  - key: ${metadata.key}');

      // If not available, fetch the full metadata which should include the section ID
      if (sectionId == null) {
        try {
          appLogger.d('  - Fetching full metadata for: ${metadata.ratingKey}');
          final fullMetadata = await client.getMetadata(metadata.ratingKey);
          if (fullMetadata != null) {
            sectionId = fullMetadata.librarySectionID;
            appLogger.d('  - Section ID from full metadata: $sectionId');
          }
        } catch (e) {
          appLogger.w('Failed to get full metadata for section ID: $e');
        }
      }

      // If still not found, try to extract from the key field
      if (sectionId == null) {
        final keyMatch = RegExp(
          r'/library/sections/(\d+)',
        ).firstMatch(metadata.key);
        if (keyMatch != null) {
          sectionId = int.tryParse(keyMatch.group(1)!);
          appLogger.d('  - Extracted from key: $sectionId');
        }
      }

      // Last resort: try to get it from the item's parent (for episodes/seasons)
      if (sectionId == null && metadata.grandparentRatingKey != null) {
        try {
          appLogger.d(
            '  - Trying to get from parent: ${metadata.grandparentRatingKey}',
          );
          final parentMeta = await client.getMetadata(
            metadata.grandparentRatingKey!,
          );
          sectionId = parentMeta?.librarySectionID;
          appLogger.d('  - Parent sectionId: $sectionId');
        } catch (e) {
          appLogger.w('Failed to get parent metadata for section ID: $e');
        }
      }

      appLogger.d('  - Final sectionId: $sectionId');

      if (sectionId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to determine library section for this item',
              ),
            ),
          );
        }
        return;
      }

      // Load collections for this library section
      final collections = await client.getLibraryCollections(
        sectionId.toString(),
      );

      if (!context.mounted) return;

      // Show dialog to select collection or create new
      final result = await showDialog<String>(
        context: context,
        builder: (context) =>
            _CollectionSelectionDialog(collections: collections),
      );

      if (result == null || !context.mounted) return;

      // Build URI for the item
      final itemUri = await client.buildMetadataUri(metadata.ratingKey);
      appLogger.d('Built URI for $itemType: $itemUri');

      if (!context.mounted) return;

      if (result == '_create_new') {
        // Create new collection flow
        final collectionName = await showDialog<String>(
          context: context,
          builder: (context) => _CreateCollectionDialog(),
        );

        if (collectionName == null ||
            collectionName.isEmpty ||
            !context.mounted) {
          return;
        }

        // Create collection first (without items)
        // Determine the collection type based on the item type
        int? collectionType;
        switch (itemType) {
          case 'movie':
            collectionType = 1;
            break;
          case 'show':
            collectionType = 2;
            break;
          case 'season':
            collectionType = 3;
            break;
          case 'episode':
            collectionType = 4;
            break;
        }

        appLogger.d(
          'Creating collection "$collectionName" with type $collectionType',
        );
        final newCollectionId = await client.createCollection(
          sectionId: sectionId.toString(),
          title: collectionName,
          uri: '', // Empty for regular collections
          type: collectionType,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (newCollectionId != null) {
            appLogger.d(
              'Successfully created collection with ID: $newCollectionId',
            );

            // Now add the item to the newly created collection
            appLogger.d(
              'Adding item to new collection $newCollectionId with URI: $itemUri',
            );
            final addSuccess = await client.addToCollection(
              collectionId: newCollectionId,
              uri: itemUri,
            );

            if (!context.mounted) return;

            if (addSuccess) {
              appLogger.d('Successfully added item to new collection');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.collections.created)));
              // Trigger refresh of collections tab
              LibraryRefreshNotifier().notifyCollectionsChanged();
            } else {
              appLogger.e('Failed to add item to new collection');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.collections.errorAddingToCollection)),
              );
            }
          } else {
            appLogger.e('Failed to create collection - API returned null');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.collections.errorAddingToCollection)),
            );
          }
        }
      } else {
        // Add to existing collection
        appLogger.d('Adding to collection $result with URI: $itemUri');
        final success = await client.addToCollection(
          collectionId: result,
          uri: itemUri,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to collection $result');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.collections.addedToCollection)),
            );
            // Trigger refresh of collections tab
            LibraryRefreshNotifier().notifyCollectionsChanged();
          } else {
            appLogger.e(
              'Failed to add item(s) to collection $result - API returned false',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.collections.errorAddingToCollection)),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Error in add to collection flow',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.collections.errorAddingToCollection}: ${e.toString()}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handle remove from collection action
  Future<void> _handleRemoveFromCollection(
    BuildContext context,
    PlexMetadata metadata,
  ) async {
    final client = _getClientForItem();

    if (widget.collectionId == null) {
      appLogger.e('Cannot remove from collection: collectionId is null');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.collections.removeFromCollection),
        content: Text(
          t.collections.removeFromCollectionConfirm(title: metadata.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      appLogger.d(
        'Removing item ${metadata.ratingKey} from collection ${widget.collectionId}',
      );
      final success = await client.removeFromCollection(
        collectionId: widget.collectionId!,
        itemId: metadata.ratingKey,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.collections.removedFromCollection)),
          );
          // Trigger refresh of collections tab
          LibraryRefreshNotifier().notifyCollectionsChanged();
          // Trigger list refresh to remove the item from the view
          widget.onListRefresh?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.collections.removeFromCollectionFailed)),
          );
        }
      }
    } catch (e) {
      appLogger.e('Failed to remove from collection', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.collections.removeFromCollectionError(error: e.toString()),
            ),
          ),
        );
      }
    }
  }

  /// Handle play action for collections and playlists
  Future<void> _handlePlay(
    BuildContext context,
    bool isCollection,
    bool isPlaylist,
  ) async {
    final client = _getClientForItem();

    await playCollectionOrPlaylist(
      context: context,
      client: client,
      item: widget.item,
      shuffle: false,
    );
  }

  /// Handle shuffle action for collections and playlists
  Future<void> _handleShuffle(
    BuildContext context,
    bool isCollection,
    bool isPlaylist,
  ) async {
    final client = _getClientForItem();

    await playCollectionOrPlaylist(
      context: context,
      client: client,
      item: widget.item,
      shuffle: true,
    );
  }

  /// Handle delete action for collections and playlists
  Future<void> _handleDelete(
    BuildContext context,
    bool isCollection,
    bool isPlaylist,
  ) async {
    final client = _getClientForItem();

    final itemTitle = widget.item.title;
    final itemTypeLabel = isCollection
        ? t.collections.collection
        : t.playlists.playlist;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isCollection ? t.collections.deleteCollection : t.playlists.delete,
        ),
        content: Text(
          isCollection
              ? t.collections.deleteConfirm(title: itemTitle)
              : t.playlists.deleteMessage(name: itemTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      bool success = false;

      if (isCollection) {
        final metadata = widget.item as PlexMetadata;
        final sectionId = metadata.librarySectionID?.toString() ?? '0';
        success = await client.deleteCollection(sectionId, metadata.ratingKey);
      } else if (isPlaylist) {
        final playlist = widget.item as PlexPlaylist;
        success = await client.deletePlaylist(playlist.ratingKey);
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCollection ? t.collections.deleted : t.playlists.deleted,
              ),
            ),
          );
          // Trigger list refresh
          widget.onListRefresh?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCollection
                    ? t.collections.deleteFailed
                    : t.playlists.errorDeleting,
              ),
            ),
          );
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete $itemTypeLabel', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCollection
                  ? t.collections.deleteFailedWithError(error: e.toString())
                  : t.playlists.errorDeleting,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _storeTapPosition,
      onLongPress: () => _showContextMenu(context),
      onSecondaryTapDown: _storeTapPosition,
      onSecondaryTap: () => _showContextMenu(context),
      child: widget.child,
    );
  }
}

/// Dialog to select a playlist or create a new one
class _PlaylistSelectionDialog extends StatelessWidget {
  final List<PlexPlaylist> playlists;

  const _PlaylistSelectionDialog({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.playlists.selectPlaylist),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Create new playlist option (always shown first)
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(t.playlists.createNewPlaylist),
                onTap: () => Navigator.pop(context, '_create_new'),
              );
            }

            final playlist = playlists[index - 1];
            return ListTile(
              leading: playlist.smart
                  ? const Icon(Icons.auto_awesome)
                  : const Icon(Icons.playlist_play),
              title: Text(playlist.title),
              subtitle: playlist.leafCount != null
                  ? Text(
                      playlist.leafCount == 1
                          ? t.playlists.oneItem
                          : t.playlists.itemCount(count: playlist.leafCount!),
                    )
                  : null,
              onTap: playlist.smart
                  ? null // Disable smart playlists
                  : () => Navigator.pop(context, playlist.ratingKey),
              enabled: !playlist.smart,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}

/// Dialog to create a new playlist
class _CreatePlaylistDialog extends StatefulWidget {
  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.playlists.create),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: t.playlists.playlistName,
          hintText: t.playlists.enterPlaylistName,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.pop(context, value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text(t.common.save),
        ),
      ],
    );
  }
}

/// Dialog to select a collection or create a new one
class _CollectionSelectionDialog extends StatelessWidget {
  final List<PlexMetadata> collections;

  const _CollectionSelectionDialog({required this.collections});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.collections.selectCollection),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: collections.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Create new collection option (always shown first)
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(t.collections.createNewCollection),
                onTap: () => Navigator.pop(context, '_create_new'),
              );
            }

            final collection = collections[index - 1];
            return ListTile(
              leading: const Icon(Icons.collections),
              title: Text(collection.title),
              subtitle: collection.childCount != null
                  ? Text('${collection.childCount} items')
                  : null,
              onTap: () => Navigator.pop(context, collection.ratingKey),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}

/// Dialog to create a new collection
class _CreateCollectionDialog extends StatefulWidget {
  @override
  State<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<_CreateCollectionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.collections.createNewCollection),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: t.collections.collectionName,
          hintText: t.collections.enterCollectionName,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.pop(context, value);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text(t.common.save),
        ),
      ],
    );
  }
}

/// Focusable context menu sheet for keyboard/gamepad navigation (mobile)
class _FocusableContextMenuSheet extends StatefulWidget {
  final String title;
  final List<_MenuAction> actions;
  final bool focusFirstItem;

  const _FocusableContextMenuSheet({
    required this.title,
    required this.actions,
    this.focusFirstItem = false,
  });

  @override
  State<_FocusableContextMenuSheet> createState() =>
      _FocusableContextMenuSheetState();
}

class _FocusableContextMenuSheetState
    extends State<_FocusableContextMenuSheet> {
  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.actions.length,
      (index) => FocusNode(debugLabel: 'ContextMenuItem$index'),
    );

    if (widget.focusFirstItem && widget.actions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Close on back keys
    if (isBackKey(event.logicalKey)) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    // Navigate with arrow keys
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedIndex > 0) {
        _focusedIndex--;
        _focusNodes[_focusedIndex].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedIndex < widget.actions.length - 1) {
        _focusedIndex++;
        _focusNodes[_focusedIndex].requestFocus();
      }
      return KeyEventResult.handled;
    }

    // Select with Enter/Space
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      Navigator.pop(context, widget.actions[_focusedIndex].value);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...widget.actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              return Focus(
                focusNode: _focusNodes[index],
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    setState(() => _focusedIndex = index);
                  }
                },
                child: Builder(
                  builder: (context) {
                    final isFocused = Focus.of(context).hasFocus;
                    return ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.label),
                      onTap: () => Navigator.pop(context, action.value),
                      selected: isFocused,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Focusable popup menu for keyboard/gamepad navigation (desktop)
class _FocusablePopupMenu extends StatefulWidget {
  final List<_MenuAction> actions;
  final Offset position;
  final bool focusFirstItem;

  const _FocusablePopupMenu({
    required this.actions,
    required this.position,
    this.focusFirstItem = false,
  });

  @override
  State<_FocusablePopupMenu> createState() => _FocusablePopupMenuState();
}

class _FocusablePopupMenuState extends State<_FocusablePopupMenu> {
  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.actions.length,
      (index) => FocusNode(debugLabel: 'PopupMenuItem$index'),
    );

    if (widget.focusFirstItem && widget.actions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Close on back keys
    if (isBackKey(event.logicalKey)) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    // Navigate with arrow keys
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedIndex > 0) {
        _focusedIndex--;
        _focusNodes[_focusedIndex].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedIndex < widget.actions.length - 1) {
        _focusedIndex++;
        _focusNodes[_focusedIndex].requestFocus();
      }
      return KeyEventResult.handled;
    }

    // Select with Enter/Space
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      Navigator.pop(context, widget.actions[_focusedIndex].value);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 220.0;

    // Calculate menu position, keeping it on screen
    double left = widget.position.dx;
    double top = widget.position.dy;

    // Adjust if menu would go off right edge
    if (left + menuWidth > screenSize.width) {
      left = screenSize.width - menuWidth - 8;
    }

    // Estimate menu height and adjust if would go off bottom
    final estimatedHeight = widget.actions.length * 48.0 + 16;
    if (top + estimatedHeight > screenSize.height) {
      top = screenSize.height - estimatedHeight - 8;
    }

    return Stack(
      children: [
        // Barrier to close menu when clicking outside
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          left: left,
          top: top,
          child: Focus(
            autofocus: !widget.focusFirstItem,
            onKeyEvent: _handleKeyEvent,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: menuWidth,
                  maxWidth: menuWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return Focus(
                      focusNode: _focusNodes[index],
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          setState(() => _focusedIndex = index);
                        }
                      },
                      child: Builder(
                        builder: (context) {
                          final isFocused = Focus.of(context).hasFocus;
                          return InkWell(
                            onTap: () => Navigator.pop(context, action.value),
                            child: Container(
                              color: isFocused
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(action.icon, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(action.label)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
