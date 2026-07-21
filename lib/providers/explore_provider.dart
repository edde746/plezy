import 'dart:async';

import 'package:flutter/foundation.dart';

import '../i18n/strings.g.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/catalog/catalog_source.dart';
import '../services/trackers/future_coalescer.dart';
import '../utils/app_logger.dart';
import 'catalog_sources_provider.dart';

enum ExploreLoadState { initial, loading, loaded, error }

/// One rendered Explore shelf, backed by either a fixed catalog row or a
/// provider-defined hub.
class ExploreRowHub {
  final CatalogRowId? row;
  final String? providerHubId;
  final MediaHub hub;

  const ExploreRowHub.catalogRow({required CatalogRowId this.row, required this.hub}) : providerHubId = null;

  const ExploreRowHub.providerHub({required String this.providerHubId, required this.hub}) : row = null;
}

/// Owns the Explore tab's fixed rows and provider-defined hubs, converted to
/// [MediaHub]s so the existing shelf stack renders them.
///
/// Lives inside the profile-keyed provider subtree. Listens to
/// [CatalogSourcesProvider] for the active source (connect/disconnect/switch)
/// and to the source's watchlist changes so the Watchlist row stays current
/// after mutations from anywhere in the app.
class ExploreProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// Rows reload when the tab is shown after this long.
  static const Duration staleAfter = Duration(minutes: 15);
  static const int rowLimit = 25;
  static const int viewAllPageLimit = 100;
  static const int viewAllMaxPages = 3;

  /// Watchlist mutations notify optimistically before the API call finishes;
  /// the row refetch waits out the burst so it reads settled server state.
  static const Duration _watchlistRefreshDelay = Duration(seconds: 1);

  ExploreProvider(this._catalogSources) {
    _catalogSources.addListener(_onSourcesChanged);
    _source = _catalogSources.activeSource;
    _source?.watchlistChanges.addListener(_onWatchlistChanged);
  }

  final CatalogSourcesProvider _catalogSources;
  CatalogSource? _source;

  Map<CatalogRowId, CatalogPage> _rows = {};
  List<CatalogHub> _providerHubs = const [];
  ExploreLoadState _state = ExploreLoadState.initial;
  String? _errorMessage;
  DateTime? _loadedAt;
  final FutureCoalescer<void> _loadCoalescer = FutureCoalescer();
  int _generation = 0;
  Timer? _watchlistRefreshTimer;

  // Watchlist-row freshness: every membership change bumps the mutation
  // epoch; a successful row refetch records which epoch it covered. A tab
  // re-shown with uncovered mutations refetches immediately — the debounced
  // timer alone can lose the race when the user navigates back quickly.
  int _watchlistMutationEpoch = 0;
  int _watchlistRowFetchedEpoch = 0;
  int _watchlistHubRetryEpoch = -1;
  final FutureCoalescer<void> _watchlistRefreshCoalescer = FutureCoalescer();

  List<ExploreRowHub>? _hubsCache;
  (int, String)? _hubsCacheKey;
  int _rowsEpoch = 0;

  CatalogSource? get activeSource => _source;

  ExploreLoadState get state => _state;

  bool get isLoading => _state == ExploreLoadState.initial || _state == ExploreLoadState.loading;

  /// Raw load failure (unlocalized); the screen wraps it for display.
  String? get errorMessage => _errorMessage;

  /// Non-empty rows of the active source in display order. Memoized on row
  /// content (and one localized string, so a locale change busts the cache).
  List<ExploreRowHub> get rowHubs {
    final source = _source;
    if (source == null) return const [];
    final key = (_rowsEpoch, rowTitle(CatalogRowId.watchlist));
    if (_hubsCache != null && key == _hubsCacheKey) return _hubsCache!;
    final hubs = <ExploreRowHub>[
      for (final row in source.supportedRows)
        if (_rows[row] case final CatalogPage page)
          if (page.items.isNotEmpty)
            ExploreRowHub.catalogRow(
              row: row,
              hub: MediaHub(
                id: 'explore:${source.id.name}:${row.name}',
                identifier: 'explore.${row.name}',
                title: rowTitle(row),
                type: 'mixed',
                items: [for (final item in page.items) item.toMediaItem()],
                size: page.items.length,
                more: page.hasMore,
              ),
            ),
      for (final providerHub in _providerHubs)
        if (providerHub.page.items.isNotEmpty)
          ExploreRowHub.providerHub(
            providerHubId: providerHub.id,
            hub: MediaHub(
              id: 'explore:${source.id.name}:hub:${providerHub.id}',
              identifier: 'explore.hub.${providerHub.id}',
              title: providerHub.title,
              type: 'mixed',
              items: [for (final item in providerHub.page.items) item.toMediaItem()],
              size: providerHub.page.items.length,
              more: providerHub.page.hasMore,
            ),
          ),
    ];
    _hubsCache = hubs;
    _hubsCacheKey = key;
    return hubs;
  }

  static String rowTitle(CatalogRowId row) => switch (row) {
    CatalogRowId.watchlist => t.explore.rows.watchlist,
    CatalogRowId.recommendedMovies => t.explore.rows.recommendedMovies,
    CatalogRowId.recommendedShows => t.explore.rows.recommendedShows,
    CatalogRowId.trendingMovies => t.explore.rows.trendingMovies,
    CatalogRowId.trendingShows => t.explore.rows.trendingShows,
    CatalogRowId.popularMovies => t.explore.rows.popularMovies,
    CatalogRowId.popularShows => t.explore.rows.popularShows,
    CatalogRowId.trendingAnime => t.explore.rows.trendingAnime,
    CatalogRowId.suggestedAnime => t.explore.rows.suggestedAnime,
    CatalogRowId.airingAnime => t.explore.rows.airingAnime,
    CatalogRowId.popularAnime => t.explore.rows.popularAnime,
    CatalogRowId.trending => t.explore.rows.trending,
    CatalogRowId.upcomingMovies => t.explore.rows.upcomingMovies,
    CatalogRowId.upcomingShows => t.explore.rows.upcomingShows,
  };

  /// Load if never loaded, after an error, or when the content has gone
  /// stale. Called on first build and every time the tab is shown.
  void ensureFresh() {
    if (_source == null) return;
    if (_state == ExploreLoadState.initial || _state == ExploreLoadState.error) {
      unawaited(load());
      return;
    }
    final loadedAt = _loadedAt;
    if (loadedAt != null && DateTime.now().difference(loadedAt) > staleAfter) {
      unawaited(load());
      return;
    }
    if (_watchlistRowFetchedEpoch < _watchlistMutationEpoch) {
      unawaited(_refreshWatchlistRow());
    }
  }

  /// Full reload of every supported row (one request per row). Concurrent
  /// calls coalesce into the in-flight pass; a source switch resets the
  /// coalescer (see [_onSourcesChanged]) so the new source's load starts
  /// instead of joining the doomed one.
  Future<void> load() => _loadCoalescer.run(_loadOnce);

  Future<void> _loadOnce() async {
    // Yield so a load() kicked off during build can't notify mid-build.
    await null;
    if (isDisposed) return;
    final source = _source;
    if (source == null) return;
    final generation = _generation;
    final mutationEpochAtStart = _watchlistMutationEpoch;

    _state = ExploreLoadState.loading;
    _errorMessage = null;
    safeNotifyListeners();

    final fetched = <CatalogRowId, CatalogPage>{};
    List<CatalogHub>? fetchedProviderHubs;
    Object? firstError;
    final CatalogHubSource? hubSource = source is CatalogHubSource ? source as CatalogHubSource : null;
    await Future.wait<void>([
      for (final row in source.supportedRows)
        () async {
          try {
            fetched[row] = await source.fetchRow(row, limit: rowLimit);
          } catch (e) {
            appLogger.w('Explore: ${source.id.name} row ${row.name} failed', error: e);
            firstError ??= e;
          }
        }(),
      if (hubSource != null)
        () async {
          try {
            fetchedProviderHubs = await hubSource.fetchHubs(limit: rowLimit);
          } catch (e) {
            appLogger.w('Explore: ${source.id.name} provider hubs failed', error: e);
            firstError ??= e;
          }
        }(),
    ]);
    if (isDisposed || generation != _generation) return;

    // A debounced watchlist refresh that landed while this load was in
    // flight covered later mutations than both the watchlist page and Plex's
    // watchlist-derived hubs — keep the fresher versions.
    if (_watchlistRowFetchedEpoch > mutationEpochAtStart) {
      fetched.remove(CatalogRowId.watchlist);
      fetchedProviderHubs = null;
    }

    if (fetched.isEmpty && (fetchedProviderHubs == null || (fetchedProviderHubs!.isEmpty && firstError != null))) {
      // Nothing succeeded: keep stale rows if any (they beat an error flash),
      // otherwise surface the failure. A null message falls back to the
      // localized empty-state text in the screen.
      if (_rows.isEmpty && _providerHubs.isEmpty) {
        _state = ExploreLoadState.error;
        _errorMessage = firstError?.toString();
      } else {
        _state = ExploreLoadState.loaded;
      }
    } else {
      // Failed rows and hubs keep their previous content.
      _rows = {..._rows, ...fetched};
      if (fetchedProviderHubs case final hubs?) _providerHubs = hubs;
      _state = ExploreLoadState.loaded;
      _loadedAt = DateTime.now();
      _rowsEpoch++;
      if (fetched.containsKey(CatalogRowId.watchlist) && mutationEpochAtStart > _watchlistRowFetchedEpoch) {
        _watchlistRowFetchedEpoch = mutationEpochAtStart;
      }
    }
    // Mutations that landed while the load was in flight aren't reflected in
    // the page we just stored — schedule the debounced catch-up ourselves
    // (the mutation-time notification skips rows that aren't loaded yet).
    if (_rows.containsKey(CatalogRowId.watchlist) && _watchlistRowFetchedEpoch < _watchlistMutationEpoch) {
      _scheduleWatchlistRefresh();
    }
    safeNotifyListeners();
  }

  /// Full item list for a fixed row's View All grid.
  Future<List<MediaItem>> loadAllForRow(CatalogRowId row) async {
    final source = _source;
    if (source == null) return const [];
    return _loadAllPages(row.name, (page) => source.fetchRow(row, page: page, limit: viewAllPageLimit));
  }

  /// Full item list for either a fixed row or a provider-defined hub.
  Future<List<MediaItem>> loadAllForHub(ExploreRowHub rowHub) async {
    if (rowHub.row case final row?) return loadAllForRow(row);
    final source = _source;
    final hubId = rowHub.providerHubId;
    if (source is! CatalogHubSource || hubId == null) return rowHub.hub.items;
    final hubSource = source as CatalogHubSource;
    return _loadAllPages(hubId, (page) => hubSource.fetchHub(hubId, page: page, limit: viewAllPageLimit));
  }

  Future<List<MediaItem>> _loadAllPages(String label, Future<CatalogPage> Function(int page) fetchPage) async {
    final items = <MediaItem>[];
    var page = 1;
    while (true) {
      final result = await fetchPage(page);
      items.addAll([for (final item in result.items) item.toMediaItem()]);
      if (!result.hasMore) break;
      if (page >= viewAllMaxPages) {
        appLogger.w('Explore: $label View All truncated at ${items.length} items ($page pages)');
        break;
      }
      page++;
    }
    return items;
  }

  void _onSourcesChanged() {
    final next = _catalogSources.activeSource;
    if (identical(next, _source)) return;
    _source?.watchlistChanges.removeListener(_onWatchlistChanged);
    _source = next;
    _source?.watchlistChanges.addListener(_onWatchlistChanged);
    _generation++;
    _watchlistRefreshTimer?.cancel();
    // Detach any in-flight passes for the old source: their generation guard
    // already discards their results, but the new source's load must not
    // coalesce into them (that left the tab stuck on the loading state).
    _loadCoalescer.reset();
    _watchlistRefreshCoalescer.reset();
    _watchlistMutationEpoch = 0;
    _watchlistRowFetchedEpoch = 0;
    _watchlistHubRetryEpoch = -1;
    _rows = {};
    _providerHubs = const [];
    _loadedAt = null;
    _errorMessage = null;
    _state = ExploreLoadState.initial;
    _rowsEpoch++;
    safeNotifyListeners();
    if (next != null) unawaited(load());
  }

  void _onWatchlistChanged() {
    // Always bump: a mutation during the initial full load has no row to
    // patch yet, but the load's completion checks this epoch to catch up.
    _watchlistMutationEpoch++;
    if (!_rows.containsKey(CatalogRowId.watchlist)) return;
    _scheduleWatchlistRefresh();
  }

  void _scheduleWatchlistRefresh() {
    _watchlistRefreshTimer?.cancel();
    _watchlistRefreshTimer = Timer(_watchlistRefreshDelay, () => unawaited(_refreshWatchlistRow()));
  }

  Future<void> _refreshWatchlistRow() => _watchlistRefreshCoalescer.run(_refreshWatchlistRowOnce);

  Future<void> _refreshWatchlistRowOnce() async {
    final source = _source;
    if (source == null || isDisposed) return;
    final generation = _generation;
    final coveredEpoch = _watchlistMutationEpoch;
    CatalogPage? fetchedPage;
    List<CatalogHub>? fetchedProviderHubs;
    final CatalogHubSource? hubSource = source is CatalogHubSource ? source as CatalogHubSource : null;
    var providerHubRefreshFailed = false;
    await Future.wait<void>([
      () async {
        try {
          fetchedPage = await source.fetchRow(CatalogRowId.watchlist, limit: rowLimit);
        } catch (e) {
          appLogger.w('Explore: watchlist row refresh failed', error: e);
        }
      }(),
      if (hubSource != null)
        () async {
          try {
            fetchedProviderHubs = await hubSource.fetchHubs(limit: rowLimit);
          } catch (e) {
            appLogger.w('Explore: ${source.id.name} provider hub refresh failed', error: e);
          }
        }(),
    ]);
    providerHubRefreshFailed = hubSource != null && fetchedProviderHubs == null;
    if (isDisposed || generation != _generation) return;
    if (fetchedPage == null && fetchedProviderHubs == null) return;

    if (fetchedPage case final page?) {
      _rows = {..._rows, CatalogRowId.watchlist: page};
      if (!providerHubRefreshFailed) {
        _watchlistRowFetchedEpoch = coveredEpoch;
        _watchlistHubRetryEpoch = -1;
      }
    }
    if (fetchedProviderHubs case final hubs?) _providerHubs = hubs;
    _rowsEpoch++;
    safeNotifyListeners();

    if (fetchedPage == null) return;
    if (providerHubRefreshFailed) {
      // One automatic retry per mutation epoch avoids leaving derived hubs
      // stale without hammering an unavailable endpoint indefinitely.
      if (_watchlistHubRetryEpoch != coveredEpoch) {
        _watchlistHubRetryEpoch = coveredEpoch;
        _scheduleWatchlistRefresh();
      }
    } else if (_watchlistMutationEpoch > coveredEpoch) {
      // Mutations that arrived during this pass need one more refresh.
      _scheduleWatchlistRefresh();
    } else {
      // Fully caught up: a still-pending debounce would only refetch the same
      // state.
      _watchlistRefreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _catalogSources.removeListener(_onSourcesChanged);
    _source?.watchlistChanges.removeListener(_onWatchlistChanged);
    _watchlistRefreshTimer?.cancel();
    super.dispose();
  }
}
