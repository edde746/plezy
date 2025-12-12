import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../services/plex_client.dart';
import '../../../services/download_storage_service.dart';
import '../../../models/plex_media_info.dart';
import '../../../utils/duration_formatter.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/focusable_bottom_sheet.dart';
import '../../../widgets/focusable_list_tile.dart';
import 'base_video_control_sheet.dart';
import 'video_control_sheet_launcher.dart';
import '../../plex_optimized_image.dart';

/// Bottom sheet for selecting chapters
class ChapterSheet extends StatefulWidget {
  final Player player;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final String? serverId; // Server ID for the metadata these chapters belong to

  const ChapterSheet({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    this.serverId,
  });

  static void show(
    BuildContext context,
    Player player,
    List<PlexChapter> chapters,
    bool chaptersLoaded, {
    String? serverId,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    VideoControlSheetLauncher.show(
      context: context,
      onOpen: onOpen,
      onClose: onClose,
      builder: (context) => ChapterSheet(
        player: player,
        chapters: chapters,
        chaptersLoaded: chaptersLoaded,
        serverId: serverId,
      ),
    );
  }

  @override
  State<ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<ChapterSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'ChapterSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  /// Get the PlexClient for chapters, or null if unavailable (offline mode)
  PlexClient? _tryGetClientForChapters(BuildContext context) {
    if (widget.serverId == null) return null;
    try {
      return context.getClientForServer(widget.serverId!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: StreamBuilder<Duration>(
        stream: widget.player.streams.position,
        initialData: widget.player.state.position,
        builder: (context, positionSnapshot) {
          final currentPosition = positionSnapshot.data ?? Duration.zero;
          final currentPositionMs = currentPosition.inMilliseconds;

          // Find the current chapter based on position
          int? currentChapterIndex;
          for (int i = 0; i < widget.chapters.length; i++) {
            final chapter = widget.chapters[i];
            final startMs = chapter.startTimeOffset ?? 0;
            final endMs =
                chapter.endTimeOffset ??
                (i < widget.chapters.length - 1
                    ? widget.chapters[i + 1].startTimeOffset ?? 0
                    : double.maxFinite.toInt());

            if (currentPositionMs >= startMs && currentPositionMs < endMs) {
              currentChapterIndex = i;
              break;
            }
          }

          Widget content;
          if (!widget.chaptersLoaded) {
            content = const Center(child: CircularProgressIndicator());
          } else if (widget.chapters.isEmpty) {
            content = const Center(
              child: Text(
                'No chapters available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          } else {
            content = ListView.builder(
              itemCount: widget.chapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.chapters[index];
                final isCurrentChapter = currentChapterIndex == index;

                // Get local file path for offline chapter thumbnails
                final localThumbPath =
                    widget.serverId != null && chapter.thumb != null
                    ? DownloadStorageService.instance.getArtworkPathSync(
                        widget.serverId!,
                        chapter.thumb!,
                      )
                    : null;

                return FocusableListTile(
                  focusNode: index == 0 ? _initialFocusNode : null,
                  leading: chapter.thumb != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: PlexOptimizedImage.thumb(
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
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : null,
                  title: Text(
                    chapter.label,
                    style: TextStyle(
                      color: isCurrentChapter ? Colors.blue : Colors.white,
                      fontWeight: isCurrentChapter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    formatDurationTimestamp(chapter.startTime),
                    style: TextStyle(
                      color: isCurrentChapter
                          ? Colors.blue.withValues(alpha: 0.7)
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isCurrentChapter
                      ? const AppIcon(Symbols.play_circle_rounded, fill: 1, color: Colors.blue)
                      : null,
                  onTap: () {
                    widget.player.seek(chapter.startTime);
                    Navigator.pop(context);
                  },
                );
              },
            );
          }

          return BaseVideoControlSheet(
            title: 'Chapters',
            icon: Symbols.video_library_rounded,
            child: content,
          );
        },
      ),
    );
  }
}
