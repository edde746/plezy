import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/seerr/seerr_request.dart';
import '../services/seerr/seerr_client.dart';
import '../utils/app_logger.dart';

enum SeerrRequestsLoadState { idle, loading, loaded, error }

/// Tiny value type for a cached lookup: TMDB title + poster path for use in
/// the My Requests list (the `/request` endpoint returns neither).
class SeerrRequestSummary {
  final String title;
  final String? posterPath;
  final String? year;
  const SeerrRequestSummary({required this.title, this.posterPath, this.year});
}

/// Owns the "My Requests" list for the active profile. Pull-to-refresh,
/// pagination, optimistic insert on submit, optimistic remove on cancel.
class SeerrRequestsProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  SeerrClient? _client;
  int _bindingGeneration = 0;

  SeerrRequestsLoadState _state = SeerrRequestsLoadState.idle;
  List<SeerrRequest> _requests = const [];
  int _currentPage = 0;
  int _totalPages = 1;
  bool _loadingMore = false;
  String? _errorMessage;

  /// Cache of TMDB summaries (title + poster + year), keyed by
  /// `"$mediaType:$tmdbId"`. Populated lazily by [_hydrateSummaries] after
  /// every successful page load so the list rows can show real titles.
  final Map<String, SeerrRequestSummary> _summaries = {};
  final Set<String> _summaryFetchesInFlight = {};

  SeerrRequestsLoadState get state => _state;
  List<SeerrRequest> get requests => _requests;
  bool get hasMore => _currentPage < _totalPages;
  bool get loadingMore => _loadingMore;
  String? get errorMessage => _errorMessage;
  bool get isBound => _client != null;

  /// Look up a cached TMDB summary for [req]. Returns null when the fetch
  /// hasn't completed (or failed) — the row should fall back to a generic
  /// label in that case.
  SeerrRequestSummary? summaryFor(SeerrRequest req) {
    final tmdbId = req.media?.tmdbId;
    if (tmdbId == null) return null;
    return _summaries['${req.mediaType}:$tmdbId'];
  }

  void bindClient(SeerrClient? client) {
    if (identical(_client, client)) return;
    _bindingGeneration++;
    _client = client;
    _state = SeerrRequestsLoadState.idle;
    _requests = const [];
    _currentPage = 0;
    _totalPages = 1;
    _loadingMore = false;
    _errorMessage = null;
    _summaries.clear();
    _summaryFetchesInFlight.clear();
    safeNotifyListeners();
  }

  Future<void> loadIfNeeded() async {
    if (_state != SeerrRequestsLoadState.idle) return;
    await refresh();
  }

  Future<void> refresh() async {
    final client = _client;
    if (client == null) return;
    final generation = _bindingGeneration;
    _state = SeerrRequestsLoadState.loading;
    _errorMessage = null;
    safeNotifyListeners();
    try {
      final page = await client.getRequests(page: 1, filter: 'all', sort: 'added');
      if (generation != _bindingGeneration || isDisposed) return;
      _state = SeerrRequestsLoadState.loaded;
      _requests = page.results;
      _currentPage = page.page;
      _totalPages = page.pages;
      safeNotifyListeners();
      _hydrateSummaries(page.results, generation);
    } catch (e, st) {
      appLogger.w('Seerr requests refresh failed', error: e, stackTrace: st);
      if (generation != _bindingGeneration || isDisposed) return;
      _state = SeerrRequestsLoadState.error;
      _errorMessage = e.toString();
      safeNotifyListeners();
    }
  }

  Future<void> loadMore() async {
    final client = _client;
    if (client == null || !hasMore || _loadingMore || _state != SeerrRequestsLoadState.loaded) return;
    final generation = _bindingGeneration;
    _loadingMore = true;
    safeNotifyListeners();
    try {
      final page = await client.getRequests(page: _currentPage + 1, filter: 'all', sort: 'added');
      if (generation != _bindingGeneration || isDisposed) return;
      _requests = [..._requests, ...page.results];
      _currentPage = page.page;
      _totalPages = page.pages;
      _loadingMore = false;
      safeNotifyListeners();
      _hydrateSummaries(page.results, generation);
    } catch (e, st) {
      appLogger.w('Seerr requests loadMore failed', error: e, stackTrace: st);
      if (generation != _bindingGeneration || isDisposed) return;
      _loadingMore = false;
      safeNotifyListeners();
    }
  }

  /// Insert a freshly-created request at the top of the list (optimistic
  /// update — caller is responsible for handling submit failures).
  void prependOptimistic(SeerrRequest req) {
    if (isDisposed) return;
    _requests = [req, ..._requests];
    if (_state == SeerrRequestsLoadState.idle) _state = SeerrRequestsLoadState.loaded;
    safeNotifyListeners();
    _hydrateSummaries([req], _bindingGeneration);
  }

  /// Pre-populate the cache with a known title (e.g. right after a successful
  /// request submit when we already have full details from the detail screen).
  /// Saves the round-trip on the very next My-Requests open.
  void cacheSummary({required String mediaType, required int tmdbId, required SeerrRequestSummary summary}) {
    _summaries['$mediaType:$tmdbId'] = summary;
    safeNotifyListeners();
  }

  Future<void> _hydrateSummaries(List<SeerrRequest> reqs, int generation) async {
    final client = _client;
    if (client == null) return;
    for (final req in reqs) {
      final tmdbId = req.media?.tmdbId;
      if (tmdbId == null) continue;
      final key = '${req.mediaType}:$tmdbId';
      if (_summaries.containsKey(key) || _summaryFetchesInFlight.contains(key)) continue;
      _summaryFetchesInFlight.add(key);
      unawaited(_fetchSummary(client, req.mediaType, tmdbId, key, generation));
    }
  }

  Future<void> _fetchSummary(SeerrClient client, String mediaType, int tmdbId, String key, int generation) async {
    try {
      if (mediaType == 'tv') {
        final tv = await client.getTv(tmdbId);
        if (generation != _bindingGeneration || isDisposed) return;
        _summaries[key] = SeerrRequestSummary(
          title: tv.name,
          posterPath: tv.posterPath,
          year: (tv.firstAirDate != null && tv.firstAirDate!.length >= 4) ? tv.firstAirDate!.substring(0, 4) : null,
        );
      } else {
        final movie = await client.getMovie(tmdbId);
        if (generation != _bindingGeneration || isDisposed) return;
        _summaries[key] = SeerrRequestSummary(
          title: movie.title,
          posterPath: movie.posterPath,
          year: (movie.releaseDate != null && movie.releaseDate!.length >= 4)
              ? movie.releaseDate!.substring(0, 4)
              : null,
        );
      }
      safeNotifyListeners();
    } catch (e) {
      appLogger.d('Seerr summary fetch failed for $key: $e');
    } finally {
      _summaryFetchesInFlight.remove(key);
    }
  }

  /// Cancel a request server-side. The row is removed from the list on
  /// success; on failure the list is reloaded so the user sees the truth.
  Future<bool> cancel(int id) async {
    final client = _client;
    if (client == null) return false;
    final previous = _requests;
    _requests = previous.where((r) => r.id != id).toList(growable: false);
    safeNotifyListeners();
    try {
      await client.deleteRequest(id);
      return true;
    } catch (e, st) {
      appLogger.w('Seerr requests cancel($id) failed', error: e, stackTrace: st);
      _requests = previous;
      safeNotifyListeners();
      return false;
    }
  }
}
