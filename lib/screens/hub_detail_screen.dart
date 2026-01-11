import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_metadata.dart';
import '../models/plex_sort.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../widgets/media_grid_sliver.dart';
import '../widgets/focused_scroll_scaffold.dart';
import 'libraries/sort_bottom_sheet.dart';
import 'libraries/state_messages.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';

/// Screen to display full content of a recommendation hub
class HubDetailScreen extends StatefulWidget {
  final PlexHub hub;

  const HubDetailScreen({super.key, required this.hub});

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen> with Refreshable {
  PlexClient get client => _getClientForHub();

  List<PlexMetadata> _items = [];
  List<PlexMetadata> _filteredItems = [];
  List<PlexSort> _sortOptions = [];
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Get the correct PlexClient for this hub's server
  PlexClient _getClientForHub() {
    return context.getClientForServer(widget.hub.serverId!);
  }

  @override
  void initState() {
    super.initState();
    // Start with items already loaded in the hub
    _items = widget.hub.items;
    _filteredItems = widget.hub.items;
    // Load more items if available
    if (widget.hub.more) {
      _loadMoreItems();
    }
    // Load sorts based on the library type
    _loadSorts();
  }

  Future<void> _loadSorts() async {
    try {
      final client = _getClientForHub();

      // Get the library key from the hub key
      // Hub keys can have various formats:
      // - /hubs/sections/1/...
      // - /library/sections/1/all?...
      final hubKey = widget.hub.hubKey;
      appLogger.d('Hub key: $hubKey');

      // Try different patterns
      RegExpMatch? match = RegExp(r'/hubs/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'/library/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'sections/(\d+)').firstMatch(hubKey);

      if (match != null) {
        final sectionId = match.group(1)!;
        appLogger.d('Loading sorts for section: $sectionId');

        // Load sorts for this library
        final sorts = await client.getLibrarySorts(sectionId);

        appLogger.d('Loaded ${sorts.length} sorts');

        setState(() {
          _sortOptions = sorts.isNotEmpty ? sorts : _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      } else {
        appLogger.w('Could not extract section ID from hub key: $hubKey');
        // Provide default sort options even if we can't get library-specific ones
        setState(() {
          _sortOptions = _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      }
    } catch (e) {
      appLogger.e('Failed to load sorts', error: e);
      // Provide default sort options on error
      setState(() {
        _sortOptions = _getDefaultSortOptions();
        // Don't set a default sort - let items stay in original order
      });
    }
  }

  List<PlexSort> _getDefaultSortOptions() {
    return [
      PlexSort(key: 'titleSort', title: t.hubDetail.title, defaultDirection: 'asc'),
      PlexSort(key: 'year', descKey: 'year:desc', title: t.hubDetail.releaseYear, defaultDirection: 'desc'),
      PlexSort(key: 'addedAt', descKey: 'addedAt:desc', title: t.hubDetail.dateAdded, defaultDirection: 'desc'),
      PlexSort(key: 'rating', descKey: 'rating:desc', title: t.hubDetail.rating, defaultDirection: 'desc'),
    ];
  }

  void _applySort() {
    setState(() {
      _filteredItems = List.from(_items);

      // Apply sorting
      if (_selectedSort != null) {
        final sortKey = _selectedSort!.key;
        _filteredItems.sort((a, b) {
          int comparison = 0;

          switch (sortKey) {
            case 'titleSort':
            case 'title':
              comparison = a.title.compareTo(b.title);
              break;
            case 'addedAt':
              comparison = (a.addedAt ?? 0).compareTo(b.addedAt ?? 0);
              break;
            case 'originallyAvailableAt':
            case 'year':
              comparison = (a.year ?? 0).compareTo(b.year ?? 0);
              break;
            case 'rating':
              comparison = (a.rating ?? 0).compareTo(b.rating ?? 0);
              break;
            default:
              comparison = a.title.compareTo(b.title);
          }

          return _isSortDescending ? -comparison : comparison;
        });
      }
    });
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SortBottomSheet(
        sortOptions: _sortOptions,
        selectedSort: _selectedSort,
        isSortDescending: _isSortDescending,
        onSortChanged: (sort, descending) {
          setState(() {
            _selectedSort = sort;
            _isSortDescending = descending;
          });
          _applySort();
        },
        onClear: () {
          setState(() {
            // Reset to no sorting (original order)
            _selectedSort = null;
            _isSortDescending = false;
          });
          _applySort();
        },
      ),
    );
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = _getClientForHub();

      // Fetch items from the hub, tagged with server info at the source
      final items = await client.getHubContent(widget.hub.hubKey);

      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });

      // Apply any existing sort
      _applySort();

      appLogger.d('Loaded ${items.length} items for hub: ${widget.hub.title}');
    } catch (e) {
      appLogger.e('Failed to load hub content', error: e);
      setState(() {
        _errorMessage = t.messages.errorLoading(error: e.toString());
        _isLoading = false;
      });
    }
  }

  void _handleItemRefresh(String ratingKey) {
    // Refresh the specific item in the list
    setState(() {
      final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
      if (index != -1) {
        // The item will be refreshed by the MediaCard itself
        appLogger.d('Item refresh requested for: $ratingKey');
      }
    });
  }

  @override
  void refresh() {
    _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(widget.hub.title),
      actions: [
        IconButton(
          icon: AppIcon(Symbols.swap_vert_rounded, fill: 1, semanticLabel: t.libraries.sort),
          onPressed: _showSortBottomSheet,
        ),
      ],
      slivers: [
        if (_errorMessage != null)
          SliverFillRemaining(
            child: ErrorStateWidget(
              message: _errorMessage!,
              icon: Symbols.error_outline_rounded,
              onRetry: _loadMoreItems,
            ),
          )
        else if (_filteredItems.isEmpty && _isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (_filteredItems.isEmpty)
          SliverFillRemaining(child: Center(child: Text(t.hubDetail.noItemsFound)))
        else
          Builder(
            builder: (context) {
              final episodePosterMode = context.watch<SettingsProvider>().episodePosterMode;

              // Determine hub content type for layout decisions
              final hasEpisodes = _filteredItems.any((item) =>
                  item.usesWideAspectRatio(episodePosterMode));
              final hasNonEpisodes = _filteredItems.any((item) =>
                  !item.usesWideAspectRatio(episodePosterMode));

              // Mixed hub = has both episodes AND non-episodes
              final isMixedHub = hasEpisodes && hasNonEpisodes;

              // Episode-only = all items are episodes with thumbnails
              final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

              // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
              final useWideLayout = episodePosterMode == EpisodePosterMode.episodeThumbnail &&
                  (isEpisodeOnlyHub || isMixedHub);

              return MediaGridSliver(
                items: _filteredItems,
                onRefresh: _handleItemRefresh,
                usePaddingAwareExtent: true,
                horizontalPadding: 16,
                useWideAspectRatio: useWideLayout,
                mixedHubContext: isMixedHub,
              );
            },
          ),
      ],
    );
  }
}
