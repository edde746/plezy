import 'dart:async';
import '../models/plex_metadata.dart';
import 'app_logger.dart';

/// Event representing a media item deletion with parent chain for hierarchical invalidation
class DeletionEvent {
  /// The ratingKey of the deleted item
  final String ratingKey;

  /// Composite key: serverId:ratingKey
  final String globalKey;

  /// Server this item belongs to
  final String serverId;

  /// Parent chain for hierarchical invalidation
  /// For an episode: [seasonRatingKey, showRatingKey]
  /// For a season: [showRatingKey]
  /// For a movie: []
  final List<String> parentChain;

  /// Media type of the deleted item
  final String mediaType;

  /// Number of leaf items (episodes) contained in the deleted item.
  /// For an episode: 1. For a season: its episode count. For a show: its total episode count.
  final int leafCount;

  DeletionEvent({
    required this.ratingKey,
    required this.serverId,
    required this.parentChain,
    required this.mediaType,
    this.leafCount = 1,
  }) : globalKey = '$serverId:$ratingKey';

  /// Check if this event affects a specific item by ratingKey
  bool affectsItem(String ratingKey) => this.ratingKey == ratingKey || parentChain.contains(ratingKey);

  /// Check if this event affects a specific globalKey
  bool affectsGlobalKey(String globalKey) =>
      this.globalKey == globalKey || parentChain.any((pk) => '$serverId:$pk' == globalKey);

  /// Check if this event affects any item in a collection
  bool affectsAnyOf(Iterable<String> ratingKeys) => ratingKeys.any(affectsItem);

  /// Check if this event affects any item in a global-key collection
  bool affectsAnyGlobalKey(Iterable<String> globalKeys) => globalKeys.any(affectsGlobalKey);

  @override
  String toString() => 'DeletionEvent(deleted: $globalKey, type: $mediaType, parents: $parentChain)';
}

/// Notifier for media deletion events across the app.
///
/// Singleton pattern following [WatchStateNotifier]. Screens subscribe
/// to receive events when items are deleted from the server.
class DeletionNotifier {
  static final DeletionNotifier _instance = DeletionNotifier._internal();

  factory DeletionNotifier() => _instance;

  DeletionNotifier._internal();

  StreamController<DeletionEvent>? _controller;

  StreamController<DeletionEvent> get _ensureController {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<DeletionEvent>.broadcast();
    }
    return _controller!;
  }

  /// Stream of all deletion events
  Stream<DeletionEvent> get stream => _ensureController.stream;

  /// Filter for events affecting a specific server
  Stream<DeletionEvent> forServer(String serverId) => stream.where((e) => e.serverId == serverId);

  /// Filter for events affecting a specific item or its children
  Stream<DeletionEvent> forItem(String ratingKey) => stream.where((e) => e.affectsItem(ratingKey));

  /// Emit a deletion event
  void notify(DeletionEvent event) {
    appLogger.d('DeletionNotifier: $event');
    _ensureController.add(event);
  }

  /// Helper to emit a deletion event from metadata
  void notifyDeleted({required PlexMetadata metadata}) {
    notify(
      DeletionEvent(
        ratingKey: metadata.ratingKey,
        serverId: metadata.serverId ?? '',
        parentChain: _buildParentChain(metadata),
        mediaType: metadata.type,
        leafCount: metadata.leafCount ?? 1,
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

  void dispose() {
    _controller?.close();
    _controller = null;
  }
}
