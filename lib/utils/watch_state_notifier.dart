import '../media/media_item.dart';
import '../media/ids.dart';
import '../media/watch_progress.dart';
import 'app_logger.dart';
import 'base_notifier.dart';
import 'global_key_utils.dart';
import 'hierarchical_event_mixin.dart';
import 'media_event_keys.dart';

/// Identity of the store overlay entry a watch event creates.
///
/// Two forms, because the two paths that need to settle later have different
/// lifetimes:
/// - [WatchPatchId.session] is minted per event and dies with the process,
///   which is right for a live playback crossing.
/// - [WatchPatchId.offlineAction] is *derived* from the persisted queue row
///   `(profileId, rowId, revision)` rather than minted, so emission,
///   hydration and promotion still join after a restart. A minted id could
///   not: the database persists the row and its revision, nothing more.
///
/// Promotion matches on this, never on the global key — a same-item rewatch
/// must never be promoted or discarded in place of the action that settled.
class WatchPatchId {
  final String value;

  const WatchPatchId._(this.value);

  factory WatchPatchId.session(int sequence) => WatchPatchId._('s:$sequence');

  factory WatchPatchId.offlineAction({required String? profileId, required int rowId, required int revision}) =>
      WatchPatchId._('o:${profileId ?? ''}:$rowId:$revision');

  @override
  bool operator ==(Object other) => other is WatchPatchId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'WatchPatchId($value)';
}

enum WatchStateChangeType { watched, unwatched, progressUpdate, removedFromContinueWatching }

/// Event representing a watch state change with parent chain for hierarchical invalidation
class WatchStateEvent with HierarchicalEventMixin {
  /// The id of the item that changed (Plex ratingKey, Jellyfin GUID, …).
  @override
  final String itemId;

  /// Composite key: serverId:itemId
  @override
  final String globalKey;

  /// Server this item belongs to
  @override
  final ServerId serverId;

  /// Optional backend-private cache namespace for user-scoped servers.
  ///
  /// UI invalidation still uses [serverId], but cache writers should prefer
  /// this when present so Jellyfin user data stays isolated per user.
  final String? cacheServerId;

  /// Type of change
  final WatchStateChangeType changeType;

  /// Parent chain for hierarchical invalidation
  /// For an episode: [seasonId, showId]
  /// For a season: [showId]
  /// For a movie: []
  @override
  final List<String> parentChain;

  /// Media type that changed
  final String mediaType;

  /// New progress value (for progressUpdate)
  final int? viewOffset;

  /// Whether item is now considered watched (>90% progress or marked)
  final bool? isNowWatched;

  /// Library section this item belongs to — used for per-tracker library
  /// filtering. Null when emitted without full metadata. Plex sends a
  /// numeric id, Jellyfin sends a UUID; both round-trip as strings.
  final String? librarySectionID;

  /// Whether the server had already accepted this exact state when the event
  /// was emitted.
  ///
  /// Only an acknowledged patch may be superseded by a later authoritative
  /// read (#1829): an unacknowledged one represents a write still owed to the
  /// server, and a read must not retire it. Defaults to `false` so a new emit
  /// site that forgets to classify itself degrades to today's behaviour rather
  /// than silently becoming retireable.
  final bool serverAcknowledged;

  /// Identity of the overlay entry this event creates, for later promotion.
  /// Null for events nothing will ever settle.
  final WatchPatchId? patchId;

  WatchStateEvent({
    required this.itemId,
    required this.serverId,
    required this.changeType,
    required this.parentChain,
    required this.mediaType,
    this.cacheServerId,
    this.viewOffset,
    this.isNowWatched,
    this.librarySectionID,
    this.serverAcknowledged = false,
    this.patchId,
  }) : globalKey = buildGlobalKey(ServerId(serverId), itemId);

  /// `serverId:librarySectionID`, matching [MediaLibrary.globalKey]. Null when
  /// the library section is unknown; tracker filters treat unknown as allowed
  /// only when no filter is configured.
  String? get librarySectionGlobalKey =>
      librarySectionID != null ? buildGlobalKey(ServerId(serverId), librarySectionID!) : null;

  @override
  String toString() => 'WatchStateEvent($changeType, $globalKey, parents: $parentChain)';
}

/// Notifier for watch state changes across the app.
///
/// Singleton pattern following [LibraryRefreshNotifier]. Screens subscribe
/// to receive events when items are marked watched/unwatched or progress updates.
class WatchStateNotifier extends BaseNotifier<WatchStateEvent> {
  static final WatchStateNotifier _instance = WatchStateNotifier._internal();

  factory WatchStateNotifier() => _instance;

  WatchStateNotifier._internal();

