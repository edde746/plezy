import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/platform_helper.dart';
import '../utils/io_helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../main.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/key_event_utils.dart';
import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../models/download_models.dart';
import '../providers/download_provider.dart';
import '../services/download_storage_service.dart';
import '../widgets/plex_optimized_image.dart';
import '../models/plex_metadata.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/formatters.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/placeholder_container.dart';
import '../mixins/item_updatable.dart';
import '../mixins/watch_state_aware.dart';
import '../mixins/deletion_aware.dart';
import '../utils/watch_state_notifier.dart';
import '../utils/deletion_notifier.dart';
import '../theme/mono_tokens.dart';
import '../i18n/strings.g.dart';

class SeasonDetailScreen extends StatefulWidget {
  final PlexMetadata season;
  final bool isOffline;

  const SeasonDetailScreen({super.key, required this.season, this.isOffline = false});

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen>
    with ItemUpdatable, WatchStateAware, DeletionAware, RouteAware {
  PlexClient? _client;

  @override
  PlexClient get client => _client!;

  List<PlexMetadata> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _watchStateChanged = false;
  // Capture keyboard mode once at init to avoid rebuild dependency
  bool _initialKeyboardMode = false;
  bool _suppressNextBackKeyUp = false;
  bool _routeSubscribed = false;

  String _toGlobalKey(String ratingKey, {String? serverId}) => '${serverId ?? widget.season.serverId ?? ''}:$ratingKey';

  // WatchStateAware: watch all episode ratingKeys
  @override
  Set<String>? get watchedRatingKeys => _episodes.map((e) => e.ratingKey).toSet();

  @override
  String? get watchStateServerId => widget.season.serverId;

  @override
  Set<String>? get watchedGlobalKeys {
    final serverId = widget.season.serverId;
    if (serverId == null) return null;

    return _episodes.map((e) => _toGlobalKey(e.ratingKey, serverId: e.serverId ?? serverId)).toSet();
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    // Update the affected episode
    if (!widget.isOffline && _client != null) {
      updateItem(event.ratingKey);
    }
  }

  @override
  Set<String>? get deletionRatingKeys {
    final keys = _episodes.map((e) => e.ratingKey).toSet();
    keys.add(widget.season.ratingKey);
    return keys;
  }

  @override
  String? get deletionServerId => widget.season.serverId;

  @override
  Set<String>? get deletionGlobalKeys {
    final serverId = widget.season.serverId;
    if (serverId == null) return null;

    final keys = _episodes.map((e) => _toGlobalKey(e.ratingKey, serverId: e.serverId ?? serverId)).toSet();
    keys.add(_toGlobalKey(widget.season.ratingKey, serverId: serverId));
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // If we have an episode that matches the rating key exactly, then remove it from our list
    final index = _episodes.indexWhere((e) => e.ratingKey == event.ratingKey);
    if (index != -1) {
      setState(() {
        _episodes.removeAt(index);
      });
      // If that was the last episode, navigate back to the show view
      if (_episodes.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Get the correct PlexClient for this season's server
  PlexClient? _getClientForSeason(BuildContext context) {
    if (widget.isOffline || widget.season.serverId == null) {
      return null;
    }
    return context.getClientForServer(widget.season.serverId!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize the client once in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Capture keyboard mode once to avoid rebuild dependency when mode changes
      _initialKeyboardMode = InputModeTracker.isKeyboardMode(context);
      _client = _getClientForSeason(context);
      _loadEpisodes();
    });
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoadingEpisodes = true;
    });

    if (widget.isOffline) {
      // Load episodes from downloads
      _loadEpisodesFromDownloads();
      return;
    }

    try {
      // Episodes are automatically tagged with server info by PlexClient
      final episodes = await _client!.getChildren(widget.season.ratingKey);

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

  /// Load episodes from downloaded content
  void _loadEpisodesFromDownloads() {
    final downloadProvider = context.read<DownloadProvider>();

    // Get all downloaded episodes for the show (grandparentRatingKey)
    final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(widget.season.parentRatingKey ?? '');

    // Filter to only this season's episodes
    final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == widget.season.index).toList()
      ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    setState(() {
      _episodes = seasonEpisodes;
      _isLoadingEpisodes = false;
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeSubscribed) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      routeObserver.unsubscribe(this);
      _routeSubscribed = false;
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returning from a child route (e.g., video player).
    // Suppress the first BACK KeyUp which can otherwise pop this route.
    _suppressNextBackKeyUp = true;
  }

  KeyEventResult _handleBackKeyEvent(KeyEvent event) {
    if (_suppressNextBackKeyUp && event is KeyUpEvent && event.logicalKey.isBackKey) {
      _suppressNextBackKeyUp = false;
      return KeyEventResult.handled;
    }
    return handleBackKeyNavigation(context, event, result: _watchStateChanged);
  }

  @override
  Widget build(BuildContext context) {
    final content = Focus(
      onKeyEvent: (_, event) => _handleBackKeyEvent(event),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            CustomAppBar(
              title: Text(widget.season.title),
              pinned: true,
              onBackPressed: () => Navigator.pop(context, _watchStateChanged),
            ),
            if (_isLoadingEpisodes)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_episodes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(Symbols.movie_rounded, fill: 1, size: 64, color: tokens(context).textMuted),
                      const SizedBox(height: 16),
                      Text(
                        t.messages.noEpisodesFoundGeneral,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tokens(context).textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final episode = _episodes[index];
                  // Get local poster path for offline mode
                  String? localPosterPath;
                  if (widget.isOffline && episode.serverId != null) {
                    final downloadProvider = context.read<DownloadProvider>();
                    final globalKey = '${episode.serverId}:${episode.ratingKey}';
                    // Get the artwork reference and convert to local file path
                    final artworkRef = downloadProvider.getArtworkPaths(globalKey);
                    localPosterPath = artworkRef?.getLocalPath(DownloadStorageService.instance, episode.serverId!);
                  }
                  return _EpisodeCard(
                    episode: episode,
                    client: _client,
                    isOffline: widget.isOffline,
                    localPosterPath: localPosterPath,
                    autofocus: index == 0 && _initialKeyboardMode,
                    onTap: () async {
                      await navigateToVideoPlayerWithRefresh(
                        context,
                        metadata: episode,
                        isOffline: widget.isOffline,
                        onRefresh: _loadEpisodes,
                      );
                    },
                    onRefresh: widget.isOffline ? null : updateItem,
                    onListRefresh: widget.isOffline ? null : _loadEpisodes,
                  );
                }, childCount: _episodes.length),
              ),
            SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
          ],
        ),
      ),
    );

    final blockSystemBack = AppPlatform.isAndroid && InputModeTracker.isKeyboardMode(context);
    if (!blockSystemBack) {
      return content;
    }

    return PopScope(
      canPop: false, // Prevent system back from double-popping on Android keyboard/TV
      onPopInvokedWithResult: (didPop, result) {},
      child: content,
    );
  }
}

