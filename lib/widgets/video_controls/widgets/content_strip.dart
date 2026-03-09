import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../mpv/mpv.dart';
import '../../../models/plex_media_info.dart';
import '../../../models/plex_metadata.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../services/download_storage_service.dart';
import '../../../services/plex_client.dart';
import '../../../utils/formatters.dart';
import '../../../utils/player_utils.dart';
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
  final Function(Duration position)? onSeekCompleted;

  /// Whether to use dpad/focus-based navigation (TV mode).
  /// When true, no tab bar is shown — pages are navigated via UP/DOWN.
  final bool useFocusNavigation;

  /// Called when navigating UP from the top-most strip page (back to buttons).
  final VoidCallback? onNavigateUp;

  /// Called on any focus activity (to reset auto-hide timer).
  final VoidCallback? onFocusActivity;

  const ContentStrip({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    this.serverId,
    this.showQueueTab = false,
    this.onQueueItemSelected,
    this.onSeekCompleted,
    this.useFocusNavigation = false,
    this.onNavigateUp,
    this.onFocusActivity,
  });

  @override
  State<ContentStrip> createState() => ContentStripState();
}

enum _StripTab { chapters, queue }

class ContentStripState extends State<ContentStrip> {
  late _StripTab _activeTab;
  final ScrollController _chapterScrollController = ScrollController();
  final ScrollController _queueScrollController = ScrollController();
  bool _hasAutoScrolledChapters = false;
  bool _hasAutoScrolledQueue = false;

