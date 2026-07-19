import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/watch_state_resolver.dart';
import '../utils/favorite_state_notifier.dart';
import '../utils/global_key_utils.dart';
import '../utils/watch_state_notifier.dart';

@immutable
class WatchStatePatch {
  final bool? isWatched;
  final bool hasViewOffsetMs;
  final int? viewOffsetMs;

  const WatchStatePatch({this.isWatched, this.hasViewOffsetMs = false, this.viewOffsetMs});

  factory WatchStatePatch.fromSnapshot(WatchStateSnapshot snapshot) => WatchStatePatch(
    isWatched: snapshot.isWatched,
    hasViewOffsetMs: snapshot.hasViewOffsetMs,
    viewOffsetMs: snapshot.viewOffsetMs,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchStatePatch &&
          other.isWatched == isWatched &&
          other.hasViewOffsetMs == hasViewOffsetMs &&
          other.viewOffsetMs == viewOffsetMs;

  @override
  int get hashCode => Object.hash(isWatched, hasViewOffsetMs, viewOffsetMs);
}

@immutable
class HydratedWatchStatePatch {
  final String globalKey;
  final WatchStatePatch patch;
  final int updatedAt;
  final int order;

  const HydratedWatchStatePatch({
    required this.globalKey,
    required this.patch,
    required this.updatedAt,
    required this.order,
  });
}

class _WatchStatePatchEntry {
  final WatchStatePatch patch;
  final int updatedAt;
  final int sequence;
  final bool isSessionEvent;

  const _WatchStatePatchEntry(
    this.patch, {
    required this.updatedAt,
    required this.sequence,
    required this.isSessionEvent,
  });

  bool isNewerThan(_WatchStatePatchEntry other) {
    if (updatedAt != other.updatedAt) return updatedAt > other.updatedAt;
    if (isSessionEvent != other.isSessionEvent) return isSessionEvent;
    return sequence > other.sequence;
  }

  @override
  bool operator ==(Object other) =>
      other is _WatchStatePatchEntry &&
      other.patch == patch &&
      other.updatedAt == updatedAt &&
      other.sequence == sequence &&
      other.isSessionEvent == isSessionEvent;

  @override
  int get hashCode => Object.hash(patch, updatedAt, sequence, isSessionEvent);
}

class _FavoritePatchEntry {
  final bool isFavorite;
  final int sequence;
  final DateTime expiresAt;

  const _FavoritePatchEntry(this.isFavorite, this.sequence, this.expiresAt);

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// The single session-local layer for watch-state freshness.
///
/// Server fetches remain the source of truth; [MediaItem] snapshots are never
/// hand-mutated to reflect watch events. Instead, every watch event lands here
/// as a patch, and consumers resolve items at point of use ([apply] /
/// [patchForItem]). Resolution is hierarchy-aware: an item's effective patch
/// is the newest among its own and its [MediaItem.parentChain] ancestors', so
/// marking a show/season reaches every descendant, while a later per-item
/// event still overrides an older container mark.
class WatchStateStore extends ChangeNotifier with DisposableChangeNotifierMixin {
  WatchStateStore({this.favoritePatchLifetime = const Duration(seconds: 30), DateTime Function()? favoriteClock})
    : _favoriteClock = favoriteClock ?? DateTime.now {
    _subscription = WatchStateNotifier().stream.listen(_onWatchStateEvent);
    _favoriteSubscription = FavoriteStateNotifier().stream.listen(_onFavoriteStateEvent);
  }

  final Duration favoritePatchLifetime;
  final DateTime Function() _favoriteClock;
  StreamSubscription<WatchStateEvent>? _subscription;
  StreamSubscription<FavoriteStateEvent>? _favoriteSubscription;
  final Map<String, _WatchStatePatchEntry> _patches = {};
  final Map<String, _WatchStatePatchEntry> _hydratedPatches = {};
  final Map<String, _FavoritePatchEntry> _favoritePatches = {};
  final Set<String> _favoriteReconciliations = {};
  Timer? _favoriteExpiryTimer;
  DateTime? _favoriteExpiryAt;
  String? _activeProfileId;
  Map<String, String?> _activeClientScopesByServer = const {};
  int _sequence = 0;

  _WatchStatePatchEntry? _exactEntryFor(String globalKey) {
    final session = _patches[globalKey];
    final hydrated = _hydratedPatches[globalKey];
    if (session == null) return hydrated;
    if (hydrated == null) return session;
    return session.isNewerThan(hydrated) ? session : hydrated;
  }

  _WatchStatePatchEntry? _entryFor(String globalKey) {
    _WatchStatePatchEntry? scopedEntry;
    final parsed = parseGlobalKey(globalKey);
    if (parsed != null) {
      final scoped = _activeClientScopesByServer[parsed.serverId];
      if (scoped != null && scoped.isNotEmpty) {
        scopedEntry = _exactEntryFor(buildGlobalKey(ServerId(scoped), parsed.ratingKey));
      }
    }
    final unscopedEntry = _exactEntryFor(globalKey);
    if (scopedEntry == null) return unscopedEntry;
    if (unscopedEntry == null) return scopedEntry;
    return scopedEntry.isNewerThan(unscopedEntry) ? scopedEntry : unscopedEntry;
  }