/// Episode card widget with D-pad long-press support
class _EpisodeCard extends StatefulWidget {
  final PlexMetadata episode;
  final PlexClient? client;
  final VoidCallback onTap;
  final Future<void> Function(String)? onRefresh;
  final Future<void> Function()? onListRefresh;
  final bool autofocus;
  final bool isOffline;
  final String? localPosterPath;

  const _EpisodeCard({
    required this.episode,
    this.client,
    required this.onTap,
    this.onRefresh,
    this.onListRefresh,
    this.autofocus = false,
    this.isOffline = false,
    this.localPosterPath,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context);
  }

  Widget _buildEpisodeMetaRow(BuildContext context) {
    return Row(
      children: [
        if (widget.episode.duration != null)
          Text(
            formatDurationTimestamp(Duration(milliseconds: widget.episode.duration!)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 12),
          ),
        if (widget.episode.originallyAvailableAt != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 12),
            ),
          ),
          Text(
            formatFullDate(widget.episode.originallyAvailableAt!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide progress when offline (not tracked)
    final hasProgress =
        !widget.isOffline &&
        widget.episode.viewOffset != null &&
        widget.episode.duration != null &&
        widget.episode.viewOffset! > 0;
    final progress = hasProgress ? widget.episode.viewOffset! / widget.episode.duration! : 0.0;

    final hasActiveProgress = hasProgress && widget.episode.viewOffset! < widget.episode.duration!;

    return FocusableWrapper(
      autofocus: widget.autofocus,
      enableLongPress: true,
      onSelect: widget.onTap,
      onLongPress: _showContextMenu,
      borderRadius: 0, // Episode cards have no border radius
      useBackgroundFocus: true, // Use background color instead of outline
      disableScale: true, // No scale animation for list items
      child: MediaContextMenu(
        key: _contextMenuKey,
        item: widget.episode,
        onRefresh: widget.onRefresh,
        onListRefresh: widget.onListRefresh,
        onTap: widget.onTap,
        child: InkWell(
          key: Key(widget.episode.ratingKey),
          onTap: widget.onTap,
          hoverColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens(context).outline, width: 0.5)),
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
                          child: widget.isOffline && widget.localPosterPath != null
                              ? Image.file(
                                  File(widget.localPosterPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const PlaceholderContainer(
                                    child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32),
                                  ),
                                )
                              : widget.episode.thumb != null
                              ? PlexOptimizedImage.thumb(
                                  client: widget.client,
                                  imagePath: widget.episode.thumb,
                                  filterQuality: FilterQuality.medium,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const PlaceholderContainer(),
                                  errorWidget: (context, url, error) => const PlaceholderContainer(
                                    child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32),
                                  ),
                                )
                              : const PlaceholderContainer(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32)),
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
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const AppIcon(Symbols.play_arrow_rounded, fill: 1, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),

                      // Progress bar at bottom
                      if (hasActiveProgress)
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

                      if (widget.episode.isWatched && !hasActiveProgress)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tokens(context).text,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                            ),
                            child: AppIcon(Symbols.check_rounded, fill: 1, color: tokens(context).bg, size: 12),
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
                      // Episode number and title with download status
                      Consumer<DownloadProvider>(
                        builder: (context, downloadProvider, _) {
                          // Build download status icon based on state
                          Widget? downloadStatusIcon;

                          // Only show download status in online mode
                          if (!widget.isOffline && widget.episode.serverId != null) {
                            final globalKey = '${widget.episode.serverId}:${widget.episode.ratingKey}';
                            final progress = downloadProvider.getProgress(globalKey);
                            final isQueueing = downloadProvider.isQueueing(globalKey);

                            // Helper to get status-specific muted color
                            Color getMutedColor(Color baseColor) {
                              return Color.lerp(
                                tokens(context).textMuted,
                                baseColor,
                                0.3, // 30% of the status color, 70% muted
                              )!;
                            }

                            if (isQueueing) {
                              // Queueing state - building queue
                              downloadStatusIcon = SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: tokens(context).textMuted),
                              );
                            } else if (progress?.status == DownloadStatus.queued) {
                              // Queued state - waiting to download
                              downloadStatusIcon = AppIcon(
                                Symbols.schedule_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.orange),
                              );
                            } else if (progress?.status == DownloadStatus.downloading) {
                              // Downloading state - active download with radial progress
                              downloadStatusIcon = SizedBox(
                                width: 14,
                                height: 14,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background circle
                                    CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getMutedColor(Colors.blue).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    // Progress circle
                                    CircularProgressIndicator(
                                      value: progress?.progressPercent,
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(getMutedColor(Colors.blue)),
                                    ),
                                  ],
                                ),
                              );
                            } else if (progress?.status == DownloadStatus.paused) {
                              // Paused state - download paused
                              downloadStatusIcon = AppIcon(
                                Symbols.pause_circle_outline_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.amber),
                              );
                            } else if (progress?.status == DownloadStatus.failed) {
                              // Failed state - download failed
                              downloadStatusIcon = AppIcon(
                                Symbols.error_outline_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.red),
                              );
                            } else if (progress?.status == DownloadStatus.cancelled) {
                              // Cancelled state - download cancelled
                              downloadStatusIcon = AppIcon(
                                Symbols.cancel_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.grey),
                              );
                            } else if (progress?.status == DownloadStatus.completed) {
                              // Completed state - download complete
                              downloadStatusIcon = AppIcon(
                                Symbols.file_download_done_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.green),
                              );
                            }
                            // Note: No icon shown if not downloaded (null)
                          }

                          return Row(
                            children: [
                              // Episode number badge
                              if (widget.episode.index != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'E${widget.episode.index}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              // Download status icon (if present)
                              if (downloadStatusIcon != null) ...[const SizedBox(width: 6), downloadStatusIcon],
                              const SizedBox(width: 8),
                              // Episode title
                              Expanded(
                                child: Text(
                                  widget.episode.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Summary
                      if (widget.episode.summary != null && widget.episode.summary!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.episode.summary!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Metadata row (duration, watched status)
                      const SizedBox(height: 8),
                      _buildEpisodeMetaRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
