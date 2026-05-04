import '../media/media_item.dart';
import 'app_logger.dart';
import 'base_notifier.dart';
import 'global_key_utils.dart';
import 'hierarchical_event_mixin.dart';

enum WatchStateChangeType { watched, unwatched, progressUpdate }

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
  final String serverId;

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
  }) : globalKey = buildGlobalKey(serverId, itemId);

  /// `serverId:librarySectionID`, matching [MediaLibrary.globalKey]. Null when
  /// the library section is unknown.
  String? get librarySectionGlobalKey => librarySectionID != null ? buildGlobalKey(serverId, librarySectionID!) : null;

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

  Stream<WatchStateEvent> forServer(String serverId) => stream.where((e) => e.serverId == serverId);

  Stream<WatchStateEvent> forItem(String itemId) => stream.where((e) => e.affectsItem(itemId));

  /// Emit a watch state event with logging
  @override
  void notify(WatchStateEvent event) {
    appLogger.d('WatchStateNotifier: $event');
    super.notify(event);
  }

  /// Helper to emit a watched/unwatched event from a [MediaItem].
  void notifyWatched({required MediaItem item, bool isNowWatched = true, String? cacheServerId}) {
    notify(
      WatchStateEvent(
        itemId: item.id,
        serverId: item.serverId ?? '',
        cacheServerId: cacheServerId,
        changeType: isNowWatched ? WatchStateChangeType.watched : WatchStateChangeType.unwatched,
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        isNowWatched: isNowWatched,
        librarySectionID: item.libraryId,
      ),
    );
  }

  /// Helper to emit a progress update event.
  /// [watchedThreshold] defaults to 0.9 — pass the server's configured value
  /// (`client.watchedThreshold`) when available.
  void notifyProgress({
    required MediaItem item,
    required int viewOffset,
    required int duration,
    double watchedThreshold = 0.9,
  }) {
    final isNowWatched = duration > 0 && (viewOffset / duration) >= watchedThreshold;

    notify(
      WatchStateEvent(
        itemId: item.id,
        serverId: item.serverId ?? '',
        changeType: WatchStateChangeType.progressUpdate,
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        viewOffset: viewOffset,
        isNowWatched: isNowWatched,
        librarySectionID: item.libraryId,
      ),
    );
  }
}
