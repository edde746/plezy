import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/watch_state_resolver.dart';
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
  WatchStateStore() {
    _subscription = WatchStateNotifier().stream.listen(_onWatchStateEvent);
  }

  StreamSubscription<WatchStateEvent>? _subscription;
  final Map<String, _WatchStatePatchEntry> _patches = {};
  final Map<String, _WatchStatePatchEntry> _hydratedPatches = {};
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
    return applyPatch(item, patchForItem(item));
  }

  List<MediaItem> applyAll(List<MediaItem> items) {
    if (_patches.isEmpty && _hydratedPatches.isEmpty) return items;
    return [for (final item in items) apply(item)];
  }

  static MediaItem applyPatch(MediaItem item, WatchStatePatch? patch) {
    if (patch == null) return item;
    return WatchStateSnapshot(
      isWatched: patch.isWatched,
      hasViewOffsetMs: patch.hasViewOffsetMs,
      viewOffsetMs: patch.viewOffsetMs,
    ).apply(item);
  }

  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    if (_patches.isEmpty && _hydratedPatches.isEmpty) return;
    _patches.clear();
    _hydratedPatches.clear();
    safeNotifyListeners();
  }

  void setActiveClientScopesByServer(Map<String, String?> scopes) {
    final normalized = <String, String?>{
      for (final entry in scopes.entries)
        if (entry.value != null && entry.value!.isNotEmpty && entry.value != entry.key) entry.key: entry.value,
    };
    if (mapEquals(_activeClientScopesByServer, normalized)) return;
    _activeClientScopesByServer = Map.unmodifiable(normalized);
    if (_patches.isNotEmpty || _hydratedPatches.isNotEmpty) safeNotifyListeners();
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

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
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
      final patch = select<WatchStateStore, WatchStatePatch?>((store) => store.patchForItem(item));
      return WatchStateStore.applyPatch(item, patch);
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
