import 'dart:io';
import 'package:flutter/material.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';

/// Helper class to store menu action data
class _MenuAction {
  final String value;
  final IconData icon;
  final String label;

  _MenuAction({
    required this.value,
    required this.icon,
    required this.label,
  });
}

/// A reusable wrapper widget that adds a context menu (long press / right click)
/// to any media item with appropriate actions based on the item type.
class MediaContextMenu extends StatefulWidget {
  final PlexClient client;
  final PlexMetadata metadata;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onTap;
  final Widget child;

  const MediaContextMenu({
    super.key,
    required this.client,
    required this.metadata,
    this.onRefresh,
    this.onTap,
    required this.child,
  });

  @override
  State<MediaContextMenu> createState() => _MediaContextMenuState();
}

class _MediaContextMenuState extends State<MediaContextMenu> {
  Offset? _tapPosition;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu(BuildContext context) async {
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
          label: 'Mark as Watched',
        ),
      );
    }

    // Mark as Unwatched
    if (widget.metadata.isWatched || isPartiallyWatched) {
      menuActions.add(
        _MenuAction(
          value: 'unwatch',
          icon: Icons.remove_circle_outline,
          label: 'Mark as Unwatched',
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
          label: 'Go to series',
        ),
      );
    }

    // Go to Season (for episodes)
    if (itemType == 'episode' && widget.metadata.parentTitle != null) {
      menuActions.add(
        _MenuAction(
          value: 'season',
          icon: Icons.playlist_play,
          label: 'Go to season',
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
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.metadata.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...menuActions.map((action) => ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () => Navigator.pop(context, action.value),
              )),
            ],
          ),
        ),
      );
    } else {
      // Show popup menu on larger screens
      final menuItems = menuActions.map((action) => PopupMenuItem(
        value: action.value,
        child: Row(
          children: [
            Icon(action.icon),
            const SizedBox(width: 12),
            Expanded(child: Text(action.label)),
          ],
        ),
      )).toList();

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

      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: menuItems,
      );
    }

    if (!context.mounted) return;

    switch (selected) {
      case 'watch':
        await _executeAction(
          context,
          () => widget.client.markAsWatched(widget.metadata.ratingKey),
          'Marked as watched',
        );
        break;

      case 'unwatch':
        await _executeAction(
          context,
          () => widget.client.markAsUnwatched(widget.metadata.ratingKey),
          'Marked as unwatched',
        );
        break;

      case 'series':
        await _navigateToRelated(
          context,
          widget.metadata.grandparentRatingKey,
          (metadata) => MediaDetailScreen(
            client: widget.client,
            metadata: metadata,
          ),
          'Error loading series',
        );
        break;

      case 'season':
        await _navigateToRelated(
          context,
          widget.metadata.parentRatingKey,
          (metadata) => SeasonDetailScreen(
            client: widget.client,
            season: metadata,
          ),
          'Error loading season',
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        widget.onRefresh?.call(widget.metadata.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

    try {
      final metadata = await widget.client.getMetadata(ratingKey);
      if (metadata != null && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenBuilder(metadata)),
        );
        widget.onRefresh?.call(widget.metadata.ratingKey);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorPrefix: $e')),
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
