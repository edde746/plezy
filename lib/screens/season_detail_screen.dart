import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/duration_formatter.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/media_context_menu.dart';
import '../mixins/item_updatable.dart';
import '../theme/theme_helper.dart';
import '../i18n/strings.g.dart';

class SeasonDetailScreen extends StatefulWidget {
  final PlexMetadata season;

  const SeasonDetailScreen({super.key, required this.season});

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen>
    with ItemUpdatable {
  late final PlexClient _client;

  @override
  PlexClient get client => _client;

  List<PlexMetadata> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _watchStateChanged = false;

  /// Get the correct PlexClient for this season's server
  PlexClient _getClientForSeason(BuildContext context) {
    return context.getClientForServer(widget.season.serverId!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize the client once in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _client = _getClientForSeason(context);
      _loadEpisodes();
    });
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoadingEpisodes = true;
    });

    try {
      // Episodes are automatically tagged with server info by PlexClient
      final episodes = await _client.getChildren(widget.season.ratingKey);

      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEpisodes = false;
      });
    }
  }

  @override
  Future<void> updateItem(String ratingKey) async {
    _watchStateChanged = true;
    await super.updateItem(ratingKey);
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _episodes.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _episodes[index] = updatedMetadata;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(widget.season.title),
            pinned: true,
            onBackPressed: () => Navigator.pop(context, _watchStateChanged),
          ),
          if (_isLoadingEpisodes)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_episodes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_outlined,
                      size: 64,
                      color: tokens(context).textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.messages.noEpisodesFoundGeneral,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final episode = _episodes[index];
                return _buildEpisodeCard(episode);
              }, childCount: _episodes.length),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(PlexMetadata episode) {
    final hasProgress =
        episode.viewOffset != null &&
        episode.duration != null &&
        episode.viewOffset! > 0;
    final progress = hasProgress
        ? episode.viewOffset! / episode.duration!
        : 0.0;

    return MediaContextMenu(
      item: episode,
      onRefresh: updateItem,
      onTap: () async {
        await navigateToVideoPlayer(context, metadata: episode);
        // Refresh episodes when returning from video player
        _loadEpisodes();
      },
      child: InkWell(
        key: Key(episode.ratingKey),
        hoverColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: tokens(context).outline, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode thumbnail (16:9 aspect ratio, fixed width)
              SizedBox(
                width: 160,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: episode.thumb != null
                            ? Builder(
                                builder: (context) {
                                  return CachedNetworkImage(
                                    imageUrl: _client.getThumbnailUrl(
                                      episode.thumb,
                                    ),
                                    filterQuality: FilterQuality.medium,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.movie,
                                            size: 32,
                                          ),
                                        ),
                                  );
                                },
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.movie, size: 32),
                              ),
                      ),
                    ),

                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Progress bar at bottom
                    if (hasProgress && !episode.isWatched)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: tokens(context).outline,
                            minHeight: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Episode number and title
                    Row(
                      children: [
                        if (episode.index != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'E${episode.index}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            episode.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Summary
                    if (episode.summary != null &&
                        episode.summary!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        episode.summary!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Metadata row (duration, watched status)
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (episode.duration != null)
                          Text(
                            formatDurationTimestamp(
                              Duration(milliseconds: episode.duration!),
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: tokens(context).textMuted,
                                  fontSize: 12,
                                ),
                          ),
                        if (episode.duration != null && episode.isWatched) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: tokens(context).textMuted,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                          Text(
                            '${t.discover.watched} ✓',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: tokens(context).textMuted,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
