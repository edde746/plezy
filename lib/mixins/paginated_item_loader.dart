import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../media/library_query.dart';
import '../utils/media_server_http_client.dart';
import '../exceptions/media_server_exceptions.dart';

/// Sparse-loading state + fetch orchestration for paginated item grids/lists.
///
/// State lives in [loadedItems] (index → item) and [totalSize]. Subclasses
/// provide [fetchPage] to hit an endpoint; the mixin handles dedupe, retry
/// with backoff, abort propagation, and request-generation invalidation so
/// reloads don't collide with in-flight fetches.
///
/// Typical lifecycle:
/// 1. Subclass's `loadItems` calls [resetPaginationState] inside `setState`,
///    then awaits [loadInitialPage].
/// 2. On scroll, subclass calls [ensureRangeLoaded] with the visible index
///    range. Eager prefetch ahead of the viewport via [prefetchAhead].
/// 3. On dispose, subclass calls [disposePagination].
mixin PaginatedItemLoader<T, W extends StatefulWidget> on State<W> {
  /// Sparse map of loaded items, keyed by position.
  final Map<int, T> loadedItems = {};

  /// Total items on the server. 0 until the first page completes.
  int totalSize = 0;

  final Set<int> _loadingRanges = {};
  AbortController? _cancelToken;
  Object? _paginationError;

  /// Monotonic generation — bumped on reset/dispose so stale fetches are
  /// discarded instead of mutating state from a prior load.
  int _requestId = 0;

  int _retryCount = 0;
  Timer? _retryTimer;
  bool _visibleRangeLoading = false;
  DateTime? _lastEagerPrefetch;
  Object? get paginationError => _paginationError;
  bool get isPaginationLoading => _loadingRanges.isNotEmpty;

  /// Re-invoked by the retry timer. Most recent range-load args.
  VoidCallback? _scheduledRetry;

  /// Size of the page whose response set [totalSize] to a [fallbackPageTotal]
  /// sentinel (a full page, total claimed one past it), or null when the total
  /// looks authoritative. Such a total is no bound on the next request.
  int? _openEndedPageSize;

  /// Fetch a page of items. Subclass implements this — typically delegating
  /// to a paginated client method that returns a [LibraryPage].
  Future<LibraryPage<T>> fetchPage(int start, int size, AbortController? abort);

  /// Hook fired after each successful page merge. Default: no-op.
  /// Override for image prefetch, syncing a base-class `items` list, etc.
  void onPageLoaded(int _, List<T> _) {}

  /// Hook fired when a lazy page starts or finishes loading, or fails.
  /// Override when the surrounding UI exposes loading or retry state.
  void onPaginationStateChanged() {}

  /// Synchronously clear pagination state and bump the generation counter.
  /// Call from inside the subclass's `setState` before awaiting
  /// [loadInitialPage]. Aborts any in-flight fetches from the previous load.
  void resetPaginationState() {
    _requestId++;
    _cancelToken?.abort();
    _cancelToken = AbortController();
    _retryTimer?.cancel();
    _retryCount = 0;
    _visibleRangeLoading = false;
    _lastEagerPrefetch = null;
    _scheduledRetry = null;
    _paginationError = null;
    _openEndedPageSize = null;
    loadedItems.clear();
    _loadingRanges.clear();
    totalSize = 0;
  }

  /// Record whether [page], fetched from [start] with [requestedSize], carries
  /// a [fallbackPageTotal] sentinel rather than the server's own count.
  void _trackOpenEndedTotal(int start, int requestedSize, LibraryPage<T> page) {
    final count = page.items.length;
    final sentinel = requestedSize > 0 && count >= requestedSize && page.totalCount == start + count + 1;
    _openEndedPageSize = sentinel ? requestedSize : null;
  }

  /// Fetch the first page. Await from outside `setState`. Mutates
  /// [loadedItems] and [totalSize] on success; throws on failure.
  Future<LibraryPage<T>> loadInitialPage(int pageSize) async {
    final result = await loadInitialPageWithStatus(pageSize);
    return result.page;
  }

  /// Like [loadInitialPage], but reports whether the fetched page was still
  /// current and actually merged into [loadedItems].
  Future<({LibraryPage<T> page, bool applied})> loadInitialPageWithStatus(int pageSize) async {
    final generation = _requestId;
    late final LibraryPage<T> result;
    try {
      result = await fetchPage(0, pageSize, _cancelToken);
    } catch (_) {
      if (generation != _requestId || !mounted) {
        return (page: LibraryPage<T>(items: const [], totalCount: 0), applied: false);
      }
      rethrow;
    }
    if (generation != _requestId || !mounted) return (page: result, applied: false);

    for (var i = 0; i < result.items.length; i++) {
      loadedItems[i] = result.items[i];
    }
    totalSize = result.totalCount;
    _trackOpenEndedTotal(0, pageSize, result);
    onPageLoaded(0, result.items);
    return (page: result, applied: true);
  }

  /// Fetch any unloaded items inside [firstIndex, firstIndex + visibleCount)
  /// with [buffer] extra indices on each side. Serialized — only one
  /// range-fetch runs at a time — and re-checks after each success so a
  /// single call can backfill multiple gaps.
  Future<void> ensureRangeLoaded(int firstIndex, int visibleCount, {int buffer = 100}) async {
    if (_visibleRangeLoading || totalSize == 0) return;

    final rangeStart = (firstIndex - buffer).clamp(0, totalSize);
    final rangeEnd = (firstIndex + visibleCount + buffer).clamp(0, totalSize);

    int? fetchStart;
    int? fetchEnd;
    for (var i = rangeStart; i < rangeEnd; i++) {
      if (!loadedItems.containsKey(i) && !_loadingRanges.contains(i)) {
        fetchStart ??= i;
        fetchEnd = i + 1;
      }
    }
    if (fetchStart == null || fetchEnd == null) return;

    _retryTimer?.cancel();
    _scheduledRetry = () => ensureRangeLoaded(firstIndex, visibleCount, buffer: buffer);
    _visibleRangeLoading = true;
    try {
      final success = await _fetchRange(fetchStart, fetchEnd - fetchStart);
      if (success && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ensureRangeLoaded(firstIndex, visibleCount, buffer: buffer);
        });
      }
    } finally {
      _visibleRangeLoading = false;
    }
  }

  /// Throttled eager prefetch: if anything immediately outside the viewport
  /// is unloaded, fetch a page. Runs at most once per 100ms.
  void prefetchAhead(int firstIndex, int visibleCount, {int pageSize = 200}) {
    if (totalSize == 0) return;

    final now = DateTime.now();
    if (_lastEagerPrefetch != null && now.difference(_lastEagerPrefetch!) < const Duration(milliseconds: 100)) {
      return;
    }

    final lookAheadStart = (firstIndex + visibleCount).clamp(0, totalSize);
    final lookAheadEnd = (lookAheadStart + visibleCount).clamp(0, totalSize);
    for (var i = lookAheadStart; i < lookAheadEnd; i++) {
      if (!loadedItems.containsKey(i) && !_loadingRanges.contains(i)) {
        _lastEagerPrefetch = now;
        _fetchRange(i, pageSize);
        return;
      }
    }

    final lookBehindStart = (firstIndex - visibleCount).clamp(0, totalSize);
    for (var i = firstIndex - 1; i >= lookBehindStart; i--) {
      if (!loadedItems.containsKey(i) && !_loadingRanges.contains(i)) {
        _lastEagerPrefetch = now;
        // Scanning upward finds the gap's last index: fetch the page that ends
        // there, not one starting there (that would refetch the viewport).
        final start = (i - pageSize + 1).clamp(0, i);
        _fetchRange(start, i - start + 1);
        return;
      }
    }
  }

  /// Evict entries far from [centerIndex] once [loadedItems] exceeds
  /// [threshold], keeping [maxKeep] entries centered on [centerIndex].
  void evictDistantItems(int centerIndex, {int maxKeep = 500, int threshold = 600}) {
    if (loadedItems.length <= threshold) return;
    final halfKeep = maxKeep ~/ 2;
    loadedItems.removeWhere((index, _) => index < centerIndex - halfKeep || index > centerIndex + halfKeep);
  }

  /// Remove the item at [index] and shift higher indices down by one.
  /// Mirrors the "one item deleted on the server" invariant: decrements
  /// [totalSize] even if [index] wasn't in the sparse map (evicted).
  void removeLoadedItemAndShift(int index) {
    _requestId++;
    _cancelToken?.abort();
    _cancelToken = AbortController();
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadingRanges.clear();
    _scheduledRetry = null;
    loadedItems.remove(index);
    final shifted = <int, T>{};
    for (final entry in loadedItems.entries) {
      if (entry.key > index) {
        shifted[entry.key - 1] = entry.value;
      } else {
        shifted[entry.key] = entry.value;
      }
    }
    loadedItems
      ..clear()
      ..addAll(shifted);
    totalSize = (totalSize - 1).clamp(0, totalSize);
  }

  /// Refetch the loaded span in place — the sparse-grid equivalent of Plex
  /// Web's `repopulateRange`. The old items stay rendered while the fetch
  /// runs; on success the span is replaced wholesale and [totalSize] adopts
  /// the server's new count, so server-side additions materialize at their
  /// sorted positions and removals disappear with no clearing and no
  /// skeleton flash. On failure the old content stays untouched
  /// (best-effort background refresh; the staleness paths recover).
  ///
  /// [anchorId] (resolved through [idOf]) reports where a caller-chosen item
  /// moved, so the caller can compensate the scroll offset and keep it
  /// visually stationary. A null result means nothing was applied.
  ///
  /// [maxSpan] bounds the refetched request: a sparse map holding disjoint
  /// clusters (initial pages plus an alpha-jump target) would otherwise span
  /// nearly the whole library in one call. When the span exceeds it, entries
  /// outside a [maxSpan]-wide window centered on [windowCenter] are dropped
  /// first — they degrade to ordinary unloaded slots the scroll path
  /// refetches on demand. Callers that cache per-index state (focus nodes)
  /// evict theirs to the same window.
  Future<({int? anchorOldIndex, int? anchorNewIndex})?> repopulateLoadedRange({
    required String Function(T item) idOf,
    String? anchorId,
    int? maxSpan,
    int? windowCenter,
  }) async {
    if (!mounted || loadedItems.isEmpty || totalSize == 0) return null;
    var indices = loadedItems.keys.toList()..sort();
    if (maxSpan != null && indices.last - indices.first + 1 > maxSpan) {
      final center = (windowCenter ?? indices.first).clamp(indices.first, indices.last);
      final lo = center - maxSpan ~/ 2;
      loadedItems.removeWhere((index, _) => index < lo || index >= lo + maxSpan);
      if (loadedItems.isEmpty) return null;
      indices = loadedItems.keys.toList()..sort();
    }
    final start = indices.first;
    final size = indices.last - start + 1;
    int? anchorOldIndex;
    if (anchorId != null) {
      for (final entry in loadedItems.entries) {
        if (idOf(entry.value) == anchorId) {
          anchorOldIndex = entry.key;
          break;
        }
      }
    }
    // Supersede in-flight fetches: their merges would interleave stale pages
    // into the repopulated span.
    _requestId++;
    _cancelToken?.abort();
    _cancelToken = AbortController();
    _retryTimer?.cancel();
    _loadingRanges.clear();
    _scheduledRetry = null;
    final generation = _requestId;
    final LibraryPage<T> page;
    try {
      page = await fetchPage(start, size, _cancelToken);
    } catch (_) {
      return null;
    }
    if (generation != _requestId || !mounted) return null;
    int? anchorNewIndex;
    if (anchorId != null) {
      for (var i = 0; i < page.items.length; i++) {
        if (idOf(page.items[i]) == anchorId) {
          anchorNewIndex = start + i;
          break;
        }
      }
    }
    setState(() {
      loadedItems.removeWhere((index, _) => index >= start && index < start + size);
      for (var i = 0; i < page.items.length; i++) {
        loadedItems[start + i] = page.items[i];
      }
      totalSize = page.totalCount;
      loadedItems.removeWhere((index, _) => index >= totalSize);
    });
    _trackOpenEndedTotal(start, size, page);
    onPageLoaded(start, page.items);
    return (anchorOldIndex: anchorOldIndex, anchorNewIndex: anchorNewIndex);
  }

  /// Discard the "fetch in flight" markers. In-flight network requests keep
  /// running but are no longer considered for dedupe — the next
  /// [ensureRangeLoaded] / [prefetchAhead] will re-scan the visible range.
  /// Used by scroll-idle handlers after a fast scroll where earlier eager
  /// prefetches are aimed at a now-irrelevant region.
  void clearPendingRanges() {
    _loadingRanges.clear();
  }

  /// Ensure the page containing [index] is fetched (or already fetched).
  /// For callers that don't track viewport geometry — trigger this when a
  /// skeleton for [index] is built, and the containing page will backfill.
  /// Dedupes so multiple skeletons in the same page share one fetch.
  void ensureIndexLoaded(int index, {int pageSize = 200}) {
    if (totalSize == 0 || index >= totalSize || index < 0) return;
    if (loadedItems.containsKey(index) || _loadingRanges.contains(index)) return;
    final pageStart = (index ~/ pageSize) * pageSize;
    // Wire up the backoff retry: if this fetch fails, the retry timer in
    // _fetchRange needs something to call. Without this, a failed fetch on a
    // skeleton-only screen leaves the skeleton stuck until something else
    // triggers a rebuild.
    _scheduledRetry = () => ensureIndexLoaded(index, pageSize: pageSize);
    _fetchRange(pageStart, pageSize);
  }

  /// Aborts in-flight requests and cancels timers. Call from `dispose()`.
  void disposePagination() {
    _requestId++;
    _cancelToken?.abort();
    _cancelToken = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadingRanges.clear();
    _paginationError = null;
    _scheduledRetry = null;
  }

  Future<bool> _fetchRange(int start, int size) async {
    if (start >= totalSize) return false;
    final clampedSize = size.clamp(0, totalSize - start);
    if (clampedSize == 0) return false;

    final indices = List.generate(clampedSize, (i) => start + i);
    if (indices.every((i) => _loadingRanges.contains(i) || loadedItems.containsKey(i))) return true;
    _loadingRanges.addAll(indices);
    _paginationError = null;
    onPaginationStateChanged();

    // A sentinel total ends one past the last full page, so clamping to it
    // would ask for a one-item tail page (and page one item at a time from
    // there). Past the known items, request a page as big as the one that
    // came back full; the server returns only what exists.
    final openEndedPageSize = _openEndedPageSize;
    final requestSize = openEndedPageSize != null && start + clampedSize >= totalSize
        ? math.max(size, openEndedPageSize)
        : clampedSize;

    final generation = _requestId;

    try {
      final result = await fetchPage(start, requestSize, _cancelToken);
      if (generation != _requestId || !mounted) return false;

      setState(() {
        for (var i = 0; i < result.items.length; i++) {
          loadedItems[start + i] = result.items[i];
        }
        if (result.totalCount != totalSize) totalSize = result.totalCount;
      });
      _trackOpenEndedTotal(start, requestSize, result);

      _retryCount = 0;
      onPageLoaded(start, result.items);
      return true;
    } catch (e) {
      if (e is MediaServerHttpException && e.type == MediaServerHttpErrorType.cancelled) return false;
      _paginationError = e;
      _retryCount++;
      final delay = Duration(milliseconds: 500 * (1 << _retryCount.clamp(0, 4)));
      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        if (mounted && generation == _requestId) _scheduledRetry?.call();
      });
      return false;
    } finally {
      _loadingRanges.removeAll(indices);
      onPaginationStateChanged();
    }
  }
}
