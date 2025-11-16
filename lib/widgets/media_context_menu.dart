import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../widgets/file_info_bottom_sheet.dart';
import '../utils/shuffle_play_helper.dart';
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
  final PlexMetadata metadata;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onTap;
  final Widget child;
  final bool isInContinueWatching;
  final void Function(VoidCallback showMenu)? onMenuReady;

  const MediaContextMenu({
    super.key,
    required this.metadata,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onTap,
    required this.child,
    this.isInContinueWatching = false,
    this.onMenuReady,
  });

  @override
  State<MediaContextMenu> createState() => _MediaContextMenuState();
}

class _MediaContextMenuState extends State<MediaContextMenu> {
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    // Pass the showMenu callback to parent if requested
    widget.onMenuReady?.call(() => _showContextMenu(context));
  }

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu(BuildContext context) async {
    final client = context.client;
    if (client == null) return;

    final itemType = widget.metadata.type.toLowerCase();
    final isPartiallyWatched =
        widget.metadata.viewedLeafCount != null &&
        widget.metadata.leafCount != null &&
        widget.metadata.viewedLeafCount! > 0 &&
        widget.metadata.viewedLeafCount! < widget.metadata.leafCount!;

    // Check if we should use bottom sheet (on iOS and Android)
    final useBottomSheet = Platform.isIOS || Platform.isAndroid;

    // Build menu actions
    final menuActions = <_MenuAction>[];

    // Mark as Watched
    if (!widget.metadata.isWatched || isPartiallyWatched) {
      menuActions.add(
        _MenuAction(
          value: 'watch',
          icon: Icons.check_circle_outline,
          label: t.mediaMenu.markAsWatched,
        ),
      );
    }

    // Mark as Unwatched
    if (widget.metadata.isWatched || isPartiallyWatched) {
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

    // Go to Series (for episodes and seasons)
    if ((itemType == 'episode' || itemType == 'season') &&
        widget.metadata.grandparentTitle != null) {
      menuActions.add(
        _MenuAction(
          value: 'series',
          icon: Icons.tv,
          label: t.mediaMenu.goToSeries,
        ),
      );
    }

    // Go to Season (for episodes)
    if (itemType == 'episode' && widget.metadata.parentTitle != null) {
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

    // Add to Playlist (for episodes, movies, shows, and seasons)
    if (itemType == 'episode' ||
        itemType == 'movie' ||
        itemType == 'show' ||
        itemType == 'season') {
      menuActions.add(
        _MenuAction(
          value: 'add_to_playlist',
          icon: Icons.playlist_add,
          label: t.playlists.addTo,
        ),
      );
    }

    String? selected;

    if (useBottomSheet) {
      // Show bottom sheet on mobile
      selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: Text(
                  widget.metadata.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...menuActions.map(
                (action) => ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  onTap: () => Navigator.pop(context, action.value),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show popup menu on larger screens
      final menuItems = menuActions
          .map(
            (action) => PopupMenuItem(
              value: action.value,
              child: Row(
                children: [
                  Icon(action.icon),
                  const SizedBox(width: 12),
                  Expanded(child: Text(action.label)),
                ],
              ),
            ),
          )
          .toList();

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

      // Calculate position for menu using RelativeRect
      final overlayRect = RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      );

      // Use showMenu with fast animations via PopupMenuTheme
      selected = await showMenu<String>(
        context: context,
        position: overlayRect,
        items: menuItems,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        menuPadding: EdgeInsets.zero,
        // Override animation duration for faster animations
        popUpAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        ),
      );
    }

    if (!context.mounted) return;

    switch (selected) {
      case 'watch':
        await _executeAction(
          context,
          () => client.markAsWatched(widget.metadata.ratingKey),
          t.messages.markedAsWatched,
        );
        break;

      case 'unwatch':
        await _executeAction(
          context,
          () => client.markAsUnwatched(widget.metadata.ratingKey),
          t.messages.markedAsUnwatched,
        );
        break;

      case 'remove_from_continue_watching':
        // Remove from Continue Watching without affecting watch status or progress
        // This preserves the progression for partially watched items
        // and doesn't mark unwatched next episodes as watched
        try {
          await client.removeFromOnDeck(widget.metadata.ratingKey);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.messages.removedFromContinueWatching)),
            );
            // Use specific callback if provided, otherwise fallback to onRefresh
            if (widget.onRemoveFromContinueWatching != null) {
              widget.onRemoveFromContinueWatching!();
            } else {
              widget.onRefresh?.call(widget.metadata.ratingKey);
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

      case 'series':
        await _navigateToRelated(
          context,
          widget.metadata.grandparentRatingKey,
          (metadata) => MediaDetailScreen(metadata: metadata),
          t.messages.errorLoadingSeries,
        );
        break;

      case 'season':
        await _navigateToRelated(
          context,
          widget.metadata.parentRatingKey,
          (metadata) => SeasonDetailScreen(season: metadata),
          t.messages.errorLoadingSeason,
        );
        break;

      case 'fileinfo':
        await _showFileInfo(context);
        break;

      case 'add_to_playlist':
        await _showAddToPlaylistDialog(context);
        break;

      case 'shuffle_play':
        await handleShufflePlay(context, widget.metadata);
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
        widget.onRefresh?.call(widget.metadata.ratingKey);
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

    final clientProvider = context.plexClient;
    final client = clientProvider.client;
    if (client == null) return;

    try {
      final metadata = await client.getMetadata(ratingKey);
      if (metadata != null && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenBuilder(metadata)),
        );
        widget.onRefresh?.call(widget.metadata.ratingKey);
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
    final client = context.client;
    if (client == null) return;

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
      final fileInfo = await client.getFileInfo(widget.metadata.ratingKey);

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
          builder: (context) => FileInfoBottomSheet(
            fileInfo: fileInfo,
            title: widget.metadata.title,
          ),
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

  /// Show dialog to select playlist and add item
  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final client = context.client;
    if (client == null) return;

    try {
      final itemType = widget.metadata.type.toLowerCase();

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
      final itemUri = await client.buildMetadataUri(widget.metadata.ratingKey);
      appLogger.d('Built URI for $itemType: $itemUri');

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

        if (context.mounted) {
          if (newPlaylist != null) {
            appLogger.d('Successfully created playlist: ${newPlaylist.title}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.created)));
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

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to playlist $result');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.playlists.itemAdded)));
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
