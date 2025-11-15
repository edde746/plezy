import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_playlist.dart';
import '../models/plex_metadata.dart';
import '../providers/settings_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/media_card.dart';
import '../widgets/playlist_item_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';

/// Screen to display the contents of a playlist
class PlaylistDetailScreen extends StatefulWidget {
  final PlexPlaylist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen>
    with Refreshable, ItemUpdatable {
  @override
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaylistItems();
  }

  Future<void> _loadPlaylistItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final items = await client.getPlaylist(widget.playlist.ratingKey);

      setState(() {
        _items = items;
        _isLoading = false;
      });

      appLogger.d(
        'Loaded ${items.length} items for playlist: ${widget.playlist.title}',
      );
    } catch (e) {
      appLogger.e('Failed to load playlist items', error: e);
      setState(() {
        _errorMessage = 'Failed to load playlist items: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.playlists.deleteConfirm),
        content: Text(t.playlists.deleteMessage(name: widget.playlist.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.playlists.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await client.deletePlaylist(widget.playlist.ratingKey);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.playlists.deleted)));
          Navigator.pop(context); // Return to playlists screen
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.playlists.errorDeleting)));
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // Adjust newIndex if moving down in the list
    if (newIndex > oldIndex) {
      newIndex--;
    }

    // Can't reorder if indices are the same
    if (oldIndex == newIndex) return;

    final movedItem = _items[oldIndex];

    // Check if item has playlistItemID (required for reordering)
    if (movedItem.playlistItemID == null) {
      appLogger.e('Cannot reorder: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
      return;
    }

    // Determine the "after" item ID
    // If moving to position 0, afterPlaylistItemId should be 0 (move to top)
    // Otherwise, use the playlistItemID of the item before the new position
    final int afterPlaylistItemId;
    if (newIndex == 0) {
      afterPlaylistItemId = 0; // Move to top
    } else {
      final afterItem = _items[newIndex - 1];
      if (afterItem.playlistItemID == null) {
        appLogger.e('Cannot reorder: after item missing playlistItemID');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
        }
        return;
      }
      afterPlaylistItemId = afterItem.playlistItemID!;
    }

    appLogger.d(
      'Reordering item from $oldIndex to $newIndex (after ID: $afterPlaylistItemId)',
    );

    // Optimistically update UI
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    // Call API to persist the change
    final success = await client.movePlaylistItem(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: movedItem.playlistItemID!,
      afterPlaylistItemId: afterPlaylistItemId,
    );

    if (!success) {
      // Revert on failure
      appLogger.e('Failed to reorder playlist item, reverting UI');
      if (mounted) {
        setState(() {
          final item = _items.removeAt(newIndex);
          _items.insert(oldIndex, item);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _items[index];

    // Check if item has playlistItemID (required for removal)
    if (item.playlistItemID == null) {
      appLogger.e('Cannot remove: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
      return;
    }

    appLogger.d(
      'Removing item ${item.title} (playlistItemID: ${item.playlistItemID}) from playlist',
    );

    // Optimistically update UI
    setState(() {
      _items.removeAt(index);
    });

    // Call API to persist the change
    final success = await client.removeFromPlaylist(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: item.playlistItemID.toString(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.itemRemoved)));
      } else {
        // Revert on failure
        appLogger.e('Failed to remove playlist item, reverting UI');
        setState(() {
          _items.insert(index, item);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
    }
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _items[index] = updatedMetadata;
    }
  }

  @override
  void refresh() {
    _loadPlaylistItems();
  }

  Future<void> _playPlaylist() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.emptyPlaylist)));
      }
      return;
    }

    final playbackState = context.read<PlaybackStateProvider>();

    // Set the playlist items as the playback queue (in order, not shuffled)
    playbackState.setPlaybackQueue(_items, widget.playlist.ratingKey);

    // Navigate to the first item
    if (mounted) {
      await navigateToVideoPlayer(context, metadata: _items.first);
    }
  }

  Future<void> _shufflePlayPlaylist() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.playlists.emptyPlaylist)));
      }
      return;
    }

    final playbackState = context.read<PlaybackStateProvider>();

    // Shuffle the items
    final shuffledItems = List<PlexMetadata>.from(_items)..shuffle();

    // Set the shuffled playlist items as the playback queue (playlist mode, not shuffle mode)
    playbackState.setPlaybackQueue(shuffledItems, widget.playlist.ratingKey);

    // Navigate to the first shuffled item
    if (mounted) {
      await navigateToVideoPlayer(context, metadata: shuffledItems.first);
    }
  }

  Future<void> _playFromItem(int index) async {
    if (_items.isEmpty || index < 0 || index >= _items.length) return;

    final playbackState = context.read<PlaybackStateProvider>();

    // Set the full playlist as playback queue (in order)
    playbackState.setPlaybackQueue(_items, widget.playlist.ratingKey);

    // Start playing from the clicked item
    if (mounted) {
      await navigateToVideoPlayer(context, metadata: _items[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlist.title,
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.playlist.smart)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.blue[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.playlists.smartPlaylist,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[300],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pinned: true,
            actions: [
              // Play button
              if (_items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: t.discover.play,
                  onPressed: _playPlaylist,
                ),
              // Shuffle button
              if (_items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: t.playlists.shuffle,
                  onPressed: _shufflePlayPlaylist,
                ),
              // Delete button for non-smart playlists
              if (!widget.playlist.smart)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: t.playlists.delete,
                  onPressed: _deletePlaylist,
                  color: Colors.red,
                ),
            ],
          ),
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPlaylistItems,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.playlist_play,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.playlists.emptyPlaylist,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (widget.playlist.smart)
            // Smart playlists: Use grid view (cannot be reordered)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _getMaxCrossAxisExtent(
                    context,
                    context.watch<SettingsProvider>().libraryDensity,
                  ),
                  childAspectRatio: 2 / 3.3,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return MediaCard(item: _items[index], onRefresh: updateItem);
                }, childCount: _items.length),
              ),
            )
          else
            // Regular playlists: Use reorderable list view
            SliverReorderableList(
              itemBuilder: (context, index) {
                final item = _items[index];
                return PlaylistItemCard(
                  key: ValueKey(item.playlistItemID ?? item.ratingKey),
                  item: item,
                  index: index,
                  onRemove: () => _removeItem(index),
                  onTap: () => _playFromItem(index),
                  canReorder: !widget.playlist.smart,
                );
              },
              itemCount: _items.length,
              onReorder: _onReorder,
            ),
        ],
      ),
    );
  }

  double _getMaxCrossAxisExtent(BuildContext context, LibraryDensity density) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0;
    final availableWidth = screenWidth - padding;

    if (screenWidth >= 900) {
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 6.5;
          maxItemWidth = 280;
          break;
        case LibraryDensity.normal:
          divisor = 8.0;
          maxItemWidth = 200;
          break;
        case LibraryDensity.compact:
          divisor = 10.0;
          maxItemWidth = 160;
          break;
      }

      return (availableWidth / divisor).clamp(120, maxItemWidth);
    } else if (screenWidth >= 600) {
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 4.5;
          maxItemWidth = 220;
          break;
        case LibraryDensity.normal:
          divisor = 5.5;
          maxItemWidth = 180;
          break;
        case LibraryDensity.compact:
          divisor = 7.0;
          maxItemWidth = 140;
          break;
      }

      return (availableWidth / divisor).clamp(100, maxItemWidth);
    } else {
      double divisor;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 2.2;
          break;
        case LibraryDensity.normal:
          divisor = 2.8;
          break;
        case LibraryDensity.compact:
          divisor = 3.5;
          break;
      }

      return availableWidth / divisor;
    }
  }
}
