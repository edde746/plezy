import 'media_item.dart';

/// Backend-neutral play queue — a flat ordered list of items with a current
/// cursor. Implementations differ in whether the queue is server-resourced
/// (Plex) or client-only (Jellyfin).
sealed class PlayQueue {
  /// Items in playback order.
  List<MediaItem> get items;

  /// Index of the currently-playing item, or `null` if the queue has not
  /// started.
  int? get currentIndex;

  /// Whether the queue has been shuffled.
  bool get shuffled;

  /// Backend that minted this queue.
  String get backendId;

  MediaItem? get current =>
      currentIndex != null && currentIndex! >= 0 && currentIndex! < items.length ? items[currentIndex!] : null;

  bool get hasNext => currentIndex != null && currentIndex! + 1 < items.length;
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;
}

/// Plex play queue — coordinated server-side via `/playQueues` so multiple
/// devices can view/control the same queue.
class PlexServerPlayQueue extends PlayQueue {
  /// Plex `playQueueID` — addresses the queue for subsequent fetches.
  final int playQueueId;

  @override
  final List<MediaItem> items;

  @override
  final int? currentIndex;

  @override
  final bool shuffled;

  /// Plex `playQueueSelectedItemID` of the active item.
  final int? selectedItemId;

  /// Plex `playQueueVersion` — server-side optimistic concurrency token.
  final int? version;

  /// Plex `playQueueSourceURI` — used for "Up Next" derivation.
  final String? sourceUri;

  PlexServerPlayQueue({
    required this.playQueueId,
    required this.items,
    this.currentIndex,
    this.shuffled = false,
    this.selectedItemId,
    this.version,
    this.sourceUri,
  });

  @override
  String get backendId => 'plex';

  PlexServerPlayQueue copyWith({
    int? playQueueId,
    List<MediaItem>? items,
    int? currentIndex,
    bool? shuffled,
    int? selectedItemId,
    int? version,
    String? sourceUri,
  }) {
    return PlexServerPlayQueue(
      playQueueId: playQueueId ?? this.playQueueId,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffled: shuffled ?? this.shuffled,
      selectedItemId: selectedItemId ?? this.selectedItemId,
      version: version ?? this.version,
      sourceUri: sourceUri ?? this.sourceUri,
    );
  }
}

/// Client-only play queue used by Jellyfin and any backend without a
/// server-side queue concept. Each [LocalPlayQueue] is anchored by a
/// client-generated UUID so callers can address it like a Plex queue.
class LocalPlayQueue extends PlayQueue {
  /// Client-generated UUID identifying this queue for the session.
  final String id;

  @override
  final List<MediaItem> items;

  @override
  final int? currentIndex;

  @override
  final bool shuffled;

  /// Server kind that owns this queue's items (typically `"jellyfin"`).
  @override
  final String backendId;

  LocalPlayQueue({
    required this.id,
    required this.items,
    required this.backendId,
    this.currentIndex,
    this.shuffled = false,
  });

  LocalPlayQueue copyWith({String? id, List<MediaItem>? items, int? currentIndex, bool? shuffled, String? backendId}) {
    return LocalPlayQueue(
      id: id ?? this.id,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffled: shuffled ?? this.shuffled,
      backendId: backendId ?? this.backendId,
    );
  }
}