  WatchStatePatch? patchForGlobalKey(String globalKey) => _entryFor(globalKey)?.patch;

  ({String key, _FavoritePatchEntry? entry}) _favoriteEntryForGlobalKey(String globalKey) {
    _scheduleFavoriteExpiryNotification();
    final now = _favoriteClock();
    final parsed = parseGlobalKey(globalKey);
    if (parsed != null) {
      final scoped = _activeClientScopesByServer[parsed.serverId];
      if (scoped != null && scoped.isNotEmpty) {
        final key = buildGlobalKey(ServerId(scoped), parsed.ratingKey);
        final entry = _favoritePatches[key];
        if (entry?.isExpiredAt(now) ?? false) {
          _scheduleFavoriteReconciliation(key, entry!.sequence);
          return (key: key, entry: null);
        }
        return (key: key, entry: entry);
      }
    }
    final entry = _favoritePatches[globalKey];
    if (entry?.isExpiredAt(now) ?? false) {
      _scheduleFavoriteReconciliation(globalKey, entry!.sequence);
      return (key: globalKey, entry: null);
    }
    return (key: globalKey, entry: entry);
  }

  bool? favoriteForGlobalKey(String globalKey) => _favoriteEntryForGlobalKey(globalKey).entry?.isFavorite;

  bool? favoriteForItem(MediaItem item) {
    final resolved = _favoriteEntryForGlobalKey(item.globalKey);
    final entry = resolved.entry;
    if (entry == null) return null;
    if (item.isFavorite == entry.isFavorite) {
      _scheduleFavoriteReconciliation(resolved.key, entry.sequence);
      return null;
    }
    return entry.isFavorite;
  }

  WatchStatePatch? patchForItem(MediaItem item) {
    var best = _entryFor(item.globalKey);
    if (item.parentChain.isNotEmpty) {
      final serverId = serverIdOrNull(item.serverId);
      for (final parentId in item.parentChain) {
        // Mirror MediaItem.globalKey's bare-id fallback when serverId is missing.
        final entry = _entryFor(serverId != null ? buildGlobalKey(serverId, parentId) : parentId);
        if (entry != null && (best == null || entry.isNewerThan(best))) best = entry;
      }
    }
    return best?.patch;
  }

  MediaItem apply(MediaItem item) {
    return applyPatch(item, patchForItem(item), isFavorite: favoriteForItem(item));
  }

  List<MediaItem> applyAll(List<MediaItem> items) {
    if (_patches.isEmpty && _hydratedPatches.isEmpty && _favoritePatches.isEmpty) return items;
    return [for (final item in items) apply(item)];
  }

  static MediaItem applyPatch(MediaItem item, WatchStatePatch? patch, {bool? isFavorite}) {
    final watchStateItem = patch == null
        ? item
        : WatchStateSnapshot(
            isWatched: patch.isWatched,
            hasViewOffsetMs: patch.hasViewOffsetMs,
            viewOffsetMs: patch.viewOffsetMs,
          ).apply(item);
    return isFavorite == null ? watchStateItem : watchStateItem.copyWith(isFavorite: isFavorite);
  }

  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    if (_patches.isEmpty && _hydratedPatches.isEmpty && _favoritePatches.isEmpty) return;
    _patches.clear();
    _hydratedPatches.clear();
    _clearFavoritePatches();
    safeNotifyListeners();
  }

  void setActiveClientScopesByServer(Map<String, String?> scopes) {
    final normalized = <String, String?>{
      for (final entry in scopes.entries)
        if (entry.value != null && entry.value!.isNotEmpty && entry.value != entry.key) entry.key: entry.value,
    };
    if (mapEquals(_activeClientScopesByServer, normalized)) return;
    _activeClientScopesByServer = Map.unmodifiable(normalized);
    if (_patches.isNotEmpty || _hydratedPatches.isNotEmpty || _favoritePatches.isNotEmpty) safeNotifyListeners();
  }

  /// Replace the persisted local-action layer without disturbing newer
  /// session events. Timestamps preserve freshness across item/ancestor keys.
  void setHydratedPatches(Iterable<HydratedWatchStatePatch> patches) {
    final next = <String, _WatchStatePatchEntry>{};
    for (final hydrated in patches) {
      final candidate = _WatchStatePatchEntry(
        hydrated.patch,
        updatedAt: hydrated.updatedAt,
        sequence: hydrated.order,
        isSessionEvent: false,
      );
      final existing = next[hydrated.globalKey];
      if (existing == null || candidate.isNewerThan(existing)) {
        next[hydrated.globalKey] = candidate;
      }
    }
    if (mapEquals(_hydratedPatches, next)) return;
    _hydratedPatches
      ..clear()
      ..addAll(next);
    safeNotifyListeners();
  }

