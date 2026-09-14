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
class HydratedWatchStatePatch {
  final String globalKey;
  final WatchStateSnapshot patch;
  final int updatedAt;
  final int order;

  const HydratedWatchStatePatch({
    required this.globalKey,
    required this.patch,
    required this.updatedAt,
    required this.order,
  });
}

/// Key for [WatchStateStore]'s observation map: a global key already resolved
/// through the client scope its request was issued under. A plain `String`
/// would work, but the wrapper keeps the two key spaces from being confused
/// with the patch maps' keys at a glance.
class _ObservationKey {
  final String value;

  const _ObservationKey(this.value);

  @override
  bool operator ==(Object other) => other is _ObservationKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class _WatchStatePatchEntry {
  final WatchStateSnapshot patch;
  final int updatedAt;
  final int sequence;
  final bool isSessionEvent;

  /// Whether the server had accepted this exact state when the entry was
  /// recorded. Only an acknowledged entry may be superseded by a later
  /// authoritative read; an unacknowledged one is a write still owed to the
  /// server and must outlive any read (#1829).
  final bool serverAcknowledged;

  /// Identity used to promote this exact entry once its write settles.
  /// Promotion never matches by global key: a same-item rewatch may already
  /// have replaced the entry, and it must not be promoted in its place.
  final WatchPatchId? patchId;

  const _WatchStatePatchEntry(
    this.patch, {
    required this.updatedAt,
    required this.sequence,
    required this.isSessionEvent,
    this.serverAcknowledged = false,
    this.patchId,
  });

  _WatchStatePatchEntry acknowledgedAt(int sequence) => _WatchStatePatchEntry(
    patch,
    updatedAt: updatedAt,
    sequence: sequence,
    isSessionEvent: true,
    serverAcknowledged: true,
    patchId: patchId,
  );

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
      other.isSessionEvent == isSessionEvent &&
      other.serverAcknowledged == serverAcknowledged &&
      other.patchId == patchId;

  @override
  int get hashCode => Object.hash(patch, updatedAt, sequence, isSessionEvent, serverAcknowledged, patchId);
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
    // A second, separately owned subscription: promotions are deliberately
    // not WatchStateEvents, and BaseNotifier carries exactly one typed
    // stream, so they cannot arrive on the channel above.
    _promotionSubscription = WatchPatchPromotionNotifier().stream.listen(_onPromotion);
  }

  StreamSubscription<WatchStateEvent>? _subscription;
  StreamSubscription<WatchPatchPromotion>? _promotionSubscription;
  final Map<String, _WatchStatePatchEntry> _patches = {};
  final Map<String, _WatchStatePatchEntry> _hydratedPatches = {};
  String? _activeProfileId;
  Map<String, String?> _activeClientScopesByServer = const {};
  int _sequence = 0;

  /// Highest watermark at which a qualifying authoritative response returned a
  /// key, under the client scope its request was issued for.
  ///
  /// This records *that* the server re-observed an item, never *what* it
  /// observed. Storing the observed state instead would need full fidelity
  /// ([WatchStateSnapshot] cannot hold a container's leaf counts) and would
  /// make two responses sharing a watermark first-response-wins. A watermark
  /// has neither problem: it is a single int, and [recordObservations] keeps
  /// the max, so response order cannot matter.
  final Map<_ObservationKey, int> _observedAt = {};

  /// Snapshot the current sequence *before* issuing an authoritative request;
  /// pass it back to [recordObservations] when that request succeeds.
  int get observationWatermark => _sequence;

  /// Identifies this store instance. Watermarks are store-local, but clients —
  /// and their in-flight requests — outlive a profile switch, so a response
  /// minted against the previous store must not be applied to this one.
  final Object _epoch = Object();

  Object get observationEpoch => _epoch;

  _WatchStatePatchEntry? _exactEntryFor(String globalKey, int? observedAt) {
    final session = _live(_patches[globalKey], observedAt);
    final hydrated = _hydratedPatches[globalKey];
    if (session == null) return hydrated;
    if (hydrated == null) return session;
    return session.isNewerThan(hydrated) ? session : hydrated;
  }

