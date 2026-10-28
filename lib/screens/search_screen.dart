import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../exceptions/media_server_exceptions.dart';
import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../media/catalog_item_ref.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_item_merge.dart';
import '../media/media_person.dart';
import '../media/search_hit.dart';
import '../integrations/integration_contracts.dart';
import '../integrations/integration_identity_store.dart';
import '../mixins/debounced_media_search.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/refreshable.dart';
import '../models/catalog/catalog_item.dart';
import '../models/catalog/catalog_labels.dart';
import '../models/catalog/catalog_metadata.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/seerr_account_provider.dart';
import '../services/catalog/catalog_source.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/data_aggregation_service.dart';
import '../services/settings_service.dart';
import '../sources/source_controller.dart';
import '../sources/source_models.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/focus_utils.dart';
import '../utils/media_server_http_client.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
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
  ({
    String query,
    SearchAggregationResult? result,
    List<MediaItem> seerr,
    List<MediaItem> catalogs,
    List<SourceEntry> files,
    bool partial,
    bool fileSearchFailed,
  })?
  _pendingSearchOutcome;
  SourceController? _sourceController;
  int? _sourceGeneration;
  List<SourceEntry> _sourceCandidates = const [];
  final Map<SourceItemKind, FocusNode> _sourceChipFocusNodes = {};

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

  /// Titles the connected Seerr instance found for the query that the media
  /// servers do not already have, as catalog stand-ins. They trail the
  /// library hits in every view (never ranked into them) so a title that is
  /// not on the server can still be found, and requested, from Search.
  List<MediaItem> _seerrResults = const [];
  List<MediaItem> _catalogResults = const [];
  final Map<String, _CatalogSearchCacheEntry> _catalogSearchCache = {};
  final Map<String, _CatalogSearchSourceHealth> _catalogSearchHealth = {};
  final IntegrationIdentityStore _identityStore = IntegrationIdentityStore();
  CatalogSourcesProvider? _catalogSourcesProvider;
  String _catalogSourceSignature = '';
  late final FocusNode _allChipFocusNode = FocusNode(debugLabel: 'SearchKindChipAll');
  late final FocusNode _peopleChipFocusNode = FocusNode(debugLabel: 'SearchPeopleChip');
  final Map<MediaKind, FocusNode> _kindChipFocusNodes = {};
  final Map<CatalogSourceId, FocusNode> _catalogChipFocusNodes = {};

  static const Duration _catalogSearchTimeout = Duration(seconds: 5);
  static const Duration _catalogSearchCacheTtl = Duration(seconds: 30);
  static const Duration _catalogSearchFailureCacheTtl = Duration(seconds: 5);
  static const int _catalogSearchLimit = 12;
  static const int _catalogSearchCacheLimit = 96;

  HiddenLibrariesProvider? _hiddenLibraries;
  Set<String> _lastSeenHiddenKeys = const {};

  @override
  void initState() {
    super.initState();
    FocusUtils.requestFocusAfterBuild(this, searchFocusNode);
    unawaited(_bindHiddenLibraries());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sources = context.read<SourceController?>();
    if (!identical(sources, _sourceController)) {
      _sourceController?.removeListener(_onSourceScopeChanged);
      _sourceController = sources;
      _sourceGeneration = sources?.generation;
      sources?.addListener(_onSourceScopeChanged);
    }
    final catalogs = context.read<CatalogSourcesProvider?>();
    if (!identical(catalogs, _catalogSourcesProvider)) {
      _catalogSourcesProvider?.removeListener(_onCatalogSourcesChanged);
      _catalogSourcesProvider = catalogs;
      _catalogSourceSignature = _catalogSignature(catalogs);
      catalogs?.addListener(_onCatalogSourcesChanged);
    }
  }

  static String _catalogSignature(CatalogSourcesProvider? catalogs) =>
      (catalogs?.connectedSources ?? const <CatalogSource>[])
          .map((source) => '${source.id.name}:${identityHashCode(source)}')
          .join('|');

  void _onCatalogSourcesChanged() {
    final catalogs = _catalogSourcesProvider;
    final signature = _catalogSignature(catalogs);
    if (signature == _catalogSourceSignature) return;
    _catalogSourceSignature = signature;
    _catalogSearchCache.clear();
    _catalogSearchHealth.clear();
    final query = searchController.text.trim();
    if (query.isNotEmpty && hasSearched) unawaited(runSearch(query));
  }

  void _onSourceScopeChanged() {
    if (!mounted || _sourceGeneration == _sourceController?.generation) return;
    _sourceGeneration = _sourceController?.generation;
    // Profile changes must invalidate even a completed Files-only search.
    fullRefresh();
  }

  @override
  void dispose() {
    _sourceController?.removeListener(_onSourceScopeChanged);
    _catalogSourcesProvider?.removeListener(_onCatalogSourcesChanged);
    for (final node in _sourceChipFocusNodes.values) {
      node.dispose();
    }
    _hiddenLibraries?.removeListener(_onHiddenLibrariesChanged);
    _allChipFocusNode.dispose();
    _peopleChipFocusNode.dispose();
    for (final node in _kindChipFocusNodes.values) {
      node.dispose();
    }
    for (final node in _catalogChipFocusNodes.values) {
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
    final multiServer = context.read<MultiServerProvider>();
    final hidden = context.read<HiddenLibrariesProvider>();
    final sources = context.read<SourceController?>();
    final abort = AbortController();
    _activeSearchAbort = abort;
    final hadServers = multiServer.hasConnectedServers;
    final profileId = context.read<ActiveProfileProvider?>()?.activeId;

    // Every leg settles independently. A broken server must not discard
    // playable indexed files, and a locked Files profile must not hide titles.
    final filesFuture = _searchIndex(sources, query);
    final seerrFuture = _searchSeerr(query);
    final catalogsFuture = _searchConnectedCatalogs(query);
    final crosswalksFuture = profileId == null
        ? Future.value(const <IdentityCrosswalk>[])
        : _loadIdentityCrosswalks(profileId);
    final serversFuture = () async {
      if (!hadServers) return null;
      try {
        await hidden.ensureInitialized();
        abort.throwIfAborted();
        return await multiServer.aggregationService.searchAcrossServers(
          query,
          hiddenLibraryKeys: hidden.hiddenLibraryKeys,
          abort: abort,
        );
      } catch (_) {
        abort.throwIfAborted();
        return null;
      }
    }();
    try {
      final result = await serversFuture;
      final files = await filesFuture;
      final seerr = await seerrFuture;
      final catalogSearch = await catalogsFuture;
      final crosswalks = await crosswalksFuture;
      abort.throwIfAborted();
      if (!mounted) return const [];
      if (profileId != context.read<ActiveProfileProvider?>()?.activeId) return const [];
      final serverSucceeded = result?.succeededServerIds.isNotEmpty ?? false;
      if (!serverSucceeded && !files.available && seerr == null && !catalogSearch.succeeded) {
        if (result != null && result.failedServerIds.isEmpty && result.cancelledServerIds.isNotEmpty) {
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.cancelled,
            message: 'Search was cancelled before any source completed',
          );
        }
        throw const _SearchUnavailableException();
      }
      final partial =
          (hadServers &&
              (result == null || result.failedServerIds.isNotEmpty || result.cancelledServerIds.isNotEmpty)) ||
          catalogSearch.failed;
      final catalogItems = _deduplicateConnectedCatalogItems([
        for (final item in catalogSearch.items)
          if (!_matchesLocalCatalogItem(item, [...?result?.candidates, ...?seerr]) &&
              !_matchesConfirmedCrosswalk(item, [...?result?.candidates, ...?seerr], crosswalks))
            item.toMediaItem(),
      ]);
      _pendingSearchOutcome = (
        query: query,
        result: result,
        seerr: seerr ?? const [],
        catalogs: catalogItems,
        files: files.entries,
        partial: partial,
        fileSearchFailed: files.failed,
      );
      return [
        ...rankSearchHits(
          [...?result?.hits, for (final entry in files.entries) SourceSearchHit(entry)],
          query,
          limit: defaultMediaSearchLimit,
        ),
        for (final item in seerr ?? const <MediaItem>[]) MediaSearchHit(item),
        for (final item in catalogItems) MediaSearchHit(item),
      ];
    } finally {
      if (identical(_activeSearchAbort, abort)) _activeSearchAbort = null;
    }
  }

  Future<({List<CatalogItem> items, bool succeeded, bool failed})> _searchConnectedCatalogs(String query) async {
    final sources = [
      for (final source in _catalogSourcesProvider?.connectedSources ?? const <CatalogSource>[])
        if (source.id != CatalogSourceId.seerr) source,
    ];
    if (sources.isEmpty) {
      return (items: const <CatalogItem>[], succeeded: false, failed: false);
    }
    if (query.trim().runes.length < 2) {
      return (items: const <CatalogItem>[], succeeded: true, failed: false);
    }

    final outcomes = await Future.wait([for (final source in sources) _searchCatalogSource(source, query)]);
    return (
      items: [for (final outcome in outcomes) ...?outcome.items?.take(_catalogSearchLimit)],
      succeeded: outcomes.any((outcome) => !outcome.failed),
      failed: outcomes.any((outcome) => outcome.failed),
    );
  }

  Future<List<IdentityCrosswalk>> _loadIdentityCrosswalks(String profileId) async {
    try {
      return await _identityStore.load(profileId);
    } on Object {
      // A preference-store failure must not take local or provider search down.
      return const [];
    }
  }

  Future<({List<CatalogItem>? items, bool failed})> _searchCatalogSource(CatalogSource source, String query) async {
    final key = '${identityHashCode(source)}:${source.id.name}:${query.trim().toLowerCase()}';
    final sourceKey = '${identityHashCode(source)}:${source.id.name}';
    final now = DateTime.now();
    final cached = _catalogSearchCache[key];
    if (cached != null && now.isBefore(cached.expiresAt)) {
      if (cached.inFlight case final pending?) {
        final result = await pending;
        return (items: result, failed: result == null);
      }
      return (items: cached.items, failed: cached.failed);
    }
    final health = _catalogSearchHealth[sourceKey];
    if (health != null && now.isBefore(health.retryAt)) return (items: null, failed: true);

    _pruneCatalogSearchCache(now);
    final entry = _CatalogSearchCacheEntry();
    final request = () async {
      try {
        return await source.search(query, limit: _catalogSearchLimit).timeout(_catalogSearchTimeout);
      } catch (error) {
        appLogger.w('Search: ${source.id.name} catalog lookup failed (${error.runtimeType})');
        return null;
      }
    }();
    entry
      ..inFlight = request
      ..expiresAt = now.add(_catalogSearchTimeout + const Duration(seconds: 1));
    _catalogSearchCache[key] = entry;
    final result = await request;
    if (identical(_catalogSearchCache[key], entry)) {
      entry
        ..inFlight = null
        ..items = result
        ..failed = result == null
        ..expiresAt = DateTime.now().add(result == null ? _catalogSearchFailureCacheTtl : _catalogSearchCacheTtl);
    }
    if (result == null) {
      (_catalogSearchHealth[sourceKey] ??= _CatalogSearchSourceHealth()).recordFailure(DateTime.now());
    } else {
      _catalogSearchHealth.remove(sourceKey);
    }
    return (items: result, failed: result == null);
  }

  void _pruneCatalogSearchCache(DateTime now) {
    _catalogSearchCache.removeWhere((_, entry) => entry.inFlight == null && !now.isBefore(entry.expiresAt));
    while (_catalogSearchCache.length >= _catalogSearchCacheLimit) {
      _catalogSearchCache.remove(_catalogSearchCache.keys.first);
    }
  }

  static bool _matchesLocalCatalogItem(CatalogItem catalogItem, List<MediaItem> candidates) {
    if (catalogItem.season != null) return false;
    final ids = catalogItem.ids.toExternalIds();
    if (!ids.hasCatalogIds) return false;
    for (final candidate in candidates) {
      if (candidate.kind != catalogItem.kind) continue;
      final candidateIds = candidate.catalogItem?.ids.toExternalIds() ?? _externalIdsFor(candidate);
      if (ids.intersects(candidateIds)) return true;
    }
    return false;
  }

  static bool _matchesConfirmedCrosswalk(
    CatalogItem catalogItem,
    List<MediaItem> candidates,
    List<IdentityCrosswalk> crosswalks,
  ) {
    final catalogRef = _catalogEntityRef(catalogItem);
    if (catalogRef == null) return false;
    for (final candidate in candidates) {
      if (candidate.kind != catalogItem.kind) continue;
      final serverRef = _serverEntityRef(candidate);
      if (serverRef == null) continue;
      if (crosswalks.any((crosswalk) {
        if (crosswalk.method != IdentifierMatchMethod.userConfirmed ||
            crosswalk.relation != EntityRelationKind.sameWork) {
          return false;
        }
        return (_sameEntity(crosswalk.from, catalogRef) && _sameEntity(crosswalk.to, serverRef)) ||
            (_sameEntity(crosswalk.from, serverRef) && _sameEntity(crosswalk.to, catalogRef));
      })) {
        return true;
      }
    }
    return false;
  }

  static IntegrationEntityRef? _catalogEntityRef(CatalogItem item) {
    final kind = _integrationKindForMediaKind(item.kind);
    final entryKey = item.ids.entryKey;
    if (kind == null || entryKey == null || entryKey.trim().isEmpty) return null;
    final nativeId = '${item.kind.id}/$entryKey';
    final reference = IntegrationEntityRef(providerId: item.source.name, nativeId: nativeId, kind: kind);
    return reference.isValid ? reference : null;
  }

  static IntegrationEntityRef? _serverEntityRef(MediaItem item) {
    final kind = _integrationKindForMediaKind(item.kind);
    final serverId = item.serverId;
    if (kind == null || serverId == null || serverId.trim().isEmpty || item.id.trim().isEmpty) return null;
    final reference = IntegrationEntityRef(
      providerId: 'server.${item.backend.id}',
      nativeId: sourceDigest('$serverId\u0000${item.id}'),
      kind: kind,
    );
    return reference.isValid ? reference : null;
  }

  static IntegrationEntityKind? _integrationKindForMediaKind(MediaKind kind) => switch (kind) {
    MediaKind.movie => IntegrationEntityKind.movie,
    MediaKind.show => IntegrationEntityKind.series,
    MediaKind.season => IntegrationEntityKind.season,
    MediaKind.episode => IntegrationEntityKind.episode,
    MediaKind.artist ||
    MediaKind.album ||
    MediaKind.track ||
    MediaKind.collection ||
    MediaKind.playlist ||
    MediaKind.clip ||
    MediaKind.photo ||
    MediaKind.folder ||
    MediaKind.unknown => null,
  };

  static bool _sameEntity(IntegrationEntityRef left, IntegrationEntityRef right) =>
      left.providerId == right.providerId &&
      left.nativeId == right.nativeId &&
      left.kind == right.kind &&
      left.editionId == right.editionId;

  /// A title returned by two connected catalogs is still one exact work for
  /// global Search. Keep the first provider's row, but retain seasons and
  /// entries without globally comparable identifiers rather than guessing.
  static List<MediaItem> _deduplicateConnectedCatalogItems(List<MediaItem> items) {
    final seenByKind = <MediaKind, List<ExternalIds>>{};
    final result = <MediaItem>[];
    for (final media in items) {
      final catalog = media.catalogItem;
      final ids = catalog?.ids.toExternalIds() ?? const ExternalIds();
      if (catalog?.season == null && ids.hasCatalogIds) {
        final seen = seenByKind.putIfAbsent(media.kind, () => []);
        if (seen.any(ids.intersects)) continue;
        seen.add(ids);
      }
      result.add(media);
    }
    return result;
  }

  static ExternalIds _externalIdsFor(MediaItem item) {
    final raw = item.raw;
    if (item is PlexMediaItem) {
      final guids = raw?['Guid'];
      return ExternalIds.fromGuids(
        guids is List ? guids : const [],
      ).fillFrom(ExternalIds.fromLegacyPlexGuid(item.guid));
    }
    final providerIds = raw?['ProviderIds'];
    if (providerIds is! Map) return const ExternalIds();
    return ExternalIds.fromJellyfinProviderIds({
      for (final entry in providerIds.entries)
        if (entry.key is String) entry.key as String: entry.value,
    });
  }

  Future<({List<SourceEntry> entries, bool available, bool failed})> _searchIndex(
    SourceController? sources,
    String query,
  ) async {
    if (sources == null) return (entries: const <SourceEntry>[], available: false, failed: false);
    try {
      final entries = await sources.searchIndex(query);
      return (entries: entries, available: sources.sources.isNotEmpty, failed: false);
    } on SourceException catch (error) {
      return (entries: const <SourceEntry>[], available: false, failed: error.reason != SourceFailure.cancelled);
    } catch (_) {
      return (entries: const <SourceEntry>[], available: false, failed: true);
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
          if (hit is! MediaSearchHit || hit.item.catalogItem?.source != CatalogSourceId.seerr) hit,
        for (final item in fresh) MediaSearchHit(item),
      ];
      _seerrResults = fresh;
      _candidateKinds = _kindsIn([..._searchCandidates, ..._seerrResults, ..._catalogResults]);
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
            if (hit case MediaSearchHit(:final item) when item.catalogItem?.source == CatalogSourceId.seerr) item,
        ];
    _catalogResults =
        matchedOutcome?.catalogs ??
        [
          for (final hit in results)
            if (hit case MediaSearchHit(
              :final item,
            ) when item.catalogItem?.source != null && item.catalogItem?.source != CatalogSourceId.seerr)
              item,
        ];
    _searchPeople =
        matched?.people ??
        [
          for (final hit in results)
            if (hit case PersonSearchHit(:final person)) person,
        ];
    _sourceCandidates = matchedOutcome?.files ?? const [];
    _candidateKinds = _kindsIn([..._searchCandidates, ..._seerrResults, ..._catalogResults]);
    if (!_hasCandidatesFor(_selectedFilter)) _selectedFilter = const _AllResults();
    _filteredResults = _rankFilteredResults(_selectedFilter, query);

    if (matchedOutcome?.partial ?? false) {
      showAppSnackBar(context, t.messages.searchPartialResults);
    } else if (matchedOutcome?.fileSearchFailed ?? false) {
      showAppSnackBar(context, '${t.fileSources.title}: ${t.fileSources.errorUnavailable}');
    }

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
    for (final kind in SourceItemKind.values)
      if (_sourceCandidates.any((entry) => entry.kind == kind)) _SourceKindResults(kind),
    for (final source in CatalogSourceId.values)
      if (_hasCatalogResultsFor(source)) _CatalogSourceResults(source),
    if (_searchPeople.isNotEmpty) const _PeopleResults(),
  ];

  /// "All" plus a single other option (one kind, or only people) has nothing
  /// to filter.
  bool get _showFilterChips => _filterOptions.length > 2;

  bool _hasCandidatesFor(_SearchFilter filter) => switch (filter) {
    _AllResults() => true,
    _KindResults(:final kind) => _candidateKinds.contains(kind),
    _PeopleResults() => _searchPeople.isNotEmpty,
    _SourceKindResults(:final kind) => _sourceCandidates.any((entry) => entry.kind == kind),
    _CatalogSourceResults(:final source) => _hasCatalogResultsFor(source),
  };

  bool _hasCatalogResultsFor(CatalogSourceId source) =>
      _catalogResults.any((item) => item.catalogItem?.source == source) ||
      _seerrResults.any((item) => item.catalogItem?.source == source);

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
          for (final item in _catalogResults)
            if (item.kind == kind) MediaSearchHit(item),
        ];
      case _SourceKindResults(:final kind):
        return rankSearchHits(
          [
            for (final entry in _sourceCandidates)
              if (entry.kind == kind) SourceSearchHit(entry),
          ],
          query,
          limit: defaultMediaSearchLimit,
        );
      case _CatalogSourceResults(:final source):
        return [
          for (final item in _seerrResults)
            if (item.catalogItem?.source == source) MediaSearchHit(item),
          for (final item in _catalogResults)
            if (item.catalogItem?.source == source) MediaSearchHit(item),
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
    _sourceCandidates = const [];
    _candidateKinds = const [];
    _filteredResults = null;
    _seerrResults = const [];
    _catalogResults = const [];
    _catalogSearchCache.clear();
  }

  FocusNode _chipFocusNode(_SearchFilter filter) => switch (filter) {
    _AllResults() => _allChipFocusNode,
    _KindResults(:final kind) => _kindChipFocusNodes.putIfAbsent(
      kind,
      () => FocusNode(debugLabel: 'SearchKindChip_${kind.id}'),
    ),
    _PeopleResults() => _peopleChipFocusNode,
    _SourceKindResults(:final kind) => _sourceChipFocusNodes.putIfAbsent(
      kind,
      () => FocusNode(debugLabel: 'SearchSourceKind_${kind.name}'),
    ),
    _CatalogSourceResults(:final source) => _catalogChipFocusNodes.putIfAbsent(
      source,
      () => FocusNode(debugLabel: 'SearchCatalogSource_${source.name}'),
    ),
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
    _CatalogSourceResults(:final source) => _catalogSourceName(source),
    _SourceKindResults(:final kind) => switch (kind) {
      SourceItemKind.ebook => t.fileSources.ebooks,
      SourceItemKind.audiobook => t.fileSources.audiobooks,
      SourceItemKind.comic => t.fileSources.comics,
      SourceItemKind.music => t.downloads.music,
      SourceItemKind.video => t.fileSources.video,
      SourceItemKind.folder || SourceItemKind.unknown => t.fileSources.title,
    },
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

  String _catalogSourceName(CatalogSourceId id) {
    for (final source in _catalogSourcesProvider?.connectedSources ?? const <CatalogSource>[]) {
      if (source.id == id) return source.displayName;
    }
    return switch (id) {
      CatalogSourceId.plex => 'Plex',
      CatalogSourceId.trakt => 'Trakt',
      CatalogSourceId.mal => 'MyAnimeList',
      CatalogSourceId.anilist => 'AniList',
      CatalogSourceId.simkl => 'Simkl',
      CatalogSourceId.seerr => t.seerr.title,
      CatalogSourceId.mdblist => 'MDBList',
    };
  }

  List<MediaItem> _localMatchCandidates(CatalogItem item) => [
    for (final candidate in _searchCandidates)
      if (candidate.kind == item.kind && candidate.serverId != null && _serverEntityRef(candidate) != null) candidate,
  ];

  Future<void> _matchCatalogItem(CatalogItem remote, List<MediaItem> candidates) async {
    final profileId = context.read<ActiveProfileProvider?>()?.activeId;
    if (profileId == null) return;
    final selected = await showDialog<MediaItem>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.matchScreen.match),
        children: [
          for (final candidate in candidates.take(50))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, candidate),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    [
                      if (candidate.year != null) candidate.year.toString(),
                      candidate.serverName ?? candidate.backend.id,
                    ].join(' · '),
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted || context.read<ActiveProfileProvider?>()?.activeId != profileId) return;
    if (!_searchCandidates.any((candidate) => candidate.globalKey == selected.globalKey) ||
        !context.read<MultiServerProvider>().serverIds.contains(selected.serverId)) {
      showErrorSnackBar(context, t.matchScreen.matchFailed);
      return;
    }
    final from = _catalogEntityRef(remote);
    final to = _serverEntityRef(selected);
    if (from == null || to == null) {
      showErrorSnackBar(context, t.matchScreen.matchFailed);
      return;
    }
    final crosswalk = IdentityCrosswalk(
      id: sourceDigest('${from.providerId}:${from.nativeId}:${to.providerId}:${to.nativeId}'),
      from: from,
      to: to,
      relation: EntityRelationKind.sameWork,
      method: IdentifierMatchMethod.userConfirmed,
      confirmedAt: DateTime.now().toUtc(),
    );
    try {
      await _identityStore.put(profileId, crosswalk);
      if (!mounted || context.read<ActiveProfileProvider?>()?.activeId != profileId) return;
      showAppSnackBar(context, t.matchScreen.matchApplied);
      unawaited(runSearch(searchController.text.trim()));
    } on Object {
      if (mounted && context.read<ActiveProfileProvider?>()?.activeId == profileId) {
        showErrorSnackBar(context, t.matchScreen.matchFailed);
      }
    }
  }

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

  /// A connected catalog result stays attributed to its source. A tap opens
  /// that provider's detail path; only Seerr rows receive a request action.
  Widget _buildCatalogRow(
    BuildContext context,
    MediaItem item, {
    required CatalogSourceId sourceId,
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
    final actions = <Widget>[];
    final catalogItem = item.catalogItem;
    if (sourceId != CatalogSourceId.seerr && catalogItem != null) {
      final localCandidates = _localMatchCandidates(catalogItem);
      if (localCandidates.isNotEmpty) {
        actions.add(
          IconButton(
            tooltip: t.matchScreen.match,
            icon: const AppIcon(Symbols.link_rounded),
            onPressed: () => unawaited(_matchCatalogItem(catalogItem, localCandidates)),
          ),
        );
      }
    }
    final seerrAction = sourceId == CatalogSourceId.seerr ? _seerrRowAction(context, item.catalogItem, seerr) : null;
    if (seerrAction != null) actions.add(seerrAction);
    if (actions.isNotEmpty) {
      row = Row(
        children: [
          Expanded(child: row),
          const SizedBox(width: 8),
          ...actions,
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
              CatalogSourceLogo(sourceId, size: 18),
              const SizedBox(width: 8),
              Text(_catalogSourceName(sourceId), style: Theme.of(context).textTheme.titleSmall),
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
    final firstCatalogIndexBySource = <CatalogSourceId, int>{};
    for (var index = 0; index < visible.length; index++) {
      if (visible[index] case MediaSearchHit(:final item)) {
        final sourceId = item.catalogItem?.source;
        if (sourceId != null) firstCatalogIndexBySource.putIfAbsent(sourceId, () => index);
      }
    }
    return buildResultsSliver(
      childCount: visible.length,
      // Half the default top padding when the chip strip sits directly above:
      // the strip already separates results from the search field.
      padding: showChips ? const EdgeInsets.fromLTRB(16, 8, 16, 16) : const EdgeInsets.all(16),
      (context, index) {
        final isFirst = index == 0;
        final onNavigateUp = isFirst ? (showChips ? _focusFilterChips : focusSearchInput) : null;
        return switch (visible[index]) {
          MediaSearchHit(:final item) when item.isCatalogItem => _buildCatalogRow(
            context,
            item,
            sourceId: item.catalogItem!.source,
            seerr: seerr,
            showHeader: index == firstCatalogIndexBySource[item.catalogItem!.source],
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
          SourceSearchHit(:final entry) => SourceTile(
            key: Key('source:${entry.key}'),
            title: entry.displayTitle,
            subtitle: [
              t.fileSources.title,
              for (final source in _sourceController?.sources ?? const <FileSource>[])
                if (source.id == entry.sourceId) source.name,
              if (entry.author.isNotEmpty) entry.author,
              if (entry.series.isNotEmpty) entry.series,
            ].join(' · '),
            icon: sourceItemIcon(entry.kind),
            focusNode: isFirst ? firstResultFocusNode : null,
            onNavigateLeft: _navigateToSidebar,
            onNavigateUp: onNavigateUp,
            onTap: () => unawaited(
              Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SourceDetailScreen(entry: entry))),
            ),
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
                onNavigateDown: searchResults.isNotEmpty && !isSearching
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
            else if (searchResults.isEmpty)
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

final class _CatalogSearchCacheEntry {
  DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  List<CatalogItem>? items;
  bool failed = false;
  Future<List<CatalogItem>?>? inFlight;
}

final class _CatalogSearchSourceHealth {
  int failures = 0;
  DateTime retryAt = DateTime.fromMillisecondsSinceEpoch(0);

  void recordFailure(DateTime now) {
    failures++;
    final seconds = switch (failures) {
      1 => 1,
      2 => 2,
      3 => 4,
      4 => 8,
      5 => 16,
      _ => 32,
    };
    retryAt = now.add(Duration(seconds: seconds));
  }
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

final class _SourceKindResults extends _SearchFilter {
  final SourceItemKind kind;

  const _SourceKindResults(this.kind);

  @override
  bool operator ==(Object other) => other is _SourceKindResults && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

final class _CatalogSourceResults extends _SearchFilter {
  final CatalogSourceId source;

  const _CatalogSourceResults(this.source);

  @override
  bool operator ==(Object other) => other is _CatalogSourceResults && other.source == source;

  @override
  int get hashCode => source.hashCode;
}
