import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/hub_vertical_navigation.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_hub.dart';
import '../../../media/media_item.dart';
import '../../../media/media_server_client.dart';
import '../../../mixins/deletion_aware.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/watch_state_aware.dart';
import '../../../services/settings_service.dart';
import '../../../utils/deletion_notifier.dart';
import '../../../utils/global_key_utils.dart';
import '../../../utils/platform_detector.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/watch_state_notifier.dart';
import '../../../widgets/hub_section.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/tv_browse_rail.dart';
import '../../../widgets/tv_spotlight_scaffold.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Recommended tab for library screen
/// Shows library-specific hubs and recommendations, including dedicated Continue Watching
class LibraryRecommendedTab extends BaseLibraryTab<MediaHub> {
  final VoidCallback? onNavigateToChrome;

  const LibraryRecommendedTab({
    super.key,
    required super.library,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
    this.onNavigateToChrome,
  });

  @override
  State<LibraryRecommendedTab> createState() => _LibraryRecommendedTabState();
}

class _LibraryRecommendedTabState extends BaseLibraryTabState<MediaHub, LibraryRecommendedTab>
    with ItemUpdatable, WatchStateAware, DeletionAware {
  /// GlobalKeys for each hub section to enable vertical navigation
  final List<GlobalKey<HubSectionState>> _hubKeys = [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();
  final TvSpotlightController _spotlight = TvSpotlightController();

  void _setSpotlightItem(MediaItem item) => _spotlight.select(item);

  @override
  void dispose() {
    _spotlight.dispose();
    super.dispose();
  }

  @override
  String? get watchStateServerId => widget.library.serverId;

  @override
  String? get deletionServerId => widget.library.serverId;

  // Deletion filtering needs the same id sets as watch state: each visible
  // item plus its parents, so deleting a season/show also matches the
  // episodes it contains here.
  @override
  Set<String>? get deletionIds => watchedIds;

  @override
  Set<String>? get deletionGlobalKeys => watchedGlobalKeys;

  @override
  Set<String>? get watchedIds {
    final keys = <String>{};
    for (final hub in items) {
      for (final item in hub.items) {
        keys.add(item.id);
        if (item.parentId != null) keys.add(item.parentId!);
        if (item.grandparentId != null) keys.add(item.grandparentId!);
      }
    }
    return keys;
  }

  @override
  Set<String>? get watchedGlobalKeys {
    final keys = <String>{};
    for (final hub in items) {
      for (final item in hub.items) {
        final serverId = item.serverId ?? widget.library.serverId;
        if (serverId == null) return null;
        keys.add(buildGlobalKey(ServerId(serverId), item.id));
        if (item.parentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.parentId!));
        if (item.grandparentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.grandparentId!));
      }
    }
    return keys;
  }

  @override
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    // Update the item in any hub that contains it. MediaHub items are
    // immutable lists; rebuild the affected hub in-place.
    for (var i = 0; i < items.length; i++) {
      final hub = items[i];
      final itemIndex = hub.items.indexWhere((item) => item.globalKey == sourceGlobalKey);
      if (itemIndex != -1) {
        final newItems = List<MediaItem>.from(hub.items);
        newItems[itemIndex] = updatedItem;
        items[i] = hub.copyWith(items: newItems);
      }
    }
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    if (event.changeType == WatchStateChangeType.progressUpdate) return;

    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      _removeContinueWatchingItem(event.itemId);
      unawaited(loadItems());
      return;
    }

    final affectedIds = {event.itemId, ...event.parentChain};
    final refreshItems = <String, MediaItem>{};
    for (final hub in items) {
      for (final item in hub.items) {
        if (affectedIds.contains(item.id)) {
          refreshItems[item.globalKey] = item;
        }
      }
    }
    for (final item in refreshItems.values) {
      unawaited(updateItem(item));
    }
  }

  void _removeContinueWatchingItem(String itemId) {
    _removeItemsFromHubs(hubMatches: _isContinueWatchingHub, itemMatches: (item) => item.id == itemId);
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // This tab is server-backed: a download-only deletion leaves the server
    // item in place, so it must not evict anything here.
    if (event.isDownloadOnly) return;

    // Drop the item and any descendants (season/show deletions take their
    // episodes with them) from every hub, then resync with the server for
    // parent leaf counts and replacement on-deck items — same
    // remove-in-place-then-reload shape as the removedFromContinueWatching
    // path above.
    _removeItemsFromHubs(
      hubMatches: (_) => true,
      itemMatches: (item) =>
          item.id == event.itemId || item.parentId == event.itemId || item.grandparentId == event.itemId,
    );
    unawaited(loadItems());
  }

  void _removeItemsFromHubs({
    required bool Function(MediaHub) hubMatches,
    required bool Function(MediaItem) itemMatches,
  }) {
    setState(() {
      for (var i = 0; i < items.length; i++) {
        final hub = items[i];
        if (!hubMatches(hub)) continue;
        final newItems = hub.items.where((item) => !itemMatches(item)).toList();
        if (newItems.length != hub.items.length) {
          items[i] = hub.copyWith(items: newItems, size: newItems.length);
        }
      }
    });
  }

  @override
  IconData get emptyIcon => Symbols.recommend_rounded;

  @override
  String get emptyMessage => t.libraries.noRecommendations;

  @override
  String get errorContext => t.libraries.tabs.recommended;

  /// Detects Continue Watching hubs by hub identifier.
  /// Section-specific CW hubs use identifiers like "movie.inprogress.1".
  static bool _isContinueWatchingHub(MediaHub hub) => hub.isContinueWatchingHub;

  static bool _usesContinueWatchingAction(MediaHub hub) => hub.usesContinueWatchingAction;

  @override
  Future<List<MediaHub>> loadData() async {
    // Clear hub keys before loading new hubs to prevent stale references
    _hubKeys.clear();

    // Backend-aware fetch: Plex hits /hubs/sections, Jellyfin synthesises
    // Continue Watching + Next Up + Recently Added.
    final client = context.tryGetMediaClientForServer(serverIdOrNull(widget.library.serverId));
    final hubs = client == null
        ? <MediaHub>[]
        : List.of(
            await client.fetchLibraryHubs(
              widget.library.id,
              libraryName: widget.library.title,
              limit: defaultHubPreviewLimit,
              libraryKind: widget.library.kind,
            ),
          );

    // Move Continue Watching hub to the front if present
    final cwIndex = hubs.indexWhere(_isContinueWatchingHub);
    if (cwIndex > 0) {
      final cwHub = hubs.removeAt(cwIndex);
      hubs.insert(0, cwHub);
    }

    return hubs;
  }

  /// Ensure we have enough GlobalKeys for all hubs
  void _ensureHubKeys(int count) {
    while (_hubKeys.length < count) {
      _hubKeys.add(GlobalKey<HubSectionState>());
    }
  }

  /// Handle vertical navigation between hubs
  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    return navigateVerticalHubRows(
      hubCount: items.length,
      hubIndex: hubIndex,
      isUp: isUp,
      propagateTopBoundary: true,
      requestFocus: (targetIndex) {
        _hubKeys[targetIndex].currentState?.requestFocusFromMemory();
      },
    );
  }

  /// Focus the first item in the first hub (for tab activation)
  @override
  void focusFirstItem() {
    if (PlatformDetector.isTV()) {
      final rail = _tvBrowseRailKey.currentState;
      if (rail != null) {
        rail.requestFocus();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final rail = _tvBrowseRailKey.currentState;
        if (rail != null) {
          rail.requestFocus();
        } else {
          focusEmptyState();
        }
      });
      return;
    }
    if (_hubKeys.isNotEmpty && items.isNotEmpty) {
      _hubKeys.first.currentState?.requestFocusAt(0);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  // Extra top padding for focus decoration (scale + border extends beyond item bounds)
  static const double _focusDecorationPadding = 8.0;

  @override
  Widget buildContent(List<MediaHub> items) {
    _ensureHubKeys(items.length);

    if (PlatformDetector.isTV()) {
      return SettingsBuilder(
        prefs: const [SettingsService.hideSpoilers, SettingsService.libraryDensity, SettingsService.episodePosterMode],
        builder: (context) => _buildTvContent(items),
      );
    }

    return CustomScrollView(
      // Allow focus decoration to render outside scroll bounds
      clipBehavior: Clip.none,
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, _focusDecorationPadding, 0, 8),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final hub = items[index];
              final isContinueWatching = _isContinueWatchingHub(hub);
              final usesContinueWatchingAction = _usesContinueWatchingAction(hub);

              return HubSection(
                key: index < _hubKeys.length ? _hubKeys[index] : null,
                hub: hub,
                icon: _getHubIcon(hub),
                isInContinueWatching: isContinueWatching,
                usesContinueWatchingAction: usesContinueWatchingAction,
                onRefresh: updateItem,
                onRemoveFromContinueWatching: isContinueWatching ? _refreshContinueWatching : null,
                onVerticalNavigation: (isUp) => _handleVerticalNavigation(index, isUp),
                onBack: widget.onBack,
                onNavigateUp: index == 0 ? widget.onBack : null,
                onNavigateToSidebar: _navigateToSidebar,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTvContent(List<MediaHub> items) {
    final tvHubs = items.where((hub) => hub.items.isNotEmpty).toList();
    return TvSpotlightScaffold(
      hubs: tvHubs,
      spotlightListenable: _spotlight,
      resolveSpotlight: () => _spotlight.resolve(tvHubs),
      resolveClient: (spotlight) =>
          context.tryGetMediaClientForServer(serverIdOrNull(spotlight?.serverId ?? widget.library.serverId)),
      foreground: tvHubs.isEmpty
          ? const SizedBox.shrink()
          : Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TvBrowseRail(
                key: _tvBrowseRailKey,
                hubs: tvHubs,
                iconForHub: (hub, _) => _getHubIcon(hub),
                onFocusedItemChanged: _setSpotlightItem,
                onRefresh: updateItem,
                onRemoveFromContinueWatching: _refreshContinueWatching,
                isContinueWatchingHub: _isContinueWatchingHub,
                usesContinueWatchingAction: _usesContinueWatchingAction,
                onNavigateUp: widget.onNavigateToChrome ?? widget.onBack,
                onNavigateToSidebar: _navigateToSidebar,
                onBack: widget.onBack,
                tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
              ),
            ),
    );
  }

  /// Refresh the Continue Watching section
  void _refreshContinueWatching() {
    // Reload all data to refresh the continue watching section
    loadItems();
  }

  IconData _getHubIcon(MediaHub hub) {
    final title = hub.title.toLowerCase();
    if (title.contains('continue watching') || title.contains('on deck')) {
      return Symbols.play_circle_rounded;
    } else if (title.contains('recently') || title.contains('new')) {
      return Symbols.fiber_new_rounded;
    } else if (title.contains('popular') || title.contains('trending')) {
      return Symbols.trending_up_rounded;
    } else if (title.contains('top') || title.contains('rated')) {
      return Symbols.star_rounded;
    } else if (title.contains('recommended')) {
      return Symbols.thumb_up_rounded;
    } else if (title.contains('unwatched')) {
      return Symbols.visibility_off_rounded;
    } else if (title.contains('genre')) {
      return Symbols.category_rounded;
    }
    return Symbols.movie_rounded;
  }
}
