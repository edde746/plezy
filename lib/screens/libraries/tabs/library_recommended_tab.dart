import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../services/plex_client.dart';
import '../../../i18n/strings.g.dart';
import '../../../mixins/item_updatable.dart';
import '../../../models/plex_hub.dart';
import '../../../models/plex_metadata.dart';
import '../../../widgets/hub_section.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Recommended tab for library screen
/// Shows library-specific hubs and recommendations, including dedicated Continue Watching
class LibraryRecommendedTab extends BaseLibraryTab<PlexHub> {
  const LibraryRecommendedTab({
    super.key,
    required super.library,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryRecommendedTab> createState() => _LibraryRecommendedTabState();
}

class _LibraryRecommendedTabState extends BaseLibraryTabState<PlexHub, LibraryRecommendedTab> with ItemUpdatable {
  /// GlobalKeys for each hub section to enable vertical navigation
  final List<GlobalKey<HubSectionState>> _hubKeys = [];

  @override
  PlexClient get client => getClientForLibrary();

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    // Update the item in any hub that contains it
    for (final hub in items) {
      final itemIndex = hub.items.indexWhere((item) => item.ratingKey == ratingKey);
      if (itemIndex != -1) {
        hub.items[itemIndex] = updatedMetadata;
      }
    }
  }

  @override
  IconData get emptyIcon => Symbols.recommend_rounded;

  @override
  String get emptyMessage => t.libraries.noRecommendations;

  @override
  String get errorContext => t.libraries.tabs.recommended;

  @override
  Future<List<PlexHub>> loadData() async {
    // Clear hub keys before loading new hubs to prevent stale references
    _hubKeys.clear();

    // Use server-specific client for this library
    final client = getClientForLibrary();

    // Load both continue watching items and regular hubs in parallel
    final results = await Future.wait([
      client.getOnDeckForLibrary(widget.library.key),
      client.getLibraryHubs(widget.library.key, limit: 12),
    ]);

    final continueWatchingItems = results[0] as List<PlexMetadata>;
    final hubs = results[1] as List<PlexHub>;

    // Filter out any existing Continue Watching hubs since we're adding our own
    final filteredHubs = hubs.where((hub) {
      final title = hub.title.toLowerCase();
      final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
      return !title.contains('continue watching') &&
          !title.contains('on deck') &&
          !hubId.contains('ondeck') &&
          !hubId.contains('continue');
    }).toList();

    final finalHubs = <PlexHub>[];

    // Add Continue Watching as the first hub if there are items
    if (continueWatchingItems.isNotEmpty) {
      final continueWatchingHub = PlexHub(
        hubKey: 'library_continue_watching_${widget.library.key}',
        title: t.discover.continueWatching,
        type: 'mixed',
        hubIdentifier: '_library_continue_watching_',
        size: continueWatchingItems.length,
        more: false,
        items: continueWatchingItems,
        serverId: widget.library.serverId,
        serverName: widget.library.serverName,
      );
      finalHubs.add(continueWatchingHub);
    }

    // Add the filtered regular hubs
    finalHubs.addAll(filteredHubs);

    return finalHubs;
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

  /// Navigate to the sidebar (called when user presses left at leftmost item)
  void _navigateToSidebar() {
    final focusScope = MainScreenFocusScope.of(context);
    focusScope?.focusSidebar();
  }

  /// Focus the first item in the first hub (for tab activation)
  @override
  void focusFirstItem() {
    if (_hubKeys.isNotEmpty && items.isNotEmpty) {
      _hubKeys[0].currentState?.requestFocusAt(0);
    }
  }

  @override
  Widget buildContent(List<PlexHub> items) {
    _ensureHubKeys(items.length);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final hub = items[index];
        final isContinueWatching = hub.hubIdentifier == '_library_continue_watching_';

        return HubSection(
          key: index < _hubKeys.length ? _hubKeys[index] : null,
          hub: hub,
          icon: _getHubIcon(hub),
          isInContinueWatching: isContinueWatching,
          onRefresh: updateItem,
          onRemoveFromContinueWatching: isContinueWatching ? _refreshContinueWatching : null,
          onVerticalNavigation: (isUp) => _handleVerticalNavigation(index, isUp),
          onBack: widget.onBack,
          onNavigateLeft: _navigateToSidebar,
          onNavigateUp: index == 0 ? widget.onBack : null,
        );
      },
    );
  }

  /// Refresh the Continue Watching section
  void _refreshContinueWatching() {
    // Reload all data to refresh the continue watching section
    loadItems();
  }

  IconData _getHubIcon(PlexHub hub) {
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