  /// Drops an acknowledged session entry the server has re-observed since.
  ///
  /// Only acknowledged entries are eligible: an unacknowledged one is a write
  /// still owed to the server, and a read must never retire it. Hydrated
  /// entries are the persisted owed-write layer and are likewise untouched —
  /// filtering happens per layer, before [_exactEntryFor] chooses, so a
  /// suppressed session entry falls back to an older hydrated one instead of
  /// suppressing both.
  static _WatchStatePatchEntry? _live(_WatchStatePatchEntry? entry, int? observedAt) {
    if (entry == null) return null;
    if (!entry.serverAcknowledged || observedAt == null) return entry;
    return observedAt >= entry.sequence ? null : entry;
  }

  /// Candidate keys for [globalKey], in the order [_entryFor] consults them:
  /// the active client scope first, then the public fallback.
  List<String> _candidateKeys(String globalKey) {
    final parsed = parseGlobalKey(globalKey);
    if (parsed != null) {
      final scoped = _activeClientScopesByServer[parsed.serverId];
      if (scoped != null && scoped.isNotEmpty) {
        return [buildGlobalKey(ServerId(scoped), parsed.ratingKey), globalKey];
      }
    }
    return [globalKey];
  }

  _WatchStatePatchEntry? _entryFor(String globalKey, [int? observedAt]) {
    for (final key in _candidateKeys(globalKey)) {
      final entry = _exactEntryFor(key, observedAt);
      if (entry != null) return entry;
    }
    return null;
  }

  /// The watermark at which [globalKey] was last authoritatively observed.
  ///
  /// Resolved through the *primary* candidate only — the active client scope
  /// when there is one, else the public key. Deliberately not a max over both:
  /// on a user-scoped backend the public server id is shared between users, so
  /// letting a public observation satisfy a scoped patch would suppress
  /// another user's watch state.
  int? _observationFor(String globalKey) => _observedAt[_ObservationKey(_candidateKeys(globalKey).first)];

  @visibleForTesting
  WatchStateSnapshot? patchForGlobalKey(String globalKey) => _entryFor(globalKey, _observationFor(globalKey))?.patch;

  WatchStateSnapshot? patchForItem(MediaItem item) {
    if (_patches.isEmpty && _hydratedPatches.isEmpty) return null;
    // One barrier for the whole resolution: an authoritative read of *this*
    // item already incorporates any container mark that preceded it, so the
    // ancestor candidates are judged against the item's own observation too.
    // Suppressing only the item's own entry would let an older season patch
    // win and render something worse than either value (#1829 review).
    final observedAt = _observationFor(item.globalKey);
    var best = _entryFor(item.globalKey, observedAt);
    if (item.parentChain.isNotEmpty) {
      final serverId = serverIdOrNull(item.serverId);
      for (final parentId in item.parentChain) {
        // Mirror MediaItem.globalKey's bare-id fallback when serverId is missing.
        final entry = _entryFor(serverId != null ? buildGlobalKey(serverId, parentId) : parentId, observedAt);
        if (entry != null && (best == null || entry.isNewerThan(best))) best = entry;
      }
    }
    return best?.patch;
  }

  /// Record that a successful authoritative response returned [rows].
  ///
  /// [watermark] must be [observationWatermark] captured immediately before
  /// the network call, and [epoch] the [observationEpoch] of the store that
  /// captured it. Entries recorded *during* the request keep a higher
  /// sequence and survive, so a local action taken mid-flight always wins.
  ///
  /// Each row carries the immutable cache scope of the client that fetched
  /// it: on a user-scoped backend the public server id is shared, so a row
  /// must only ever reconcile the scope it actually came from.
  void recordObservations(
    Iterable<({MediaItem item, String? clientScope})> rows, {
    required int watermark,
    required Object epoch,
  }) {
    // Watermarks are store-local, but clients — and their in-flight requests
    // — outlive a profile switch, so a response minted against the previous
    // store carries a sequence that means nothing here.
    if (!identical(epoch, _epoch)) return;
    if (_patches.isEmpty) return;
    var changed = false;
    for (final row in rows) {
      final item = row.item;
      // An observation is only ever consulted to suppress a patch, so keep
      // one only while some patch could still apply to this item — its own,
      // or an ancestor's, which the barrier in [patchForItem] also judges
      // against this key. That bounds the map by the items the user acted
      // on rather than by everything ever fetched.
      if (!_hasSuppressibleEntry(item)) continue;
      final scope = row.clientScope;
      final key = _ObservationKey(
        scope != null && scope.isNotEmpty && scope != item.serverId
            ? buildGlobalKey(ServerId(scope), item.id)
            : item.globalKey,
      );
      final existing = _observedAt[key];
      if (existing != null && existing >= watermark) continue;
      _observedAt[key] = watermark;
      changed = true;
    }
    if (changed) safeNotifyListeners();
  }

