import '../utils/app_logger.dart';

/// Backend identifier for a media item, library, or server.
///
/// Used as a discriminator on neutral domain types so consumers can branch on
/// backend-specific behavior (e.g. only Plex supports server-side play queues
/// in v1) and so persisted records can round-trip the source of an item.
enum MediaBackend {
  plex,
  jellyfin;

  String get id => switch (this) {
    MediaBackend.plex => 'plex',
    MediaBackend.jellyfin => 'jellyfin',
  };

  static MediaBackend fromId(String id) => switch (id) {
    'plex' => MediaBackend.plex,
    'jellyfin' => MediaBackend.jellyfin,
    _ => throw ArgumentError('Unknown MediaBackend id: $id'),
  };

  /// Like [fromId] but tolerates legacy/missing values by defaulting to Plex.
  /// Used by JSON deserialization of cached offline data:
  /// - `null` is the pre-Jellyfin shape and silently defaults to Plex.
  /// - An unrecognized non-null id logs a warning and defaults to Plex; this
  ///   surfaces corrupted cache rows or schema drift instead of silently
  ///   misclassifying Jellyfin items as Plex.
  static MediaBackend fromString(String? id) {
    if (id != null && id != 'plex' && id != 'jellyfin') {
      appLogger.w('Unknown MediaBackend id "$id"; defaulting to plex');
    }
    return switch (id) {
      'jellyfin' => MediaBackend.jellyfin,
      _ => MediaBackend.plex,
    };
  }
}
