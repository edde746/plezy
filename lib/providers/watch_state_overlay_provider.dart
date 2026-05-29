import 'dart:async';

import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/watch_state_resolver.dart';
import '../utils/global_key_utils.dart';
import '../utils/watch_state_notifier.dart';

@immutable
class WatchStateOverlayPatch {
  final bool? isWatched;
  final bool hasViewOffsetMs;
  final int? viewOffsetMs;

  const WatchStateOverlayPatch({this.isWatched, this.hasViewOffsetMs = false, this.viewOffsetMs});

  factory WatchStateOverlayPatch.fromSnapshot(WatchStateSnapshot snapshot) => WatchStateOverlayPatch(
    isWatched: snapshot.isWatched,
    hasViewOffsetMs: snapshot.hasViewOffsetMs,
    viewOffsetMs: snapshot.viewOffsetMs,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchStateOverlayPatch &&
          other.isWatched == isWatched &&
          other.hasViewOffsetMs == hasViewOffsetMs &&
          other.viewOffsetMs == viewOffsetMs;

  @override
  int get hashCode => Object.hash(isWatched, hasViewOffsetMs, viewOffsetMs);
}

/// Session-local watch-state overlay for immediate UI freshness.
///
/// Server fetches remain the source of truth; this only patches stale
/// [MediaItem] snapshots while a screen waits for its next refresh.
class WatchStateOverlayProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  WatchStateOverlayProvider() {
    _subscription = WatchStateNotifier().stream.listen(_onWatchStateEvent);
  }

  StreamSubscription<WatchStateEvent>? _subscription;
  final Map<String, WatchStateOverlayPatch> _patches = {};
  String? _activeProfileId;
  Map<String, String?> _activeClientScopesByServer = const {};

  WatchStateOverlayPatch? patchForGlobalKey(String globalKey) {
    final parsed = parseGlobalKey(globalKey);
    if (parsed != null) {
      final scoped = _activeClientScopesByServer[parsed.serverId];
      if (scoped != null && scoped.isNotEmpty) {
        final scopedPatch = _patches[buildGlobalKey(scoped, parsed.ratingKey)];
        if (scopedPatch != null) return scopedPatch;
      }
    }
    return _patches[globalKey];
  }

  WatchStateOverlayPatch? patchForItem(MediaItem item) => patchForGlobalKey(item.globalKey);

  MediaItem apply(MediaItem item) {
    return applyPatch(item, patchForItem(item));
  }

  static MediaItem applyPatch(MediaItem item, WatchStateOverlayPatch? patch) {
    if (patch == null) return item;

    var updated = item;
    final isWatched = patch.isWatched;
    if (isWatched != null) {
      updated = updated.copyWith(viewCount: isWatched ? 1 : 0);
    }
    if (patch.hasViewOffsetMs) {
      updated = updated.copyWith(viewOffsetMs: patch.viewOffsetMs);
    }
    return updated;
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
    final patch = WatchStateOverlayPatch.fromSnapshot(WatchStateResolver.fromEvent(event));

    final cacheServerId = event.cacheServerId;
    final key = cacheServerId != null && cacheServerId.isNotEmpty && cacheServerId != event.serverId
        ? buildGlobalKey(cacheServerId, event.itemId)
        : event.globalKey;
    if (_patches[key] == patch) return;
    _patches[key] = patch;
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
