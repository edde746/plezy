import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../client/plex_client.dart';
import '../providers/plex_client_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/media_context_menu.dart';
import '../mixins/item_updatable.dart';
import '../theme/theme_helper.dart';
import '../utils/audiobook_player_navigation.dart';

/// Detail screen for an audiobook (album level)
///
/// Shows book metadata and chapter list.
/// Chapters are represented as tracks in the Plex structure.
class AudiobookDetailScreen extends StatefulWidget {
  final PlexMetadata book;

  const AudiobookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<AudiobookDetailScreen> createState() => _AudiobookDetailScreenState();
}

class _AudiobookDetailScreenState extends State<AudiobookDetailScreen>
    with ItemUpdatable {
  @override
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _chapters = [];
  bool _isLoadingChapters = false;
  PlexMetadata? _fullMetadata;
  bool _isLoadingMetadata = true;
  late final ScrollController _scrollController;
  bool _watchStateChanged = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadFullMetadata();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      // Fetch full metadata
      final metadata = await client.getMetadataWithImages(
        widget.book.ratingKey,
      );

      if (metadata != null) {
        setState(() {
          _fullMetadata = metadata;
          _isLoadingMetadata = false;
        });

        // Load chapters (tracks)
        _loadChapters();
        return;
      }

      // Fallback to passed metadata
      setState(() {
        _fullMetadata = widget.book;
        _isLoadingMetadata = false;
      });

      _loadChapters();
    } catch (e) {
      // Fallback to passed metadata on error
      setState(() {
        _fullMetadata = widget.book;
        _isLoadingMetadata = false;
      });

      _loadChapters();
    }
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoadingChapters = true;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final chapters = await client.getChildren(widget.book.ratingKey);
      setState(() {
        _chapters = chapters;
        _isLoadingChapters = false;
      });
    } catch (e) {
      appLogger.e('Failed to load chapters', error: e);
      setState(() {
        _isLoadingChapters = false;
      });
    }
  }

  /// Update watch state without full screen rebuild
  Future<void> _updateWatchState() async {
    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final metadata = await client.getMetadataWithImages(
        widget.book.ratingKey,
      );

      if (metadata != null) {
        // Also refetch chapters to update their watch counts
        final updatedChapters = await client.getChildren(widget.book.ratingKey);

        setState(() {
          _fullMetadata = metadata;
          _chapters = updatedChapters;
        });
      }
    } catch (e) {
      appLogger.e('Failed to update watch state', error: e);
    }
  }

  Future<void> _playFirstChapter() async {
    if (_chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No chapters found')),
        );
      }
      return;
    }

    // Find the first unfinished chapter or first chapter with progress
    int startIndex = 0;
    for (int i = 0; i < _chapters.length; i++) {
      if (_chapters[i].viewOffset != null && _chapters[i].viewOffset! > 0) {
        if (!_chapters[i].isWatched) {
          // Found a chapter with progress that's not finished
          startIndex = i;
          break;
        }
      }
    }

    // Navigate to audiobook player with full playlist
    final result = await navigateToAudiobookPlayer(
      context,
      metadata: _chapters[startIndex],
      playlist: _chapters,
      initialIndex: startIndex,
    );

    // Refresh if playback occurred
    if (result == true && mounted) {
      _watchStateChanged = true;
      _updateWatchState();
    }
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _chapters.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _chapters[index] = updatedMetadata;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = _fullMetadata ?? widget.book;

    // Show loading state while fetching full metadata
    if (_isLoadingMetadata) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine header height based on screen size
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final headerHeight = isDesktop ? size.height * 0.6 : size.height * 0.4;

    // Calculate total duration from chapters
    int totalDuration = 0;
    for (final chapter in _chapters) {
      totalDuration += chapter.duration ?? 0;
    }

    // Calculate progress
    int totalProgress = 0;
    for (final chapter in _chapters) {
      totalProgress += chapter.viewOffset ?? 0;
    }
    final hasProgress = totalProgress > 0;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero header with book cover
          DesktopSliverAppBar(
            expandedHeight: headerHeight,
            pinned: true,
            leading: AppBarBackButton(
              style: BackButtonStyle.circular,
              onPressed: () => Navigator.pop(context, _watchStateChanged),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Art (use thumb as background for audiobooks)
                  if (metadata.thumb != null)
                    Consumer<PlexClientProvider>(
                      builder: (context, clientProvider, child) {
                        final client = clientProvider.client;
                        if (client == null) {
                          return Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: client.getThumbnailUrl(metadata.thumb),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Content at bottom
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Book icon
                            const Icon(
                              Icons.headphones,
                              color: Colors.white70,
                              size: 32,
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              metadata.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Author (grandparent title)
                            if (metadata.grandparentTitle != null)
                              Text(
                                'By ${metadata.grandparentTitle}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Metadata chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (metadata.year != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${metadata.year}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (totalDuration > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatDuration(totalDuration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (_chapters.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_chapters.length} chapter${_chapters.length != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _playFirstChapter,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              hasProgress ? 'Resume' : 'Play',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () async {
                          try {
                            final clientProvider = context.plexClient;
                            final client = clientProvider.client;
                            if (client == null) return;

                            await client.markAsWatched(metadata.ratingKey);
                            if (context.mounted) {
                              _watchStateChanged = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked as listened'),
                                ),
                              );
                              _updateWatchState();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check),
                        tooltip: 'Mark as listened',
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          maximumSize: const Size(48, 48),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () async {
                          try {
                            final clientProvider = context.plexClient;
                            final client = clientProvider.client;
                            if (client == null) return;

                            await client.markAsUnwatched(metadata.ratingKey);
                            if (context.mounted) {
                              _watchStateChanged = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked as unlistened'),
                                ),
                              );
                              _updateWatchState();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.remove_done),
                        tooltip: 'Mark as unlistened',
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          maximumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress indicator
                  if (hasProgress && totalDuration > 0) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalProgress / totalDuration,
                            backgroundColor: tokens(context).outline,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDuration(totalProgress)} of ${_formatDuration(totalDuration)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: tokens(context).textMuted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Summary
                  if (metadata.summary != null && metadata.summary!.isNotEmpty) ...[
                    Text(
                      'About this audiobook',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      metadata.summary!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Chapters
                  Text(
                    'Chapters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingChapters)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_chapters.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No chapters found',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _chapters.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        return _buildChapterCard(chapter);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(PlexMetadata chapter) {
    final hasProgress = chapter.viewOffset != null &&
        chapter.duration != null &&
        chapter.viewOffset! > 0;
    final progress = hasProgress ? chapter.viewOffset! / chapter.duration! : 0.0;

    return MediaContextMenu(
      metadata: chapter,
      onRefresh: (ratingKey) {
        _watchStateChanged = true;
        _updateWatchState();
      },
      onTap: () async {
        // Find the index of this chapter
        final chapterIndex = _chapters.indexWhere(
          (c) => c.ratingKey == chapter.ratingKey,
        );

        // Navigate to audiobook player
        final result = await navigateToAudiobookPlayer(
          context,
          metadata: chapter,
          playlist: _chapters,
          initialIndex: chapterIndex >= 0 ? chapterIndex : 0,
        );

        // Refresh if playback occurred
        if (result == true && mounted) {
          _watchStateChanged = true;
          _updateWatchState();
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: "chapter-${chapter.ratingKey}",
          identifier: "chapter-${chapter.ratingKey}",
          button: true,
          hint: "Tap to play ${chapter.title}",
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Chapter number badge
                  if (chapter.index != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${chapter.index}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.headphones, size: 20),
                    ),
                  const SizedBox(width: 16),

                  // Chapter info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasProgress && !chapter.isWatched) ...[
                              // Show progress time when chapter has progress
                              Text(
                                '${_formatDuration(chapter.viewOffset!)} / ${_formatDuration(chapter.duration!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
                              ),
                            ] else if (chapter.duration != null) ...[
                              // Show total duration for unstarted chapters
                              Text(
                                _formatDuration(chapter.duration!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: tokens(context).textMuted),
                              ),
                            ],
                            if (chapter.duration != null && chapter.isWatched) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: tokens(context).textMuted),
                                ),
                              ),
                              Text(
                                'Listened ✓',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: tokens(context).textMuted),
                              ),
                            ],
                          ],
                        ),
                        if (hasProgress && !chapter.isWatched) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: tokens(context).outline,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  const Icon(Icons.play_arrow, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