  Stream<WatchStateEvent> forServer(ServerId serverId) => stream.where((e) => e.serverId == serverId);

  Stream<WatchStateEvent> forItem(String itemId) => stream.where((e) => e.affectsItem(itemId));

  /// Emit a watch state event with logging
  @override
  void notify(WatchStateEvent event) {
    appLogger.d('WatchStateNotifier: $event');
    super.notify(event);
  }

  /// Helper to emit a watched/unwatched event from a [MediaItem].
  ///
  /// Returns the [WatchPatchId] of the overlay entry it created so a caller
  /// that must settle later can promote that exact entry. Callers with
  /// nothing to settle ignore it.
  WatchPatchId? notifyWatched({
    required MediaItem item,
    bool isNowWatched = true,
    String? cacheServerId,
    bool serverAcknowledged = false,
    WatchPatchId? patchId,
  }) {
    final serverId = serverIdForEvent(item, notifier: 'WatchStateNotifier', event: 'watched');
    if (serverId == null) return null;
    final id = patchId ?? WatchPatchId.session(++_sequence);
    notify(
      WatchStateEvent(
        itemId: item.id,
        serverId: serverId,
        cacheServerId: cacheServerId,
        changeType: isNowWatched ? WatchStateChangeType.watched : WatchStateChangeType.unwatched,
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        isNowWatched: isNowWatched,
        librarySectionID: item.libraryId,
        serverAcknowledged: serverAcknowledged,
        patchId: id,
      ),
    );
    return id;
  }

  /// Monotonic source for session-minted [WatchPatchId]s.
  var _sequence = 0;

  /// Helper to emit a progress update event.
  /// [watchedThreshold] defaults to 0.9 — pass the server's configured value
  /// (`client.watchedThreshold`) when available.
  ///
  /// Returns the created [WatchPatchId], as [notifyWatched] does.
  WatchPatchId? notifyProgress({
    required MediaItem item,
    required int viewOffset,
    required int duration,
    String? cacheServerId,
    double watchedThreshold = 0.9,
    bool serverAcknowledged = false,
    WatchPatchId? patchId,
  }) {
    final serverId = serverIdForEvent(item, notifier: 'WatchStateNotifier', event: 'progress');
    if (serverId == null) return null;
    final isNowWatched = isWatchedProgress(positionMs: viewOffset, durationMs: duration, threshold: watchedThreshold);
    final id = patchId ?? WatchPatchId.session(++_sequence);

    notify(
      WatchStateEvent(
        itemId: item.id,
        serverId: serverId,
        cacheServerId: cacheServerId,
        changeType: WatchStateChangeType.progressUpdate,
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        viewOffset: viewOffset,
        isNowWatched: isNowWatched,
        librarySectionID: item.libraryId,
        serverAcknowledged: serverAcknowledged,
        patchId: id,
      ),
    );
    return id;
  }

  /// Helper to emit a Continue Watching removal event.
  void notifyRemovedFromContinueWatching({required MediaItem item}) {
    final serverId = serverIdForEvent(item, notifier: 'WatchStateNotifier', event: 'continue-watching removal');
    if (serverId == null) return;
    notify(
      WatchStateEvent(
        itemId: item.id,
        serverId: serverId,
        changeType: WatchStateChangeType.removedFromContinueWatching,
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        librarySectionID: item.libraryId,
      ),
    );
  }
}

/// A patch the server has now definitively accepted.
///
/// Deliberately *not* a [WatchStateEvent]: semantic subscribers must not see
/// promotions. `OfflineWatchSyncService` reacts to `watched`/`unwatched` by
/// purging queued progress, so replaying one here would delete a newer
/// rewatch — the very write promotion exists to protect.
///
/// [BaseNotifier] is single-stream by construction, and `WatchStateNotifier`
/// fixes its type to [WatchStateEvent], so this needs its own channel rather
/// than a discriminated union on the existing one.
class WatchPatchPromotion {
  final WatchPatchId patchId;

  const WatchPatchPromotion(this.patchId);

  @override
  String toString() => 'WatchPatchPromotion($patchId)';
}

/// Sibling singleton to [WatchStateNotifier] carrying non-semantic
/// promotions, following the same pattern as `LibraryRefreshNotifier`.
class WatchPatchPromotionNotifier extends BaseNotifier<WatchPatchPromotion> {
  static final WatchPatchPromotionNotifier _instance = WatchPatchPromotionNotifier._internal();

  factory WatchPatchPromotionNotifier() => _instance;

  WatchPatchPromotionNotifier._internal();

  void promote(WatchPatchId patchId) {
    appLogger.d('WatchPatchPromotionNotifier: promoting $patchId');
    notify(WatchPatchPromotion(patchId));
  }
}
