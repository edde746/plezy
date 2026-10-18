import 'media_item.dart';

/// Client-only play queue used by Jellyfin and any backend without a
/// server-side queue concept.
///
/// Plex server-side queues (`/playQueues`) flow through the Plex
/// `PlayQueueResponse` model instead and never materialize as this type.
class LocalPlayQueue {
  final List<MediaItem> items;
  final int? currentIndex;
  final bool shuffled;

  const LocalPlayQueue({required this.items, this.currentIndex, this.shuffled = false});
}
