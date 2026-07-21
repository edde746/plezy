import 'package:flutter/foundation.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/app_logger.dart';
import '../trackers/future_coalescer.dart';
import 'catalog_source.dart';

/// One snapshot page of watchlist membership: each group holds every key
/// form of a single watchlist entry.
typedef WatchlistKeyPage = ({List<List<String>> groups, bool hasMore});

/// Shared watchlist snapshot + optimistic-mutation machinery behind the
/// watchlist half of [CatalogSource] (Trakt, MAL). Implementations supply
/// key derivation, the snapshot page fetch, and the actual mutation call.
///
/// The snapshot maps every key form of an entry to the entry's full key
/// group, so a mutation carrying only a subset of the entry's id forms (a
/// media-detail remove works from server-resolved external ids, which lack
/// Trakt's trakt/slug forms) still drops the WHOLE entry. With a flat key
/// set, the sibling keys survived a remove and any-match membership stayed
/// true for the rest of the session.
mixin CatalogWatchlistMachinery {
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();
  final FutureCoalescer<void> _watchlistLoad = FutureCoalescer();
  Map<String, Set<String>>? _watchlistKeyGroups;

  // ---------- Contract ----------

  /// Log prefix naming the source and its list, e.g. `Trakt: watchlist`.
  String get watchlistLogLabel;

  /// Full-snapshot paging bounds.
  int get watchlistPageLimit;
  int get watchlistMaxPages;

  /// Every membership key form of [ids], namespaced by [kind]. Sources with
  /// different identity rules (MAL and AniList) override this.
  List<String> membershipKeysFor(MediaKind kind, CatalogItemIds ids) => [
    for (final key in ids.allKeys) '${kind.id}/$key',
  ];

  /// One page of the snapshot as key groups (one group per entry).
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit);

  /// Resolve [ids] to the concrete forms the mutation call needs (MAL maps
  /// external ids to a MAL id via Fribb). Throw when the item cannot exist
  /// in this source's domain. Default: pass-through.
  Future<CatalogItemIds> resolveWatchlistMutationIds(MediaKind kind, CatalogItemIds ids) async => ids;

  /// The actual API mutation for the resolved [ids].
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add});

  // ---------- CatalogSource watchlist surface ----------

  Listenable get watchlistChanges => _watchlistChanges;

  /// Load failures are logged and swallowed: membership stays unknown
  /// (null) and the next call retries — every UI call site fires this
  /// unawaited, so a flaky request must not become an uncaught error.
  Future<void> ensureWatchlistLoaded() {
    if (_watchlistKeyGroups != null) return Future.value();
    return _watchlistLoad.run(_loadWatchlistSnapshot);
  }

  Future<void> _loadWatchlistSnapshot() async {
    try {
      final map = <String, Set<String>>{};
      var page = 1;
      while (true) {
        final res = await fetchWatchlistKeyPage(page, watchlistPageLimit);
        for (final group in res.groups) {
          final shared = group.toSet();
          for (final key in shared) {
            map[key] = shared;
          }
        }
        if (!res.hasMore) break;
        if (page >= watchlistMaxPages) {
          appLogger.w('$watchlistLogLabel snapshot truncated at ${map.length} keys ($page pages)');
          break;
        }
        page++;
      }
      _watchlistKeyGroups = map;
      _watchlistChanges.notify();
    } catch (e) {
      appLogger.w('$watchlistLogLabel snapshot load failed', error: e);
    }
  }

  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) {
    final map = _watchlistKeyGroups;
    if (map == null) return null;
    return membershipKeysFor(kind, ids).any(map.containsKey);
  }

  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) => _mutateWatchlist(kind, ids, add: true);

  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) => _mutateWatchlist(kind, ids, add: false);

  Future<void> _mutateWatchlist(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final resolved = await resolveWatchlistMutationIds(kind, ids);
    final keys = membershipKeysFor(kind, resolved);

    // Optimistic: flip the snapshot first so UI toggles instantly; revert on
    // failure. Callers surface the rethrown error.
    final map = _watchlistKeyGroups;
    Set<String>? addedGroup;
    List<Set<String>>? removedGroups;
    var changed = false;
    if (map != null && keys.isNotEmpty) {
      if (add) {
        addedGroup = keys.toSet();
        for (final key in addedGroup) {
          map[key] = addedGroup;
        }
        changed = true;
      } else {
        removedGroups = _takeGroups(map, keys);
        changed = removedGroups.isNotEmpty;
      }
      if (changed) _watchlistChanges.notify();
    }

    try {
      await performWatchlistMutation(kind, resolved, add: add);
    } catch (_) {
      // Revert only if the snapshot wasn't replaced by a reload meanwhile.
      if (changed && identical(map, _watchlistKeyGroups)) {
        if (addedGroup != null) {
          for (final key in addedGroup) {
            if (identical(map![key], addedGroup)) map.remove(key);
          }
        }
        for (final group in removedGroups ?? const <Set<String>>[]) {
          for (final key in group) {
            map![key] = group;
          }
        }
        _watchlistChanges.notify();
      }
      rethrow;
    }
  }

  /// Remove every entry group hit by [keys] from [map], returning them for
  /// a potential revert.
  static List<Set<String>> _takeGroups(Map<String, Set<String>> map, Iterable<String> keys) {
    final groups = <Set<String>>[];
    for (final key in keys) {
      final group = map[key];
      if (group != null && !groups.any((existing) => identical(existing, group))) {
        groups.add(group);
      }
    }
    for (final group in groups) {
      group.forEach(map.remove);
    }
    return groups;
  }

  /// Call from the source's [CatalogSource.dispose].
  void disposeWatchlistMachinery() {
    _watchlistChanges.dispose();
  }
}
