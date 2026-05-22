import 'dart:async';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../main.dart' show routeObserver;
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
import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../utils/provider_extensions.dart';
import '../utils/plex_season_display.dart';
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
import '../utils/content_utils.dart';
import '../utils/rating_utils.dart';
import '../models/download_models.dart';
import '../services/download_storage_service.dart';
import '../utils/download_version_utils.dart';
import '../utils/download_utils.dart';
import '../services/settings_service.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../widgets/settings_builder.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/layout_constants.dart';
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
import '../widgets/tv_browse_rail.dart';
import '../widgets/tv_spotlight_background.dart';

part 'media_detail/action_buttons.dart';

const double _tvDetailTallPosterScale = TvBrowseRailLayout.compactTallPosterScale;
const double _tvDetailEpisodeThumbnailScale = TvBrowseRailLayout.compactEpisodeThumbnailScale;
const double _tvDetailActionSize = 46;
const double _tvDetailActionRailGap = 4;
const String _tvDetailSeasonHubIdPrefix = 'detail_season_';
const String _tvDetailActorsHubId = 'detail_actors';
const String _tvDetailActorPersonIdRawKey = 'tvDetailActorPersonId';

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
    with WatchStateAware, DeletionAware, MountedSetStateMixin, ServerBoundMediaMixin, RouteAware {
  /// Public input alias — used as the live source of truth until the detail
  /// fetch returns. Holds backend-neutral [MediaItem] data.
  MediaItem get _metadata => _fullMetadata ?? widget.metadata;
  List<MediaItem> _seasons = [];
  bool _isLoadingSeasons = false;
  Completer<void>? _seasonsCompleter;
  List<MediaItem> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _isLoadingAllEpisodes = false;
  int _episodesLoadGeneration = 0;
  int _tvSeasonEpisodeCacheWarmGeneration = 0;
  bool _showEpisodesDirectly = false;
  MediaItem? _fullMetadata;
  MediaItem? _onDeckEpisode;
  final Map<String, int> _localProgressById = {};
  bool _isLoadingMetadata = true;
  List<MediaItem>? _extras;
  List<MediaHub> _relatedHubs = [];
  List<GlobalKey<HubSectionState>> _relatedHubKeys = [];
  bool _hasLoadedExtras = false;
  bool _hasLoadedRelatedHubs = false;
  final _tvDetailRailKey = GlobalKey<TvBrowseRailState>();
  PageRoute<dynamic>? _route;
  late final ScrollController _scrollController;
  final ScrollController _extrasScrollController = ScrollController();
  bool _watchStateChanged = false;
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  bool _suppressBackAfterPop = false;
  bool _tvDetailRevealed = false;
  bool _tvDetailRevealScheduled = false;
  bool _hasLoadedSeasons = false;
  bool _hasLoadedEpisodes = false;
  double? _tvDetailPendingRailHeight;
  double? _tvDetailStableRailHeight;
  MediaItem? _tvDetailFocusedEpisode;
  bool _tvDetailActionRowHasFocus = false;

  // Inline season tabs
  int _selectedSeasonIndex = 0;
  final Map<String, List<MediaItem>> _episodeCache = {};
  final Set<String> _seasonEpisodeLoadsInFlight = {};
  bool _isLoadingSeasonEpisodes = false;
  List<FocusNode> _seasonTabFocusNodes = [];

  MediaItem _withFallbackLibrary(MediaItem item, MediaItem fallback) {
    return item.copyWith(
      libraryId: item.libraryId ?? fallback.libraryId,
      libraryTitle: item.libraryTitle ?? fallback.libraryTitle,
    );
  }

  final Map<int, GlobalKey<MediaContextMenuState>> _seasonContextMenuKeys = {};
  final ScrollController _seasonTabsScrollController = ScrollController();
  final FocusNode _firstEpisodeFocusNode = FocusNode(debugLabel: 'first_episode');
  final FocusNode _lastEpisodeFocusNode = FocusNode(debugLabel: 'last_episode');
  static const int _episodesPageSize = 200;

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
    _watchStateChanged = true;
    final epIndex = _episodes.indexWhere((e) => e.id == event.itemId);

    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      return;
    }

    if (event.changeType == WatchStateChangeType.progressUpdate) {
      if (event.viewOffset != null) {
        _patchLocalProgress(event.itemId, event.viewOffset!, epIndex: epIndex);
      }
      if (event.isNowWatched != true) return;
    }

    _localProgressById.remove(event.itemId);
    _patchWatchedStateFromEvent(
      event,
      epIndex: epIndex,
      clearWatchedProgress: !widget.isOffline || event.changeType == WatchStateChangeType.progressUpdate,
    );

    if (widget.isOffline) {
      if (_metadata.isShow) {
        unawaited(_loadOfflineOnDeckEpisode());
      }
      return;
    }

    // Online: refresh server-derived counters and on-deck state. A watched
    // episode can change the hero play target even when the episode row itself
    // was already visible and patched locally.
    unawaited(_refreshWatchState());
  }

  void _patchWatchedStateFromEvent(WatchStateEvent event, {required int epIndex, required bool clearWatchedProgress}) {
    final isWatched = event.isNowWatched;
    if (isWatched == null) return;

    setStateIfMounted(() {
      final base = _fullMetadata ?? widget.metadata;
      final episodeDelta = epIndex == -1 ? 0 : _watchStateDelta(_episodes[epIndex], isWatched);

      if (base.id == event.itemId) {
        _fullMetadata = _withWatchedPatch(base, isWatched, clearWatchedProgress: clearWatchedProgress);
      }

      final onDeckEpisode = _onDeckEpisode;
      if (onDeckEpisode != null && onDeckEpisode.id == event.itemId) {
        _onDeckEpisode = _withWatchedPatch(onDeckEpisode, isWatched, clearWatchedProgress: clearWatchedProgress);
      }

      _patchWatchedInListWhere(
        _seasons,
        (item) => item.id == event.itemId,
        isWatched,
        clearWatchedProgress: clearWatchedProgress,
      );
      _patchWatchedInListWhere(
        _episodes,
        (item) => item.id == event.itemId,
        isWatched,
        clearWatchedProgress: clearWatchedProgress,
      );
      for (final cached in _episodeCache.values) {
        _patchWatchedInListWhere(
          cached,
          (item) => item.id == event.itemId,
          isWatched,
          clearWatchedProgress: clearWatchedProgress,
        );
      }
      final extras = _extras;
      if (extras != null) {
        _patchWatchedInListWhere(
          extras,
          (item) => item.id == event.itemId,
          isWatched,
          clearWatchedProgress: clearWatchedProgress,
        );
      }
      _relatedHubs = _patchWatchedInHubs(
        _relatedHubs,
        (item) => item.id == event.itemId,
        isWatched,
        clearWatchedProgress: clearWatchedProgress,
      );

      if (base.id == event.itemId || _seasons.any((season) => season.id == event.itemId)) {
        _patchLoadedDescendantsOf(event.itemId, isWatched, clearWatchedProgress: clearWatchedProgress);
      } else if (episodeDelta != 0) {
        _adjustParentWatchCounts(event.parentChain, episodeDelta);
      }
    });
  }

  MediaItem _withWatchedPatch(MediaItem item, bool isWatched, {required bool clearWatchedProgress}) {
    final viewOffsetMs = isWatched && !clearWatchedProgress ? null : 0;
    var updated = item.copyWith(viewCount: isWatched ? 1 : 0);
    if (item.leafCount != null || item.viewedLeafCount != null) {
      updated = updated.copyWith(viewedLeafCount: isWatched ? (item.leafCount ?? item.viewedLeafCount ?? 1) : 0);
    }
    return viewOffsetMs == null ? updated : updated.copyWith(viewOffsetMs: viewOffsetMs);
  }

  int _watchStateDelta(MediaItem item, bool isWatched) {
    if (item.isWatched == isWatched) return 0;
    return isWatched ? 1 : -1;
  }

  void _patchWatchedInListWhere(
    List<MediaItem> items,
    bool Function(MediaItem item) test,
    bool isWatched, {
    required bool clearWatchedProgress,
  }) {
    for (var i = 0; i < items.length; i++) {
      if (test(items[i])) {
        items[i] = _withWatchedPatch(items[i], isWatched, clearWatchedProgress: clearWatchedProgress);
      }
    }
  }

  List<MediaHub> _patchWatchedInHubs(
    List<MediaHub> hubs,
    bool Function(MediaItem item) test,
    bool isWatched, {
    required bool clearWatchedProgress,
  }) {
    var changed = false;
    final updatedHubs = <MediaHub>[];
    for (final hub in hubs) {
      var hubChanged = false;
      final items = List<MediaItem>.of(hub.items);
      _patchWatchedInListWhere(
        items,
        (item) {
          final matches = test(item);
          hubChanged = hubChanged || matches;
          return matches;
        },
        isWatched,
        clearWatchedProgress: clearWatchedProgress,
      );
      changed = changed || hubChanged;
      updatedHubs.add(hubChanged ? hub.copyWith(items: items) : hub);
    }
    return changed ? updatedHubs : hubs;
  }

  void _patchLoadedDescendantsOf(String parentId, bool isWatched, {required bool clearWatchedProgress}) {
    final isDescendant = (MediaItem item) => item.parentChain.contains(parentId);
    _patchWatchedInListWhere(_seasons, isDescendant, isWatched, clearWatchedProgress: clearWatchedProgress);
    _patchWatchedInListWhere(_episodes, isDescendant, isWatched, clearWatchedProgress: clearWatchedProgress);
    for (final entry in _episodeCache.entries) {
      _patchWatchedInListWhere(
        entry.value,
        (item) => entry.key == parentId || isDescendant(item),
        isWatched,
        clearWatchedProgress: clearWatchedProgress,
      );
    }
  }

  void _adjustParentWatchCounts(List<String> parentIds, int delta) {
    if (parentIds.isEmpty) return;
    final parentIdSet = parentIds.toSet();
    final base = _fullMetadata ?? widget.metadata;
    if (parentIdSet.contains(base.id)) {
      _fullMetadata = _withAdjustedViewedLeafCount(base, delta);
    }
    for (var i = 0; i < _seasons.length; i++) {
      if (parentIdSet.contains(_seasons[i].id)) {
        _seasons[i] = _withAdjustedViewedLeafCount(_seasons[i], delta);
      }
    }
  }

  MediaItem _withAdjustedViewedLeafCount(MediaItem item, int delta) {
    final viewedLeafCount = item.viewedLeafCount;
    if (viewedLeafCount == null) return item;
    final max = item.leafCount ?? (1 << 30);
    final next = (viewedLeafCount + delta).clamp(0, max).toInt();
    return item.copyWith(viewedLeafCount: next);
  }

  void _patchLocalProgress(String itemId, int viewOffset, {int? epIndex}) {
    _localProgressById[itemId] = viewOffset;
    setStateIfMounted(() {
      final base = _fullMetadata ?? widget.metadata;
      if (base.id == itemId) {
        _fullMetadata = base.copyWith(viewOffsetMs: viewOffset);
      }

      final onDeckEpisode = _onDeckEpisode;
      if (onDeckEpisode != null && onDeckEpisode.id == itemId) {
        _onDeckEpisode = onDeckEpisode.copyWith(viewOffsetMs: viewOffset);
      }

      final index = epIndex ?? _episodes.indexWhere((e) => e.id == itemId);
      if (index != -1) {
        final updated = _episodes[index].copyWith(viewOffsetMs: viewOffset);
        _episodes[index] = updated;
        _syncEpisodeToCache(index, updated);
      }
    });
  }

  MediaItem _applyLocalProgress(MediaItem item) {
    if (!_localProgressById.containsKey(item.id)) return item;
    return item.copyWith(viewOffsetMs: _localProgressById[item.id]!);
  }

  MediaItem _normalizeRefreshedItem(MediaItem item, MediaItem fallback) {
    return _applyLocalProgress(
      _withFallbackLibrary(
        item.copyWith(
          serverId: item.serverId ?? fallback.serverId ?? _metadata.serverId,
          serverName: item.serverName ?? fallback.serverName ?? _metadata.serverName,
        ),
        fallback,
      ),
    );
  }

  void _patchItemEverywhere(MediaItem item) {
    final base = _fullMetadata ?? widget.metadata;
    if (base.id == item.id) {
      _fullMetadata = _normalizeRefreshedItem(item, base);
    }

    final onDeckEpisode = _onDeckEpisode;
    if (onDeckEpisode != null && onDeckEpisode.id == item.id) {
      _onDeckEpisode = _normalizeRefreshedItem(item, onDeckEpisode);
    }

    _patchItemInList(_seasons, item);
    _patchItemInList(_episodes, item);
    for (final cached in _episodeCache.values) {
      _patchItemInList(cached, item);
    }
    final extras = _extras;
    if (extras != null) {
      _patchItemInList(extras, item);
    }

    _relatedHubs = _patchItemInHubs(_relatedHubs, item);
  }

  void _patchItemInList(List<MediaItem> items, MediaItem item) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].id == item.id) {
        items[i] = _normalizeRefreshedItem(item, items[i]);
      }
    }
  }

  List<MediaHub> _patchItemInHubs(List<MediaHub> hubs, MediaItem item) {
    var changed = false;
    final updatedHubs = <MediaHub>[];
    for (final hub in hubs) {
      var hubChanged = false;
      final items = List<MediaItem>.of(hub.items);
      for (var i = 0; i < items.length; i++) {
        if (items[i].id == item.id) {
          items[i] = _normalizeRefreshedItem(item, items[i]);
          hubChanged = true;
        }
      }
      changed = changed || hubChanged;
      updatedHubs.add(hubChanged ? hub.copyWith(items: items) : hub);
    }
    return changed ? updatedHubs : hubs;
  }

  Future<void> _refreshItemInPlace(String itemId) async {
    final client = _getMediaClientForMetadata(context);
    if (client == null) return;

    try {
      final refreshed = await client.fetchItem(itemId);
      if (refreshed == null || !mounted) return;
      setStateIfMounted(() {
        _patchItemEverywhere(refreshed);
      });
    } catch (e) {
      appLogger.d('Item refresh failed for $itemId', error: e);
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
        final refreshedMetadata = _applyLocalProgress(
          _withFallbackLibrary(
            metadata.copyWith(serverId: serverId, serverName: serverName ?? metadata.serverName),
            _metadata,
          ),
        );
        final refreshedOnDeck = onDeckEpisode == null
            ? null
            : _applyLocalProgress(
                _withFallbackLibrary(
                  onDeckEpisode.copyWith(serverId: serverId, serverName: serverName ?? onDeckEpisode.serverName),
                  refreshedMetadata,
                ),
              );
        setStateIfMounted(() {
          _fullMetadata = refreshedMetadata;
          _onDeckEpisode = refreshedOnDeck;
        });
      }

      // Do not refresh seasons/episodes here. The watch event has already
      // patched loaded rows, and rebuilding those lists causes visible rail
      // churn on TV/detail layouts.
    } catch (e) {
      appLogger.d('Watch-state refresh failed', error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _extrasFocusNode = FocusNode(debugLabel: 'extras_row');
    _extrasFocusNode.addListener(_handleExtrasFocusChange);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || route == _route) return;
    if (_route != null) routeObserver.unsubscribe(this);
    _route = route;
    routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _suppressBackAfterPop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _suppressBackAfterPop = false;
      });
    });
  }

  bool _consumeBackAfterChildPop(KeyEvent event) {
    if (!_suppressBackAfterPop || !event.logicalKey.isBackKey) return false;
    if (event is KeyUpEvent) _suppressBackAfterPop = false;
    return true;
  }

  KeyEventResult _handleMediaDetailBackKey(FocusNode _, KeyEvent event) {
    if (_consumeBackAfterChildPop(event)) return KeyEventResult.handled;
    return handleBackKeyNavigation(context, event, result: _watchStateChanged);
  }

  void _popMediaDetailIfBackNotSuppressed() {
    if (_suppressBackAfterPop) {
      _suppressBackAfterPop = false;
      return;
    }
    Navigator.pop(context, _watchStateChanged);
  }

  bool _isTvDetailReadyToReveal(MediaItem metadata) {
    if (_isLoadingMetadata) return false;
    if (!_hasLoadedTvDetailSupplementalSections(metadata)) return false;

    if (metadata.isShow) {
      if (_isLoadingSeasons || (!_hasLoadedSeasons && _seasons.isEmpty)) return false;
      if (_showEpisodesDirectly) return _hasLoadedEpisodes && !_isLoadingEpisodes;
      if (_seasons.isEmpty) return true;
      if (_selectedSeasonIndex < 0 || _selectedSeasonIndex >= _seasons.length) return false;
      return !_isLoadingSeasonEpisodes && _episodeCache.containsKey(_seasons[_selectedSeasonIndex].id);
    }

    if (metadata.isSeason) {
      return _hasLoadedEpisodes && !_isLoadingEpisodes;
    }

    return true;
  }

  bool _hasLoadedTvDetailSupplementalSections(MediaItem metadata) {
    if (widget.isOffline || (!metadata.isMovie && !metadata.isShow)) return true;
    return _hasLoadedExtras && _hasLoadedRelatedHubs;
  }

  void _scheduleTvDetailReveal(double railHeight, {required bool focusPrimaryAction}) {
    final pendingRailHeight = _tvDetailPendingRailHeight;
    if (pendingRailHeight == null || railHeight > pendingRailHeight) {
      _tvDetailPendingRailHeight = railHeight;
    }
    if (_tvDetailRevealed || _tvDetailRevealScheduled) return;

    _tvDetailRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _tvDetailStableRailHeight = _tvDetailPendingRailHeight ?? railHeight;
          _tvDetailRevealScheduled = false;
          _tvDetailRevealed = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (focusPrimaryAction) {
            _playButtonFocusNode.requestFocus();
          } else {
            _tvDetailRailKey.currentState?.requestFocus();
          }
        });
      });
    });
  }

  Widget _buildTvDetailRevealGate(Widget child, KeyEventResult Function(FocusNode, KeyEvent) handleBack) {
    final revealed = _tvDetailRevealed;
    return Focus(
      canRequestFocus: !revealed,
      onKeyEvent: revealed ? null : handleBack,
      child: ExcludeFocus(
        excluding: !revealed,
        child: IgnorePointer(
          ignoring: !revealed,
          child: AnimatedOpacity(
            opacity: revealed ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _extrasScrollController.dispose();
    _extrasFocusNode.removeListener(_handleExtrasFocusChange);
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

  /// Build title text widget for clear logo fallback.
  Widget _buildDetailTitle(
    BuildContext context,
    String title, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    double shadowBlur = 8,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: fontWeight,
          fontSize: fontSize,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: shadowBlur)],
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
    final size = PlatformDetector.isTV() ? 26.0 : 20.0;
    return SizedBox(
      width: size,
      height: size,
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
  /// Build a metadata chip with optional leading icon or widget
  Widget _buildMetadataChip(String text, {IconData? icon, Widget? leading}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTv = PlatformDetector.isTV();
    final textWidget = Text(
      text,
      style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: isTv ? 16 : 13, fontWeight: FontWeight.w600),
    );

    final hasLeading = leading != null || icon != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTv ? 14 : 12, vertical: isTv ? 8 : 6),
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
                  AppIcon(icon!, fill: 1, color: colorScheme.onSecondaryContainer, size: isTv ? 20 : 16),
                SizedBox(width: isTv ? 6 : 4),
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

    final iconData = isNumeric ? Symbols.star_rounded : Symbols.thumb_up_rounded;
    final activeIconColor = isNumeric ? Colors.amber : Colors.teal;
    // Numeric backends show the formatted rating when set; binary backends
    // rely on the filled icon to communicate the like state and keep the
    // "Rate" label as the action prompt either way.
    final label = isNumeric && hasRating ? formatRating(starValue) : t.mediaMenu.rate;

    return ListenableBuilder(
      listenable: _ratingChipFocusNode,
      builder: (context, _) {
        final activate = () => _showRatingDialog(context, metadata);
        final colorScheme = Theme.of(context).colorScheme;
        final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
        final showFocus = _ratingChipFocusNode.hasFocus && isKeyboardMode;
        final bgColor = showFocus ? colorScheme.inverseSurface : colorScheme.secondaryContainer.withValues(alpha: 0.8);
        final fgColor = showFocus ? colorScheme.onInverseSurface : colorScheme.onSecondaryContainer;

        return FocusableWrapper(
          focusNode: _ratingChipFocusNode,
          onSelect: activate,
          borderRadius: 100,
          disableScale: true,
          useBackgroundFocus: true,
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
      },
    );
  }

  void _showRatingDialog(BuildContext sheetContext, MediaItem metadata) {
    OverlaySheetController.showAdaptive(
      sheetContext,
      builder: (context) => RatingBottomSheet(
        item: metadata,
        serverClient: _getMediaClientForMetadata(this.context),
        onServerRatingChanged: (rating) {
          setStateIfMounted(() {
            _fullMetadata = (_fullMetadata ?? widget.metadata).copyWith(userRating: rating);
          });
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

  MediaServerClient? _getArtworkMediaClient(BuildContext context) {
    if (!widget.isOffline) return _getMediaClientForMetadata(context);
    return context.tryGetMediaClientForServer(_metadata.serverId);
  }

  Widget? _buildOfflineArtworkIfAvailable(
    BuildContext context, {
    required Iterable<String?> artworkPaths,
    required BoxFit fit,
    required ImageType imageType,
    Alignment alignment = Alignment.center,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
  }) {
    if (!widget.isOffline || _metadata.serverId == null) return null;

    final downloadProvider = context.read<DownloadProvider>();
    for (final artworkPath in artworkPaths) {
      final localPath = downloadProvider.getArtworkLocalPath(_metadata.serverId!, artworkPath);
      if (localPath == null || !File(localPath).existsSync()) continue;

      return OptimizedMediaImage(
        client: null,
        imagePath: null,
        localFilePath: localPath,
        fit: fit,
        alignment: alignment,
        imageType: imageType,
        errorWidget: errorWidget,
      );
    }

    return null;
  }

  Widget _buildHeroNetworkArtwork(
    BuildContext context, {
    required MediaServerClient? client,
    required List<String> artworkPaths,
    required Size mediaSize,
    required double dpr,
    required int memCacheHeight,
    int index = 0,
  }) {
    if (index >= artworkPaths.length) return const PlaceholderContainer();

    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
      client: client,
      thumbPath: artworkPaths[index],
      maxWidth: mediaSize.width,
      maxHeight: mediaSize.height * 0.6,
      devicePixelRatio: dpr,
      imageType: ImageType.art,
    );
    if (imageUrl.isEmpty) {
      return _buildHeroNetworkArtwork(
        context,
        client: client,
        artworkPaths: artworkPaths,
        mediaSize: mediaSize,
        dpr: dpr,
        memCacheHeight: memCacheHeight,
        index: index + 1,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: PlexImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => const PlaceholderContainer(),
      errorBuilder: (context, error, stackTrace) => _buildHeroNetworkArtwork(
        context,
        client: client,
        artworkPaths: artworkPaths,
        mediaSize: mediaSize,
        dpr: dpr,
        memCacheHeight: memCacheHeight,
        index: index + 1,
      ),
    );
  }

  String _syncRuleKeyForMetadata(BuildContext context, DownloadProvider downloadProvider, MediaItem metadata) {
    final serverId = metadata.serverId;
    final client = _getMediaClientForMetadata(context);
    if (client == null || serverId == null) return metadata.globalKey;
    return downloadProvider.syncRuleKeyForClient(client, metadata.id, serverId: serverId);
  }

  void _navigateToActorMedia(MediaRole actor) {
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
          displayTitle: metadata.displayTitle,
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
      _hasLoadedExtras = false;
      _hasLoadedRelatedHubs = false;
    });

    // Offline mode: try to load full metadata from cache (has clearLogo, summary, etc.)
    if (widget.isOffline) {
      final cachedMetadata = await context.read<DownloadProvider>().lookupOfflineMetadata(
        _metadata.serverId ?? '',
        _metadata.id,
      );
      if (!mounted) return;
      setState(() {
        _fullMetadata = _applyLocalProgress(cachedMetadata ?? _metadata);
        _isLoadingMetadata = false;
        _hasLoadedExtras = true;
        _hasLoadedRelatedHubs = true;
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
          _fullMetadata = _applyLocalProgress(_metadata);
          _isLoadingMetadata = false;
          _hasLoadedSeasons = true;
          _hasLoadedEpisodes = true;
          _hasLoadedExtras = true;
          _hasLoadedRelatedHubs = true;
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
      final source = metadata ?? _metadata;
      final base = _applyLocalProgress(
        _withFallbackLibrary(
          source.copyWith(serverId: serverId ?? source.serverId, serverName: serverName ?? source.serverName),
          _metadata,
        ),
      );
      final onDeckWithServerId = onDeckEpisode == null
          ? null
          : _applyLocalProgress(
              _withFallbackLibrary(
                onDeckEpisode.copyWith(
                  serverId: serverId ?? onDeckEpisode.serverId,
                  serverName: serverName ?? onDeckEpisode.serverName,
                ),
                base,
              ),
            );

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
        _fullMetadata = _applyLocalProgress(_metadata);
        _isLoadingMetadata = false;
        _hasLoadedExtras = true;
        _hasLoadedRelatedHubs = true;
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
      _hasLoadedSeasons = false;
    });

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (client == null) {
      setStateIfMounted(() {
        _isLoadingSeasons = false;
        _hasLoadedSeasons = true;
      });
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
          .map(
            (season) => _withFallbackLibrary(
              season.copyWith(serverId: serverId, serverName: _metadata.serverName ?? season.serverName),
              _metadata,
            ),
          )
          .toList();

      // Plex can override the library season mode per show; Jellyfin falls
      // through to "flatten when there's a single season".
      bool shouldShowEpisodesDirectly;
      if (client is PlexClient) {
        shouldShowEpisodesDirectly = shouldShowPlexEpisodesDirectly(
          show: _metadata,
          seasons: seasonsWithServerId,
          libraryPrefs: prefs,
        );
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
        _hasLoadedSeasons = true;
        _showEpisodesDirectly = shouldShowEpisodesDirectly;
        _selectedSeasonIndex = onDeckSeasonIndex;
      });

      if (shouldShowEpisodesDirectly) {
        await _fetchAllEpisodes();
      } else if (seasonsWithServerId.isNotEmpty) {
        if (PlatformDetector.isTV()) {
          await _fetchSeasonEpisodes(onDeckSeasonIndex);
          unawaited(_warmTvSeasonEpisodeCaches(onDeckSeasonIndex));
        } else {
          // Fetch episodes for the auto-selected season
          unawaited(_fetchSeasonEpisodes(onDeckSeasonIndex));
        }
      }
    } catch (e, st) {
      appLogger.w('Seasons load failed', error: e, stackTrace: st);
      setStateIfMounted(() {
        _isLoadingSeasons = false;
        _hasLoadedSeasons = true;
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
        libraryId: firstEp.libraryId ?? _metadata.libraryId,
        libraryTitle: firstEp.libraryTitle ?? _metadata.libraryTitle,
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
      _hasLoadedSeasons = true;
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
      _episodes = seasonEpisodes.map(_applyLocalProgress).toList();
      _isLoadingEpisodes = false;
      _hasLoadedEpisodes = true;
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
    final seasonId = season.id;

    // Check cache first
    final cached = _episodeCache[seasonId];
    if (cached != null) {
      setStateIfMounted(() {
        if (_isSelectedSeason(seasonIndex, seasonId)) {
          _episodes = cached.map(_applyLocalProgress).toList();
          _isLoadingSeasonEpisodes = false;
        }
      });
      return;
    }

    if (!_seasonEpisodeLoadsInFlight.add(seasonId)) {
      setStateIfMounted(() {
        if (_isSelectedSeason(seasonIndex, seasonId)) _isLoadingSeasonEpisodes = true;
      });
      return;
    }

    setStateIfMounted(() {
      if (_isSelectedSeason(seasonIndex, seasonId)) _isLoadingSeasonEpisodes = true;
    });

    try {
      if (widget.isOffline) {
        // Offline: load from downloads
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);
        final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == season.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        _completeSeasonEpisodesLoad(
          seasonIndex: seasonIndex,
          seasonId: seasonId,
          episodes: seasonEpisodes.map(_applyLocalProgress).toList(),
        );
      } else {
        // Resolve the right backend client so Jellyfin (where the typed
        // PlexClient helper returns null) loads episodes too.
        final serverId = _metadata.serverId;
        final mediaClient = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
        if (serverId == null || mediaClient == null) {
          _completeSeasonEpisodesLoad(seasonIndex: seasonIndex, seasonId: seasonId, episodes: const <MediaItem>[]);
          return;
        }
        final episodes = await mediaClient.fetchChildren(season.id);
        final episodesWithServerId = episodes
            .map(
              (e) => _withFallbackLibrary(
                e.copyWith(
                  serverId: _metadata.serverId ?? e.serverId,
                  serverName: _metadata.serverName ?? e.serverName,
                  grandparentId: _metadata.id,
                  grandparentTitle: _metadata.title ?? e.grandparentTitle,
                ),
                season.libraryId != null ? season : _metadata,
              ),
            )
            .map(_applyLocalProgress)
            .toList();
        _completeSeasonEpisodesLoad(seasonIndex: seasonIndex, seasonId: seasonId, episodes: episodesWithServerId);
      }
    } catch (e) {
      _completeSeasonEpisodesLoad(seasonIndex: seasonIndex, seasonId: seasonId, episodes: const <MediaItem>[]);
    } finally {
      _seasonEpisodeLoadsInFlight.remove(seasonId);
    }
  }

  bool _isSelectedSeason(int seasonIndex, String seasonId) {
    return _selectedSeasonIndex == seasonIndex &&
        seasonIndex >= 0 &&
        seasonIndex < _seasons.length &&
        _seasons[seasonIndex].id == seasonId;
  }

  Future<void> _warmTvSeasonEpisodeCaches(int selectedSeasonIndex) async {
    if (widget.isOffline || _showEpisodesDirectly || _seasons.isEmpty) return;
    final generation = ++_tvSeasonEpisodeCacheWarmGeneration;
    final seasons = List<MediaItem>.of(_seasons);
    final seasonIdsToWarm = {
      for (var i = 0; i < seasons.length; i++)
        if (i != selectedSeasonIndex && !_episodeCache.containsKey(seasons[i].id)) seasons[i].id,
    };
    if (seasonIdsToWarm.isEmpty) return;

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (serverId == null || client == null) return;

    final seasonsById = {for (final season in seasons) season.id: season};
    final seasonsByIndex = <int, MediaItem>{
      for (final season in seasons)
        if (season.index != null) season.index!: season,
    };
    final episodesBySeasonId = {
      for (final season in seasons)
        if (seasonIdsToWarm.contains(season.id)) season.id: <MediaItem>[],
    };

    try {
      var offset = 0;
      var total = 0;
      do {
        final page = await client.fetchPlayableDescendantsPage(_metadata.id, start: offset, size: _episodesPageSize);
        if (!mounted || generation != _tvSeasonEpisodeCacheWarmGeneration) return;
        if (page.items.isEmpty) break;

        final enriched = _enrichPlayableEpisodes(page.items, serverId);
        for (final episode in enriched) {
          final seasonId = _seasonIdForEpisode(episode, seasonsById: seasonsById, seasonsByIndex: seasonsByIndex);
          if (seasonId == null || !seasonIdsToWarm.contains(seasonId)) continue;
          episodesBySeasonId[seasonId]?.add(episode);
        }

        offset += page.items.length;
        total = page.totalCount;
      } while (offset < total && total > 0);

      _completeWarmedTvSeasonEpisodeCaches(seasons, episodesBySeasonId, generation);
    } catch (e, st) {
      appLogger.w('Failed to load TV season episode caches', error: e, stackTrace: st);
      await _warmTvSeasonEpisodeCachesBySeason(seasons, seasonIdsToWarm, client, serverId, generation);
    }
  }

  Future<void> _warmTvSeasonEpisodeCachesBySeason(
    List<MediaItem> seasons,
    Set<String> seasonIdsToWarm,
    MediaServerClient client,
    String serverId,
    int generation,
  ) async {
    final episodesBySeasonId = <String, List<MediaItem>>{};

    for (final season in seasons) {
      if (!seasonIdsToWarm.contains(season.id) || _episodeCache.containsKey(season.id)) continue;
      if (!mounted || generation != _tvSeasonEpisodeCacheWarmGeneration) return;
      try {
        final episodes = await client.fetchChildren(season.id);
        if (!mounted || generation != _tvSeasonEpisodeCacheWarmGeneration) return;
        episodesBySeasonId[season.id] = episodes
            .map(
              (episode) => _withFallbackLibrary(
                episode.copyWith(
                  serverId: serverId,
                  serverName: _metadata.serverName ?? episode.serverName,
                  grandparentId: _metadata.id,
                  grandparentTitle: _metadata.title ?? episode.grandparentTitle,
                  parentId: season.id,
                  parentIndex: season.index ?? episode.parentIndex,
                ),
                season.libraryId != null ? season : _metadata,
              ),
            )
            .map(_applyLocalProgress)
            .toList();
      } catch (e, st) {
        appLogger.w('Failed to load TV season episodes for ${season.id}', error: e, stackTrace: st);
        episodesBySeasonId[season.id] = const <MediaItem>[];
      }
    }

    _completeWarmedTvSeasonEpisodeCaches(seasons, episodesBySeasonId, generation);
  }

  String? _seasonIdForEpisode(
    MediaItem episode, {
    required Map<String, MediaItem> seasonsById,
    required Map<int, MediaItem> seasonsByIndex,
  }) {
    final parentId = episode.parentId;
    if (parentId != null && seasonsById.containsKey(parentId)) return parentId;

    final parentIndex = episode.parentIndex;
    if (parentIndex != null) return seasonsByIndex[parentIndex]?.id;

    return null;
  }

  void _completeWarmedTvSeasonEpisodeCaches(
    List<MediaItem> seasons,
    Map<String, List<MediaItem>> episodesBySeasonId,
    int generation,
  ) {
    if (!mounted || generation != _tvSeasonEpisodeCacheWarmGeneration) return;
    final currentSeasonIds = _seasons.map((season) => season.id).toSet();
    setStateIfMounted(() {
      for (final season in seasons) {
        if (!currentSeasonIds.contains(season.id) || _episodeCache.containsKey(season.id)) continue;
        _episodeCache[season.id] = List.of(episodesBySeasonId[season.id] ?? const <MediaItem>[]);
      }
    });
  }

  void _completeSeasonEpisodesLoad({
    required int seasonIndex,
    required String seasonId,
    required List<MediaItem> episodes,
  }) {
    setStateIfMounted(() {
      _episodeCache[seasonId] = episodes;
      if (_isSelectedSeason(seasonIndex, seasonId)) {
        _episodes = List.of(episodes);
        _isLoadingSeasonEpisodes = false;
      }
    });
  }

  /// Load extras (trailers, behind-the-scenes, etc.). Plex-only — Jellyfin
  /// has no equivalent of `fetchExtras`.
  Future<void> _loadExtras() async {
    void markLoaded() {
      setStateIfMounted(() {
        _hasLoadedExtras = true;
      });
    }

    // Only load extras for movies and shows
    if (!_metadata.isMovie && !_metadata.isShow) {
      markLoaded();
      return;
    }

    // Skip in offline mode (no server available)
    if (widget.isOffline) {
      markLoaded();
      return;
    }

    if (_metadata.backend != MediaBackend.plex) {
      markLoaded();
      return;
    }

    try {
      final client = getServerBoundPlexClient(context);
      if (client == null) {
        markLoaded();
        return;
      }

      final extras = await client.fetchExtras(_metadata.id);

      // Preserve serverId for each extra (needed for multi-server setups).
      final extrasWithServerId = extras
          .map(
            (extra) => extra.copyWith(
              serverId: _metadata.serverId ?? extra.serverId,
              serverName: _metadata.serverName ?? extra.serverName,
            ),
          )
          .toList();

      setStateIfMounted(() {
        _extras = extrasWithServerId;
        _hasLoadedExtras = true;
      });
    } catch (e) {
      // Silently fail - extras section won't appear if fetch fails
      markLoaded();
    }
  }

  /// Load related hubs (collections, similar, "more from" director/actor).
  /// Backend-neutral — both Plex and Jellyfin implement
  /// [MediaServerClient.fetchRelatedHubs].
  Future<void> _loadRelatedHubs() async {
    void markLoaded() {
      setStateIfMounted(() {
        _hasLoadedRelatedHubs = true;
      });
    }

    if (!_metadata.isMovie && !_metadata.isShow) {
      markLoaded();
      return;
    }

    if (widget.isOffline) {
      markLoaded();
      return;
    }

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (client == null) {
      markLoaded();
      return;
    }

    try {
      final relatedHubs = await client.fetchRelatedHubs(_metadata.id);

      setStateIfMounted(() {
        _relatedHubs = relatedHubs;
        _relatedHubKeys = List.generate(relatedHubs.length, (_) => GlobalKey<HubSectionState>());
        _hasLoadedRelatedHubs = true;
      });
    } catch (e) {
      // Silently fail - related sections won't appear if fetch fails
      markLoaded();
    }
  }

  /// Focus the first visible section above cast: season tabs → overview → play button.
  /// Shared by cast UP, extras UP, and related hub UP handlers.
  void _focusSectionAboveCast() {
    final metadata = _fullMetadata ?? _metadata;
    if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
      _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
      _scrollSectionIntoView(_seasonsSectionKey);
    } else if (!PlatformDetector.isTV() && metadata.summary != null && metadata.summary!.isNotEmpty) {
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
    final isTv = PlatformDetector.isTV();

    if (isTv && key.isUpKey) {
      return KeyEventResult.handled;
    }

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

    if (isTv) {
      _tvDetailRailKey.currentState?.requestFocus();
      return KeyEventResult.handled;
    }

    // DOWN order: overview → seasons → cast → extras
    if (!PlatformDetector.isTV() && metadata.summary != null && metadata.summary!.isNotEmpty) {
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
    final density = SettingsService.instanceOrNull!.read(SettingsService.libraryDensity);
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
    return SettingValueBuilder<bool>(
      pref: SettingsService.showSeasonPostersOnTabs,
      builder: (context, showPosters, _) => _buildSeasonTabsContent(context, showPosters),
    );
  }

  Widget _buildSeasonTabsContent(BuildContext context, bool showPosters) {
    final showSeasonPosters = showPosters && !PlatformDetector.isTV();

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
            if (showSeasonPosters && posterPath != null && posterPath.isNotEmpty) {
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
                  errorBuilder: (context, error, stackTrace) => const PlaceholderContainer(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MediaContextMenu(
                key: contextMenuKey,
                item: season,
                onRefresh: (itemId) {
                  _watchStateChanged = true;
                  unawaited(_refreshItemInPlace(itemId));
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
                      if (PlatformDetector.isTV()) {
                        _tvDetailRailKey.currentState?.requestFocus();
                        return;
                      }
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

  void _handleExtrasFocusChange() {
    if (!_extrasFocusNode.hasFocus) _resetExtrasLongPressState();
  }

  void _resetExtrasLongPressState() {
    _selectKeyTimer?.cancel();
    _isSelectKeyDown = false;
    _longPressTriggered = false;
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

  static const Widget _sectionLoading = Center(
    child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
  );

  Widget _sectionEmpty(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
      ),
    );
  }

  /// Build episode list directly when the library hides seasons for single-season shows
  Widget _buildEpisodesList() {
    final client = _getMediaClientForMetadata(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _episodes.length + (_isLoadingAllEpisodes ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _episodes.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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
                  } else if (!PlatformDetector.isTV() && (_fullMetadata ?? _metadata).summary?.isNotEmpty == true) {
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
                    final updated = _applyLocalProgress(refreshed);
                    _episodes[index] = updated;
                    _syncEpisodeToCache(index, updated);
                  });
                }
              },
            );
          },
          onRefresh: widget.isOffline ? null : _refreshItemInPlace,
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
    final generation = ++_episodesLoadGeneration;
    if (_seasons.isEmpty) {
      setStateIfMounted(() {
        _isLoadingEpisodes = false;
        _isLoadingAllEpisodes = false;
        _hasLoadedEpisodes = true;
      });
      return;
    }
    final serverId = _metadata.serverId;
    if (serverId == null) {
      setStateIfMounted(() {
        _isLoadingEpisodes = false;
        _isLoadingAllEpisodes = false;
        _hasLoadedEpisodes = true;
      });
      return;
    }
    final client = context.tryGetMediaClientForServer(serverId);
    if (client == null) {
      setStateIfMounted(() {
        _isLoadingEpisodes = false;
        _isLoadingAllEpisodes = false;
        _hasLoadedEpisodes = true;
      });
      return;
    }
    setStateIfMounted(() {
      _isLoadingEpisodes = true;
      _isLoadingAllEpisodes = false;
      _hasLoadedEpisodes = false;
    });
    try {
      final firstPage = await client.fetchPlayableDescendantsPage(_metadata.id, start: 0, size: _episodesPageSize);
      if (!mounted || generation != _episodesLoadGeneration) return;
      final enriched = _enrichPlayableEpisodes(firstPage.items, serverId);
      setStateIfMounted(() {
        _episodes = enriched;
        _isLoadingEpisodes = false;
        _isLoadingAllEpisodes = firstPage.items.length < firstPage.totalCount;
        _hasLoadedEpisodes = true;
      });
      if (firstPage.items.length < firstPage.totalCount) {
        unawaited(_fetchRemainingEpisodes(client, serverId, generation, firstPage.items.length, firstPage.totalCount));
      }
    } catch (e, st) {
      appLogger.w('Failed to load episodes for all seasons', error: e, stackTrace: st);
      setStateIfMounted(() {
        _isLoadingEpisodes = false;
        _isLoadingAllEpisodes = false;
        _hasLoadedEpisodes = true;
      });
    }
  }

  List<MediaItem> _enrichPlayableEpisodes(List<MediaItem> episodes, String serverId) {
    // Enrich each episode with serverId/serverName/grandparent fields —
    // Jellyfin's recursive query doesn't always populate them, and the copy is
    // a no-op for Plex where the mapper already does.
    final fallbackGrandparentId = _metadata.isSeason ? (_metadata.grandparentId ?? _metadata.parentId) : _metadata.id;
    final fallbackGrandparentTitle = _metadata.isSeason
        ? (_metadata.grandparentTitle ?? _metadata.parentTitle)
        : _metadata.title;
    return episodes
        .map(
          (e) => _withFallbackLibrary(
            e.copyWith(
              serverId: serverId,
              serverName: _metadata.serverName ?? e.serverName,
              grandparentId: e.grandparentId ?? fallbackGrandparentId,
              grandparentTitle: e.grandparentTitle ?? fallbackGrandparentTitle,
            ),
            _metadata,
          ),
        )
        .map(_applyLocalProgress)
        .toList();
  }

  Future<void> _fetchRemainingEpisodes(
    MediaServerClient client,
    String serverId,
    int generation,
    int startOffset,
    int totalCount,
  ) async {
    var offset = startOffset;
    var total = totalCount;
    try {
      while (offset < total) {
        final page = await client.fetchPlayableDescendantsPage(_metadata.id, start: offset, size: _episodesPageSize);
        if (!mounted || generation != _episodesLoadGeneration) return;
        if (page.items.isEmpty) break;
        final enriched = _enrichPlayableEpisodes(page.items, serverId);
        setStateIfMounted(() {
          _episodes.addAll(enriched);
        });
        offset += page.items.length;
        total = page.totalCount;
      }
    } catch (e, st) {
      appLogger.w('Failed to finish loading all episodes', error: e, stackTrace: st);
    } finally {
      if (mounted && generation == _episodesLoadGeneration) {
        setStateIfMounted(() {
          _isLoadingAllEpisodes = false;
        });
      }
    }
  }

  /// Load the next unwatched episode for offline mode (offline OnDeck)
  Future<void> _loadOfflineOnDeckEpisode() async {
    final offlineWatchProvider = context.read<OfflineWatchProvider>();
    final nextEpisode = await offlineWatchProvider.getNextUnwatchedEpisode(_metadata.id);

    setStateIfMounted(() {
      _onDeckEpisode = nextEpisode == null ? null : _applyLocalProgress(nextEpisode);
    });

    if (nextEpisode != null) {
      appLogger.d('Offline OnDeck: S${nextEpisode.parentIndex}E${nextEpisode.index} - ${nextEpisode.title}');
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
      final episodeWithServerId = firstEpisode.copyWith(
        serverId: _metadata.serverId ?? firstEpisode.serverId,
        serverName: _metadata.serverName ?? firstEpisode.serverName,
        libraryId: firstEpisode.libraryId ?? _metadata.libraryId,
        libraryTitle: firstEpisode.libraryTitle ?? _metadata.libraryTitle,
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
    final sectionTitleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: isTv ? 28 : null,
    );

    // Show loading state while fetching full metadata
    if (_isLoadingMetadata) {
      final loading = Focus(
        onKeyEvent: _handleMediaDetailBackKey,
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
    final headerHeight = size.height * (isTv ? 1.0 : 0.6);

    if (isTv) {
      return _buildTvDetailScreen(context, metadata, _handleMediaDetailBackKey);
    }

    final content = OverlaySheetHost(
      child: Focus(
        onKeyEvent: _handleMediaDetailBackKey,
        child: Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Hero header with background art
                  SliverToBoxAdapter(child: _buildHeroHeader(context, metadata, size, headerHeight)),

                  // Main content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTv ? TvLayoutConstants.horizontalInset : 16,
                        vertical: isTv ? 8 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary
                          if (!isTv && metadata.summary != null && metadata.summary!.isNotEmpty) ...[
                            Text(key: _overviewSectionKey, t.discover.overview, style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            Focus(
                              focusNode: _overviewFocusNode,
                              onKeyEvent: _handleOverviewKeyEvent,
                              child: ListenableBuilder(
                                listenable: _overviewFocusNode,
                                builder: (context, _) {
                                  final showFocus =
                                      _overviewFocusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      border: Border.all(
                                        color: showFocus
                                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: () {
                                      final summaryStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
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
                              _sectionLoading
                            else if (_seasons.isEmpty)
                              _sectionEmpty(context, t.messages.noSeasonsFound)
                            else ...[
                              Text(key: _seasonsSectionKey, t.libraries.groupings.episodes, style: sectionTitleStyle),
                              const SizedBox(height: 12),
                              _buildSeasonTabs(),
                              const SizedBox(height: 16),
                              if (_isLoadingSeasonEpisodes)
                                _sectionLoading
                              else if (_episodes.isNotEmpty)
                                _buildEpisodesList()
                              else
                                _sectionEmpty(context, t.messages.noEpisodesFoundGeneral),
                            ],
                            const SizedBox(height: 24),
                          ] else if ((isShow && _showEpisodesDirectly) || metadata.isSeason) ...[
                            // Server says flatten — existing behavior unchanged
                            Text(key: _seasonsSectionKey, t.libraries.groupings.episodes, style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            if (_isLoadingSeasons || _isLoadingEpisodes)
                              _sectionLoading
                            else if (_episodes.isNotEmpty)
                              _buildEpisodesList()
                            else
                              _sectionEmpty(context, t.messages.noEpisodesFoundGeneral),
                            const SizedBox(height: 24),
                          ],

                          // Cast
                          if (metadata.roles != null && metadata.roles!.isNotEmpty) ...[
                            Text(key: _castSectionKey, t.discover.cast, style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            _buildCastSection(metadata),
                            const SizedBox(height: 24),
                          ],

                          // Trailers & Extras Section
                          if (!widget.isOffline && _extras != null && _extras!.isNotEmpty) ...[
                            Text(key: _extrasSectionKey, t.discover.extras, style: sectionTitleStyle),
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
                            SizedBox(height: isTv ? 28 : 8),
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

  Widget _buildTvDetailScreen(
    BuildContext context,
    MediaItem metadata,
    KeyEventResult Function(FocusNode, KeyEvent) handleBack,
  ) {
    final size = MediaQuery.sizeOf(context);
    final detailHubs = _tvDetailHubs(metadata);
    final hideSpoilers = SettingsService.instanceOrNull!.read(SettingsService.hideSpoilers);
    final detailScale = TvLayoutConstants.scaleForSize(size);
    final spotlightTop = (size.height * 0.08).clamp(44.0 * detailScale, 110.0 * detailScale).toDouble();
    final rawRailHeight = _estimateTvDetailRailHeight(size, detailHubs);
    if (!_tvDetailRevealed && _isTvDetailReadyToReveal(metadata)) {
      _scheduleTvDetailReveal(rawRailHeight, focusPrimaryAction: metadata.isMovie);
    }
    final stableRailHeight = _tvDetailStableRailHeight;
    final railHeight = stableRailHeight == null || rawRailHeight > stableRailHeight ? rawRailHeight : stableRailHeight;
    final railTopPadding = 12 * detailScale;
    final foregroundBottom = (railHeight - railTopPadding) + (_tvDetailActionRailGap * detailScale);
    final spotlightLeft = (24 * detailScale).clamp(18.0, 40.0).toDouble();

    final revealContent = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: spotlightLeft,
          right: size.width * 0.43,
          top: spotlightTop,
          bottom: foregroundBottom,
          child: _buildTvDetailForeground(context, metadata, hideSpoilers: hideSpoilers, scale: detailScale),
        ),
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
        if (detailHubs.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TvBrowseRail(
              key: _tvDetailRailKey,
              hubs: detailHubs,
              iconForHub: _getTvDetailHubIcon,
              onFocusedHubItemChanged: _handleTvDetailFocusedRailItemChanged,
              onRefresh: (itemId) => unawaited(_refreshItemInPlace(itemId)),
              onActiveHubChanged: _handleTvDetailHubChanged,
              onActivateItem: _handleTvDetailRailItemActivated,
              onNavigateUp: _focusTvDetailActionRow,
              onBack: _popMediaDetailIfBackNotSuppressed,
              tallPosterScale: _tvDetailTallPosterScale,
              widePosterScaleForHub: _tvDetailWidePosterScaleForHub,
              initialHubId: _tvDetailInitialHubId(metadata),
              initialItemId: _tvDetailInitialItemId(metadata),
              episodePosterModeForHub: _tvDetailEpisodePosterModeForHub,
            ),
          ),
      ],
    );

    final content = OverlaySheetHost(
      child: Focus(
        onKeyEvent: handleBack,
        child: Scaffold(
          body: Stack(
            children: [
              TvSpotlightBackground(item: metadata, client: _getArtworkMediaClient(context), showInfo: false),
              _buildTvDetailRevealGate(revealContent, handleBack),
            ],
          ),
        ),
      ),
    );

    final blockSystemBack = Platform.isAndroid && InputModeTracker.isKeyboardMode(context);
    if (!blockSystemBack) return content;
    return PopScope(
      canPop: false,
      // ignore: no-empty-block - required callback, blocks system back on Android TV
      onPopInvokedWithResult: (didPop, result) {},
      child: content,
    );
  }

  Widget _buildTvDetailForeground(
    BuildContext context,
    MediaItem metadata, {
    required bool hideSpoilers,
    required double scale,
  }) {
    final theme = Theme.of(context);
    final description = _tvDetailDescription(metadata, hideSpoilers: hideSpoilers);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) return const SizedBox.shrink();

        final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 264.0;
        final desiredLogoHeight = 220 * scale;
        final minLogoHeight = 72 * scale;
        final desiredLogoWidth = 790 * scale;
        final metadataLineHeight = 22 * scale;
        final logoMetadataGap = 10 * scale;
        final summaryGap = 10 * scale;
        final summaryFontSize = availableHeight < 260 * scale ? 16.2 * scale : 18 * scale;
        final summaryLineHeight = summaryFontSize * 1.35;
        final actionHeight = _tvDetailActionSize * scale;
        final actionGap = 12 * scale;
        final hasDescription = description != null && description.isNotEmpty;
        var summaryMaxLines = 0;
        var logoHeight = 0.0;

        for (var lines = hasDescription ? 3 : 0; lines >= 0; lines--) {
          final descriptionHeight = lines > 0 ? summaryGap + (summaryLineHeight * lines) : 0.0;
          final reservedHeight = logoMetadataGap + metadataLineHeight + descriptionHeight + actionGap + actionHeight;
          final remainingForLogo = availableHeight - reservedHeight;
          if (remainingForLogo >= minLogoHeight || lines == 0) {
            summaryMaxLines = lines;
            logoHeight = remainingForLogo <= 0 ? 0 : remainingForLogo.clamp(0, desiredLogoHeight).toDouble();
            break;
          }
        }

        final showLogo = logoHeight > 0;
        final descriptionHeight = summaryMaxLines > 0 ? summaryGap + (summaryLineHeight * summaryMaxLines) : 0.0;
        final contentHeight =
            (showLogo ? logoHeight + logoMetadataGap : 0) +
            metadataLineHeight +
            descriptionHeight +
            actionGap +
            actionHeight;
        final logoWidth = desiredLogoWidth < constraints.maxWidth ? desiredLogoWidth : constraints.maxWidth;

        return ClipRect(
          child: SizedBox(
            height: availableHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                height: contentHeight <= availableHeight ? contentHeight : availableHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLogo) ...[
                      _buildDetailLogoOrTitle(
                        context,
                        metadata,
                        width: logoWidth,
                        height: logoHeight,
                        titleBuilder: (context, title) => _buildDetailTitle(
                          context,
                          title,
                          fontSize: 56 * scale,
                          fontWeight: FontWeight.w800,
                          shadowBlur: 12,
                        ),
                      ),
                      SizedBox(height: logoMetadataGap),
                    ],
                    SizedBox(
                      height: metadataLineHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTvDetailMetadataLine(context, metadata, scale),
                      ),
                    ),
                    if (hasDescription && summaryMaxLines > 0) ...[
                      SizedBox(height: summaryGap),
                      SizedBox(
                        height: summaryLineHeight * summaryMaxLines,
                        child: Text(
                          description,
                          maxLines: summaryMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: summaryFontSize,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: actionGap),
                    SizedBox(height: actionHeight, child: _buildActionButtons(metadata)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailLogoOrTitle(
    BuildContext context,
    MediaItem metadata, {
    required double width,
    required double height,
    required Widget Function(BuildContext context, String title) titleBuilder,
  }) {
    Widget titleFallback(BuildContext context) => titleBuilder(context, metadata.displayTitle);

    if (metadata.clearLogoPath == null) {
      return SizedBox(width: width, height: height, child: titleFallback(context));
    }

    return SizedBox(
      width: width,
      height: height,
      child: Builder(
        builder: (context) {
          final localArtwork = _buildOfflineArtworkIfAvailable(
            context,
            artworkPaths: [metadata.clearLogoPath],
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            imageType: ImageType.logo,
            errorWidget: (context, url, error) => titleFallback(context),
          );
          if (localArtwork != null) return localArtwork;

          final client = _getArtworkMediaClient(context);
          final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
          final logoUrl = MediaImageHelper.getOptimizedImageUrl(
            client: client,
            thumbPath: metadata.clearLogoPath,
            maxWidth: width,
            maxHeight: height,
            devicePixelRatio: dpr,
            imageType: ImageType.logo,
          );

          if (logoUrl.isEmpty) return titleFallback(context);

          return blurArtwork(
            CachedNetworkImage(
              imageUrl: logoUrl,
              cacheManager: PlexImageCacheManager.instance,
              filterQuality: FilterQuality.medium,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              memCacheWidth: (width * dpr).clamp(200, 1000).round(),
              placeholder: (context, url) => const SizedBox.shrink(),
              errorBuilder: (context, error, stackTrace) => titleFallback(context),
            ),
            sigma: 10,
            clip: false,
          );
        },
      ),
    );
  }

  Widget _buildTvDetailMetadataLine(BuildContext context, MediaItem metadata, double scale) {
    final lineMetadata = _tvDetailFocusedEpisode ?? metadata;
    final episodeLabel = formatSeasonEpisodeLabel(lineMetadata.parentIndex, lineMetadata.index);
    final parts = [
      if (lineMetadata.isEpisode && episodeLabel != null) episodeLabel,
      if (lineMetadata.isMovie) t.discover.movie else if (lineMetadata.isShow) t.discover.tvShow,
      if (lineMetadata.rating != null) '★ ${formatRating(lineMetadata.rating!)}',
      if (lineMetadata.contentRating != null) formatContentRating(lineMetadata.contentRating!),
      if (lineMetadata.durationMs != null) formatDurationTextual(lineMetadata.durationMs!),
      if (lineMetadata.isEpisode && lineMetadata.originallyAvailableAt != null)
        formatFullDate(lineMetadata.originallyAvailableAt!)
      else if (lineMetadata.year != null)
        lineMetadata.year.toString(),
    ];

    return Text(
      parts.join('  •  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    );
  }

  String? _tvDetailDescription(MediaItem metadata, {required bool hideSpoilers}) {
    final focusedEpisode = _tvDetailFocusedEpisode;
    if (focusedEpisode == null) return _tvDetailItemDescription(metadata, hideSpoilers: hideSpoilers);

    final episodeDescription = _tvDetailItemDescription(
      focusedEpisode,
      hideSpoilers: hideSpoilers,
      showSpoilerFallback: false,
    );
    if (episodeDescription != null) return episodeDescription;

    final season = _tvDetailSeasonForEpisode(focusedEpisode, metadata);
    final seasonDescription = season == null ? null : _tvDetailItemDescription(season, hideSpoilers: hideSpoilers);
    if (seasonDescription != null) return seasonDescription;

    final showDescription = _tvDetailItemDescription(metadata, hideSpoilers: hideSpoilers);
    if (showDescription != null) return showDescription;

    if (hideSpoilers && focusedEpisode.shouldHideSpoiler) return focusedEpisode.title;
    return null;
  }

  String? _tvDetailItemDescription(MediaItem item, {required bool hideSpoilers, bool showSpoilerFallback = true}) {
    final shouldHideSpoiler = hideSpoilers && item.shouldHideSpoiler;
    final summary = shouldHideSpoiler ? null : item.summary;
    if (summary != null && summary.isNotEmpty) return summary;
    if (showSpoilerFallback && shouldHideSpoiler && item.isEpisode) return item.title;
    return null;
  }

  MediaItem? _tvDetailSeasonForEpisode(MediaItem episode, MediaItem metadata) {
    for (final season in _seasons) {
      if (episode.parentId != null && season.id == episode.parentId) return season;
      if (episode.parentIndex != null && season.index == episode.parentIndex) return season;
    }
    if (metadata.isSeason &&
        ((episode.parentId != null && metadata.id == episode.parentId) ||
            (episode.parentIndex != null && metadata.index == episode.parentIndex))) {
      return metadata;
    }
    return null;
  }

  double _estimateTvBrowseRailHeight(Size size, List<MediaHub> hubs) {
    final svc = SettingsService.instanceOrNull!;
    return TvBrowseRailLayout.estimateHeight(
      size: size,
      hubs: hubs,
      density: svc.read(SettingsService.libraryDensity),
      episodePosterMode: svc.read(SettingsService.episodePosterMode),
      episodePosterModeForHub: _tvDetailEpisodePosterModeForHub,
      widePosterScaleForHub: _tvDetailWidePosterScaleForHub,
      tallPosterScale: _tvDetailTallPosterScale,
    );
  }

  double _estimateTvDetailRailHeight(Size size, List<MediaHub> hubs) {
    final hubRailHeight = _estimateTvBrowseRailHeight(size, hubs);
    if (hubRailHeight > 0) return hubRailHeight;
    return _estimateTvDetailEmptyRailReserveHeight(size);
  }

  double _estimateTvDetailEmptyRailReserveHeight(Size size) {
    final svc = SettingsService.instanceOrNull!;
    final scale = TvBrowseRailLayout.scaleForSize(size);
    final availableWidth = size.width - TvBrowseRailLayout.horizontalInsetForScale(scale);
    if (availableWidth <= 0) return 0;

    final metrics = TvBrowseRailLayout.metricsForHub(
      hub: MediaHub(
        id: 'detail_empty_rail_reserve',
        title: '',
        type: 'movie',
        items: [MediaItem(id: 'detail_empty_rail_reserve_item', backend: _metadata.backend, kind: MediaKind.movie)],
      ),
      availableWidth: availableWidth,
      density: svc.read(SettingsService.libraryDensity),
      episodePosterMode: svc.read(SettingsService.episodePosterMode),
      scale: scale,
      tallPosterScale: _tvDetailTallPosterScale,
      widePosterScale: 1.0,
    );
    final sectionHeight = TvBrowseRailLayout.hubSectionHeightFor(scale: scale, activeRailHeight: metrics.height);
    return TvBrowseRailLayout.railTopPaddingForScale(scale) +
        TvBrowseRailLayout.viewportHeightFor(hubCount: 1, scale: scale, sectionHeight: sectionHeight) +
        TvBrowseRailLayout.railBottomPaddingForScale(scale);
  }

  bool _isTvDetailEpisodeHub(MediaHub hub) {
    return hub.id.startsWith(_tvDetailSeasonHubIdPrefix) || hub.id == 'detail_episodes';
  }

  EpisodePosterMode _tvDetailEpisodePosterModeForHub(MediaHub hub) {
    if (_isTvDetailEpisodeHub(hub)) return EpisodePosterMode.episodeThumbnail;
    return SettingsService.instanceOrNull!.read(SettingsService.episodePosterMode);
  }

  double _tvDetailWidePosterScaleForHub(MediaHub hub) {
    return _isTvDetailEpisodeHub(hub) ? _tvDetailEpisodeThumbnailScale : 1.0;
  }

  List<MediaHub> _tvDetailHubs(MediaItem metadata) {
    final hubs = <MediaHub>[];
    if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty) {
      for (var i = 0; i < _seasons.length; i++) {
        final season = _seasons[i];
        final cachedEpisodes = _episodeCache[season.id];
        if (cachedEpisodes == null) continue;
        final episodes = i == _selectedSeasonIndex ? _episodes : cachedEpisodes;
        hubs.add(
          MediaHub(
            id: '$_tvDetailSeasonHubIdPrefix$i',
            title: season.title?.isNotEmpty == true ? season.title! : (season.displaySubtitle ?? season.displayTitle),
            type: 'episode',
            items: episodes,
            size: episodes.length,
          ),
        );
      }
    } else if (_episodes.isNotEmpty) {
      hubs.add(
        MediaHub(
          id: 'detail_episodes',
          title: t.libraries.groupings.episodes,
          type: 'episode',
          items: _episodes,
          size: _episodes.length,
        ),
      );
    }
    final actors = _tvDetailActorItems(metadata);
    if (actors.isNotEmpty) {
      hubs.add(
        MediaHub(id: _tvDetailActorsHubId, title: t.discover.cast, type: 'person', items: actors, size: actors.length),
      );
    }
    if (_extras != null && _extras!.isNotEmpty) {
      hubs.add(
        MediaHub(id: 'detail_extras', title: t.discover.extras, type: 'clip', items: _extras!, size: _extras!.length),
      );
    }
    hubs.addAll(_relatedHubs.where((hub) => hub.items.isNotEmpty));
    return hubs;
  }

  String? _tvDetailInitialHubId(MediaItem metadata) {
    if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty) {
      return '$_tvDetailSeasonHubIdPrefix$_selectedSeasonIndex';
    }
    if ((metadata.isShow && _showEpisodesDirectly) || metadata.isSeason) {
      return 'detail_episodes';
    }
    return null;
  }

  String? _tvDetailInitialItemId(MediaItem metadata) {
    if (!metadata.isShow) return null;
    return _onDeckEpisode?.id;
  }

  List<MediaItem> _tvDetailActorItems(MediaItem metadata) {
    final roles = metadata.roles;
    if (roles == null || roles.isEmpty) return const [];

    return [
      for (var i = 0; i < roles.length; i++)
        if (roles[i].tag.trim().isNotEmpty) _tvDetailActorItem(metadata, roles[i], i),
    ];
  }

  MediaItem _tvDetailActorItem(MediaItem metadata, MediaRole actor, int index) {
    final personId = actor.id?.trim();
    return MediaItem(
      id: personId != null && personId.isNotEmpty ? '${metadata.id}_actor_$personId' : '${metadata.id}_actor_$index',
      backend: metadata.backend,
      kind: MediaKind.unknown,
      title: actor.tag,
      parentTitle: actor.role,
      thumbPath: actor.thumbPath,
      serverId: metadata.serverId,
      serverName: metadata.serverName,
      raw: {if (personId != null && personId.isNotEmpty) _tvDetailActorPersonIdRawKey: personId},
    );
  }

  bool _handleTvDetailRailItemActivated(MediaHub hub, MediaItem item) {
    if (hub.id != _tvDetailActorsHubId) return false;
    final personId = item.raw?[_tvDetailActorPersonIdRawKey];
    if (personId is String && personId.isNotEmpty) {
      _navigateToActorMedia(
        MediaRole(id: personId, tag: item.displayTitle, role: item.parentTitle, thumbPath: item.thumbPath),
      );
    }
    return true;
  }

  void _clearTvDetailFocusedEpisode() {
    if (_tvDetailFocusedEpisode == null) return;
    setStateIfMounted(() {
      _tvDetailFocusedEpisode = null;
    });
  }

  void _setTvDetailActionRowFocus(bool hasFocus) {
    _tvDetailActionRowHasFocus = hasFocus;
    if (hasFocus) _clearTvDetailFocusedEpisode();
  }

  void _focusTvDetailActionRow() {
    _tvDetailActionRowHasFocus = true;
    _clearTvDetailFocusedEpisode();
    _playButtonFocusNode.requestFocus();
  }

  void _handleTvDetailFocusedRailItemChanged(MediaHub hub, MediaItem item) {
    if (_tvDetailActionRowHasFocus) {
      _clearTvDetailFocusedEpisode();
      return;
    }
    if (!_isTvDetailEpisodeHub(hub) || !item.isEpisode) {
      _clearTvDetailFocusedEpisode();
      return;
    }
    if (_tvDetailFocusedEpisode?.id == item.id) return;
    setStateIfMounted(() {
      _tvDetailFocusedEpisode = item;
    });
  }

  void _handleTvDetailHubChanged(MediaHub hub, int index) {
    if (!_isTvDetailEpisodeHub(hub)) {
      _clearTvDetailFocusedEpisode();
      return;
    }
    if (hub.items.isEmpty) _clearTvDetailFocusedEpisode();
    if (!hub.id.startsWith(_tvDetailSeasonHubIdPrefix)) return;
    final seasonIndex = int.tryParse(hub.id.substring(_tvDetailSeasonHubIdPrefix.length));
    if (seasonIndex == null || seasonIndex < 0 || seasonIndex >= _seasons.length) return;
    final season = _seasons[seasonIndex];
    final cached = _episodeCache[season.id];
    if (_selectedSeasonIndex == seasonIndex && (cached != null || _episodes.isNotEmpty || _isLoadingSeasonEpisodes)) {
      return;
    }

    if (cached != null) {
      setStateIfMounted(() {
        _selectedSeasonIndex = seasonIndex;
        _episodes = cached.map(_applyLocalProgress).toList();
        _isLoadingSeasonEpisodes = false;
      });
      return;
    }

    setStateIfMounted(() {
      _selectedSeasonIndex = seasonIndex;
      _episodes = const <MediaItem>[];
      _isLoadingSeasonEpisodes = true;
    });
    unawaited(_fetchSeasonEpisodes(seasonIndex));
  }

  IconData _getTvDetailHubIcon(MediaHub hub, int index) {
    if (hub.id.startsWith(_tvDetailSeasonHubIdPrefix)) return Symbols.tv_rounded;
    if (hub.id == 'detail_episodes') return Symbols.tv_rounded;
    if (hub.id == 'detail_extras') return Symbols.theaters_rounded;
    if (hub.id == _tvDetailActorsHubId) return Symbols.group_rounded;
    return _getRelatedHubIcon(hub);
  }

  Widget _buildHeroHeader(BuildContext context, MediaItem metadata, Size size, double headerHeight) {
    return Stack(
      children: [
        // Background Art (fixed height, no parallax)
        SizedBox(
          height: headerHeight,
          width: double.infinity,
          child: Builder(
            builder: (context) {
              final containerAspect = size.width / headerHeight;
              final heroArtPaths = metadata.heroArtCandidates(containerAspectRatio: containerAspect);
              if (heroArtPaths.isEmpty) return const PlaceholderContainer();

              final localArtwork = _buildOfflineArtworkIfAvailable(
                context,
                artworkPaths: heroArtPaths,
                fit: BoxFit.cover,
                imageType: ImageType.art,
                errorWidget: (context, url, error) => const PlaceholderContainer(),
              );
              if (localArtwork != null) return localArtwork;

              final client = _getArtworkMediaClient(context);
              final mqSize = MediaQuery.sizeOf(context);
              final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
              final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
                displayWidth: (mqSize.width * dpr).round(),
                displayHeight: (headerHeight * dpr).round(),
                imageType: ImageType.art,
              );

              return blurArtwork(
                _buildHeroNetworkArtwork(
                  context,
                  client: client,
                  artworkPaths: heroArtPaths,
                  mediaSize: mqSize,
                  dpr: dpr,
                  memCacheHeight: memHeight,
                ),
              );
            },
          ),
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
          top: 0,
          bottom: 16,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHeroHeaderContent(context, metadata),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderContent(BuildContext context, MediaItem metadata) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) return const SizedBox.shrink();

        final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 264.0;
        const desiredLogoHeight = 120.0;
        const desiredLogoWidth = 400.0;
        const actionHeight = 48.0;
        final chips = <Widget>[
          if (metadata.year != null) _buildMetadataChip('${metadata.year}'),
          if (metadata case PlexMediaItem(:final editionTitle?)) _buildMetadataChip(editionTitle),
          if (metadata.contentRating != null) _buildMetadataChip(formatContentRating(metadata.contentRating!)),
          if (metadata.durationMs != null) _buildMetadataChip(formatDurationTextual(metadata.durationMs!)),
          ..._buildRatingChips(metadata),
        ];

        final showActions = availableHeight >= actionHeight;
        final remainingAfterActions = availableHeight - (showActions ? actionHeight : 0);
        final showChips = chips.isNotEmpty && remainingAfterActions >= 88;
        final chipHeight = showChips ? (remainingAfterActions >= 170 ? 68.0 : 32.0) : 0.0;
        final chipActionGap = showChips && showActions ? (availableHeight < 180 ? 8.0 : 16.0) : 0.0;
        final remainingForLogo = remainingAfterActions - chipHeight - chipActionGap;
        final logoGap = remainingForLogo >= 52 && (showChips || showActions)
            ? (availableHeight < 180 ? 8.0 : 12.0)
            : 0.0;
        final logoHeight = (remainingForLogo - logoGap).clamp(0.0, desiredLogoHeight).toDouble();
        final showLogo = logoHeight >= 24;
        final effectiveLogoGap = showLogo ? logoGap : 0.0;
        final logoWidth = desiredLogoWidth.clamp(0.0, constraints.maxWidth).toDouble();
        final titleFontSize = (logoHeight * 0.38).clamp(24.0, 40.0).toDouble();
        final contentHeight =
            (showLogo ? logoHeight + effectiveLogoGap : 0.0) +
            chipHeight +
            chipActionGap +
            (showActions ? actionHeight : 0.0);

        return ClipRect(
          child: SizedBox(
            height: availableHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                height: contentHeight.clamp(0.0, availableHeight).toDouble(),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLogo) ...[
                        _buildDetailLogoOrTitle(
                          context,
                          metadata,
                          width: logoWidth,
                          height: logoHeight,
                          titleBuilder: (context, title) => _buildDetailTitle(
                            context,
                            title,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            shadowBlur: 8,
                          ),
                        ),
                        if (effectiveLogoGap > 0) SizedBox(height: effectiveLogoGap),
                      ],
                      if (showChips)
                        ClipRect(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: chipHeight),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              heightFactor: 1,
                              child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                            ),
                          ),
                        ),
                      if (chipActionGap > 0) SizedBox(height: chipActionGap),
                      if (showActions) SizedBox(height: actionHeight, child: _buildActionButtons(metadata)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (context, libraryDensity, child) => _buildCastSectionContent(metadata),
    );
  }

  Widget _buildCastSectionContent(MediaItem metadata) {
    final cardWidth = _getResponsiveCardWidth();
    const innerPadding = 3.0;
    final imageSize = cardWidth;
    // image + inner padding + text area + outer list padding + focus scale headroom
    final containerHeight = imageSize + innerPadding * 2 + 66 + 16;

    final theme = Theme.of(context);
    final actorNameStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final actorRoleStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Focus(
      focusNode: _castFocusNode,
      onKeyEvent: _handleCastKeyEvent,
      child: ListenableBuilder(
        listenable: _castFocusNode,
        builder: (context, _) {
          final hasFocus = _castFocusNode.hasFocus;

          return SizedBox(
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
                                    Text(
                                      actor.tag,
                                      style: actorNameStyle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
          );
        },
      ),
    );
  }

  Widget _buildExtrasSection() {
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (context, libraryDensity, child) => _buildExtrasSectionContent(),
    );
  }

  Widget _buildExtrasSectionContent() {
    final cardWidth = _getResponsiveCardWidth();
    // 16:9 aspect ratio for clip thumbnails (cardWidth includes 8px padding on each side)
    final posterHeight = (cardWidth - 16) * (9 / 16);
    final containerHeight = posterHeight + 66;

    return Focus(
      focusNode: _extrasFocusNode,
      onKeyEvent: _handleExtrasKeyEvent,
      child: ListenableBuilder(
        listenable: _extrasFocusNode,
        builder: (context, _) {
          final hasFocus = _extrasFocusNode.hasFocus;

          return SizedBox(
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
          );
        },
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
