import '../utils/platform_helper.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../services/plex_client.dart';
import '../services/play_queue_launcher.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/download_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/library_refresh_notifier.dart';
import '../utils/snackbar_helper.dart';
import '../utils/dialogs.dart';
import '../utils/focus_utils.dart';
import '../services/external_player_service.dart';
import '../focus/dpad_navigator.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../utils/smart_deletion_handler.dart';
import '../utils/deletion_notifier.dart';
import '../theme/mono_tokens.dart';
import '../widgets/file_info_bottom_sheet.dart';
import '../widgets/focusable_bottom_sheet.dart';
import '../widgets/focusable_list_tile.dart';
import '../i18n/strings.g.dart';

/// Helper class to store menu action data
class _MenuAction {
  final String value;
  final IconData icon;
  final String label;
  final Color? hoverColor;

  _MenuAction({required this.value, required this.icon, required this.label, this.hoverColor});
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
  final String? collectionId; // The collection ID if displaying within a collection

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
  bool _isContextMenuOpen = false;

  bool get isContextMenuOpen => _isContextMenuOpen;

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
        _tapPosition = Offset(topLeft.dx + size.width / 2, topLeft.dy + size.height / 2);
      }
    }
    _showContextMenu(menuContext);
  }

  /// Get the serverId from the item (PlexMetadata or PlexPlaylist)
  String? get _itemServerId {
    if (widget.item is PlexMetadata) return (widget.item as PlexMetadata).serverId;
    if (widget.item is PlexPlaylist) return (widget.item as PlexPlaylist).serverId;
    return null;
  }

  /// Get the correct PlexClient for this item's server
  PlexClient _getClientForItem() => context.getClientWithFallback(_itemServerId);

  void _handleTap() {
    if (_isContextMenuOpen) return;
    widget.onTap?.call();
  }

  void _showContextMenu(BuildContext context) async {
    if (_isContextMenuOpen) return;
    _isContextMenuOpen = true;

    // Capture the currently focused node for restoration after menu closes
    final previousFocus = FocusManager.instance.primaryFocus;
    bool didNavigate = false;

    final isPlaylist = widget.item is PlexPlaylist;
    final metadata = isPlaylist ? null : widget.item as PlexMetadata;
    final mediaType = isPlaylist ? null : metadata!.mediaType;
    final isCollection = mediaType == PlexMediaType.collection;

    final isPartiallyWatched =
        !isPlaylist &&
        metadata!.viewedLeafCount != null &&
        metadata.leafCount != null &&
        metadata.viewedLeafCount! > 0 &&
        metadata.viewedLeafCount! < widget.item.leafCount!;

    // Check if we should use bottom sheet (on iOS and Android)
    final useBottomSheet = AppPlatform.isIOS || AppPlatform.isAndroid;

    // Build menu actions
    final menuActions = <_MenuAction>[];

    // Special actions for collections and playlists
    if (isCollection || isPlaylist) {
      // Play
      menuActions.add(_MenuAction(value: 'play', icon: Symbols.play_arrow_rounded, label: t.common.play));

      // Shuffle
      menuActions.add(_MenuAction(value: 'shuffle', icon: Symbols.shuffle_rounded, label: t.mediaMenu.shufflePlay));

      // Delete
      menuActions.add(_MenuAction(value: 'delete', icon: Symbols.delete_rounded, label: t.common.delete));

      // Skip other menu items for collections and playlists
    } else {
      // Regular menu items for other types

      // Mark as Watched
      if (!metadata!.isWatched || isPartiallyWatched) {
        menuActions.add(
          _MenuAction(value: 'watch', icon: Symbols.check_circle_outline_rounded, label: t.mediaMenu.markAsWatched),
        );
      }

      // Mark as Unwatched
      if (metadata.isWatched || isPartiallyWatched) {
        menuActions.add(
          _MenuAction(
            value: 'unwatch',
            icon: Symbols.remove_circle_outline_rounded,
            label: t.mediaMenu.markAsUnwatched,
          ),
        );
      }

      // Remove from Continue Watching (only in continue watching section)
      if (widget.isInContinueWatching) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_continue_watching',
            icon: Symbols.close_rounded,
            label: t.mediaMenu.removeFromContinueWatching,
          ),
        );
      }

      // Remove from Collection (only when viewing items within a collection)
      if (widget.collectionId != null) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_collection',
            icon: Symbols.delete_outline_rounded,
            label: t.collections.removeFromCollection,
          ),
        );
      }

      // Go to Series (for episodes and seasons)
      if ((mediaType == PlexMediaType.episode || mediaType == PlexMediaType.season) &&
          metadata.grandparentTitle != null) {
        menuActions.add(_MenuAction(value: 'series', icon: Symbols.tv_rounded, label: t.mediaMenu.goToSeries));
      }

      // Go to Season (for episodes)
      if (mediaType == PlexMediaType.episode && metadata.parentTitle != null) {
        menuActions.add(
          _MenuAction(value: 'season', icon: Symbols.playlist_play_rounded, label: t.mediaMenu.goToSeason),
        );
      }

      // Shuffle Play (for shows and seasons)
      if (mediaType == PlexMediaType.show || mediaType == PlexMediaType.season) {
        menuActions.add(
          _MenuAction(value: 'shuffle_play', icon: Symbols.shuffle_rounded, label: t.mediaMenu.shufflePlay),
        );
      }

      // File Info (for episodes and movies)
      if (mediaType == PlexMediaType.episode || mediaType == PlexMediaType.movie) {
        menuActions.add(_MenuAction(value: 'fileinfo', icon: Symbols.info_rounded, label: t.mediaMenu.fileInfo));
      }

      // Play in External Player (for episodes and movies)
      if (mediaType == PlexMediaType.episode || mediaType == PlexMediaType.movie) {
        menuActions.add(
          _MenuAction(
            value: 'play_external',
            icon: Symbols.open_in_new_rounded,
            label: t.externalPlayer.playInExternalPlayer,
          ),
        );
      }

      // Download options (for episodes, movies, shows, and seasons)
      if (mediaType == PlexMediaType.episode ||
          mediaType == PlexMediaType.movie ||
          mediaType == PlexMediaType.show ||
          mediaType == PlexMediaType.season) {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        final globalKey = '${metadata.serverId}:${metadata.ratingKey}';
        final isDownloaded = downloadProvider.isDownloaded(globalKey);

        if (isDownloaded) {
          // Show delete download option
          menuActions.add(
            _MenuAction(value: 'delete_download', icon: Symbols.delete_rounded, label: t.downloads.deleteDownload),
          );
        } else {
          // Show download option
          menuActions.add(
            _MenuAction(value: 'download', icon: Symbols.download_rounded, label: t.downloads.downloadNow),
          );
        }
      }

      // Add to... (for episodes, movies, shows, and seasons)
      if (mediaType == PlexMediaType.episode ||
          mediaType == PlexMediaType.movie ||
          mediaType == PlexMediaType.show ||
          mediaType == PlexMediaType.season) {
        menuActions.add(_MenuAction(value: 'add_to', icon: Symbols.add_rounded, label: t.common.addTo));
      }

      // Delete media item (for episodes, movies, shows, and seasons)
      if (mediaType == PlexMediaType.episode ||
          mediaType == PlexMediaType.movie ||
          mediaType == PlexMediaType.show ||
          mediaType == PlexMediaType.season) {
        menuActions.add(
          _MenuAction(
            value: 'delete_media',
            icon: Symbols.delete_rounded,
            label: t.common.delete,
            hoverColor: Theme.of(context).colorScheme.error,
          ),
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
      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

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
        builder: (dialogContext) =>
            _FocusablePopupMenu(actions: menuActions, position: position, focusFirstItem: openedFromKeyboard),
      );
    }

    try {
      final client = _getClientForItem();

      if (!context.mounted) return;

      // Check if we're in offline mode for watch actions
      final offlineModeProvider = context.read<OfflineModeProvider>();
      final isOffline = offlineModeProvider.isOffline;

      switch (selected) {
        case 'watch':
          if (isOffline && metadata?.serverId != null) {
            // Offline mode: queue action for later sync (emits WatchStateEvent)
            final offlineWatch = context.read<OfflineWatchProvider>();
            await offlineWatch.markAsWatched(serverId: metadata!.serverId!, ratingKey: metadata.ratingKey);
            if (context.mounted) {
              showAppSnackBar(context, t.messages.markedAsWatchedOffline);
              widget.onRefresh?.call(metadata.ratingKey);
            }
          } else {
            // Pass metadata to emit WatchStateEvent for cross-screen updates
            await _executeAction(
              context,
              () => client.markAsWatched(metadata!.ratingKey, metadata: metadata),
              t.messages.markedAsWatched,
            );
          }
          break;

        case 'unwatch':
          if (isOffline && metadata?.serverId != null) {
            // Offline mode: queue action for later sync (emits WatchStateEvent)
            final offlineWatch = context.read<OfflineWatchProvider>();
            await offlineWatch.markAsUnwatched(serverId: metadata!.serverId!, ratingKey: metadata.ratingKey);
            if (context.mounted) {
              showAppSnackBar(context, t.messages.markedAsUnwatchedOffline);
              widget.onRefresh?.call(metadata.ratingKey);
            }
          } else {
            // Pass metadata to emit WatchStateEvent for cross-screen updates
            await _executeAction(
              context,
              () => client.markAsUnwatched(metadata!.ratingKey, metadata: metadata),
              t.messages.markedAsUnwatched,
            );
          }
          break;

        case 'remove_from_continue_watching':
          // Remove from Continue Watching without affecting watch status or progress
          // This preserves the progression for partially watched items
          // and doesn't mark unwatched next episodes as watched
          try {
            await client.removeFromOnDeck(metadata!.ratingKey);
            if (context.mounted) {
              showSuccessSnackBar(context, t.messages.removedFromContinueWatching);
              // Use specific callback if provided, otherwise fallback to onRefresh
              if (widget.onRemoveFromContinueWatching != null) {
                widget.onRemoveFromContinueWatching!();
              } else {
                widget.onRefresh?.call(metadata.ratingKey);
              }
            }
          } catch (e) {
            if (context.mounted) {
              showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
            }
          }
          break;

        case 'remove_from_collection':
          await _handleRemoveFromCollection(context, metadata!);
          break;

        case 'series':
          didNavigate = true;
          await _navigateToRelated(
            context,
            metadata!.grandparentRatingKey,
            (metadata) => MediaDetailScreen(metadata: metadata),
            t.messages.errorLoadingSeries,
          );
          break;

        case 'season':
          didNavigate = true;
          await _navigateToRelated(
            context,
            metadata!.parentRatingKey,
            (metadata) => SeasonDetailScreen(season: metadata),
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

        case 'play_external':
          await _handlePlayExternal(context);
          break;

        case 'download':
          await _handleDownload(context);
          break;

        case 'delete_download':
          await _handleDeleteDownload(context);
          break;

        case 'delete_media':
          await _handleDeleteMediaItem(context, mediaType);
          break;
      }
    } finally {
      _isContextMenuOpen = false;

      // Restore focus to the previously focused item after the menu closes,
      // but only if no navigation occurred and the focus node is still valid
      if (!didNavigate && previousFocus != null && previousFocus.canRequestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (previousFocus.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
    }
  }

  /// Execute an action with error handling and refresh
  Future<void> _executeAction(BuildContext context, Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (context.mounted) {
        showSuccessSnackBar(context, successMessage);
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
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
      final metadata = await client.getMetadataWithImages(ratingKey);
      if (metadata != null && context.mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => screenBuilder(metadata)));
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, '$errorPrefix: $e');
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
          builder: (context) => const Center(child: CircularProgressIndicator()),
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
          builder: (context) => FileInfoBottomSheet(fileInfo: fileInfo, title: metadata.title),
        );
      } else if (context.mounted) {
        showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoadingFileInfo(error: e.toString()));
      }
    }
  }

  /// Handle shuffle play using play queues
  Future<void> _handleShufflePlayWithQueue(BuildContext context) async {
    final client = _getClientForItem();
    final metadata = widget.item as PlexMetadata;

    final launcher = PlayQueueLauncher(
      context: context,
      client: client,
      serverId: metadata.serverId,
      serverName: metadata.serverName,
    );

    await launcher.launchShuffledShow(metadata: metadata, showLoadingIndicator: true);
  }

  /// Show submenu for Add to... (Playlist or Collection)
  Future<void> _showAddToSubmenu(BuildContext context) async {
    final useBottomSheet = AppPlatform.isIOS || AppPlatform.isAndroid;

    final submenuActions = [
      _MenuAction(value: 'playlist', icon: Symbols.playlist_play_rounded, label: t.playlists.playlist),
      _MenuAction(value: 'collection', icon: Symbols.collections_rounded, label: t.collections.collection),
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
                child: Text(t.common.addTo, style: Theme.of(context).textTheme.titleMedium),
              ),
              ...submenuActions.map((action) {
                return ListTile(
                  leading: AppIcon(action.icon, fill: 1),
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
              children: [AppIcon(action.icon, fill: 1, size: 20), const SizedBox(width: 12), Text(action.label)],
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
        final playlistName = await showTextInputDialog(
          context,
          title: t.playlists.create,
          labelText: t.playlists.playlistName,
          hintText: t.playlists.enterPlaylistName,
        );

        if (playlistName == null || playlistName.isEmpty || !context.mounted) {
          return;
        }

        // Create playlist with the item(s)
        appLogger.d('Creating playlist "$playlistName" with URI length: ${itemUri.length}');
        final newPlaylist = await client.createPlaylist(title: playlistName, uri: itemUri);

        if (!context.mounted) return;

        if (context.mounted) {
          if (newPlaylist != null) {
            appLogger.d('Successfully created playlist: ${newPlaylist.title}');
            showSuccessSnackBar(context, t.playlists.created);
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
          } else {
            appLogger.e('Failed to create playlist - API returned null');
            showErrorSnackBar(context, t.playlists.errorCreating);
          }
        }
      } else {
        // Add to existing playlist
        appLogger.d('Adding to playlist $result with URI: $itemUri');
        final success = await client.addToPlaylist(playlistId: result, uri: itemUri);

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to playlist $result');
            showSuccessSnackBar(context, t.playlists.itemAdded);
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
          } else {
            appLogger.e('Failed to add item(s) to playlist $result - API returned false');
            showErrorSnackBar(context, t.playlists.errorAdding);
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e('Error in add to playlist flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.playlists.errorLoading}: ${e.toString()}');
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
          final fullMetadata = await client.getMetadataWithImages(metadata.ratingKey);
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
        final keyMatch = RegExp(r'/library/sections/(\d+)').firstMatch(metadata.key);
        if (keyMatch != null) {
          sectionId = int.tryParse(keyMatch.group(1)!);
          appLogger.d('  - Extracted from key: $sectionId');
        }
      }

      // Last resort: try to get it from the item's parent (for episodes/seasons)
      if (sectionId == null && metadata.grandparentRatingKey != null) {
        try {
          appLogger.d('  - Trying to get from parent: ${metadata.grandparentRatingKey}');
          final parentMeta = await client.getMetadataWithImages(metadata.grandparentRatingKey!);
          sectionId = parentMeta?.librarySectionID;
          appLogger.d('  - Parent sectionId: $sectionId');
        } catch (e) {
          appLogger.w('Failed to get parent metadata for section ID: $e');
        }
      }

      appLogger.d('  - Final sectionId: $sectionId');

      if (sectionId == null) {
        if (context.mounted) {
          showErrorSnackBar(context, 'Unable to determine library section for this item');
        }
        return;
      }

      // Load collections for this library section
      final collections = await client.getLibraryCollections(sectionId.toString());

      if (!context.mounted) return;

      // Show dialog to select collection or create new
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _CollectionSelectionDialog(collections: collections),
      );

      if (result == null || !context.mounted) return;

      // Build URI for the item
      final itemUri = await client.buildMetadataUri(metadata.ratingKey);
      appLogger.d('Built URI for $itemType: $itemUri');

      if (!context.mounted) return;

      if (result == '_create_new') {
        // Create new collection flow
        final collectionName = await showTextInputDialog(
          context,
          title: t.collections.createNewCollection,
          labelText: t.collections.collectionName,
          hintText: t.collections.enterCollectionName,
        );

        if (collectionName == null || collectionName.isEmpty || !context.mounted) {
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

        appLogger.d('Creating collection "$collectionName" with type $collectionType');
        final newCollectionId = await client.createCollection(
          sectionId: sectionId.toString(),
          title: collectionName,
          uri: '', // Empty for regular collections
          type: collectionType,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (newCollectionId != null) {
            appLogger.d('Successfully created collection with ID: $newCollectionId');

            // Now add the item to the newly created collection
            appLogger.d('Adding item to new collection $newCollectionId with URI: $itemUri');
            final addSuccess = await client.addToCollection(collectionId: newCollectionId, uri: itemUri);

            if (!context.mounted) return;

            if (addSuccess) {
              appLogger.d('Successfully added item to new collection');
              showSuccessSnackBar(context, t.collections.created);
              // Trigger refresh of collections tab
              LibraryRefreshNotifier().notifyCollectionsChanged();
            } else {
              appLogger.e('Failed to add item to new collection');
              showErrorSnackBar(context, t.collections.errorAddingToCollection);
            }
          } else {
            appLogger.e('Failed to create collection - API returned null');
            showErrorSnackBar(context, t.collections.errorAddingToCollection);
          }
        }
      } else {
        // Add to existing collection
        appLogger.d('Adding to collection $result with URI: $itemUri');
        final success = await client.addToCollection(collectionId: result, uri: itemUri);

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to collection $result');
            showSuccessSnackBar(context, t.collections.addedToCollection);
            // Trigger refresh of collections tab
            LibraryRefreshNotifier().notifyCollectionsChanged();
          } else {
            appLogger.e('Failed to add item(s) to collection $result - API returned false');
            showErrorSnackBar(context, t.collections.errorAddingToCollection);
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e('Error in add to collection flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.collections.errorAddingToCollection}: ${e.toString()}');
      }
    }
  }

  /// Handle remove from collection action
  Future<void> _handleRemoveFromCollection(BuildContext context, PlexMetadata metadata) async {
    final client = _getClientForItem();

    if (widget.collectionId == null) {
      appLogger.e('Cannot remove from collection: collectionId is null');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.removeFromCollection,
      message: t.collections.removeFromCollectionConfirm(title: metadata.title),
    );

    if (!confirmed || !context.mounted) return;

    try {
      appLogger.d('Removing item ${metadata.ratingKey} from collection ${widget.collectionId}');
      final success = await client.removeFromCollection(collectionId: widget.collectionId!, itemId: metadata.ratingKey);

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.collections.removedFromCollection);
          // Trigger refresh of collections tab
          LibraryRefreshNotifier().notifyCollectionsChanged();
          // Trigger list refresh to remove the item from the view
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, t.collections.removeFromCollectionFailed);
        }
      }
    } catch (e) {
      appLogger.e('Failed to remove from collection', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.collections.removeFromCollectionError(error: e.toString()));
      }
    }
  }

  /// Handle play action for collections and playlists
  Future<void> _handlePlay(BuildContext context, bool isCollection, bool isPlaylist) async {
    await _launchCollectionOrPlaylist(context, shuffle: false);
  }

  /// Handle shuffle action for collections and playlists
  Future<void> _handleShuffle(BuildContext context, bool isCollection, bool isPlaylist) async {
    await _launchCollectionOrPlaylist(context, shuffle: true);
  }

  /// Launch playback for collection or playlist
  Future<void> _launchCollectionOrPlaylist(BuildContext context, {required bool shuffle}) async {
    final client = _getClientForItem();
    final item = widget.item;

    final launcher = PlayQueueLauncher(
      context: context,
      client: client,
      serverId: item is PlexMetadata ? item.serverId : (item as PlexPlaylist).serverId,
      serverName: item is PlexMetadata ? item.serverName : (item as PlexPlaylist).serverName,
    );

    await launcher.launchFromCollectionOrPlaylist(item: item, shuffle: shuffle, showLoadingIndicator: false);
  }

  /// Handle delete action for collections and playlists
  Future<void> _handleDelete(BuildContext context, bool isCollection, bool isPlaylist) async {
    final client = _getClientForItem();

    final itemTitle = widget.item.title;
    final itemTypeLabel = isCollection ? t.collections.collection : t.playlists.playlist;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: isCollection ? t.collections.deleteCollection : t.playlists.delete,
      message: isCollection
          ? t.collections.deleteConfirm(title: itemTitle)
          : t.playlists.deleteMessage(name: itemTitle),
    );

    if (!confirmed || !context.mounted) return;

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
          showSuccessSnackBar(context, isCollection ? t.collections.deleted : t.playlists.deleted);
          // Trigger list refresh
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, isCollection ? t.collections.deleteFailed : t.playlists.errorDeleting);
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete $itemTypeLabel', error: e);
      if (context.mounted) {
        showErrorSnackBar(
          context,
          isCollection ? t.collections.deleteFailedWithError(error: e.toString()) : t.playlists.errorDeleting,
        );
      }
    }
  }

  /// Handle play in external player action
  Future<void> _handlePlayExternal(BuildContext context) async {
    final metadata = widget.item as PlexMetadata;
    final client = _getClientForItem();

    await ExternalPlayerService.launch(context: context, metadata: metadata, client: client);
  }

  /// Handle download action
  Future<void> _handleDownload(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final metadata = widget.item as PlexMetadata;
    final client = _getClientForItem();

    try {
      final count = await downloadProvider.queueDownload(metadata, client);
      if (context.mounted) {
        // Show appropriate message based on count
        final message = count > 1 ? t.downloads.episodesQueued(count: count) : t.downloads.downloadQueued;
        showSuccessSnackBar(context, message);
      }
    } on CellularDownloadBlockedException {
      if (context.mounted) {
        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
    } catch (e) {
      appLogger.e('Failed to queue download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle delete download action
  Future<void> _handleDeleteDownload(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final metadata = widget.item as PlexMetadata;
    final globalKey = '${metadata.serverId}:${metadata.ratingKey}';

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.downloads.deleteDownload,
      message: t.downloads.deleteConfirm(title: metadata.title),
    );

    if (!confirmed || !context.mounted) return;

    try {
      // Use smart deletion handler (shows progress only if >500ms)
      await SmartDeletionHandler.deleteWithProgress(context: context, provider: downloadProvider, globalKey: globalKey);

      if (context.mounted) {
        showSuccessSnackBar(context, t.downloads.downloadDeleted);
        // Refresh the view if needed
        widget.onRefresh?.call(metadata.ratingKey);
      }
    } catch (e) {
      appLogger.e('Failed to delete download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle delete media item action
  /// This permanently removes the media item and its associated files from the server
  Future<void> _handleDeleteMediaItem(BuildContext context, PlexMediaType? mediaType) async {
    final metadata = widget.item as PlexMetadata;
    final isMultipleMediaItems = mediaType == PlexMediaType.show || mediaType == PlexMediaType.season;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.common.delete,
      message: "${t.mediaMenu.confirmDelete}${isMultipleMediaItems ? "\n${t.mediaMenu.deleteMultipleWarning}" : ""}",
    );

    if (!confirmed || !context.mounted) return;

    try {
      final client = _getClientForItem();
      final success = await client.deleteMediaItem(metadata.ratingKey);

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.mediaMenu.mediaDeletedSuccessfully);
          // Broadcast deletion event for cross-screen propagation
          DeletionNotifier().notifyDeleted(metadata: metadata);
          // Backward-compatible list refresh for screens that are not DeletionAware yet
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, t.mediaMenu.mediaFailedToDelete);
        }
      }
    } catch (e) {
      appLogger.e(t.mediaMenu.mediaFailedToDelete, error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.mediaMenu.mediaFailedToDelete);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
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
                leading: const AppIcon(Symbols.add_rounded, fill: 1),
                title: Text(t.playlists.createNewPlaylist),
                onTap: () => Navigator.pop(context, '_create_new'),
              );
            }

            final playlist = playlists[index - 1];
            return ListTile(
              leading: playlist.smart
                  ? const AppIcon(Symbols.auto_awesome_rounded, fill: 1)
                  : const AppIcon(Symbols.playlist_play_rounded, fill: 1),
              title: Text(playlist.title),
              subtitle: playlist.leafCount != null
                  ? Text(
                      playlist.leafCount == 1 ? t.playlists.oneItem : t.playlists.itemCount(count: playlist.leafCount!),
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
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
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
                leading: const AppIcon(Symbols.add_rounded, fill: 1),
                title: Text(t.collections.createNewCollection),
                onTap: () => Navigator.pop(context, '_create_new'),
              );
            }

            final collection = collections[index - 1];
            return ListTile(
              leading: const AppIcon(Symbols.collections_rounded, fill: 1),
              title: Text(collection.title),
              subtitle: collection.childCount != null ? Text('${collection.childCount} items') : null,
              onTap: () => Navigator.pop(context, collection.ratingKey),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
    );
  }
}

