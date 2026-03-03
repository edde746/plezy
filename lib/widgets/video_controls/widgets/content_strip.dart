import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../mpv/mpv.dart';
import '../../../models/plex_media_info.dart';
import '../../../models/plex_metadata.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../services/download_storage_service.dart';
import '../../../services/plex_client.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/provider_extensions.dart';
import '../../app_icon.dart';
import '../../plex_optimized_image.dart';

/// Horizontal scrollable strip of chapter/queue items shown on swipe-up.
class ContentStrip extends StatefulWidget {
  final Player player;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final String? serverId;
  final bool showQueueTab;
  final Function(PlexMetadata)? onQueueItemSelected;

  const ContentStrip({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    this.serverId,
    this.showQueueTab = false,
    this.onQueueItemSelected,
  });

  @override
  State<ContentStrip> createState() => _ContentStripState();
}

enum _StripTab { chapters, queue }

class _ContentStripState extends State<ContentStrip> {
  late _StripTab _activeTab;
  final ScrollController _chapterScrollController = ScrollController();
  final ScrollController _queueScrollController = ScrollController();
  bool _hasAutoScrolledChapters = false;
  bool _hasAutoScrolledQueue = false;

  bool get _hasChapters => widget.chapters.isNotEmpty;
  bool get _hasQueue => widget.showQueueTab && widget.onQueueItemSelected != null;
  bool get _hasBothTabs => _hasChapters && _hasQueue;

  @override
  void initState() {
    super.initState();
    _activeTab = _hasChapters ? _StripTab.chapters : _StripTab.queue;
  }

  @override
  void dispose() {
    _chapterScrollController.dispose();
    _queueScrollController.dispose();
    super.dispose();
  }

  PlexClient? _tryGetClient(BuildContext context, String? serverId) {
    if (serverId == null) return null;
    try {
      return context.getClientForServer(serverId);
    } catch (_) {
      return null;
    }
  }

  void _autoScrollTo(ScrollController controller, int index, {bool force = false}) {
    if (!controller.hasClients) return;
    const itemWidth = 132.0; // 120 thumb + 12 padding
    final target = (index * itemWidth - 60).clamp(0.0, controller.position.maxScrollExtent);
    if (force || (target - controller.offset).abs() > itemWidth) {
      controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasBothTabs) _buildTabBar(),
            const SizedBox(height: 8),
            SizedBox(
              height: 106,
              child: _activeTab == _StripTab.chapters ? _buildChapterStrip() : _buildQueueStrip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabLabel(t.videoControls.chapters, _StripTab.chapters),
        const SizedBox(width: 24),
        _buildTabLabel(t.videoControls.queue, _StripTab.queue),
      ],
    );
  }

  Widget _buildTabLabel(String label, _StripTab tab) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildChapterStrip() {
    return StreamBuilder<Duration>(
      stream: widget.player.streams.position,
      initialData: widget.player.state.position,
      builder: (context, positionSnapshot) {
        final currentPosition = positionSnapshot.data ?? Duration.zero;
        final currentPositionMs = currentPosition.inMilliseconds;

        int? currentChapterIndex;
        for (int i = 0; i < widget.chapters.length; i++) {
          final chapter = widget.chapters[i];
          final startMs = chapter.startTimeOffset ?? 0;
          final endMs = chapter.endTimeOffset ??
              (i < widget.chapters.length - 1 ? widget.chapters[i + 1].startTimeOffset ?? 0 : double.maxFinite.toInt());
          if (currentPositionMs >= startMs && currentPositionMs < endMs) {
            currentChapterIndex = i;
            break;
          }
        }

        // Auto-scroll to current chapter on first build
        if (!_hasAutoScrolledChapters && currentChapterIndex != null) {
          _hasAutoScrolledChapters = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoScrollTo(_chapterScrollController, currentChapterIndex!);
          });
        }

        return ListView.builder(
          controller: _chapterScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.chapters.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final chapter = widget.chapters[index];
            final isCurrent = currentChapterIndex == index;

            final localThumbPath = widget.serverId != null && chapter.thumb != null
                ? DownloadStorageService.instance.getArtworkPathSync(widget.serverId!, chapter.thumb!)
                : null;

            return _buildStripItem(
              context: context,
              isCurrent: isCurrent,
              thumbnail: chapter.thumb != null
                  ? PlexOptimizedImage.thumb(
                      client: _tryGetClient(context, widget.serverId),
                      imagePath: chapter.thumb,
                      localFilePath: localThumbPath,
                      width: 120,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
                    )
                  : null,
              title: chapter.label,
              subtitle: formatDurationTimestamp(chapter.startTime),
              onTap: () => widget.player.seek(chapter.startTime),
            );
          },
        );
      },
    );
  }

  Widget _buildQueueStrip() {
    return Consumer<PlaybackStateProvider>(
      builder: (context, playbackState, _) {
        final items = playbackState.loadedItems;
        final currentItemID = playbackState.currentPlayQueueItemID;
        final currentIndex = items.indexWhere((item) => item.playQueueItemID == currentItemID);

        if (!_hasAutoScrolledQueue && currentIndex >= 0) {
          _hasAutoScrolledQueue = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoScrollTo(_queueScrollController, currentIndex);
          });
        }

        return ListView.builder(
          controller: _queueScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final item = items[index];
            final isCurrent = item.playQueueItemID == currentItemID;

            PlexClient? client;
            if (item.serverId != null) {
              try {
                client = context.getClientForServer(item.serverId!);
              } catch (_) {}
            }

            return _buildStripItem(
              context: context,
              isCurrent: isCurrent,
              thumbnail: item.thumb != null
                  ? PlexOptimizedImage.thumb(
                      client: client,
                      imagePath: item.thumb,
                      width: 120,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
                    )
                  : null,
              title: item.title,
              subtitle: _buildQueueSubtitle(item),
              onTap: () => widget.onQueueItemSelected?.call(item),
            );
          },
        );
      },
    );
  }

  String _buildQueueSubtitle(PlexMetadata item) {
    if (item.grandparentTitle != null && item.parentIndex != null && item.index != null) {
      return '${item.grandparentTitle} \u00b7 S${item.parentIndex}E${item.index}';
    }
    if (item.grandparentTitle != null) return item.grandparentTitle!;
    if (item.year != null) return '${item.year}';
    return item.type;
  }

  Widget _buildStripItem({
    required BuildContext context,
    required bool isCurrent,
    required Widget? thumbnail,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              width: 120,
              height: 68,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: thumbnail ??
                        Container(
                          color: Colors.white10,
                          child: const Center(
                            child: AppIcon(Symbols.movie_rounded, fill: 1, color: Colors.white38, size: 28),
                          ),
                        ),
                  ),
                  if (isCurrent)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                          border: Border.fromBorderSide(BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              title,
              style: TextStyle(
                color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.white,
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: isCurrent ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7) : tokens(context).textMuted,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
