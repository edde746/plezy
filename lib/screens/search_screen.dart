import 'dart:async';
import 'package:flutter/material.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';

class SearchScreen extends StatefulWidget {
  final PlexClient client;
  final PlexUserProfile? userProfile;

  const SearchScreen({super.key, required this.client, this.userProfile});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with Refreshable, ItemUpdatable {
  @override
  PlexClient get client => widget.client;

  final _searchController = TextEditingController();
  List<PlexMetadata> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

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
      });
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
      final results = await widget.client.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
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

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _searchResults.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (index != -1) {
      _searchResults[index] = updatedMetadata;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            DesktopSliverAppBar(title: const Text('Search'), floating: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search movies, shows, music...',
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
                        'Search your media',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a title, actor, or keyword',
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
                        'No results found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 2 / 3.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _searchResults[index];
                    return MediaCard(
                      key: Key(item.ratingKey),
                      client: widget.client,
                      item: item,
                      onRefresh: updateItem,
                      userProfile: widget.userProfile,
                    );
                  }, childCount: _searchResults.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
