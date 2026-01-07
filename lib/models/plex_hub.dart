import 'plex_metadata.dart';

/// Represents a Plex hub/recommendation section (e.g., Trending Movies, Top Thrillers)
class PlexHub {
  final String hubKey;
  final String title;
  final String type;
  final String? hubIdentifier;
  final int size;
  final bool more;
  final List<PlexMetadata> items;

  // Multi-server support fields
  final String? serverId; // Server machine identifier
  final String? serverName; // Server display name

  PlexHub({
    required this.hubKey,
    required this.title,
    required this.type,
    this.hubIdentifier,
    required this.size,
    required this.more,
    required this.items,
    this.serverId,
    this.serverName,
  });

  factory PlexHub.fromJson(Map<String, dynamic> json) {
    final metadataList = <PlexMetadata>[];

    // Helper function to parse entries from a JSON list
    void parseEntries(List? entries, {bool isDirectory = false}) {
      if (entries == null) return;
      for (final item in entries) {
        try {
          if (isDirectory && item is Map && !item.containsKey('type')) {
            // Directory items often represent shows but might miss the type field
            // Default to 'show' if it looks like a show (has leafCount or childCount)
            // or 'folder' as a safe default
            final String type = (item.containsKey('leafCount') || item.containsKey('childCount')) ? 'show' : 'folder';
            item['type'] = type;
          }
          metadataList.add(PlexMetadata.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          // Skip items that fail to parse
        }
      }
    }

    // Hubs can contain either Metadata or Directory entries
    parseEntries(json['Metadata'] as List?);
    parseEntries(json['Directory'] as List?, isDirectory: true);

    return PlexHub(
      hubKey: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'hub',
      hubIdentifier: json['hubIdentifier'] as String?,
      size: (json['size'] as num?)?.toInt() ?? metadataList.length,
      more: json['more'] == true || json['more'] == 1,
      items: metadataList,
    );
  }
}
