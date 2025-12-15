import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../services/plex_client.dart';
import '../../services/play_queue_launcher.dart';
import '../../models/plex_playlist.dart';
import '../../models/plex_metadata.dart';
import '../../utils/app_logger.dart';
import '../../utils/provider_extensions.dart';
import '../../widgets/media_grid_sliver.dart';
import 'playlist_item_card.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dialogs.dart';
import '../base_media_list_detail_screen.dart';

/// Screen to display the contents of a playlist
class PlaylistDetailScreen extends StatefulWidget {
  final PlexPlaylist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseMediaListDetailScreen<PlaylistDetailScreen>
    with StandardItemLoader<PlaylistDetailScreen> {
  @override
  dynamic get mediaItem => widget.playlist;

  @override
  String get title => widget.playlist.title;

  @override
  String get emptyMessage => t.playlists.emptyPlaylist;

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  @override
  Future<List<PlexMetadata>> fetchItems() async {
    return await client.getPlaylist(widget.playlist.ratingKey);
  }

  @override
  String getLoadSuccessMessage(int itemCount) {
    return 'Loaded $itemCount items for playlist: ${widget.playlist.title}';
  }

  /// Get the correct PlexClient for this playlist's server
  PlexClient _getClientForPlaylist() {
    return context.getClientForServer(widget.playlist.serverId!);
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.playlists.deleteConfirm,
      message: t.playlists.deleteMessage(name: widget.playlist.title),
    );

    if (confirmed == true && mounted) {
      final success = await client.deletePlaylist(widget.playlist.ratingKey);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.deleted)));
          Navigator.pop(context); // Return to playlists screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorDeleting)));
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

    final movedItem = items[oldIndex];

    // Check if item has playlistItemID (required for reordering)
    if (movedItem.playlistItemID == null) {
      appLogger.e('Cannot reorder: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
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
      final afterItem = items[newIndex - 1];
      if (afterItem.playlistItemID == null) {
        appLogger.e('Cannot reorder: after item missing playlistItemID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
        }
        return;
      }
      afterPlaylistItemId = afterItem.playlistItemID!;
    }

    appLogger.d('Reordering item from $oldIndex to $newIndex (after ID: $afterPlaylistItemId)');

    // Optimistically update UI
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
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
          final item = items.removeAt(newIndex);
          items.insert(oldIndex, item);
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final item = items[index];

    // Check if item has playlistItemID (required for removal)
    if (item.playlistItemID == null) {
      appLogger.e('Cannot remove: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
      return;
    }

    appLogger.d('Removing item ${item.title} (playlistItemID: ${item.playlistItemID}) from playlist');

    // Optimistically update UI
    setState(() {
      items.removeAt(index);
    });

    // Call API to persist the change
    final success = await client.removeFromPlaylist(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: item.playlistItemID.toString(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.itemRemoved)));
      } else {
        // Revert on failure
        appLogger.e('Failed to remove playlist item, reverting UI');
        setState(() {
          items.insert(index, item);
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
    }
  }

  Future<void> _playFromItem(int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;

    final plexClient = _getClientForPlaylist();
    final selectedItem = items[index];

    final launcher = PlayQueueLauncher(
      context: context,
      client: plexClient,
      serverId: widget.playlist.serverId,
      serverName: widget.playlist.serverName,
    );

    await launcher.launchFromPlaylistItem(
      playlist: widget.playlist,
      selectedItem: selectedItem,
      showLoadingIndicator: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.playlist.title, style: const TextStyle(fontSize: 16)),
          if (widget.playlist.smart)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(Symbols.auto_awesome_rounded, fill: 1, size: 12, color: Colors.blue[300]),
                const SizedBox(width: 4),
                Text(
                  t.playlists.smartPlaylist,
                  style: TextStyle(fontSize: 11, color: Colors.blue[300], fontWeight: FontWeight.normal),
                ),
              ],
            ),
        ],
      ),
      actions: buildAppBarActions(
        onDelete: widget.playlist.smart ? null : _deletePlaylist,
        deleteTooltip: t.playlists.delete,
        showDelete: !widget.playlist.smart,
      ),
      slivers: [
        ...buildStateSlivers(),
        if (items.isNotEmpty)
          if (widget.playlist.smart)
            // Smart playlists: Use grid view (cannot be reordered)
            MediaGridSliver(items: items, onRefresh: updateItem)
          else
            // Regular playlists: Use reorderable list view
            SliverReorderableList(
              itemBuilder: (context, index) {
                final item = items[index];
                return PlaylistItemCard(
                  key: ValueKey(item.playlistItemID ?? item.ratingKey),
                  item: item,
                  index: index,
                  onRemove: () => _removeItem(index),
                  onTap: () => _playFromItem(index),
                  onRefresh: updateItem,
                  canReorder: !widget.playlist.smart,
                );
              },
              itemCount: items.length,
              onReorder: _onReorder,
            ),
      ],
    );
  }
}
