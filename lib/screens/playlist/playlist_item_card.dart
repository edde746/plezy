import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../services/plex_client.dart';
import '../../models/plex_metadata.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_extensions.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/media_context_menu.dart';
import '../../widgets/media_progress_bar.dart';
import '../../widgets/plex_optimized_image.dart';

/// Custom list item widget for playlist items
/// Shows drag handle, poster, title/metadata, duration, and remove button
class PlaylistItemCard extends StatefulWidget {
  final PlexMetadata item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback? onTap;
  final void Function(String ratingKey)? onRefresh;
  final bool canReorder; // Whether drag handle should be shown

  // Focus state for keyboard/D-pad navigation
  final bool isFocused;
  final int? focusedColumn; // 0=row, 1=drag handle, 2=remove button
  final bool isMoving; // Whether this item is being moved/reordered

  const PlaylistItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    this.onTap,
    this.onRefresh,
    this.canReorder = true,
    this.isFocused = false,
    this.focusedColumn,
    this.isMoving = false,
  });

  @override
  State<PlaylistItemCard> createState() => _PlaylistItemCardState();
}

class _PlaylistItemCardState extends State<PlaylistItemCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();
  Offset? _tapPosition;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context, position: _tapPosition);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine if row is focused (main content area)
    final isRowFocused = widget.isFocused && widget.focusedColumn == 0;

    // Focus states for individual elements
    final isDragHandleFocused = widget.isFocused && widget.focusedColumn == 1;
    final isRemoveButtonFocused = widget.isFocused && widget.focusedColumn == 2;

    // Determine card styling based on focus/move state
    Color? cardColor;
    ShapeBorder? cardShape;
    if (widget.isMoving) {
      cardColor = colorScheme.primaryContainer;
    } else if (isRowFocused) {
      // Row is focused - use visible border like FocusableWrapper
      cardColor = colorScheme.surfaceContainerHighest;
      cardShape = RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: colorScheme.primary, width: 2.5),
      );
    }

    return MediaContextMenu(
      key: _contextMenuKey,
      item: widget.item,
      onRefresh: widget.onRefresh,
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cardColor,
        shape: cardShape,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _storeTapPosition,
          onLongPress: _showContextMenu,
          onSecondaryTapDown: _storeTapPosition,
          onSecondaryTap: _showContextMenu,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Drag handle (if reorderable)
                // Wrapped in GestureDetector to consume long-press and prevent context menu
                if (widget.canReorder)
                  GestureDetector(
                    // ignore: no-empty-block - consumes long-press to prevent context menu on drag
                    onLongPress: () {},
                    child: ReorderableDragStartListener(
                      index: widget.index,
                      child: Container(
                        color: Colors.transparent,
                        height: 90,
                        padding: const EdgeInsets.only(right: 4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(2, 8, 6, 8),
                          decoration: isDragHandleFocused
                              ? BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                )
                              : null,
                          child: AppIcon(
                            widget.isMoving ? Symbols.swap_vert_rounded : Symbols.drag_indicator_rounded,
                            fill: 1,
                            color: (widget.isMoving || isDragHandleFocused) ? colorScheme.primary : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Poster thumbnail
                _buildPosterImage(context),

                const SizedBox(width: 12),

                // Title and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.item.displayTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Subtitle (episode info or type)
                      Text(
                        _buildSubtitle(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Progress indicator if partially watched
                      if (widget.item.viewOffset != null && widget.item.duration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: MediaProgressBar(
                            viewOffset: widget.item.viewOffset!,
                            duration: widget.item.duration!,
                            minHeight: 3,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Duration
                if (widget.item.duration != null)
                  Text(
                    formatDurationTextual(widget.item.duration!),
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),

                const SizedBox(width: 8),

                // Remove button
                Container(
                  decoration: isRemoveButtonFocused
                      ? BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        )
                      : null,
                  child: IconButton(
                    icon: const AppIcon(Symbols.close_rounded, fill: 1, size: 20),
                    onPressed: widget.onRemove,
                    tooltip: t.playlists.removeItem,
                    color: isRemoveButtonFocused ? colorScheme.primary : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get the correct PlexClient for this item's server
  PlexClient _getClientForItem(BuildContext context) {
    return context.getClientForServer(widget.item.serverId!);
  }

  Widget _buildPosterImage(BuildContext context) {
    final posterUrl = widget.item.posterThumb();
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: PlexOptimizedImage.poster(
        client: _getClientForItem(context),
        imagePath: posterUrl,
        width: 60,
        height: 90,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: const BorderRadius.all(Radius.circular(6))),
      child: const AppIcon(Symbols.movie_rounded, fill: 1, color: Colors.grey, size: 24),
    );
  }

  String _buildSubtitle() {
    final itemType = widget.item.type.toLowerCase();

    if (itemType == 'episode') {
      // For episodes, show "S#E# - Episode Title"
      final season = widget.item.parentIndex;
      final episode = widget.item.index;
      if (season != null && episode != null) {
        return 'S${season}E$episode${widget.item.displaySubtitle != null ? ' - ${widget.item.displaySubtitle}' : ''}';
      }
      return widget.item.displaySubtitle ?? t.discover.tvShow;
    } else if (itemType == 'movie') {
      // For movies, show year
      return widget.item.year?.toString() ?? t.discover.movie;
    }

    // Default to type
    return widget.item.type;
  }
}