  // Focus nodes for focus navigation mode
  final List<FocusNode> _chapterFocusNodes = [];
  final List<FocusNode> _queueFocusNodes = [];

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
    for (final node in _chapterFocusNodes) {
      node.dispose();
    }
    for (final node in _queueFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Request focus on the current chapter or queue item (called by parent when strip appears).
  void requestInitialFocus() {
    if (_activeTab == _StripTab.chapters && _chapterFocusNodes.isNotEmpty) {
      final currentIndex = _getCurrentChapterIndex();
      final idx = (currentIndex ?? 0).clamp(0, _chapterFocusNodes.length - 1);
      _chapterFocusNodes[idx].requestFocus();
      _scrollToFocusedNode(_chapterFocusNodes[idx]);
    } else if (_activeTab == _StripTab.queue && _queueFocusNodes.isNotEmpty) {
      final currentIndex = _getCurrentQueueIndex();
      final idx = (currentIndex ?? 0).clamp(0, _queueFocusNodes.length - 1);
      _queueFocusNodes[idx].requestFocus();
      _scrollToFocusedNode(_queueFocusNodes[idx]);
    }
  }

  int? _getCurrentChapterIndex() {
    final currentPositionMs = widget.player.state.position.inMilliseconds;
    for (int i = 0; i < widget.chapters.length; i++) {
      final chapter = widget.chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs =
          chapter.endTimeOffset ??
          (i < widget.chapters.length - 1 ? widget.chapters[i + 1].startTimeOffset ?? 0 : double.maxFinite.toInt());
      if (currentPositionMs >= startMs && currentPositionMs < endMs) {
        return i;
      }
    }
    return null;
  }

  Future<void> _handleChapterTap(Duration position) async {
    final clamped = clampSeekPosition(widget.player, position);
    await widget.player.seek(clamped);
    if (mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  int? _getCurrentQueueIndex() {
    try {
      final playbackState = context.read<PlaybackStateProvider>();
      final items = playbackState.loadedItems;
      final currentItemID = playbackState.currentPlayQueueItemID;
      final idx = items.indexWhere((item) => item.playQueueItemID == currentItemID);
      return idx >= 0 ? idx : null;
    } catch (_) {
      return null;
    }
  }

  void _ensureFocusNodes(List<FocusNode> nodes, int count, String prefix) {
    while (nodes.length < count) {
      nodes.add(FocusNode(debugLabel: '$prefix${nodes.length}'));
    }
    while (nodes.length > count) {
      nodes.removeLast().dispose();
    }
  }

  void _scrollToFocusedNode(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = node.context;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  KeyEventResult _handleFocusItemKeyEvent(FocusNode node, KeyEvent event, int index, int totalItems, _StripTab page) {
    if (!event.isActionable) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // LEFT/RIGHT - navigate between items
    if (key == LogicalKeyboardKey.arrowLeft) {
      final nodes = page == _StripTab.chapters ? _chapterFocusNodes : _queueFocusNodes;
      if (index > 0) {
        nodes[index - 1].requestFocus();
        _scrollToFocusedNode(nodes[index - 1]);
        widget.onFocusActivity?.call();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      final nodes = page == _StripTab.chapters ? _chapterFocusNodes : _queueFocusNodes;
      if (index < totalItems - 1) {
        nodes[index + 1].requestFocus();
        _scrollToFocusedNode(nodes[index + 1]);
        widget.onFocusActivity?.call();
      }
      return KeyEventResult.handled;
    }

    // UP - navigate to previous layer
    if (key == LogicalKeyboardKey.arrowUp) {
      if (page == _StripTab.queue && _hasChapters) {
        // Switch to chapters page and focus current chapter
        setState(() => _activeTab = _StripTab.chapters);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _chapterFocusNodes.isNotEmpty) {
            final idx = (_getCurrentChapterIndex() ?? 0).clamp(0, _chapterFocusNodes.length - 1);
            _chapterFocusNodes[idx].requestFocus();
            _scrollToFocusedNode(_chapterFocusNodes[idx]);
          }
        });
        widget.onFocusActivity?.call();
      } else {
        // chapters page (or queue without chapters) → go back to buttons
        widget.onNavigateUp?.call();
      }
      return KeyEventResult.handled;
    }

    // DOWN - navigate to next layer
    if (key == LogicalKeyboardKey.arrowDown) {
      if (page == _StripTab.chapters && _hasQueue) {
        // Switch to queue page and focus current queue item
        setState(() => _activeTab = _StripTab.queue);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _queueFocusNodes.isNotEmpty) {
            final idx = (_getCurrentQueueIndex() ?? 0).clamp(0, _queueFocusNodes.length - 1);
            _queueFocusNodes[idx].requestFocus();
            _scrollToFocusedNode(_queueFocusNodes[idx]);
          }
        });
        widget.onFocusActivity?.call();
      }
      // On queue page or chapters-only, consume to prevent bubbling
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  PlexClient? _tryGetClient(BuildContext context, String? serverId) {
    return context.tryGetClientForServer(serverId);
  }

  double _itemWidth(bool isTablet) => isTablet ? 212.0 : 132.0; // thumb + 12 padding

  void _autoScrollTo(ScrollController controller, int index, {bool force = false, bool isTablet = false}) {
    if (!controller.hasClients) return;
    final itemWidth = _itemWidth(isTablet);
    final target = (index * itemWidth - 60).clamp(0.0, controller.position.maxScrollExtent);
    if (force || (target - controller.offset).abs() > itemWidth) {
      controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final stripHeight = isTablet ? 170.0 : 106.0;
    // Add extra height for focus decoration when in focus navigation mode
    final effectiveStripHeight = widget.useFocusNavigation ? stripHeight + 16.0 : stripHeight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.useFocusNavigation ? 0 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab bar only shown in touch mode when both tabs exist
            if (_hasBothTabs && !widget.useFocusNavigation) _buildTabBar(),
            // In focus mode, show a small label for the current page
            if (widget.useFocusNavigation)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _activeTab == _StripTab.chapters ? t.videoControls.chapters : t.videoControls.queue,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            if (!widget.useFocusNavigation) const SizedBox(height: 8),
            SizedBox(
              height: effectiveStripHeight,
              child: _activeTab == _StripTab.chapters ? _buildChapterStrip(isTablet) : _buildQueueStrip(isTablet),
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
          Container(height: 2, width: 40, color: isActive ? Colors.white : Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildChapterStrip(bool isTablet) {
    final thumbWidth = isTablet ? 200.0 : 120.0;
    final thumbHeight = isTablet ? 112.0 : 68.0;

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
          final endMs =
              chapter.endTimeOffset ??
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
            _autoScrollTo(_chapterScrollController, currentChapterIndex!, isTablet: isTablet);
          });
        }

        // Ensure focus nodes for focus navigation mode
        if (widget.useFocusNavigation) {
          _ensureFocusNodes(_chapterFocusNodes, widget.chapters.length, 'ChapterFocus');
        }

        return ListView.builder(
          controller: _chapterScrollController,
          scrollDirection: Axis.horizontal,
          clipBehavior: widget.useFocusNavigation ? Clip.none : Clip.hardEdge,
          itemCount: widget.chapters.length,
          padding: EdgeInsets.symmetric(horizontal: widget.useFocusNavigation ? 12 : 4),
          itemBuilder: (context, index) {
            final chapter = widget.chapters[index];
            final isCurrent = currentChapterIndex == index;

            final localThumbPath = widget.serverId != null && chapter.thumb != null
                ? DownloadStorageService.instance.getArtworkPathSync(widget.serverId!, chapter.thumb!)
                : null;

            void onTap() => unawaited(_handleChapterTap(chapter.startTime));

            final item = _buildStripItem(
              context: context,
              isCurrent: isCurrent,
              isTablet: isTablet,
              thumbnail: chapter.thumb != null
                  ? PlexOptimizedImage.thumb(
                      client: _tryGetClient(context, widget.serverId),
                      imagePath: chapter.thumb,
                      localFilePath: localThumbPath,
                      width: thumbWidth,
                      height: thumbHeight,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
                    )
                  : null,
              title: chapter.label,
              subtitle: formatDurationTimestamp(chapter.startTime),
              onTap: onTap,
            );

            if (widget.useFocusNavigation) {
              return Align(
                alignment: Alignment.topCenter,
                child: FocusableWrapper(
                  focusNode: _chapterFocusNodes[index],
                  onSelect: onTap,
                  onKeyEvent: (node, event) =>
                      _handleFocusItemKeyEvent(node, event, index, widget.chapters.length, _StripTab.chapters),
                  onFocusChange: (hasFocus) {
                    if (hasFocus) widget.onFocusActivity?.call();
                  },
                  borderRadius: 6,
                  autoScroll: false,
                  useBackgroundFocus: true,
                  child: item,
                ),
              );
            }

            return item;
          },
        );
      },
    );
  }

