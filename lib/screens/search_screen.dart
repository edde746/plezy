import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../exceptions/media_server_exceptions.dart';
import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../discovery/discovery_choice.dart';
import '../media/catalog_item_ref.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_item_merge.dart';
import '../media/media_person.dart';
import '../media/search_hit.dart';
import '../mixins/debounced_media_search.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/refreshable.dart';
import '../models/catalog/catalog_item.dart';
import '../models/catalog/catalog_labels.dart';
import '../models/catalog/catalog_metadata.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/seerr_account_provider.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/data_aggregation_service.dart';
import '../services/settings_service.dart';
import '../sources/publication_shelf.dart';
import '../sources/source_controller.dart';
import '../sources/source_models.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/media_server_http_client.dart';
import '../utils/search_relevance.dart';
import '../widgets/app_icon.dart';
import '../widgets/catalog_source_logo.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/search_input_field.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/focusable_tab_chip.dart';
import '../widgets/person_search_row.dart';
import '../widgets/seerr_request_sheet.dart';
import '../utils/focus_utils.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';
import 'sources/source_detail_screen.dart';
import 'sources/source_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with
        Refreshable,
        ManualRefreshable,
        FullRefreshable,
        SearchInputFocusable,
        FocusableTab,
        MountedSetStateMixin,
        DebouncedMediaSearch<SearchScreen, SearchHit> {
  String? _focusResultsForQuery;
  final _tvTextInputController = TvTextInputController();
  AbortController? _activeSearchAbort;
  ({String query, SearchAggregationResult result, List<MediaItem> seerr, List<SourceEntry> sourceFiles})?
  _pendingSearchOutcome;

  /// Filter over the current results: everything, one media kind, or only
  /// people. Chips and the filtered views derive from [_searchCandidates] and
  /// [_searchPeople] — the pre-rank pools behind the ranked [searchResults] —
  /// so a kind ranked out of the "All" top-N still gets a chip, and selecting
  /// a chip shows everything the servers returned for it.
  _SearchFilter _selectedFilter = const _AllResults();
  List<MediaItem> _searchCandidates = const [];
  List<MediaPerson> _searchPeople = const [];
  List<MediaKind> _candidateKinds = const [];
  List<SearchHit>? _filteredResults;
  List<SourceEntry> _sourceFileResults = const [];

  /// Titles the connected Seerr instance found for the query that the media
  /// servers do not already have, as catalog stand-ins. They trail the
  /// library hits in every view (never ranked into them) so a title that is
  /// not on the server can still be found, and requested, from Search.
  List<MediaItem> _seerrResults = const [];
  late final FocusNode _allChipFocusNode = FocusNode(debugLabel: 'SearchKindChipAll');
  late final FocusNode _peopleChipFocusNode = FocusNode(debugLabel: 'SearchPeopleChip');
  final Map<MediaKind, FocusNode> _kindChipFocusNodes = {};

  HiddenLibrariesProvider? _hiddenLibraries;
  Set<String> _lastSeenHiddenKeys = const {};

  @override
  void initState() {
    super.initState();
    FocusUtils.requestFocusAfterBuild(this, searchFocusNode);
    unawaited(_bindHiddenLibraries());
  }

  @override
  void dispose() {
    _hiddenLibraries?.removeListener(_onHiddenLibrariesChanged);
    _allChipFocusNode.dispose();
    _peopleChipFocusNode.dispose();
    for (final node in _kindChipFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Re-run the visible query when a library is hidden or unhidden while
  /// results are on screen. The listener is attached only after the provider
  /// has hydrated, so its initial load notification cannot race the first
  /// query — which awaits that same hydration — into running twice.
  Future<void> _bindHiddenLibraries() async {
    final hiddenLibraries = context.read<HiddenLibrariesProvider>();
    await hiddenLibraries.ensureInitialized();
    if (!mounted) return;
    _lastSeenHiddenKeys = Set.of(hiddenLibraries.hiddenLibraryKeys);
    _hiddenLibraries = hiddenLibraries..addListener(_onHiddenLibrariesChanged);
  }

  void _onHiddenLibrariesChanged() {
    final hiddenLibraries = _hiddenLibraries;
    if (hiddenLibraries == null || !mounted) return;
    final currentKeys = hiddenLibraries.hiddenLibraryKeys;
    if (currentKeys.length == _lastSeenHiddenKeys.length && currentKeys.containsAll(_lastSeenHiddenKeys)) {
      return;
    }
    _lastSeenHiddenKeys = Set.of(currentKeys);
    final query = searchController.text.trim();
    if (query.isEmpty || !hasSearched) return;
    unawaited(runSearch(query));
  }

  @override
  String get searchDebugLabel => 'Search';

  @override
  Future<List<SearchHit>> performSearchQuery(String query) async {
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    final sourceFilesFuture = _searchRemoteSourceFiles(query);
    final seerrFuture = _searchSeerr(query);
    if (!multiServerProvider.hasConnectedServers) {
      final sourceFiles = await sourceFilesFuture;
      final seerr = await seerrFuture ?? const <MediaItem>[];
      if (!mounted) return const [];
      if (sourceFiles.isEmpty && seerr.isEmpty) throw const _SearchUnavailableException();
      const emptyResult = (
        hits: <SearchHit>[],
        candidates: <MediaItem>[],
        people: <MediaPerson>[],
        succeededServerIds: <String>{},
        cancelledServerIds: <String>{},
        failedServerIds: <String>{},
      );
      _pendingSearchOutcome = (query: query, result: emptyResult, seerr: seerr, sourceFiles: sourceFiles);
      return [for (final item in seerr) MediaSearchHit(item)];
    }

    // Hidden-library keys must be hydrated before the first query, or a cold
    // start would filter nothing. Read before any await: the profile subtree
    // can be torn down mid-search.
    final hiddenLibraries = context.read<HiddenLibrariesProvider>();
    await hiddenLibraries.ensureInitialized();
    if (!mounted) return const [];

    final abort = AbortController();
    _activeSearchAbort = abort;
    try {
      final result = await multiServerProvider.aggregationService.searchAcrossServers(
        query,
        hiddenLibraryKeys: hiddenLibraries.hiddenLibraryKeys,
        abort: abort,
      );
      abort.throwIfAborted();
      final sourceFiles = await sourceFilesFuture;
      final seerr = await seerrFuture ?? const <MediaItem>[];
      abort.throwIfAborted();
      if (result.succeededServerIds.isEmpty &&
          result.failedServerIds.isNotEmpty &&
          sourceFiles.isEmpty &&
          seerr.isEmpty) {
        throw const _SearchUnavailableException();
      }
      if (result.succeededServerIds.isEmpty &&
          result.cancelledServerIds.isNotEmpty &&
          sourceFiles.isEmpty &&
          seerr.isEmpty) {
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.cancelled,
          message: 'Search was cancelled before any server completed',
        );
      }
      _pendingSearchOutcome = (query: query, result: result, seerr: seerr, sourceFiles: sourceFiles);
      return [...result.hits, for (final item in seerr) MediaSearchHit(item)];
    } finally {
      if (identical(_activeSearchAbort, abort)) _activeSearchAbort = null;
    }
  }

  /// Cloud files join global Search after they have been browsed once. The
  /// source index stores stable file metadata only; signed playback links are
  /// refreshed by SourceDetailScreen when a result is opened.
  Future<List<SourceEntry>> _searchRemoteSourceFiles(String query) async {
    final sources = context.read<SourceController?>();
    if (sources == null || sources.blocked || query.trim().isEmpty) return const [];
    try {
      await sources.ready;
      if (!mounted || sources.blocked || sources.profileId == null) return const [];
      final profile = sources.profileId!;
      final epoch = sources.generation;
      final remoteSources = sources.sources.where((source) => source.kind == FileSourceKind.remoteCloud).toList();
      if (remoteSources.isEmpty) return const [];
      final pages = await Future.wait([
        for (final source in remoteSources)
          sources.repository.entriesPage(
            profile,
            source: source.id,
            shelf: PublicationShelf.videos,
            query: query,
            limit: 12,
          ),
      ]);
      if (!mounted || sources.blocked || !sources.current(epoch) || sources.profileId != profile) return const [];
      final connectedSourceIds = sources.sources
          .where((source) => source.kind == FileSourceKind.remoteCloud)
          .map((source) => source.id)
          .toSet();
      final seen = <String>{};
      final result = [
        for (final page in pages)
          for (final entry in page.items)
            if (connectedSourceIds.contains(entry.sourceId) &&
                entry.kind == SourceItemKind.video &&
                !entry.unavailable &&
                seen.add(entry.key))
              entry,
      ];
      final normalizedQuery = normalizeSearchText(query);
      result.sort((a, b) {
        final aTitle = normalizeSearchText(a.displayTitle), bTitle = normalizeSearchText(b.displayTitle);
        final aRank = aTitle == normalizedQuery
            ? 0
            : aTitle.startsWith(normalizedQuery)
            ? 1
            : 2;
        final bRank = bTitle == normalizedQuery
            ? 0
            : bTitle.startsWith(normalizedQuery)
            ? 1
            : 2;
        return aRank == bRank ? aTitle.compareTo(bTitle) : aRank.compareTo(bRank);
      });
      return result.take(48).toList(growable: false);
    } on Object {
      // The server and Seerr search paths remain useful if the local source
      // index is unavailable or is being torn down with a profile change.
      return const [];
    }
  }

  /// Upper bound on how long a slow Seerr instance can hold back the
  /// library results it is shown alongside.
  static const Duration _seerrSearchTimeout = Duration(seconds: 5);

  /// The connected Seerr source's titles for [query] that its media server
  /// does not report as available — available ones are already among the
  /// library hits. Null when Seerr is not connected, the lookup failed, or it
  /// outlived [_seerrSearchTimeout].
  Future<List<MediaItem>?> _searchSeerr(String query) async {
    final seerr = context.read<CatalogSourcesProvider?>()?.seerrSource;
    if (seerr == null) return null;
    try {
      final items = await seerr.search(query).timeout(_seerrSearchTimeout);
      return [
        for (final item in items)
          if (_isMissingFromLibrary(item)) item.toMediaItem(),
      ];
    } catch (error) {
      appLogger.w('Search: Seerr lookup failed', error: error);
      return null;
    }
  }

  static bool _isMissingFromLibrary(CatalogItem item) {
    final state = item.serverState;
    return state?.availability != CatalogAvailability.available &&
        state?.availability4k != CatalogAvailability.available;
  }

  /// Re-read the Seerr rows of the query on screen after a request, so the
  /// row's action turns into the request's status. Library rows stay as
  /// they are.
  Future<void> _refreshSeerrResults() async {
    final query = lastSearchedQuery;
    if (query.isEmpty) return;
    final fresh = await _searchSeerr(query);
    if (fresh == null || !mounted || isSearching || query != lastSearchedQuery) return;
    setState(() {
      searchResults = [
        for (final hit in searchResults)
          if (hit is! MediaSearchHit || !hit.item.isCatalogItem) hit,
        for (final item in fresh) MediaSearchHit(item),
      ];
      _seerrResults = fresh;
      _candidateKinds = _kindsIn([..._searchCandidates, ..._seerrResults]);
      if (!_hasCandidatesFor(_selectedFilter)) _selectedFilter = const _AllResults();
      _filteredResults = _rankFilteredResults(_selectedFilter, query);
    });
  }

  @override
  void onSearchInvalidated() {
    _activeSearchAbort?.abort();
    _activeSearchAbort = null;
    _pendingSearchOutcome = null;
  }

  @override
  void onSearchError(Object error) {
    _focusResultsForQuery = null;
    _pendingSearchOutcome = null;
    _resetFilter();
    final message = error is _SearchUnavailableException
        ? t.errors.searchUnavailable
        : t.errors.searchFailed(error: error);
    showErrorSnackBar(context, message);
  }

  @override
  void onSearchCleared() {
    _focusResultsForQuery = null;
    _pendingSearchOutcome = null;
    _resetFilter();
  }

  @override
  void onSearchCompleted(String query, List<SearchHit> results) {
    final outcome = _pendingSearchOutcome;
    _pendingSearchOutcome = null;
    final matchedOutcome = outcome != null && outcome.query == query ? outcome : null;
    final matched = matchedOutcome?.result;

    // Committed alongside the results the pending setState renders (build has
    // not run yet): the pre-rank pools the filter chips derive from. A selected
    // filter survives a refined query as long as it still has candidates;
    // otherwise it falls back to "All".
    _searchCandidates =
        matched?.candidates ??
        [
          for (final hit in results)
            if (hit case MediaSearchHit(:final item) when !item.isCatalogItem) item,
        ];
    _seerrResults =
        matchedOutcome?.seerr ??
        [
          for (final hit in results)
            if (hit case MediaSearchHit(:final item) when item.isCatalogItem) item,
        ];
    final serverVideoIdentities = <String>{
      for (final item in _searchCandidates) ...canonicalVideoIdentitiesForMediaItem(item),
    };
    _sourceFileResults = [
      for (final entry in matchedOutcome?.sourceFiles ?? const <SourceEntry>[])
        if (!canonicalVideoIdentitiesForSourceEntry(entry).any(serverVideoIdentities.contains)) entry,
    ];
    _searchPeople =
        matched?.people ??
        [
          for (final hit in results)
            if (hit case PersonSearchHit(:final person)) person,
        ];
    _candidateKinds = _kindsIn([..._searchCandidates, ..._seerrResults]);
    if (!_hasCandidatesFor(_selectedFilter)) _selectedFilter = const _AllResults();
    _filteredResults = _rankFilteredResults(_selectedFilter, query);

    if (matched != null && matched.failedServerIds.isNotEmpty) {
      showAppSnackBar(context, t.messages.searchPartialResults);
    }

    if (_focusResultsForQuery == null || _focusResultsForQuery != query) return;
    _focusResultsForQuery = null;
    if (results.isEmpty && _sourceFileResults.isEmpty) return;
    if (searchController.text.trim() != query) return; // user kept editing
    FocusUtils.requestFocusAfterBuild(this, firstResultFocusNode);
  }

  /// OSK "Search" / hardware Enter on TV additionally focuses the results
  /// when the forced search lands.
  @override
  void handleSearchSubmit() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    if (_sourceFileResults.isNotEmpty && searchResults.isEmpty && !isSearching && query == lastSearchedQuery) {
      FocusUtils.requestFocusAfterBuild(this, firstResultFocusNode);
      return;
    }
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

  /// Cmd+R / Ctrl+R re-runs the query currently on screen; `runSearch` no-ops
  /// on an empty field.
  @override
  void manualRefresh() => refresh();

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
    _tvTextInputController.closeTextInput();
    if (trimmed.isEmpty) return;

    // Land focus on the (visible) input immediately so the D-pad remote is
    // never stranded on the hidden previous tab — while the search is in
    // flight, when it fails, and when it returns nothing.
    _tvTextInputController.focusInputWithoutOpening();

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
      // A fresh Jellyfin `fetchItem` carries no library field, and a
      // library-less row would lose its label (#1970); keep the identity
      // and library context the search stamped on the original row.
      final merged = mergeFetchedMediaItem(fetched: updated, fallbackServerId: ServerId(serverId), existing: source);
      // The same row can sit in the ranked "All" list, the filtered view,
      // and the candidate pool; refresh every copy so a later chip switch
      // cannot resurrect the stale row.
      var replaced = _replaceHitByGlobalKey(searchResults, source.globalKey, merged);
      replaced = _replaceByGlobalKey(_searchCandidates, source.globalKey, merged) || replaced;
      final filtered = _filteredResults;
      if (filtered != null) {
        replaced = _replaceHitByGlobalKey(filtered, source.globalKey, merged) || replaced;
      }
      if (replaced) setState(() {});
    } catch (e) {
      appLogger.d('Search item refresh skipped for ${source.globalKey}', error: e);
    }
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  /// Chip display order. `folder`/`unknown` are never search kinds, and
  /// `clip`/`photo` rows (Plex extras, Jellyfin/Emby home and music videos)
  /// stay reachable under "All" without a chip of their own.
  static const List<MediaKind> _kindFilterOrder = [
    MediaKind.movie,
    MediaKind.show,
    MediaKind.season,
    MediaKind.episode,
    MediaKind.artist,
    MediaKind.album,
    MediaKind.track,
    MediaKind.collection,
    MediaKind.playlist,
  ];

  static List<MediaKind> _kindsIn(List<MediaItem> candidates) {
    if (candidates.isEmpty) return const [];
    final present = {for (final item in candidates) item.kind};
    return [
      for (final kind in _kindFilterOrder)
        if (present.contains(kind)) kind,
    ];
  }

  static bool _replaceByGlobalKey(List<MediaItem> items, String globalKey, MediaItem replacement) {
    final index = items.indexWhere((item) => item.globalKey == globalKey);
    if (index == -1) return false;
    items[index] = replacement;
    return true;
  }

  static bool _replaceHitByGlobalKey(List<SearchHit> hits, String globalKey, MediaItem replacement) {
    final index = hits.indexWhere((hit) => hit is MediaSearchHit && hit.globalKey == globalKey);
    if (index == -1) return false;
    hits[index] = MediaSearchHit(replacement);
    return true;
  }

  /// The list the results sliver renders: the aggregation's ranked list, or
  /// the selected filter's pool re-ranked with the full display budget.
  List<SearchHit> get _visibleResults => _filteredResults ?? searchResults;

  /// Chip order: All, the media kinds present, then People.
  List<_SearchFilter> get _filterOptions => [
    const _AllResults(),
    for (final kind in _candidateKinds) _KindResults(kind),
    if (_searchPeople.isNotEmpty) const _PeopleResults(),
  ];

  /// "All" plus a single other option (one kind, or only people) has nothing
  /// to filter.
  bool get _showFilterChips => _candidateKinds.length + (_searchPeople.isEmpty ? 0 : 1) > 1;

  bool _hasCandidatesFor(_SearchFilter filter) => switch (filter) {
    _AllResults() => true,
    _KindResults(:final kind) => _candidateKinds.contains(kind),
    _PeopleResults() => _searchPeople.isNotEmpty,
  };

  /// The selected filter's pool re-ranked with the full display budget, or
  /// null for "All" (the aggregation's ranked list).
  List<SearchHit>? _rankFilteredResults(_SearchFilter filter, String query) {
    switch (filter) {
      case _AllResults():
        return null;
      case _KindResults(:final kind):
        final ofKind = [
          for (final candidate in _searchCandidates)
            if (candidate.kind == kind) candidate,
        ];
        return [
          for (final item in rankMediaSearchResults(ofKind, query, limit: defaultMediaSearchLimit))
            MediaSearchHit(item),
          for (final item in _seerrResults)
            if (item.kind == kind) MediaSearchHit(item),
        ];
      case _PeopleResults():
        return [
          for (final person in rankPeopleSearchResults(_searchPeople, query, limit: defaultMediaSearchLimit))
            PersonSearchHit(person),
        ];
    }
  }

  void _selectFilter(_SearchFilter filter) {
    if (filter == _selectedFilter) return;
    setState(() {
      _selectedFilter = filter;
      _filteredResults = _rankFilteredResults(filter, lastSearchedQuery);
    });
  }

  void _resetFilter() {
    _selectedFilter = const _AllResults();
    _searchCandidates = const [];
    _searchPeople = const [];
    _candidateKinds = const [];
    _filteredResults = null;
    _seerrResults = const [];
    _sourceFileResults = const [];
  }

  FocusNode _chipFocusNode(_SearchFilter filter) => switch (filter) {
    _AllResults() => _allChipFocusNode,
    _KindResults(:final kind) => _kindChipFocusNodes.putIfAbsent(
      kind,
      () => FocusNode(debugLabel: 'SearchKindChip_${kind.id}'),
    ),
    _PeopleResults() => _peopleChipFocusNode,
  };

  /// D-pad landing point for the chip row: the chip that is currently active.
  void _focusFilterChips() => _chipFocusNode(_selectedFilter).requestFocus();

  void _focusFirstResult() {
    if (_visibleResults.isNotEmpty) firstResultFocusNode.requestFocus();
  }

  String _filterLabel(_SearchFilter filter) => switch (filter) {
    _AllResults() => t.libraries.groupings.all,
    _KindResults(:final kind) => _kindFilterLabel(kind),
    _PeopleResults() => t.search.people,
  };

  String _kindFilterLabel(MediaKind kind) => switch (kind) {
    MediaKind.movie => t.libraries.groupings.movies,
    MediaKind.show => t.libraries.groupings.shows,
    MediaKind.season => t.libraries.groupings.seasons,
    MediaKind.episode => t.libraries.groupings.episodes,
    MediaKind.artist => t.libraries.groupings.artists,
    MediaKind.album => t.libraries.groupings.albums,
    MediaKind.track => t.libraries.groupings.tracks,
    MediaKind.collection => t.libraries.tabs.collections,
    MediaKind.playlist => t.libraries.tabs.playlists,
    // Unreachable: excluded from _kindFilterOrder.
    MediaKind.clip || MediaKind.photo || MediaKind.folder || MediaKind.unknown => kind.id,
  };

  Widget _buildFilterChips() {
    // Chips trap RIGHT to keep focus inside the strip (see
    // FocusableChipStateMixin), so left/right neighbors are wired explicitly,
    // like every other tab-chip strip.
    final filters = _filterOptions;
    return SliverToBoxAdapter(
      child: Padding(
        // The search field's own bottom padding provides the gap above; the
        // results sliver below shrinks its top padding to match (16/16 visual
        // rhythm around the strip instead of the default 24/24).
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabChipStrip(
          children: [
            for (final (index, filter) in filters.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              FocusableTabChip(
                label: _filterLabel(filter),
                isSelected: _selectedFilter == filter,
                focusNode: _chipFocusNode(filter),
                onSelect: () => _selectFilter(filter),
                onNavigateLeft: index == 0
                    ? _navigateToSidebar
                    : () => _chipFocusNode(filters[index - 1]).requestFocus(),
                onNavigateRight: index < filters.length - 1
                    ? () => _chipFocusNode(filters[index + 1]).requestFocus()
                    : null,
                onNavigateUp: focusSearchInput,
                onNavigateDown: _focusFirstResult,
                onBack: _navigateToSidebar,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestFromSeerr(SeerrCatalogSource seerr, CatalogItem item, int tmdbId) async {
    await showSeerrRequestSheet(context, source: seerr, kind: item.kind, tmdbId: tmdbId, title: item.title);
    if (mounted) await _refreshSeerrResults();
  }

  /// The trailing end of a Seerr row: the status of a request already in
  /// flight, otherwise a Request button when the user may request this kind.
  /// The button is off the D-pad path, so TV requests through the row's
  /// detail screen or context menu instead.
  Widget? _seerrRowAction(BuildContext context, CatalogItem? item, SeerrCatalogSource? seerr) {
    if (item == null) return null;
    if (item.serverState?.request
        case final request? &&
            (CatalogRequestState.pending || CatalogRequestState.approved || CatalogRequestState.processing)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          requestStateLabel(request, is4k: false),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tokens(context).textMuted),
        ),
      );
    }
    final tmdbId = item.ids.tmdb;
    if (seerr == null || tmdbId == null || !seerr.canRequest(item.kind) || PlatformDetector.isTV()) return null;
    return IconButton(
      tooltip: t.seerr.request,
      icon: const AppIcon(Symbols.download_rounded, fill: 1, size: 22),
      onPressed: () => unawaited(_requestFromSeerr(seerr, item, tmdbId)),
    );
  }

  /// A Seerr title the servers do not have: the same row as a library hit
  /// (a tap opens the catalog detail screen), plus its request action. The
  /// first one heads the Seerr section.
  Widget _buildSeerrRow(
    BuildContext context,
    MediaItem item, {
    required SeerrCatalogSource? seerr,
    required bool showHeader,
    required bool isFirst,
    required VoidCallback? onNavigateUp,
  }) {
    Widget row = FocusableMediaCard(
      key: Key(item.globalKey),
      item: item,
      viewModeOverride: ViewMode.list,
      disableScale: true,
      focusNode: isFirst ? firstResultFocusNode : null,
      onNavigateLeft: _navigateToSidebar,
      onNavigateUp: onNavigateUp,
    );
    if (_seerrRowAction(context, item.catalogItem, seerr) case final action?) {
      row = Row(
        children: [
          Expanded(child: row),
          const SizedBox(width: 8),
          action,
        ],
      );
    }
    if (!showHeader) return row;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, isFirst ? 0 : 16, 8, 8),
          child: Row(
            children: [
              const CatalogSourceLogo(CatalogSourceId.seerr, size: 18),
              const SizedBox(width: 8),
              Text(t.seerr.title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        row,
      ],
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final multiServer = context.watch<MultiServerProvider>();
    final libraries = context.watch<LibrariesProvider>();
    // Subscriptions for the Seerr rows' Request action: the source itself
    // (disconnect) and the signed-in user's request permissions.
    final seerr = context.select<CatalogSourcesProvider?, SeerrCatalogSource?>((sources) => sources?.seerrSource);
    context.select<SeerrAccountProvider?, int?>((account) => account?.permissions);
    final showServerName = multiServer.totalServerCount > 1;
    final showChips = _showFilterChips;
    final visible = _visibleResults;
    final firstSeerrIndex = visible.indexWhere((hit) => hit is MediaSearchHit && hit.item.isCatalogItem);
    final showSourceFiles = _sourceFileResults.isNotEmpty && _selectedFilter is! _PeopleResults;
    final sourceFilesStart = visible.length;
    return buildResultsSliver(
      childCount: visible.length + (showSourceFiles ? _sourceFileResults.length + 1 : 0),
      // Half the default top padding when the chip strip sits directly above:
      // the strip already separates results from the search field.
      padding: showChips ? const EdgeInsets.fromLTRB(16, 8, 16, 16) : const EdgeInsets.all(16),
      (context, index) {
        if (showSourceFiles && index >= sourceFilesStart) {
          if (index == sourceFilesStart) {
            return Padding(
              padding: EdgeInsets.fromLTRB(8, visible.isEmpty ? 0 : 16, 8, 8),
              child: Row(
                children: [
                  const AppIcon(Symbols.cloud_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(t.streaming.cloudFiles, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            );
          }
          final fileIndex = index - sourceFilesStart - 1;
          final entry = _sourceFileResults[fileIndex];
          final source = context
              .read<SourceController?>()
              ?.sources
              .where((candidate) => candidate.id == entry.sourceId)
              .firstOrNull;
          final firstResult = visible.isEmpty && fileIndex == 0;
          return SourceTile(
            key: ValueKey(entry.key),
            title: entry.displayTitle,
            subtitle: _remoteSourceSubtitle(source),
            icon: Symbols.movie_rounded,
            index: fileIndex,
            count: _sourceFileResults.length,
            focusNode: firstResult ? firstResultFocusNode : null,
            onNavigateUp: firstResult ? (_showFilterChips ? _focusFilterChips : focusSearchInput) : null,
            onNavigateLeft: _navigateToSidebar,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceDetailScreen(entry: entry))),
          );
        }
        final isFirst = index == 0;
        final onNavigateUp = isFirst ? (showChips ? _focusFilterChips : focusSearchInput) : null;
        return switch (visible[index]) {
          MediaSearchHit(:final item) when item.isCatalogItem => _buildSeerrRow(
            context,
            item,
            seerr: seerr,
            showHeader: index == firstSeerrIndex,
            isFirst: isFirst,
            onNavigateUp: onNavigateUp,
          ),
          MediaSearchHit(:final item) => FocusableMediaCard(
            key: Key(item.globalKey),
            item: item,
            viewModeOverride: ViewMode.list,
            disableScale: true,
            focusNode: isFirst ? firstResultFocusNode : null,
            onRefresh: updateItem,
            onListRefresh: refresh,
            onNavigateLeft: _navigateToSidebar,
            onNavigateUp: onNavigateUp,
            showServerName: showServerName,
            libraryName: libraries.libraryLabelFor(item),
          ),
          PersonSearchHit(:final person) => PersonSearchRow(
            key: Key(person.globalKey),
            person: person,
            focusNode: isFirst ? firstResultFocusNode : null,
            showServerName: showServerName,
            onNavigateLeft: _navigateToSidebar,
            onNavigateUp: onNavigateUp,
          ),
        };
      },
    );
  }

  String _remoteSourceSubtitle(FileSource? source) {
    if (source == null) return t.streaming.cloudFiles;
    final service = switch (source.options['service']) {
      'realDebrid' => t.streaming.realDebrid,
      'allDebrid' => t.streaming.allDebrid,
      'premiumize' => t.streaming.premiumize,
      'torbox' => t.streaming.torbox,
      _ => t.streaming.cloudFiles,
    };
    return '${source.name} · $service';
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
              child: SearchInputField(
                controller: searchController,
                focusNode: searchFocusNode,
                debugLabel: searchDebugLabel,
                hintText: t.search.hint,
                tvTextInputController: _tvTextInputController,
                onNavigateLeft: _navigateToSidebar,
                onNavigateDown: (searchResults.isNotEmpty || _sourceFileResults.isNotEmpty) && !isSearching
                    ? (_showFilterChips ? _focusFilterChips : firstResultFocusNode.requestFocus)
                    : null,
                onEditingComplete: PlatformDetector.isTV() ? handleSearchSubmit : null,
                onBack: () {
                  if (searchController.text.isNotEmpty) {
                    searchController.clear();
                  } else {
                    _navigateToSidebar();
                  }
                },
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
            else if (searchResults.isEmpty && _sourceFileResults.isEmpty)
              SliverFillRemaining(
                child: StateMessageWidget(
                  message: t.messages.noResultsFound,
                  subtitle: t.search.tryDifferentTerm,
                  icon: Symbols.search_off_rounded,
                  iconSize: 80,
                ),
              )
            else ...[
              if (_showFilterChips) _buildFilterChips(),
              _buildResultsList(context),
            ],
          ],
        ),
      ),
    );
  }
}

final class _SearchUnavailableException implements Exception {
  const _SearchUnavailableException();
}

/// One chip of the search results filter strip.
sealed class _SearchFilter {
  const _SearchFilter();
}

final class _AllResults extends _SearchFilter {
  const _AllResults();
}

final class _KindResults extends _SearchFilter {
  final MediaKind kind;

  const _KindResults(this.kind);

  @override
  bool operator ==(Object other) => other is _KindResults && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

final class _PeopleResults extends _SearchFilter {
  const _PeopleResults();
}
