import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_service.dart';
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
import '../exceptions/media_server_exceptions.dart';
import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../utils/provider_extensions.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_role.dart';
import '../widgets/media_card.dart';
import '../i18n/strings.g.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/media_image_helper.dart';
import '../services/plex_client.dart';
import '../media/media_server_client.dart';
import '../services/media_list_playback_launcher.dart';
import '../services/offline_watch_sync_service.dart';
import '../utils/content_utils.dart';
import '../utils/rating_utils.dart';
import '../models/download_models.dart';
import '../services/download_storage_service.dart';
import '../utils/download_version_utils.dart';
import '../utils/download_utils.dart';
import '../providers/settings_provider.dart';
import '../utils/grid_size_calculator.dart';
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
import 'actor_media_screen.dart';
import '../widgets/focusable_tab_chip.dart';
import '../widgets/hub_section.dart';
import '../widgets/loading_indicator_box.dart';

enum _SyncRuleAction { edit, remove, delete }

class MediaDetailScreen extends StatefulWidget {
  final MediaItem metadata;
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
  /// Public input alias — used as the live source of truth until the detail
  /// fetch returns. Holds backend-neutral [MediaItem] data.
  MediaItem get _metadata => _fullMetadata ?? widget.metadata;
  List<MediaItem> _seasons = [];
  bool _isLoadingSeasons = false;
  Completer<void>? _seasonsCompleter;
  List<MediaItem> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _showEpisodesDirectly = false;
  MediaItem? _fullMetadata;
  MediaItem? _onDeckEpisode;
  bool _isLoadingMetadata = true;
  List<MediaItem>? _extras;
  List<MediaHub> _relatedHubs = [];
  List<GlobalKey<HubSectionState>> _relatedHubKeys = [];
  late final ScrollController _scrollController;
  final ScrollController _extrasScrollController = ScrollController();
  bool _watchStateChanged = false;
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  // Inline season tabs
  int _selectedSeasonIndex = 0;
  final Map<String, List<MediaItem>> _episodeCache = {};
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

  // Focus target for the trailing info rows (studio / contentRating)
  late final FocusNode _infoRowsFocusNode;
  final _infoRowsSectionKey = GlobalKey();

  @override
  MediaItem get serverBoundMetadata => _metadata;

  @override
  bool get isServerBoundOffline => widget.isOffline;

  // WatchStateAware: watch the show/movie and all season/episode ratingKeys
  @override
  Set<String>? get watchedIds {
    final keys = <String>{_metadata.id};
    for (final season in _seasons) {
      keys.add(season.id);
    }
    for (final ep in _episodes) {
      keys.add(ep.id);
    }
    return keys;
  }

  @override
  String? get watchStateServerId => serverBoundServerId;

