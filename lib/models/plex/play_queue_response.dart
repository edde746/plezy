import '../../media/media_item.dart';

/// Response from Plex play queue API.
/// Contains queue metadata and a window of items in neutral [MediaItem] form.
class PlayQueueResponse {
  final int playQueueID;
  final int? playQueueSelectedItemID;
  final int? playQueueSelectedItemOffset;
  final String? playQueueSelectedMetadataItemID;
  final bool playQueueShuffled;
  final String? playQueueSourceURI;
  final int? playQueueTotalCount;
  final int playQueueVersion;
  final int? size; // Number of items in this response window
  final List<MediaItem>? items;

  PlayQueueResponse({
    required this.playQueueID,
    this.playQueueSelectedItemID,
    this.playQueueSelectedItemOffset,
    this.playQueueSelectedMetadataItemID,
    required this.playQueueShuffled,
    this.playQueueSourceURI,
    required this.playQueueTotalCount,
    required this.playQueueVersion,
    this.size,
    this.items,
  });

  /// Get the current selected item from the queue. Items in a Plex
  /// `PlayQueueResponse` are always [PlexMediaItem]; the cast is safe.
  MediaItem? get selectedItem {
    if (items == null || playQueueSelectedItemID == null) return null;
    try {
      return items!.firstWhere((item) => item is PlexMediaItem && item.playQueueItemId == playQueueSelectedItemID);
    } catch (e) {
      return null;
    }
  }

  int? get selectedItemIndex {
    if (items == null || playQueueSelectedItemID == null) return null;
    return items!.indexWhere((item) => item is PlexMediaItem && item.playQueueItemId == playQueueSelectedItemID);
  }
}
