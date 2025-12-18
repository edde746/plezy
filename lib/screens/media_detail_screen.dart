import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/key_event_utils.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../widgets/plex_optimized_image.dart';
import '../utils/plex_image_helper.dart';
import '../../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../models/download_models.dart';
import '../providers/playback_state_provider.dart';
import '../providers/download_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/app_bar_back_button.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_card.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/placeholder_container.dart';
import 'season_detail_screen.dart';

class MediaDetailScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final bool isOffline;

  const MediaDetailScreen({super.key, required this.metadata, this.isOffline = false});

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
  final ScrollController _seasonsScrollController = ScrollController();
  bool _watchStateChanged = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadFullMetadata();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _seasonsScrollController.dispose();
    super.dispose();
  }

  /// Build title text widget for clear logo fallback
  Widget _buildTitleText(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build radial progress indicator for download button
  /// If progressPercent is null or 0, shows indeterminate spinner
  Widget _buildRadialProgress(double? progressPercent) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle (only show if we have determinate progress)
          if (progressPercent != null && progressPercent > 0)
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
          // Progress circle (indeterminate if no progress, determinate otherwise)
          CircularProgressIndicator(
            value: (progressPercent != null && progressPercent > 0) ? progressPercent : null, // null = indeterminate
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  /// Build action buttons row (play, shuffle, download, mark watched)
  Widget _buildActionButtons(PlexMetadata metadata) {
    final playButtonLabel = _getPlayButtonLabel(metadata);
    final playButtonIcon = AppIcon(_getPlayButtonIcon(metadata), fill: 1, size: 20);

    Future<void> onPlayPressed() async {
      // For TV shows, play the OnDeck episode if available
      // Otherwise, play the first episode of the first season
      if (metadata.isShow) {
        if (_onDeckEpisode != null) {
          appLogger.d('Playing on deck episode: ${_onDeckEpisode!.title}');
          await navigateToVideoPlayerWithRefresh(
            context,
            metadata: _onDeckEpisode!,
            isOffline: widget.isOffline,
            onRefresh: _loadFullMetadata,
          );
        } else {
          // No on deck episode, fetch first episode of first season
          await _playFirstEpisode();
        }
      } else {
        appLogger.d('Playing: ${metadata.title}');
        // For movies or episodes, play directly
        await navigateToVideoPlayerWithRefresh(
          context,
          metadata: metadata,
          isOffline: widget.isOffline,
          onRefresh: _loadFullMetadata,
        );
      }
    }

    return Row(
      children: [
        SizedBox(
          height: 48,
          child: FilledButton(
            autofocus: InputModeTracker.isKeyboardMode(context),
            onPressed: onPlayPressed,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: playButtonLabel.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      playButtonIcon,
                      const SizedBox(width: 8),
                      Text(playButtonLabel, style: const TextStyle(fontSize: 16)),
                    ],
                  )
                : playButtonIcon,
          ),
        ),
        const SizedBox(width: 12),
        // Shuffle button (only for shows and seasons)
        if (metadata.isShow || metadata.isSeason) ...[
          IconButton.filledTonal(
            onPressed: () async {
              await _handleShufflePlayWithQueue(context, metadata);
            },
            icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
            tooltip: t.tooltips.shufflePlay,
            iconSize: 20,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
          ),
          const SizedBox(width: 12),
        ],
        // Download button (hide in offline mode - already downloaded)
        if (!widget.isOffline)
          Consumer<DownloadProvider>(
            builder: (context, downloadProvider, _) {
              final globalKey = '${metadata.serverId}:${metadata.ratingKey}';
              final progress = downloadProvider.getProgress(globalKey);
              final isQueueing = downloadProvider.isQueueing(globalKey);

              // Debug logging
              if (progress != null) {
                appLogger.d('UI rebuilding for $globalKey: status=${progress.status}, progress=${progress.progress}%');
              }

              // State 1: Queueing (building download queue)
              if (isQueueing) {
                return IconButton.filledTonal(
                  onPressed: null,
                  icon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  iconSize: 20,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
                );
              }

              // State 2: Queued (waiting to download)
              if (progress?.status == DownloadStatus.queued) {
                final currentFile = progress?.currentFile;
                final tooltip = currentFile != null && currentFile.contains('episodes')
                    ? 'Queued $currentFile'
                    : 'Queued';

                return IconButton.filledTonal(
                  onPressed: null,
                  tooltip: tooltip,
                  icon: const AppIcon(Symbols.schedule_rounded, fill: 1),
                  iconSize: 20,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
                );
              }

              // State 3: Downloading (active download)
              if (progress?.status == DownloadStatus.downloading) {
                // Show episode count in tooltip for shows/seasons
                final currentFile = progress?.currentFile;
                final tooltip = currentFile != null && currentFile.contains('episodes')
                    ? 'Downloading $currentFile'
                    : 'Downloading...';

                return IconButton.filledTonal(
                  onPressed: null,
                  tooltip: tooltip,
                  icon: _buildRadialProgress(progress?.progressPercent),
                  iconSize: 20,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
                );
              }

              // State 4: Paused (can resume)
              if (progress?.status == DownloadStatus.paused) {
                return IconButton.filledTonal(
                  onPressed: () async {
                    final client = _getClientForMetadata(context);
                    if (client == null) return;
                    await downloadProvider.resumeDownload(globalKey, client);
                    if (context.mounted) {
                      showAppSnackBar(context, 'Download resumed');
                    }
                  },
                  icon: const AppIcon(Symbols.pause_circle_outline_rounded, fill: 1),
                  tooltip: 'Resume download',
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    foregroundColor: Colors.amber,
                  ),
                );
              }

              // State 5: Failed (can retry)
              if (progress?.status == DownloadStatus.failed) {
                return IconButton.filledTonal(
                  onPressed: () async {
                    final client = _getClientForMetadata(context);
                    if (client == null) return;

                    // Delete failed download and retry
                    await downloadProvider.deleteDownload(globalKey);
                    try {
                      await downloadProvider.queueDownload(metadata, client);

                      if (context.mounted) {
                        showSuccessSnackBar(context, t.downloads.downloadQueued);
                      }
                    } on CellularDownloadBlockedException {
                      if (context.mounted) {
                        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                      }
                    }
                  },
                  icon: const AppIcon(Symbols.error_outline_rounded, fill: 1),
                  tooltip: 'Retry download',
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    foregroundColor: Colors.red,
                  ),
                );
              }

              // State 6: Cancelled (can delete or retry)
              if (progress?.status == DownloadStatus.cancelled) {
                return IconButton.filledTonal(
                  onPressed: () async {
                    // Show options: Delete or Retry
                    final action = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancelled Download'),
                        content: const Text('This download was cancelled. What would you like to do?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, 'delete'), child: Text(t.common.delete)),
                          TextButton(onPressed: () => Navigator.pop(context, 'retry'), child: const Text('Retry')),
                        ],
                      ),
                    );

                    if (action == 'delete' && context.mounted) {
                      await downloadProvider.deleteDownload(globalKey);
                      if (context.mounted) {
                        showSuccessSnackBar(context, t.downloads.downloadDeleted);
                      }
                    } else if (action == 'retry' && context.mounted) {
                      final client = _getClientForMetadata(context);
                      if (client == null) return;
                      await downloadProvider.deleteDownload(globalKey);
                      try {
                        await downloadProvider.queueDownload(metadata, client);
                        if (context.mounted) {
                          showSuccessSnackBar(context, t.downloads.downloadQueued);
                        }
                      } on CellularDownloadBlockedException {
                        if (context.mounted) {
                          showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                        }
                      }
                    }
                  },
                  icon: const AppIcon(Symbols.cancel_rounded, fill: 1),
                  tooltip: 'Cancelled download',
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    foregroundColor: Colors.grey,
                  ),
                );
              }

              // State 7: Partial Download (some episodes downloaded, not all)
              if (progress?.status == DownloadStatus.partial) {
                final currentFile = progress?.currentFile;
                final tooltip = currentFile != null
                    ? 'Downloaded $currentFile - Click to complete'
                    : 'Partially downloaded - Click to complete';

                return IconButton.filledTonal(
                  onPressed: () async {
                    final client = _getClientForMetadata(context);
                    if (client == null) return;

                    // Queue only the missing episodes
                    final count = await downloadProvider.queueMissingEpisodes(metadata, client);

                    if (context.mounted) {
                      final message = count > 0
                          ? t.downloads.episodesQueued(count: count)
                          : 'All episodes already downloaded';
                      showAppSnackBar(context, message);
                    }
                  },
                  tooltip: tooltip,
                  icon: const AppIcon(Symbols.downloading_rounded, fill: 1),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    foregroundColor: Colors.orange,
                  ),
                );
              }

              // State 8: Downloaded/Completed (can delete)
              if (downloadProvider.isDownloaded(globalKey)) {
                return IconButton.filledTonal(
                  onPressed: () async {
                    // Show delete download confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(t.downloads.deleteDownload),
                        content: Text(t.downloads.deleteConfirm(title: metadata.title)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text(t.common.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await downloadProvider.deleteDownload(globalKey);
                      if (context.mounted) {
                        showSuccessSnackBar(context, t.downloads.downloadDeleted);
                      }
                    }
                  },
                  icon: const AppIcon(Symbols.file_download_done_rounded, fill: 1),
                  tooltip: t.downloads.deleteDownload,
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    foregroundColor: Colors.green,
                  ),
                );
              }

              // State 9: Not downloaded (default - can download)
              return IconButton.filledTonal(
                onPressed: () async {
                  final client = _getClientForMetadata(context);
                  if (client == null) return;
                  final count = await downloadProvider.queueDownload(metadata, client);
                  if (context.mounted) {
                    final message = count > 1 ? t.downloads.episodesQueued(count: count) : t.downloads.downloadQueued;
                    showSuccessSnackBar(context, message);
                  }
                },
                icon: const AppIcon(Symbols.download_rounded, fill: 1),
                tooltip: t.downloads.downloadNow,
                iconSize: 20,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
              );
            },
          ),
        const SizedBox(width: 12),
        // Mark as watched/unwatched toggle (works offline too)
        IconButton.filledTonal(
          onPressed: () async {
            try {
              final isWatched = metadata.isWatched;
              if (widget.isOffline) {
                // Offline mode: queue action for later sync
                final offlineWatch = context.read<OfflineWatchProvider>();
                if (isWatched) {
                  await offlineWatch.markAsUnwatched(serverId: metadata.serverId!, ratingKey: metadata.ratingKey);
                } else {
                  await offlineWatch.markAsWatched(serverId: metadata.serverId!, ratingKey: metadata.ratingKey);
                }
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    isWatched ? t.messages.markedAsUnwatchedOffline : t.messages.markedAsWatchedOffline,
                  );
                  // Refresh offline OnDeck
                  _loadOfflineOnDeckEpisode();
                }
              } else {
                // Online mode: send to server
                final client = _getClientForMetadata(context);
                if (client == null) return;

                if (isWatched) {
                  await client.markAsUnwatched(metadata.ratingKey);
                } else {
                  await client.markAsWatched(metadata.ratingKey);
                }
                if (context.mounted) {
                  _watchStateChanged = true;
                  showSuccessSnackBar(context, isWatched ? t.messages.markedAsUnwatched : t.messages.markedAsWatched);
                  // Update watch state without full rebuild
                  _updateWatchState();
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
              }
            }
          },
          icon: AppIcon(metadata.isWatched ? Symbols.remove_done_rounded : Symbols.check_rounded, fill: 1),
          tooltip: metadata.isWatched ? t.tooltips.markAsUnwatched : t.tooltips.markAsWatched,
          iconSize: 20,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48), maximumSize: const Size(48, 48)),
        ),
      ],
    );
  }

  /// Build a metadata chip with optional leading icon
  Widget _buildMetadataChip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(100),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(icon, fill: 1, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 16),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  /// Get the correct PlexClient for this metadata's server
  /// Returns null in offline mode or if serverId is null
  PlexClient? _getClientForMetadata(BuildContext context) {
    if (widget.isOffline || widget.metadata.serverId == null) {
      return null;
    }
    return context.getClientForServer(widget.metadata.serverId!);
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    // Offline mode: use passed metadata directly, load seasons from downloads
    if (widget.isOffline) {
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
        _loadSeasonsFromDownloads();
        // Get offline OnDeck episode
        _loadOfflineOnDeckEpisode();
      }
      return;
    }

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);
      if (client == null) {
        // No client available, use passed metadata
        setState(() {
          _fullMetadata = widget.metadata;
          _isLoadingMetadata = false;
        });
        return;
      }

      // Fetch full metadata with clearLogo and OnDeck episode
      final result = await client.getMetadataWithImagesAndOnDeck(widget.metadata.ratingKey);
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

        // Load seasons if it's a show
        if (metadata.isShow) {
          _loadSeasons();
        }
        return;
      }

      // Fallback to passed metadata
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
        _loadSeasons();
      }
    } catch (e) {
      // Fallback to passed metadata on error
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
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

      final seasons = await client?.getChildren(widget.metadata.ratingKey) ?? [];
      // Preserve serverId for each season
      final seasonsWithServerId = seasons
          .map((season) => season.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName))
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

  /// Load seasons from downloaded episodes (offline mode)
  void _loadSeasonsFromDownloads() {
    setState(() {
      _isLoadingSeasons = true;
    });

    final downloadProvider = context.read<DownloadProvider>();
    final episodes = downloadProvider.getDownloadedEpisodesForShow(widget.metadata.ratingKey);

    // Group episodes by season
    final Map<int, List<PlexMetadata>> seasonMap = {};
    for (final episode in episodes) {
      final seasonNum = episode.parentIndex ?? 0;
      seasonMap.putIfAbsent(seasonNum, () => []).add(episode);
    }

    // Create season metadata from episodes
    final seasons = seasonMap.entries.map((entry) {
      final firstEp = entry.value.first;
      return PlexMetadata(
        ratingKey: firstEp.parentRatingKey ?? '',
        key: '/library/metadata/${firstEp.parentRatingKey}',
        type: 'season',
        title: firstEp.parentTitle ?? 'Season ${entry.key}',
        index: entry.key,
        thumb: firstEp.parentThumb,
        parentRatingKey: firstEp.grandparentRatingKey,
        serverId: widget.metadata.serverId,
        serverName: widget.metadata.serverName,
      );
    }).toList()..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    setState(() {
      _seasons = seasons;
      _isLoadingSeasons = false;
    });
  }

  /// Navigate to a season detail screen
  Future<void> _navigateToSeason(PlexMetadata season) async {
    final watchStateChanged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SeasonDetailScreen(season: season, isOffline: widget.isOffline),
      ),
    );
    if (watchStateChanged == true) {
      _watchStateChanged = true;
      _updateWatchState();
    }
  }

  /// Build horizontal seasons list for larger screens (>=600px)
  Widget _buildHorizontalSeasons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth >= 1400
        ? 220.0
        : screenWidth >= 900
        ? 200.0
        : screenWidth >= 700
        ? 190.0
        : 160.0;
    final posterHeight = (cardWidth - 16) * 1.5;
    final containerHeight = posterHeight + 66;

    return SizedBox(
      height: containerHeight,
      child: HorizontalScrollWithArrows(
        controller: _seasonsScrollController,
        builder: (scrollController) => ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 5),
          itemCount: _seasons.length,
          itemBuilder: (context, index) {
            final season = _seasons[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FocusableMediaCard(
                item: season,
                width: cardWidth,
                height: posterHeight,
                forceGridMode: true,
                isOffline: widget.isOffline,
                onRefresh: (_) {
                  _watchStateChanged = true;
                  _updateWatchState();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build vertical seasons list for smaller screens (<600px)
  Widget _buildVerticalSeasons() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _seasons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final season = _seasons[index];
        // Look up each season's artwork, not the show's
        String? seasonPosterPath;
        if (widget.isOffline && season.serverId != null) {
          seasonPosterPath = context.read<DownloadProvider>().getArtworkLocalPath(season.serverId!, season.thumb);
        }
        return _SeasonCard(
          season: season,
          client: _getClientForMetadata(context),
          isOffline: widget.isOffline,
          localPosterPath: seasonPosterPath,
          onTap: () => _navigateToSeason(season),
          onRefresh: () {
            _watchStateChanged = true;
            _updateWatchState();
          },
        );
      },
    );
  }

  /// Load the next unwatched episode for offline mode (offline OnDeck)
  Future<void> _loadOfflineOnDeckEpisode() async {
    final offlineWatchProvider = context.read<OfflineWatchProvider>();
    final nextEpisode = await offlineWatchProvider.getNextUnwatchedEpisode(widget.metadata.ratingKey);

    if (nextEpisode != null && mounted) {
      setState(() {
        _onDeckEpisode = nextEpisode;
      });
      appLogger.d('Offline OnDeck: S${nextEpisode.parentIndex}E${nextEpisode.index} - ${nextEpisode.title}');
    }
  }

  /// Update watch state without full screen rebuild
  /// This preserves scroll position and only updates watch-related data
  Future<void> _updateWatchState() async {
    // Skip in offline mode
    if (widget.isOffline) return;

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);
      if (client == null) return;

      final metadata = await client.getMetadataWithImages(widget.metadata.ratingKey);

      if (metadata != null) {
        // Preserve serverId from original metadata
        final metadataWithServerId = metadata.copyWith(
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );

        // For shows, also refetch seasons to update their watch counts
        List<PlexMetadata>? updatedSeasons;
        if (metadata.isShow) {
          final seasons = await client.getChildren(widget.metadata.ratingKey);
          // Preserve serverId for each season
          updatedSeasons = seasons
              .map(
                (season) => season.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName),
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
      // If seasons aren't loaded yet, wait for them or load them
      if (_seasons.isEmpty && !_isLoadingSeasons) {
        if (widget.isOffline) {
          _loadSeasonsFromDownloads();
        } else {
          await _loadSeasons();
        }
      }

      // Wait for seasons to finish loading if they're currently loading
      while (_isLoadingSeasons) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      if (_seasons.isEmpty) {
        if (mounted) {
          showErrorSnackBar(context, t.messages.noSeasonsFound);
        }
        return;
      }

      // Get the first season (usually Season 1, but could be Season 0 for specials)
      final firstSeason = _seasons.first;

      // Get episodes of the first season
      List<PlexMetadata> episodes;
      if (!mounted) return;
      if (widget.isOffline) {
        // In offline mode, get episodes from downloads
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(widget.metadata.ratingKey);
        // Filter to episodes of this season
        episodes = allEpisodes.where((ep) => ep.parentIndex == firstSeason.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
      } else {
        final client = _getClientForMetadata(context);
        if (client == null) return;
        episodes = await client.getChildren(firstSeason.ratingKey);
      }

      if (episodes.isEmpty) {
        if (mounted) {
          showErrorSnackBar(context, t.messages.noEpisodesFound);
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
        appLogger.d('Playing first episode: ${episodeWithServerId.title}');
        await navigateToVideoPlayerWithRefresh(
          context,
          metadata: episodeWithServerId,
          isOffline: widget.isOffline,
          onRefresh: _loadFullMetadata,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle shuffle play using play queues
  /// Note: Shuffle requires server connectivity (play queue API)
  Future<void> _handleShufflePlayWithQueue(BuildContext context, PlexMetadata metadata) async {
    // Shuffle requires server connectivity
    if (widget.isOffline) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Shuffle not available offline');
      }
      return;
    }

    final client = _getClientForMetadata(context);
    if (client == null) return;

    final playbackState = context.read<PlaybackStateProvider>();

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Determine the rating key for the play queue
      String showRatingKey;
      if (metadata.isShow) {
        showRatingKey = metadata.ratingKey;
      } else if (metadata.isSeason) {
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
      final playQueue = await client.createShowPlayQueue(showRatingKey: showRatingKey, shuffle: 1);

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (playQueue == null || playQueue.items == null || playQueue.items!.isEmpty) {
        if (context.mounted) {
          showErrorSnackBar(context, t.messages.noEpisodesFound);
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
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use full metadata if loaded, otherwise use passed metadata
    final metadata = _fullMetadata ?? widget.metadata;
    final isShow = metadata.isShow;

    KeyEventResult handleBack(FocusNode _, KeyEvent event) =>
        handleBackKeyNavigation(context, event, result: _watchStateChanged);

    // Show loading state while fetching full metadata
    if (_isLoadingMetadata) {
      return Focus(
        onKeyEvent: handleBack,
        child: Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Determine header height based on screen size
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.6;

    return Focus(
      onKeyEvent: handleBack,
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero header with background art
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Background Art (fixed height, no parallax)
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: metadata.art != null
                            ? Builder(
                                builder: (context) {
                                  // Check for offline local file first
                                  if (widget.isOffline && widget.metadata.serverId != null) {
                                    final localPath = context.read<DownloadProvider>().getArtworkLocalPath(
                                      widget.metadata.serverId!,
                                      metadata.art,
                                    );
                                    if (localPath != null && File(localPath).existsSync()) {
                                      return Image.file(
                                        File(localPath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const PlaceholderContainer(),
                                      );
                                    }
                                    // Offline but no local file - show placeholder
                                    return const PlaceholderContainer();
                                  }

                                  // Online - use network image
                                  final client = _getClientForMetadata(context);
                                  final mediaQuery = MediaQuery.of(context);
                                  final imageUrl = PlexImageHelper.getOptimizedImageUrl(
                                    client: client,
                                    thumbPath: metadata.art,
                                    maxWidth: mediaQuery.size.width,
                                    maxHeight: mediaQuery.size.height * 0.6,
                                    devicePixelRatio: mediaQuery.devicePixelRatio,
                                    imageType: ImageType.art,
                                  );

                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const PlaceholderContainer(),
                                    errorWidget: (context, url, error) => const PlaceholderContainer(),
                                  );
                                },
                              )
                            : const PlaceholderContainer(),
                      ),

                      // Gradient overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: -1, // Extend 1px past to prevent subpixel gap
                        child: Builder(
                          builder: (context) {
                            final bgColor = Theme.of(context).scaffoldBackgroundColor;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, bgColor.withValues(alpha: 0.9), bgColor],
                                  stops: const [0.3, 0.8, 1.0],
                                ),
                              ),
                            );
                          },
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
                                        // Check for offline local file first
                                        if (widget.isOffline && widget.metadata.serverId != null) {
                                          final localPath = context.read<DownloadProvider>().getArtworkLocalPath(
                                            widget.metadata.serverId!,
                                            metadata.clearLogo,
                                          );
                                          if (localPath != null && File(localPath).existsSync()) {
                                            return Image.file(
                                              File(localPath),
                                              fit: BoxFit.contain,
                                              alignment: Alignment.centerLeft,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildTitleText(context, metadata.title),
                                            );
                                          }
                                          // Offline but no local file - show title text
                                          return _buildTitleText(context, metadata.title);
                                        }

                                        // Online - use network image
                                        final client = _getClientForMetadata(context);
                                        final dpr = MediaQuery.of(context).devicePixelRatio;
                                        final logoUrl = PlexImageHelper.getOptimizedImageUrl(
                                          client: client,
                                          thumbPath: metadata.clearLogo,
                                          maxWidth: 400,
                                          maxHeight: 120,
                                          devicePixelRatio: dpr,
                                          imageType: ImageType.logo,
                                        );

                                        return CachedNetworkImage(
                                          imageUrl: logoUrl,
                                          filterQuality: FilterQuality.medium,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                          memCacheWidth: (400 * dpr).clamp(200, 800).round(),
                                          placeholder: (context, url) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              metadata.title,
                                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8),
                                                ],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            return _buildTitleText(context, metadata.title);
                                          },
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Text(
                                    metadata.title,
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)],
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
                                    if (metadata.year != null) _buildMetadataChip('${metadata.year}'),
                                    if (metadata.contentRating != null)
                                      _buildMetadataChip(formatContentRating(metadata.contentRating!)),
                                    if (metadata.duration != null)
                                      _buildMetadataChip(formatDurationTextual(metadata.duration!)),
                                    if (metadata.rating != null)
                                      _buildMetadataChip(
                                        '${(metadata.rating! * 10).toStringAsFixed(0)}%',
                                        icon: Symbols.star_rounded,
                                      ),
                                    if (metadata.audienceRating != null)
                                      _buildMetadataChip(
                                        '${(metadata.audienceRating! * 10).toStringAsFixed(0)}%',
                                        icon: Symbols.people_rounded,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Action buttons
                                _buildActionButtons(metadata),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        if (metadata.summary != null) ...[
                          Text(
                            t.discover.overview,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(metadata.summary!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                          const SizedBox(height: 24),
                        ],

                        // Seasons (for TV shows)
                        if (isShow) ...[
                          Text(
                            t.discover.seasons,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingSeasons)
                            const Center(
                              child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                            )
                          else if (_seasons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  t.messages.noSeasonsFound,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                ),
                              ),
                            )
                          else if (size.width >= 600)
                            _buildHorizontalSeasons()
                          else
                            _buildVerticalSeasons(),
                          const SizedBox(height: 24),
                        ],

                        // Cast
                        if (metadata.role != null && metadata.role!.isNotEmpty) ...[
                          Text(
                            t.discover.cast,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final actor = metadata.role![index];
                                  return SizedBox(
                                    width: 120,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                                          child: actor.thumb != null
                                              ? CachedNetworkImage(
                                                  imageUrl: actor.thumb!,
                                                  width: 120,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                    child: const Center(
                                                      child: AppIcon(Symbols.person_rounded, fill: 1),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                    child: const Center(
                                                      child: AppIcon(Symbols.person_rounded, fill: 1),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 120,
                                                  height: 120,
                                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  child: const Center(child: AppIcon(Symbols.person_rounded, fill: 1)),
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 84,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                actor.tag,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (actor.role != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  actor.role!,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          _buildInfoRow(t.discover.rating, formatContentRating(metadata.contentRating!)),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Sticky top bar with fading background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: _scrollOffset < 50,
                child: AnimatedOpacity(
                  opacity: (_scrollOffset / 100).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Back button (always visible)
            Positioned(
              top: 0,
              left: 0,
              child: DesktopAppBarHelper.buildAdjustedLeading(
                AppBarBackButton(
                  style: BackButtonStyle.circular,
                  onPressed: () => Navigator.pop(context, _watchStateChanged),
                ),
                context: context,
              )!,
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
            style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }

  String _getPlayButtonLabel(PlexMetadata metadata) {
    // For TV shows - use compact S1E1 format
    if (metadata.isShow) {
      if (_onDeckEpisode != null) {
        final episode = _onDeckEpisode!;
        final seasonNum = episode.parentIndex ?? 0;
        final episodeNum = episode.index ?? 0;

        // Use the same format for both play and resume
        // (icon will indicate the difference)
        return t.discover.playEpisode(season: seasonNum.toString(), episode: episodeNum.toString());
      } else {
        // No on deck episode, will play first episode
        return t.discover.playEpisode(season: '1', episode: '1');
      }
    }

    // For movies or episodes - NO TEXT, just icon
    return '';
  }

  IconData _getPlayButtonIcon(PlexMetadata metadata) {
    // For TV shows
    if (metadata.isShow) {
      if (_onDeckEpisode != null) {
        final episode = _onDeckEpisode!;
        // Check if episode has been partially watched
        if (episode.viewOffset != null && episode.viewOffset! > 0) {
          return Symbols.resume_rounded; // Resume icon
        }
      }
    } else {
      // For movies or episodes
      if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
        return Symbols.resume_rounded; // Resume icon
      }
    }

    return Symbols.play_arrow_rounded; // Default play icon
  }
}

/// Season card widget
class _SeasonCard extends StatelessWidget {
  final PlexMetadata season;
  final PlexClient? client;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final bool isOffline;
  final String? localPosterPath;

  const _SeasonCard({
    required this.season,
    this.client,
    required this.onTap,
    required this.onRefresh,
    this.isOffline = false,
    this.localPosterPath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: MediaContextMenu(
        item: season,
        onRefresh: (ratingKey) => onRefresh(),
        onTap: onTap,
        child: Semantics(
          label: "media-season-${season.ratingKey}",
          identifier: "media-season-${season.ratingKey}",
          button: true,
          hint: "Tap to view ${season.title}",
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Season poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: isOffline && localPosterPath != null
                        ? Image.file(
                            File(localPosterPath!),
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const AppIcon(Symbols.movie_rounded, fill: 1, size: 32),
                            ),
                          )
                        : season.thumb != null
                        ? PlexOptimizedImage.poster(
                            client: client,
                            imagePath: season.thumb,
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 120,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const AppIcon(Symbols.movie_rounded, fill: 1, size: 32),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 120,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const AppIcon(Symbols.movie_rounded, fill: 1, size: 32),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Season info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (season.leafCount != null)
                          Text(
                            t.discover.episodeCount(count: season.leafCount.toString()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        // Hide watch progress when offline (not tracked)
                        if (!isOffline) ...[
                          const SizedBox(height: 8),
                          if (season.viewedLeafCount != null && season.leafCount != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: season.viewedLeafCount! / season.leafCount!,
                                      backgroundColor: tokens(context).outline,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.discover.watchedProgress(
                                    watched: season.viewedLeafCount.toString(),
                                    total: season.leafCount.toString(),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),

                  const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
