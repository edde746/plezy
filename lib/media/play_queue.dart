import 'media_item.dart';

/// Client-only play queue used by Jellyfin and any backend without a
/// server-side queue concept. Each [LocalPlayQueue] is anchored by a
/// client-generated UUID so callers can address it like a Plex queue.
///
/// Plex server-side queues (`/playQueues`) flow through the Plex
/// `PlayQueueResponse` model instead and never materialize as this type.
class LocalPlayQueue {
  /// Client-generated UUID identifying this queue for the session.
  final String id;
  final List<MediaItem> items;
  final int? currentIndex;
  final bool shuffled;

  const LocalPlayQueue({required this.id, required this.items, this.currentIndex, this.shuffled = false});
}