  void _onWatchStateEvent(WatchStateEvent event) {
    final snapshot = WatchStateResolver.fromEvent(event);
    if (snapshot.isEmpty) return;
    final patch = WatchStatePatch.fromSnapshot(snapshot);

    final cacheServerId = event.cacheServerId;
    final key = cacheServerId != null && cacheServerId.isNotEmpty && cacheServerId != event.serverId
        ? buildGlobalKey(ServerId(cacheServerId), event.itemId)
        : event.globalKey;
    _patches[key] = _WatchStatePatchEntry(
      patch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      sequence: ++_sequence,
      isSessionEvent: true,
    );
    safeNotifyListeners();
  }

  void _onFavoriteStateEvent(FavoriteStateEvent event) {
    final key = event.stateKey;
    final sequence = ++_sequence;
    _favoritePatches[key] = _FavoritePatchEntry(
      event.isFavorite,
      sequence,
      _favoriteClock().add(favoritePatchLifetime),
    );
    _favoriteReconciliations.remove(key);
    // Consuming listeners re-run a favorite lookup below, which arms the
    // shared expiry timer. Relay-only listeners should not retain a timer for
    // state they never read (notably the download metadata bridge).
    safeNotifyListeners();
  }

  void _scheduleFavoriteReconciliation(String key, int sequence) {
    if (!_favoriteReconciliations.add(key)) return;
    scheduleMicrotask(() {
      _favoriteReconciliations.remove(key);
      if (isDisposed || _favoritePatches[key]?.sequence != sequence) return;
      _favoritePatches.remove(key);
      _scheduleFavoriteExpiryNotification();
      safeNotifyListeners();
    });
  }

  void _scheduleFavoriteExpiryNotification() {
    if (isDisposed || !hasListeners || _favoritePatches.isEmpty) {
      _cancelFavoriteExpiryTimer();
      return;
    }

    DateTime? earliest;
    for (final entry in _favoritePatches.values) {
      if (earliest == null || entry.expiresAt.isBefore(earliest)) earliest = entry.expiresAt;
    }
    if (earliest == null) {
      _cancelFavoriteExpiryTimer();
      return;
    }
    if (_favoriteExpiryTimer?.isActive == true && _favoriteExpiryAt == earliest) return;

    _favoriteExpiryTimer?.cancel();
    _favoriteExpiryAt = earliest;
    final remaining = earliest.difference(_favoriteClock());
    _favoriteExpiryTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (isDisposed || _favoriteExpiryAt != earliest) return;
      _favoriteExpiryTimer = null;
      _favoriteExpiryAt = null;
      final now = _favoriteClock();
      final expiredKeys = [
        for (final entry in _favoritePatches.entries)
          if (entry.value.isExpiredAt(now)) entry.key,
      ];
      for (final key in expiredKeys) {
        _favoritePatches.remove(key);
        _favoriteReconciliations.remove(key);
      }
      if (expiredKeys.isNotEmpty) safeNotifyListeners();
      _scheduleFavoriteExpiryNotification();
    });
  }

  void _cancelFavoriteExpiryTimer() {
    _favoriteExpiryTimer?.cancel();
    _favoriteExpiryTimer = null;
    _favoriteExpiryAt = null;
  }

  void _clearFavoritePatches() {
    _cancelFavoriteExpiryTimer();
    _favoriteReconciliations.clear();
    _favoritePatches.clear();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _scheduleFavoriteExpiryNotification();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) _cancelFavoriteExpiryTimer();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _favoriteSubscription?.cancel();
    _favoriteSubscription = null;
    _clearFavoritePatches();
    super.dispose();
  }
}

/// Point-of-use watch-state resolution. All fall back to the item as-is when
/// no [WatchStateStore] is in the tree (tests, isolated subtrees).
extension WatchStateResolution on BuildContext {
  /// Build-time resolution: subscribes this context to the item's effective
  /// patch, so the widget rebuilds when a newer event lands for it (or an
  /// ancestor). Use in `build`.
  MediaItem withFreshWatchState(MediaItem item) {
    try {
      final state = select<WatchStateStore, (WatchStatePatch?, bool?)>(
        (store) => (store.patchForItem(item), store.favoriteForItem(item)),
      );
      return WatchStateStore.applyPatch(item, state.$1, isFavorite: state.$2);
    } on ProviderNotFoundException {
      return item;
    }
  }

  /// Point-in-time resolution for handlers and non-build code paths.
  MediaItem readFreshWatchState(MediaItem item) {
    try {
      return read<WatchStateStore>().apply(item);
    } on ProviderNotFoundException {
      return item;
    }
  }

  List<MediaItem> readFreshWatchStateAll(List<MediaItem> items) {
    try {
      return read<WatchStateStore>().applyAll(items);
    } on ProviderNotFoundException {
      return items;
    }
  }
}
