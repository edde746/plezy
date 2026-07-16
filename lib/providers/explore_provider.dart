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

/// A row of the Explore tab: the catalog row id plus its rendering hub.
typedef ExploreRowHub = ({CatalogRowId row, MediaHub hub});

/// Owns the Explore tab's data: one [CatalogPage] per row of the active
/// [CatalogSource], converted to [MediaHub]s so the existing shelf stack
/// renders them.
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
            (
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

    final rows = source.supportedRows;
    Object? firstError;
    final results = await Future.wait([
      for (final row in rows)
        source.fetchRow(row, limit: rowLimit).then<CatalogPage?>((page) => page).catchError((Object e) {
          appLogger.w('Explore: ${source.id.name} row ${row.name} failed', error: e);
          firstError ??= e;
          return null;
        }),
    ]);
    if (isDisposed || generation != _generation) return;

    final fetched = <CatalogRowId, CatalogPage>{
      for (var i = 0; i < rows.length; i++)
        if (results[i] case final CatalogPage page) rows[i]: page,
    };
    // A debounced watchlist-row refresh that landed while this load was in
    // flight covered later mutations than our page — keep the fresher one.
    if (_watchlistRowFetchedEpoch > mutationEpochAtStart) {
      fetched.remove(CatalogRowId.watchlist);
    }

    if (fetched.isEmpty) {
      // Nothing succeeded: keep stale rows if any (they beat an error flash),
      // otherwise surface the failure. A null message falls back to the
      // localized empty-state text in the screen.
      if (_rows.isEmpty) {
        _state = ExploreLoadState.error;
        _errorMessage = firstError?.toString();
      } else {
        _state = ExploreLoadState.loaded;
      }
    } else {
      // Failed rows keep their previous page.
      _rows = {..._rows, ...fetched};
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

  /// Full item list for a row's View All grid, paging past the shelf cap.
  Future<List<MediaItem>> loadAllForRow(CatalogRowId row) async {
    final source = _source;
    if (source == null) return const [];
    final items = <MediaItem>[];
    var page = 1;
    while (true) {
      final res = await source.fetchRow(row, page: page, limit: viewAllPageLimit);
      items.addAll([for (final item in res.items) item.toMediaItem()]);
      if (!res.hasMore) break;
      if (page >= viewAllMaxPages) {
        appLogger.w('Explore: ${row.name} View All truncated at ${items.length} items ($page pages)');
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
    _rows = {};
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
    try {
      final page = await source.fetchRow(CatalogRowId.watchlist, limit: rowLimit);
      if (isDisposed || generation != _generation) return;
      _rows = {..._rows, CatalogRowId.watchlist: page};
      _rowsEpoch++;
      _watchlistRowFetchedEpoch = coveredEpoch;
      safeNotifyListeners();
      if (_watchlistMutationEpoch > coveredEpoch) {
        // Mutations that arrived while this pass was in flight coalesced
        // into it but aren't reflected in its page — go around once more.
        _scheduleWatchlistRefresh();
      } else {
        // Fully caught up: a still-pending debounce would only refetch the
        // same state.
        _watchlistRefreshTimer?.cancel();
      }
    } catch (e) {
      appLogger.w('Explore: watchlist row refresh failed', error: e);
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
