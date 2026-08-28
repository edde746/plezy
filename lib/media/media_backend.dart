import '../utils/app_logger.dart';
import 'media_browser_dialect.dart';

/// Backend identifier for a media item, library, or server.
///
/// Used as a discriminator on neutral domain types so consumers can branch on
/// backend-specific behavior (e.g. only Plex supports server-side play queues
/// in v1) and so persisted records can round-trip the source of an item.
enum MediaBackend {
  plex,
  jellyfin,
  emby;

  String get id => switch (this) {
    MediaBackend.plex => 'plex',
    MediaBackend.jellyfin => 'jellyfin',
    MediaBackend.emby => 'emby',
  };

  String get productName => switch (this) {
    MediaBackend.plex => 'Plex',
    MediaBackend.jellyfin => 'Jellyfin',
    MediaBackend.emby => 'Emby',
  };

  static MediaBackend fromId(String id) => switch (id) {
    'plex' => MediaBackend.plex,
    'jellyfin' => MediaBackend.jellyfin,
    'emby' => MediaBackend.emby,
    _ => throw ArgumentError('Unknown MediaBackend id: $id'),
  };

  /// Like [fromId] but tolerates legacy/missing values by defaulting to Plex.
  /// Used by JSON deserialization of cached offline data:
  /// - `null` is the pre-Jellyfin shape and silently defaults to Plex.
  /// - An unrecognized non-null id logs a warning and defaults to Plex; this
  ///   surfaces corrupted cache rows or schema drift instead of silently
  ///   misclassifying Jellyfin items as Plex.
  static MediaBackend fromString(String? id) {
    if (id != null && id != 'plex' && id != 'jellyfin' && id != 'emby') {
      appLogger.w('Unknown MediaBackend id "$id"; defaulting to plex');
    }
    return switch (id) {
      'jellyfin' => MediaBackend.jellyfin,
      'emby' => MediaBackend.emby,
      _ => MediaBackend.plex,
    };
  }

  /// True for backends served by the MediaBrowser HTTP API — Jellyfin and its
  /// Emby ancestor. They share one client stack, one query grammar and one set
  /// of DTO shapes, so behaviour keyed to "not Plex" should test this instead
  /// of comparing against [MediaBackend.jellyfin].
  bool get usesMediaBrowserApi => dialect != null;

  /// The MediaBrowser dialect this backend speaks, or `null` for Plex.
  MediaBrowserDialect? get dialect => switch (this) {
    MediaBackend.plex => null,
    MediaBackend.jellyfin => MediaBrowserDialect.jellyfin,
    MediaBackend.emby => MediaBrowserDialect.emby,
  };
}
