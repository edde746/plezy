import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../client/plex_client.dart';
import '../i18n/strings.g.dart';
import '../mixins/item_updatable.dart';
import '../mixins/refreshable.dart';
import '../models/plex_metadata.dart';
import '../providers/multi_server_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/grid_cross_axis_extent.dart';
import '../utils/provider_extensions.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/media_card.dart';
import '../widgets/server_badge.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with Refreshable {
  final _searchController = TextEditingController();
  List<PlexMetadata> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;
  String _lastSearchedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    final query = _searchController.text;

    if (query.trim().isEmpty) {
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

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
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

  // Public method to fully reload all content (for profile switches)
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
                padding: const EdgeInsets.all(16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: t.search.hint,
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // State update handled by listener
                        },
                      ),
                  ],
                  autoFocus: false,
                ),
              ),
            ),
            if (_isSearching)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_hasSearched)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        t.search.searchYourMedia,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.search.enterTitleActorOrKeyword,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.messages.noResultsFound,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.search.tryDifferentTerm,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  if (settingsProvider.viewMode == ViewMode.list) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _searchResults[index];
                          return MediaCard(
                            key: Key(item.ratingKey),
                            item: item,
                            onRefresh: updateItem,
                          );
                        }, childCount: _searchResults.length),
                      ),
                    );
                  } else {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: getMaxCrossAxisExtentWithPadding(
                            context,
                            settingsProvider.libraryDensity,
                            32,
                          ),
                          childAspectRatio: 2 / 3.3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _searchResults[index];
                          return MediaCard(
                            key: Key(item.ratingKey),
                            item: item,
                            onRefresh: updateItem,
                          );
                        }, childCount: _searchResults.length),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
