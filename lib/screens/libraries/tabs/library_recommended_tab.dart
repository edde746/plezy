import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../media/media_hub.dart';
import '../../../media/media_item.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/watch_state_aware.dart';
import '../../../services/settings_service.dart';
import '../../../utils/global_key_utils.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/platform_detector.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/watch_state_notifier.dart';
import '../../../widgets/hub_section.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/tv_browse_rail.dart';
import '../../../widgets/tv_spotlight_background.dart';
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
    with ItemUpdatable, WatchStateAware {
  /// GlobalKeys for each hub section to enable vertical navigation
  final List<GlobalKey<HubSectionState>> _hubKeys = [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();
  MediaItem? _spotlightItem;

  MediaItem? get _defaultSpotlightItem {
    for (final hub in items) {
      if (hub.items.isNotEmpty) return hub.items.first;
    }
    return null;
  }

  MediaItem? get _effectiveSpotlightItem {
    final current = _spotlightItem;
    if (current == null) return _defaultSpotlightItem;
    for (final hub in items) {
      if (hub.items.any((item) => item.globalKey == current.globalKey)) return current;
    }
    return _defaultSpotlightItem;
  }

  void _setSpotlightItem(MediaItem item) {
    if (_spotlightItem?.globalKey == item.globalKey) return;
    setState(() => _spotlightItem = item);
  }

  @override
  String? get itemServerId => widget.library.serverId;

  @override
  String? get watchStateServerId => widget.library.serverId;

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
        keys.add(buildGlobalKey(serverId, item.id));
        if (item.parentId != null) keys.add(buildGlobalKey(serverId, item.parentId!));
        if (item.grandparentId != null) keys.add(buildGlobalKey(serverId, item.grandparentId!));
      }
    }
    return keys;
  }

  @override
  void updateItemInLists(String itemId, MediaItem updatedItem) {
    // Update the item in any hub that contains it. MediaHub items are
    // immutable lists; rebuild the affected hub in-place.
    for (var i = 0; i < items.length; i++) {
      final hub = items[i];
      final itemIndex = hub.items.indexWhere((item) => item.id == itemId);
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
    final refreshIds = <String>{};
    for (final hub in items) {
      for (final item in hub.items) {
        if (affectedIds.contains(item.id)) {
          refreshIds.add(item.id);
        }
      }
    }
    for (final itemId in refreshIds) {
      unawaited(updateItem(itemId));
    }
  }

  void _removeContinueWatchingItem(String itemId) {
    setState(() {
      for (var i = 0; i < items.length; i++) {
        final hub = items[i];
        if (!_isContinueWatchingHub(hub)) continue;
        final newItems = hub.items.where((item) => item.id != itemId).toList();
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
  static bool _isContinueWatchingHub(MediaHub hub) {
    final hubId = hub.identifier?.toLowerCase() ?? '';
    return hubId.contains('inprogress');
  }

  @override
  Future<List<MediaHub>> loadData() async {
    // Clear hub keys before loading new hubs to prevent stale references
    _hubKeys.clear();

    // Backend-aware fetch: Plex hits /hubs/sections, Jellyfin synthesises
    // Continue Watching + Next Up + Recently Added.
    final client = context.tryGetMediaClientForServer(widget.library.serverId);
    final hubs = client == null
        ? <MediaHub>[]
        : List.of(
            await client.fetchLibraryHubs(
              widget.library.id,
              libraryName: widget.library.title,
              limit: 12,
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
    final targetIndex = isUp ? hubIndex - 1 : hubIndex + 1;

    // Check if target is valid
    if (targetIndex < 0) {
      // At top boundary - return false to allow onNavigateUp to handle it
      return false;
    }

    if (targetIndex >= _hubKeys.length) {
      // At bottom boundary, block navigation
      return true;
    }

    // Navigate to target hub with column memory
    final targetState = _hubKeys[targetIndex].currentState;
    if (targetState != null) {
      targetState.requestFocusFromMemory();
      return true;
    }

    return false;
  }

  /// Focus the first item in the first hub (for tab activation)
  @override
  void focusFirstItem() {
    if (PlatformDetector.isTV()) {
      _tvBrowseRailKey.currentState?.requestFocus();
      return;
    }
    if (_hubKeys.isNotEmpty && items.isNotEmpty) {
      _hubKeys.first.currentState?.requestFocusAt(0);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
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

              return HubSection(
                key: index < _hubKeys.length ? _hubKeys[index] : null,
                hub: hub,
                icon: _getHubIcon(hub),
                isInContinueWatching: isContinueWatching,
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
    final spotlight = _effectiveSpotlightItem;
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final svc = SettingsService.instanceOrNull!;
    final client = context.tryGetMediaClientForServer(spotlight?.serverId ?? widget.library.serverId);
    final scale = TvLayoutConstants.scaleForSize(size);
    final sidebarBleed = MainScreenFocusScope.sideNavigationBleedOf(
      context,
      alwaysKeepSidebarOpen: svc.read(SettingsService.alwaysKeepSidebarOpen),
    );
    final railSize = MainScreenFocusScope.foregroundSizeOf(context);
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    final railHeight = tvHubs.isEmpty
        ? 0.0
        : TvBrowseRailLayout.estimateHeight(
            size: railSize,
            hubs: tvHubs,
            density: svc.read(SettingsService.libraryDensity),
            episodePosterMode: svc.read(SettingsService.episodePosterMode),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
          );
    final spotlightTop = (size.height * 0.075).clamp(64.0 * scale, 120.0 * scale).toDouble();
    final minimumSpotlightBottom = railHeight + (8 * scale);
    final baseSpotlightBottom = (size.height * 0.48).clamp(160.0, 820.0).toDouble();
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (size.height - spotlightTop - (96 * scale)).clamp(0.0, double.infinity).toDouble();
    final spotlightBottom = desiredSpotlightBottom > maxSpotlightBottom ? maxSpotlightBottom : desiredSpotlightBottom;
    final spotlightLeft = (24 * scale).clamp(18.0, 40.0).toDouble();

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: -sidebarBleed,
              width: fullBleedWidth,
              child: TvSpotlightBackground(
                item: spotlight,
                client: client,
                hideSpoilers: svc.read(SettingsService.hideSpoilers),
                contentTop: spotlightTop,
                contentBottom: spotlightBottom,
                contentLeft: spotlightLeft + sidebarBleed,
                compact: true,
                showPrimaryAction: false,
              ),
            ),
            if (tvHubs.isNotEmpty)
              Positioned(
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
                  onNavigateUp: widget.onNavigateToChrome ?? widget.onBack,
                  onNavigateToSidebar: _navigateToSidebar,
                  onBack: widget.onBack,
                  tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
                  backgroundBleedLeft: sidebarBleed,
                ),
              ),
          ],
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
