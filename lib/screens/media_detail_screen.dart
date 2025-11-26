import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../mixins/keyboard_long_press_mixin.dart';
import '../widgets/focus/focus_indicator.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/playback_state_provider.dart';
import '../theme/theme_helper.dart';
import '../utils/app_logger.dart';
import '../utils/content_rating_formatter.dart';
import '../utils/duration_formatter.dart';
import '../utils/keyboard_utils.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
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
  final FocusNode _playButtonFocusNode = FocusNode(debugLabel: 'PlayButton');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadFullMetadata();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playButtonFocusNode.dispose();
    super.dispose();
  }

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId!);
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      // Fetch full metadata with clearLogo and OnDeck episode
      final result = await client.getMetadataWithImagesAndOnDeck(
        widget.metadata.ratingKey,
      );
      final metadata = result['metadata'] as PlexMetadata?;
      final onDeckEpisode = result['onDeckEpisode'] as PlexMetadata?;

      if (metadata != null) {
        // Preserve serverId from original metadata
        final metadataWithServerId = metadata.copyWith(
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );
        final onDeckWithServerId = onDeckEpisode?.copyWith(
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );

        setState(() {
          _fullMetadata = metadataWithServerId;
          _onDeckEpisode = onDeckWithServerId;
          _isLoadingMetadata = false;
        });

        // Focus the play button after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playButtonFocusNode.requestFocus();
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

      // Focus the play button after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playButtonFocusNode.requestFocus();
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

      // Focus the play button after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playButtonFocusNode.requestFocus();
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
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      final seasons = await client.getChildren(widget.metadata.ratingKey);
      // Preserve serverId for each season
      final seasonsWithServerId = seasons
          .map(
            (season) => season.copyWith(
              serverId: widget.metadata.serverId,
              serverName: widget.metadata.serverName,
            ),
          )
          .toList();
      setState(() {
        _seasons = seasonsWithServerId;
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
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      final metadata = await client.getMetadataWithImages(
        widget.metadata.ratingKey,
      );

      if (metadata != null) {
        // Preserve serverId from original metadata
        final metadataWithServerId = metadata.copyWith(
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );

        // For shows, also refetch seasons to update their watch counts
        List<PlexMetadata>? updatedSeasons;
        if (metadata.type.toLowerCase() == 'show') {
          final seasons = await client.getChildren(widget.metadata.ratingKey);
          // Preserve serverId for each season
          updatedSeasons = seasons
              .map(
                (season) => season.copyWith(
                  serverId: widget.metadata.serverId,
                  serverName: widget.metadata.serverName,
                ),
              )
              .toList();
        }

        // Single setState to minimize rebuilds - scroll position is preserved by controller
        setState(() {
          _fullMetadata = metadataWithServerId;
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
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

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
          ).showSnackBar(SnackBar(content: Text(t.messages.noSeasonsFound)));
        }
        return;
      }

      // Get the first season (usually Season 1, but could be Season 0 for specials)
      final firstSeason = _seasons.first;

      // Get episodes of the first season
      final episodes = await client.getChildren(firstSeason.ratingKey);

      if (episodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.messages.noEpisodesFound)));
        }
        return;
      }

      // Play the first episode
      final firstEpisode = episodes.first;
      // Preserve serverId for the episode
      final episodeWithServerId = firstEpisode.copyWith(
        serverId: widget.metadata.serverId,
        serverName: widget.metadata.serverName,
      );
      if (mounted) {
        // Client already retrieved earlier in the method
        appLogger.d('Playing first episode: ${episodeWithServerId.title}');
        await navigateToVideoPlayer(context, metadata: episodeWithServerId);
        appLogger.d('Returned from playback, refreshing metadata');
        // Refresh metadata when returning from video player
        _loadFullMetadata();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
    }
  }

  /// Handle shuffle play using play queues
  Future<void> _handleShufflePlayWithQueue(
    BuildContext context,
    PlexMetadata metadata,
  ) async {
    final client = _getClientForMetadata(context);

    final playbackState = context.read<PlaybackStateProvider>();
    final itemType = metadata.type.toLowerCase();

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Determine the rating key for the play queue
      String showRatingKey;
      if (itemType == 'show') {
        showRatingKey = metadata.ratingKey;
      } else if (itemType == 'season') {
        // For seasons, we need the show's rating key
        // The season's parentRatingKey should point to the show
        if (metadata.parentRatingKey == null) {
          throw Exception('Season is missing parentRatingKey');
        }
        showRatingKey = metadata.parentRatingKey!;
      } else {
        throw Exception('Shuffle play only works for shows and seasons');
      }

      // Create a shuffled play queue for the show
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 1,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (playQueue == null ||
          playQueue.items == null ||
          playQueue.items!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.messages.noEpisodesFound)));
        }
        return;
      }

      // Initialize playback state with the play queue
      await playbackState.setPlaybackFromPlayQueue(
        playQueue,
        showRatingKey,
        serverId: metadata.serverId,
        serverName: metadata.serverName,
      );

      // Set the client for the playback state provider
      playbackState.setClient(client);

      // Navigate to the first episode in the shuffled queue
      final firstEpisode = playQueue.items!.first.copyWith(
        serverId: metadata.serverId,
        serverName: metadata.serverName,
      );

      if (context.mounted) {
        await navigateToVideoPlayer(context, metadata: firstEpisode);
        // Refresh metadata when returning from video player
        _loadFullMetadata();
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (isBackKeyEvent(event)) {
            Navigator.pop(context, _watchStateChanged);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: CustomScrollView(
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
                      Builder(
                        builder: (context) {
                          final client = _getClientForMetadata(context);
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
                                  child: Builder(
                                    builder: (context) {
                                      final client = _getClientForMetadata(
                                        context,
                                      );
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
                                                  color: Colors.white
                                                      .withValues(alpha: 0.3),
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
                                        formatDurationTextual(
                                          metadata.duration!,
                                        ),
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
                              focusNode: _playButtonFocusNode,
                              onPressed: () async {
                                // For TV shows, play the OnDeck episode if available
                                // Otherwise, play the first episode of the first season
                                if (metadata.type.toLowerCase() == 'show') {
                                  if (_onDeckEpisode != null) {
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
                              await _handleShufflePlayWithQueue(
                                context,
                                metadata,
                              );
                            },
                            icon: const Icon(Icons.shuffle),
                            tooltip: t.tooltips.shufflePlay,
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
                              final client = _getClientForMetadata(context);

                              await client.markAsWatched(metadata.ratingKey);
                              if (context.mounted) {
                                _watchStateChanged = true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t.messages.markedAsWatched),
                                  ),
                                );
                                // Update watch state without full rebuild
                                _updateWatchState();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.messages.errorLoading(
                                        error: e.toString(),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check),
                          tooltip: t.tooltips.markAsWatched,
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
                              final client = _getClientForMetadata(context);

                              await client.markAsUnwatched(metadata.ratingKey);
                              if (context.mounted) {
                                _watchStateChanged = true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t.messages.markedAsUnwatched),
                                  ),
                                );
                                // Update watch state without full rebuild
                                _updateWatchState();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.messages.errorLoading(
                                        error: e.toString(),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.remove_done),
                          tooltip: t.tooltips.markAsUnwatched,
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
                        t.discover.overview,
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
                        t.discover.seasons,
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
                              t.messages.noSeasonsFound,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        FocusTraversalGroup(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _seasons.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final season = _seasons[index];
                              return _FocusableSeasonCard(
                                season: season,
                                client: _getClientForMetadata(context),
                                onTap: () async {
                                  final watchStateChanged =
                                      await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SeasonDetailScreen(
                                                season: season,
                                              ),
                                        ),
                                      );
                                  if (watchStateChanged == true) {
                                    _watchStateChanged = true;
                                    _updateWatchState();
                                  }
                                },
                                onRefresh: () {
                                  _watchStateChanged = true;
                                  _updateWatchState();
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Cast
                    if (metadata.role != null && metadata.role!.isNotEmpty) ...[
                      Text(
                        t.discover.cast,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: HorizontalScrollWithArrows(
                          builder: (scrollController) => ListView.separated(
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: metadata.role!.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final actor = metadata.role![index];
                              return SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: actor.thumb != null
                                          ? CachedNetworkImage(
                                              imageUrl: actor.thumb!,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: const Center(
                                                      child: Icon(Icons.person),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: const Center(
                                                      child: Icon(Icons.person),
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              width: 120,
                                              height: 120,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Center(
                                                child: Icon(Icons.person),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 84,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            actor.tag,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (actor.role != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              actor.role!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Additional info
                    if (metadata.studio != null) ...[
                      _buildInfoRow(t.discover.studio, metadata.studio!),
                      const SizedBox(height: 12),
                    ],
                    if (metadata.contentRating != null) ...[
                      _buildInfoRow(
                        t.discover.rating,
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

  String _getPlayButtonLabel(PlexMetadata metadata) {
    // For TV shows
    if (metadata.type.toLowerCase() == 'show') {
      if (_onDeckEpisode != null) {
        final episode = _onDeckEpisode!;
        final seasonNum = episode.parentIndex ?? 0;
        final episodeNum = episode.index ?? 0;

        // Check if episode has been partially watched (viewOffset > 0)
        if (episode.viewOffset != null && episode.viewOffset! > 0) {
          return t.discover.resumeEpisode(
            season: seasonNum.toString(),
            episode: episodeNum.toString(),
          );
        } else {
          return t.discover.playEpisode(
            season: seasonNum.toString(),
            episode: episodeNum.toString(),
          );
        }
      } else {
        // No on deck episode, will play first episode
        return t.discover.playEpisode(season: '1', episode: '1');
      }
    }

    // For movies or episodes, check if partially watched
    if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
      return t.discover.resume;
    }

    return t.discover.play;
  }
}

/// Focusable season card widget
class _FocusableSeasonCard extends StatefulWidget {
  final PlexMetadata season;
  final PlexClient client;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _FocusableSeasonCard({
    required this.season,
    required this.client,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<_FocusableSeasonCard> createState() => _FocusableSeasonCardState();
}

class _FocusableSeasonCardState extends State<_FocusableSeasonCard>
    with KeyboardLongPressMixin {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  @override
  void onKeyboardTap() => widget.onTap();

  @override
  void onKeyboardLongPress() {
    _contextMenuKey.currentState?.showContextMenu(context);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Handle long-press detection for activation keys
    return handleKeyboardLongPress(event);
  }

  @override
  Widget build(BuildContext context) {
    final season = widget.season;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: FocusIndicator(
        isFocused: _isFocused,
        borderRadius: 12,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: MediaContextMenu(
            key: _contextMenuKey,
            item: season,
            onRefresh: (ratingKey) => widget.onRefresh(),
            onTap: widget.onTap,
            child: Semantics(
              label: "media-season-${season.ratingKey}",
              identifier: "media-season-${season.ratingKey}",
              button: true,
              hint: "Tap to view ${season.title}",
              child: InkWell(
                onTap: widget.onTap,
                focusColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Season poster
                      if (season.thumb != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: widget.client.getThumbnailUrl(
                              season.thumb,
                            ),
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
                                t.discover.episodeCount(
                                  count: season.leafCount.toString(),
                                ),
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
                                        backgroundColor: tokens(
                                          context,
                                        ).outline,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.discover.watchedProgress(
                                      watched: season.viewedLeafCount
                                          .toString(),
                                      total: season.leafCount.toString(),
                                    ),
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
        ),
      ),
    );
  }
}
