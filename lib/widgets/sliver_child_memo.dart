import 'package:flutter/widgets.dart';

/// Per-index widget cache for lazy sliver/list children.
///
/// `SliverChildBuilderDelegate.shouldRebuild` is unconditionally true, so any
/// rebuild of the surrounding widget (pagination `setState`, settings change,
/// hub refresh) hands every *realized* child a brand-new widget and rebuilds
/// its whole subtree — 5-20ms per media card, times every visible card, often
/// inside layout via `SliverCrossAxisLayoutBuilder`. Returning the *identical*
/// widget instance for an unchanged item lets `Element.updateChild`
/// short-circuit the entire subtree instead.
///
/// A cache entry is reused only while:
/// - the [epoch] passed to [widgetFor] equals the one the cache was built
///   under (pack everything the item builder closes over — column count,
///   item count, card geometry, view prefs — into a record so any change
///   flushes stale closures), and
/// - the item at that index is `identical` to the cached one (item updates
///   replace the object, so in-place data changes invalidate naturally), and
/// - the optional per-index [salt] compares equal (for cheap per-index state
///   like "is this the focused index" that isn't part of the item).
class SliverChildMemo<T extends Object> {
  /// Hard cap so a long scroll through a huge library can't pin thousands of
  /// widget trees (and their item objects, defeating item eviction). Clearing
  /// only costs one rebuild of the currently realized children.
  static const int _maxEntries = 600;

  Object? _epoch;
  final Map<int, (T, Object?, Widget)> _cache = {};

  /// Returns the cached widget for [index] when item/epoch/salt are
  /// unchanged, without building anything on a miss. Lets callers decide
  /// whether a miss is allowed to inflate this frame (see
  /// `CardInflationBudget`). A changed [epoch] flushes the cache here too so
  /// a subsequent [widgetFor] sees the same state.
  Widget? tryGet(int index, T item, {required Object epoch, Object? salt}) {
    if (epoch != _epoch) {
      _cache.clear();
      _epoch = epoch;
      return null;
    }
    final entry = _cache[index];
    if (entry != null && identical(entry.$1, item) && entry.$2 == salt) {
      return entry.$3;
    }
    return null;
  }

  /// Returns the cached widget for [index] when item/epoch/salt are
  /// unchanged, otherwise runs [build] and caches the result.
  Widget widgetFor(int index, T item, {required Object epoch, Object? salt, required Widget Function() build}) {
    if (epoch != _epoch) {
      _cache.clear();
      _epoch = epoch;
    }
    final entry = _cache[index];
    if (entry != null && identical(entry.$1, item) && entry.$2 == salt) {
      return entry.$3;
    }
    if (_cache.length >= _maxEntries) _cache.clear();
    final widget = build();
    _cache[index] = (item, salt, widget);
    return widget;
  }

  void clear() => _cache.clear();

  /// Drops entries outside `centerIndex ± halfWindow`.
  ///
  /// Call alongside per-index resource eviction (e.g. focus-node eviction):
  /// a cached widget must not outlive resources it captured, like a
  /// [FocusNode] that eviction disposed.
  void removeOutsideRange(int centerIndex, {required int halfWindow}) {
    _cache.removeWhere((index, _) => index < centerIndex - halfWindow || index > centerIndex + halfWindow);
  }
}
