import 'dart:async';
import 'dart:math' as math;
import '../media/ids.dart';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../navigation/profile_navigation_scope.dart';
import '../services/device_performance.dart';
import '../services/image_cache_service.dart';
import '../services/fullscreen_state_manager.dart';
import 'package:flutter/services.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/rating_bottom_sheet.dart';

import '../focus/dpad_navigator.dart';
import '../focus/dpad_select_long_press_controller.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/hub_vertical_navigation.dart';
import '../focus/key_event_utils.dart';
import '../focus/input_mode_tracker.dart';
import '../widgets/cast_member_strip.dart';
import '../widgets/focus_builders.dart';
import '../media/library_query.dart';
import '../media/media_hub.dart';
import '../utils/provider_extensions.dart';
import '../utils/plex_season_display.dart';
import '../media/media_item.dart';
import '../media/episode_collection.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_role.dart';
import '../media/paged_media_list_state.dart';
import '../widgets/media_card.dart';
import '../widgets/media_rating_badge.dart';
import '../i18n/strings.g.dart';
import '../theme/mono_tokens.dart';
import '../widgets/cycling_media_backdrop.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_quality_labels.dart';
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
import '../services/watch_actions.dart';
import '../widgets/settings_builder.dart';
import '../utils/layout_constants.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/download_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../providers/watch_state_store.dart';
import '../services/catalog/catalog_source.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/scroll_utils.dart';
import '../utils/dialogs.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/app_menu.dart';
import '../widgets/catalog_source_logo.dart';
import '../widgets/desktop_app_bar.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/horizontal_scroll_with_arrows.dart';
import '../widgets/media_context_menu.dart';
import 'libraries/state_messages.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/placeholder_container.dart';
import '../mixins/watch_state_aware.dart';
import '../mixins/deletion_aware.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/server_bound_media_mixin.dart';
import '../utils/watch_state_notifier.dart';
import '../utils/deletion_notifier.dart';
import '../utils/global_key_utils.dart';
import '../widgets/episode_card.dart';
import '../widgets/fitting_title_text.dart';
import 'actor_media_screen.dart';
import '../widgets/focusable_tab_chip.dart';
import '../widgets/hub_section.dart';
import '../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/rasterized_gradient.dart';
import '../widgets/tv_browse_rail.dart';
import '../widgets/tv_spotlight_background.dart';

part 'media_detail/action_buttons.dart';

/// Ceiling for the detail hero's backdrop box, as a fraction of the window
/// height. Roughly the natural height of a 16:9 backdrop on a 16:10 desktop
/// window, so it does not bite there; it only kicks in on short/wide windows,
/// where an unbounded box would leave artwork showing under the overview.
const double _maxHeroArtViewportFraction = 0.86;

const double _tvDetailTallPosterScale = TvBrowseRailLayout.compactTallPosterScale;
const double _tvDetailEpisodeThumbnailScale = TvBrowseRailLayout.compactEpisodeThumbnailScale;
const double _tvDetailActionSize = 46;
const double _tvDetailActionRailGap = 4;
const String _tvDetailSeasonsErrorHubId = 'detail_seasons_error';
const String _tvDetailSeasonHubIdPrefix = 'detail_season_';
const String _tvDetailExtrasHubId = 'detail_extras';
const String _tvDetailActorsHubId = 'detail_actors';
const String _tvDetailActorPersonIdRawKey = 'tvDetailActorPersonId';

enum _SyncRuleAction { edit, remove, delete }

/// A watchlist-capable catalog source paired with this item's ids in that
/// source's terms (see `_resolveWatchlistIds`).
typedef WatchlistCandidate = ({CatalogSource source, CatalogItemIds ids});

class _SeasonEpisodePager {
  final Map<String, PagedMediaListState<MediaItem>> _states = {};
  final Set<String> _firstPageLoadsInFlight = {};
  final Set<String> _moreLoadsInFlight = {};

  PagedMediaListState<MediaItem> stateFor(String seasonId) {
    return _states[seasonId] ?? const PagedMediaListState<MediaItem>();
  }

  bool hasState(String seasonId) => _states.containsKey(seasonId);

  bool beginFirstPageLoad(String seasonId) => _firstPageLoadsInFlight.add(seasonId);
  void endFirstPageLoad(String seasonId) => _firstPageLoadsInFlight.remove(seasonId);

  bool beginMoreLoad(String seasonId) => _moreLoadsInFlight.add(seasonId);
  void endMoreLoad(String seasonId) => _moreLoadsInFlight.remove(seasonId);

  void markFirstPageLoading(String seasonId) {
    _states[seasonId] = stateFor(seasonId).startInitialLoad();
  }

  void completeFirstPage(String seasonId, List<MediaItem> episodes, int total) {
    _states[seasonId] = stateFor(seasonId).completeInitialLoad(episodes, total);
  }

  void failFirstPage(String seasonId) {
    _states[seasonId] = stateFor(seasonId).failInitialLoad();
  }

  void markMoreLoading(String seasonId) {
    _states[seasonId] = stateFor(seasonId).startLoadMore();
  }

  void completeMoreLoad(
    String seasonId, {
    required int expectedOffset,
    required List<MediaItem> episodes,
    required int total,
  }) {
    _states[seasonId] = stateFor(
      seasonId,
    ).completeLoadMore(expectedOffset: expectedOffset, pageItems: episodes, total: total);
  }

  void failMoreLoad(String seasonId) {
    _states[seasonId] = stateFor(seasonId).failLoadMore();
  }

  void resetSeason(String seasonId) {
    _states.remove(seasonId);
    _firstPageLoadsInFlight.remove(seasonId);
    _moreLoadsInFlight.remove(seasonId);
  }

  /// Drops cached episode pages for seasons outside [keepSeasonIds].
  /// In-flight sets are left alone — a completing prefetch just re-adds one
  /// bounded page. Evicted seasons transparently refetch through the normal
  /// unloaded-hub path when refocused.
  void retainOnly(Set<String> keepSeasonIds) {
    _states.removeWhere((seasonId, _) => !keepSeasonIds.contains(seasonId));
  }

  void removeEpisode(String episodeId) {
    for (final entry in _states.entries.toList()) {
      _states[entry.key] = entry.value.removeWhere((episode) => episode.id == episodeId);
    }
  }

  void patchEpisode(String episodeId, MediaItem Function(MediaItem existing) patch) {
    for (final entry in _states.entries.toList()) {
      var changed = false;
      final next = <MediaItem>[];
      for (final episode in entry.value.items) {
        if (episode.id == episodeId) {
          changed = true;
          next.add(patch(episode));
        } else {
          next.add(episode);
        }
      }
      if (changed) _states[entry.key] = entry.value.replaceItems(next);
    }
  }
}

class MediaDetailScreen extends StatefulWidget {
  final MediaItem metadata;
  final bool isOffline;

