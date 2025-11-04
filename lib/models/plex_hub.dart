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

  PlexHub({
    required this.hubKey,
    required this.title,
    required this.type,
    this.hubIdentifier,
    required this.size,
    required this.more,
    required this.items,
  });

  factory PlexHub.fromJson(Map<String, dynamic> json) {
    final metadataList = <PlexMetadata>[];

    // Hubs can contain either Metadata or Directory entries
    if (json['Metadata'] != null) {
      for (final item in json['Metadata'] as List) {
        try {
          metadataList.add(PlexMetadata.fromJson(item));
        } catch (e) {
          // Skip items that fail to parse
        }
      }
    }

    if (json['Directory'] != null) {
      for (final item in json['Directory'] as List) {
        try {
          metadataList.add(PlexMetadata.fromJson(item));
        } catch (e) {
          // Skip items that fail to parse
        }
      }
    }

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
