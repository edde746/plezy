import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../utils/provider_extensions.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../widgets/file_info_bottom_sheet.dart';
import '../utils/shuffle_play_helper.dart';

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
  final VoidCallback? onTap;
  final Widget child;

  const MediaContextMenu({
    super.key,
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
        _MenuAction(value: 'series', icon: Icons.tv, label: 'Go to series'),
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

    // Shuffle Play (for shows and seasons)
    if (itemType == 'show' || itemType == 'season') {
      menuActions.add(
        _MenuAction(
          value: 'shuffle_play',
          icon: Icons.shuffle,
          label: 'Shuffle Play',
        ),
      );
    }

    // File Info (for episodes and movies)
    if (itemType == 'episode' || itemType == 'movie') {
      menuActions.add(
        _MenuAction(
          value: 'fileinfo',
          icon: Icons.info_outline,
          label: 'File Info',
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
              ...menuActions.map(
                (action) => ListTile(
                  leading: Icon(action.icon),
                  title: Text(action.label),
                  onTap: () => Navigator.pop(context, action.value),
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
          'Marked as watched',
        );
        break;

      case 'unwatch':
        await _executeAction(
          context,
          () => client.markAsUnwatched(widget.metadata.ratingKey),
          'Marked as unwatched',
        );
        break;

      case 'series':
        await _navigateToRelated(
          context,
          widget.metadata.grandparentRatingKey,
          (metadata) => MediaDetailScreen(metadata: metadata),
          'Error loading series',
        );
        break;

      case 'season':
        await _navigateToRelated(
          context,
          widget.metadata.parentRatingKey,
          (metadata) => SeasonDetailScreen(season: metadata),
          'Error loading season',
        );
        break;

      case 'fileinfo':
        await _showFileInfo(context);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          const SnackBar(content: Text('File information not available')),
        );
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading file info: $e')));
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
