import 'dart:async';
import '../models/plex_metadata.dart';
import 'app_logger.dart';

/// Types of watch state changes
enum WatchStateChangeType { watched, unwatched, progressUpdate }

/// Event representing a watch state change with parent chain for hierarchical invalidation
class WatchStateEvent {
  /// The item that changed
  final String ratingKey;

  /// Composite key: serverId:ratingKey
  final String globalKey;

  /// Server this item belongs to
  final String serverId;

  /// Type of change
  final WatchStateChangeType changeType;

  /// Parent chain for hierarchical invalidation
  /// For an episode: [seasonRatingKey, showRatingKey]
  /// For a season: [showRatingKey]
  /// For a movie: []
  final List<String> parentChain;

  /// Media type that changed
  final String mediaType;

  /// New progress value (for progressUpdate)
  final int? viewOffset;

  /// Whether item is now considered watched (>90% progress or marked)
  final bool? isNowWatched;

  WatchStateEvent({
    required this.ratingKey,
    required this.serverId,
    required this.changeType,
    required this.parentChain,
    required this.mediaType,
    this.viewOffset,
    this.isNowWatched,
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
  String toString() => 'WatchStateEvent($changeType, $globalKey, parents: $parentChain)';
}

/// Notifier for watch state changes across the app.
///
/// Singleton pattern following [LibraryRefreshNotifier]. Screens subscribe
/// to receive events when items are marked watched/unwatched or progress updates.
class WatchStateNotifier {
  static final WatchStateNotifier _instance = WatchStateNotifier._internal();

  factory WatchStateNotifier() => _instance;

  WatchStateNotifier._internal();

  StreamController<WatchStateEvent>? _controller;

  StreamController<WatchStateEvent> get _ensureController {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<WatchStateEvent>.broadcast();
    }
    return _controller!;
  }

  /// Stream of all watch state events
  Stream<WatchStateEvent> get stream => _ensureController.stream;

  /// Filter for events affecting a specific server
  Stream<WatchStateEvent> forServer(String serverId) => stream.where((e) => e.serverId == serverId);

  /// Filter for events affecting a specific item or its children
  Stream<WatchStateEvent> forItem(String ratingKey) => stream.where((e) => e.affectsItem(ratingKey));

  /// Emit a watch state event
  void notify(WatchStateEvent event) {
    appLogger.d('WatchStateNotifier: $event');
    _ensureController.add(event);
  }

  /// Helper to emit a watched/unwatched event from metadata
  void notifyWatched({required PlexMetadata metadata, bool isNowWatched = true}) {
    notify(
      WatchStateEvent(
        ratingKey: metadata.ratingKey,
        serverId: metadata.serverId ?? '',
        changeType: isNowWatched ? WatchStateChangeType.watched : WatchStateChangeType.unwatched,
        parentChain: _buildParentChain(metadata),
        mediaType: metadata.type,
        isNowWatched: isNowWatched,
      ),
    );
  }

  /// Helper to emit a progress update event
  void notifyProgress({required PlexMetadata metadata, required int viewOffset, required int duration}) {
    const threshold = 0.90;
    final isNowWatched = duration > 0 && (viewOffset / duration) >= threshold;

    notify(
      WatchStateEvent(
        ratingKey: metadata.ratingKey,
        serverId: metadata.serverId ?? '',
        changeType: WatchStateChangeType.progressUpdate,
        parentChain: _buildParentChain(metadata),
        mediaType: metadata.type,
        viewOffset: viewOffset,
        isNowWatched: isNowWatched,
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
