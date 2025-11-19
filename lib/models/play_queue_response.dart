import 'package:json_annotation/json_annotation.dart';
import 'plex_metadata.dart';

part 'play_queue_response.g.dart';

/// Converter to handle both int (0/1) and bool values from Plex API
class BoolOrIntConverter implements JsonConverter<bool, Object> {
  const BoolOrIntConverter();

  @override
  bool fromJson(Object json) {
    if (json is bool) return json;
    if (json is int) return json != 0;
    if (json is String) return json.toLowerCase() == 'true' || json == '1';
    return false;
  }

  @override
  Object toJson(bool object) => object;
}

/// Response from Plex play queue API
/// Contains queue metadata and a window of items
@JsonSerializable(createToJson: false)
class PlayQueueResponse {
  final int playQueueID;
  final int? playQueueSelectedItemID;
  final int? playQueueSelectedItemOffset;
  final String? playQueueSelectedMetadataItemID;
  @BoolOrIntConverter()
  final bool playQueueShuffled;
  final String? playQueueSourceURI;
  final int? playQueueTotalCount;
  final int playQueueVersion;
  final int? size; // Number of items in this response window
  @JsonKey(name: 'Metadata')
  final List<PlexMetadata>? items;

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

  factory PlayQueueResponse.fromJson(Map<String, dynamic> json) {
    // The API returns data wrapped in MediaContainer
    final container = json['MediaContainer'] as Map<String, dynamic>? ?? json;
    return _$PlayQueueResponseFromJson(container);
  }

  /// Get the current selected item from the queue
  PlexMetadata? get selectedItem {
    if (items == null || playQueueSelectedItemID == null) return null;
    try {
      return items!.firstWhere(
        (item) => item.playQueueItemID == playQueueSelectedItemID,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the index of the selected item in the current window
  int? get selectedItemIndex {
    if (items == null || playQueueSelectedItemID == null) return null;
    return items!.indexWhere(
      (item) => item.playQueueItemID == playQueueSelectedItemID,
    );
  }
}
