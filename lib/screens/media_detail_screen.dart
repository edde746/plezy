import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../theme/theme_helper.dart';
import '../utils/app_logger.dart';
import '../utils/content_rating_formatter.dart';
import '../utils/provider_extensions.dart';
import '../utils/shuffle_play_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/media_context_menu.dart';
import 'season_detail_screen.dart';

class MediaDetailScreen extends StatefulWidget {
  final PlexMetadata metadata;

  const MediaDetailScreen({super.key, required this.metadata});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  List<PlexMetadata> _seasons = [];
  bool _isLoadingSeasons = false;
  PlexMetadata? _fullMetadata;
  PlexMetadata? _onDeckEpisode;
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

      // Fetch full metadata with clearLogo and OnDeck episode
      final result = await client.getMetadataWithImagesAndOnDeck(
        widget.metadata.ratingKey,
      );
      final metadata = result['metadata'] as PlexMetadata?;
      final onDeckEpisode = result['onDeckEpisode'] as PlexMetadata?;

      if (metadata != null) {
        setState(() {
          _fullMetadata = metadata;
          _onDeckEpisode = onDeckEpisode;
          _isLoadingMetadata = false;
        });

        // Load seasons if it's a show
        if (metadata.type.toLowerCase() == 'show') {
          _loadSeasons();
        }
        return;
      }

