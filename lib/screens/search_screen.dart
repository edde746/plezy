import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../focus/dpad_navigator.dart';
import '../i18n/strings.g.dart';
import '../mixins/refreshable.dart';
import '../models/plex_metadata.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/focusable_media_card.dart';
import '../utils/focus_utils.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with Refreshable, FullRefreshable, SearchInputFocusable {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  final _firstResultFocusNode = FocusNode(debugLabel: 'SearchFirstResult');
  List<PlexMetadata> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late final Debounce _searchDebounce;
  String _lastSearchedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchDebounce = debounce(_performSearch, const Duration(milliseconds: 500));
    _searchController.addListener(_onSearchChanged);
    // Focus the search input when the screen is shown
    FocusUtils.requestFocusAfterBuild(this, _searchFocusNode);
  }

  @override
  void dispose() {
    _searchDebounce.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _firstResultFocusNode.dispose();
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
      final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Search across all connected servers
      final results = await multiServerProvider.aggregationService.searchAcrossServers(query);
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
        showErrorSnackBar(context, t.errors.searchFailed(error: e));
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
    _searchFocusNode.requestFocus();
  }

  /// Set the search query externally (e.g. from companion remote)
  @override
  void setSearchQuery(String query) {
    _searchController.text = query;
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    appLogger.d('SearchScreen.fullRefresh() called - clearing search and reloading');
    // Clear search results and search text for new profile
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _hasSearched = false;
      _lastSearchedQuery = '';
    });
  }

  void updateItem(String _) {
    // Trigger a refresh of the search to get updated metadata
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  /// Handle key events on the search input for D-pad navigation
  KeyEventResult _handleSearchInputKeyEvent(FocusNode _, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // DOWN: Focus first result if results exist and not loading
    if (key.isDownKey && _searchResults.isNotEmpty && !_isSearching) {
      _firstResultFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // LEFT at cursor position 0: Navigate to sidebar
    if (key.isLeftKey && _searchController.selection.baseOffset == 0) {
      _navigateToSidebar();
      return KeyEventResult.handled;
    }

    // BACK: Clear search or navigate to sidebar
    if (key.isBackKey) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      } else {
        _navigateToSidebar();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildResultsList(BuildContext context) {
    final multiServer = context.watch<MultiServerProvider>();
    final showServerName = multiServer.totalServerCount > 1;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _searchResults[index];
          return FocusableMediaCard(
            key: Key(item.globalKey),
            item: item,
            forceListMode: true,
            focusNode: index == 0 ? _firstResultFocusNode : null,
            onListRefresh: () => updateItem(item.ratingKey),
            onNavigateLeft: _navigateToSidebar,
            onNavigateUp: index == 0 ? focusSearchInput : null,
            showServerName: showServerName,
          );
        }, childCount: _searchResults.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            DesktopSliverAppBar(title: Text(t.common.search), floating: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Focus(
                  onKeyEvent: _handleSearchInputKeyEvent,
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
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            if (_isSearching)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (!_hasSearched)
              SliverFillRemaining(
                child: StateMessageWidget(
                  message: t.search.searchYourMedia,
                  subtitle: t.search.enterTitleActorOrKeyword,
                  icon: Symbols.search_rounded,
                  iconSize: 80,
                ),
              )
            else if (_searchResults.isEmpty)
              SliverFillRemaining(
                child: StateMessageWidget(
                  message: t.messages.noResultsFound,
                  subtitle: t.search.tryDifferentTerm,
                  icon: Symbols.search_off_rounded,
                  iconSize: 80,
                ),
              )
            else
              _buildResultsList(context),
          ],
        ),
      ),
    );
  }
}
