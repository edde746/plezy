import 'package:flutter/material.dart';
import '../../models/plex_hub.dart';
import '../../widgets/hub_section.dart';
import '../../widgets/hub_navigation_controller.dart';
import '../../i18n/strings.g.dart';
import 'base_library_tab.dart';

/// Recommended tab for library screen
/// Shows library-specific hubs and recommendations
class LibraryRecommendedTab extends BaseLibraryTab<PlexHub> {
  const LibraryRecommendedTab({super.key, required super.library});

  @override
  State<LibraryRecommendedTab> createState() => _LibraryRecommendedTabState();
}

class _LibraryRecommendedTabState
    extends BaseLibraryTabState<PlexHub, LibraryRecommendedTab> {
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
  IconData get emptyIcon => Icons.recommend;

  @override
  String get emptyMessage => t.libraries.noRecommendations;

  @override
  String get errorContext => t.libraries.tabs.recommended;

  @override
  Future<List<PlexHub>> loadData() async {
    // Use server-specific client for this library
    final client = getClientForLibrary();

    // Hubs are now tagged with server info at the source
    return await client.getLibraryHubs(widget.library.key, limit: 12);
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
          return HubSection(
            hub: hub,
            icon: _getHubIcon(hub),
            navigationOrder: index,
          );
        },
      ),
    );
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
