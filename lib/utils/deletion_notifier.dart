import '../models/plex_metadata.dart';
import 'app_logger.dart';
import 'base_notifier.dart';
import 'global_key_utils.dart';
import 'hierarchical_event_mixin.dart';

/// Event representing a media item deletion with parent chain for hierarchical invalidation
class DeletionEvent with HierarchicalEventMixin {
  /// The ratingKey of the deleted item
  @override
  final String ratingKey;

  /// Composite key: serverId:ratingKey
  @override
  final String globalKey;

  /// Server this item belongs to
  @override
  final String serverId;

  /// Parent chain for hierarchical invalidation
  /// For an episode: [seasonRatingKey, showRatingKey]
  /// For a season: [showRatingKey]
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
    required this.ratingKey,
    required this.serverId,
    required this.parentChain,
    required this.mediaType,
    this.leafCount = 1,
    this.isDownloadOnly = false,
  }) : globalKey = buildGlobalKey(serverId, ratingKey);

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
  Stream<DeletionEvent> forItem(String ratingKey) => stream.where((e) => e.affectsItem(ratingKey));

  /// Emit a deletion event with logging
  @override
  void notify(DeletionEvent event) {
    appLogger.d('DeletionNotifier: $event');
    super.notify(event);
  }

  /// Helper to emit a deletion event from metadata
  void notifyDeleted({required PlexMetadata metadata, bool isDownloadOnly = false}) {
    notify(
      DeletionEvent(
        ratingKey: metadata.ratingKey,
        serverId: metadata.serverId ?? '',
        parentChain: _buildParentChain(metadata),
        mediaType: metadata.type,
        leafCount: metadata.leafCount ?? 1,
        isDownloadOnly: isDownloadOnly,
      ),
    );
  }

  /// Build parent chain from metadata's parent keys
  List<String> _buildParentChain(PlexMetadata metadata) {
    final chain = <String>[];
    if (metadata.parentRatingKey != null) {
      chain.add(metadata.parentRatingKey!);
    }
    if (metadata.grandparentRatingKey != null) {
      chain.add(metadata.grandparentRatingKey!);
    }
    return chain;
  }
}
