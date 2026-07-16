import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../focus/focusable_text_field.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../mixins/debounced_media_search.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/loading_indicator_box.dart';
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
    with Refreshable, FullRefreshable, SearchInputFocusable, FocusableTab, MountedSetStateMixin, DebouncedMediaSearch {
  String? _focusResultsForQuery;
  final _tvKeyboardController = TvKeyboardController();
  final _clearFocusNode = FocusNode(debugLabel: 'Search.clear');

  @override
  void initState() {
    super.initState();
    FocusUtils.requestFocusAfterBuild(this, searchFocusNode);
  }

  @override
  void dispose() {
    _clearFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    searchController.clear();
    searchFocusNode.requestFocus();
  }

  @override
  String get searchDebugLabel => 'Search';

  @override
  Future<List<MediaItem>> performSearchQuery(String query) async {
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception('No servers available');
    }
    return multiServerProvider.aggregationService.searchAcrossServers(query);
  }

  @override
  void onSearchError(Object error) {
    _focusResultsForQuery = null;
    showErrorSnackBar(context, t.errors.searchFailed(error: error));
  }

  @override
  void onSearchCleared() {
    _focusResultsForQuery = null;
  }

  @override
  void onSearchCompleted(String query, List<MediaItem> results) {
    if (_focusResultsForQuery == null || _focusResultsForQuery != query) return;
    _focusResultsForQuery = null;
    if (results.isEmpty) return;
    if (searchController.text.trim() != query) return; // user kept editing
    FocusUtils.requestFocusAfterBuild(this, firstResultFocusNode);
  }

  /// OSK "Search" / hardware Enter on TV additionally focuses the results
  /// when the forced search lands.
  @override
  void handleSearchSubmit() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    if (searchResults.isEmpty || isSearching || query != lastSearchedQuery) {
      _focusResultsForQuery = query;
    }
    super.handleSearchSubmit();
  }

  @override
  void refresh() {
    if (!mounted) return;
    runSearch(searchController.text.trim());
  }

  /// Focus the search input field
  @override
  void focusSearchInput() {
    if (!mounted) return;
    searchFocusNode.requestFocus();
  }

  @override
  void focusActiveTabIfReady() {
    if (!mounted) return;
    searchFocusNode.requestFocus();
  }

  /// Apply a complete query submitted from the Plezy companion remote: set the
  /// text, dismiss any open on-screen keyboard, land focus on the input without
  /// (re)opening the OSK, and run the search now — the first result takes focus
  /// when it lands (via onSearchCompleted). The user already typed the query on
  /// their phone, so the TV keyboard must never be up afterwards.
  @override
  void submitSearchQuery(String query) {
    if (!mounted) return;
    final trimmed = query.trim();
    searchController.text = trimmed; // listener arms the debounce / resets state

    // Focusing the field normally auto-opens the OSK; a remote search must not
    // show it, and must dismiss one the TV user already had open (the phone's
    // Search chip sends tabSearch before the query arrives).
    _tvKeyboardController.closeKeyboard();
    if (trimmed.isEmpty) return;

    // Land focus on the (visible) input immediately so the D-pad remote is
    // never stranded on the hidden previous tab — while the search is in
    // flight, when it fails, and when it returns nothing.
    _tvKeyboardController.focusInputWithoutKeyboard();

    // Same path as the OSK Search key: jumps straight to already-matching
    // results, or cancels the debounce and runs now; the screen override arms
    // _focusResultsForQuery so results take focus when they land.
    handleSearchSubmit();
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    if (!mounted) return;
    appLogger.d('SearchScreen.fullRefresh() called - clearing search and reloading');
    // Clearing the field resets the search state through the text listener.
    _focusResultsForQuery = null;
    searchController.clear();
  }

  Future<void> updateItem(MediaItem source) async {
    if (!mounted) return;
    final serverId = source.serverId;
    if (serverId == null) return;

    try {
      final multiServer = context.read<MultiServerProvider>();
      final updated = await multiServer.getClientForServer(ServerId(serverId))?.fetchItem(source.id);
      if (!mounted || updated == null) return;
      final index = searchResults.indexWhere((item) => item.globalKey == source.globalKey);
      if (index == -1) return;
      setState(() {
        searchResults[index] = updated;
      });
    } catch (e) {
      appLogger.d('Search item refresh skipped for ${source.globalKey}', error: e);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final multiServer = context.watch<MultiServerProvider>();
    final showServerName = multiServer.totalServerCount > 1;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = searchResults[index];
            return FocusableMediaCard(
              key: Key(item.globalKey),
              item: item,
              forceListMode: true,
              disableScale: true,
              focusNode: index == 0 ? firstResultFocusNode : null,
              onRefresh: updateItem,
              onListRefresh: refresh,
              onNavigateLeft: _navigateToSidebar,
              onNavigateUp: index == 0 ? focusSearchInput : null,
              showServerName: showServerName,
            );
          },
          childCount: searchResults.length,
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
        ),
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
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    FocusableTextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      tvKeyboardController: _tvKeyboardController,
                      textInputAction: TextInputAction.search,
                      onNavigateLeft: _navigateToSidebar,
                      onNavigateRight: searchController.text.isNotEmpty ? _clearFocusNode.requestFocus : null,
                      onNavigateDown: searchResults.isNotEmpty && !isSearching
                          ? firstResultFocusNode.requestFocus
                          : null,
                      onEditingComplete: PlatformDetector.isTV() ? handleSearchSubmit : null,
                      onBack: () {
                        if (searchController.text.isNotEmpty) {
                          searchController.clear();
                        } else {
                          _navigateToSidebar();
                        }
                      },
                      decoration: pillInputDecoration(
                        context,
                        hintText: t.search.hint,
                        prefixIcon: const AppIcon(Symbols.search_rounded, fill: 1),
                        suffixIcon: searchController.text.isNotEmpty ? const SizedBox(width: 48) : null,
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      FocusableButton(
                        focusNode: _clearFocusNode,
                        onPressed: _clearSearch,
                        onNavigateLeft: searchFocusNode.requestFocus,
                        onNavigateDown: searchResults.isNotEmpty && !isSearching
                            ? firstResultFocusNode.requestFocus
                            : null,
                        autoScroll: false,
                        child: IconButton(icon: const AppIcon(Symbols.clear_rounded, fill: 1), onPressed: _clearSearch),
                      ),
                  ],
                ),
              ),
            ),
            if (isSearching)
              LoadingIndicatorBox.sliver
            else if (!hasSearched)
              SliverFillRemaining(
                child: StateMessageWidget(
                  message: t.search.searchYourMedia,
                  subtitle: t.search.enterTitleActorOrKeyword,
                  icon: Symbols.search_rounded,
                  iconSize: 80,
                ),
              )
            else if (lastSearchFailed)
              SliverFillRemaining(
                child: StateMessageWidget(message: t.explore.searchFailed, icon: Symbols.error_rounded, iconSize: 80),
              )
            else if (searchResults.isEmpty)
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