  @override
  Set<String>? get watchedGlobalKeys {
    final serverId = serverBoundServerId;
    if (serverId == null) return null;

    final keys = <String>{toServerBoundGlobalKey(_metadata.id, serverId: serverId)};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.id, serverId: season.serverId ?? serverId));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.id, serverId: ep.serverId ?? serverId));
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    final epIndex = _episodes.indexWhere((e) => e.id == event.itemId);

    if (widget.isOffline) {
      // Offline: skip network refetch — patch the affected episode (or
      // the show metadata) in-memory using the local watch flag the event
      // already carries. The sync service drains queued actions to the
      // server when the device reconnects.
      if (epIndex != -1 && event.isNowWatched != null) {
        setStateIfMounted(() {
          final updated = _episodes[epIndex].copyWith(
            viewCount: event.isNowWatched! ? 1 : 0,
            viewOffsetMs: event.isNowWatched! ? _episodes[epIndex].viewOffsetMs : 0,
          );
          _episodes[epIndex] = updated;
          _syncEpisodeToCache(epIndex, updated);
        });
      } else if (event.itemId == _metadata.id) {
        unawaited(_updateWatchStateOffline());
      }
      return;
    }

    // Online: re-fetch the affected row so server-derived counters
    // (parent leafCounts, lastViewedAt) refresh too.
    if (epIndex != -1) {
      _updateEpisodeWatchState(event.itemId);
    } else {
      _refreshWatchState();
    }
  }

  @override
  Set<String>? get deletionIds {
    final keys = <String>{_metadata.id};
    for (final season in _seasons) {
      keys.add(season.id);
    }
    for (final ep in _episodes) {
      keys.add(ep.id);
    }
    return keys;
  }

  @override
  String? get deletionServerId => serverBoundServerId;

  @override
  Set<String>? get deletionGlobalKeys {
    final serverId = serverBoundServerId;
    if (serverId == null) return null;

    final keys = <String>{toServerBoundGlobalKey(_metadata.id, serverId: serverId)};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.id, serverId: season.serverId ?? serverId));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.id, serverId: ep.serverId ?? serverId));
    }
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // Download-only deletions should only remove items when viewing offline content
    if (event.isDownloadOnly && !widget.isOffline) return;
    if (!event.isDownloadOnly && widget.isOffline) return;

    // Drop the episode from any visible/cached list. This fires whether we're
    // showing a flattened episode list or a season-tabs view of a show.
    final epIndex = _episodes.indexWhere((e) => e.id == event.itemId);
    if (epIndex != -1) {
      setState(() {
        _episodes.removeAt(epIndex);
      });
    }
    for (final cached in _episodeCache.values) {
      cached.removeWhere((e) => e.id == event.itemId);
    }

    if (epIndex != -1 && _showEpisodesDirectly) {
      if (_episodes.isEmpty && (_metadata.isSeason || _metadata.isShow) && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // If we have a season that matches the rating key exactly, then remove it from our list
    final seasonIndex = _seasons.indexWhere((s) => s.id == event.itemId);
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
      final idx = _seasons.indexWhere((s) => s.id == parentKey);
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
    // Backend-neutral. Plex bundles metadata + on-deck in one round-trip
    // (`?includeOnDeck=1`); Jellyfin's [fetchItemWithOnDeck] returns
    // onDeckEpisode=null and on-deck repopulates from cached lists on
    // the next navigation.
    final mediaClient = _getMediaClientForMetadata(context);
    if (mediaClient == null) return;
    final serverId = _metadata.serverId;
    if (serverId == null) return;
    final serverName = _metadata.serverName;

    try {
      final result = await mediaClient.fetchItemWithOnDeck(_metadata.id);
      final metadata = result.item;
      final onDeckEpisode = result.onDeckEpisode;
      if (metadata != null) {
        setStateIfMounted(() {
          _fullMetadata = metadata.copyWith(serverId: serverId, serverName: serverName);
          if (onDeckEpisode != null) {
            _onDeckEpisode = onDeckEpisode.copyWith(serverId: serverId, serverName: serverName);
          }
        });
      }

      if (_metadata.isShow) {
        final seasons = await mediaClient.fetchChildren(_metadata.id);
        _episodeCache.clear();
        setStateIfMounted(() {
          _seasons = seasons.map((s) => s.copyWith(serverId: serverId, serverName: serverName)).toList();
        });
        if (_showEpisodesDirectly) {
          await _fetchAllEpisodes();
        } else if (_seasons.isNotEmpty) {
          unawaited(_fetchSeasonEpisodes(_selectedSeasonIndex));
        }
      } else if (_metadata.isSeason) {
        _episodeCache.clear();
        await _fetchAllEpisodes();
      }
    } catch (e) {
      appLogger.d('Watch-state refresh failed', error: e);
    }
  }

  /// Update a single episode's watch state without refetching everything.
  /// Backend-neutral so Jellyfin items refresh in place when their
  /// watched flag changes (the previous Plex-only path no-op'd for
  /// Jellyfin and left the row stale).
  Future<void> _updateEpisodeWatchState(String ratingKey) async {
    final mediaClient = _getMediaClientForMetadata(context);
    if (mediaClient == null) return;
    try {
      final refreshed = await mediaClient.fetchItem(ratingKey);
      if (refreshed != null) {
        setStateIfMounted(() {
          final i = _episodes.indexWhere((e) => e.id == ratingKey);
          if (i != -1) {
            _episodes[i] = refreshed;
            _syncEpisodeToCache(i, refreshed);
          }
        });
      }
    } catch (e) {
      appLogger.d('Episode cache sync skipped', error: e);
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
    _infoRowsFocusNode = FocusNode(debugLabel: 'info_rows');
    _loadFullMetadata();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    _extrasScrollController.dispose();
    _extrasFocusNode.dispose();
    _playButtonFocusNode.dispose();
    _ratingChipFocusNode.dispose();
    _overviewFocusNode.dispose();
    _castFocusNode.dispose();
    _infoRowsFocusNode.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;
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
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary.withValues(alpha: 0.2)),
            ),
          // Progress circle (indeterminate if no progress, determinate otherwise)
          CircularProgressIndicator(
            value: (progressPercent != null && progressPercent > 0) ? progressPercent : null, // null = indeterminate
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  /// Build action buttons row (play, shuffle, download, mark watched)
  Widget _buildActionButtons(MediaItem metadata) {
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
          // Download button (hide in offline mode - already downloaded,
          // and on Apple TV where there's no user file storage).
          if (!widget.isOffline && !PlatformDetector.isAppleTV())
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, _) {
                final globalKey = metadata.globalKey;
                final ruleKey = _syncRuleKeyForMetadata(context, downloadProvider, metadata);
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
                    icon: const LoadingIndicatorBox(size: 20),
                    iconSize: 20,
                    style: actionButtonStyle(),
                  );
                }

                // State 2: Queued (waiting to download)
                if (progress?.status == DownloadStatus.queued) {
                  final currentFile = progress?.currentFile;
                  final tooltip = currentFile != null && currentFile.contains('episodes')
                      ? t.downloads.queuedFilesTooltip(files: currentFile)
                      : t.downloads.queuedTooltip;

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
                      ? t.downloads.downloadingFilesTooltip(files: currentFile)
                      : t.downloads.downloadingTooltip;

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
                      final client = _getMediaClientForMetadata(context);
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
                      final client = _getMediaClientForMetadata(context);
                      if (client == null) return;

                      final versionConfig = await _resolveDownloadVersion(context, metadata, client);
                      if (versionConfig == null || !context.mounted) return;

                      await downloadProvider.deleteDownload(globalKey);
                      try {
                        await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);

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
                        final client = _getMediaClientForMetadata(context);
                        if (client == null) return;

                        final versionConfig = await _resolveDownloadVersion(context, metadata, client);
                        if (versionConfig == null || !context.mounted) return;

                        await downloadProvider.deleteDownload(globalKey);
                        try {
                          await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);
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
                  final hasSyncRule = downloadProvider.hasSyncRule(ruleKey);
                  final currentFile = progress?.currentFile;

                  if (hasSyncRule) {
                    // Synced partial — this is the normal state for sync rules
                    final syncRule = downloadProvider.getSyncRule(ruleKey);
                    final isEnabled = syncRule?.enabled ?? true;
                    final tooltip = currentFile != null
                        ? '$currentFile (syncing ${t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?')})'
                        : t.downloads.keepSynced;

                    return IconButton.filledTonal(
                      onPressed: () => _showSyncRuleActions(
                        context,
                        downloadProvider,
                        metadata,
                        ruleKey: ruleKey,
                        downloadGlobalKey: globalKey,
                      ),
                      tooltip: tooltip,
                      icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
                      iconSize: 20,
                      style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey),
                    );
                  }

                  final tooltip = currentFile != null
                      ? 'Downloaded $currentFile - Click to complete'
                      : 'Partially downloaded - Click to complete';

                  return IconButton.filledTonal(
                    onPressed: () async {
                      final client = _getMediaClientForMetadata(context);
                      if (client == null) return;

                      final versionConfig = await _resolveDownloadVersion(context, metadata, client);
                      if (versionConfig == null || !context.mounted) return;

                      final count = await downloadProvider.queueMissingEpisodes(
                        metadata,
                        client,
                        versionConfig: versionConfig,
                      );

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
                  final hasSyncRule = downloadProvider.hasSyncRule(ruleKey);

                  if (hasSyncRule) {
                    // Synced + complete — show sync icon
                    final syncRule = downloadProvider.getSyncRule(ruleKey);
                    final isEnabled = syncRule?.enabled ?? true;
                    return IconButton.filledTonal(
                      onPressed: () => _showSyncRuleActions(
                        context,
                        downloadProvider,
                        metadata,
                        ruleKey: ruleKey,
                        downloadGlobalKey: globalKey,
                      ),
                      icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
                      tooltip: t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?'),
                      iconSize: 20,
                      style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey),
                    );
                  }

                  return IconButton.filledTonal(
                    onPressed: () async {
                      // Show delete download confirmation
                      final confirmed = await showDeleteConfirmation(
                        context,
                        title: t.downloads.deleteDownload,
                        message: t.downloads.deleteConfirm(title: metadata.displayTitle),
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
                    final client = _getMediaClientForMetadata(context);
                    if (client == null) return;

                    try {
                      final result = await showDownloadOptionsAndQueue(
                        context,
                        metadata: metadata,
                        client: client,
                        downloadProvider: downloadProvider,
                      );
                      if (result == null || !context.mounted) return;

                      showSuccessSnackBar(context, result.toSnackBarMessage());
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
                    await offlineWatch.markAsUnwatched(serverId: metadata.serverId!, itemId: metadata.id);
                  } else {
                    await offlineWatch.markAsWatched(serverId: metadata.serverId!, itemId: metadata.id);
                  }
                  if (mounted) {
                    showAppSnackBar(
                      context,
                      isWatched ? t.messages.markedAsUnwatchedOffline : t.messages.markedAsWatchedOffline,
                    );
                    unawaited(_updateWatchStateOffline());
                    unawaited(_loadOfflineOnDeckEpisode());
                  }
                } else {
                  // Online mode: dispatch via the right backend's neutral
                  // method so Jellyfin items hit /UserPlayedItems and Plex
                  // items hit /:/scrobble.
                  final serverId = metadata.serverId;
                  if (serverId == null) return;
                  final client = context.tryGetMediaClientForServer(serverId);
                  if (client == null) return;

                  if (isWatched) {
                    await client.markUnwatched(metadata);
                  } else {
                    await client.markWatched(metadata);
                  }
                  if (mounted) {
                    _watchStateChanged = true;
                    showSuccessSnackBar(context, isWatched ? t.messages.markedAsUnwatched : t.messages.markedAsWatched);
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
    final colorScheme = Theme.of(context).colorScheme;
    final textWidget = Text(
      text,
      style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.w500),
    );

    final hasLeading = leading != null || icon != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: hasLeading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null)
                  leading
                else
                  AppIcon(icon!, fill: 1, color: colorScheme.onSecondaryContainer, size: 16),
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
  List<Widget> _buildRatingChips(MediaItem metadata) {
    final chips = <Widget>[];
    // Plex-only fields (audienceRating / ratingImage / audienceRatingImage)
    // — Jellyfin lacks rating-source attribution. Pull them via a typed
    // narrow so the rest of the chip layout stays backend-neutral.
    final plex = metadata is PlexMediaItem ? metadata : null;
    final audienceRating = plex?.audienceRating;
    final ratingImage = plex?.ratingImage;
    final audienceRatingImage = plex?.audienceRatingImage;
    final bothRT =
        metadata.rating != null &&
        audienceRating != null &&
        isRottenTomatoes(ratingImage) &&
        isRottenTomatoes(audienceRatingImage);

    if (bothRT) {
      final critic = parseRatingImage(ratingImage, metadata.rating)!;
      final audience = parseRatingImage(audienceRatingImage, audienceRating)!;
      chips.add(_buildCombinedRtChip(critic, audience));
    } else {
      if (metadata.rating != null) {
        chips.add(_buildRatingChip(ratingImage, metadata.rating!, Symbols.star_rounded));
      }
      if (audienceRating != null) {
        chips.add(_buildRatingChip(audienceRatingImage, audienceRating, Symbols.people_rounded));
      }
    }

    // User rating chip (tappable)
    if (!widget.isOffline) {
      chips.add(_buildUserRatingChip(metadata));
    }

    return chips;
  }

  Widget _buildUserRatingChip(MediaItem metadata) {
    final mediaClient = _getMediaClientForMetadata(context);
    final isNumeric = mediaClient?.capabilities.numericUserRating ?? true;
    final hasRating = metadata.userRating != null && metadata.userRating! > 0;
    final starValue = hasRating ? metadata.userRating! / 2.0 : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final showFocus = _ratingChipFocusNode.hasFocus && isKeyboardMode;

    final bgColor = showFocus ? colorScheme.inverseSurface : colorScheme.secondaryContainer.withValues(alpha: 0.8);
    final fgColor = showFocus ? colorScheme.onInverseSurface : colorScheme.onSecondaryContainer;

    final activate = isNumeric ? () => _showRatingDialog(metadata, starValue) : () => _toggleLike(metadata);

    final iconData = isNumeric ? Symbols.star_rounded : Symbols.thumb_up_rounded;
    final activeIconColor = isNumeric ? Colors.amber : Colors.teal;
    // Numeric backends show the formatted rating when set; binary backends
    // rely on the filled icon to communicate the like state and keep the
    // "Rate" label as the action prompt either way.
    final label = isNumeric && hasRating ? formatRating(starValue) : t.mediaMenu.rate;

    return FocusableWrapper(
      focusNode: _ratingChipFocusNode,
      onSelect: activate,
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
        onTap: activate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.all(Radius.circular(100))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                iconData,
                fill: hasRating ? 1 : 0,
                color: showFocus ? fgColor : (hasRating ? activeIconColor : fgColor),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: fgColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Like/unlike toggle for backends that only support binary ratings
  /// (Jellyfin). Maps to [MediaServerClient.rate] with 10 (like) or -1
  /// (clear) — the Jellyfin client routes those through POST/DELETE on
  /// `/UserItems/{id}/Rating`.
  Future<void> _toggleLike(MediaItem metadata) async {
    final client = _getMediaClientForMetadata(context);
    if (client == null) return;
    final wasLiked = metadata.userRating != null && metadata.userRating! >= 6;
    final newRating = wasLiked ? -1.0 : 10.0;
    try {
      await client.rate(metadata, newRating);
      setStateIfMounted(() {
        _fullMetadata = _fullMetadata?.copyWith(userRating: wasLiked ? 0 : 10);
      });
    } on MediaServerHttpException catch (e) {
      appLogger.w('Failed to toggle rating', error: e);
      if (mounted) showErrorSnackBar(context, t.errors.failedToRate);
    }
  }

  void _showRatingDialog(MediaItem metadata, double currentStarValue) {
    showModalBottomSheet(
      context: context,
      builder: (context) => RatingBottomSheet(
        currentRating: currentStarValue,
        onRate: (stars) async {
          final client = _getMediaClientForMetadata(this.context);
          if (client == null) return;
          final plexRating = stars * 2.0; // Convert 0-5 stars to 0-10 scale
          try {
            await client.rate(metadata, plexRating);
            setStateIfMounted(() {
              _fullMetadata = _fullMetadata?.copyWith(userRating: plexRating);
            });
          } on MediaServerHttpException catch (e) {
            appLogger.w('Failed to set rating', error: e);
            if (mounted) showErrorSnackBar(this.context, t.errors.failedToRate);
          }
        },
        onClear: () async {
          final client = _getMediaClientForMetadata(this.context);
          if (client == null) return;
          try {
            await client.rate(metadata, -1);
            setStateIfMounted(() {
              _fullMetadata = _fullMetadata?.copyWith(userRating: 0);
            });
          } on MediaServerHttpException catch (e) {
            appLogger.w('Failed to clear rating', error: e);
            if (mounted) showErrorSnackBar(this.context, t.errors.failedToRate);
          }
        },
      ),
    );
  }

  /// Build a combined RT chip showing critic + audience side by side.
  Widget _buildCombinedRtChip(RatingInfo critic, RatingInfo audience) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.8),
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

  /// Backend-neutral counterpart of [getServerBoundPlexClient]. Returns a
  /// [MediaServerClient] for Jellyfin items too, so image URLs use the
  /// right server's transcoder.
  MediaServerClient? _getMediaClientForMetadata(BuildContext context) {
    return getServerBoundMediaClient(context);
  }

  String _syncRuleKeyForMetadata(BuildContext context, DownloadProvider downloadProvider, MediaItem metadata) {
    final serverId = metadata.serverId;
    final client = _getMediaClientForMetadata(context);
    if (client == null || serverId == null) return metadata.globalKey;
    return downloadProvider.syncRuleKeyForClient(client, metadata.id, serverId: serverId);
  }

  void _navigateToActorMedia(MediaRole actor) {
    // Plex-only today — Jellyfin's `/Persons/{id}/Items` isn't wired yet.
    // Cast cards still render for parity, but tapping is a no-op until the
    // Jellyfin path lands.
    if (_metadata.backend != MediaBackend.plex) return;
    final personId = actor.id;
    if (personId == null || _metadata.serverId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActorMediaScreen(
          actorName: actor.tag,
          personId: personId,
          actorThumb: actor.thumbPath,
          characterName: actor.role,
          serverId: _metadata.serverId!,
          serverName: _metadata.serverName,
          backend: _metadata.backend,
        ),
      ),
    );
  }

  /// Resolve version selection for download using shared utility.
  Future<DownloadVersionConfig?> _resolveDownloadVersion(
    BuildContext context,
    MediaItem metadata,
    MediaServerClient client,
  ) {
    final fallback = _fullMetadata?.mediaVersions;
    return resolveDownloadVersion(context, metadata, client, fallbackVersions: fallback);
  }

  /// Shows actions for a synced item: edit count, remove rule, delete downloads.
  Future<void> _showSyncRuleActions(
    BuildContext context,
    DownloadProvider downloadProvider,
    MediaItem metadata, {
    required String ruleKey,
    required String downloadGlobalKey,
  }) async {
    final syncRule = downloadProvider.getSyncRule(ruleKey);
    if (syncRule == null) return;

    final selected = await showOptionPickerDialog<_SyncRuleAction>(
      context,
      title: t.downloads.manageSyncRule,
      options: [
        (icon: Symbols.edit_rounded, label: t.downloads.editSyncRule, value: _SyncRuleAction.edit),
        (icon: Symbols.sync_disabled_rounded, label: t.downloads.removeSyncRule, value: _SyncRuleAction.remove),
        (icon: Symbols.delete_rounded, label: t.downloads.deleteDownload, value: _SyncRuleAction.delete),
      ],
    );

    if (selected == null || !context.mounted) return;

    switch (selected) {
      case _SyncRuleAction.edit:
        final updated = await editSyncRuleCount(
          context,
          downloadProvider: downloadProvider,
          globalKey: ruleKey,
          currentCount: syncRule.episodeCount,
        );
        if (updated && context.mounted) {
          showSuccessSnackBar(context, t.downloads.syncRuleUpdated);
        }

      case _SyncRuleAction.remove:
        final removed = await confirmAndRemoveSyncRule(
          context,
          downloadProvider: downloadProvider,
          globalKey: ruleKey,
          displayTitle: metadata.displayTitle,
        );
        if (removed && context.mounted) {
          showSuccessSnackBar(context, t.downloads.syncRuleRemoved);
        }

      case _SyncRuleAction.delete:
        final confirmed = await showDeleteConfirmation(
          context,
          title: t.downloads.deleteDownload,
          message: t.downloads.deleteConfirm(title: metadata.displayTitle),
        );
        if (confirmed && context.mounted) {
          await downloadProvider.deleteSyncRule(ruleKey);
          await downloadProvider.deleteDownload(downloadGlobalKey);
          if (context.mounted) {
            showSuccessSnackBar(context, t.downloads.downloadDeleted);
          }
        }
    }
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    // Offline mode: try to load full metadata from cache (has clearLogo, summary, etc.)
    if (widget.isOffline) {
      final cachedMetadata = await context.read<DownloadProvider>().lookupOfflineMetadata(
        _metadata.serverId ?? '',
        _metadata.id,
      );
      if (!mounted) return;
      setState(() {
        _fullMetadata = cachedMetadata ?? _metadata;
        _isLoadingMetadata = false;
      });

      if (_metadata.isShow) {
        _loadSeasonsFromDownloads();
        // Get offline OnDeck episode
        unawaited(_loadOfflineOnDeckEpisode());
      } else if (_metadata.isSeason) {
        _seasons = [_metadata];
        _showEpisodesDirectly = true;
        _loadEpisodesFromDownloads();
      }
      return;
    }

    try {
      // Backend-neutral lookup. Plex returns the OnDeck episode bundled in
      // the same response (`?includeOnDeck=1`); Jellyfin's
      // [fetchItemWithOnDeck] returns onDeckEpisode=null and the UI
      // populates resume separately if needed.
      final client = getServerBoundMediaClient(context);
      if (client == null) {
        // Truly orphaned item (server gone) — fall back to widget metadata
        // and let downstream loaders no-op gracefully.
        setState(() {
          _fullMetadata = _metadata;
          _isLoadingMetadata = false;
        });
        return;
      }

      final result = await client.fetchItemWithOnDeck(_metadata.id);
      final metadata = result.item;
      final onDeckEpisode = result.onDeckEpisode;

      if (!mounted) return;

      // Preserve serverId from original metadata
      final serverId = _metadata.serverId;
      final serverName = _metadata.serverName;
      final base = (metadata ?? _metadata).copyWith(serverId: serverId, serverName: serverName);
      final onDeckWithServerId = onDeckEpisode?.copyWith(serverId: serverId, serverName: serverName);

      setState(() {
        _fullMetadata = base;
        _onDeckEpisode = onDeckWithServerId;
        _isLoadingMetadata = false;
      });

      if (base.isShow) {
        unawaited(_loadSeasons());
      } else if (base.isSeason) {
        _seasons = [base];
        _showEpisodesDirectly = true;
        unawaited(_fetchAllEpisodes());
      }

      // [_loadExtras] and [_loadRelatedHubs] short-circuit for non-Plex
      // backends; safe to call unconditionally.
      unawaited(_loadExtras());
      unawaited(_loadRelatedHubs());
    } catch (e) {
      // Fallback to passed metadata on error
      if (!mounted) return;
      setState(() {
        _fullMetadata = _metadata;
        _isLoadingMetadata = false;
      });

      if (_metadata.isShow) {
        unawaited(_loadSeasons());
      } else if (_metadata.isSeason) {
        _seasons = [_metadata];
        _showEpisodesDirectly = true;
        unawaited(_fetchAllEpisodes());
      }
    }
  }

  Future<void> _loadSeasons() async {
    _seasonsCompleter = Completer<void>();
    setStateIfMounted(() {
      _isLoadingSeasons = true;
    });

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (client == null) {
      setStateIfMounted(() => _isLoadingSeasons = false);
      if (!(_seasonsCompleter?.isCompleted ?? true)) _seasonsCompleter?.complete();
      return;
    }

    try {
      // Plex has a server-side "flatten seasons" preference;
      // Jellyfin has no equivalent, so fetch the prefs only when we have
      // a Plex client and a section id. The library section id came from
      // Plex as an int but lands in [MediaItem.libraryId] as the string
      // form (or null on Jellyfin items).
      final sectionId = (_fullMetadata ?? _metadata).libraryId;
      final seasonsFuture = client.fetchChildren(_metadata.id);
      final prefsFuture = (client is PlexClient && sectionId != null)
          ? client.getLibrarySectionPrefs(sectionId)
          : Future.value(<String, dynamic>{});

      final results = await Future.wait([seasonsFuture, prefsFuture]);
      final seasons = results[0] as List<MediaItem>;
      final prefs = results[1] as Map<String, dynamic>;

      // Preserve serverId for each season.
      final seasonsWithServerId = seasons
          .map((season) => season.copyWith(serverId: serverId, serverName: _metadata.serverName))
          .toList();

      // Plex's flattenSeasons modes: 1 = always, 2 = single-season only.
      // Jellyfin falls through to "flatten when there's a single season".
      bool shouldShowEpisodesDirectly;
      if (client is PlexClient) {
        const flattenSeasonsAlways = 1;
        const flattenSeasonsSingleSeason = 2;
        final flattenSeasons = int.tryParse(prefs['flattenSeasons']?.toString() ?? '');
        final isAlways = flattenSeasons == flattenSeasonsAlways;
        final isSingleSeason = flattenSeasons == flattenSeasonsSingleSeason;
        shouldShowEpisodesDirectly =
            isAlways || seasonsWithServerId.isEmpty || (isSingleSeason && seasonsWithServerId.length == 1);
      } else {
        shouldShowEpisodesDirectly = seasonsWithServerId.length <= 1;
      }

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
        unawaited(_fetchSeasonEpisodes(onDeckSeasonIndex));
      }
    } catch (e, st) {
      appLogger.w('Seasons load failed', error: e, stackTrace: st);
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
    final episodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);

    // Group episodes by season
    final Map<int, List<MediaItem>> seasonMap = {};
    for (final episode in episodes) {
      final seasonNum = episode.parentIndex ?? 0;
      seasonMap.putIfAbsent(seasonNum, () => []).add(episode);
    }

    // Create synthetic season MediaItems from the grouped episodes.
    final seasons = seasonMap.entries.map((entry) {
      final firstEp = entry.value.first;
      return MediaItem(
        id: firstEp.parentId ?? '',
        backend: _metadata.backend,
        kind: MediaKind.season,
        title: firstEp.parentTitle ?? 'Season ${entry.key}',
        index: entry.key,
        leafCount: entry.value.length,
        thumbPath: firstEp.parentThumbPath,
        parentId: firstEp.grandparentId,
        serverId: _metadata.serverId,
        serverName: _metadata.serverName,
      );
    }).toList()..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    // Create focus nodes for season tabs and cache episodes per season
    _updateSeasonTabFocusNodes(seasons.length);
    for (final entry in seasonMap.entries) {
      final seasonRatingKey = entry.value.first.parentId ?? '';
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
    final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.parentId ?? '');
    final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == _metadata.index).toList()
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
      _seasonTabFocusNodes = List.generate(count, (i) => FocusNode(debugLabel: 'season_tab_$i'));
      _seasonContextMenuKeys.clear();
    }
  }

  /// Find the season index matching the initial selection or on-deck episode, or fall back to 0
  int _findOnDeckSeasonIndex(List<MediaItem> seasons) {
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
    final cached = _episodeCache[season.id];
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
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);
        final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == season.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        _episodeCache[season.id] = seasonEpisodes;
        setStateIfMounted(() {
          _episodes = List.of(seasonEpisodes);
          _isLoadingSeasonEpisodes = false;
        });
      } else {
        // Resolve the right backend client so Jellyfin (where the typed
        // PlexClient helper returns null) loads episodes too.
        final serverId = _metadata.serverId;
        final mediaClient = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
        if (serverId == null || mediaClient == null) {
          setStateIfMounted(() => _isLoadingSeasonEpisodes = false);
          return;
        }
        final episodes = await mediaClient.fetchChildren(season.id);
        final episodesWithServerId = episodes
            .map(
              (e) => e.copyWith(
                serverId: _metadata.serverId,
                serverName: _metadata.serverName,
                grandparentId: _metadata.id,
                grandparentTitle: _metadata.title,
              ),
            )
            .toList();
        _episodeCache[season.id] = episodesWithServerId;
        setStateIfMounted(() {
          _episodes = List.of(episodesWithServerId);
          _isLoadingSeasonEpisodes = false;
        });
      }
    } catch (e) {
      setStateIfMounted(() => _isLoadingSeasonEpisodes = false);
    }
  }

  /// Load extras (trailers, behind-the-scenes, etc.). Plex-only — Jellyfin
  /// has no equivalent of `fetchExtras`.
  Future<void> _loadExtras() async {
    // Only load extras for movies and shows
    if (!_metadata.isMovie && !_metadata.isShow) {
      return;
    }

    // Skip in offline mode (no server available)
    if (widget.isOffline) {
      return;
    }

    if (_metadata.backend != MediaBackend.plex) return;

    try {
      final client = getServerBoundPlexClient(context);
      if (client == null) {
        return;
      }

      final extras = await client.fetchExtras(_metadata.id);

      // Preserve serverId for each extra (needed for multi-server setups).
      final extrasWithServerId = extras
          .map((extra) => extra.copyWith(serverId: _metadata.serverId, serverName: _metadata.serverName))
          .toList();

      setStateIfMounted(() {
        _extras = extrasWithServerId;
      });
    } catch (e) {
      // Silently fail - extras section won't appear if fetch fails
    }
  }

  /// Load related hubs (collections, similar, "more from" director/actor).
  /// Backend-neutral — both Plex and Jellyfin implement
  /// [MediaServerClient.fetchRelatedHubs].
  Future<void> _loadRelatedHubs() async {
    if (!_metadata.isMovie && !_metadata.isShow) {
      return;
    }

    if (widget.isOffline) {
      return;
    }

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (client == null) return;

    try {
      final relatedHubs = await client.fetchRelatedHubs(_metadata.id);

      setStateIfMounted(() {
        _relatedHubs = relatedHubs;
        _relatedHubKeys = List.generate(relatedHubs.length, (_) => GlobalKey<HubSectionState>());
      });
    } catch (e) {
      // Silently fail - related sections won't appear if fetch fails
    }
  }

  /// Focus the first visible section above cast: season tabs → overview → play button.
  /// Shared by cast UP, extras UP, and related hub UP handlers.
  void _focusSectionAboveCast() {
    final metadata = _fullMetadata ?? _metadata;
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
  }

  /// Focus the first visible section above extras: cast → season tabs → overview → play button.
  void _focusSectionAboveExtras() {
    final metadata = _fullMetadata ?? _metadata;
    if (metadata.roles != null && metadata.roles!.isNotEmpty) {
      _castFocusNode.requestFocus();
      _scrollSectionIntoView(_castSectionKey);
    } else {
      _focusSectionAboveCast();
    }
  }

  bool get _hasInfoRows {
    final metadata = _fullMetadata ?? _metadata;
    return metadata.studio != null || metadata.contentRating != null;
  }

  /// Focus the trailing info rows (studio / contentRating) and scroll them into view.
  void _focusInfoRows() {
    _infoRowsFocusNode.requestFocus();
    _scrollSectionIntoView(_infoRowsSectionKey);
  }

  /// Focus the first visible focusable section above info rows: related hubs → extras → cast → …
  void _focusSectionAboveInfoRows() {
    if (_relatedHubs.isNotEmpty) {
      _relatedHubKeys.last.currentState?.requestFocusFromMemory();
    } else if (_extras != null && _extras!.isNotEmpty) {
      _extrasFocusNode.requestFocus();
      _scrollSectionIntoView(_extrasSectionKey);
    } else {
      _focusSectionAboveExtras();
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

    final metadata = _fullMetadata ?? _metadata;

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

    if (_episodes.isNotEmpty) {
      _firstEpisodeFocusNode.requestFocus();
      _scrollSectionIntoView(_seasonsSectionKey);
      return KeyEventResult.handled;
    }

    if (metadata.roles != null && metadata.roles!.isNotEmpty) {
      _castFocusNode.requestFocus();
      _scrollSectionIntoView(_castSectionKey);
      return KeyEventResult.handled;
    }

    if (_extras != null && _extras!.isNotEmpty) {
      _extrasFocusNode.requestFocus();
      _scrollSectionIntoView(_extrasSectionKey);
      return KeyEventResult.handled;
    }

    if (_relatedHubs.isNotEmpty) {
      _relatedHubKeys.first.currentState?.requestFocusFromMemory();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled; // consume to prevent unwanted traversal
  }

  /// Get the responsive card width used by seasons/extras/cast rows.
  /// Uses the shared grid size calculator for consistency with library grids.
  double _getResponsiveCardWidth() {
    final density = context.read<SettingsProvider>().libraryDensity;
    final availableWidth = MediaQuery.sizeOf(context).width;
    return GridSizeCalculator.getCellWidth(availableWidth, context, density);
  }

  /// Handle key events for the overview section
  KeyEventResult _handleOverviewKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    final metadata = _fullMetadata ?? _metadata;

    // UP: always play button (overview is directly below play)
    if (key.isUpKey) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      _playButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    if (key.isDownKey) {
      if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
        _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
        _scrollSectionIntoView(_seasonsSectionKey);
      } else if (_episodes.isNotEmpty) {
        _firstEpisodeFocusNode.requestFocus();
        _scrollSectionIntoView(_seasonsSectionKey);
      } else if (metadata.roles != null && metadata.roles!.isNotEmpty) {
        _castFocusNode.requestFocus();
        _scrollSectionIntoView(_castSectionKey);
      } else if (_extras != null && _extras!.isNotEmpty) {
        _extrasFocusNode.requestFocus();
        _scrollSectionIntoView(_extrasSectionKey);
      } else if (_relatedHubs.isNotEmpty) {
        _relatedHubKeys.first.currentState?.requestFocusFromMemory();
      } else if (_hasInfoRows) {
        _focusInfoRows();
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
    final showPosters = context.select<SettingsProvider, bool>((p) => p.showSeasonPostersOnTabs);
    return HorizontalScrollWithArrows(
      controller: _seasonTabsScrollController,
      builder: (scrollController) => SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_seasons.length, (index) {
            final season = _seasons[index];
            final contextMenuKey = _seasonContextMenuKeys.putIfAbsent(index, () => GlobalKey<MediaContextMenuState>());
            Offset? tapPosition;
            final posterPath = season.thumbPath;
            Widget? topImage;
            if (showPosters && posterPath != null && posterPath.isNotEmpty) {
              const posterWidth = 72.0;
              const posterHeight = 108.0;
              final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
              final client = _getMediaClientForMetadata(context);
              final imageUrl = MediaImageHelper.getOptimizedImageUrl(
                client: client,
                thumbPath: posterPath,
                maxWidth: posterWidth,
                maxHeight: posterHeight,
                devicePixelRatio: dpr,
                imageType: ImageType.poster,
              );
              final (memWidth, _) = MediaImageHelper.getMemCacheDimensions(
                displayWidth: (posterWidth * dpr).round(),
                displayHeight: (posterHeight * dpr).round(),
                imageType: ImageType.poster,
              );
              topImage = SizedBox(
                width: posterWidth,
                height: posterHeight,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheManager: PlexImageCacheManager.instance,
                  fit: BoxFit.cover,
                  memCacheWidth: memWidth,
                  placeholder: (context, url) => const PlaceholderContainer(),
                  errorWidget: (context, url, error) => const PlaceholderContainer(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MediaContextMenu(
                key: contextMenuKey,
                item: season,
                onRefresh: (_) {
                  _watchStateChanged = true;
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
                    label: season.title!,
                    isSelected: index == _selectedSeasonIndex,
                    topImage: topImage,
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
        scrollListToIndex(
          _extrasScrollController,
          _focusedExtraIndex,
          itemExtent: _getResponsiveCardWidth() + 4,
          leadingPadding: 0,
        );
      }
      return KeyEventResult.handled;
    }

    // RIGHT: next extra
    if (key.isRightKey) {
      if (_focusedExtraIndex < _extras!.length - 1) {
        setState(() => _focusedExtraIndex++);
        scrollListToIndex(
          _extrasScrollController,
          _focusedExtraIndex,
          itemExtent: _getResponsiveCardWidth() + 4,
          leadingPadding: 0,
        );
      }
      return KeyEventResult.handled;
    }

    if (key.isUpKey) {
      _focusSectionAboveExtras();
      return KeyEventResult.handled;
    }

    // DOWN: related hubs → info rows → consume
    if (key.isDownKey) {
      if (_relatedHubs.isNotEmpty) {
        _relatedHubKeys.first.currentState?.requestFocusFromMemory();
      } else if (_hasInfoRows) {
        _focusInfoRows();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the cast row (locked focus pattern)
  KeyEventResult _handleCastKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    final metadata = _fullMetadata ?? _metadata;
    final roleCount = metadata.roles?.length ?? 0;

    // LEFT: previous cast member
    if (key.isLeftKey) {
      if (_focusedCastIndex > 0) {
        setState(() => _focusedCastIndex--);
        scrollListToIndex(
          _castScrollController,
          _focusedCastIndex,
          itemExtent: _getResponsiveCardWidth() + 6 + 4,
          leadingPadding: 0,
        );
      }
      return KeyEventResult.handled;
    }

    // RIGHT: next cast member
    if (key.isRightKey) {
      if (_focusedCastIndex < roleCount - 1) {
        setState(() => _focusedCastIndex++);
        scrollListToIndex(
          _castScrollController,
          _focusedCastIndex,
          itemExtent: _getResponsiveCardWidth() + 6 + 4,
          leadingPadding: 0,
        );
      }
      return KeyEventResult.handled;
    }

    if (key.isUpKey) {
      // If episodes are visible, focus the last episode (cast is right below episodes)
      if (_episodes.isNotEmpty) {
        final target = _episodes.length == 1 ? _firstEpisodeFocusNode : _lastEpisodeFocusNode;
        target.requestFocus();
      } else {
        _focusSectionAboveCast();
      }
      return KeyEventResult.handled;
    }

    // DOWN: extras → related hubs → info rows → consume
    if (key.isDownKey) {
      if (_extras != null && _extras!.isNotEmpty) {
        _extrasFocusNode.requestFocus();
        _scrollSectionIntoView(_extrasSectionKey);
      } else if (_relatedHubs.isNotEmpty) {
        _relatedHubKeys.first.currentState?.requestFocusFromMemory();
      } else if (_hasInfoRows) {
        _focusInfoRows();
      }
      return KeyEventResult.handled;
    }

    // SELECT: navigate to actor media
    if (key.isSelectKey) {
      final metadata = _fullMetadata ?? _metadata;
      if (_focusedCastIndex < (metadata.roles?.length ?? 0)) {
        _navigateToActorMedia(metadata.roles![_focusedCastIndex]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle vertical navigation between related hub sections
  bool _handleRelatedHubNavigation(int hubIndex, bool isUp) {
    if (_relatedHubKeys.isEmpty) return false;

    if (isUp && hubIndex == 0) {
      if (_extras != null && _extras!.isNotEmpty) {
        _extrasFocusNode.requestFocus();
        _scrollSectionIntoView(_extrasSectionKey);
      } else {
        _focusSectionAboveExtras();
      }
      return true;
    }

    final targetIndex = isUp ? hubIndex - 1 : hubIndex + 1;
    if (targetIndex < 0 || targetIndex >= _relatedHubKeys.length) {
      if (!isUp && _hasInfoRows) _focusInfoRows();
      return true; // at boundary, consume
    }

    _relatedHubKeys[targetIndex].currentState?.requestFocusFromMemory();
    return true;
  }

  /// Handle key events for the trailing info rows (studio / contentRating).
  /// UP returns to the previous focusable section; all other directions consume.
  KeyEventResult _handleInfoRowsKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isUpKey) {
      _focusSectionAboveInfoRows();
      return KeyEventResult.handled;
    }

    // DOWN / LEFT / RIGHT / SELECT: consume — info rows are the terminal row.
    return KeyEventResult.handled;
  }

  IconData _getRelatedHubIcon(MediaHub hub) {
    final lower = hub.title.toLowerCase();
    if (lower.contains('collection')) return Symbols.video_library_rounded;
    if (lower.contains('similar')) return Symbols.auto_awesome_rounded;
    if (lower.contains('more from') || lower.contains('more with')) return Symbols.person_rounded;
    if (lower.contains('genre') || lower.contains('director')) return Symbols.movie_rounded;
    return Symbols.recommend_rounded;
  }

  /// Build episode list directly when the library hides seasons for single-season shows
  Widget _buildEpisodesList() {
    final client = _getMediaClientForMetadata(context);
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
          onNavigateUp: index == 0
              ? () {
                  if (!_showEpisodesDirectly) {
                    _focusSelectedSeasonTab();
                  } else if ((_fullMetadata ?? _metadata).summary?.isNotEmpty == true) {
                    _overviewFocusNode.requestFocus();
                    _scrollSectionIntoView(_overviewSectionKey);
                  } else {
                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                    _playButtonFocusNode.requestFocus();
                  }
                }
              : null,
          localPosterPath: localPosterPath,
          onTap: () async {
            await navigateToVideoPlayerWithRefresh(
              context,
              metadata: episode,
              isOffline: widget.isOffline,
              onRefresh: () async {
                final refreshed = await client?.fetchItem(episode.id);
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
                  final refreshed = await client?.fetchItem(ratingKey);
                  if (refreshed != null) {
                    setStateIfMounted(() {
                      final i = _episodes.indexWhere((e) => e.id == ratingKey);
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
  void _syncEpisodeToCache(int episodeIndex, MediaItem updated) {
    if (_showEpisodesDirectly || _seasons.isEmpty) return;
    if (_selectedSeasonIndex >= _seasons.length) return;
    final season = _seasons[_selectedSeasonIndex];
    final cached = _episodeCache[season.id];
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
      _episodeCache.remove(season.id);
      await _fetchSeasonEpisodes(_selectedSeasonIndex);
    }
  }

  Future<void> _fetchAllEpisodes() async {
    if (_seasons.isEmpty) return;
    final serverId = _metadata.serverId;
    if (serverId == null) return;
    final client = context.tryGetMediaClientForServer(serverId);
    if (client == null) return;
    setStateIfMounted(() => _isLoadingEpisodes = true);
    try {
      // One-shot recursive expansion — Plex `/grandchildren`, Jellyfin
      // Recursive=true. Replaces the previous per-season fan-out so a
      // many-season show flatten doesn't fan out N parallel HTTP calls.
      // Enrich each episode with serverId/serverName/grandparent fields —
      // Jellyfin's recursive query doesn't always populate them, and the
      // copy is a no-op for Plex where the mapper already does.
      final episodes = await client.fetchPlayableDescendants(_metadata.id);
      final fallbackGrandparentId = _metadata.isSeason ? (_metadata.grandparentId ?? _metadata.parentId) : _metadata.id;
      final fallbackGrandparentTitle = _metadata.isSeason
          ? (_metadata.grandparentTitle ?? _metadata.parentTitle)
          : _metadata.title;
      final enriched = episodes
          .map(
            (e) => e.copyWith(
              serverId: serverId,
              serverName: _metadata.serverName,
              grandparentId: e.grandparentId ?? fallbackGrandparentId,
              grandparentTitle: e.grandparentTitle ?? fallbackGrandparentTitle,
            ),
          )
          .toList();
      setStateIfMounted(() {
        _episodes = enriched;
        _isLoadingEpisodes = false;
      });
    } catch (e, st) {
      appLogger.w('Failed to load episodes for all seasons', error: e, stackTrace: st);
      setStateIfMounted(() => _isLoadingEpisodes = false);
    }
  }

  /// Load the next unwatched episode for offline mode (offline OnDeck)
  Future<void> _loadOfflineOnDeckEpisode() async {
    final offlineWatchProvider = context.read<OfflineWatchProvider>();
    final nextEpisode = await offlineWatchProvider.getNextUnwatchedEpisode(_metadata.id);

    if (nextEpisode != null) {
      setStateIfMounted(() {
        _onDeckEpisode = nextEpisode;
      });
      appLogger.d('Offline OnDeck: S${nextEpisode.parentIndex}E${nextEpisode.index} - ${nextEpisode.title}');
    }
  }

  /// Offline: patch the in-memory metadata so the UI reflects a queued
  /// watch/unwatch action immediately. The sync service holds the truth
  /// for offline state and will reconcile with the server on reconnect,
  /// so we don't need to round-trip through the per-backend cache here.
  Future<void> _updateWatchStateOffline() async {
    final serverId = _metadata.serverId;
    if (serverId == null) return;
    final localStatus = await context.read<OfflineWatchSyncService>().getLocalWatchStatus('$serverId:${_metadata.id}');
    if (localStatus == null) return;
    setStateIfMounted(() {
      final base = _fullMetadata ?? _metadata;
      _fullMetadata = base.copyWith(
        viewCount: localStatus ? 1 : 0,
        // Reset the resume position when transitioning to unwatched, mirroring
        // the previous Plex cache-mutation behavior.
        viewOffsetMs: localStatus ? base.viewOffsetMs : 0,
      );
    });
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
      List<MediaItem> episodes;
      if (!mounted) return;
      if (widget.isOffline) {
        // In offline mode, get episodes from downloads
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);
        // Filter to episodes of this season
        episodes = allEpisodes.where((ep) => ep.parentIndex == firstSeason.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
      } else {
        final client = getServerBoundMediaClient(context);
        if (client == null) return;
        episodes = await client.fetchChildren(firstSeason.id);
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
      final episodeWithServerId = firstEpisode.copyWith(serverId: _metadata.serverId, serverName: _metadata.serverName);
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

  /// Handle shuffle play. Routes through [MediaListPlaybackLauncher.forItem]
  /// so Plex uses its server-side `/playQueues` and Jellyfin builds a local
  /// shuffled queue from `fetchClientSideEpisodeQueue`.
  Future<void> _handleShufflePlayWithQueue(BuildContext context, MediaItem metadata) async {
    if (widget.isOffline) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Shuffle not available offline');
      }
      return;
    }

    final launcher = MediaListPlaybackLauncher.forItem(context, metadata);
    final result = await launcher.launchShuffledShow(metadata: metadata);
    if (result is PlayQueueSuccess && mounted) {
      unawaited(_loadFullMetadata());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use full metadata if loaded, otherwise use passed metadata
    final metadata = _fullMetadata ?? _metadata;
    final isShow = metadata.isShow;
    final isMobile = PlatformDetector.isMobile(context);
    final isTv = PlatformDetector.isTV();
    final theme = Theme.of(context);

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
    final size = MediaQuery.sizeOf(context);
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
                          child: (metadata.artPath != null || metadata.backgroundSquarePath != null)
                              ? Builder(
                                  builder: (context) {
                                    final containerAspect = size.width / headerHeight;
                                    final heroArtPath = metadata.heroArt(containerAspectRatio: containerAspect);

                                    // Check for offline local file first
                                    if (widget.isOffline && _metadata.serverId != null) {
                                      final localPath = context.read<DownloadProvider>().getArtworkLocalPath(
                                        _metadata.serverId!,
                                        heroArtPath,
                                      );
                                      if (localPath != null && File(localPath).existsSync()) {
                                        return OptimizedMediaImage(
                                          client: null,
                                          imagePath: null,
                                          localFilePath: localPath,
                                          fit: BoxFit.cover,
                                          imageType: ImageType.art,
                                          errorWidget: (context, url, error) => const PlaceholderContainer(),
                                        );
                                      }
                                      // Offline but no local file - show placeholder
                                      return const PlaceholderContainer();
                                    }

                                    // Online - use network image
                                    final client = _getMediaClientForMetadata(context);
                                    final mqSize = MediaQuery.sizeOf(context);
                                    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
                                    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
                                      client: client,
                                      thumbPath: heroArtPath,
                                      maxWidth: mqSize.width,
                                      maxHeight: mqSize.height * 0.6,
                                      devicePixelRatio: dpr,
                                      imageType: ImageType.art,
                                    );

                                    final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
                                      displayWidth: (mqSize.width * dpr).round(),
                                      displayHeight: (mqSize.height * 0.6 * dpr).round(),
                                      imageType: ImageType.art,
                                    );
                                    return blurArtwork(
                                      CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        cacheManager: PlexImageCacheManager.instance,
                                        fit: BoxFit.cover,
                                        memCacheHeight: memHeight,
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Clear logo or title
                                  if (metadata.clearLogoPath != null)
                                    SizedBox(
                                      height: 120,
                                      width: 400,
                                      child: Builder(
                                        builder: (context) {
                                          // Check for offline local file first
                                          if (widget.isOffline && _metadata.serverId != null) {
                                            final localPath = context.read<DownloadProvider>().getArtworkLocalPath(
                                              _metadata.serverId!,
                                              metadata.clearLogoPath,
                                            );
                                            if (localPath != null && File(localPath).existsSync()) {
                                              return OptimizedMediaImage(
                                                client: null,
                                                imagePath: null,
                                                localFilePath: localPath,
                                                fit: BoxFit.contain,
                                                alignment: Alignment.centerLeft,
                                                imageType: ImageType.logo,
                                                errorWidget: (context, url, error) =>
                                                    _buildTitleText(context, metadata.displayTitle),
                                              );
                                            }
                                            // Offline but no local file - show title text
                                            return _buildTitleText(context, metadata.displayTitle);
                                          }

                                          // Online - use network image
                                          final client = _getMediaClientForMetadata(context);
                                          final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
                                          final logoUrl = MediaImageHelper.getOptimizedImageUrl(
                                            client: client,
                                            thumbPath: metadata.clearLogoPath,
                                            maxWidth: 400,
                                            maxHeight: 120,
                                            devicePixelRatio: dpr,
                                            imageType: ImageType.logo,
                                          );

                                          return blurArtwork(
                                            CachedNetworkImage(
                                              imageUrl: logoUrl,
                                              cacheManager: PlexImageCacheManager.instance,
                                              filterQuality: FilterQuality.medium,
                                              fit: BoxFit.contain,
                                              alignment: Alignment.centerLeft,
                                              memCacheWidth: (400 * dpr).clamp(200, 800).round(),
                                              placeholder: (context, url) => Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  metadata.displayTitle,
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
                                                return _buildTitleText(context, metadata.displayTitle);
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
                                      metadata.displayTitle,
                                      style: theme.textTheme.displaySmall?.copyWith(
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
                                      if (metadata case PlexMediaItem(:final editionTitle?))
                                        _buildMetadataChip(editionTitle),
                                      if (metadata.contentRating != null)
                                        _buildMetadataChip(formatContentRating(metadata.contentRating!)),
                                      if (metadata.durationMs != null)
                                        _buildMetadataChip(formatDurationTextual(metadata.durationMs!)),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary
                          if (metadata.summary != null && metadata.summary!.isNotEmpty) ...[
                            Text(
                              key: _overviewSectionKey,
                              t.discover.overview,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Focus(
                              focusNode: _overviewFocusNode,
                              onKeyEvent: _handleOverviewKeyEvent,
                              onFocusChange: (_) => setState(() {}),
                              child: Builder(
                                builder: (context) {
                                  final innerTheme = Theme.of(context);
                                  final showFocus =
                                      _overviewFocusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      border: Border.all(
                                        color: showFocus
                                            ? innerTheme.colorScheme.primary.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: () {
                                      final summaryStyle = innerTheme.textTheme.bodyLarge?.copyWith(height: 1.6);
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
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                key: _seasonsSectionKey,
                                t.libraries.groupings.episodes,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
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
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],

                          // Cast
                          if (metadata.roles != null && metadata.roles!.isNotEmpty) ...[
                            Text(
                              key: _castSectionKey,
                              t.discover.cast,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildExtrasSection(),
                            const SizedBox(height: 24),
                          ],

                          // Related Hubs (Collections, Similar, More From...)
                          for (int i = 0; i < _relatedHubs.length; i++) ...[
                            HubSection(
                              key: _relatedHubKeys[i],
                              hub: _relatedHubs[i],
                              icon: _getRelatedHubIcon(_relatedHubs[i]),
                              inset: true,
                              onVerticalNavigation: (isUp) => _handleRelatedHubNavigation(i, isUp),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Additional info — wrapped in Focus so DPAD DOWN from the
                          // last focusable section lands here and scrolls it into view.
                          if (_hasInfoRows)
                            Focus(
                              focusNode: _infoRowsFocusNode,
                              onKeyEvent: _handleInfoRowsKeyEvent,
                              child: Column(
                                key: _infoRowsSectionKey,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom)),
                ],
              ),
              // Sticky top bar with fading background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollOffset,
                  builder: (context, offset, child) => IgnorePointer(
                    ignoring: offset < 50,
                    child: AnimatedOpacity(
                      opacity: (offset / 100).clamp(0.0, 1.0),
                      duration: const Duration(milliseconds: 150),
                      child: child!,
                    ),
                  ),
                  child: Container(
                    height: MediaQuery.paddingOf(context).top + 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.3, 1.0],
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
  MediaItem? _getPrimaryTrailer() {
    if (_extras == null || _extras!.isEmpty) return null;

    // If there's a trailerKey (Plex `primaryExtraKey`), try to find that specific trailer
    final metadata = _fullMetadata ?? _metadata;
    if (metadata case PlexMediaItem(:final trailerKey?)) {
      // Extract rating key from trailerKey (e.g., "/library/metadata/52601" -> "52601")
      final primaryKey = trailerKey.split('/').last;
      try {
        return _extras!.firstWhere((extra) => extra.id == primaryKey);
      } catch (_) {
        // Primary key not found, fall through to find any trailer
      }
    }

    // Otherwise, find the first item with subtype 'trailer'. Extras are
    // always Plex-sourced so the cast is safe; non-Plex backends route
    // around this method entirely.
    try {
      return _extras!.firstWhere((extra) => extra is PlexMediaItem && extra.subtype == 'trailer');
    } catch (_) {
      // No trailer found, return null (button won't appear)
      return null;
    }
  }

  /// Build the cast section with locked focus pattern for D-pad navigation
  /// Uses same layout pattern as seasons/extras (ListView.builder + Padding(horizontal: 2))
  Widget _buildCastSection(MediaItem metadata) {
    final cardWidth = _getResponsiveCardWidth();
    const innerPadding = 3.0;
    final imageSize = cardWidth;
    // image + inner padding + text area + outer list padding + focus scale headroom
    final containerHeight = imageSize + innerPadding * 2 + 66 + 16;

    final hasFocus = _castFocusNode.hasFocus;
    final theme = Theme.of(context);
    final actorNameStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final actorRoleStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

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
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: metadata.roles!.length,
            itemBuilder: (context, index) {
              final actor = metadata.roles![index];
              final isFocused = hasFocus && index == _focusedCastIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FocusBuilders.buildLockedFocusWrapper(
                  context: context,
                  isFocused: isFocused,
                  borderRadius: tokens(context).radiusSm,
                  onTap: () => _navigateToActorMedia(actor),
                  child: Padding(
                    padding: const EdgeInsets.all(innerPadding),
                    child: SizedBox(
                      width: cardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                            child: OptimizedMediaImage(
                              client: getServerBoundMediaClient(context),
                              imagePath: actor.thumbPath,
                              width: imageSize,
                              height: imageSize,
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
                                Text(actor.tag, style: actorNameStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (actor.role != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    actor.role!,
                                    style: actorRoleStyle,
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
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: _extras!.length,
            itemBuilder: (context, index) {
              final extra = _extras![index];
              final isFocused = hasFocus && index == _focusedExtraIndex;
              final cardKey = _extraCardKeys.putIfAbsent(index, () => GlobalKey<MediaCardState>());

              return Padding(
                padding: const EdgeInsets.only(right: 4),
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
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
      ],
    );
  }

  String _getPlayButtonLabel(MediaItem metadata) {
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

  IconData _getPlayButtonIcon(MediaItem metadata) {
    // For TV shows
    if (metadata.isShow) {
      if (_onDeckEpisode != null) {
        final episode = _onDeckEpisode!;
        // Check if episode has been partially watched
        if (episode.viewOffsetMs != null && episode.viewOffsetMs! > 0) {
          return Symbols.resume_rounded; // Resume icon
        }
      }
    } else {
      // For movies or episodes
      if (metadata.viewOffsetMs != null && metadata.viewOffsetMs! > 0) {
        return Symbols.resume_rounded; // Resume icon
      }
    }

    return Symbols.play_arrow_rounded; // Default play icon
  }
}
