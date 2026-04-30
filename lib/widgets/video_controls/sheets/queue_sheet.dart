import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_item.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import '../../optimized_media_image.dart';

const _kThumbWidth = 60.0;
const _kThumbHeight = 34.0;

/// Bottom sheet for viewing and navigating the play queue
class QueueSheet extends StatefulWidget {
  final Function(MediaItem) onItemSelected;

  const QueueSheet({super.key, required this.onItemSelected});

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  final _firstItemKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackStateProvider>(
      builder: (context, playbackState, _) {
        final items = playbackState.loadedItems;
        final currentItemID = playbackState.currentPlayQueueItemID;

        Widget content;
        if (items.isEmpty) {
          content = Center(
            child: Text(t.videoControls.noQueueItems, style: TextStyle(color: tokens(context).textMuted)),
          );
        } else {
          final currentIndex = items.indexWhere((item) => playbackState.playQueueItemIdFor(item) == currentItemID);
          if (!_didInitialScroll && currentIndex > 0) {
            _didInitialScroll = true;
            scrollToCurrentItem(_scrollController, _firstItemKey, currentIndex);
          }

          content = ListView.builder(
            controller: _scrollController,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrent = playbackState.playQueueItemIdFor(item) == currentItemID;

              final primaryColor = Theme.of(context).colorScheme.primary;
              return FocusableListTile(
                key: index == 0 ? _firstItemKey : null,
                leading: _buildThumbnail(context, item, isCurrent),
                title: Text(
                  item.title ?? '',
                  style: TextStyle(
                    color: isCurrent ? primaryColor : null,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _buildSubtitle(item),
                  style: TextStyle(
                    color: isCurrent ? primaryColor.withValues(alpha: 0.7) : tokens(context).textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isCurrent ? AppIcon(Symbols.play_circle_rounded, fill: 1, color: primaryColor) : null,
                onTap: () {
                  widget.onItemSelected(item);
                  OverlaySheetController.of(context).close();
                },
              );
            },
          );
        }

        return BaseVideoControlSheet(title: t.videoControls.queue, icon: Symbols.queue_rounded, child: content);
      },
    );
  }

  Widget? _buildThumbnail(BuildContext context, MediaItem item, bool isCurrent) {
    if (item.thumbPath == null) return null;

    // Try to get client for thumbnails, may fail in offline mode
    final client = context.tryGetMediaClientForServer(item.serverId);

    return SizedBox(
      width: _kThumbWidth,
      height: _kThumbHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: OptimizedMediaImage.thumb(
              client: client,
              imagePath: item.thumbPath,
              width: _kThumbWidth,
              height: _kThumbHeight,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: _kThumbHeight),
            ),
          ),
          if (isCurrent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  border: Border.fromBorderSide(BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildSubtitle(MediaItem item) {
    if (item.grandparentTitle != null && item.parentIndex != null && item.index != null) {
      return '${item.grandparentTitle} \u00b7 S${item.parentIndex}E${item.index}';
    }
    if (item.grandparentTitle != null) {
      return item.grandparentTitle!;
    }
    if (item.year != null) {
      final edition = item.editionTitle;
      return edition != null ? '${item.year} · $edition' : '${item.year}';
    }
    return item.kind.name;
  }
}
