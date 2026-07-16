import 'package:flutter/material.dart';
import '../../../media/ids.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_item.dart';
import '../../../media/media_item_labels.dart';
import '../../../media/media_item_types.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../services/settings_service.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../widgets/settings_builder.dart';
import '../widgets/media_selector_thumbnail.dart';
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
  final _initialScroll = InitialItemScrollController();

  @override
  void dispose() {
    _initialScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingValueBuilder<bool>(
      pref: SettingsService.hideSpoilers,
      builder: (context, hideSpoilers, _) => Consumer<PlaybackStateProvider>(
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
            _initialScroll.maybeScrollTo(currentIndex);

            content = ListView.builder(
              controller: _initialScroll.controller,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrent = playbackState.playQueueItemIdFor(item) == currentItemID;

                final primaryColor = Theme.of(context).colorScheme.primary;
                return FocusableListTile(
                  key: index == 0 ? _initialScroll.firstItemKey : null,
                  leading: _buildThumbnail(context, item, isCurrent, hideSpoilers: hideSpoilers),
                  title: Text(
                    item.title ?? '',
                    style: TextStyle(
                      color: isCurrent ? primaryColor : null,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: Text(
                    formatQueueItemSubtitle(item),
                    style: TextStyle(
                      color: isCurrent ? primaryColor.withValues(alpha: 0.7) : tokens(context).textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
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
      ),
    );
  }

  Widget? _buildThumbnail(BuildContext context, MediaItem item, bool isCurrent, {required bool hideSpoilers}) {
    if (item.thumbPath == null) return null;

    // Try to get client for thumbnails, may fail in offline mode
    final client = context.tryGetMediaClientForServer(serverIdOrNull(item.serverId));

    return MediaSelectorThumbnail(
      width: _kThumbWidth,
      height: _kThumbHeight,
      thumbnail: OptimizedMediaImage.thumb(
        client: client,
        imagePath: item.thumbPath,
        width: _kThumbWidth,
        height: _kThumbHeight,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: _kThumbHeight),
      ),
      isCurrent: isCurrent,
      borderColor: Theme.of(context).colorScheme.primary,
      blurThumbnail: hideSpoilers && item.shouldHideSpoiler,
    );
  }
}
