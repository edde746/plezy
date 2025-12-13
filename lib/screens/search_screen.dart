import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../i18n/strings.g.dart';
import '../mixins/refreshable.dart';
import '../models/plex_metadata.dart';
import '../providers/multi_server_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_logger.dart';
import '../utils/sliver_adaptive_media_builder.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/media_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with Refreshable, FullRefreshable, SearchInputFocusable {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  List<PlexMetadata> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late final Debounce _searchDebounce;
  String _lastSearchedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchDebounce = debounce(
      _performSearch,
      const Duration(milliseconds: 500),
    );
    _searchController.addListener(_onSearchChanged);
    // Focus the search input when the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchDebounce.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    if (query.trim().isEmpty) {
      _searchDebounce.cancel();
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
        _lastSearchedQuery = '';
      });
      return;
    }

    // Only search if the query has actually changed
    if (query.trim() == _lastSearchedQuery.trim()) {
      return;
    }

    _searchDebounce([query]);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Search across all connected servers
      final results = await multiServerProvider.aggregationService
          .searchAcrossServers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _lastSearchedQuery = query.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errors.searchFailed(error: e))),
        );
      }
    }
  }

  @override
  void refresh() {
    // Re-run the current search if there is one
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Focus the search input field
  @override
  void focusSearchInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    appLogger.d(
      'SearchScreen.fullRefresh() called - clearing search and reloading',
    );
    // Clear search results and search text for new profile
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _hasSearched = false;
      _lastSearchedQuery = '';
    });
  }

  void updateItem(String ratingKey) {
    // Trigger a refresh of the search to get updated metadata
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            DesktopSliverAppBar(title: Text(t.screens.search), floating: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: t.search.hint,
                    prefixIcon: const AppIcon(Symbols.search_rounded, fill: 1),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const AppIcon(Symbols.clear_rounded, fill: 1),
                            onPressed: () {
                              _searchController.clear();
                              // State update handled by listener
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            if (_isSearching)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_hasSearched)
              _SearchEmptyState(
                icon: Symbols.search_rounded,
                title: t.search.searchYourMedia,
                subtitle: t.search.enterTitleActorOrKeyword,
              )
            else if (_searchResults.isEmpty)
              _SearchEmptyState(
                icon: Symbols.search_off_rounded,
                title: t.messages.noResultsFound,
                subtitle: t.search.tryDifferentTerm,
              )
            else
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return buildAdaptiveMediaSliverBuilder<PlexMetadata>(
                    context: context,
                    items: _searchResults,
                    itemBuilder: (context, item, index) {
                      return MediaCard(
                        key: Key(item.ratingKey),
                        item: item,
                        onRefresh: updateItem,
                      );
                    },
                    viewMode: settingsProvider.viewMode,
                    density: settingsProvider.libraryDensity,
                    padding: const EdgeInsets.all(16),
                    childAspectRatio: 2 / 3.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget for search screen with icon, title, and subtitle.
class _SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, fill: 1, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