/// Focusable context menu sheet for keyboard/gamepad navigation (mobile)
class _FocusableContextMenuSheet extends StatefulWidget {
  final String title;
  final List<_MenuAction> actions;
  final bool focusFirstItem;

  const _FocusableContextMenuSheet({required this.title, required this.actions, this.focusFirstItem = false});

  @override
  State<_FocusableContextMenuSheet> createState() => _FocusableContextMenuSheetState();
}

class _FocusableContextMenuSheetState extends State<_FocusableContextMenuSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'ContextMenuSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableBottomSheet(
      initialFocusNode: widget.focusFirstItem ? _initialFocusNode : null,
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.actions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final action = entry.value;
                      return FocusableListTile(
                        focusNode: index == 0 ? _initialFocusNode : null,
                        leading: AppIcon(action.icon, fill: 1),
                        title: Text(action.label),
                        onTap: () => Navigator.pop(context, action.value),
                        hoverColor: action.hoverColor,
                      );
                    }),
                  ],
                ),
              ),
            ),
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

  const _FocusablePopupMenu({required this.actions, required this.position, this.focusFirstItem = false});

  @override
  State<_FocusablePopupMenu> createState() => _FocusablePopupMenuState();
}

class _FocusablePopupMenuState extends State<_FocusablePopupMenu> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'PopupMenuInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
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

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
          return KeyEventResult.handled;
        }
        if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
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
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.actions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return FocusableListTile(
                      focusNode: index == 0 ? _initialFocusNode : null,
                      leading: AppIcon(action.icon, fill: 1, size: 20),
                      title: Text(action.label),
                      onTap: () => Navigator.pop(context, action.value),
                      hoverColor: action.hoverColor,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
