import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../focus/focusable_text_field.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../mixins/controller_disposer_mixin.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/refreshable.dart';
import '../models/seerr/seerr_search_result.dart';
import '../providers/multi_server_provider.dart';
import '../providers/seerr_session_provider.dart';
import '../services/seerr/seerr_constants.dart';
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
import 'seerr/seerr_detail_screen.dart';
import 'seerr/seerr_tab_root.dart';
import 'seerr/widgets/not_in_library_banner.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with
        Refreshable,
        FullRefreshable,
        SearchInputFocusable,
        FocusableTab,
        ControllerDisposerMixin,
        MountedSetStateMixin {
  late final _searchController = createTextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  final _firstResultFocusNode = FocusNode(debugLabel: 'SearchFirstResult');
  List<MediaItem> _searchResults = [];
  List<SeerrSearchResult> _seerrResults = const [];
  bool _isSearching = false;
  bool _isSearchingSeerr = false;
  bool _hasSearched = false;
  late final Debounce _searchDebounce;
  String _lastSearchedQuery = '';
  String? _focusResultsForQuery;
  int _seerrSearchGeneration = 0;

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
    if (!mounted) return;

    final query = _searchController.text;

    if (query.trim().isEmpty) {
      _searchDebounce.cancel();
      _focusResultsForQuery = null;
      setStateIfMounted(() {
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
    if (!mounted) return;

    if (query.trim().isEmpty) {
      setStateIfMounted(() {
        _searchResults = [];
        _seerrResults = const [];
        _hasSearched = false;
      });
      return;
    }

    setStateIfMounted(() {
      _isSearching = true;
      _hasSearched = true;
    });

    // Kick off the Seerr search in parallel — its result lands independently
    // of the library search so the primary list isn't gated on Seerr being
    // reachable.
    unawaited(_performSeerrSearch(query));

    try {
      if (!mounted) return;
      final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      final neutral = await multiServerProvider.aggregationService.searchAcrossServers(query);
      if (mounted) {
        setStateIfMounted(() {
          _searchResults = neutral;
          _isSearching = false;
          _lastSearchedQuery = query.trim();
        });
        _maybeFocusResultsAfterSubmit(query, neutral);
      }
    } catch (e) {
      _focusResultsForQuery = null;
      if (mounted) {
        setStateIfMounted(() {
          _isSearching = false;
        });
        showErrorSnackBar(context, t.errors.searchFailed(error: e));
      }
    }
  }

  Future<void> _performSeerrSearch(String query) async {
    final session = Provider.of<SeerrSessionProvider>(context, listen: false);
    final client = session.client;
    if (client == null) {
      setStateIfMounted(() {
        _seerrResults = const [];
        _isSearchingSeerr = false;
      });
      return;
    }
    final generation = ++_seerrSearchGeneration;
    setStateIfMounted(() {
      _isSearchingSeerr = true;
      _seerrResults = const [];
    });
    try {
      final page = await client.search(query);
      if (!mounted || generation != _seerrSearchGeneration) return;
      // Skip persons — the user wants requestable media here.
      final filtered = page.results.where((r) => r is! SeerrPersonResult).toList(growable: false);
      setStateIfMounted(() {
        _seerrResults = filtered;
        _isSearchingSeerr = false;
      });
    } catch (e) {
      appLogger.d('Seerr search (secondary) failed: $e');
      if (!mounted || generation != _seerrSearchGeneration) return;
      setStateIfMounted(() => _isSearchingSeerr = false);
    }
  }

  void _openSeerrDetail(SeerrSearchResult r) {
    final title = switch (r) {
      SeerrMovieResult(:final title) => title,
      SeerrTvResult(:final name) => name,
      SeerrPersonResult(:final name) => name,
    };
    final poster = switch (r) {
      SeerrMovieResult(:final posterPath) => posterPath,
      SeerrTvResult(:final posterPath) => posterPath,
      SeerrPersonResult(:final profilePath) => profilePath,
    };
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeerrDetailScreen(
          tmdbId: r.id,
          mediaType: r.mediaType,
          initialTitle: title,
          initialPosterPath: poster,
        ),
      ),
    );
  }

  /// OSK "Search" / hardware Enter on TV: jump to results, or force the
  /// search to run now and focus results when it lands.
  void _handleSearchSubmit() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (_searchResults.isNotEmpty && !_isSearching && query == _lastSearchedQuery.trim()) {
      _firstResultFocusNode.requestFocus();
      return;
    }

    _focusResultsForQuery = query;
    if (_searchDebounce.isPending || !_isSearching) {
      _searchDebounce.cancel();
      _performSearch(query);
    }
    // else: the in-flight search already covers the current text; its
    // completion focuses the results.
  }

  void _maybeFocusResultsAfterSubmit(String query, List<MediaItem> results) {
    if (_focusResultsForQuery == null || _focusResultsForQuery != query.trim()) return;
    _focusResultsForQuery = null;
    if (results.isEmpty) return;
    if (_searchController.text.trim() != query.trim()) return; // user kept editing
    FocusUtils.requestFocusAfterBuild(this, _firstResultFocusNode);
  }

  @override
  void refresh() {
    if (!mounted) return;
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Focus the search input field
  @override
  void focusSearchInput() {
    if (!mounted) return;
    _searchFocusNode.requestFocus();
  }

  @override
  void focusActiveTabIfReady() {
    if (!mounted) return;
    _searchFocusNode.requestFocus();
  }

  /// Set the search query externally (e.g. from companion remote)
  @override
  void setSearchQuery(String query) {
    if (!mounted) return;
    _searchController.text = query;
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    if (!mounted) return;
    appLogger.d('SearchScreen.fullRefresh() called - clearing search and reloading');
    // Clear search results and search text for new profile
    _searchController.clear();
    _focusResultsForQuery = null;
    setStateIfMounted(() {
      _searchResults.clear();
      _isSearching = false;
      _hasSearched = false;
      _lastSearchedQuery = '';
    });
  }

  void updateItem(String _) {
    if (!mounted) return;
    // Trigger a refresh of the search to get updated metadata
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context, listen: false)?.focusSidebar();
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
            onRefresh: updateItem,
            onListRefresh: () => updateItem(item.id),
            onNavigateLeft: _navigateToSidebar,
            onNavigateUp: index == 0 ? focusSearchInput : null,
            showServerName: showServerName,
          );
        }, childCount: _searchResults.length),
      ),
    );
  }

  void _openSeerrSearch(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SeerrTabRoot(initialSearchQuery: query)),
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
                  onEditingComplete: PlatformDetector.isTV() ? _handleSearchSubmit : null,
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
              LoadingIndicatorBox.sliver
            else if (!_hasSearched)
              SliverFillRemaining(
                child: StateMessageWidget(
                  message: t.search.searchYourMedia,
                  subtitle: t.search.enterTitleActorOrKeyword,
                  icon: Symbols.search_rounded,
                  iconSize: 80,
                ),
              )
            else ...[
              if (_searchResults.isNotEmpty) ...[
                if (_seerrResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      icon: Symbols.video_library_rounded,
                      label: t.search.inYourLibrary,
                    ),
                  ),
                _buildResultsList(context),
              ],
              if (_searchResults.isEmpty && !_isSearchingSeerr && _seerrResults.isEmpty)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: StateMessageWidget(
                          message: t.messages.noResultsFound,
                          subtitle: t.search.tryDifferentTerm,
                          icon: Symbols.search_off_rounded,
                          iconSize: 80,
                        ),
                      ),
                      Consumer<SeerrSessionProvider>(
                        builder: (context, seerr, _) {
                          if (!seerr.hasConfiguredServer) return const SizedBox.shrink();
                          final query = _searchController.text.trim();
                          if (query.isEmpty) return const SizedBox.shrink();
                          return NotInLibraryBanner(
                            query: query,
                            onTap: () => _openSeerrSearch(query),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (_isSearchingSeerr && _seerrResults.isEmpty && _searchResults.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicatorBox())),
                ),
              if (_seerrResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Symbols.playlist_add_check_rounded,
                    label: t.search.fromSeerr,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = _seerrResults[index];
                        return _SeerrSearchRow(result: r, onTap: () => _openSeerrDetail(r));
                      },
                      childCount: _seerrResults.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          AppIcon(icon, fill: 1, size: 18),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _SeerrSearchRow extends StatelessWidget {
  final SeerrSearchResult result;
  final VoidCallback onTap;
  const _SeerrSearchRow({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (result) {
      SeerrMovieResult(:final title) => title,
      SeerrTvResult(:final name) => name,
      SeerrPersonResult(:final name) => name,
    };
    final poster = switch (result) {
      SeerrMovieResult(:final posterPath) => posterPath,
      SeerrTvResult(:final posterPath) => posterPath,
      SeerrPersonResult(:final profilePath) => profilePath,
    };
    final year = switch (result) {
      SeerrMovieResult(:final releaseDate) => (releaseDate != null && releaseDate.length >= 4) ? releaseDate.substring(0, 4) : null,
      SeerrTvResult(:final firstAirDate) => (firstAirDate != null && firstAirDate.length >= 4) ? firstAirDate.substring(0, 4) : null,
      SeerrPersonResult() => null,
    };
    final typeLabel = result.mediaType == 'tv' ? t.seerr.tabs.search : '';
    final posterUrl = SeerrConstants.posterUrl(poster);
    return FocusableWrapper(
      disableScale: true,
      borderRadius: 8,
      descendantsAreFocusable: false,
      autoScroll: true,
      onSelect: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 75,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: posterUrl != null
                      ? Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                        )
                      : Container(color: theme.colorScheme.surfaceContainerHighest),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if ((year ?? '').isNotEmpty || typeLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [year, if (typeLabel.isNotEmpty) typeLabel].whereType<String>().join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
