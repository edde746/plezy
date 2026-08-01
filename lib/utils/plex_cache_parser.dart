/// Utility class for parsing Plex API cache responses
///
/// Provides consistent extraction of MediaContainer data across the codebase.
class PlexCacheParser {
  PlexCacheParser._();

  static Map<String, dynamic>? extractMediaContainer(Map<String, dynamic>? cached) {
    final container = cached?['MediaContainer'];
    return container is Map<String, dynamic> ? container : null;
  }

  static List<dynamic>? extractMetadataList(Map<String, dynamic>? cached) {
    return extractMediaContainer(cached)?['Metadata'] as List?;
  }

  static Map<String, dynamic>? extractFirstMetadata(Map<String, dynamic>? cached) {
    final list = extractMetadataList(cached);
    if (list == null || list.isEmpty) return null;
    return list.first as Map<String, dynamic>;
  }
}
