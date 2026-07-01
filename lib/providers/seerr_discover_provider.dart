import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/seerr/seerr_page.dart';
import '../models/seerr/seerr_search_result.dart';
import '../services/seerr/seerr_client.dart';
import '../utils/app_logger.dart';

enum SeerrHubLoadState { idle, loading, loaded, error }

/// One discover hub (Trending, Popular Movies, Popular TV).
class SeerrHubState {
  final SeerrHubLoadState state;
  final List<SeerrSearchResult> results;
  final int currentPage;
  final int totalPages;
  final String? errorMessage;
  final bool loadingMore;

  const SeerrHubState({
    this.state = SeerrHubLoadState.idle,
    this.results = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.errorMessage,
    this.loadingMore = false,
  });

  bool get hasMore => currentPage < totalPages;

  SeerrHubState copyWith({
    SeerrHubLoadState? state,
    List<SeerrSearchResult>? results,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
    bool clearError = false,
    bool? loadingMore,
  }) {
    return SeerrHubState(
      state: state ?? this.state,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

enum SeerrHubId { trending, popularMovies, popularTv }

/// Owns the three discover hubs for the active profile. The provider is
/// rebound (via [bindClient]) whenever [SeerrSessionProvider] swaps the
/// active SeerrClient.
class SeerrDiscoverProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  SeerrClient? _client;
  int _bindingGeneration = 0;

  final Map<SeerrHubId, SeerrHubState> _hubs = {
    SeerrHubId.trending: const SeerrHubState(),
    SeerrHubId.popularMovies: const SeerrHubState(),
    SeerrHubId.popularTv: const SeerrHubState(),
  };

  SeerrHubState hub(SeerrHubId id) => _hubs[id] ?? const SeerrHubState();
  bool get isBound => _client != null;

  /// Called by the proxy provider when the active SeerrClient changes.
  void bindClient(SeerrClient? client) {
    if (identical(_client, client)) return;
    _bindingGeneration++;
    _client = client;
    // Reset all hubs to idle so the next focus triggers a fresh load.
    for (final id in SeerrHubId.values) {
      _hubs[id] = const SeerrHubState();
    }
    safeNotifyListeners();
  }

  /// Load the first page if the hub is idle. No-op if already loading,
  /// loaded, or in error state (caller can call [retry] explicitly).
  Future<void> loadIfNeeded(SeerrHubId id) async {
    final current = hub(id);
    if (current.state != SeerrHubLoadState.idle) return;
    await _loadFirstPage(id);
  }

  Future<void> retry(SeerrHubId id) => _loadFirstPage(id);

  Future<void> _loadFirstPage(SeerrHubId id) async {
    final client = _client;
    if (client == null) return;
    final generation = _bindingGeneration;
    _hubs[id] = const SeerrHubState(state: SeerrHubLoadState.loading);
    safeNotifyListeners();
    try {
      final page = await _fetch(id, client, 1);
      if (generation != _bindingGeneration || isDisposed) return;
      _hubs[id] = SeerrHubState(
        state: SeerrHubLoadState.loaded,
        results: page.results,
        currentPage: page.page,
        totalPages: page.pages,
      );
      safeNotifyListeners();
    } catch (e, st) {
      appLogger.w('Seerr discover ${id.name} failed', error: e, stackTrace: st);
      if (generation != _bindingGeneration || isDisposed) return;
      _hubs[id] = SeerrHubState(state: SeerrHubLoadState.error, errorMessage: e.toString());
      safeNotifyListeners();
    }
  }

  Future<void> loadMore(SeerrHubId id) async {
    final client = _client;
    if (client == null) return;
    final current = hub(id);
    if (!current.hasMore || current.loadingMore || current.state != SeerrHubLoadState.loaded) return;
    final generation = _bindingGeneration;
    _hubs[id] = current.copyWith(loadingMore: true);
    safeNotifyListeners();
    try {
      final next = await _fetch(id, client, current.currentPage + 1);
      if (generation != _bindingGeneration || isDisposed) return;
      _hubs[id] = current.copyWith(
        results: [...current.results, ...next.results],
        currentPage: next.page,
        totalPages: next.pages,
        loadingMore: false,
      );
      safeNotifyListeners();
    } catch (e, st) {
      appLogger.w('Seerr discover ${id.name} loadMore failed', error: e, stackTrace: st);
      if (generation != _bindingGeneration || isDisposed) return;
      _hubs[id] = current.copyWith(loadingMore: false);
      safeNotifyListeners();
    }
  }

  Future<SeerrPage<SeerrSearchResult>> _fetch(SeerrHubId id, SeerrClient client, int page) {
    return switch (id) {
      SeerrHubId.trending => client.discoverTrending(page: page),
      SeerrHubId.popularMovies => client.discoverMovies(page: page),
      SeerrHubId.popularTv => client.discoverTv(page: page),
    };
  }
}
