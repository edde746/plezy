import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/foundation.dart';

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

class _WatchStatePatchEntry {
  final WatchStatePatch patch;
  final int sequence;

  const _WatchStatePatchEntry(this.patch, this.sequence);
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
  String? _activeProfileId;
  Map<String, String?> _activeClientScopesByServer = const {};
  int _sequence = 0;

  _WatchStatePatchEntry? _entryFor(String globalKey) {
    _WatchStatePatchEntry? scopedEntry;
    final parsed = parseGlobalKey(globalKey);
    if (parsed != null) {
      final scoped = _activeClientScopesByServer[parsed.serverId];
      if (scoped != null && scoped.isNotEmpty) {
        scopedEntry = _patches[buildGlobalKey(ServerId(scoped), parsed.ratingKey)];
      }
    }
    final unscopedEntry = _patches[globalKey];
    if (scopedEntry == null) return unscopedEntry;
    if (unscopedEntry == null) return scopedEntry;
    return scopedEntry.sequence >= unscopedEntry.sequence ? scopedEntry : unscopedEntry;
  }

  WatchStatePatch? patchForGlobalKey(String globalKey) => _entryFor(globalKey)?.patch;

  WatchStatePatch? patchForItem(MediaItem item) {
    var best = _entryFor(item.globalKey);
    if (item.parentChain.isNotEmpty) {
      final serverId = serverIdOrNull(item.serverId);
      for (final parentId in item.parentChain) {
        // Mirror MediaItem.globalKey's bare-id fallback when serverId is missing.
        final entry = _entryFor(serverId != null ? buildGlobalKey(serverId, parentId) : parentId);
        if (entry != null && (best == null || entry.sequence > best.sequence)) best = entry;
      }
    }
    return best?.patch;
  }

  MediaItem apply(MediaItem item) {
    return applyPatch(item, patchForItem(item));
  }

  List<MediaItem> applyAll(List<MediaItem> items) {
    if (_patches.isEmpty) return items;
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
    if (_patches.isEmpty) return;
    _patches.clear();
    safeNotifyListeners();
  }

  void setActiveClientScopesByServer(Map<String, String?> scopes) {
    final normalized = <String, String?>{
      for (final entry in scopes.entries)
        if (entry.value != null && entry.value!.isNotEmpty && entry.value != entry.key) entry.key: entry.value,
    };
    if (mapEquals(_activeClientScopesByServer, normalized)) return;
    _activeClientScopesByServer = Map.unmodifiable(normalized);
    if (_patches.isNotEmpty) safeNotifyListeners();
  }

  void _onWatchStateEvent(WatchStateEvent event) {
    final snapshot = WatchStateResolver.fromEvent(event);
    if (snapshot.isEmpty) return;
    final patch = WatchStatePatch.fromSnapshot(snapshot);

    final cacheServerId = event.cacheServerId;
    final key = cacheServerId != null && cacheServerId.isNotEmpty && cacheServerId != event.serverId
        ? buildGlobalKey(ServerId(cacheServerId), event.itemId)
        : event.globalKey;
    _patches[key] = _WatchStatePatchEntry(patch, ++_sequence);
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
