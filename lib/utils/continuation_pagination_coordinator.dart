/// A backend page consumed by [ContinuationPaginationCoordinator].
///
/// [consumedCount] is deliberately separate from [items.length]. A screen may
/// filter or otherwise map wire items while the backend cursor must still
/// advance by the number of records consumed from the response.
class ContinuationPage<T> {
  const ContinuationPage({required this.items, required this.totalCount, required this.consumedCount});

  final List<T> items;
  final int totalCount;
  final int consumedCount;
}

enum ContinuationLoadStatus { completed, failed, stale, idle }

typedef ContinuationPageLoader<T> = Future<ContinuationPage<T>> Function(int startIndex);
typedef ContinuationPageHandler<T> = void Function(ContinuationPage<T> page);

/// Coordinates an eager, indexed continuation without depending on Flutter.
///
/// Screens retain ownership of item mapping and presentation through [onPage].
/// This class owns cursor advancement, generation invalidation, retry state,
/// stale-result rejection, and request coalescing.
class ContinuationPaginationCoordinator<T> {
  ContinuationPaginationCoordinator({required this.loadPage, required this.onPage, this.onStateChanged, this.onError});

  final ContinuationPageLoader<T> loadPage;
  final ContinuationPageHandler<T> onPage;
  final void Function()? onStateChanged;
  final void Function(Object error, StackTrace stackTrace)? onError;

  int _generation = 0;
  int? _nextStartIndex;
  int? _totalCount;
  Future<ContinuationLoadStatus>? _inFlight;
  int? _inFlightGeneration;
  bool _disposed = false;
  bool _isLoading = false;
  Object? _error;
  StackTrace? _errorStackTrace;

  int? get nextStartIndex => _nextStartIndex;
  int? get totalCount => _totalCount;
  bool get hasMore => _nextStartIndex != null;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  StackTrace? get errorStackTrace => _errorStackTrace;

  /// Invalidates all prior work, runs [request], and reports whether its result
  /// still belongs to the current generation.
  Future<bool> runNewGeneration(Future<void> Function() request) async {
    final generation = _beginGeneration();
    try {
      await request();
    } catch (_) {
      if (!_isCurrent(generation)) return false;
      rethrow;
    }
    return _isCurrent(generation);
  }

  /// Seeds the continuation cursor from an accepted initial response.
  void setContinuation({required int startIndex, required int totalCount}) {
    if (_disposed) return;
    _totalCount = totalCount;
    _nextStartIndex = startIndex < totalCount ? startIndex : null;
    _error = null;
    _errorStackTrace = null;
    onStateChanged?.call();
  }

  /// Loads all remaining pages. Calls made while this generation is loading
  /// share the same operation and do not issue duplicate backend requests.
  Future<ContinuationLoadStatus> loadRemaining() {
    final existing = _inFlight;
    if (existing != null) return existing;
    if (_disposed || _nextStartIndex == null) {
      return Future.value(ContinuationLoadStatus.idle);
    }

    final generation = _generation;
    _inFlightGeneration = generation;
    final operation = _loadRemaining(generation);
    _inFlight = operation;
    return operation;
  }

  /// Retries from the first cursor that did not complete successfully.
  Future<ContinuationLoadStatus> retry() => loadRemaining();

  /// Invalidates pending results and suppresses future callbacks.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _nextStartIndex = null;
    _totalCount = null;
    _inFlight = null;
    _inFlightGeneration = null;
    _isLoading = false;
    _error = null;
    _errorStackTrace = null;
  }

  int _beginGeneration() {
    _generation++;
    _nextStartIndex = null;
    _totalCount = null;
    _inFlight = null;
    _inFlightGeneration = null;
    _isLoading = false;
    _error = null;
    _errorStackTrace = null;
    if (!_disposed) onStateChanged?.call();
    return _generation;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<ContinuationLoadStatus> _loadRemaining(int generation) async {
    _isLoading = true;
    _error = null;
    _errorStackTrace = null;
    onStateChanged?.call();

    try {
      while (_isCurrent(generation)) {
        final startIndex = _nextStartIndex;
        if (startIndex == null) return ContinuationLoadStatus.completed;

        final page = await loadPage(startIndex);
        if (!_isCurrent(generation)) return ContinuationLoadStatus.stale;

        if (page.consumedCount <= 0) {
          _totalCount = page.totalCount;
          _nextStartIndex = null;
          onStateChanged?.call();
          return ContinuationLoadStatus.completed;
        }

        onPage(page);
        _totalCount = page.totalCount;
        final nextStartIndex = startIndex + page.consumedCount;
        _nextStartIndex = nextStartIndex < page.totalCount ? nextStartIndex : null;
        onStateChanged?.call();
      }
      return ContinuationLoadStatus.stale;
    } catch (exception, stackTrace) {
      if (!_isCurrent(generation)) return ContinuationLoadStatus.stale;
      _error = exception;
      _errorStackTrace = stackTrace;
      onError?.call(exception, stackTrace);
      return ContinuationLoadStatus.failed;
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        onStateChanged?.call();
      }
      if (_inFlightGeneration == generation) {
        _inFlight = null;
        _inFlightGeneration = null;
      }
    }
  }
}
