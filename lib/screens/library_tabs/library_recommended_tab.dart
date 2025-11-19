import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plex_library.dart';
import '../../models/plex_hub.dart';
import '../../providers/plex_client_provider.dart';
import '../../utils/app_logger.dart';
import '../../widgets/hub_section.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/refreshable.dart';
import '../../widgets/content_state_builder.dart';

/// Recommended tab for library screen
/// Shows library-specific hubs and recommendations
class LibraryRecommendedTab extends StatefulWidget {
  final PlexLibrary library;

  const LibraryRecommendedTab({super.key, required this.library});

  @override
  State<LibraryRecommendedTab> createState() => _LibraryRecommendedTabState();
}

class _LibraryRecommendedTabState extends State<LibraryRecommendedTab>
    with AutomaticKeepAliveClientMixin, Refreshable {
  @override
  bool get wantKeepAlive => true;

  @override
  void refresh() {
    _loadHubs();
  }

  List<PlexHub> _hubs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHubs();
  }

  @override
  void didUpdateWidget(LibraryRecommendedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.key != widget.library.key) {
      _loadHubs();
    }
  }

  Future<void> _loadHubs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = context.read<PlexClientProvider>().client;
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      final hubs = await client.getLibraryHubs(widget.library.key, limit: 12);

      if (!mounted) return;

      setState(() {
        _hubs = hubs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Error loading library hubs', error: e);
      setState(() {
        _errorMessage = t.errors.failedToLoad(
          context: t.libraries.tabs.recommended,
          error: e.toString(),
        );
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return ContentStateBuilder<PlexHub>(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      items: _hubs,
      emptyIcon: Icons.recommend,
      emptyMessage: t.libraries.noRecommendations,
      onRetry: _loadHubs,
      builder: (items) => RefreshIndicator(
        onRefresh: _loadHubs,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final hub = items[index];
            return HubSection(hub: hub, icon: _getHubIcon(hub));
          },
        ),
      ),
    );
  }
}
