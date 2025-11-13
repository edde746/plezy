import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import '../../../models/plex_media_info.dart';
import '../../../providers/plex_client_provider.dart';

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

  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  static void show(
    BuildContext context,
    Player player,
    List<PlexChapter> chapters,
    bool chaptersLoaded,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
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
          final endMs =
              chapter.endTimeOffset ??
              (i < chapters.length - 1
                  ? chapters[i + 1].startTimeOffset ?? 0
                  : double.maxFinite.toInt());

          if (currentPositionMs >= startMs && currentPositionMs < endMs) {
            currentChapterIndex = i;
            break;
          }
        }

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.video_library, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Chapters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                if (!chaptersLoaded)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (chapters.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No chapters available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
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
                                        builder:
                                            (context, clientProvider, child) {
                                              final client =
                                                  clientProvider.client;
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
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
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
                              color: isCurrentChapter
                                  ? Colors.blue
                                  : Colors.white,
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
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
