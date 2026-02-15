import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/plex_metadata.dart';

/// Individual item in the folder tree
/// Can be either a folder (expandable) or a file (tappable)
class FolderTreeItem extends StatelessWidget {
  final PlexMetadata item;
  final int depth;
  final bool isExpanded;
  final bool isFolder;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final bool isLoading;

  const FolderTreeItem({
    super.key,
    required this.item,
    required this.depth,
    this.isExpanded = false,
    this.isFolder = false,
    this.onTap,
    this.onExpand,
    this.isLoading = false,
  });

  IconData _getIcon() {
    if (isFolder) {
      return Symbols.folder_rounded;
    }

    // File icons based on type
    final type = item.type.toLowerCase();
    switch (type) {
      case 'movie':
        return Symbols.movie_rounded;
      case 'show':
        return Symbols.tv_rounded;
      case 'season':
        return Symbols.video_library_rounded;
      case 'episode':
        return Symbols.play_circle_rounded;
      case 'collection':
        return Symbols.collections_rounded;
      default:
        return Symbols.insert_drive_file_rounded;
    }
  }

  void _handleTap() {
    if (isFolder) {
      onExpand?.call();
    } else {
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final indentation = depth * 24.0;
    final expandIcon = isExpanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded;

    return InkWell(
      onTap: _handleTap,
      child: Container(
        padding: EdgeInsets.only(left: 16.0 + indentation, right: 16.0, top: 12.0, bottom: 12.0),
        child: Row(
          children: [
            // Expand/collapse icon for folders
            if (isFolder)
              SizedBox(
                width: 24,
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : AppIcon(expandIcon, fill: 1, size: 20),
              )
            else
              const SizedBox(width: 24),

            const SizedBox(width: 8),

            // File/folder icon
            AppIcon(
              _getIcon(),
              fill: 1,
              size: 20,
              color: isFolder
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),

            const SizedBox(width: 12),

            // Item title
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(fontSize: 14, fontWeight: isFolder ? FontWeight.w500 : FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Additional metadata for files
            if (!isFolder && item.year != null)
              Text(
                item.year.toString(),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}
