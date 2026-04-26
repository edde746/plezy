import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_server_client.dart';
import '../../../mpv/mpv.dart';
import '../../../services/download_storage_service.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/player_utils.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';
import '../../optimized_media_image.dart';

/// Bottom sheet for selecting chapters
class ChapterSheet extends StatefulWidget {
  final Player player;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final String? serverId; // Server ID for the metadata these chapters belong to
  final Function(Duration position)? onSeekCompleted;

  const ChapterSheet({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    this.serverId,
    this.onSeekCompleted,
  });

  @override
  State<ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<ChapterSheet> {
  final _firstItemKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleChapterTap(Duration position) async {
    final clamped = clampSeekPosition(widget.player, position);
    await widget.player.seek(clamped);
    if (mounted) {
      widget.onSeekCompleted?.call(clamped);
      OverlaySheetController.of(context).close();
    }
  }

  /// Get the media client for chapters, or null if unavailable (offline mode).
  MediaServerClient? _tryGetClientForChapters(BuildContext context) {
    return context.tryGetMediaClientForServer(widget.serverId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.streams.position,
      initialData: widget.player.state.position,
      builder: (context, positionSnapshot) {
        final currentPosition = positionSnapshot.data ?? Duration.zero;
        final currentChapterIndex = MediaChapter.indexAtPosition(currentPosition, widget.chapters);

        Widget content;
        if (!widget.chaptersLoaded) {
          content = const Center(child: CircularProgressIndicator());
        } else if (widget.chapters.isEmpty) {
          content = Center(
            child: Text(t.videoControls.noChaptersAvailable, style: TextStyle(color: tokens(context).textMuted)),
          );
        } else {
          if (!_didInitialScroll && currentChapterIndex != null && currentChapterIndex > 0) {
            _didInitialScroll = true;
            scrollToCurrentItem(_scrollController, _firstItemKey, currentChapterIndex);
          }

          content = ListView.builder(
            controller: _scrollController,
            itemCount: widget.chapters.length,
            itemBuilder: (context, index) {
              final chapter = widget.chapters[index];
              final isCurrentChapter = currentChapterIndex == index;

              // Get local file path for offline chapter thumbnails
              final localThumbPath = widget.serverId != null && chapter.thumb != null
                  ? DownloadStorageService.instance.getArtworkPathSync(widget.serverId!, chapter.thumb!)
                  : null;

              return FocusableListTile(
                key: index == 0 ? _firstItemKey : null,
                leading: chapter.thumb != null
                    ? SizedBox(
                        width: 60,
                        height: 34,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                              child: OptimizedMediaImage.thumb(
                                client: _tryGetClientForChapters(context),
                                imagePath: chapter.thumb,
                                localFilePath: localThumbPath,
                                width: 60,
                                height: 34,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
                              ),
                            ),
                            if (isCurrentChapter)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    border: Border.fromBorderSide(
                                      BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : null,
                title: Text(
                  chapter.label,
                  style: TextStyle(
                    color: isCurrentChapter ? Theme.of(context).colorScheme.primary : null,
                    fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  formatDurationTimestamp(chapter.startTime),
                  style: TextStyle(
                    color: isCurrentChapter
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                        : tokens(context).textMuted,
                    fontSize: 12,
                  ),
                ),
                trailing: isCurrentChapter
                    ? AppIcon(Symbols.play_circle_rounded, fill: 1, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  unawaited(_handleChapterTap(chapter.startTime));
                },
              );
            },
          );
        }

        return BaseVideoControlSheet(title: t.videoControls.chapters, icon: Symbols.bookmarks_rounded, child: content);
      },
    );
  }
}
