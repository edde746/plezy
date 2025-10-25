import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/app_bar_back_button.dart';
import 'video_player_screen.dart';

class SeasonDetailScreen extends StatefulWidget {
  final PlexClient client;
  final PlexMetadata season;
  final PlexUserProfile? userProfile;

  const SeasonDetailScreen({
    super.key,
    required this.client,
    required this.season,
    this.userProfile,
  });

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  List<PlexMetadata> _episodes = [];
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoadingEpisodes = true;
    });

    try {
      final episodes = await widget.client.getChildren(widget.season.ratingKey);
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          DesktopSliverAppBar(
            title: Text(widget.season.title),
            pinned: true,
            leading: const AppBarBackButton(
              style: BackButtonStyle.circular,
            ),
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
                    const Icon(
                      Icons.movie_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No episodes found',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 12);
                  }
                  final episodeIndex = index ~/ 2;
                  final episode = _episodes[episodeIndex];
                  return _buildEpisodeCard(episode);
                }, childCount: _episodes.length * 2 - 1),
              ),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                client: widget.client,
                metadata: episode,
                userProfile: widget.userProfile,
              ),
            ),
          );
          // Refresh episodes when returning from video player
          _loadEpisodes();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                            ? CachedNetworkImage(
                                imageUrl: widget.client.getThumbnailUrl(
                                  episode.thumb,
                                ),
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
                                  child: const Icon(Icons.movie, size: 32),
                                ),
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

                    // Watched indicator
                    if (episode.isWatched)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
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
                            backgroundColor: Colors.grey.withValues(alpha: 0.3),
                            minHeight: 3,
                          ),
                        ),
                      ),

                    // Duration badge
                    if (episode.duration != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _formatDuration(episode.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
                          color: Colors.grey,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
