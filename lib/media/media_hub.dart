import 'media_item.dart';

/// A named, ordered list of items grouped on the home screen (Plex `Hub`,
/// or a synthesized Jellyfin "Latest"/"Resume"/"NextUp" row).
class MediaHub {
  /// Backend-opaque hub identifier (Plex `key`, synthesized for Jellyfin).
  final String id;

  /// Human-readable hub identifier for analytics and routing — e.g.
  /// `home.continue`, `tv.recentlyadded`. Synthesized for Jellyfin.
  final String? identifier;

  final String title;

  /// Hub kind: `movie`, `show`, `mixed`, `clip`, etc. — drives UI rendering.
  final String type;

  final List<MediaItem> items;

  /// Total number of items the server reports (may exceed [items.length] when
  /// a "see more" affordance is available).
  final int size;

  /// Whether more items are available beyond what's loaded.
  final bool more;

  /// When set, this hub was split from a multi-library hub and should only
  /// show items belonging to this library.
  final String? libraryId;

  final String? serverId;
  final String? serverName;

  const MediaHub({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    this.identifier,
    this.size = 0,
    this.more = false,
    this.libraryId,
    this.serverId,
    this.serverName,
  });

  MediaHub copyWith({
    String? id,
    String? identifier,
    String? title,
    String? type,
    List<MediaItem>? items,
    int? size,
    bool? more,
    String? libraryId,
    String? serverId,
    String? serverName,
  }) {
    return MediaHub(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      type: type ?? this.type,
      items: items ?? this.items,
      size: size ?? this.size,
      more: more ?? this.more,
      libraryId: libraryId ?? this.libraryId,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}