  bool _hasSuppressibleEntry(MediaItem item) {
    for (final key in _candidateKeys(item.globalKey)) {
      if (_patches[key]?.serverAcknowledged ?? false) return true;
    }
    if (item.parentChain.isEmpty) return false;
    final serverId = serverIdOrNull(item.serverId);
    for (final parentId in item.parentChain) {
      final parentKey = serverId != null ? buildGlobalKey(serverId, parentId) : parentId;
      for (final key in _candidateKeys(parentKey)) {
        if (_patches[key]?.serverAcknowledged ?? false) return true;
      }
    }
    return false;
  }

  MediaItem apply(MediaItem item) {
    return applyPatch(item, patchForItem(item));
  }

  List<MediaItem> applyAll(List<MediaItem> items) {
    if (_patches.isEmpty && _hydratedPatches.isEmpty) return items;
    return [for (final item in items) apply(item)];
  }

  static MediaItem applyPatch(MediaItem item, WatchStateSnapshot? patch) => patch == null ? item : patch.apply(item);

  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    if (_patches.isEmpty && _hydratedPatches.isEmpty && _observedAt.isEmpty) return;
    _patches.clear();
    _hydratedPatches.clear();
    // Observations are only meaningful against the patches they suppress.
    _observedAt.clear();
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
    final activeScope = _activeClientScopesByServer[event.serverId];
    final eventScope = event.cacheServerId;
    if (activeScope != null &&
        activeScope.isNotEmpty &&
        eventScope != null &&
        eventScope.isNotEmpty &&
        eventScope != event.serverId &&
        eventScope != activeScope) {
      return;
    }
    final resolvedScope = activeScope != null && activeScope.isNotEmpty ? activeScope : eventScope;
    final key = resolvedScope != null && resolvedScope.isNotEmpty && resolvedScope != event.serverId
        ? buildGlobalKey(ServerId(resolvedScope), event.itemId)
        : event.globalKey;
    _patches[key] = _WatchStatePatchEntry(
      snapshot,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      sequence: ++_sequence,
      isSessionEvent: true,
      serverAcknowledged: event.serverAcknowledged,
      patchId: event.patchId,
    );
    safeNotifyListeners();
  }

  /// The write behind [promotion] has settled, so its entry may now be
  /// superseded by a later authoritative read.
  ///
  /// Matching is by patch identity, never by key: an unknown id — because a
  /// newer action replaced the entry, or because the process restarted — is a
  /// deliberate no-op. The fresh sequence matters as much as the flag: an
  /// observation captured *before* the write landed must not suppress the
  /// entry it predates.
  void _onPromotion(WatchPatchPromotion promotion) {
    final sessionKey = _keyForPatchId(_patches, promotion.patchId);
    if (sessionKey != null) {
      _patches[sessionKey] = _patches[sessionKey]!.acknowledgedAt(++_sequence);
      safeNotifyListeners();
      return;
    }

    // A hydrated entry is the persisted owed-write layer. Once the write has
    // landed it no longer belongs there, and leaving it would make it
    // immortal, since suppression only ever considers session entries. Move
    // it — but never over a newer session entry on the same key, which would
    // defeat the exact-identity rule promotion exists for.
    final hydratedKey = _keyForPatchId(_hydratedPatches, promotion.patchId);
    if (hydratedKey == null) return;
    final promoted = _hydratedPatches.remove(hydratedKey)!;
    final existing = _patches[hydratedKey];
    if (existing == null || existing.patchId == promotion.patchId) {
      _patches[hydratedKey] = promoted.acknowledgedAt(++_sequence);
    }
    safeNotifyListeners();
  }

  static String? _keyForPatchId(Map<String, _WatchStatePatchEntry> entries, WatchPatchId patchId) {
    for (final entry in entries.entries) {
      if (entry.value.patchId == patchId) return entry.key;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _promotionSubscription?.cancel();
    _promotionSubscription = null;
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
      final patch = select<WatchStateStore, WatchStateSnapshot?>((store) => store.patchForItem(item));
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