      // Fallback to passed metadata
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.type.toLowerCase() == 'show') {
        _loadSeasons();
      }
    } catch (e) {
      // Fallback to passed metadata on error
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.type.toLowerCase() == 'show') {
        _loadSeasons();
      }
    }
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoadingSeasons = true;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final seasons = await client.getChildren(widget.metadata.ratingKey);
      setState(() {
        _seasons = seasons;
        _isLoadingSeasons = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSeasons = false;
      });
    }
  }

  /// Update watch state without full screen rebuild
  /// This preserves scroll position and only updates watch-related data
  Future<void> _updateWatchState() async {
    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      final metadata = await client.getMetadataWithImages(
        widget.metadata.ratingKey,
      );

      if (metadata != null) {
        // For shows, also refetch seasons to update their watch counts
        List<PlexMetadata>? updatedSeasons;
        if (metadata.type.toLowerCase() == 'show') {
          updatedSeasons = await client.getChildren(widget.metadata.ratingKey);
        }

        // Single setState to minimize rebuilds - scroll position is preserved by controller
        setState(() {
          _fullMetadata = metadata;
          if (updatedSeasons != null) {
            _seasons = updatedSeasons;
          }
        });
      }
    } catch (e) {
      appLogger.e('Failed to update watch state', error: e);
      // Silently fail - user can manually refresh if needed
    }
  }

  Future<void> _playFirstEpisode() async {
    try {
      // Extract context dependencies before async operations
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      // If seasons aren't loaded yet, wait for them or load them
      if (_seasons.isEmpty && !_isLoadingSeasons) {
        await _loadSeasons();
      }

      // Wait for seasons to finish loading if they're currently loading
      while (_isLoadingSeasons) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (_seasons.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No seasons found')));
        }
        return;
      }

      // Get the first season (usually Season 1, but could be Season 0 for specials)
      final firstSeason = _seasons.first;

      // Get episodes of the first season
      final episodes = await client.getChildren(firstSeason.ratingKey);

      if (episodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No episodes found in first season')),
          );
        }
        return;
      }

      // Play the first episode
      final firstEpisode = episodes.first;
      if (mounted) {
        final clientProvider = context.plexClient;
        final client = clientProvider.client;
        if (client == null) return;

        appLogger.d('Playing first episode: ${firstEpisode.title}');
        await navigateToVideoPlayer(context, metadata: firstEpisode);
        appLogger.d('Returned from playback, refreshing metadata');
        // Refresh metadata when returning from video player
        _loadFullMetadata();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading first episode: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use full metadata if loaded, otherwise use passed metadata
    final metadata = _fullMetadata ?? widget.metadata;
    final isShow = metadata.type.toLowerCase() == 'show';

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

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero header with background art
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
                  // Background Art
                  if (metadata.art != null)
                    Consumer<PlexClientProvider>(
                      builder: (context, clientProvider, child) {
                        final client = clientProvider.client;
                        if (client == null) {
                          return Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: client.getThumbnailUrl(metadata.art),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
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
                            // Clear logo or title
                            if (metadata.clearLogo != null)
                              SizedBox(
                                height: 120,
                                width: 400,
                                child: Consumer<PlexClientProvider>(
                                  builder: (context, clientProvider, child) {
                                    final client = clientProvider.client;
                                    if (client == null) {
                                      return Text(
                                        metadata.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      );
                                    }
                                    return CachedNetworkImage(
                                      imageUrl: client.getThumbnailUrl(
                                        metadata.clearLogo,
                                      ),
                                      filterQuality: FilterQuality.medium,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerLeft,
                                      placeholder: (context, url) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          metadata.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            metadata.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              )
                            else
                              Text(
                                metadata.title,
                                style: Theme.of(context).textTheme.displaySmall
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
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
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
                                if (metadata.contentRating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      formatContentRating(
                                        metadata.contentRating!,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (metadata.duration != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatDuration(metadata.duration!),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (metadata.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(metadata.rating! * 10).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (metadata.audienceRating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(metadata.audienceRating! * 10).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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
                            onPressed: () async {
                              // For TV shows, play the OnDeck episode if available
                              // Otherwise, play the first episode of the first season
                              if (metadata.type.toLowerCase() == 'show') {
                                if (_onDeckEpisode != null) {
                                  final clientProvider = context.plexClient;
                                  final client = clientProvider.client;
                                  if (client == null) return;

                                  appLogger.d(
                                    'Playing on deck episode: ${_onDeckEpisode!.title}',
                                  );
                                  await navigateToVideoPlayer(
                                    context,
                                    metadata: _onDeckEpisode!,
                                  );
                                  appLogger.d(
                                    'Returned from playback, refreshing metadata',
                                  );
                                  // Refresh metadata when returning from video player
                                  _loadFullMetadata();
                                } else {
                                  // No on deck episode, fetch first episode of first season
                                  await _playFirstEpisode();
                                }
                              } else {
                                final clientProvider = context.plexClient;
                                final client = clientProvider.client;
                                if (client == null) return;

                                appLogger.d('Playing: ${metadata.title}');
                                // For movies or episodes, play directly
                                await navigateToVideoPlayer(
                                  context,
                                  metadata: metadata,
                                );
                                appLogger.d(
                                  'Returned from playback, refreshing metadata',
                                );
                                // Refresh metadata when returning from video player
                                _loadFullMetadata();
                              }
                            },
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              _getPlayButtonLabel(metadata),
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Shuffle button (only for shows and seasons)
                      if (metadata.type.toLowerCase() == 'show' ||
                          metadata.type.toLowerCase() == 'season') ...[
                        IconButton.filledTonal(
                          onPressed: () async {
                            await handleShufflePlay(context, metadata);
                          },
                          icon: const Icon(Icons.shuffle),
                          tooltip: 'Shuffle play',
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            maximumSize: const Size(48, 48),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
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
                                  content: Text('Marked as watched'),
                                ),
                              );
                              // Update watch state without full rebuild
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
                        tooltip: 'Mark as watched',
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
                                  content: Text('Marked as unwatched'),
                                ),
                              );
                              // Update watch state without full rebuild
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
                        tooltip: 'Mark as unwatched',
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          maximumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  if (metadata.summary != null) ...[
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      metadata.summary!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Seasons (for TV shows)
                  if (isShow) ...[
                    Text(
                      'Seasons',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingSeasons)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_seasons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No seasons found',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _seasons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final season = _seasons[index];
                          return _buildSeasonCard(season);
                        },
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Additional info
                  if (metadata.studio != null) ...[
                    _buildInfoRow('Studio', metadata.studio!),
                    const SizedBox(height: 12),
                  ],
                  if (metadata.contentRating != null) ...[
                    _buildInfoRow(
                      'Rating',
                      formatContentRating(metadata.contentRating!),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard(PlexMetadata season) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: MediaContextMenu(
        metadata: season,
        onRefresh: (ratingKey) {
          _watchStateChanged = true;
          _updateWatchState();
        },
        onTap: () async {
          final watchStateChanged = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => SeasonDetailScreen(season: season),
            ),
          );
          if (watchStateChanged == true) {
            _watchStateChanged = true;
            _updateWatchState();
          }
        },
        child: Semantics(
          label: "media-season-${season.ratingKey}",
          identifier: "media-season-${season.ratingKey}",
          button: true,
          hint: "Tap to view ${season.title}",
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Season poster
                  if (season.thumb != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Consumer<PlexClientProvider>(
                        builder: (context, clientProvider, child) {
                          final client = clientProvider.client;
                          if (client == null) {
                            return Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.movie, size: 32),
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl: client.getThumbnailUrl(season.thumb),
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.movie, size: 32),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.movie, size: 32),
                    ),
                  const SizedBox(width: 16),

                  // Season info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (season.leafCount != null)
                          Text(
                            '${season.leafCount} episodes',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        const SizedBox(height: 8),
                        if (season.viewedLeafCount != null &&
                            season.leafCount != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        season.viewedLeafCount! /
                                        season.leafCount!,
                                    backgroundColor: tokens(context).outline,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${season.viewedLeafCount}/${season.leafCount} watched',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
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

  String _getPlayButtonLabel(PlexMetadata metadata) {
    // For TV shows
    if (metadata.type.toLowerCase() == 'show') {
      if (_onDeckEpisode != null) {
        final episode = _onDeckEpisode!;
        final seasonNum = episode.parentIndex ?? 0;
        final episodeNum = episode.index ?? 0;

        // Check if episode has been partially watched (viewOffset > 0)
        if (episode.viewOffset != null && episode.viewOffset! > 0) {
          return 'Resume S$seasonNum, E$episodeNum';
        } else {
          return 'Play S$seasonNum, E$episodeNum';
        }
      } else {
        // No on deck episode, will play first episode
        return 'Play S1, E1';
      }
    }

    // For movies or episodes, check if partially watched
    if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
      return 'Resume';
    }

    return 'Play';
  }
}
