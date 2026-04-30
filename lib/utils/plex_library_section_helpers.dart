import '../media/media_item.dart';

/// Plex-only helpers for navigating to a "library section" hub entry.
///
/// Plex's home/discover hubs occasionally surface library-section rows
/// (`/library/sections/{id}/all`) alongside individual items; the
/// `PlexMappers` adapter stashes the section key in [MediaItem.raw] under
/// `'key'` so navigation code can detect and route to the library screen
/// instead of the media-detail screen.
///
/// Jellyfin's analogue is the dedicated `MediaLibrary` shape — Jellyfin
/// "views" never appear inside a [MediaItem], so these helpers correctly
/// return `false`/`null` for any Jellyfin item.
extension PlexLibrarySection on MediaItem {
  /// Whether this item represents a Plex library section (shared
  /// whole-library entry, not a media item).
  bool get isLibrarySection {
    final key = raw?['key'];
    return key is String && key.startsWith('/library/sections/');
  }

  /// Extract the library section id from the stashed Plex `raw['key']`.
  /// Returns `null` for non-section items or items without a parsable id.
  String? get librarySectionKey {
    if (!isLibrarySection) return null;
    final key = raw?['key'] as String?;
    if (key == null) return null;
    final match = RegExp(r'/library/sections/(\d+)').firstMatch(key);
    return match?.group(1);
  }
}
