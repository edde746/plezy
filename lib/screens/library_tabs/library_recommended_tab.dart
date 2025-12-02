import 'package:flutter/material.dart';

import '../../client/plex_client.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/item_updatable.dart';
import '../../models/plex_hub.dart';
import '../../models/plex_metadata.dart';
import '../../widgets/hub_navigation_controller.dart';
import '../../widgets/hub_section.dart';
import 'base_library_tab.dart';

/// Recommended tab for library screen
/// Shows library-specific hubs and recommendations, including dedicated Continue Watching
class LibraryRecommendedTab extends BaseLibraryTab<PlexHub> {
  const LibraryRecommendedTab({super.key, required super.library});

  @override
  State<LibraryRecommendedTab> createState() => _LibraryRecommendedTabState();
}

class _LibraryRecommendedTabState
    extends BaseLibraryTabState<PlexHub, LibraryRecommendedTab>
    with ItemUpdatable {
  final HubNavigationController _hubNavigationController =
      HubNavigationController();

  @override
  void dispose() {
    _hubNavigationController.dispose();
    super.dispose();
  }

  /// Focus the first item in the first hub
  @override
  void focusFirstItem() {
    _hubNavigationController.focusHub(0, 0);
  }

  @override
  PlexClient get client => getClientForLibrary();

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    // Update the item in any hub that contains it
    for (final hub in items) {
      final itemIndex = hub.items.indexWhere(
        (item) => item.ratingKey == ratingKey,
      );
      if (itemIndex != -1) {
        hub.items[itemIndex] = updatedMetadata;
      }
    }
  }

  @override
  IconData get emptyIcon => Icons.recommend;

  @override
  String get emptyMessage => t.libraries.noRecommendations;

  @override
  String get errorContext => t.libraries.tabs.recommended;

  @override
  Future<List<PlexHub>> loadData() async {
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

  @override
  Widget buildContent(List<PlexHub> items) {
    return HubNavigationScope(
      controller: _hubNavigationController,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final hub = items[index];
          final isContinueWatching =
              hub.hubIdentifier == '_library_continue_watching_';

          return HubSection(
            hub: hub,
            icon: _getHubIcon(hub),
            navigationOrder: index,
            isInContinueWatching: isContinueWatching,
            onRefresh: updateItem,
            onRemoveFromContinueWatching: isContinueWatching
                ? _refreshContinueWatching
                : null,
          );
        },
      ),
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
      return Icons.play_circle;
    } else if (title.contains('recently') || title.contains('new')) {
      return Icons.fiber_new;
    } else if (title.contains('popular') || title.contains('trending')) {
      return Icons.trending_up;
    } else if (title.contains('top') || title.contains('rated')) {
      return Icons.star;
    } else if (title.contains('recommended')) {
      return Icons.thumb_up;
    } else if (title.contains('unwatched')) {
      return Icons.visibility_off;
    } else if (title.contains('genre')) {
      return Icons.category;
    }
    return Icons.movie;
  }
}
