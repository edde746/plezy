import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import '../../../models/plex_media_info.dart';
import '../../../providers/plex_client_provider.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for selecting chapters
class ChapterSheet extends StatelessWidget {
  final Player player;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;

  const ChapterSheet({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
  });

  static void show(
    BuildContext context,
    Player player,
    List<PlexChapter> chapters,
    bool chaptersLoaded,
  ) {
    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) => ChapterSheet(
        player: player,
        chapters: chapters,
        chaptersLoaded: chaptersLoaded,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, positionSnapshot) {
        final currentPosition = positionSnapshot.data ?? Duration.zero;
        final currentPositionMs = currentPosition.inMilliseconds;

        // Find the current chapter based on position
        int? currentChapterIndex;
        for (int i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          final startMs = chapter.startTimeOffset ?? 0;
          final endMs = chapter.endTimeOffset ??
              (i < chapters.length - 1
                  ? chapters[i + 1].startTimeOffset ?? 0
                  : double.maxFinite.toInt());

          if (currentPositionMs >= startMs && currentPositionMs < endMs) {
            currentChapterIndex = i;
            break;
          }
        }

        Widget content;
        if (!chaptersLoaded) {
          content = const Center(child: CircularProgressIndicator());
        } else if (chapters.isEmpty) {
          content = const Center(
            child: Text(
              'No chapters available',
              style: TextStyle(color: Colors.white70),
            ),
          );
        } else {
          content = ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final isCurrentChapter = currentChapterIndex == index;

              return ListTile(
                leading: chapter.thumb != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Consumer<PlexClientProvider>(
                              builder: (context, clientProvider, child) {
                                final client = clientProvider.client;
                                if (client == null) {
                                  return const Icon(
                                    Icons.image,
                                    color: Colors.white54,
                                    size: 34,
                                  );
                                }
                                return Image.network(
                                  client.getThumbnailUrl(
                                    chapter.thumb,
                                  ),
                                  width: 60,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) =>
                                      const Icon(
                                    Icons.image,
                                    color: Colors.white54,
                                    size: 34,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (isCurrentChapter)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    4,
                                  ),
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
                  _formatDuration(chapter.startTime),
                  style: TextStyle(
                    color: isCurrentChapter
                        ? Colors.blue.withValues(alpha: 0.7)
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing: isCurrentChapter
                    ? const Icon(
                        Icons.play_circle_filled,
                        color: Colors.blue,
                      )
                    : null,
                onTap: () {
                  player.seek(chapter.startTime);
                  Navigator.pop(context);
                },
              );
            },
          );
        }

        return BaseVideoControlSheet(
          title: 'Chapters',
          icon: Icons.video_library,
          child: content,
        );
      },
    );
  }
}
