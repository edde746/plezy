import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plex_metadata.dart';
import '../utils/keyboard_utils.dart';

/// Individual item in the folder tree
/// Can be either a folder (expandable) or a file (tappable)
class FolderTreeItem extends StatefulWidget {
  final PlexMetadata item;
  final int depth;
  final bool isExpanded;
  final bool isFolder;
  final void Function({bool isKeyboard})? onTap;
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

  @override
  State<FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<FolderTreeItem> {
  bool _isKeyboardActivation = false;

  IconData _getIcon() {
    if (widget.isFolder) {
      return Icons.folder;
    }

    // File icons based on type
    final type = widget.item.type.toLowerCase();
    switch (type) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'season':
        return Icons.video_library;
      case 'episode':
        return Icons.play_circle_outline;
      case 'collection':
        return Icons.collections;
      default:
        return Icons.insert_drive_file;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        isKeyboardActivationKey(event.logicalKey)) {
      _isKeyboardActivation = true;
      return KeyEventResult.ignored; // Let InkWell handle the activation
    }
    return KeyEventResult.ignored;
  }

  void _handleTap() {
    if (widget.isFolder) {
      widget.onExpand?.call();
    } else {
      widget.onTap?.call(isKeyboard: _isKeyboardActivation);
    }
    _isKeyboardActivation = false;
  }

  @override
  Widget build(BuildContext context) {
    final indentation = widget.depth * 24.0;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + indentation,
            right: 16.0,
            top: 12.0,
            bottom: 12.0,
          ),
          child: Row(
            children: [
              // Expand/collapse icon for folders
              if (widget.isFolder)
                SizedBox(
                  width: 24,
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                        ),
                )
              else
                const SizedBox(width: 24),

              const SizedBox(width: 8),

              // File/folder icon
              Icon(
                _getIcon(),
                size: 20,
                color: widget.isFolder
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),

              const SizedBox(width: 12),

              // Item title
              Expanded(
                child: Text(
                  widget.item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isFolder
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Additional metadata for files
              if (!widget.isFolder && widget.item.year != null)
                Text(
                  widget.item.year.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
