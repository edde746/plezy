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

/// Bottom sheet for viewing and navigating the play queue
class QueueSheet extends StatelessWidget {
  final Function(PlexMetadata) onItemSelected;

  const QueueSheet({super.key, required this.onItemSelected});

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
          // Find current index for initial scroll
          final currentIndex = items.indexWhere((item) => item.playQueueItemID == currentItemID);

          content = ListView.builder(
            controller: currentIndex > 0 ? ScrollController(initialScrollOffset: currentIndex * 56.0) : null,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrent = item.playQueueItemID == currentItemID;

              return FocusableListTile(
                leading: _buildThumbnail(context, item, isCurrent),
                title: Text(
                  item.title,
                  style: TextStyle(
                    color: isCurrent ? Colors.blue : null,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _buildSubtitle(item),
                  style: TextStyle(
                    color: isCurrent ? Colors.blue.withValues(alpha: 0.7) : tokens(context).textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isCurrent
                    ? const AppIcon(Symbols.play_circle_rounded, fill: 1, color: Colors.blue)
                    : null,
                onTap: () {
                  onItemSelected(item);
                  OverlaySheetController.of(context).close();
                },
              );
            },
          );
        }

        return BaseVideoControlSheet(
          title: t.videoControls.queue,
          icon: Symbols.queue_music_rounded,
          child: content,
        );
      },
    );
  }

  Widget? _buildThumbnail(BuildContext context, PlexMetadata item, bool isCurrent) {
    if (item.thumb == null) return null;

    // Try to get client for thumbnails, may fail in offline mode
    final client = _tryGetClient(context, item);

    return SizedBox(
      width: 60,
      height: 34,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: PlexOptimizedImage.thumb(
              client: client,
              imagePath: item.thumb,
              width: 60,
              height: 34,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
            ),
          ),
          if (isCurrent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  border: const Border.fromBorderSide(BorderSide(color: Colors.blue, width: 2)),
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
      return '${item.year}';
    }
    return item.type;
  }

  static dynamic _tryGetClient(BuildContext context, PlexMetadata item) {
    if (item.serverId == null) return null;
    try {
      return context.getClientForServer(item.serverId!);
    } catch (_) {
      return null;
    }
  }
}
