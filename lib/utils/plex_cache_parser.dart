/// Utility class for parsing Plex API cache responses
///
/// Provides consistent extraction of MediaContainer data across the codebase.
class PlexCacheParser {
  PlexCacheParser._();

  /// Extract the Metadata list from a cached response
  ///
  /// Returns null if MediaContainer or Metadata is not present
  static List<dynamic>? extractMetadataList(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    return cached['MediaContainer']?['Metadata'] as List?;
  }

  /// Extract the first metadata item from a cached response
  ///
  /// Returns null if no metadata exists
  static Map<String, dynamic>? extractFirstMetadata(
    Map<String, dynamic>? cached,
  ) {
    final list = extractMetadataList(cached);
    if (list == null || list.isEmpty) return null;
    return list[0] as Map<String, dynamic>;
  }

  /// Check if a cached response has valid metadata
  static bool hasMetadata(Map<String, dynamic>? cached) {
    final list = extractMetadataList(cached);
    return list != null && list.isNotEmpty;
  }

  /// Extract Directory list from a cached response (for libraries, playlists)
  static List<dynamic>? extractDirectoryList(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    return cached['MediaContainer']?['Directory'] as List?;
  }

  /// Extract Hub list from a cached response
  static List<dynamic>? extractHubList(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    return cached['MediaContainer']?['Hub'] as List?;
  }

  /// Extract Chapter list from the first metadata item
  static List<dynamic>? extractChapters(Map<String, dynamic>? cached) {
    final metadata = extractFirstMetadata(cached);
    if (metadata == null) return null;
    return metadata['Chapter'] as List?;
  }

  /// Extract Marker list from the first metadata item
  static List<dynamic>? extractMarkers(Map<String, dynamic>? cached) {
    final metadata = extractFirstMetadata(cached);
    if (metadata == null) return null;
    return metadata['Marker'] as List?;
  }
}
