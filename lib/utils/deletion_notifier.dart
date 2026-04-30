import '../media/media_item.dart';
import 'app_logger.dart';
import 'base_notifier.dart';
import 'global_key_utils.dart';
import 'hierarchical_event_mixin.dart';

/// Event representing a media item deletion with parent chain for hierarchical invalidation
class DeletionEvent with HierarchicalEventMixin {
  /// The id of the deleted item (Plex ratingKey, Jellyfin GUID, …).
  @override
  final String itemId;

  /// Composite key: serverId:itemId
  @override
  final String globalKey;

  /// Server this item belongs to
  @override
  final String serverId;

  /// Parent chain for hierarchical invalidation
  /// For an episode: [seasonId, showId]
  /// For a season: [showId]
  /// For a movie: []
  @override
  final List<String> parentChain;

  /// Media type of the deleted item
  final String mediaType;

  /// Number of leaf items (episodes) contained in the deleted item.
  /// For an episode: 1. For a season: its episode count. For a show: its total episode count.
  final int leafCount;

  /// True if only the local download was deleted (not the server-side media).
  /// Screens should only remove items for download deletions when in offline mode.
  final bool isDownloadOnly;

  DeletionEvent({
    required this.itemId,
    required this.serverId,
    required this.parentChain,
    required this.mediaType,
    this.leafCount = 1,
    this.isDownloadOnly = false,
  }) : globalKey = buildGlobalKey(serverId, itemId);

  @override
  String toString() => 'DeletionEvent(deleted: $globalKey, type: $mediaType, parents: $parentChain)';
}

/// Notifier for media deletion events across the app.
///
/// Singleton pattern following [WatchStateNotifier]. Screens subscribe
/// to receive events when items are deleted from the server.
class DeletionNotifier extends BaseNotifier<DeletionEvent> {
  static final DeletionNotifier _instance = DeletionNotifier._internal();

  factory DeletionNotifier() => _instance;

  DeletionNotifier._internal();

  /// Filter for events affecting a specific server
  Stream<DeletionEvent> forServer(String serverId) => stream.where((e) => e.serverId == serverId);

  /// Filter for events affecting a specific item or its children
  Stream<DeletionEvent> forItem(String itemId) => stream.where((e) => e.affectsItem(itemId));

  /// Emit a deletion event with logging
  @override
  void notify(DeletionEvent event) {
    appLogger.d('DeletionNotifier: $event');
    super.notify(event);
  }

  /// Helper to emit a deletion event from a [MediaItem].
  void notifyDeletedItem({required MediaItem item, bool isDownloadOnly = false}) {
    notify(
      DeletionEvent(
        itemId: item.id,
        serverId: item.serverId ?? '',
        parentChain: item.parentChain,
        mediaType: item.kind.id,
        leafCount: item.leafCount ?? 1,
        isDownloadOnly: isDownloadOnly,
      ),
    );
  }
}
