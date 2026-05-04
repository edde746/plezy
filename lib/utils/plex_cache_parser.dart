/// Utility class for parsing Plex API cache responses
///
/// Provides consistent extraction of MediaContainer data across the codebase.
class PlexCacheParser {
  PlexCacheParser._();

  static List<dynamic>? extractMetadataList(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    return cached['MediaContainer']?['Metadata'] as List?;
  }

  static Map<String, dynamic>? extractFirstMetadata(Map<String, dynamic>? cached) {
    final list = extractMetadataList(cached);
    if (list == null || list.isEmpty) return null;
    return list.first as Map<String, dynamic>;
  }

  static List<dynamic>? extractChapters(Map<String, dynamic>? cached) {
    final metadata = extractFirstMetadata(cached);
    if (metadata == null) return null;
    return metadata['Chapter'] as List?;
  }
}