  /// If provided, auto-selects this season index when the screen loads.
  /// Used when navigating to a show from a season context.
  final int? initialSeasonIndex;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const MediaDetailScreen({
    super.key,
    required this.metadata,
    this.isOffline = false,
    this.initialSeasonIndex,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

PageRoute<bool> mediaDetailRoute({
  required MediaItem metadata,
  bool isOffline = false,
  int? initialSeasonIndex,
  String? initialSeasonId,
  String? initialEpisodeId,
}) {
  final page = MediaDetailScreen(
    metadata: metadata,
    isOffline: isOffline,
    initialSeasonIndex: initialSeasonIndex,
    initialSeasonId: initialSeasonId,
    initialEpisodeId: initialEpisodeId,
  );
  if (!PlatformDetector.isTV()) return MaterialPageRoute<bool>(builder: (_) => page);

  return PageRouteBuilder<bool>(
    // Opaque so the covered route stops painting/building once the fade
    // completes (the framework only offstages routes below after the
    // transition settles, so push/pop fades still composite over live
    // content). The detail screen paints a full-screen opaque background
    // immediately, and the video player route is itself opaque and never
    // sits below a detail route, so nothing can leak through.
    opaque: true,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
        child: child,
      );
    },
    transitionDuration: AppDurations.animMedium,
    reverseTransitionDuration: AppDurations.animMedium,
  );
}

class _MediaDetailScreenState extends State<MediaDetailScreen>
    with WatchStateAware, DeletionAware, MountedSetStateMixin, ServerBoundMediaMixin, RouteAware {
  /// Public input alias — used as the live source of truth until the detail
  /// fetch returns. Holds backend-neutral [MediaItem] data.
  MediaItem get _metadata => _fullMetadata ?? widget.metadata;
  List<MediaItem> _seasons = [];
  bool _isLoadingSeasons = false;
  bool _seasonsLoadFailed = false; // the seasons fetch threw (vs. a genuinely empty show)
  Completer<void>? _seasonsCompleter;
  List<MediaItem> _episodes = [];
  PagedMediaListState<MediaItem> _allEpisodes = const PagedMediaListState<MediaItem>();
  int _episodesLoadGeneration = 0;
  bool _showEpisodesDirectly = false;
  MediaItem? _fullMetadata;
  MediaItem? _onDeckEpisode;
  bool _isLoadingMetadata = true;
  List<MediaItem>? _extras;
  List<MediaHub> _relatedHubs = [];
  List<GlobalKey<HubSectionState>> _relatedHubKeys = [];
  bool _hasLoadedExtras = false;
  bool _hasLoadedRelatedHubs = false;
  final _tvDetailRailKey = GlobalKey<TvBrowseRailState>();
  PageRoute<dynamic>? _route;
  RouteObserver<PageRoute<dynamic>>? _routeObserver;
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
  // ValueNotifier (not setState) so d-pad scrubbing across episodes rebuilds
  // only the foreground info panel, never the whole screen with its rail
  // (same isolation pattern as DiscoverScreen._spotlightItem).
  final ValueNotifier<MediaItem?> _tvDetailFocusedEpisode = ValueNotifier(null);
  bool _tvDetailActionRowHasFocus = false;

  // Watchlist action (external catalog sources: Trakt, MAL). External ids
  // resolve once via the owning server, then per capable source; membership
  // comes from each source's session snapshot, so opening details never
  // costs a provider call. Multiple candidates → the toggle opens a chooser.
  List<WatchlistCandidate> _watchlistCandidates = const [];
  List<CatalogSource> _watchlistListenedSources = const [];
  final GlobalKey _watchlistButtonKey = GlobalKey();
  bool _watchlistMutationInFlight = false;

  // Inline season tabs
  int _selectedSeasonIndex = 0;
  final _seasonEpisodePager = _SeasonEpisodePager();
  List<FocusNode> _seasonTabFocusNodes = [];

  PagedMediaListState<MediaItem> get _selectedSeasonEpisodeState {
    if (_selectedSeasonIndex < 0 || _selectedSeasonIndex >= _seasons.length) {
      return const PagedMediaListState<MediaItem>();
    }
    return _seasonEpisodePager.stateFor(_seasons[_selectedSeasonIndex].id);
  }

  bool get _isLoadingEpisodes => _allEpisodes.isInitialLoading;
  bool get _isLoadingAllEpisodes => _allEpisodes.isLoadingMore;
  int get _allEpisodesTotal => _allEpisodes.totalCount;
  bool get _allEpisodesPageError => _allEpisodes.initialLoadFailed || _allEpisodes.pageLoadFailed;
  bool get _isLoadingSeasonEpisodes => _selectedSeasonEpisodeState.isInitialLoading;
  bool get _isLoadingMoreSeasonEpisodes => _selectedSeasonEpisodeState.isLoadingMore;
  bool get _seasonEpisodesPageError => _selectedSeasonEpisodeState.pageLoadFailed;
  bool get _seasonEpisodesFirstPageError => _selectedSeasonEpisodeState.initialLoadFailed;

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
  final FocusNode _initialEpisodeFocusNode = FocusNode(debugLabel: 'initial_episode');
  String? _lastEpisodeFocusPinnedKey;
  bool _suppressNextLastEpisodeFocusLoad = false;
  bool _initialDetailFocusApplied = false;
  bool _initialEpisodePagingInFlight = false;
  bool _initialEpisodePagingDone = false;
  static const int _episodesPageSize = 200;
  // Sentinel at the end of the inline episode list; its viewport position drives
  // lazy paging (the list is shrink-wrapped, so it can't self-detect near-end).
  final GlobalKey _episodeTailKey = GlobalKey();

  late final FocusNode _playButtonFocusNode;
  late final FocusNode _ratingChipFocusNode;
  final _extrasSelectLongPress = DpadSelectLongPressController();

  // Context menu key for the three-dots button
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  // Locked focus pattern for extras
  int _focusedExtraIndex = 0;
  final ValueNotifier<int> _focusedExtraIndexNotifier = ValueNotifier<int>(0);
  late final FocusNode _extrasFocusNode;
  final Map<int, GlobalKey<MediaCardState>> _extraCardKeys = {};
  final _extrasSectionKey = GlobalKey();

  // Locked focus pattern for overview
  late final FocusNode _overviewFocusNode;
  final _overviewSectionKey = GlobalKey();

  final _castStripKey = GlobalKey<CastMemberStripState>();
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

    final keys = <String>{toServerBoundGlobalKey(_metadata.id, serverId: ServerId(serverId))};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.id, serverId: ServerId(season.serverId ?? serverId)));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.id, serverId: ServerId(ep.serverId ?? serverId)));
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    _watchStateChanged = true;
    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) return;

    // Lists keep their server snapshots untouched; cards and the hero resolve
    // them against [WatchStateStore] at build, so a rebuild is all the
    // visuals need.
    setStateIfMounted(() {});

    if (event.changeType == WatchStateChangeType.progressUpdate && event.isNowWatched != true) return;

    if (widget.isOffline) {
      if (_metadata.isShow) {
        unawaited(_loadOfflineOnDeckEpisode());
      }
      return;
    }

    // Online: refresh server-derived counters and on-deck state. A watched
    // episode can change the hero play target even when the episode row itself
    // was already visible.
    unawaited(_refreshWatchState());
  }

  /// Session-fresh view of [item]: server snapshot + newest watch-state patch.
  MediaItem _fresh(MediaItem item) => context.readFreshWatchState(item);

  List<MediaItem> _freshAll(List<MediaItem> items) => context.readFreshWatchStateAll(items);

  MediaItem _normalizeRefreshedItem(MediaItem item, MediaItem fallback) {
    return _withFallbackLibrary(
      item.copyWith(
        serverId: item.serverId ?? fallback.serverId ?? _metadata.serverId,
        serverName: item.serverName ?? fallback.serverName ?? _metadata.serverName,
      ),
      fallback,
    );
  }

  void _patchItemEverywhere(String sourceGlobalKey, MediaItem item) {
    final base = _fullMetadata ?? widget.metadata;
    if (base.globalKey == sourceGlobalKey) {
      _fullMetadata = _normalizeRefreshedItem(item, base);
    }

    final onDeckEpisode = _onDeckEpisode;
    if (onDeckEpisode != null && onDeckEpisode.globalKey == sourceGlobalKey) {
      _onDeckEpisode = _normalizeRefreshedItem(item, onDeckEpisode);
    }

    _patchItemInList(_seasons, sourceGlobalKey, item);
    _patchItemInList(_episodes, sourceGlobalKey, item);
    _syncFlattenEpisodeState();
    _seasonEpisodePager.patchEpisode(
      item.id,
      (existing) => existing.globalKey == sourceGlobalKey ? _normalizeRefreshedItem(item, existing) : existing,
    );
    final extras = _extras;
    if (extras != null) {
      _patchItemInList(extras, sourceGlobalKey, item);
    }

    _relatedHubs = _patchItemInHubs(_relatedHubs, sourceGlobalKey, item);
  }

  void _patchItemInList(List<MediaItem> items, String sourceGlobalKey, MediaItem item) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].globalKey == sourceGlobalKey) {
        items[i] = _normalizeRefreshedItem(item, items[i]);
      }
    }
  }

  List<MediaHub> _patchItemInHubs(List<MediaHub> hubs, String sourceGlobalKey, MediaItem item) {
    var changed = false;
    final updatedHubs = <MediaHub>[];
    for (final hub in hubs) {
      var hubChanged = false;
      final items = List<MediaItem>.of(hub.items);
      for (var i = 0; i < items.length; i++) {
        if (items[i].globalKey == sourceGlobalKey) {
          items[i] = _normalizeRefreshedItem(item, items[i]);
          hubChanged = true;
        }
      }
      changed = changed || hubChanged;
      updatedHubs.add(hubChanged ? hub.copyWith(items: items) : hub);
    }
    return changed ? updatedHubs : hubs;
  }

  Future<void> _refreshItemInPlace(MediaItem source) async {
    final serverId = source.serverId;
    if (serverId == null) return;
    final client = context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) return;

    try {
      final refreshed = await client.fetchItem(source.id);
      if (refreshed == null || !mounted) return;
      setStateIfMounted(() {
        _patchItemEverywhere(source.globalKey, refreshed);
      });
    } catch (e) {
      appLogger.d('Item refresh failed for ${source.globalKey}', error: e);
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

    final keys = <String>{toServerBoundGlobalKey(_metadata.id, serverId: ServerId(serverId))};
    for (final season in _seasons) {
      keys.add(toServerBoundGlobalKey(season.id, serverId: ServerId(season.serverId ?? serverId)));
    }
    for (final ep in _episodes) {
      keys.add(toServerBoundGlobalKey(ep.id, serverId: ServerId(ep.serverId ?? serverId)));
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
        if (_isFlattenEpisodeList) {
          _allEpisodes = _allEpisodes.removeWhere((episode) => episode.id == event.itemId);
          _episodes = _allEpisodes.items;
        } else {
          _episodes.removeAt(epIndex);
        }
      });
    }
    _seasonEpisodePager.removeEpisode(event.itemId);

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
        final refreshedMetadata = _withFallbackLibrary(
          metadata.copyWith(serverId: serverId, serverName: serverName ?? metadata.serverName),
          _metadata,
        );
        final refreshedOnDeck = onDeckEpisode == null
            ? null
            : _withFallbackLibrary(
                onDeckEpisode.copyWith(serverId: serverId, serverName: serverName ?? onDeckEpisode.serverName),
                refreshedMetadata,
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
    _lastEpisodeFocusNode.addListener(_onLastEpisodeFocusChanged);
    _extrasFocusNode = FocusNode(debugLabel: 'extras_row');
    _extrasFocusNode.addListener(_handleExtrasFocusChange);
    _playButtonFocusNode = FocusNode(debugLabel: 'play_button');
    _ratingChipFocusNode = FocusNode(debugLabel: 'rating_chip');
    _overviewFocusNode = FocusNode(debugLabel: 'overview');
    _infoRowsFocusNode = FocusNode(debugLabel: 'info_rows');
    _loadFullMetadata();
    _initWatchlistState();
  }

  /// Hook up the watchlist action's data: every watchlist-capable catalog
  /// source this item resolves in, with its per-source ids. No-ops offline
  /// and for non-movie/show kinds.
  void _initWatchlistState() {
    if (widget.isOffline || (!_metadata.isMovie && !_metadata.isShow)) return;
    final sources = Provider.of<CatalogSourcesProvider?>(context, listen: false)?.watchlistCapableSources;
    if (sources == null || sources.isEmpty) return;
    _watchlistListenedSources = sources;
    for (final source in sources) {
      source.watchlistChanges.addListener(_onWatchlistSourceChanged);
      unawaited(source.ensureWatchlistLoaded());
    }
    unawaited(_resolveWatchlistIds(sources));
  }

  Future<void> _resolveWatchlistIds(List<CatalogSource> sources) async {
    try {
      final ids = await _getMediaClientForMetadata(context)?.fetchExternalIds(_metadata.id);
      if (!mounted || ids == null || !ids.hasAny) return;
      // Sources can require their own id forms (MAL maps external ids to an
      // anime id via Fribb); null means the item is outside that source's
      // domain. The action shows for the sources that resolved; with more
      // than one, the toggle opens a source chooser.
      final candidates = <WatchlistCandidate>[];
      for (final source in sources) {
        try {
          final resolved = await source.resolveItemIds(_metadata.kind, ids);
          if (resolved != null) candidates.add((source: source, ids: resolved));
        } catch (e, stackTrace) {
          appLogger.d(
            'Watchlist external-id resolution failed for ${source.id.name}',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      if (!mounted || candidates.isEmpty) return;
      setState(() => _watchlistCandidates = candidates);
    } catch (e) {
      appLogger.d('Watchlist external-id resolution failed', error: e);
    }
  }

  void _onWatchlistSourceChanged() {
    // ignore: no-empty-block - membership state lives in the source
    setStateIfMounted(() {});
  }

  void _onScroll() {
    final positions = _scrollController.positions;
    if (positions.length != 1) return;
    _scrollOffset.value = positions.first.pixels;
    _maybeTriggerEpisodePaging();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeObserver = ProfileNavigationScope.of(context).routeObserver;
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic>) return;
    if (route == _route && routeObserver == _routeObserver) return;
    _routeObserver?.unsubscribe(this);
    _route = route;
    _routeObserver = routeObserver;
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

  void _handleMediaDetailSystemBack() {
    if (BackKeyCoordinator.consumeIfHandled()) return;
    _popMediaDetailIfBackNotSuppressed();
  }

  bool _isTvDetailReadyToReveal(MediaItem metadata) {
    if (_isLoadingMetadata) return false;
    if (!_hasLoadedTvDetailSupplementalSections(metadata)) return false;

    if (metadata.isShow) {
      if (_isLoadingSeasons || (!_hasLoadedSeasons && _seasons.isEmpty)) return false;
      if (_showEpisodesDirectly) return _hasLoadedEpisodes && !_isLoadingEpisodes;
      if (_seasons.isEmpty) return true;
      if (_selectedSeasonIndex < 0 || _selectedSeasonIndex >= _seasons.length) return false;
      if (_seasonEpisodesFirstPageError) return true;
      return !_isLoadingSeasonEpisodes && _seasonEpisodePager.hasState(_seasons[_selectedSeasonIndex].id);
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
    for (final source in _watchlistListenedSources) {
      source.watchlistChanges.removeListener(_onWatchlistSourceChanged);
    }
    _routeObserver?.unsubscribe(this);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _tvDetailFocusedEpisode.dispose();
    _extrasScrollController.dispose();
    _extrasFocusNode.removeListener(_handleExtrasFocusChange);
    _extrasFocusNode.dispose();
    _focusedExtraIndexNotifier.dispose();
    _playButtonFocusNode.dispose();
    _ratingChipFocusNode.dispose();
    _overviewFocusNode.dispose();
    _infoRowsFocusNode.dispose();
    _extrasSelectLongPress.dispose();
    for (final node in _seasonTabFocusNodes) {
      node.dispose();
    }
    _seasonTabsScrollController.dispose();
    _firstEpisodeFocusNode.dispose();
    _lastEpisodeFocusNode.removeListener(_onLastEpisodeFocusChanged);
    _lastEpisodeFocusNode.dispose();
    _initialEpisodeFocusNode.dispose();
    super.dispose();
  }

  /// Build title text widget for clear logo fallback.
  Widget _buildDetailTitle(
    BuildContext context,
    String title, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    double shadowBlur = 8,
    Color? color,
    Color? shadowColor,
  }) {
    final baseStyle = (Theme.of(context).textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: color ?? Colors.white,
      fontWeight: fontWeight,
      fontSize: fontSize,
      shadows: [Shadow(color: shadowColor ?? Colors.black.withValues(alpha: 0.5), blurRadius: shadowBlur)],
    );

    return FittingTitleText(title, style: baseStyle);
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
        alignment: .center,
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
      style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: isTv ? 16 : 13, fontWeight: .w600),
    );

    final hasLeading = leading != null || icon != null;

    return Container(
      padding: .symmetric(horizontal: isTv ? 14 : 12, vertical: isTv ? 8 : 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: hasLeading
          ? Row(
              mainAxisSize: .min,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isTv = PlatformDetector.isTV();
    return MediaRatingBadge.chip(
      imageUri: imageUri,
      value: value,
      fallbackIcon: fallbackIcon,
      foregroundColor: colorScheme.onSecondaryContainer,
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.8),
      iconSize: isTv ? 20 : 16,
      spacing: isTv ? 6 : 4,
      padding: EdgeInsets.symmetric(horizontal: isTv ? 14 : 12, vertical: isTv ? 8 : 6),
      textStyle: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: isTv ? 16 : 13, fontWeight: .w600),
    );
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
      chips.add(_buildCombinedRtChip(ratingImage, metadata.rating!, audienceRatingImage, audienceRating));
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
    final active = isNumeric ? hasRating : metadata.isFavorite == true;

    final iconData = isNumeric ? Symbols.star_rounded : Symbols.favorite_rounded;
    final activeIconColor = isNumeric ? Colors.amber : Colors.redAccent;
    // Numeric backends show the formatted rating when set; favorite backends
    // rely on the filled heart to communicate the favorite state and keep the
    // "Rate" label as the action prompt either way.
    final label = isNumeric && hasRating ? formatRating(starValue) : t.mediaMenu.rate;

    return ListenableBuilder(
      listenable: _ratingChipFocusNode,
      builder: (context, _) {
        void activate() => _showRatingDialog(context, metadata);
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
            if (key.isLeftKey || key.isRightKey) {
              return KeyEventResult.handled; // consume — single chip, nothing beside it (#1181)
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
                mainAxisSize: .min,
                children: [
                  AppIcon(
                    iconData,
                    fill: active ? 1 : 0,
                    color: showFocus ? fgColor : (active ? activeIconColor : fgColor),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(color: fgColor, fontSize: 13, fontWeight: .w500),
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
    OverlaySheetController.of(sheetContext).show(
      showDragHandle: true,
      builder: (context) => RatingBottomSheet(
        item: metadata,
        serverClient: _getMediaClientForMetadata(this.context),
        onServerRatingChanged: (rating) {
          setStateIfMounted(() {
            _fullMetadata = (_fullMetadata ?? widget.metadata).copyWith(userRating: rating);
          });
        },
        onServerFavoriteChanged: (favorite) {
          setStateIfMounted(() {
            _fullMetadata = (_fullMetadata ?? widget.metadata).copyWith(isFavorite: favorite);
          });
        },
      ),
    );
  }

  /// Build a combined RT chip showing critic + audience side by side.
  Widget _buildCombinedRtChip(
    String? criticImageUri,
    double criticValue,
    String? audienceImageUri,
    double audienceValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13, fontWeight: .w500);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          MediaRatingBadge.inline(
            imageUri: criticImageUri,
            value: criticValue,
            fallbackIcon: Symbols.star_rounded,
            foregroundColor: colorScheme.onSecondaryContainer,
            iconSize: 16,
            spacing: 4,
            textStyle: textStyle,
          ),
          const SizedBox(width: 10),
          MediaRatingBadge.inline(
            imageUri: audienceImageUri,
            value: audienceValue,
            fallbackIcon: Symbols.people_rounded,
            foregroundColor: colorScheme.onSecondaryContainer,
            iconSize: 16,
            spacing: 4,
            textStyle: textStyle,
          ),
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
    return context.tryGetMediaClientForServer(serverIdOrNull(_metadata.serverId));
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

    for (final artworkPath in artworkPaths) {
      final localPath = _offlineArtworkLocalPath(context, artworkPath);
      if (localPath == null) continue;

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

  String? _offlineArtworkLocalPath(BuildContext context, String? artworkPath) {
    if (!widget.isOffline || _metadata.serverId == null) return null;
    final localPath = context.read<DownloadProvider>().getArtworkLocalPath(ServerId(_metadata.serverId!), artworkPath);
    if (localPath == null || !File(localPath).existsSync()) return null;
    return localPath;
  }

  String _syncRuleKeyForMetadata(BuildContext context, DownloadProvider downloadProvider, MediaItem metadata) {
    final serverId = metadata.serverId;
    final client = _getMediaClientForMetadata(context);
    if (client == null || serverId == null) return metadata.globalKey;
    return downloadProvider.syncRuleKeyForClient(client, metadata.id, serverId: ServerId(serverId));
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
      final serverId = serverIdOrNull(_metadata.serverId);
      final cachedMetadata = serverId == null
          ? null
          : await context.read<DownloadProvider>().lookupOfflineMetadata(serverId, _metadata.id);
      if (!mounted) return;
      setState(() {
        _fullMetadata = cachedMetadata ?? _metadata;
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
          _fullMetadata = _metadata;
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
      final base = _withFallbackLibrary(
        source.copyWith(serverId: serverId ?? source.serverId, serverName: serverName ?? source.serverName),
        _metadata,
      );
      final onDeckWithServerId = onDeckEpisode == null
          ? null
          : _withFallbackLibrary(
              onDeckEpisode.copyWith(
                serverId: serverId ?? onDeckEpisode.serverId,
                serverName: serverName ?? onDeckEpisode.serverName,
              ),
              base,
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
        _fullMetadata = _metadata;
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
      _seasonsLoadFailed = false;
      _hasLoadedSeasons = false;
    });

    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(ServerId(serverId));
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
      // Prefs are a per-library nicety (Plex "flatten seasons"); a failure here
      // must never take down the seasons list, so degrade to defaults.
      final prefsFuture = (client is PlexClient && sectionId != null)
          ? client.getLibrarySectionPrefs(sectionId).catchError((_) => <String, dynamic>{})
          : Future.value(<String, dynamic>{});

      final results = await Future.wait([seasonsFuture, prefsFuture]);
      final seasons = results.first as List<MediaItem>;
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
        _ensureFallbackOnDeckEpisode();
      } else if (seasonsWithServerId.isNotEmpty) {
        // Load only the on-deck season's first page; other seasons load lazily
        // when focused (strict on-demand — no whole-show pre-warm). Once the
        // on-deck season is loaded, synthesize on-deck if the backend omitted it.
        final fetchOnDeckSeason = _fetchSeasonEpisodes(onDeckSeasonIndex).then((_) => _ensureFallbackOnDeckEpisode());
        if (PlatformDetector.isTV()) {
          await fetchOnDeckSeason;
        } else {
          unawaited(fetchOnDeckSeason);
        }
      }
    } catch (e, st) {
      appLogger.w('Seasons load failed', error: e, stackTrace: st);
      setStateIfMounted(() {
        _isLoadingSeasons = false;
        _seasonsLoadFailed = true;
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
      final seasonId = firstEp.parentId ?? '';
      final seasonGlobalKey = _metadata.serverId == null || seasonId.isEmpty
          ? null
          : buildGlobalKey(ServerId(_metadata.serverId!), seasonId);
      final storedSeason = seasonGlobalKey == null ? null : downloadProvider.getMetadata(seasonGlobalKey);
      if (storedSeason != null && storedSeason.isSeason) {
        return _withFallbackLibrary(
          storedSeason.copyWith(
            serverId: _metadata.serverId,
            serverName: _metadata.serverName ?? storedSeason.serverName,
            leafCount: storedSeason.leafCount ?? entry.value.length,
          ),
          _metadata,
        );
      }
      return MediaItem(
        id: seasonId,
        backend: _metadata.backend,
        kind: MediaKind.season,
        title: firstEp.parentTitle?.isNotEmpty == true ? firstEp.parentTitle : t.common.seasonNumber(number: entry.key),
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
      final sortedEpisodes = entry.value..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
      _seasonEpisodePager.completeFirstPage(seasonRatingKey, sortedEpisodes, sortedEpisodes.length);
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
      _allEpisodes = _allEpisodes.completeInitialLoad(seasonEpisodes, seasonEpisodes.length);
      _episodes = _allEpisodes.items;
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

  /// Find the season index matching the initial selection or on-deck episode,
  /// then fall back to the same season the Play button would use.
  int _findOnDeckSeasonIndex(List<MediaItem> seasons) {
    return preferredSeasonIndex(
      seasons,
      initialSeasonId: widget.initialSeasonId,
      initialSeasonIndex: widget.initialSeasonIndex,
      onDeckEpisode: _onDeckEpisode,
    );
  }

  /// Fetch episodes for a specific season by index, using cache when available
  /// Load (or restore) the FIRST page of a season's episodes. The rest loads
  /// lazily via [_loadMoreSeasonEpisodes] as the user scrolls/navigates toward
  /// the end, so a 1000+ episode season never blocks on one giant request.
  Future<void> _fetchSeasonEpisodes(int seasonIndex) async {
    if (seasonIndex < 0 || seasonIndex >= _seasons.length) return;
    final season = _seasons[seasonIndex];
    final seasonId = season.id;

    // Restore from cache (which may hold only a partial page — more loads on
    // demand) and clear any prior per-season loading/error state.
    final cached = _seasonEpisodePager.stateFor(seasonId);
    if (_seasonEpisodePager.hasState(seasonId) && !cached.isInitialLoading && !cached.initialLoadFailed) {
      _seasonEpisodePager.completeFirstPage(seasonId, cached.items, cached.totalCount);
      setStateIfMounted(() {
        if (_isSelectedSeason(seasonIndex, seasonId)) {
          _episodes = List.of(_seasonEpisodePager.stateFor(seasonId).items);
        }
      });
      unawaited(_prefetchAdjacentSeasonEpisodePages(seasonIndex));
      return;
    }

    if (!_seasonEpisodePager.beginFirstPageLoad(seasonId)) {
      setStateIfMounted(() {
        if (_isSelectedSeason(seasonIndex, seasonId)) {
          _seasonEpisodePager.markFirstPageLoading(seasonId);
        }
      });
      return;
    }

    final generation = ++_episodesLoadGeneration;
    setStateIfMounted(() {
      if (_isSelectedSeason(seasonIndex, seasonId)) {
        _seasonEpisodePager.markFirstPageLoading(seasonId);
      }
    });

    try {
      if (widget.isOffline) {
        // Offline: load from downloads (already the complete set).
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);
        final seasonEpisodes = allEpisodes.where((ep) => ep.parentIndex == season.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        _completeSeasonEpisodesLoad(
          seasonIndex: seasonIndex,
          seasonId: seasonId,
          episodes: seasonEpisodes,
          total: seasonEpisodes.length,
          generation: generation,
        );
      } else {
        // Resolve the right backend client so Jellyfin (where the typed
        // PlexClient helper returns null) loads episodes too.
        final mediaClient = _getMediaClientForMetadata(context);
        if (mediaClient == null) {
          _completeSeasonEpisodesLoad(
            seasonIndex: seasonIndex,
            seasonId: seasonId,
            episodes: const <MediaItem>[],
            total: 0,
            generation: generation,
          );
          return;
        }
        final page = await fetchSeasonEpisodePage(
          mediaClient,
          show: _metadata,
          season: season,
          start: 0,
          size: _episodesPageSize,
        );
        if (!mounted || generation != _episodesLoadGeneration) return;
        _completeSeasonEpisodesLoad(
          seasonIndex: seasonIndex,
          seasonId: seasonId,
          episodes: page.items,
          total: page.totalCount,
          generation: generation,
        );
      }
    } catch (e, st) {
      appLogger.w('Season episodes load failed', error: e, stackTrace: st);
      if (mounted && generation == _episodesLoadGeneration && _isSelectedSeason(seasonIndex, seasonId)) {
        setStateIfMounted(() {
          _seasonEpisodePager.failFirstPage(seasonId);
        });
      }
    } finally {
      _seasonEpisodePager.endFirstPageLoad(seasonId);
    }
  }

  /// TV-only quality-of-life prefetch: warm just the first page of the adjacent
  /// seasons so horizontal season rail changes feel instant without reverting to
  /// whole-show or whole-season eager loading.
  Future<void> _prefetchAdjacentSeasonEpisodePages(int centerIndex) async {
    if (!PlatformDetector.isTV() || widget.isOffline || _showEpisodesDirectly || _seasons.isEmpty) return;
    for (final index in [centerIndex - 1, centerIndex + 1]) {
      if (index < 0 || index >= _seasons.length) continue;
      unawaited(_prefetchSeasonEpisodeFirstPage(index));
    }
  }

  Future<void> _prefetchSeasonEpisodeFirstPage(int seasonIndex) async {
    if (seasonIndex < 0 || seasonIndex >= _seasons.length) return;
    final season = _seasons[seasonIndex];
    final seasonId = season.id;
    if (_seasonEpisodePager.hasState(seasonId)) return;
    if (!_seasonEpisodePager.beginFirstPageLoad(seasonId)) return;

    try {
      final mediaClient = _getMediaClientForMetadata(context);
      if (mediaClient == null) return;
      final page = await fetchSeasonEpisodePage(
        mediaClient,
        show: _metadata,
        season: season,
        start: 0,
        size: _episodesPageSize,
      );
      if (!mounted || _showEpisodesDirectly || seasonIndex >= _seasons.length || _seasons[seasonIndex].id != seasonId) {
        return;
      }
      setStateIfMounted(() {
        final current = _seasonEpisodePager.stateFor(seasonId);
        if (_seasonEpisodePager.hasState(seasonId) && !(current.isInitialLoading && !current.hasItems)) return;
        _seasonEpisodePager.completeFirstPage(seasonId, page.items, page.totalCount);
        if (_isSelectedSeason(seasonIndex, seasonId)) {
          _episodes = List.of(_seasonEpisodePager.stateFor(seasonId).items);
        }
      });
      if (_isSelectedSeason(seasonIndex, seasonId)) unawaited(_prefetchAdjacentSeasonEpisodePages(seasonIndex));
    } catch (e, st) {
      appLogger.d('TV adjacent season episode prefetch failed', error: e, stackTrace: st);
      if (mounted && _isSelectedSeason(seasonIndex, seasonId)) {
        setStateIfMounted(() {
          _seasonEpisodePager.failFirstPage(seasonId);
        });
      }
    } finally {
      _seasonEpisodePager.endFirstPageLoad(seasonId);
    }
  }

  /// Load the next page of the selected season's episodes and append it.
  /// No-op when nothing more remains, offline, or a page is already in flight.
  Future<void> _loadMoreSeasonEpisodes() async {
    final seasonIndex = _selectedSeasonIndex;
    if (widget.isOffline || seasonIndex < 0 || seasonIndex >= _seasons.length) return;
    final season = _seasons[seasonIndex];
    final seasonId = season.id;
    final state = _seasonEpisodePager.stateFor(seasonId);
    final loaded = state.items.length;
    if (!state.hasMore) return;
    if (!_seasonEpisodePager.beginMoreLoad(seasonId)) return;
    final generation = _episodesLoadGeneration;

    setStateIfMounted(() {
      if (_isSelectedSeason(seasonIndex, seasonId)) {
        _seasonEpisodePager.markMoreLoading(seasonId);
      }
    });

    try {
      final mediaClient = _getMediaClientForMetadata(context);
      if (mediaClient == null) {
        setStateIfMounted(() {
          if (_isSelectedSeason(seasonIndex, seasonId)) {
            _seasonEpisodePager.completeMoreLoad(seasonId, expectedOffset: loaded, episodes: const [], total: loaded);
          }
        });
        return;
      }
      final page = await fetchSeasonEpisodePage(
        mediaClient,
        show: _metadata,
        season: season,
        start: loaded,
        size: _episodesPageSize,
      );
      if (!mounted || generation != _episodesLoadGeneration) return;
      setStateIfMounted(() {
        _seasonEpisodePager.completeMoreLoad(
          seasonId,
          expectedOffset: loaded,
          episodes: page.items,
          total: page.totalCount,
        );
        if (_isSelectedSeason(seasonIndex, seasonId)) _episodes = List.of(_seasonEpisodePager.stateFor(seasonId).items);
      });
    } catch (e, st) {
      appLogger.w('Season episodes page load failed', error: e, stackTrace: st);
      if (mounted && generation == _episodesLoadGeneration && _isSelectedSeason(seasonIndex, seasonId)) {
        setStateIfMounted(() {
          _seasonEpisodePager.failMoreLoad(seasonId);
        });
      }
    } finally {
      _seasonEpisodePager.endMoreLoad(seasonId);
    }
  }

  /// Whether the selected season has more episodes to page in.
  bool get _selectedSeasonHasMore {
    if (_selectedSeasonIndex < 0 || _selectedSeasonIndex >= _seasons.length) return false;
    return _selectedSeasonEpisodeState.hasMore;
  }

  bool _isSelectedSeason(int seasonIndex, String seasonId) {
    return _selectedSeasonIndex == seasonIndex &&
        seasonIndex >= 0 &&
        seasonIndex < _seasons.length &&
        _seasons[seasonIndex].id == seasonId;
  }

  void _completeSeasonEpisodesLoad({
    required int seasonIndex,
    required String seasonId,
    required List<MediaItem> episodes,
    required int total,
    required int generation,
  }) {
    if (generation != _episodesLoadGeneration) return;
    setStateIfMounted(() {
      _seasonEpisodePager.completeFirstPage(seasonId, episodes, total);
      if (_isSelectedSeason(seasonIndex, seasonId)) {
        _episodes = List.of(_seasonEpisodePager.stateFor(seasonId).items);
      }
    });
    if (_isSelectedSeason(seasonIndex, seasonId)) unawaited(_prefetchAdjacentSeasonEpisodePages(seasonIndex));
  }

  /// Load extras (trailers, featurettes, behind-the-scenes, etc.).
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

    try {
      final client = getServerBoundMediaClient(context);
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
    final client = serverId == null ? null : context.tryGetMediaClientForServer(ServerId(serverId));
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
      _castStripKey.currentState?.requestFocus();
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

  bool get _hasInitialDetailFocusTarget =>
      widget.initialEpisodeId != null || widget.initialSeasonId != null || widget.initialSeasonIndex != null;

  bool get _episodesContainInitialTarget {
    final targetEpisodeId = widget.initialEpisodeId;
    return targetEpisodeId != null && _episodes.any((episode) => episode.id == targetEpisodeId);
  }

  void _scheduleInitialMobileDetailFocus(MediaItem metadata) {
    if (_initialDetailFocusApplied || PlatformDetector.isTV() || !_hasInitialDetailFocusTarget) return;

    if (widget.initialEpisodeId != null) {
      if (_episodesContainInitialTarget) {
        _applyInitialMobileFocus(_initialTargetEpisodeFocusNode(), _seasonsSectionKey);
        return;
      }
      _maybeLoadMoreForInitialEpisode();
      // Target never materialized (stale/deleted id) — fall back to the
      // season anchors below instead of retrying forever.
      if (!_initialEpisodePagingDone) return;
    }

    if (metadata.isShow &&
        !_showEpisodesDirectly &&
        _seasons.isNotEmpty &&
        _seasonTabFocusNodes.length > _selectedSeasonIndex) {
      _applyInitialMobileFocus(_seasonTabFocusNodes[_selectedSeasonIndex], _seasonsSectionKey);
      return;
    }

    if (((metadata.isShow && _showEpisodesDirectly) || metadata.isSeason) && _episodes.isNotEmpty) {
      _applyInitialMobileFocus(_firstEpisodeFocusNode, _seasonsSectionKey);
    }
  }

  void _applyInitialMobileFocus(FocusNode node, GlobalKey sectionKey) {
    _initialDetailFocusApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      node.requestFocus();
      _scrollSectionIntoView(sectionKey);
    });
  }

  void _maybeLoadMoreForInitialEpisode() {
    if (_initialEpisodePagingDone || _initialEpisodePagingInFlight) return;
    if (_episodesContainInitialTarget) {
      _initialEpisodePagingDone = true;
      return;
    }

    final hasMore = _isFlattenEpisodeList ? _allEpisodes.hasMore : _selectedSeasonHasMore;
    final pageError = _isFlattenEpisodeList ? _allEpisodesPageError : _seasonEpisodesPageError;
    if (!hasMore || pageError) {
      // All pages loaded (or paging failed) without the target appearing.
      _initialEpisodePagingDone = true;
      return;
    }
    if (_isFlattenEpisodeList ? _isLoadingAllEpisodes : _isLoadingMoreSeasonEpisodes) return;

    _initialEpisodePagingInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _episodesContainInitialTarget) {
        _initialEpisodePagingInFlight = false;
        return;
      }

      Future<void>? load;
      if (_isFlattenEpisodeList) {
        if (_allEpisodes.hasMore && !_isLoadingAllEpisodes && !_allEpisodesPageError) {
          load = _loadMoreAllEpisodes();
        }
      } else if (_selectedSeasonHasMore && !_isLoadingMoreSeasonEpisodes && !_seasonEpisodesPageError) {
        load = _loadMoreSeasonEpisodes();
      }

      if (load == null) {
        _initialEpisodePagingInFlight = false;
        return;
      }

      // The loaders setState on success and failure, so the resulting rebuild
      // re-enters this method for the next page (or marks paging done).
      unawaited(load.whenComplete(() => _initialEpisodePagingInFlight = false));
    });
  }

  /// Focus the first available section above the primary action row.
  void _focusAboveActionRow() {
    if (PlatformDetector.isTV()) return;
    if (!widget.isOffline) _ratingChipFocusNode.requestFocus();
  }

  /// Focus the overview, or the first available content section when there is no overview.
  void _focusBelowActionRow() {
    final metadata = _fullMetadata ?? _metadata;

    if (PlatformDetector.isTV()) {
      _tvDetailRailKey.currentState?.requestFocus();
      return;
    }

    if (metadata.summary != null && metadata.summary!.isNotEmpty) {
      _overviewFocusNode.requestFocus();
      _scrollSectionIntoView(_overviewSectionKey);
      return;
    }

    _focusBelowOverview();
  }

  /// Focus the first available content section after the overview.
  void _focusBelowOverview() {
    final metadata = _fullMetadata ?? _metadata;

    // DOWN order: season tabs → episodes → cast → extras → related hubs → info rows.
    if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty && _seasonTabFocusNodes.isNotEmpty) {
      // Focus the selected season tab chip
      _seasonTabFocusNodes[_selectedSeasonIndex].requestFocus();
      _scrollSectionIntoView(_seasonsSectionKey);
      return;
    }

    if (_episodes.isNotEmpty) {
      _firstEpisodeFocusNode.requestFocus();
      _scrollSectionIntoView(_seasonsSectionKey);
      return;
    }

    if (metadata.roles != null && metadata.roles!.isNotEmpty) {
      _castStripKey.currentState?.requestFocus();
      _scrollSectionIntoView(_castSectionKey);
      return;
    }

    if (_extras != null && _extras!.isNotEmpty) {
      _extrasFocusNode.requestFocus();
      _scrollSectionIntoView(_extrasSectionKey);
      return;
    }

    if (_relatedHubs.isNotEmpty) {
      _relatedHubKeys.first.currentState?.requestFocusFromMemory();
      return;
    }

    if (_hasInfoRows) {
      _focusInfoRows();
    }
  }

  /// Get the responsive card width used by seasons/extras/cast rows.
  /// Delegates to the cast strip's calculator so the dpad scroll math and
  /// the rendered cards can never disagree.
  double _getResponsiveCardWidth() => CastMemberStrip.responsiveCardWidth(context);

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
              final localArtwork = _buildOfflineArtworkIfAvailable(
                context,
                artworkPaths: [posterPath],
                fit: BoxFit.cover,
                imageType: ImageType.poster,
                errorWidget: (context, url, error) => const PlaceholderContainer(),
              );
              topImage = SizedBox(
                width: posterWidth,
                height: posterHeight,
                child:
                    localArtwork ??
                    (widget.isOffline
                        ? const PlaceholderContainer()
                        : Builder(
                            builder: (context) {
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
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                cacheManager: PlexImageCacheManager.instance,
                                fit: BoxFit.cover,
                                memCacheWidth: memWidth,
                                placeholder: (context, url) => const PlaceholderContainer(),
                                errorBuilder: (context, error, stackTrace) => const PlaceholderContainer(),
                              );
                            },
                          )),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MediaContextMenu(
                key: contextMenuKey,
                item: season,
                onRefresh: (source) {
                  _watchStateChanged = true;
                  unawaited(_refreshItemInPlace(source));
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

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      if (event is KeyUpEvent && key.isSelectKey) {
        _extrasSelectLongPress.reset();
      }
      return KeyEventResult.handled;
    }

    final extras = _extras;
    if (extras == null || extras.isEmpty) {
      _extrasSelectLongPress.reset();
      return KeyEventResult.ignored;
    }

    final selectResult = _extrasSelectLongPress.handleKeyEvent(
      event,
      isOwnerActive: () => mounted,
      onShortPress: () {
        if (_focusedExtraIndex < extras.length) {
          navigateToVideoPlayer(context, metadata: extras[_focusedExtraIndex]);
        }
      },
      onLongPress: () {
        if (_focusedExtraIndex < _extraCardKeys.length) {
          _extraCardKeys[_focusedExtraIndex]?.currentState?.showContextMenu();
        }
      },
    );
    if (selectResult != KeyEventResult.ignored) return selectResult;

    if (!event.isActionable) return KeyEventResult.ignored;

    // LEFT: previous extra
    if (key.isLeftKey) {
      if (_focusedExtraIndex > 0) {
        _focusedExtraIndex--;
        _focusedExtraIndexNotifier.value = _focusedExtraIndex;
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
        _focusedExtraIndex++;
        _focusedExtraIndexNotifier.value = _focusedExtraIndex;
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
    _extrasSelectLongPress.reset();
  }

  void _focusSectionDirectlyAboveCast() {
    if (_episodes.isNotEmpty) {
      final useLastEpisode = _episodes.length > 1;
      if (useLastEpisode) _suppressNextLastEpisodeFocusLoad = true;
      final target = useLastEpisode ? _lastEpisodeFocusNode : _firstEpisodeFocusNode;
      target.requestFocus();
    } else {
      _focusSectionAboveCast();
    }
  }

  /// Focus the first visible section below cast.
  void _focusSectionBelowCast() {
    if (_extras != null && _extras!.isNotEmpty) {
      _extrasFocusNode.requestFocus();
      _scrollSectionIntoView(_extrasSectionKey);
    } else if (_relatedHubs.isNotEmpty) {
      _relatedHubKeys.first.currentState?.requestFocusFromMemory();
    } else if (_hasInfoRows) {
      _focusInfoRows();
    }
  }

  /// Handle vertical navigation between related hub sections
  bool _handleRelatedHubNavigation(int hubIndex, bool isUp) {
    return navigateVerticalHubRows(
      hubCount: _relatedHubKeys.length,
      hubIndex: hubIndex,
      isUp: isUp,
      onTopBoundary: () {
        if (_extras != null && _extras!.isNotEmpty) {
          _extrasFocusNode.requestFocus();
          _scrollSectionIntoView(_extrasSectionKey);
        } else {
          _focusSectionAboveExtras();
        }
      },
      onBottomBoundary: _hasInfoRows ? _focusInfoRows : null,
      requestFocus: (targetIndex) {
        _relatedHubKeys[targetIndex].currentState?.requestFocusFromMemory();
      },
    );
  }

  /// Handle key events for the trailing info rows (studio / contentRating).
  /// UP returns to the previous focusable section; terminal geometry is trapped.
  KeyEventResult _handleInfoRowsKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey) return KeyEventResult.ignored;
    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isUpKey) {
      _focusSectionAboveInfoRows();
      return KeyEventResult.handled;
    }

    if (key.isDownKey || key.isLeftKey || key.isRightKey || key.isSelectKey) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
    child: Padding(padding: .all(32), child: CircularProgressIndicator()),
  );

  Widget _sectionEmpty(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tokens(context).textMuted)),
      ),
    );
  }

  /// Retryable error for a section whose fetch threw (vs. [_sectionEmpty], which
  /// means a successful-but-empty result). Reuses the app-wide [ErrorStateWidget]
  /// so the Retry button is dpad-focusable.
  Widget _sectionError(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ErrorStateWidget(
        message: message,
        icon: Symbols.error_outline_rounded,
        onRetry: onRetry,
        retryLabel: t.common.retry,
      ),
    );
  }

  /// Build episode list directly when the library hides seasons for single-season shows
  Widget _buildEpisodesList() {
    final client = _getMediaClientForMetadata(context);
    final hasPinnedLastEpisode = _hasPinnedLastEpisodeInList;
    return ListView.builder(
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: .zero,
      itemCount: _episodes.length + (_episodeListHasMore || _episodeListLoadingMore || _episodeListPageError ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _episodes.length) {
          return _buildEpisodeListTail();
        }
        final episode = _episodes[index];
        String? localPosterPath;
        if (widget.isOffline && episode.serverId != null) {
          final artworkRef = context.read<DownloadProvider>().getArtworkPaths(episode.globalKey);
          localPosterPath = artworkRef?.getLocalPath(DownloadStorageService.instance, ServerId(episode.serverId!));
        }
        return EpisodeCard(
          episode: episode,
          client: client,
          isOffline: widget.isOffline,
          autofocus: false,
          focusNode: _episodeListFocusNode(episode: episode, index: index, hasPinnedLastEpisode: hasPinnedLastEpisode),
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
              onRefresh: () => unawaited(_refreshItemInPlace(episode)),
            );
          },
          onRefresh: widget.isOffline ? null : _refreshItemInPlace,
          onListRefresh: widget.isOffline ? null : _refreshCurrentEpisodes,
        );
      },
    );
  }

  bool _shouldUseLastEpisodeFocusNode({
    required MediaItem episode,
    required int index,
    required bool hasPinnedLastEpisode,
  }) {
    if (_episodes.length <= 1) return false;
    if (hasPinnedLastEpisode) return episode.globalKey == _lastEpisodeFocusPinnedKey;
    return index == _episodes.length - 1;
  }

  bool get _hasPinnedLastEpisodeInList {
    final pinnedKey = _lastEpisodeFocusPinnedKey;
    return pinnedKey != null && _episodes.any((episode) => episode.globalKey == pinnedKey);
  }

  /// Resolve the focus node for an inline episode list item. Role nodes
  /// (first/last) take priority so their consumers always find them attached;
  /// the initial navigation target only claims a node when no role applies.
  FocusNode? _episodeListFocusNode({
    required MediaItem episode,
    required int index,
    required bool hasPinnedLastEpisode,
  }) {
    if (index == 0) return _firstEpisodeFocusNode;
    if (_shouldUseLastEpisodeFocusNode(episode: episode, index: index, hasPinnedLastEpisode: hasPinnedLastEpisode)) {
      return _lastEpisodeFocusNode;
    }
    if (widget.initialEpisodeId == episode.id) return _initialEpisodeFocusNode;
    return null;
  }

  /// The node the initial target episode's card actually holds.
  FocusNode _initialTargetEpisodeFocusNode() {
    final index = _episodes.indexWhere((episode) => episode.id == widget.initialEpisodeId);
    if (index == -1) return _initialEpisodeFocusNode;
    return _episodeListFocusNode(
          episode: _episodes[index],
          index: index,
          hasPinnedLastEpisode: _hasPinnedLastEpisodeInList,
        ) ??
        _initialEpisodeFocusNode;
  }

  /// Tail of the inline episode list: a retry tile when a page failed, otherwise
  /// a spinner. Carries [_episodeTailKey] so the scroll listener can detect when
  /// it nears the viewport and page the next batch in.
  Widget _buildEpisodeListTail() {
    if (_episodeListPageError) {
      return Padding(
        key: _episodeTailKey,
        padding: const EdgeInsets.all(16),
        child: ErrorStateWidget(
          message: t.messages.episodesLoadFailed,
          icon: Symbols.error_outline_rounded,
          onRetry: () => unawaited(_loadMoreEpisodeList()),
          retryLabel: t.common.retry,
        ),
      );
    }
    return Padding(
      key: _episodeTailKey,
      padding: const EdgeInsets.all(24),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  void _syncFlattenEpisodeState() {
    if (_isFlattenEpisodeList) _allEpisodes = _allEpisodes.replaceItems(_episodes);
  }

  /// Refresh episodes for the current context (inline season or all flattened)
  Future<void> _refreshCurrentEpisodes() async {
    if (_showEpisodesDirectly) {
      await _fetchAllEpisodes();
    } else if (_seasons.isNotEmpty) {
      // Clear cache for current season and re-fetch
      final season = _seasons[_selectedSeasonIndex];
      _seasonEpisodePager.resetSeason(season.id);
      await _fetchSeasonEpisodes(_selectedSeasonIndex);
    }
  }

  Future<void> _fetchAllEpisodes() async {
    final generation = ++_episodesLoadGeneration;
    if (_seasons.isEmpty) {
      setStateIfMounted(() {
        _allEpisodes = const PagedMediaListState<MediaItem>();
        _episodes = const <MediaItem>[];
        _hasLoadedEpisodes = true;
      });
      return;
    }
    final serverId = _metadata.serverId;
    if (serverId == null) {
      setStateIfMounted(() {
        _allEpisodes = const PagedMediaListState<MediaItem>();
        _episodes = const <MediaItem>[];
        _hasLoadedEpisodes = true;
      });
      return;
    }
    final client = context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) {
      setStateIfMounted(() {
        _allEpisodes = const PagedMediaListState<MediaItem>();
        _episodes = const <MediaItem>[];
        _hasLoadedEpisodes = true;
      });
      return;
    }
    setStateIfMounted(() {
      _allEpisodes = const PagedMediaListState<MediaItem>().startInitialLoad();
      _episodes = const <MediaItem>[];
      _hasLoadedEpisodes = false;
    });
    try {
      final firstPage = await _fetchFlattenedEpisodePage(client, ServerId(serverId), start: 0, size: _episodesPageSize);
      if (!mounted || generation != _episodesLoadGeneration) return;
      setStateIfMounted(() {
        _allEpisodes = _allEpisodes.completeInitialLoad(firstPage.items, firstPage.totalCount);
        _episodes = _allEpisodes.items;
        _hasLoadedEpisodes = true;
      });
    } catch (e, st) {
      appLogger.w('Failed to load episodes for all seasons', error: e, stackTrace: st);
      setStateIfMounted(() {
        _allEpisodes = _allEpisodes.failInitialLoad();
        _hasLoadedEpisodes = true;
      });
    }
  }

  MediaItem? get _flattenedSeasonForDirectEpisodePaging {
    if (_metadata.isSeason) {
      if (_seasons.length == 1 && _seasons.first.isSeason) return _seasons.first;
      final full = _fullMetadata;
      if (full != null && full.isSeason) return full;
      return _metadata;
    }
    if (_showEpisodesDirectly && _seasons.length == 1 && _seasons.first.isSeason) {
      return _seasons.first;
    }
    return null;
  }

  String? _seriesIdForSeason(MediaItem season) {
    if (_metadata.isShow) return (_fullMetadata ?? _metadata).id;
    return season.grandparentId ?? season.parentId ?? _metadata.grandparentId ?? _metadata.parentId;
  }

  Future<LibraryPage<MediaItem>> _fetchFlattenedEpisodePage(
    MediaServerClient client,
    ServerId serverId, {
    required int start,
    required int size,
  }) async {
    final season = _flattenedSeasonForDirectEpisodePaging;
    if (season != null) {
      final seriesId = _seriesIdForSeason(season);
      final seasonPagingClient = client is SeasonEpisodePagingClient ? client as SeasonEpisodePagingClient : null;
      final page = seriesId != null && seasonPagingClient != null
          ? await seasonPagingClient.fetchSeasonEpisodesPage(seriesId, season.id, start: start, size: size)
          : await client.fetchChildrenPage(season.id, start: start, size: size);
      return LibraryPage<MediaItem>(
        items: _enrichDirectSeasonEpisodes(page.items, season: season, serverId: serverId),
        totalCount: page.totalCount,
        offset: page.offset,
      );
    }

    final page = await client.fetchPlayableDescendantsPage(_metadata.id, start: start, size: size);
    return LibraryPage<MediaItem>(
      items: _enrichPlayableEpisodes(page.items, serverId),
      totalCount: page.totalCount,
      offset: page.offset,
    );
  }

  List<MediaItem> _enrichDirectSeasonEpisodes(
    List<MediaItem> episodes, {
    required MediaItem season,
    required ServerId serverId,
  }) {
    if (_metadata.isShow) {
      return normalizeSeasonEpisodes(episodes, show: _fullMetadata ?? _metadata, season: season);
    }

    return _enrichPlayableEpisodes(episodes, serverId)
        .map(
          (episode) => _withFallbackLibrary(
            episode.copyWith(
              parentId: episode.parentId ?? season.id,
              parentTitle: episode.parentTitle ?? season.title,
              parentIndex: episode.parentIndex ?? season.index,
              grandparentId: episode.grandparentId ?? season.grandparentId ?? season.parentId,
              grandparentTitle: episode.grandparentTitle ?? season.grandparentTitle ?? season.parentTitle,
            ),
            season,
          ),
        )
        .toList();
  }

  List<MediaItem> _enrichPlayableEpisodes(List<MediaItem> episodes, ServerId serverId) {
    // Enrich each episode with serverId/serverName/parent fields — backends
    // don't always populate them on recursive queries, and hierarchy-aware
    // watch-state resolution needs the parentChain intact. The copy is a no-op
    // where the mapper already did.
    final fallbackParentId = _metadata.isSeason ? _metadata.id : null;
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
              parentId: e.parentId ?? fallbackParentId,
              grandparentId: e.grandparentId ?? fallbackGrandparentId,
              grandparentTitle: e.grandparentTitle ?? fallbackGrandparentTitle,
            ),
            _metadata,
          ),
        )
        .toList();
  }

  /// Load the next page of the flatten/all-episodes list (single-season show or
  /// season detail) on demand and append it.
  Future<void> _loadMoreAllEpisodes() async {
    if (widget.isOffline || !_allEpisodes.hasMore || _allEpisodes.isLoadingMore) return;
    final serverId = _metadata.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(ServerId(serverId));
    if (serverId == null || client == null) return;
    final generation = _episodesLoadGeneration;
    final offset = _allEpisodes.items.length;
    setStateIfMounted(() {
      _allEpisodes = _allEpisodes.startLoadMore();
    });
    try {
      final page = await _fetchFlattenedEpisodePage(client, ServerId(serverId), start: offset, size: _episodesPageSize);
      if (!mounted || generation != _episodesLoadGeneration) return;
      setStateIfMounted(() {
        _allEpisodes = _allEpisodes.completeLoadMore(
          expectedOffset: offset,
          pageItems: page.items,
          total: page.totalCount,
        );
        _episodes = _allEpisodes.items;
      });
    } catch (e, st) {
      appLogger.w('Failed to load more episodes', error: e, stackTrace: st);
      if (mounted && generation == _episodesLoadGeneration) {
        setStateIfMounted(() {
          _allEpisodes = _allEpisodes.failLoadMore();
        });
      }
    }
  }

  /// The inline episode list renders in two modes: the flatten/all-episodes list
  /// (single-season show or season detail) and the per-season list. These
  /// getters unify lazy-paging state across both so [_buildEpisodesList] and the
  /// scroll/focus triggers don't have to branch on the mode.
  bool get _isFlattenEpisodeList => _showEpisodesDirectly || _metadata.isSeason;
  bool get _episodeListHasMore => _isFlattenEpisodeList ? _allEpisodes.hasMore : _selectedSeasonHasMore;
  bool get _episodeListLoadingMore => _isFlattenEpisodeList ? _isLoadingAllEpisodes : _isLoadingMoreSeasonEpisodes;
  bool get _episodeListPageError => _isFlattenEpisodeList ? _allEpisodesPageError : _seasonEpisodesPageError;
  Future<void> _loadMoreEpisodeList() => _isFlattenEpisodeList ? _loadMoreAllEpisodes() : _loadMoreSeasonEpisodes();

  /// Trigger lazy paging when the tail sentinel nears the viewport. Read-only —
  /// must never scroll (it runs inside the scroll listener).
  void _maybeTriggerEpisodePaging() {
    if (!_episodeListHasMore || _episodeListLoadingMore || _episodeListPageError) return;
    final tailContext = _episodeTailKey.currentContext;
    if (tailContext == null) return;
    final render = tailContext.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final tailTop = render.localToGlobal(Offset.zero).dy;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    // Prefetch once the tail is within ~one viewport of the visible bottom.
    if (tailTop <= viewportHeight * 2) unawaited(_loadMoreEpisodeList());
  }

  void _onLastEpisodeFocusChanged() {
    if (!_lastEpisodeFocusNode.hasFocus) {
      _suppressNextLastEpisodeFocusLoad = false;
      if (_lastEpisodeFocusPinnedKey != null) {
        setStateIfMounted(() => _lastEpisodeFocusPinnedKey = null);
      }
      return;
    }

    if (_episodes.isNotEmpty) _lastEpisodeFocusPinnedKey ??= _episodes.last.globalKey;

    if (_suppressNextLastEpisodeFocusLoad) {
      _suppressNextLastEpisodeFocusLoad = false;
      return;
    }

    // dpad/keyboard equivalent of scrolling to the end of the loaded episodes.
    if (!_episodeListPageError) unawaited(_loadMoreEpisodeList());
  }

  /// Load the next unwatched episode for offline mode (offline OnDeck)
  Future<void> _loadOfflineOnDeckEpisode() async {
    final offlineWatchProvider = context.read<OfflineWatchProvider>();
    final nextEpisode = await offlineWatchProvider.getNextUnwatchedEpisode(_metadata.id);

    setStateIfMounted(() {
      _onDeckEpisode = nextEpisode;
    });

    if (nextEpisode != null) {
      appLogger.d('Offline OnDeck: S${nextEpisode.parentIndex}E${nextEpisode.index} - ${nextEpisode.title}');
    }
  }

  /// Online counterpart to [_loadOfflineOnDeckEpisode]: when the backend
  /// omitted an on-deck episode (e.g. the show was removed from Continue
  /// Watching) synthesize one from the on-deck season's already-loaded episodes
  /// so the next unwatched episode is highlighted/focused and the Play button
  /// resumes it. No-op once a backend on-deck episode exists, or when every
  /// loaded episode is watched (keep the default S1E1 for a rewatch).
  void _ensureFallbackOnDeckEpisode() {
    // Reached via unawaited fetch continuations — the screen may be gone by
    // now, and _freshAll reads providers through State.context.
    if (!mounted) return;
    if (_onDeckEpisode != null) return;
    final next = firstUnwatchedEpisode(_freshAll(_episodes));
    if (next == null) return;
    setStateIfMounted(() {
      _onDeckEpisode = next;
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

      final firstSeason = defaultPlaybackSeason(_seasons)!;

      // Get the first episode of the first season.
      MediaItem? firstEpisode;
      if (!mounted) return;
      if (widget.isOffline) {
        // In offline mode, get episodes from downloads
        final downloadProvider = context.read<DownloadProvider>();
        final allEpisodes = downloadProvider.getDownloadedEpisodesForShow(_metadata.id);
        // Filter to episodes of this season
        final episodes = allEpisodes.where((ep) => ep.parentIndex == firstSeason.index).toList()
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
        firstEpisode = episodes.isEmpty ? null : episodes.first;
      } else {
        final client = getServerBoundMediaClient(context);
        if (client == null) return;
        firstEpisode = await fetchFirstEpisodeForSeason(
          client,
          firstSeason.id,
          seriesId: _seriesIdForSeason(firstSeason),
        );
      }

      if (firstEpisode == null) {
        if (mounted) {
          showErrorSnackBar(context, t.messages.noEpisodesFound);
        }
        return;
      }

      // Play the first episode
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
        showErrorSnackBar(context, t.mediaMenu.shuffleNotAvailableOffline);
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
    // Session-fresh hero: server snapshot resolved against the watch-state
    // store (onWatchStateChanged rebuilds on relevant events).
    final metadata = _fresh(_fullMetadata ?? _metadata);
    final isShow = metadata.isShow;
    final isMobile = PlatformDetector.isMobile(context);
    final isTv = PlatformDetector.isTV();
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: .bold, fontSize: isTv ? 28 : null);

    // Show loading state while fetching full metadata
    if (_isLoadingMetadata) {
      // A bare AppBar's auto-implied back button ignores the macOS traffic
      // lights; route the leading through the shared desktop padding logic.
      final backButton = AppBarBackButton(
        style: BackButtonStyle.plain,
        onPressed: () => Navigator.pop(context, _watchStateChanged),
      );
      final loading = ListenableBuilder(
        listenable: FullscreenStateManager(),
        builder: (context, _) => Focus(
          onKeyEvent: _handleMediaDetailBackKey,
          child: Scaffold(
            appBar: AppBar(
              leading: DesktopAppBarSections.buildLeadingSection(leading: backButton, context: context),
              leadingWidth: DesktopAppBarSections.calculateLeadingWidthForSection(
                leading: backButton,
                context: context,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      final blockSystemBack = InputModeTracker.shouldBlockSystemBack(context);
      if (!blockSystemBack) {
        return loading;
      }
      return PopScope(
        canPop: false, // Prevent system back from double-popping on Android keyboard/TV
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleMediaDetailSystemBack();
        },
        child: loading,
      );
    }

    // Determine header height based on screen size
    final size = MediaQuery.sizeOf(context);
    final headerHeight = size.height * (isTv ? 1.0 : 0.6);

    if (isTv) {
      return _buildTvDetailScreen(context, metadata, _handleMediaDetailBackKey);
    }

    _scheduleInitialMobileDetailFocus(metadata);

    final blockSystemBack = InputModeTracker.shouldBlockSystemBack(context);
    final content = PrimaryScrollController(
      controller: _scrollController,
      child: IosStatusBarTapScrollToTop(
        controller: _scrollController,
        child: OverlaySheetHost(
          // blockSystemBack keeps the route from double-popping on Android
          // keyboard/TV (the key handler owns dpad back); elsewhere canPop:true
          // keeps the iOS swipe-back. The host also closes an open sheet on back.
          canPop: !blockSystemBack,
          onSystemBack: _handleMediaDetailSystemBack,
          child: Focus(
            onKeyEvent: _handleMediaDetailBackKey,
            child: Scaffold(
              body: Stack(
                children: [
                  // Background art sits behind the scroll view so it can be
                  // taller than the hero sliver without displacing content.
                  _buildHeroBackdropLayer(context, metadata, size, headerHeight),

                  CustomScrollView(
                    primary: true,
                    slivers: [
                      // Hero header content over the background art
                      SliverToBoxAdapter(
                        child: SizedBox(height: headerHeight, child: _buildHeroHeader(context, metadata)),
                      ),

                      // Main content
                      SliverToBoxAdapter(
                        child: Padding(
                          // Reduced top inset keeps the Overview/first section
                          // tight under the hero's action row (the hero already
                          // contributes its own bottom inset above this).
                          padding: .fromLTRB(
                            isTv ? TvLayoutConstants.horizontalInset : 16,
                            isTv ? 8 : 4,
                            isTv ? TvLayoutConstants.horizontalInset : 16,
                            isTv ? 8 : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              // Summary
                              if (!isTv && metadata.summary != null && metadata.summary!.isNotEmpty) ...[
                                Text(key: _overviewSectionKey, t.discover.overview, style: sectionTitleStyle),
                                const SizedBox(height: 12),
                                CollapsibleText(
                                  text: metadata.summary!,
                                  maxLines: isMobile ? 6 : 4,
                                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                                  focusNode: _overviewFocusNode,
                                  skipTraversal: false,
                                  onNavigateUp: () {
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                    );
                                    _playButtonFocusNode.requestFocus();
                                  },
                                  onNavigateDown: _focusBelowOverview,
                                  onNavigateLeft: () {},
                                  onNavigateRight: () {},
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Seasons / Episodes (for TV shows and seasons)
                              if (isShow && !_showEpisodesDirectly) ...[
                                // Season tabs + inline episodes
                                if (_isLoadingSeasons)
                                  _sectionLoading
                                else if (_seasonsLoadFailed)
                                  _sectionError(t.messages.seasonsLoadFailed, () => unawaited(_loadSeasons()))
                                else if (_seasons.isEmpty)
                                  _sectionEmpty(context, t.messages.noSeasonsFound)
                                else ...[
                                  Text(
                                    key: _seasonsSectionKey,
                                    t.libraries.groupings.episodes,
                                    style: sectionTitleStyle,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSeasonTabs(),
                                  const SizedBox(height: 16),
                                  if (_isLoadingSeasonEpisodes)
                                    _sectionLoading
                                  else if (_seasonEpisodesFirstPageError && _episodes.isEmpty)
                                    _sectionError(
                                      t.messages.episodesLoadFailed,
                                      () => unawaited(_fetchSeasonEpisodes(_selectedSeasonIndex)),
                                    )
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
                                else if (_allEpisodesPageError && _episodes.isEmpty)
                                  _sectionError(t.messages.episodesLoadFailed, () => unawaited(_fetchAllEpisodes()))
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
                                    crossAxisAlignment: .start,
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
                      SliverPadding(padding: .only(bottom: MediaQuery.paddingOf(context).bottom)),
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
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top + 58,
                        child: RasterizedGradient(
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
        ),
      ),
    );

    return content;
  }

  Widget _buildTvDetailScreen(
    BuildContext context,
    MediaItem metadata,
    KeyEventResult Function(FocusNode, KeyEvent) handleBack,
  ) {
    final size = MediaQuery.sizeOf(context);
    final detailHubs = _tvDetailHubs(metadata);
    if (widget.initialEpisodeId != null && !_initialEpisodePagingDone) {
      _maybeLoadMoreForInitialEpisode();
    }
    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
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
          child: ValueListenableBuilder<MediaItem?>(
            valueListenable: _tvDetailFocusedEpisode,
            builder: (context, _, _) =>
                _buildTvDetailForeground(context, metadata, hideSpoilers: hideSpoilers, scale: detailScale),
          ),
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
              onRefresh: (source) => unawaited(_refreshItemInPlace(source)),
              onActiveHubChanged: _handleTvDetailHubChanged,
              onActivateItem: _handleTvDetailRailItemActivated,
              trailingForHub: _tvDetailTrailingState,
              onRetryHub: _retryTvDetailHub,
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

    final blockSystemBack = InputModeTracker.shouldBlockSystemBack(context);
    final content = OverlaySheetHost(
      // blockSystemBack keeps the route from double-popping on Android keyboard/
      // TV (the key handler owns dpad back); the host also closes an open sheet.
      canPop: !blockSystemBack,
      onSystemBack: _handleMediaDetailSystemBack,
      child: Focus(
        onKeyEvent: handleBack,
        child: Scaffold(
          body: Stack(
            children: [
              TvSpotlightBackground(
                item: metadata,
                client: _getArtworkMediaClient(context),
                showInfo: false,
                localArtworkPathResolver: widget.isOffline ? (path) => _offlineArtworkLocalPath(context, path) : null,
                allowNetwork: !widget.isOffline,
              ),
              _buildTvDetailRevealGate(revealContent, handleBack),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildTvDetailForeground(
    BuildContext context,
    MediaItem metadata, {
    required bool hideSpoilers,
    required double scale,
  }) {
    final theme = Theme.of(context);
    final description = _tvDetailDescription(metadata, hideSpoilers: hideSpoilers);
    final foregroundColor = _tvDetailForegroundColor(context);
    final mutedForegroundColor = foregroundColor.withValues(alpha: 0.78);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) return const SizedBox.shrink();

        final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 264.0;
        final desiredLogoHeight = 220 * scale;
        final minLogoHeight = 60 * scale;
        final desiredLogoWidth = 790 * scale;
        final metadataLineHeight = 22 * scale;
        final genreLineHeight = 22 * scale;
        final genreGap = 6 * scale;
        final logoMetadataGap = 10 * scale;
        final summaryGap = 6 * scale;
        final summaryFontSize = availableHeight < 260 * scale ? 16.2 * scale : 18 * scale;
        final summaryLineHeight = summaryFontSize * 1.35;
        final actionHeight = _tvDetailActionSize * scale;
        final actionGap = 12 * scale;
        final hasDescription = description != null && description.isNotEmpty;
        // Genres come from the show/movie, not the focused episode, so the line
        // stays stable as episode rows gain focus.
        final genres = metadata.genres ?? const <String>[];
        final genreBlockHeight = genres.isEmpty ? 0.0 : genreGap + genreLineHeight;
        var summaryMaxLines = 0;
        var logoHeight = 0.0;

        for (var lines = hasDescription ? 3 : 0; lines >= 0; lines--) {
          final descriptionHeight = lines > 0 ? summaryGap + (summaryLineHeight * lines) : 0.0;
          final reservedHeight =
              logoMetadataGap + metadataLineHeight + genreBlockHeight + descriptionHeight + actionGap + actionHeight;
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
            genreBlockHeight +
            descriptionHeight +
            actionGap +
            actionHeight;
        final logoWidth = desiredLogoWidth < constraints.maxWidth ? desiredLogoWidth : constraints.maxWidth;

        return ClipRect(
          child: SizedBox(
            height: availableHeight,
            child: Align(
              alignment: .bottomLeft,
              child: SizedBox(
                height: contentHeight <= availableHeight ? contentHeight : availableHeight,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Semantics(
                      key: const ValueKey('tv_detail_information_semantics'),
                      identifier: 'tv_detail_information',
                      container: true,
                      label: _tvDetailInformationSemanticLabel(metadata, description: description, genres: genres),
                      child: ExcludeSemantics(
                        // This is one non-interactive announcement. The action
                        // buttons below remain separate accessible controls.
                        child: Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .start,
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
                                  fontWeight: .w800,
                                  shadowBlur: 12,
                                  color: foregroundColor,
                                  shadowColor: _tvDetailTitleShadowColor(context),
                                ),
                              ),
                              SizedBox(height: logoMetadataGap),
                            ],
                            SizedBox(
                              height: metadataLineHeight,
                              child: Align(
                                alignment: .centerLeft,
                                child: _buildTvDetailMetadataLine(context, metadata, scale),
                              ),
                            ),
                            if (genres.isNotEmpty) ...[
                              SizedBox(height: genreGap),
                              SizedBox(
                                height: genreLineHeight,
                                child: Align(
                                  alignment: .centerLeft,
                                  child: Text(
                                    genres.join('  •  '),
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                    style: TextStyle(
                                      color: mutedForegroundColor,
                                      fontSize: 16 * scale,
                                      fontWeight: .w600,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (hasDescription && summaryMaxLines > 0) ...[
                              SizedBox(height: summaryGap),
                              SizedBox(
                                height: summaryLineHeight * summaryMaxLines,
                                child: Text(
                                  description,
                                  maxLines: summaryMaxLines,
                                  overflow: .ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: mutedForegroundColor,
                                    fontSize: summaryFontSize,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

  String _tvDetailInformationSemanticLabel(
    MediaItem metadata, {
    required String? description,
    required List<String> genres,
  }) {
    final lineMetadata = _tvDetailFocusedEpisode.value ?? metadata;
    final parts = <String>[];

    void add(String? value) {
      if (value == null || value.isEmpty || parts.contains(value)) return;
      parts.add(value);
    }

    add(metadata.displayTitle);
    if (!identical(lineMetadata, metadata)) add(lineMetadata.displayTitle);

    final episodeLabel = formatSeasonEpisodeLabel(lineMetadata.parentIndex, lineMetadata.index);
    if (lineMetadata.isEpisode) add(episodeLabel);
    if (lineMetadata.isMovie) {
      add(t.discover.movie);
    } else if (lineMetadata.isShow) {
      add(t.discover.tvShow);
    }
    add(MediaRatingBadge.semanticLabelForMedia(lineMetadata, fallbackItem: metadata));
    if (lineMetadata.contentRating != null) add(formatContentRating(lineMetadata.contentRating!));
    if (lineMetadata.durationMs != null) add(formatDurationTextual(lineMetadata.durationMs!));
    if (lineMetadata.isEpisode && lineMetadata.originallyAvailableAt != null) {
      add(formatAbbreviatedDate(lineMetadata.originallyAvailableAt!));
    } else if (lineMetadata.year != null) {
      add(lineMetadata.year.toString());
    }
    for (final label in buildMediaQualityLabels(lineMetadata)) {
      add(label);
    }
    if (genres.isNotEmpty) add(genres.join(', '));
    add(description);

    return parts.join(', ');
  }

  Color _tvDetailForegroundColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  Color _tvDetailTitleShadowColor(BuildContext context) {
    final brightness = Theme.of(context).colorScheme.brightness;
    return brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.55);
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
            alignment: .centerLeft,
            imageType: ImageType.heroLogo,
            errorWidget: (context, url, error) => titleFallback(context),
          );
          if (localArtwork != null) return localArtwork;

          final client = _getArtworkMediaClient(context);
          final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
          final targetWidth = (width * dpr).round();
          final targetHeight = (height * dpr).round();
          final (memCacheWidth, memCacheHeight) = MediaImageHelper.getMemCacheDimensions(
            displayWidth: targetWidth,
            displayHeight: targetHeight,
            imageType: ImageType.heroLogo,
          );
          final logoUrl = MediaImageHelper.getOptimizedImageUrl(
            client: client,
            thumbPath: metadata.clearLogoPath,
            maxWidth: width,
            maxHeight: height,
            devicePixelRatio: dpr,
            imageType: ImageType.heroLogo,
          );

          if (logoUrl.isEmpty) return titleFallback(context);

          return blurArtwork(
            CachedNetworkImage(
              imageUrl: logoUrl,
              cacheManager: PlexImageCacheManager.instance,
              filterQuality: FilterQuality.medium,
              fit: BoxFit.contain,
              alignment: .centerLeft,
              memCacheWidth: memCacheWidth,
              memCacheHeight: memCacheHeight,
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
    final lineMetadata = _tvDetailFocusedEpisode.value ?? metadata;
    final episodeLabel = formatSeasonEpisodeLabel(lineMetadata.parentIndex, lineMetadata.index);
    final qualityLabels = buildMediaQualityLabels(lineMetadata);
    final textStyle = TextStyle(
      color: _tvDetailForegroundColor(context),
      fontSize: 18 * scale,
      fontWeight: .w700,
      letterSpacing: 0.1,
    );
    final children = <Widget>[];

    void addSeparator() {
      if (children.isNotEmpty) children.add(Text('  •  ', maxLines: 1, style: textStyle));
    }

    void addTextPart(String text) {
      addSeparator();
      children.add(Text(text, maxLines: 1, style: textStyle));
    }

    void addWidgetPart(Widget widget) {
      addSeparator();
      children.add(widget);
    }

    if (lineMetadata.isEpisode && episodeLabel != null) addTextPart(episodeLabel);
    if (lineMetadata.isMovie) {
      addTextPart(t.discover.movie);
    } else if (lineMetadata.isShow) {
      addTextPart(t.discover.tvShow);
    }
    final ratingBadge = MediaRatingBadge.inlineForMedia(
      item: lineMetadata,
      fallbackItem: metadata,
      foregroundColor: textStyle.color,
      iconSize: textStyle.fontSize,
      spacing: 4 * scale,
      textStyle: textStyle,
    );
    if (ratingBadge != null) {
      addWidgetPart(ratingBadge);
    }
    if (lineMetadata.contentRating != null) addTextPart(formatContentRating(lineMetadata.contentRating!));
    if (lineMetadata.durationMs != null) addTextPart(formatDurationTextual(lineMetadata.durationMs!));
    if (lineMetadata.isEpisode && lineMetadata.originallyAvailableAt != null) {
      addTextPart(formatAbbreviatedDate(lineMetadata.originallyAvailableAt!));
    } else if (lineMetadata.year != null) {
      addTextPart(lineMetadata.year.toString());
    }
    for (final label in qualityLabels) {
      addTextPart(label);
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  String? _tvDetailDescription(MediaItem metadata, {required bool hideSpoilers}) {
    final focusedEpisode = _tvDetailFocusedEpisode.value;
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
    final svc = SettingsService.instance;
    return TvBrowseRailLayout.estimateHeight(
      size: size,
      hubs: hubs,
      density: svc.read(SettingsService.libraryDensity),
      episodePosterMode: svc.read(SettingsService.episodePosterMode),
      episodePosterModeForHub: _tvDetailEpisodePosterModeForHub,
      widePosterScaleForHub: _tvDetailWidePosterScaleForHub,
      fullCardLayout: svc.read(SettingsService.tvFullCardLayout),
      tallPosterScale: _tvDetailTallPosterScale,
    );
  }

  double _estimateTvDetailRailHeight(Size size, List<MediaHub> hubs) {
    final hubRailHeight = _estimateTvBrowseRailHeight(size, hubs);
    if (hubRailHeight > 0) return hubRailHeight;
    return _estimateTvDetailEmptyRailReserveHeight(size);
  }

  double _estimateTvDetailEmptyRailReserveHeight(Size size) {
    final svc = SettingsService.instance;
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
      fullCardLayout: svc.read(SettingsService.tvFullCardLayout),
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
    return SettingsService.instance.read(SettingsService.episodePosterMode);
  }

  double _tvDetailWidePosterScaleForHub(MediaHub hub) {
    return _isTvDetailEpisodeHub(hub) || hub.id == _tvDetailExtrasHubId ? _tvDetailEpisodeThumbnailScale : 1.0;
  }

  List<MediaHub> _tvDetailHubs(MediaItem metadata) {
    final hubs = <MediaHub>[];
    if (metadata.isShow && !_showEpisodesDirectly && _seasonsLoadFailed) {
      hubs.add(
        MediaHub(
          id: _tvDetailSeasonsErrorHubId,
          title: t.libraries.groupings.seasons,
          type: 'episode',
          items: const [],
          size: 0,
        ),
      );
    } else if (metadata.isShow && !_showEpisodesDirectly && _seasons.isNotEmpty) {
      // Emit a hub for every season so TV users can choose a season before its
      // episodes are fetched. Extra pages load in-place when focus reaches the
      // last loaded episode; the trailing slot is reserved for loading/retry.
      for (var i = 0; i < _seasons.length; i++) {
        final season = _seasons[i];
        final state = _seasonEpisodePager.stateFor(season.id);
        final episodes = i == _selectedSeasonIndex ? _episodes : state.items;
        final total = state.totalCount > episodes.length ? state.totalCount : (season.leafCount ?? episodes.length);
        hubs.add(
          MediaHub(
            id: '$_tvDetailSeasonHubIdPrefix$i',
            title: season.title?.isNotEmpty == true ? season.title! : (season.displaySubtitle ?? season.displayTitle),
            type: 'episode',
            items: episodes,
            size: total,
          ),
        );
      }
    } else if (_episodes.isNotEmpty) {
      final total = _allEpisodesTotal > _episodes.length ? _allEpisodesTotal : _episodes.length;
      hubs.add(
        MediaHub(
          id: 'detail_episodes',
          title: t.libraries.groupings.episodes,
          type: 'episode',
          items: _episodes,
          size: total,
        ),
      );
    } else if ((metadata.isShow && _showEpisodesDirectly) || metadata.isSeason) {
      if (_allEpisodesPageError || _isLoadingEpisodes) {
        hubs.add(
          MediaHub(
            id: 'detail_episodes',
            title: t.libraries.groupings.episodes,
            type: 'episode',
            items: const [],
            size: 0,
          ),
        );
      }
    }
    final actors = _tvDetailActorItems(metadata);
    if (actors.isNotEmpty) {
      hubs.add(
        MediaHub(id: _tvDetailActorsHubId, title: t.discover.cast, type: 'person', items: actors, size: actors.length),
      );
    }
    if (_extras != null && _extras!.isNotEmpty) {
      hubs.add(
        MediaHub(
          id: _tvDetailExtrasHubId,
          title: t.discover.extras,
          type: 'clip',
          items: _extras!,
          size: _extras!.length,
        ),
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
    if (widget.initialEpisodeId != null) return widget.initialEpisodeId;
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

  Future<bool> _handleTvDetailRailItemActivated(MediaHub hub, MediaItem item) async {
    if (_isTvDetailEpisodeHub(hub) && item.isEpisode) {
      await navigateToVideoPlayerWithRefresh(
        context,
        metadata: item,
        isOffline: widget.isOffline,
        onRefresh: () => unawaited(_refreshItemInPlace(item)),
      );
      return true;
    }
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
    _tvDetailFocusedEpisode.value = null;
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
    if (_tvDetailFocusedEpisode.value?.id == item.id) return;
    _tvDetailFocusedEpisode.value = item;
    if (hub.id == 'detail_episodes') {
      if (!_allEpisodesPageError && _episodes.isNotEmpty && item.id == _episodes.last.id) {
        unawaited(_loadMoreAllEpisodes());
      }
      return;
    }
    if (hub.id == '$_tvDetailSeasonHubIdPrefix$_selectedSeasonIndex' &&
        !_seasonEpisodesPageError &&
        _episodes.isNotEmpty &&
        item.id == _episodes.last.id) {
      unawaited(_loadMoreSeasonEpisodes());
    }
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
    final state = _seasonEpisodePager.stateFor(season.id);
    final hasLoadedState =
        _seasonEpisodePager.hasState(season.id) && !state.isInitialLoading && !state.initialLoadFailed;
    if (_selectedSeasonIndex == seasonIndex &&
        (hasLoadedState || _episodes.isNotEmpty || _isLoadingSeasonEpisodes || _seasonEpisodesFirstPageError)) {
      return;
    }

    if (hasLoadedState) {
      _seasonEpisodePager.completeFirstPage(season.id, state.items, state.totalCount);
      setStateIfMounted(() {
        _selectedSeasonIndex = seasonIndex;
        _episodes = List.of(_seasonEpisodePager.stateFor(season.id).items);
      });
      unawaited(_prefetchAdjacentSeasonEpisodePages(seasonIndex));
      _pruneDistantSeasonPages(seasonIndex);
      return;
    }

    setStateIfMounted(() {
      _selectedSeasonIndex = seasonIndex;
      _episodes = const <MediaItem>[];
      _seasonEpisodePager.markFirstPageLoading(season.id);
    });
    unawaited(_fetchSeasonEpisodes(seasonIndex));
    unawaited(_prefetchAdjacentSeasonEpisodePages(seasonIndex));
    _pruneDistantSeasonPages(seasonIndex);
  }

  /// Low-end TV only: keep episode pages for the selected season ±1 (the
  /// prefetch window) and drop the rest. Visited 200-item pages otherwise
  /// accumulate for the screen's lifetime — irrelevant for a 3-season show,
  /// tens of MB of retained heap for a 30-season one.
  void _pruneDistantSeasonPages(int seasonIndex) {
    if (!DevicePerformance.isLowEndHardware || !PlatformDetector.isTV()) return;
    final keep = <String>{
      for (var i = seasonIndex - 1; i <= seasonIndex + 1; i++)
        if (i >= 0 && i < _seasons.length) _seasons[i].id,
    };
    _seasonEpisodePager.retainOnly(keep);
  }

  /// What the rail should show in a hub's trailing slot: a spinner while the
  /// selected season page loads or a retry tile if it failed. Episode hubs do
  /// not use the legacy "View All" slot; they page in-place on focus.
  TvRailTrailing _tvDetailTrailingState(MediaHub hub) {
    if (hub.id == _tvDetailSeasonsErrorHubId) return TvRailTrailing.error;
    final isFlatten = hub.id == 'detail_episodes';
    final isSeason = hub.id.startsWith(_tvDetailSeasonHubIdPrefix);
    if (!isFlatten && !isSeason) return hub.more ? TvRailTrailing.viewAll : TvRailTrailing.none;
    if (isFlatten) {
      if (_allEpisodesPageError) return TvRailTrailing.error;
      if (_isLoadingEpisodes || _isLoadingAllEpisodes) return TvRailTrailing.loading;
      return TvRailTrailing.none;
    }
    final isSelectedSeason = hub.id == '$_tvDetailSeasonHubIdPrefix$_selectedSeasonIndex';
    if (isSelectedSeason) {
      if (_seasonEpisodesFirstPageError || _seasonEpisodesPageError) return TvRailTrailing.error;
      if (_isLoadingSeasonEpisodes || _isLoadingMoreSeasonEpisodes) return TvRailTrailing.loading;
    }
    return TvRailTrailing.none;
  }

  void _retryTvDetailHub(MediaHub hub) {
    if (hub.id == _tvDetailSeasonsErrorHubId) {
      unawaited(_loadSeasons());
      return;
    }
    if (hub.id == 'detail_episodes') {
      unawaited(_episodes.isEmpty ? _fetchAllEpisodes() : _loadMoreAllEpisodes());
      return;
    }
    if (hub.id.startsWith(_tvDetailSeasonHubIdPrefix)) {
      final seasonIndex = int.tryParse(hub.id.substring(_tvDetailSeasonHubIdPrefix.length));
      if (seasonIndex != null && seasonIndex >= 0 && seasonIndex < _seasons.length) {
        final state = _seasonEpisodePager.stateFor(_seasons[seasonIndex].id);
        unawaited(state.items.isNotEmpty ? _loadMoreSeasonEpisodes() : _fetchSeasonEpisodes(seasonIndex));
      }
    }
  }

  IconData _getTvDetailHubIcon(MediaHub hub, int index) {
    if (hub.id == _tvDetailSeasonsErrorHubId) return Symbols.error_outline_rounded;
    if (hub.id.startsWith(_tvDetailSeasonHubIdPrefix)) return Symbols.tv_rounded;
    if (hub.id == 'detail_episodes') return Symbols.tv_rounded;
    if (hub.id == _tvDetailExtrasHubId) return Symbols.theaters_rounded;
    if (hub.id == _tvDetailActorsHubId) return Symbols.group_rounded;
    return _getRelatedHubIcon(hub);
  }

  /// Height of the backdrop paint box, which is deliberately taller than the
  /// hero sliver on wide windows.
  ///
  /// Cover-fitting a 16:9 backdrop into a hero that is much wider than 16:9
  /// scales it to the window width and then throws away the top and bottom of
  /// the frame. Painting into the artwork's own natural height instead keeps
  /// the whole frame, and the extra height is spent behind the content that
  /// follows the hero rather than pushing that content down — the sliver
  /// layout below is unchanged.
  ///
  /// Never shorter than the hero: portrait windows are already taller than the
  /// artwork and keep cropping the sides as before. Never taller than
  /// [_maxHeroArtViewportFraction] either, because the scrim ramps across this
  /// box, so a box that overshoots the window would still be translucent where
  /// the overview text begins.
  double _heroArtHeight(Size size, double headerHeight) {
    const backdropAspect = 16 / 9;
    final maxArtHeight = math.max(headerHeight, size.height * _maxHeroArtViewportFraction);
    return (size.width / backdropAspect).clamp(headerHeight, maxArtHeight).toDouble();
  }

  /// Backdrop + scrim, painted behind the scroll view and translated with it so
  /// it keeps the hero's fixed, no-parallax relationship to the content.
  Widget _buildHeroBackdropLayer(BuildContext context, MediaItem metadata, Size size, double headerHeight) {
    final artHeight = _heroArtHeight(size, headerHeight);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: artHeight,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
            return Transform.translate(offset: Offset(0, -offset), child: child);
          },
          child: RepaintBoundary(
            child: Stack(
              fit: .expand,
              children: [
                Builder(
                  builder: (context) {
                    final containerAspect = size.width / artHeight;
                    final heroArtPaths = metadata.heroArtCandidates(containerAspectRatio: containerAspect);
                    if (heroArtPaths.isEmpty) return const PlaceholderContainer();

                    return blurArtwork(
                      CyclingMediaBackdrop(
                        mediaKey: metadata.globalKey,
                        imagePaths: metadata.heroBackdropPaths,
                        fallbackImagePaths: heroArtPaths,
                        client: _getArtworkMediaClient(context),
                        localArtworkPathResolver: widget.isOffline
                            ? (path) => _offlineArtworkLocalPath(context, path)
                            : null,
                        allowNetwork: !widget.isOffline,
                        width: size.width,
                        height: artHeight,
                        fallbackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),

                // Gradient overlay
                Builder(
                  builder: (context) {
                    final bgColor = Theme.of(context).scaffoldBackgroundColor;
                    // Full-height eased scrim. The light global dim (alpha 0.2 at
                    // the very top) lowers the contrast the ramp has to bridge on
                    // bright artwork — without it, any fade to solid compresses
                    // into a visible band above the content stack. The body samples
                    // easeInOut (continuous curvature — hand-picked stops kink at
                    // every boundary); the tail instead decays the remaining
                    // transparency geometrically (~1/8 per sample) because an eased
                    // zero-slope landing leaves a faint artwork glow that pure-black
                    // (OLED) backgrounds expose. Solid bg from 94% so nothing ghosts
                    // where the artwork ends, on any theme.
                    //
                    // The ramp spans the art box, not the hero, so on wide windows
                    // it keeps fading past the hero edge and the bottom of the frame
                    // dissolves behind the overview instead of being cut off.
                    const scrimAlphas = [0.20, 0.234, 0.325, 0.453, 0.60, 0.747, 0.875, 0.985, 0.998, 1.0];
                    const scrimXs = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 0.9375, 1.0];
                    const solidStop = 0.94;
                    return RasterizedGradient(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          for (final a in scrimAlphas) bgColor.withValues(alpha: a),
                          bgColor,
                        ],
                        stops: [for (final x in scrimXs) solidStop * x, 1.0],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, MediaItem metadata) {
    // bottom: false — the hero is the top sliver, so the bottom safe-area
    // inset would otherwise push the action row far up off the hero edge.
    // Left/right stay enabled for the landscape notch.
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildHeroHeaderContent(context, metadata),
      ),
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
          for (final label in buildMediaQualityLabels(metadata)) _buildMetadataChip(label),
          ..._buildRatingChips(metadata),
        ];
        // Genres render on their own line below the metadata chips.
        final genreChips = [for (final genre in metadata.genres ?? const <String>[]) _buildMetadataChip(genre)];

        final showActions = availableHeight >= actionHeight;
        final remainingAfterActions = availableHeight - (showActions ? actionHeight : 0);
        final showChips = chips.isNotEmpty && remainingAfterActions >= 88;
        final chipHeight = showChips ? (remainingAfterActions >= 170 ? 68.0 : 32.0) : 0.0;
        final chipActionGap = showChips && showActions ? (availableHeight < 180 ? 8.0 : 16.0) : 0.0;
        // Reserve a dedicated genre row, but only when the logo still keeps room
        // afterwards so the title isn't crowded out on short heroes.
        const genreRowHeight = 32.0;
        const genreGap = 8.0;
        final showGenres =
            showChips &&
            genreChips.isNotEmpty &&
            remainingAfterActions - chipHeight - chipActionGap - (genreRowHeight + genreGap) >= 52;
        final genreBlockHeight = showGenres ? genreRowHeight + genreGap : 0.0;
        final remainingForLogo = remainingAfterActions - chipHeight - chipActionGap - genreBlockHeight;
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
            genreBlockHeight +
            chipActionGap +
            (showActions ? actionHeight : 0.0);

        return ClipRect(
          child: SizedBox(
            height: availableHeight,
            child: Align(
              alignment: .bottomLeft,
              child: SizedBox(
                height: contentHeight.clamp(0.0, availableHeight).toDouble(),
                child: Align(
                  alignment: .bottomLeft,
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
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
                            fontWeight: .bold,
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
                              alignment: .bottomLeft,
                              heightFactor: 1,
                              child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                            ),
                          ),
                        ),
                      if (showGenres) ...[
                        const SizedBox(height: genreGap),
                        ClipRect(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: genreRowHeight),
                            child: Align(
                              alignment: .bottomLeft,
                              heightFactor: 1,
                              child: Wrap(spacing: 8, runSpacing: 8, children: genreChips),
                            ),
                          ),
                        ),
                      ],
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

  /// Get the primary trailer from the extras list.
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

    try {
      return _extras!.firstWhere(_isTrailerExtra);
    } catch (_) {
      // No trailer found, return null (button won't appear)
      return null;
    }
  }

  bool _isTrailerExtra(MediaItem extra) {
    if (extra case PlexMediaItem(:final subtype?)) {
      return subtype.toLowerCase() == 'trailer';
    }
    final raw = extra.raw;
    final extraType = raw?['ExtraType'] as String?;
    final type = raw?['Type'] as String?;
    return extraType?.toLowerCase() == 'trailer' || type?.toLowerCase() == 'trailer';
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
    final roles = metadata.roles!;
    return CastMemberStrip(
      key: _castStripKey,
      members: [for (final actor in roles) (name: actor.tag, secondary: actor.role, imagePath: actor.thumbPath)],
      imageClient: getServerBoundMediaClient(context),
      onNavigateUp: _focusSectionDirectlyAboveCast,
      onNavigateDown: _focusSectionBelowCast,
      onMemberTap: (index) => _navigateToActorMedia(roles[index]),
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
    final containerHeight = posterHeight + 52;

    return Focus(
      focusNode: _extrasFocusNode,
      onKeyEvent: _handleExtrasKeyEvent,
      child: ListenableBuilder(
        listenable: Listenable.merge([_extrasFocusNode, _focusedExtraIndexNotifier]),
        builder: (context, _) {
          final hasFocus = _extrasFocusNode.hasFocus;

          return SizedBox(
            height: containerHeight,
            child: HorizontalScrollWithArrows(
              controller: _extrasScrollController,
              builder: (scrollController) => ListView.builder(
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
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
                      delegateFocusBorder: true,
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
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontWeight: .w600, color: theme.colorScheme.onSurfaceVariant),
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
        final seasonNum = defaultPlaybackSeason(_seasons)?.index ?? 1;
        return t.discover.playEpisode(season: seasonNum.toString(), episode: '1');
      }
    }

    // For movies or episodes - NO TEXT, just icon
    return '';
  }

  IconData _getPlayButtonIcon(MediaItem metadata) {
    // For TV shows
    if (metadata.isShow) {
      if (_onDeckEpisode != null) {
        final episode = _fresh(_onDeckEpisode!);
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
