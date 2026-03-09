import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/plex_metadata.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import '../../plex_optimized_image.dart';

const _kItemHeight = 72.0;
const _kItemHeightTablet = 116.0;
const _kThumbWidth = 60.0;
const _kThumbHeight = 34.0;
const _kThumbWidthTablet = 120.0;
const _kThumbHeightTablet = 68.0;

/// Bottom sheet for viewing and navigating the play queue
class QueueSheet extends StatelessWidget {
  final Function(PlexMetadata) onItemSelected;

  const QueueSheet({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final itemHeight = isTablet ? _kItemHeightTablet : _kItemHeight;

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
          // Find current index for initial scroll
          final currentIndex = items.indexWhere((item) => item.playQueueItemID == currentItemID);

          content = ListView.builder(
            controller: currentIndex > 0 ? ScrollController(initialScrollOffset: currentIndex * itemHeight) : null,
            itemExtent: itemHeight,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrent = item.playQueueItemID == currentItemID;

              final primaryColor = Theme.of(context).colorScheme.primary;
              return FocusableListTile(
                leading: _buildThumbnail(context, item, isCurrent, isTablet: isTablet),
                title: Text(
                  item.title,
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
                  onItemSelected(item);
                  OverlaySheetController.of(context).close();
                },
              );
            },
          );
        }

        return BaseVideoControlSheet(title: t.videoControls.queue, icon: Symbols.queue_music_rounded, child: content);
      },
    );
  }

  Widget? _buildThumbnail(BuildContext context, PlexMetadata item, bool isCurrent, {bool isTablet = false}) {
    if (item.thumb == null) return null;

    final thumbWidth = isTablet ? _kThumbWidthTablet : _kThumbWidth;
    final thumbHeight = isTablet ? _kThumbHeightTablet : _kThumbHeight;

    // Try to get client for thumbnails, may fail in offline mode
    final client = _tryGetClient(context, item);

    return SizedBox(
      width: thumbWidth,
      height: thumbHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: PlexOptimizedImage.thumb(
              client: client,
              imagePath: item.thumb,
              width: thumbWidth,
              height: thumbHeight,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: thumbHeight),
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

  String _buildSubtitle(PlexMetadata item) {
    if (item.grandparentTitle != null && item.parentIndex != null && item.index != null) {
      return '${item.grandparentTitle} \u00b7 S${item.parentIndex}E${item.index}';
    }
    if (item.grandparentTitle != null) {
      return item.grandparentTitle!;
    }
    if (item.year != null) {
      return item.editionTitle != null ? '${item.year} · ${item.editionTitle}' : '${item.year}';
    }
    return item.type;
  }

  static dynamic _tryGetClient(BuildContext context, PlexMetadata item) {
    return context.tryGetClientForServer(item.serverId);
  }
}
