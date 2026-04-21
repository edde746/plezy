import '../utils/json_utils.dart';
import '../widgets/plex_optimized_image.dart' show kBlurArtwork, obfuscateText;
import 'mixins/multi_server_fields.dart';
import 'plex_metadata.dart';

/// Represents a Plex hub/recommendation section (e.g., Trending Movies, Top Thrillers)
class PlexHub with MultiServerFields {
  final String hubKey;
  final String title;
  final String type;
  final String? hubIdentifier;
  final int size;
  final bool more;
  final List<PlexMetadata> items;

  @override
  final String? serverId;
  @override
  final String? serverName;

  /// When set, this hub was split from a multi-library hub and should only
  /// show items belonging to this library section.
  final int? librarySectionID;

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
    this.librarySectionID,
  });

  factory PlexHub.fromJson(Map<String, dynamic> json, {String? serverId, String? serverName}) {
    final metadataList = <PlexMetadata>[];

    // Helper function to parse entries from a JSON list
    void parseEntries(List? entries, {bool isDirectory = false}) {
      if (entries == null) return;
      for (final item in entries) {
        try {
          Map<String, dynamic> entry = item as Map<String, dynamic>;
          if (isDirectory && !entry.containsKey('type')) {
            // Directory items often represent shows but might miss the type field.
            // Default to 'show' if it looks like a show, else 'folder'.
            entry = Map<String, dynamic>.from(entry);
            entry['type'] = (entry.containsKey('leafCount') || entry.containsKey('childCount')) ? 'show' : 'folder';
          }
          var parsed = PlexMetadata.fromJsonWithImages(entry);
          if (serverId != null || serverName != null) {
            parsed = parsed.copyWith(serverId: serverId, serverName: serverName);
          }
          metadataList.add(parsed);
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
      title: kBlurArtwork
          ? obfuscateText(json['title'] as String? ?? 'Unknown')
          : json['title'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'hub',
      hubIdentifier: json['hubIdentifier'] as String?,
      size: (json['size'] as num?)?.toInt() ?? metadataList.length,
      more: flexibleBool(json['more']),
      items: metadataList,
      serverId: serverId,
      serverName: serverName,
    );
  }
}
