/// Immutable state for a list loaded in pages.
class PagedMediaListState<T> {
  const PagedMediaListState({
    this.items = const [],
    this.totalCount = 0,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.initialLoadFailed = false,
    this.pageLoadFailed = false,
  });

  final List<T> items;
  final int totalCount;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool initialLoadFailed;
  final bool pageLoadFailed;

  bool get hasMore => items.length < totalCount;
  bool get hasItems => items.isNotEmpty;

  PagedMediaListState<T> copyWith({
    List<T>? items,
    int? totalCount,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? initialLoadFailed,
    bool? pageLoadFailed,
  }) {
    return PagedMediaListState<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialLoadFailed: initialLoadFailed ?? this.initialLoadFailed,
      pageLoadFailed: pageLoadFailed ?? this.pageLoadFailed,
    );
  }

  PagedMediaListState<T> startInitialLoad() {
    return copyWith(isInitialLoading: true, isLoadingMore: false, initialLoadFailed: false, pageLoadFailed: false);
  }

  PagedMediaListState<T> completeInitialLoad(List<T> pageItems, int total) {
    return copyWith(
      items: List<T>.of(pageItems),
      totalCount: total,
      isInitialLoading: false,
      isLoadingMore: false,
      initialLoadFailed: false,
      pageLoadFailed: false,
    );
  }

  PagedMediaListState<T> failInitialLoad() {
    return copyWith(isInitialLoading: false, isLoadingMore: false, initialLoadFailed: true);
  }

  PagedMediaListState<T> startLoadMore() {
    return copyWith(isLoadingMore: true, pageLoadFailed: false);
  }

  PagedMediaListState<T> completeLoadMore({
    required int expectedOffset,
    required List<T> pageItems,
    required int total,
  }) {
    if (items.length != expectedOffset) {
      return copyWith(isLoadingMore: false);
    }
    final nextTotal = pageItems.isEmpty ? expectedOffset : total;
    return copyWith(
      items: <T>[...items, ...pageItems],
      totalCount: nextTotal,
      isLoadingMore: false,
      pageLoadFailed: false,
    );
  }

  PagedMediaListState<T> failLoadMore() {
    return copyWith(isLoadingMore: false, pageLoadFailed: true);
  }

  PagedMediaListState<T> replaceItems(List<T> nextItems) {
    final nextTotal = totalCount < nextItems.length ? nextItems.length : totalCount;
    return copyWith(items: List<T>.of(nextItems), totalCount: nextTotal);
  }

  PagedMediaListState<T> removeWhere(bool Function(T item) test) {
    var removed = 0;
    final nextItems = <T>[];
    for (final item in items) {
      if (test(item)) {
        removed++;
      } else {
        nextItems.add(item);
      }
    }
    if (removed == 0) return this;
    final decrementedTotal = totalCount - removed;
    final nextTotal = decrementedTotal < nextItems.length ? nextItems.length : decrementedTotal;
    return copyWith(items: nextItems, totalCount: nextTotal);
  }

  PagedMediaListState<R> mapItems<R>(R Function(T item) map) {
    return PagedMediaListState<R>(
      items: items.map(map).toList(),
      totalCount: totalCount,
      isInitialLoading: isInitialLoading,
      isLoadingMore: isLoadingMore,
      initialLoadFailed: initialLoadFailed,
      pageLoadFailed: pageLoadFailed,
    );
  }
}
