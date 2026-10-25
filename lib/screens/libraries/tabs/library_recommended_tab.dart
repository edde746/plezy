import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/hub_vertical_navigation.dart';
import '../../../focus/locked_hub_controller.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_hub.dart';
import '../../../media/media_item.dart';
import '../../../media/media_server_client.dart';
import '../../../mixins/deletion_aware.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/watch_state_aware.dart';
import '../../../services/settings_service.dart';
import '../../../utils/deletion_notifier.dart';
import '../../../utils/home_section_builder.dart'
    show libraryContinueWatchingHeroOverrideKey, withResolvedHeroOverride, withoutWatchedItems;
import '../../../utils/hub_icons.dart';
import '../../../utils/media_event_keys.dart';
import '../../../utils/media_navigation_helper.dart';
import '../../../utils/platform_detector.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/watch_state_notifier.dart';
import '../../../widgets/hero_hub_section.dart';
import '../../../widgets/hub_section.dart';
import '../../../widgets/nested_tab_scrollbar.dart';
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
    with ItemUpdatable, WatchStateAware, DeletionAware, DeletionMirrorsWatchState {
  /// Navigation belongs to the rendered hub snapshot, never an in-flight load.
  final Map<String, GlobalKey<HubSectionState>> _hubKeysByIdentity = {};

  /// Hero rows' keys, identity-keyed like [_hubKeysByIdentity] and filled by
  /// [_keysForHubs] (index-aligned, null for non-hero rows). HeroHubSection
  /// has its own state type, so a hero row needs its own GlobalKey or
  /// index-based focus requests (d-pad DOWN from the tab bar, focusFirstItem)
  /// silently skip it.
  final Map<String, GlobalKey<HeroHubSectionState>> _heroHubKeysByIdentity = {};
  List<GlobalKey<HeroHubSectionState>?> _heroKeys = const [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();
  final TvSpotlightController _spotlight = TvSpotlightController();
  HubFocusMemory _hubFocusMemory = HubFocusMemory();

  void _setSpotlightItem(MediaHub hub, MediaItem item) => _spotlight.select(item, hub: hub);

  @override
  void didUpdateWidget(LibraryRecommendedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.library.globalKey != widget.library.globalKey) {
      _hubKeysByIdentity.clear();
      _heroHubKeysByIdentity.clear();
      _hubFocusMemory = HubFocusMemory();
    }
  }

  @override
  void dispose() {
    _spotlight.dispose();
    super.dispose();
  }

  @override
  String? get watchStateServerId => widget.library.serverId;

  /// Every item on screen, across all hubs.
  Iterable<MediaItem> get _visibleItems => items.expand((hub) => hub.items);

  @override
  bool get hasFocusableContent => _visibleItems.isNotEmpty;

  // Deletion mirrors these via DeletionMirrorsWatchState: each visible item
  // plus its parents, so deleting a season/show also matches the episodes it
  // contains here.
  @override
  Set<String>? get watchedIds => hierarchicalEventIds(_visibleItems);

  @override
  Set<String>? get watchedGlobalKeys =>
      hierarchicalEventGlobalKeys(_visibleItems, fallbackServerId: widget.library.serverId);

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

    if (event.changeType == WatchStateChangeType.watched &&
        SettingsService.instance.read(SettingsService.hideWatchedInHubs)) {
      // Hide watched is on (#2159): drop the title (and a season/show's
      // episodes) from its rows now instead of refreshing it in place.
      _removeItemsFromHubs(
        hubMatches: (hub) => !_isContinueWatchingHub(hub),
        itemMatches: (item) =>
            item.id == event.itemId || item.parentId == event.itemId || item.grandparentId == event.itemId,
      );
      setState(() => items.removeWhere((hub) => !_isContinueWatchingHub(hub) && hub.items.isEmpty));
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

    // Eviction is immediate for both origins. Push reconciliation belongs to
    // the coarse library event and its visibility/playback-aware pacer.
    _removeItemsFromHubs(
      hubMatches: (_) => true,
      itemMatches: (item) =>
          item.id == event.itemId || item.parentId == event.itemId || item.grandparentId == event.itemId,
    );
    if (event.origin == DeletionOrigin.local) {
      unawaited(loadItems());
    }
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
      items.removeWhere((hub) => hub.items.isEmpty);
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
  Future<void> loadItems() => runLoadTransaction(_loadRecommendedHubs);

  Future<List<MediaHub>> _loadRecommendedHubs() async {
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
    hubs.removeWhere((hub) => hub.items.isEmpty);

    // This library's own Continue Watching isn't a PlexManagedHub — Plex
    // has no promote/demote concept for it — so unlike every other row
    // here it can't be hidden through updateManagedHubVisibility; it's a
    // Plezy-local toggle instead (Home layout settings → the library's own
    // "Continue Watching" tile), read directly here.
    final libraryCwHidden = SettingsService.instance
        .read(SettingsService.libraryContinueWatchingHidden)
        .contains(widget.library.globalKey);
    if (libraryCwHidden) hubs.removeWhere(_isContinueWatchingHub);

    // Move Continue Watching hub to the front if present
    final cwIndex = hubs.indexWhere(_isContinueWatchingHub);
    if (cwIndex > 0) {
      final cwHub = hubs.removeAt(cwIndex);
      hubs.insert(0, cwHub);
    }

    // Same Hero overrides the Home screen applies to this exact
    // hub (buildConfiguredHomeSections in home_section_builder.dart) — a
    // row's Hero setting is meant to follow it wherever it's
    // shown, not just on Home. Continue Watching bypasses this generic
    // identifier-matched lookup, same reason Home's own Continue Watching
    // does (see continueWatchingHeroOverrideKey's doc comment) — it's keyed
    // separately instead, per library.
    final overrides = SettingsService.instance.read(SettingsService.managedHubHeroOverrides);
    final cwOverride = overrides[libraryContinueWatchingHeroOverrideKey(widget.library.globalKey)];
    final resolved = [
      for (final hub in hubs)
        _isContinueWatchingHub(hub)
            ? hub.copyWith(heroStyle: cwOverride?.heroStyle ?? false, heroAutoSlide: cwOverride?.heroAutoSlide ?? true)
            : withResolvedHeroOverride(hub, overrides),
    ];
    // Same opt-in watched filter as Home (#2159).
    return SettingsService.instance.read(SettingsService.hideWatchedInHubs) ? withoutWatchedItems(resolved) : resolved;
  }

  List<GlobalKey<HubSectionState>> _keysForHubs(List<MediaHub> hubs) {
    final occurrences = <String, int>{};
    final liveIdentities = <String>{};
    final keys = <GlobalKey<HubSectionState>>[];
    final heroKeys = <GlobalKey<HeroHubSectionState>?>[];
    for (final hub in hubs) {
      var identity = '${hub.serverId ?? ''}:${hub.identifier ?? hub.id}';
      final occurrence = occurrences.update(identity, (n) => n + 1, ifAbsent: () => 0);
      if (occurrence > 0) identity = '$identity#$occurrence';
      liveIdentities.add(identity);
      keys.add(_hubKeysByIdentity.putIfAbsent(identity, GlobalKey<HubSectionState>.new));
      heroKeys.add(
        hub.heroStyle && hub.items.isNotEmpty
            ? _heroHubKeysByIdentity.putIfAbsent(identity, GlobalKey<HeroHubSectionState>.new)
            : null,
      );
    }
    _hubKeysByIdentity.removeWhere((identity, _) => !liveIdentities.contains(identity));
    _heroHubKeysByIdentity.removeWhere((identity, _) => !liveIdentities.contains(identity));
    _heroKeys = heroKeys;
    return keys;
  }

  /// Focus row [index]: its hero key when it is a hero row, else its plain key.
  void _requestFocusAtHub(List<GlobalKey<HubSectionState>> keys, int index) {
    if (index < 0 || index >= keys.length) return;
    final hero = index < _heroKeys.length ? _heroKeys[index] : null;
    if (hero != null) {
      hero.currentState?.requestFocusFromMemory();
    } else {
      keys[index].currentState?.requestFocusFromMemory();
    }
  }

  bool _handleVerticalNavigation(List<GlobalKey<HubSectionState>> keys, int hubIndex, bool isUp) {
    return navigateVerticalHubRows(
      hubCount: keys.length,
      hubIndex: hubIndex,
      isUp: isUp,
      propagateTopBoundary: true,
      requestFocus: (targetIndex) => _requestFocusAtHub(keys, targetIndex),
    );
  }

  /// Focus the first item in the first hub (for tab activation)
  @override
  void focusFirstItem() {
    if (PlatformDetector.usesTvHomeLayout()) {
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
    if (items.isNotEmpty) {
      final keys = _keysForHubs(items);
      final hero = _heroKeys.isNotEmpty ? _heroKeys.first : null;
      if (hero != null) {
        hero.currentState?.requestFocusFromMemory();
      } else {
        keys.first.currentState?.requestFocusAt(0);
      }
    }
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  // Extra top padding for focus decoration (scale + border extends beyond item bounds)
  static const double _focusDecorationPadding = 8.0;

  @override
  Widget buildContent(List<MediaHub> items) {
    final hubKeys = _keysForHubs(items);

    // Same stock TV spotlight layout as Home (see discover_screen.dart).
    if (PlatformDetector.usesTvHomeLayout()) {
      return SettingsBuilder(
        prefs: const [SettingsService.hideSpoilers, SettingsService.libraryDensity, SettingsService.episodePosterMode],
        builder: (context) => _buildTvContent(items),
      );
    }

    return NestedTabScrollbar(
      child: CustomScrollView(
        // Allow focus decoration to render outside scroll bounds
        clipBehavior: Clip.none,
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, _focusDecorationPadding, 0, 8),
            sliver: SliverList.builder(
              itemCount: items.length,
              findChildIndexCallback: (key) {
                final index = hubKeys.indexOf(key as GlobalKey<HubSectionState>);
                return index < 0 ? null : index;
              },
              itemBuilder: (context, index) {
                final hub = items[index];
                final isContinueWatching = _isContinueWatchingHub(hub);
                final usesContinueWatchingAction = _usesContinueWatchingAction(hub);

                if (hub.heroStyle && hub.items.isNotEmpty) {
                  return HeroHubSection(
                    key: _heroKeys[index],
                    hub: hub,
                    onVerticalNavigation: (isUp) => _handleVerticalNavigation(hubKeys, index, isUp),
                    onNavigateUp: index == 0 ? widget.onBack : null,
                    onNavigateToSidebar: _navigateToSidebar,
                  );
                }
                return HubSection(
                  key: hubKeys[index],
                  hub: hub,
                  focusMemory: _hubFocusMemory,
                  icon: hubIconFor(hub),
                  isInContinueWatching: isContinueWatching,
                  usesContinueWatchingAction: usesContinueWatchingAction,
                  onRefresh: updateItem,
                  onRemoveFromContinueWatching: isContinueWatching ? _refreshContinueWatching : null,
                  onVerticalNavigation: (isUp) => _handleVerticalNavigation(hubKeys, index, isUp),
                  onBack: widget.onBack,
                  onNavigateUp: index == 0 ? widget.onBack : null,
                  onNavigateToSidebar: _navigateToSidebar,
                );
              },
            ),
          ),
        ],
      ),
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
                focusMemory: _hubFocusMemory,
                iconForHub: (hub, _) => hubIconFor(hub),
                onFocusedHubItemChanged: _setSpotlightItem,
                onRefresh: updateItem,
                onRemoveFromContinueWatching: _refreshContinueWatching,
                isContinueWatchingHub: _isContinueWatchingHub,
                usesContinueWatchingAction: _usesContinueWatchingAction,
                onNavigateUp: widget.onNavigateToChrome ?? widget.onBack,
                onNavigateToSidebar: _navigateToSidebar,
                onBack: widget.onBack,
                tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
                widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
                onActivateItem: _handleTvHeroActivate,
              ),
            ),
    );
  }

  /// Selecting a Hero row's item on TV — "clicking the banner" — mirrors PC's
  /// hero card tap exactly (same Organizer-configured
  /// heroCardTapAction setting). Plain rows
  /// return false so TvBrowseRail's own default activation (open details, or
  /// play directly for Continue Watching) still applies unchanged.
  Future<bool> _handleTvHeroActivate(MediaHub hub, MediaItem item) async {
    if (!hub.heroStyle) return false;
    final tapAction = SettingsService.instance.read(SettingsService.heroCardTapAction);
    unawaited(
      navigateToMediaItem(context, item, onRefresh: updateItem, playDirectly: tapAction == HeroCardTapAction.play),
    );
    return true;
  }

  /// Refresh the Continue Watching section
  void _refreshContinueWatching() {
    // Reload all data to refresh the continue watching section
    loadItems();
  }
}
