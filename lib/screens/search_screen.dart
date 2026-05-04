import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../mixins/controller_disposer_mixin.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/pill_input_decoration.dart';
import '../widgets/focusable_media_card.dart';
import '../utils/focus_utils.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with Refreshable, FullRefreshable, SearchInputFocusable, FocusableTab, ControllerDisposerMixin {
  late final _searchController = createTextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  final _firstResultFocusNode = FocusNode(debugLabel: 'SearchFirstResult');
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late final Debounce _searchDebounce;
  String _lastSearchedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchDebounce = debounce(_performSearch, const Duration(milliseconds: 500));
    _searchController.addListener(_onSearchChanged);
    FocusUtils.requestFocusAfterBuild(this, _searchFocusNode);
  }

  @override
  void dispose() {
    _searchDebounce.cancel();
    _searchController.removeListener(_onSearchChanged);
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

      final neutral = await multiServerProvider.aggregationService.searchAcrossServers(query);
      if (mounted) {
        setState(() {
          _searchResults = neutral;
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
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Focus the search input field
  @override
  void focusSearchInput() {
    _searchFocusNode.requestFocus();
  }

  @override
  void focusActiveTabIfReady() {
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
            disableScale: true,
            focusNode: index == 0 ? _firstResultFocusNode : null,
            onListRefresh: () => updateItem(item.id),
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
          primary: false,
          slivers: [
            DesktopSliverAppBar(title: Text(t.common.search), floating: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: FocusableTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onNavigateLeft: _navigateToSidebar,
                  onNavigateDown: _searchResults.isNotEmpty && !_isSearching
                      ? _firstResultFocusNode.requestFocus
                      : null,
                  onBack: () {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                    } else {
                      _navigateToSidebar();
                    }
                  },
                  decoration: pillInputDecoration(
                    context,
                    hintText: t.search.hint,
                    prefixIcon: const AppIcon(Symbols.search_rounded, fill: 1),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const AppIcon(Symbols.clear_rounded, fill: 1),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
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