  Widget _buildQueueStrip(bool isTablet) {
    final thumbWidth = isTablet ? 200.0 : 120.0;
    final thumbHeight = isTablet ? 112.0 : 68.0;

    return Consumer<PlaybackStateProvider>(
      builder: (context, playbackState, _) {
        final items = playbackState.loadedItems;
        final currentItemID = playbackState.currentPlayQueueItemID;
        final currentIndex = items.indexWhere((item) => item.playQueueItemID == currentItemID);

        if (!_hasAutoScrolledQueue && currentIndex >= 0) {
          _hasAutoScrolledQueue = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoScrollTo(_queueScrollController, currentIndex, isTablet: isTablet);
          });
        }

        // Ensure focus nodes for focus navigation mode
        if (widget.useFocusNavigation) {
          _ensureFocusNodes(_queueFocusNodes, items.length, 'QueueFocus');
        }

        return ListView.builder(
          controller: _queueScrollController,
          scrollDirection: Axis.horizontal,
          clipBehavior: widget.useFocusNavigation ? Clip.none : Clip.hardEdge,
          itemCount: items.length,
          padding: EdgeInsets.symmetric(horizontal: widget.useFocusNavigation ? 12 : 4),
          itemBuilder: (context, index) {
            final item = items[index];
            final isCurrent = item.playQueueItemID == currentItemID;

            PlexClient? client;
            if (item.serverId != null) {
              try {
                client = context.tryGetClientForServer(item.serverId);
              } catch (_) {}
            }

            void onTap() => widget.onQueueItemSelected?.call(item);

            final stripItem = _buildStripItem(
              context: context,
              isCurrent: isCurrent,
              isTablet: isTablet,
              thumbnail: item.thumb != null
                  ? PlexOptimizedImage.thumb(
                      client: client,
                      imagePath: item.thumb,
                      width: thumbWidth,
                      height: thumbHeight,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
                    )
                  : null,
              title: item.title,
              subtitle: _buildQueueSubtitle(item),
              onTap: onTap,
            );

            if (widget.useFocusNavigation) {
              return Align(
                alignment: Alignment.topCenter,
                child: FocusableWrapper(
                  focusNode: _queueFocusNodes[index],
                  onSelect: onTap,
                  onKeyEvent: (node, event) =>
                      _handleFocusItemKeyEvent(node, event, index, items.length, _StripTab.queue),
                  onFocusChange: (hasFocus) {
                    if (hasFocus) widget.onFocusActivity?.call();
                  },
                  borderRadius: 6,
                  autoScroll: false,
                  useBackgroundFocus: true,
                  child: stripItem,
                ),
              );
            }

            return stripItem;
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
    if (item.year != null) return item.editionTitle != null ? '${item.year} · ${item.editionTitle}' : '${item.year}';
    return item.type;
  }

  Widget _buildStripItem({
    required BuildContext context,
    required bool isCurrent,
    required Widget? thumbnail,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isTablet = false,
  }) {
    final itemWidth = isTablet ? 200.0 : 120.0;
    final thumbHeight = isTablet ? 112.0 : 68.0;
    final titleFontSize = isTablet ? 13.0 : 11.0;
    final subtitleFontSize = isTablet ? 12.0 : 10.0;

    final verticalMargin = widget.useFocusNavigation ? 4.0 : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: itemWidth,
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: verticalMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              width: itemWidth,
              height: thumbHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child:
                        thumbnail ??
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
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
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
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: isCurrent ? Colors.white70 : Colors.white60,
                fontSize: subtitleFontSize,
                fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
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
