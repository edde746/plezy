import 'dart:async';

import 'package:flutter/widgets.dart';

import '../media/media_item.dart';
import '../utils/app_logger.dart';

/// Debounced free-text media search shared by the main search screen and the
/// catalog (Explore) search screen: text controller + focus nodes, a 500ms
/// debounce, a generation guard against out-of-order responses, in-flight
/// invalidation when the text diverges from the query being fetched, and the
/// loading/failed/empty state flags the screens render from.
///
/// Implementations override [performSearchQuery]; everything else (including
/// controller/node disposal) is owned here.
mixin DebouncedMediaSearch<T extends StatefulWidget> on State<T> {
  static const Duration searchDebounceDuration = Duration(milliseconds: 500);

  late final TextEditingController searchController = TextEditingController();
  late final FocusNode searchFocusNode = FocusNode(debugLabel: '${searchDebugLabel}Input');
  late final FocusNode firstResultFocusNode = FocusNode(debugLabel: '${searchDebugLabel}FirstResult');

  /// Plain restartable timer instead of rate_limiter's Debounce: that one
  /// times its trailing edge with DateTime.now(), which never advances under
  /// the widget-test fake clock, so the debounce would be untestable.
  Timer? _debounceTimer;

  List<MediaItem> searchResults = [];
  bool isSearching = false;
  bool hasSearched = false;
  bool lastSearchFailed = false;
  String lastSearchedQuery = '';

  int _searchGeneration = 0;
  String? _inFlightQuery;
  bool _showedClearButton = false;
  String _lastObservedText = '';

  /// Names the focus nodes and log lines.
  String get searchDebugLabel => widget.runtimeType.toString();

  /// Run the actual search. Thrown errors flip [lastSearchFailed].
  Future<List<MediaItem>> performSearchQuery(String query);

  /// A failed search was applied to the state (e.g. show a snackbar).
  void onSearchError(Object error) {}

  /// A successful search was applied to the state.
  void onSearchCompleted(String query, List<MediaItem> results) {}

  /// The field was cleared and the state reset.
  void onSearchCleared() {}

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    firstResultFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    // The controller also notifies on selection/composing changes (e.g. the
    // focus gain after an external text set writes a collapsed selection); a
    // selection-only notification mid-flight would re-arm the debounce and
    // re-run the identical query against the servers.
    final text = searchController.text;
    if (text == _lastObservedText) return;
    _lastObservedText = text;
    final query = text.trim();

    // The clear affordance tracks text emptiness; without this rebuild it
    // only appeared when a search landed ~500ms later.
    if (query.isNotEmpty != _showedClearButton) {
      _showedClearButton = query.isNotEmpty;
      setState(() {});
    }

    if (query.isEmpty) {
      _debounceTimer?.cancel();
      _searchGeneration++;
      _inFlightQuery = null;
      setState(() {
        searchResults = [];
        hasSearched = false;
        isSearching = false;
        lastSearchFailed = false;
        lastSearchedQuery = '';
      });
      onSearchCleared();
      return;
    }

    if (query == lastSearchedQuery) {
      // Reverted to what's already shown: the pending debounce and any
      // in-flight pass for the intermediate text must not land afterwards.
      _debounceTimer?.cancel();
      if (_invalidateStaleInFlight(query)) setState(() => isSearching = false);
      return;
    }

    _invalidateStaleInFlight(query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(searchDebounceDuration, () => runSearch(query));
  }

  /// An in-flight search for text the field no longer shows can only land
  /// wrong; kill it via the generation. Returns true when one was dropped.
  bool _invalidateStaleInFlight(String current) {
    if (_inFlightQuery == null || _inFlightQuery == current) return false;
    _searchGeneration++;
    _inFlightQuery = null;
    return true;
  }

  /// Run [query] now, bypassing the debounce (submit, external refresh).
  Future<void> runSearch(String query) async {
    if (!mounted || query.isEmpty) return;
    final generation = ++_searchGeneration;
    _inFlightQuery = query;
    setState(() {
      isSearching = true;
      hasSearched = true;
      lastSearchFailed = false;
    });
    try {
      final results = await performSearchQuery(query);
      if (!mounted || generation != _searchGeneration) return;
      _inFlightQuery = null;
      setState(() {
        searchResults = results;
        isSearching = false;
        lastSearchedQuery = query;
      });
      onSearchCompleted(query, results);
    } catch (e) {
      appLogger.w('$searchDebugLabel: search failed', error: e);
      if (!mounted || generation != _searchGeneration) return;
      _inFlightQuery = null;
      setState(() {
        searchResults = [];
        isSearching = false;
        lastSearchFailed = true;
        lastSearchedQuery = query;
      });
      onSearchError(e);
    }
  }

  /// OSK "Search" / hardware Enter on TV: jump to results, or force the
  /// pending search to run now.
  void handleSearchSubmit() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    if (searchResults.isNotEmpty && !isSearching && query == lastSearchedQuery) {
      firstResultFocusNode.requestFocus();
      return;
    }
    if ((_debounceTimer?.isActive ?? false) || !isSearching) {
      _debounceTimer?.cancel();
      runSearch(query);
    }
    // else: the in-flight search already covers the current text.
  }
}
