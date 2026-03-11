import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/rating_bottom_sheet.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/key_event_utils.dart';
import '../focus/input_mode_tracker.dart';
import '../widgets/focus_builders.dart';
import '../widgets/media_card.dart';
import '../i18n/strings.g.dart';
import '../widgets/plex_optimized_image.dart';
import '../utils/plex_image_helper.dart';
import '../../services/plex_client.dart';
import '../services/plex_api_cache.dart';
import '../models/plex_metadata.dart';
import '../models/plex_video_playback_data.dart';
import '../utils/content_utils.dart';
import '../utils/rating_utils.dart';
import '../models/download_models.dart';
import '../services/download_storage_service.dart';
import '../providers/playback_state_provider.dart';
import '../providers/download_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/scroll_utils.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/app_bar_back_button.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/placeholder_container.dart';
import '../mixins/watch_state_aware.dart';
import '../mixins/deletion_aware.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/server_bound_media_mixin.dart';
import '../utils/watch_state_notifier.dart';
import '../utils/deletion_notifier.dart';
import '../widgets/episode_card.dart';
import '../widgets/focusable_tab_chip.dart';

class MediaDetailScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final bool isOffline;

  /// If provided, auto-selects this season index when the screen loads.
  /// Used when navigating to a show from a season context.
  final int? initialSeasonIndex;

  const MediaDetailScreen({super.key, required this.metadata, this.isOffline = false, this.initialSeasonIndex});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen>
    with WatchStateAware, DeletionAware, MountedSetStateMixin, ServerBoundMediaMixin {
  List<PlexMetadata> _seasons = [];
  bool _isLoadingSeasons = false;
  Completer<void>? _seasonsCompleter;
  List<PlexMetadata> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _showEpisodesDirectly = false;
  PlexMetadata? _fullMetadata;
  PlexMetadata? _onDeckEpisode;
  PlexVideoPlaybackData? _playbackData;
  bool _isLoadingMetadata = true;
  List<PlexMetadata>? _extras;
  late final ScrollController _scrollController;
  final ScrollController _extrasScrollController = ScrollController();
  bool _watchStateChanged = false;
  double _scrollOffset = 0;

  // Inline season tabs
  int _selectedSeasonIndex = 0;
  final Map<String, List<PlexMetadata>> _episodeCache = {};
  bool _isLoadingSeasonEpisodes = false;
  List<FocusNode> _seasonTabFocusNodes = [];
  final Map<int, GlobalKey<MediaContextMenuState>> _seasonContextMenuKeys = {};
  final ScrollController _seasonTabsScrollController = ScrollController();
  final FocusNode _firstEpisodeFocusNode = FocusNode(debugLabel: 'first_episode');
  final FocusNode _lastEpisodeFocusNode = FocusNode(debugLabel: 'last_episode');

  late final FocusNode _playButtonFocusNode;
  late final FocusNode _ratingChipFocusNode;
  Timer? _selectKeyTimer;
  bool _isSelectKeyDown = false;
  bool _longPressTriggered = false;
  static const _longPressDuration = Duration(milliseconds: 500);

  // Context menu key for the three-dots button
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();


  // Locked focus pattern for extras
  int _focusedExtraIndex = 0;
  late final FocusNode _extrasFocusNode;
  final Map<int, GlobalKey<MediaCardState>> _extraCardKeys = {};
  final _extrasSectionKey = GlobalKey();

  // Locked focus pattern for overview
  late final FocusNode _overviewFocusNode;
  final _overviewSectionKey = GlobalKey();

  // Locked focus pattern for cast
  int _focusedCastIndex = 0;
  late final FocusNode _castFocusNode;
  final ScrollController _castScrollController = ScrollController();
  final _castSectionKey = GlobalKey();
  final _seasonsSectionKey = GlobalKey();

  @override
  PlexMetadata get serverBoundMetadata => widget.metadata;

  @override
  bool get isServerBoundOffline => widget.isOffline;

  // WatchStateAware: watch the show/movie and all season/episode ratingKeys
  @override
  Set<String>? get watchedRatingKeys {
    final keys = <String>{widget.metadata.ratingKey};
    for (final season in _seasons) {
      keys.add(season.ratingKey);
    }
    for (final ep in _episodes) {
      keys.add(ep.ratingKey);
    }
    return keys;
  }

  @override
  String? get watchStateServerId => serverBoundServerId;

  @override
  Set<String>? get watchedGlobalKeys {
    final serverId = serverBoundServerId;
    if (serverId == null) return null;

    final keys = <String>{toServerBoundGlobalKey(widget.metadata.ratingKey, serverId: serverId)};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.ratingKey, serverId: season.serverId ?? serverId));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.ratingKey, serverId: ep.serverId ?? serverId));
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    if (!widget.isOffline) {
      // If the event matches an episode currently shown, update it directly
      final epIndex = _episodes.indexWhere((e) => e.ratingKey == event.ratingKey);
      if (epIndex != -1) {
        _updateEpisodeWatchState(event.ratingKey);
      } else {
        _refreshWatchState();
      }
    }
  }

  @override
  Set<String>? get deletionRatingKeys {
    final keys = <String>{widget.metadata.ratingKey};
    for (final season in _seasons) {
      keys.add(season.ratingKey);
    }
    for (final ep in _episodes) {
      keys.add(ep.ratingKey);
    }
    return keys;
  }

  @override
  String? get deletionServerId => serverBoundServerId;

  @override
  Set<String>? get deletionGlobalKeys {
    final serverId = serverBoundServerId;
    if (serverId == null) return null;

    final keys = <String>{toServerBoundGlobalKey(widget.metadata.ratingKey, serverId: serverId)};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.ratingKey, serverId: season.serverId ?? serverId));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.ratingKey, serverId: ep.serverId ?? serverId));
    }
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // Download-only deletions should only remove items when viewing offline content
    if (event.isDownloadOnly && !widget.isOffline) return;
    if (!event.isDownloadOnly && widget.isOffline) return;

    // When showing episodes directly (season view or flattened), handle episode deletion
    if (_showEpisodesDirectly) {
      final epIndex = _episodes.indexWhere((e) => e.ratingKey == event.ratingKey);
      if (epIndex != -1) {
        setState(() {
          _episodes.removeAt(epIndex);
        });
        if (_episodes.isEmpty && widget.metadata.isSeason && mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    // If we have a season that matches the rating key exactly, then remove it from our list
    final seasonIndex = _seasons.indexWhere((s) => s.ratingKey == event.ratingKey);
    if (seasonIndex != -1) {
      setState(() {
        _seasons.removeAt(seasonIndex);
      });

      // If the show has no more seasons, navigate back up to the library
      if (_seasons.isEmpty && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _refreshWatchState();
      return;
    }

    // If a child item was delete, then update our list to reflect that.
    // If all children were deleted, remove our item.
    // Otherwise, just update the counts.
    for (final parentKey in event.parentChain) {
      final idx = _seasons.indexWhere((s) => s.ratingKey == parentKey);
      if (idx != -1) {
        final season = _seasons[idx];
        final newLeafCount = (season.leafCount ?? 1) - 1;
        if (newLeafCount <= 0) {
          // Season is now empty, remove it
          setState(() {
            _seasons.removeAt(idx);
          });

          // Otherwise we have no more seasons, so navigate up
          if (_seasons.isEmpty && mounted) {
            Navigator.of(context).pop();
            return;
          }
        } else {
          setState(() {
            // Otherwise just update the counts
            _seasons[idx] = season.copyWith(leafCount: newLeafCount);
          });
        }
        _refreshWatchState();
        return;
      }
    }
  }

  /// Lightweight refresh for watch state changes - no loader, preserves scroll
  Future<void> _refreshWatchState() async {
    final client = _getClientForMetadata(context);
    if (client == null) return;

    try {
      // Fetch updated metadata + on-deck without showing loader
      final result = await client.getMetadataWithImagesAndOnDeck(widget.metadata.ratingKey);
      final metadata = result['metadata'] as PlexMetadata?;
      final onDeckEpisode = result['onDeckEpisode'] as PlexMetadata?;

      if (metadata != null) {
        setStateIfMounted(() {
          _fullMetadata = metadata.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName);
          _onDeckEpisode = onDeckEpisode?.copyWith(
            serverId: widget.metadata.serverId,
            serverName: widget.metadata.serverName,
          );
        });
      }

      // Refresh seasons for updated watched counts (also without loader)
      if (widget.metadata.isShow) {
        final seasons = await client.getChildren(widget.metadata.ratingKey);
        // Clear episode cache so stale watch state data isn't reused
        _episodeCache.clear();
        setStateIfMounted(() {
          _seasons = seasons
              .map((s) => s.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName))
              .toList();
        });
        // Re-fetch episodes for the currently selected season
        if (!_showEpisodesDirectly && _seasons.isNotEmpty) {
          _fetchSeasonEpisodes(_selectedSeasonIndex);
        }
      } else if (widget.metadata.isSeason) {
        await _fetchAllEpisodes();
      }
    } catch (e) {
      // Silently fail - data will refresh on next navigation
    }
  }

  /// Update a single episode's watch state without refetching everything
  Future<void> _updateEpisodeWatchState(String ratingKey) async {
    final client = _getClientForMetadata(context);
    if (client == null) return;
    try {
      final refreshed = await client.getMetadataWithImages(ratingKey);
      if (refreshed != null) {
        setStateIfMounted(() {
          final i = _episodes.indexWhere((e) => e.ratingKey == ratingKey);
          if (i != -1) {
            _episodes[i] = refreshed;
            _syncEpisodeToCache(i, refreshed);
          }
        });
      }
    } catch (_) {
      // Silently fail
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _extrasFocusNode = FocusNode(debugLabel: 'extras_row');
    _playButtonFocusNode = FocusNode(debugLabel: 'play_button');
    _ratingChipFocusNode = FocusNode(debugLabel: 'rating_chip');
    _overviewFocusNode = FocusNode(debugLabel: 'overview');
    _castFocusNode = FocusNode(debugLabel: 'cast_row');
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
    _extrasScrollController.dispose();
    _extrasFocusNode.dispose();
    _playButtonFocusNode.dispose();
    _ratingChipFocusNode.dispose();
    _overviewFocusNode.dispose();
    _castFocusNode.dispose();
    _castScrollController.dispose();
    _selectKeyTimer?.cancel();
    for (final node in _seasonTabFocusNodes) {
      node.dispose();
    }
    _seasonTabsScrollController.dispose();
    _firstEpisodeFocusNode.dispose();
    _lastEpisodeFocusNode.dispose();
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
      } else if (metadata.isSeason) {
        // For seasons, play the first episode
        if (_episodes.isNotEmpty) {
          await navigateToVideoPlayerWithRefresh(
            context,
            metadata: _episodes.first,
            isOffline: widget.isOffline,
            onRefresh: _loadFullMetadata,
          );
        } else {
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
          playbackData: _playbackData,
        );
      }
    }

    final primaryTrailer = _getPrimaryTrailer();

    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final colorScheme = Theme.of(context).colorScheme;

    // In keyboard/d-pad mode, focused buttons get a prominent style.
    // overlayColor is set to transparent to prevent the Material focus
    // overlay from dimming the background color we set.
    final focusBg = colorScheme.inverseSurface;
    final focusFg = colorScheme.onInverseSurface;
    final tonalBg = colorScheme.secondaryContainer;
    final tonalFg = colorScheme.onSecondaryContainer;
    final noOverlay = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) return Colors.transparent;
      return null; // default for other states
    });

    ButtonStyle actionButtonStyle({Color? foregroundColor, EdgeInsetsGeometry? padding}) {
      if (!isKeyboardMode) {
        if (padding != null) {
          return FilledButton.styleFrom(padding: padding);
        }
        return IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          maximumSize: const Size(48, 48),
          foregroundColor: foregroundColor,
        );
      }
      return ButtonStyle(
        padding: padding != null ? WidgetStatePropertyAll(padding) : null,
        minimumSize: padding == null ? const WidgetStatePropertyAll(Size(48, 48)) : null,
        maximumSize: padding == null ? const WidgetStatePropertyAll(Size(48, 48)) : null,
        overlayColor: noOverlay,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusBg;
          return tonalBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusFg;
          return foregroundColor ?? tonalFg;
        }),
      );
    }

    return Focus(
      skipTraversal: true,
      onKeyEvent: _handlePlayButtonKeyEvent,
      child: Row(
        children: [
          SizedBox(
            height: 48,
            child: FilledButton(
              focusNode: _playButtonFocusNode,
              autofocus: isKeyboardMode,
              onPressed: onPlayPressed,
              style: actionButtonStyle(padding: const EdgeInsets.symmetric(horizontal: 16)),
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
          // Trailer button (only if trailer is available)
          if (primaryTrailer != null) ...[
            IconButton.filledTonal(
              onPressed: () async {
                await navigateToVideoPlayer(context, metadata: primaryTrailer);
              },
              icon: const AppIcon(Symbols.theaters_rounded, fill: 1),
              tooltip: t.tooltips.playTrailer,
              iconSize: 20,
              style: actionButtonStyle(),
            ),
            const SizedBox(width: 12),
          ],
          // Shuffle button (only for shows and seasons)
          if (metadata.isShow || metadata.isSeason) ...[
            IconButton.filledTonal(
              onPressed: () async {
                await _handleShufflePlayWithQueue(context, metadata);
              },
              icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
              tooltip: t.tooltips.shufflePlay,
              iconSize: 20,
              style: actionButtonStyle(),
            ),
            const SizedBox(width: 12),
          ],
          // Download button (hide in offline mode - already downloaded)
          if (!widget.isOffline)
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, _) {
                final globalKey = metadata.globalKey;
                final progress = downloadProvider.getProgress(globalKey);
                final isQueueing = downloadProvider.isQueueing(globalKey);

                // Debug logging
                if (progress != null) {
                  appLogger.d(
                    'UI rebuilding for $globalKey: status=${progress.status}, progress=${progress.progress}%',
                  );
                }

                // State 1: Queueing (building download queue)
                if (isQueueing) {
                  return IconButton.filledTonal(
                    onPressed: null,
                    icon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    iconSize: 20,
                    style: actionButtonStyle(),
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
                    style: actionButtonStyle(),
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
                    style: actionButtonStyle(),
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
                    style: actionButtonStyle(foregroundColor: Colors.amber),
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
                    style: actionButtonStyle(foregroundColor: Colors.red),
                  );
                }

                // State 6: Cancelled (can delete or retry)
                if (progress?.status == DownloadStatus.cancelled) {
                  return IconButton.filledTonal(
                    onPressed: () async {
                      // Show options: Delete or Retry
                      final retry = await showConfirmDialog(
                        context,
                        title: 'Cancelled Download',
                        message: 'This download was cancelled. What would you like to do?',
                        cancelText: t.common.delete,
                        confirmText: 'Retry',
                      );

                      if (!retry && context.mounted) {
                        await downloadProvider.deleteDownload(globalKey);
                        if (context.mounted) {
                          showSuccessSnackBar(context, t.downloads.downloadDeleted);
                        }
                      } else if (retry && context.mounted) {
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
                    style: actionButtonStyle(foregroundColor: Colors.grey),
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
                    style: actionButtonStyle(foregroundColor: Colors.orange),
                  );
                }

                // State 8: Downloaded/Completed (can delete)
                if (downloadProvider.isDownloaded(globalKey)) {
                  return IconButton.filledTonal(
                    onPressed: () async {
                      // Show delete download confirmation
                      final confirmed = await showDeleteConfirmation(
                        context,
                        title: t.downloads.deleteDownload,
                        message: t.downloads.deleteConfirm(title: metadata.title),
                      );

                      if (confirmed && context.mounted) {
                        await downloadProvider.deleteDownload(globalKey);
                        if (context.mounted) {
                          showSuccessSnackBar(context, t.downloads.downloadDeleted);
                        }
                      }
                    },
                    icon: const AppIcon(Symbols.file_download_done_rounded, fill: 1),
                    tooltip: t.downloads.deleteDownload,
                    iconSize: 20,
                    style: actionButtonStyle(foregroundColor: Colors.green),
                  );
                }

                // State 9: Not downloaded (default - can download)
                return IconButton.filledTonal(
                  onPressed: () async {
                    final client = _getClientForMetadata(context);
                    if (client == null) return;
                    try {
                      final count = await downloadProvider.queueDownload(metadata, client);
                      if (context.mounted) {
                        final message = count > 1
                            ? t.downloads.episodesQueued(count: count)
                            : t.downloads.downloadQueued;
                        showSuccessSnackBar(context, message);
                      }
                    } on CellularDownloadBlockedException {
                      if (context.mounted) {
                        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                      }
                    }
                  },
                  icon: const AppIcon(Symbols.download_rounded, fill: 1),
                  tooltip: t.downloads.downloadNow,
                  iconSize: 20,
                  style: actionButtonStyle(),
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
                  if (mounted) {
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
                  if (mounted) {
                    _watchStateChanged = true;
                    showSuccessSnackBar(context, isWatched ? t.messages.markedAsUnwatched : t.messages.markedAsWatched);
                    // Update watch state without full rebuild
                    _updateWatchState();
                  }
                }
              } catch (e) {
                if (mounted) {
                  showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
                }
              }
            },
            icon: AppIcon(metadata.isWatched ? Symbols.remove_done_rounded : Symbols.check_rounded, fill: 1),
            tooltip: metadata.isWatched ? t.tooltips.markAsUnwatched : t.tooltips.markAsWatched,
            iconSize: 20,
            style: actionButtonStyle(),
          ),
          // Three-dots menu button (hidden in offline mode)
          if (!widget.isOffline) ...[
            const SizedBox(width: 12),
            MediaContextMenu(
              key: _contextMenuKey,
              item: metadata,
              onRefresh: (_) => _loadFullMetadata(),
              child: Builder(
                builder: (buttonContext) => IconButton.filledTonal(
                  onPressed: () {
                    final renderBox = buttonContext.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final position = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
                      _contextMenuKey.currentState?.showContextMenu(buttonContext, position: position);
                    }
                  },
                  icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                  iconSize: 20,
                  style: actionButtonStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a metadata chip with optional leading icon or widget
  Widget _buildMetadataChip(String text, {IconData? icon, Widget? leading}) {
    final textWidget = Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );

    final hasLeading = leading != null || icon != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: hasLeading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null)
                  leading
                else
                  AppIcon(icon!, fill: 1, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 16),
                const SizedBox(width: 4),
                textWidget,
              ],
            )
          : textWidget,
    );
  }

  /// Build a rating chip that shows a source icon when available,
  /// falling back to a generic Material icon.
  Widget _buildRatingChip(String? imageUri, double value, IconData fallbackIcon) {
    final info = parseRatingImage(imageUri, value);
    if (info != null) {
      return _buildMetadataChip(info.formattedValue, leading: SvgPicture.asset(info.assetPath, width: 16, height: 16));
    }
    return _buildMetadataChip('${(value * 10).toStringAsFixed(0)}%', icon: fallbackIcon);
  }

  /// Build all rating chips for the metadata.
  /// When both critic and audience ratings are from Rotten Tomatoes,
  /// they are combined into a single badge.
  List<Widget> _buildRatingChips(PlexMetadata metadata) {
    final chips = <Widget>[];
    final bothRT =
        metadata.rating != null &&
        metadata.audienceRating != null &&
        isRottenTomatoes(metadata.ratingImage) &&
        isRottenTomatoes(metadata.audienceRatingImage);

    if (bothRT) {
      final critic = parseRatingImage(metadata.ratingImage, metadata.rating)!;
      final audience = parseRatingImage(metadata.audienceRatingImage, metadata.audienceRating)!;
      chips.add(_buildCombinedRtChip(critic, audience));
    } else {
      if (metadata.rating != null) {
        chips.add(_buildRatingChip(metadata.ratingImage, metadata.rating!, Symbols.star_rounded));
      }
      if (metadata.audienceRating != null) {
        chips.add(_buildRatingChip(metadata.audienceRatingImage, metadata.audienceRating!, Symbols.people_rounded));
      }
    }

    // User rating chip (tappable)
    if (!widget.isOffline) {
      chips.add(_buildUserRatingChip(metadata));
    }

    return chips;
  }

  Widget _buildUserRatingChip(PlexMetadata metadata) {
    final hasRating = metadata.userRating != null && metadata.userRating! > 0;
    final starValue = hasRating ? metadata.userRating! / 2.0 : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final showFocus = _ratingChipFocusNode.hasFocus && isKeyboardMode;

    final bgColor = showFocus ? colorScheme.inverseSurface : colorScheme.secondaryContainer.withValues(alpha: 0.8);
    final fgColor = showFocus ? colorScheme.onInverseSurface : colorScheme.onSecondaryContainer;

    return FocusableWrapper(
      focusNode: _ratingChipFocusNode,
      onSelect: () => _showRatingDialog(metadata, starValue),
      borderRadius: 100,
      disableScale: true,
      focusColor: Colors.transparent,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (_, event) {
        if (!event.isActionable) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key.isDownKey) {
          _playButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (key.isUpKey) {
          return KeyEventResult.handled; // consume — nothing above
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _showRatingDialog(metadata, starValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                Symbols.star_rounded,
                fill: hasRating ? 1 : 0,
                color: showFocus ? fgColor : (hasRating ? Colors.amber : fgColor),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                hasRating ? formatRating(starValue) : t.mediaMenu.rate,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(PlexMetadata metadata, double currentStarValue) {
    showModalBottomSheet(
      context: context,
      builder: (context) => RatingBottomSheet(
        currentRating: currentStarValue,
        onRate: (stars) async {
          final client = _getClientForMetadata(this.context);
          if (client == null) return;
          final plexRating = stars * 2.0; // Convert 0-5 stars to 0-10 scale
          final success = await client.rateItem(metadata.ratingKey, plexRating);
          if (success) _updateWatchState();
        },
        onClear: () async {
          final client = _getClientForMetadata(this.context);
          if (client == null) return;
          final success = await client.rateItem(metadata.ratingKey, -1);
          if (success) _updateWatchState();
        },
      ),
    );
  }

  /// Build a combined RT chip showing critic + audience side by side.
  Widget _buildCombinedRtChip(RatingInfo critic, RatingInfo audience) {
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSecondaryContainer,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(critic.assetPath, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(critic.formattedValue, style: textStyle),
          const SizedBox(width: 10),
          SvgPicture.asset(audience.assetPath, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(audience.formattedValue, style: textStyle),
        ],
      ),
    );
  }

  /// Get the correct PlexClient for this metadata's server
  /// Returns null in offline mode or if serverId is null
  PlexClient? _getClientForMetadata(BuildContext context) {
    return getServerBoundClient(context);
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    // Offline mode: try to load full metadata from cache (has clearLogo, summary, etc.)
    if (widget.isOffline) {
      final cachedMetadata = await PlexApiCache.instance.getMetadata(
        widget.metadata.serverId ?? '',
        widget.metadata.ratingKey,
      );
      if (!mounted) return;
      setState(() {
        _fullMetadata = cachedMetadata ?? widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
        _loadSeasonsFromDownloads();
        // Get offline OnDeck episode
        _loadOfflineOnDeckEpisode();
      } else if (widget.metadata.isSeason) {
        _seasons = [widget.metadata];
        _showEpisodesDirectly = true;
        _loadEpisodesFromDownloads();
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
      final playbackData = result['playbackData'] as PlexVideoPlaybackData?;

      if (!mounted) return;

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
          _playbackData = playbackData;
          _isLoadingMetadata = false;
        });

        // Load seasons if it's a show
        if (metadata.isShow) {
          _loadSeasons();
        } else if (metadata.isSeason) {
          _seasons = [widget.metadata];
          _showEpisodesDirectly = true;
          _fetchAllEpisodes();
        }

        // Load extras (trailers, behind-the-scenes, etc.)
        _loadExtras();

        return;
      }

      // Fallback to passed metadata
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
        _loadSeasons();
      } else if (widget.metadata.isSeason) {
        _seasons = [widget.metadata];
        _showEpisodesDirectly = true;
        _fetchAllEpisodes();
      }
    } catch (e) {
      // Fallback to passed metadata on error
      if (!mounted) return;
      setState(() {
        _fullMetadata = widget.metadata;
        _isLoadingMetadata = false;
      });

      if (widget.metadata.isShow) {
        _loadSeasons();
      } else if (widget.metadata.isSeason) {
        _seasons = [widget.metadata];
        _showEpisodesDirectly = true;
        _fetchAllEpisodes();
      }
    }
  }

  Future<void> _loadSeasons() async {
    _seasonsCompleter = Completer<void>();
    setState(() {
      _isLoadingSeasons = true;
    });

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      // Fetch seasons and library prefs in parallel
      final sectionId = (_fullMetadata ?? widget.metadata).librarySectionID?.toString();
      final seasonsFuture = client?.getChildren(widget.metadata.ratingKey) ?? Future.value(<PlexMetadata>[]);
      final prefsFuture = (sectionId != null && client != null)
          ? client.getLibrarySectionPrefs(sectionId)
          : Future.value(<String, dynamic>{});

      final results = await Future.wait([seasonsFuture, prefsFuture]);
      final seasons = results[0] as List<PlexMetadata>;
      final prefs = results[1] as Map<String, dynamic>;

      // Preserve serverId for each season
      final seasonsWithServerId = seasons
          .map((season) => season.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName))
          .toList();

      // Check the server setting the season display mode
      const flattenSeasonsAlways = 1;
      const flattenSeasonsSingleSeason = 2;
      final flattenSeasons = int.tryParse(prefs['flattenSeasons']?.toString() ?? '');
      final isAlways = flattenSeasons == flattenSeasonsAlways;
      final isSingleSeason = flattenSeasons == flattenSeasonsSingleSeason;
      final shouldShowEpisodesDirectly =
          isAlways || (isSingleSeason && seasonsWithServerId.length == 1);

      // Create focus nodes for season tabs
      _updateSeasonTabFocusNodes(seasonsWithServerId.length);

      // Auto-select the on-deck season
      final onDeckSeasonIndex = _findOnDeckSeasonIndex(seasonsWithServerId);

      setStateIfMounted(() {
        _seasons = seasonsWithServerId;
        _isLoadingSeasons = false;
        _showEpisodesDirectly = shouldShowEpisodesDirectly;
        _selectedSeasonIndex = onDeckSeasonIndex;
      });

      if (shouldShowEpisodesDirectly) {
        await _fetchAllEpisodes();
      } else if (seasonsWithServerId.isNotEmpty) {
        // Fetch episodes for the auto-selected season
        _fetchSeasonEpisodes(onDeckSeasonIndex);
      }
    } catch (e) {
      setStateIfMounted(() {
        _isLoadingSeasons = false;
      });
    } finally {
      if (!(_seasonsCompleter?.isCompleted ?? true)) {
        _seasonsCompleter?.complete();
      }
    }
  }

  /// Load seasons from downloaded episodes (offline mode)
  void _loadSeasonsFromDownloads() {
    _seasonsCompleter = Completer<void>();
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

    // Create focus nodes for season tabs and cache episodes per season
    _updateSeasonTabFocusNodes(seasons.length);
    for (final entry in seasonMap.entries) {
      final seasonRatingKey = entry.value.first.parentRatingKey ?? '';
      _episodeCache[seasonRatingKey] = entry.value..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
    }

    final onDeckSeasonIndex = _findOnDeckSeasonIndex(seasons);

    setState(() {
      _seasons = seasons;
      _isLoadingSeasons = false;
      _selectedSeasonIndex = onDeckSeasonIndex;
    });

    // Load episodes for the selected season from cache
    if (seasons.isNotEmpty) {
      _fetchSeasonEpisodes(onDeckSeasonIndex);
    }

    if (!(_seasonsCompleter?.isCompleted ?? true)) {
      _seasonsCompleter?.complete();
    }
  }

  /// Load episodes from downloaded content for a season
  void _loadEpisodesFromDownloads() {
    final downloadProvider = context.read<DownloadProvider>();
    final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(widget.metadata.parentRatingKey ?? '');
    final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == widget.metadata.index).toList()
      ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    setState(() {
      _episodes = seasonEpisodes;
      _isLoadingEpisodes = false;
    });
  }

  /// Create or update focus nodes for season tab chips
  void _updateSeasonTabFocusNodes(int count) {
    if (_seasonTabFocusNodes.length != count) {
      for (final node in _seasonTabFocusNodes) {
        node.dispose();
      }
      _seasonTabFocusNodes = List.generate(
        count,
        (i) => FocusNode(debugLabel: 'season_tab_$i'),
      );
      _seasonContextMenuKeys.clear();
    }
  }

  /// Find the season index matching the initial selection or on-deck episode, or fall back to 0
  int _findOnDeckSeasonIndex(List<PlexMetadata> seasons) {
    // Prefer explicit initial season (from navigation)
    if (widget.initialSeasonIndex != null && seasons.isNotEmpty) {
      final idx = seasons.indexWhere((s) => s.index == widget.initialSeasonIndex);
      if (idx != -1) return idx;
    }
    // Fall back to on-deck episode's season
    if (_onDeckEpisode != null && seasons.isNotEmpty) {
      final onDeckParentIndex = _onDeckEpisode!.parentIndex;
      if (onDeckParentIndex != null) {
        final idx = seasons.indexWhere((s) => s.index == onDeckParentIndex);
        if (idx != -1) return idx;
      }
    }
    return 0;
  }

  /// Fetch episodes for a specific season by index, using cache when available
  Future<void> _fetchSeasonEpisodes(int seasonIndex) async {
    if (seasonIndex < 0 || seasonIndex >= _seasons.length) return;
    final season = _seasons[seasonIndex];

    // Check cache first
    final cached = _episodeCache[season.ratingKey];
    if (cached != null) {
      setStateIfMounted(() {
        _episodes = List.of(cached);
        _isLoadingSeasonEpisodes = false;
      });
      return;
    }

    setStateIfMounted(() => _isLoadingSeasonEpisodes = true);

    try {
      if (widget.isOffline) {
        // Offline: load from downloads
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(widget.metadata.ratingKey);
        final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == season.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        _episodeCache[season.ratingKey] = seasonEpisodes;
        setStateIfMounted(() {
          _episodes = List.of(seasonEpisodes);
          _isLoadingSeasonEpisodes = false;
        });
      } else {
        final client = _getClientForMetadata(context);
        if (client == null) {
          setStateIfMounted(() => _isLoadingSeasonEpisodes = false);
          return;
        }
        final episodes = await client.getChildren(season.ratingKey);
        final episodesWithServerId = episodes
            .map((e) => e.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName))
            .toList();
        _episodeCache[season.ratingKey] = episodesWithServerId;
        setStateIfMounted(() {
          _episodes = List.of(episodesWithServerId);
          _isLoadingSeasonEpisodes = false;
        });
      }
    } catch (e) {
      setStateIfMounted(() => _isLoadingSeasonEpisodes = false);
    }
  }

  /// Load extras (trailers, behind-the-scenes, etc.)
  Future<void> _loadExtras() async {
    // Only load extras for movies and shows
    if (!widget.metadata.isMovie && !widget.metadata.isShow) {
      return;
    }

    // Skip in offline mode (no server available)
    if (widget.isOffline) {
      return;
    }

    try {
      final client = _getClientForMetadata(context);
      if (client == null) {
        return;
      }

      final extras = await client.getExtras(widget.metadata.ratingKey);

      // Preserve serverId for each extra (needed for multi-server setups)
      final extrasWithServerId = extras
          .map((extra) => extra.copyWith(serverId: widget.metadata.serverId, serverName: widget.metadata.serverName))
          .toList();

      setStateIfMounted(() {
        _extras = extrasWithServerId;
      });
    } catch (e) {
      // Silently fail - extras section won't appear if fetch fails
    }
  }

  /// Scroll the main scroll view so the section with the given key is centered
  void _scrollSectionIntoView(GlobalKey key) {
    scrollContextToCenter(key.currentContext);
  }

  /// Intercept DOWN from the play button row to focus the first available section
  KeyEventResult _handlePlayButtonKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (!event.isActionable) return KeyEventResult.ignored;

    // UP: focus the rating chip if available
    if (key.isUpKey) {
      if (!widget.isOffline) {
        _ratingChipFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (!key.isDownKey) return KeyEventResult.ignored;

    final metadata = _fullMetadata ?? widget.metadata;

    // DOWN order: overview → seasons → cast → extras
    if (metadata.summary != null && metadata.summary!.isNotEmpty) {
      _overviewFocusNode.requestFocus();
      _scrollSectionIntoView(_overviewSectionKey);
      return KeyEventResult.handled;
    }

    if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
      // Focus the selected season tab chip
      _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
      _scrollSectionIntoView(_seasonsSectionKey);
      return KeyEventResult.handled;
    }

    if (metadata.role != null && metadata.role!.isNotEmpty) {
      _castFocusNode.requestFocus();
      _scrollSectionIntoView(_castSectionKey);
      return KeyEventResult.handled;
    }

    if (_extras != null && _extras!.isNotEmpty) {
      _extrasFocusNode.requestFocus();
      _scrollSectionIntoView(_extrasSectionKey);
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled; // consume to prevent unwanted traversal
  }

  /// Get the responsive card width used by seasons/extras/cast rows
  double _getResponsiveCardWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1400) return 220.0;
    if (screenWidth >= 900) return 200.0;
    if (screenWidth >= 700) return 190.0;
    return 160.0;
  }

  /// Handle key events for the overview section
  KeyEventResult _handleOverviewKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    final metadata = _fullMetadata ?? widget.metadata;

    // UP: always play button (overview is directly below play)
    if (key.isUpKey) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      _playButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // DOWN: season tabs → cast → extras
    if (key.isDownKey) {
      if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
        _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
        _scrollSectionIntoView(_seasonsSectionKey);
      } else if (metadata.role != null && metadata.role!.isNotEmpty) {
        _castFocusNode.requestFocus();
        _scrollSectionIntoView(_castSectionKey);
      } else if (_extras != null && _extras!.isNotEmpty) {
        _extrasFocusNode.requestFocus();
        _scrollSectionIntoView(_extrasSectionKey);
      }
      return KeyEventResult.handled;
    }

    // LEFT/RIGHT/SELECT: consume to prevent unwanted traversal
    if (key.isLeftKey || key.isRightKey || key.isSelectKey) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Show context menu for a season tab
  void _showSeasonTabContextMenu(int index, {Offset? position}) {
    final key = _seasonContextMenuKeys.putIfAbsent(index, () => GlobalKey<MediaContextMenuState>());
    key.currentState?.showContextMenu(context, position: position);
  }

  /// Focus the currently selected season tab
  void _focusSelectedSeasonTab() {
    if (_seasonTabFocusNodes.length > _selectedSeasonIndex) {
      _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
    }
  }

  /// Scroll a season tab into view within the horizontal scroll
  void _scrollSeasonTabIntoView(int index) {
    if (index < 0 || index >= _seasonTabFocusNodes.length) return;
    scrollContextToCenter(_seasonTabFocusNodes[index].context);
  }

  /// Build inline season tab chips with LEFT/RIGHT/DOWN focus navigation
  Widget _buildSeasonTabs() {
    return HorizontalScrollWithArrows(
      controller: _seasonTabsScrollController,
      builder: (scrollController) => SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_seasons.length, (index) {
            final season = _seasons[index];
            final contextMenuKey = _seasonContextMenuKeys.putIfAbsent(
              index,
              () => GlobalKey<MediaContextMenuState>(),
            );
            Offset? tapPosition;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MediaContextMenu(
                key: contextMenuKey,
                item: season,
                onRefresh: (_) {
                  _watchStateChanged = true;
                  _updateWatchState();
                },
                onListRefresh: () {
                  if (widget.isOffline) {
                    _loadSeasonsFromDownloads();
                  } else {
                    _loadSeasons();
                  }
                },
                child: GestureDetector(
                  onTapDown: (details) => tapPosition = details.globalPosition,
                  onLongPress: () => _showSeasonTabContextMenu(index, position: tapPosition),
                  onSecondaryTapDown: (details) => tapPosition = details.globalPosition,
                  onSecondaryTap: () => _showSeasonTabContextMenu(index, position: tapPosition),
                  child: FocusableTabChip(
                    label: season.title,
                    isSelected: index == _selectedSeasonIndex,
                    focusNode: _seasonTabFocusNodes.length > index ? _seasonTabFocusNodes[index] : null,
                    onSelect: () {
                      if (index == _selectedSeasonIndex) return;
                      setState(() => _selectedSeasonIndex = index);
                      _fetchSeasonEpisodes(index);
                    },
                    onNavigateLeft: index > 0
                        ? () {
                            final newIndex = index - 1;
                            setState(() => _selectedSeasonIndex = newIndex);
                            _seasonTabFocusNodes[newIndex].requestFocus();
                            _scrollSeasonTabIntoView(newIndex);
                            _fetchSeasonEpisodes(newIndex);
                          }
                        : null,
                    onNavigateRight: index < _seasons.length - 1
                        ? () {
                            final newIndex = index + 1;
                            setState(() => _selectedSeasonIndex = newIndex);
                            _seasonTabFocusNodes[newIndex].requestFocus();
                            _scrollSeasonTabIntoView(newIndex);
                            _fetchSeasonEpisodes(newIndex);
                          }
                        : null,
                    onNavigateDown: () {
                      _firstEpisodeFocusNode.requestFocus();
                    },
                    onLongPress: () => _showSeasonTabContextMenu(index),
                    onBack: () {
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Handle key events for the extras row (locked focus pattern)
  KeyEventResult _handleExtrasKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isBackKey) return KeyEventResult.ignored;

    // Handle SELECT with long-press detection
    if (key.isSelectKey) {
      if (event is KeyDownEvent) {
        _selectKeyTimer?.cancel();
        _isSelectKeyDown = true;
        _longPressTriggered = false;
        _selectKeyTimer = Timer(_longPressDuration, () {
          if (!mounted) return;
          if (_isSelectKeyDown) {
            _longPressTriggered = true;
            SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
            _extraCardKeys[_focusedExtraIndex]?.currentState?.showContextMenu();
          }
        });
        return KeyEventResult.handled;
      } else if (event is KeyRepeatEvent) {
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        final timerWasActive = _selectKeyTimer?.isActive ?? false;
        _selectKeyTimer?.cancel();
        if (!_longPressTriggered && timerWasActive && _isSelectKeyDown) {
          if (_focusedExtraIndex < _extras!.length) {
            navigateToVideoPlayer(context, metadata: _extras![_focusedExtraIndex]);
          }
        }
        _isSelectKeyDown = false;
        _longPressTriggered = false;
        return KeyEventResult.handled;
      }
    }

    if (!event.isActionable) return KeyEventResult.ignored;
    if (_extras == null || _extras!.isEmpty) return KeyEventResult.ignored;

    // LEFT: previous extra
    if (key.isLeftKey) {
      if (_focusedExtraIndex > 0) {
        setState(() => _focusedExtraIndex--);
        scrollListToIndex(_extrasScrollController, _focusedExtraIndex, itemExtent: _getResponsiveCardWidth() + 4);
      }
      return KeyEventResult.handled;
    }

    // RIGHT: next extra
    if (key.isRightKey) {
      if (_focusedExtraIndex < _extras!.length - 1) {
        setState(() => _focusedExtraIndex++);
        scrollListToIndex(_extrasScrollController, _focusedExtraIndex, itemExtent: _getResponsiveCardWidth() + 4);
      }
      return KeyEventResult.handled;
    }

    // UP: cast → season tabs → overview → play button
    if (key.isUpKey) {
      final metadata = _fullMetadata ?? widget.metadata;
      if (metadata.role != null && metadata.role!.isNotEmpty) {
        _castFocusNode.requestFocus();
        _scrollSectionIntoView(_castSectionKey);
      } else if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
        _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
        _scrollSectionIntoView(_seasonsSectionKey);
      } else if (metadata.summary != null && metadata.summary!.isNotEmpty) {
        _overviewFocusNode.requestFocus();
        _scrollSectionIntoView(_overviewSectionKey);
      } else {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        _playButtonFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }

    // DOWN: consume (nothing below extras to focus)
    if (key.isDownKey) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the cast row (locked focus pattern)
  KeyEventResult _handleCastKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    final metadata = _fullMetadata ?? widget.metadata;
    final roleCount = metadata.role?.length ?? 0;

    // LEFT: previous cast member
    if (key.isLeftKey) {
      if (_focusedCastIndex > 0) {
        setState(() => _focusedCastIndex--);
        scrollListToIndex(_castScrollController, _focusedCastIndex, itemExtent: 120.0 + 4);
      }
      return KeyEventResult.handled;
    }

    // RIGHT: next cast member
    if (key.isRightKey) {
      if (_focusedCastIndex < roleCount - 1) {
        setState(() => _focusedCastIndex++);
        scrollListToIndex(_castScrollController, _focusedCastIndex, itemExtent: 120.0 + 4);
      }
      return KeyEventResult.handled;
    }

    // UP: season tabs → overview → play button
    if (key.isUpKey) {
      // If episodes are visible, focus the last episode (cast is right below episodes)
      if (_episodes.isNotEmpty) {
        // For single episode, _lastEpisodeFocusNode isn't attached — use first
        final target = _episodes.length == 1 ? _firstEpisodeFocusNode : _lastEpisodeFocusNode;
        target.requestFocus();
        return KeyEventResult.handled;
      }
      if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
        _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
        _scrollSectionIntoView(_seasonsSectionKey);
      } else if (metadata.summary != null && metadata.summary!.isNotEmpty) {
        _overviewFocusNode.requestFocus();
        _scrollSectionIntoView(_overviewSectionKey);
      } else {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        _playButtonFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }

    // DOWN: extras (if available) → consume
    if (key.isDownKey) {
      if (_extras != null && _extras!.isNotEmpty) {
        _extrasFocusNode.requestFocus();
        _scrollSectionIntoView(_extrasSectionKey);
      }
      return KeyEventResult.handled;
    }

    // SELECT: consume (cast is informational)
    if (key.isSelectKey) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Build episode list directly when the library hides seasons for single-season shows
  Widget _buildEpisodesList() {
    final client = _getClientForMetadata(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final episode = _episodes[index];
        String? localPosterPath;
        if (widget.isOffline && episode.serverId != null) {
          final artworkRef = context.read<DownloadProvider>().getArtworkPaths(episode.globalKey);
          localPosterPath = artworkRef?.getLocalPath(DownloadStorageService.instance, episode.serverId!);
        }
        return EpisodeCard(
          episode: episode,
          client: client,
          isOffline: widget.isOffline,
          autofocus: false,
          focusNode: index == 0
              ? _firstEpisodeFocusNode
              : index == _episodes.length - 1 && _episodes.length > 1
                  ? _lastEpisodeFocusNode
                  : null,
          onNavigateUp: index == 0 ? _focusSelectedSeasonTab : null,
          localPosterPath: localPosterPath,
          onTap: () async {
            await navigateToVideoPlayerWithRefresh(
              context,
              metadata: episode,
              isOffline: widget.isOffline,
              onRefresh: () async {
                final refreshed = await client?.getMetadataWithImages(episode.ratingKey);
                if (refreshed != null) {
                  setStateIfMounted(() {
                    _episodes[index] = refreshed;
                    _syncEpisodeToCache(index, refreshed);
                  });
                }
              },
            );
          },
          onRefresh: widget.isOffline
              ? null
              : (ratingKey) async {
                  final refreshed = await client?.getMetadataWithImages(ratingKey);
                  if (refreshed != null) {
                    setStateIfMounted(() {
                      final i = _episodes.indexWhere((e) => e.ratingKey == ratingKey);
                      if (i != -1) {
                        _episodes[i] = refreshed;
                        _syncEpisodeToCache(i, refreshed);
                      }
                    });
                  }
                },
          onListRefresh: widget.isOffline ? null : _refreshCurrentEpisodes,
        );
      },
    );
  }

  /// Sync an updated episode back into the episode cache
  void _syncEpisodeToCache(int episodeIndex, PlexMetadata updated) {
    if (_showEpisodesDirectly || _seasons.isEmpty) return;
    if (_selectedSeasonIndex >= _seasons.length) return;
    final season = _seasons[_selectedSeasonIndex];
    final cached = _episodeCache[season.ratingKey];
    if (cached != null && episodeIndex < cached.length) {
      cached[episodeIndex] = updated;
    }
  }

  /// Refresh episodes for the current context (inline season or all flattened)
  Future<void> _refreshCurrentEpisodes() async {
    if (_showEpisodesDirectly) {
      await _fetchAllEpisodes();
    } else if (_seasons.isNotEmpty) {
      // Clear cache for current season and re-fetch
      final season = _seasons[_selectedSeasonIndex];
      _episodeCache.remove(season.ratingKey);
      await _fetchSeasonEpisodes(_selectedSeasonIndex);
    }
  }

  Future<void> _fetchAllEpisodes() async {
    if (_seasons.isEmpty) return;
    final client = _getClientForMetadata(context);
    if (client == null) return;
    setStateIfMounted(() => _isLoadingEpisodes = true);
    try {
      final episodeLists = await Future.wait(
        _seasons.map((season) => client.getChildren(season.ratingKey)),
      );
      setStateIfMounted(() {
        _episodes = episodeLists.expand((e) => e).toList();
        _isLoadingEpisodes = false;
      });
    } catch (_) {
      setStateIfMounted(() => _isLoadingEpisodes = false);
    }
  }

  /// Load the next unwatched episode for offline mode (offline OnDeck)
  Future<void> _loadOfflineOnDeckEpisode() async {
    final offlineWatchProvider = context.read<OfflineWatchProvider>();
    final nextEpisode = await offlineWatchProvider.getNextUnwatchedEpisode(widget.metadata.ratingKey);

    if (nextEpisode != null) {
      setStateIfMounted(() {
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
        setStateIfMounted(() {
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
      if (_isLoadingSeasons && _seasonsCompleter != null) {
        await _seasonsCompleter!.future.timeout(const Duration(seconds: 10), onTimeout: () {});
      }

      if (!mounted) return;

      if (_seasons.isEmpty) {
        if (mounted) {
          showErrorSnackBar(context, t.messages.noSeasonsFound);
        }
        return;
      }

      // Skip Season 0 (Specials) — prefer the first regular season
      final firstSeason = _seasons.firstWhere((s) => (s.index ?? 0) > 0, orElse: () => _seasons.first);

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
      await playbackState.setPlaybackFromPlayQueue(playQueue, showRatingKey);

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
    final isMobile = PlatformDetector.isMobile(context);
    final isTv = PlatformDetector.isTV();

    KeyEventResult handleBack(FocusNode _, KeyEvent event) =>
        handleBackKeyNavigation(context, event, result: _watchStateChanged);

    // Show loading state while fetching full metadata
    if (_isLoadingMetadata) {
      final loading = Focus(
        onKeyEvent: handleBack,
        child: Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
      final blockSystemBack = Platform.isAndroid && InputModeTracker.isKeyboardMode(context);
      if (!blockSystemBack) {
        return loading;
      }
      return PopScope(
        canPop: false, // Prevent system back from double-popping on Android keyboard/TV
        // ignore: no-empty-block - required callback, blocks system back on Android TV
        onPopInvokedWithResult: (didPop, result) {},
        child: loading,
      );
    }

    // Determine header height based on screen size
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.6;

    final content = OverlaySheetHost(
      child: Focus(
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
                          child: (metadata.art != null || metadata.backgroundSquare != null)
                              ? Builder(
                                  builder: (context) {
                                    final containerAspect = size.width / headerHeight;
                                    final heroArtPath = metadata.heroArt(containerAspectRatio: containerAspect);

                                    // Check for offline local file first
                                    if (widget.isOffline && widget.metadata.serverId != null) {
                                      final localPath = context.read<DownloadProvider>().getArtworkLocalPath(
                                        widget.metadata.serverId!,
                                        heroArtPath,
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
                                    final dpr = PlexImageHelper.effectiveDevicePixelRatio(context);
                                    final imageUrl = PlexImageHelper.getOptimizedImageUrl(
                                      client: client,
                                      thumbPath: heroArtPath,
                                      maxWidth: mediaQuery.size.width,
                                      maxHeight: mediaQuery.size.height * 0.6,
                                      devicePixelRatio: dpr,
                                      imageType: ImageType.art,
                                    );

                                    return blurArtwork(
                                      CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const PlaceholderContainer(),
                                        errorWidget: (context, url, error) => const PlaceholderContainer(),
                                      ),
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
                                          final dpr = PlexImageHelper.effectiveDevicePixelRatio(context);
                                          final logoUrl = PlexImageHelper.getOptimizedImageUrl(
                                            client: client,
                                            thumbPath: metadata.clearLogo,
                                            maxWidth: 400,
                                            maxHeight: 120,
                                            devicePixelRatio: dpr,
                                            imageType: ImageType.logo,
                                          );

                                          return blurArtwork(
                                            CachedNetworkImage(
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
                                            ),
                                            sigma: 10,
                                            clip: false,
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
                                      if (metadata.editionTitle != null) _buildMetadataChip(metadata.editionTitle!),
                                      if (metadata.contentRating != null)
                                        _buildMetadataChip(formatContentRating(metadata.contentRating!)),
                                      if (metadata.duration != null)
                                        _buildMetadataChip(formatDurationTextual(metadata.duration!)),
                                      ..._buildRatingChips(metadata),
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
                          if (metadata.summary != null && metadata.summary!.isNotEmpty) ...[
                            Text(
                              key: _overviewSectionKey,
                              t.discover.overview,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Focus(
                              focusNode: _overviewFocusNode,
                              onKeyEvent: _handleOverviewKeyEvent,
                              onFocusChange: (_) => setState(() {}),
                              child: Builder(
                                builder: (context) {
                                  final showFocus =
                                      _overviewFocusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      border: Border.all(
                                        color: showFocus
                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: () {
                                      final summaryStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6);
                                      if (isTv) {
                                        return Text(metadata.summary!, style: summaryStyle);
                                      }
                                      return CollapsibleText(
                                        text: metadata.summary!,
                                        maxLines: isMobile ? 6 : 4,
                                        style: summaryStyle,
                                      );
                                    }(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Seasons / Episodes (for TV shows and seasons)
                          if (isShow && !_showEpisodesDirectly) ...[
                            // Season tabs + inline episodes
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
                            else ...[
                              Text(
                                key: _seasonsSectionKey,
                                t.libraries.groupings.episodes,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildSeasonTabs(),
                              const SizedBox(height: 16),
                              if (_isLoadingSeasonEpisodes)
                                const Center(
                                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                                )
                              else if (_episodes.isNotEmpty)
                                _buildEpisodesList()
                              else
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      t.messages.noEpisodesFoundGeneral,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 24),
                          ] else if ((isShow && _showEpisodesDirectly) || metadata.isSeason) ...[
                            // Server says flatten — existing behavior unchanged
                            Text(
                              key: _seasonsSectionKey,
                              t.libraries.groupings.episodes,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingSeasons || _isLoadingEpisodes)
                              const Center(
                                child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                              )
                            else if (_episodes.isNotEmpty)
                              _buildEpisodesList()
                            else
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    t.messages.noEpisodesFoundGeneral,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],

                          // Cast
                          if (metadata.role != null && metadata.role!.isNotEmpty) ...[
                            Text(
                              key: _castSectionKey,
                              t.discover.cast,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildCastSection(metadata),
                            const SizedBox(height: 24),
                          ],

                          // Trailers & Extras Section
                          if (!widget.isOffline && _extras != null && _extras!.isNotEmpty) ...[
                            Text(
                              key: _extrasSectionKey,
                              t.discover.extras,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildExtrasSection(),
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
                  SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
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
      ),
    );

    final blockSystemBack = Platform.isAndroid && InputModeTracker.isKeyboardMode(context);
    if (!blockSystemBack) {
      return content;
    }

    return PopScope(
      canPop: false, // Prevent system back from double-popping on Android keyboard/TV
      // ignore: no-empty-block - required callback, blocks system back on Android TV
      onPopInvokedWithResult: (didPop, result) {},
      child: content,
    );
  }

  /// Get the primary trailer from the extras list
  PlexMetadata? _getPrimaryTrailer() {
    if (_extras == null || _extras!.isEmpty) return null;

    // If there's a primaryExtraKey, try to find that specific trailer
    final metadata = _fullMetadata ?? widget.metadata;
    if (metadata.primaryExtraKey != null) {
      // Extract rating key from primaryExtraKey (e.g., "/library/metadata/52601" -> "52601")
      final primaryKey = metadata.primaryExtraKey!.split('/').last;
      try {
        return _extras!.firstWhere((extra) => extra.ratingKey == primaryKey);
      } catch (_) {
        // Primary key not found, fall through to find any trailer
      }
    }

    // Otherwise, find the first item with subtype 'trailer'
    try {
      return _extras!.firstWhere((extra) => extra.subtype == 'trailer');
    } catch (_) {
      // No trailer found, return null (button won't appear)
      return null;
    }
  }

  /// Build the cast section with locked focus pattern for D-pad navigation
  /// Uses same layout pattern as seasons/extras (ListView.builder + Padding(horizontal: 2))
  Widget _buildCastSection(PlexMetadata metadata) {
    const cardWidth = 120.0;
    const innerPadding = 6.0;
    // image + inner padding + text area + outer list padding + focus scale headroom
    const containerHeight = 120.0 + innerPadding * 2 + 66 + 16;

    final hasFocus = _castFocusNode.hasFocus;

    return Focus(
      focusNode: _castFocusNode,
      onKeyEvent: _handleCastKeyEvent,
      onFocusChange: (_) => setState(() {}),
      child: SizedBox(
        height: containerHeight,
        child: HorizontalScrollWithArrows(
          controller: _castScrollController,
          builder: (scrollController) => ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            itemCount: metadata.role!.length,
            itemBuilder: (context, index) {
              final actor = metadata.role![index];
              final isFocused = hasFocus && index == _focusedCastIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FocusBuilders.buildLockedFocusWrapper(
                  context: context,
                  isFocused: isFocused,
                  borderRadius: tokens(context).radiusSm,
                  child: Padding(
                    padding: const EdgeInsets.all(innerPadding),
                    child: SizedBox(
                      width: cardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                            child: PlexOptimizedImage(
                              client: _getClientForMetadata(context),
                              imagePath: actor.thumb,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              imageType: ImageType.avatar,
                              fallbackIcon: Symbols.person_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  actor.tag,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                                    maxLines: 1,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasSection() {
    final cardWidth = _getResponsiveCardWidth();
    // 16:9 aspect ratio for clip thumbnails (cardWidth includes 8px padding on each side)
    final posterHeight = (cardWidth - 16) * (9 / 16);
    final containerHeight = posterHeight + 66;

    final hasFocus = _extrasFocusNode.hasFocus;

    return Focus(
      focusNode: _extrasFocusNode,
      onKeyEvent: _handleExtrasKeyEvent,
      child: SizedBox(
        height: containerHeight,
        child: HorizontalScrollWithArrows(
          controller: _extrasScrollController,
          builder: (scrollController) => ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            itemCount: _extras!.length,
            itemBuilder: (context, index) {
              final extra = _extras![index];
              final isFocused = hasFocus && index == _focusedExtraIndex;
              final cardKey = _extraCardKeys.putIfAbsent(index, () => GlobalKey<MediaCardState>());

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FocusBuilders.buildLockedFocusWrapper(
                  context: context,
                  isFocused: isFocused,
                  onTap: () => navigateToVideoPlayer(context, metadata: extra),
                  child: MediaCard(
                    key: cardKey,
                    item: extra,
                    width: cardWidth,
                    height: posterHeight,
                    forceGridMode: true,
                  ),
                ),
              );
            },
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

