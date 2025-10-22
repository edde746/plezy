import 'package:json_annotation/json_annotation.dart';

part 'plex_metadata.g.dart';

@JsonSerializable()
class PlexMetadata {
  final String ratingKey;
  final String key;
  final String? guid;
  final String? studio;
  final String type;
  final String title;
  final String? contentRating;
  final String? summary;
  final int? rating;
  final int? year;
  final String? thumb;
  final String? art;
  final int? duration;
  final int? addedAt;
  final int? updatedAt;
  final String? grandparentTitle; // Show title for episodes
  final String? grandparentThumb; // Show poster for episodes
  final String? grandparentArt; // Show art for episodes
  final String? grandparentRatingKey; // Show rating key for episodes
  final String? parentTitle; // Season title for episodes
  final String? parentRatingKey; // Season rating key for episodes
  final int? parentIndex; // Season number
  final int? index; // Episode number
  final String? grandparentTheme; // Show theme music
  final int? viewOffset; // Resume position in ms
  final int? viewCount;
  final int? leafCount; // Total number of episodes in a series/season
  final int? viewedLeafCount; // Number of watched episodes in a series/season

  // Transient field for clear logo (extracted from Image array)
  String? _clearLogo;
  String? get clearLogo => _clearLogo;

  PlexMetadata({
    required this.ratingKey,
    required this.key,
    this.guid,
    this.studio,
    required this.type,
    required this.title,
    this.contentRating,
    this.summary,
    this.rating,
    this.year,
    this.thumb,
    this.art,
    this.duration,
    this.addedAt,
    this.updatedAt,
    this.grandparentTitle,
    this.grandparentThumb,
    this.grandparentArt,
    this.grandparentRatingKey,
    this.parentTitle,
    this.parentRatingKey,
    this.parentIndex,
    this.index,
    this.grandparentTheme,
    this.viewOffset,
    this.viewCount,
    this.leafCount,
    this.viewedLeafCount,
  });

  // Extract clearLogo from Image array in raw JSON
  void _extractClearLogo(Map<String, dynamic> json) {
    if (!json.containsKey('Image')) return;

    final images = json['Image'] as List?;
    if (images == null) return;

    for (var image in images) {
      if (image is Map && image['type'] == 'clearLogo') {
        _clearLogo = image['url'] as String?;
        return;
      }
    }
  }

  // Custom factory that extracts clearLogo
  factory PlexMetadata.fromJsonWithImages(Map<String, dynamic> json) {
    final metadata = PlexMetadata.fromJson(json);
    metadata._extractClearLogo(json);
    return metadata;
  }

  // Helper to get the display title (show name for episodes/seasons, title otherwise)
  String get displayTitle {
    final itemType = type.toLowerCase();

    // For episodes and seasons, prefer grandparent title (show name)
    if ((itemType == 'episode' || itemType == 'season') &&
        grandparentTitle != null) {
      return grandparentTitle!;
    }
    // For seasons without grandparent, check if this IS the show (parentTitle might have show name)
    if (itemType == 'season' && parentTitle != null) {
      return parentTitle!;
    }
    return title;
  }

  // Helper to get the subtitle (episode/season title)
  String? get displaySubtitle {
    final itemType = type.toLowerCase();

    if (itemType == 'episode' || itemType == 'season') {
      // If we showed grandparent/parent as title, show this item's title as subtitle
      if (grandparentTitle != null ||
          (itemType == 'season' && parentTitle != null)) {
        return title;
      }
    }
    return null;
  }

  // Helper to get the poster (show poster for episodes/seasons, thumb otherwise)
  String? get posterThumb {
    final itemType = type.toLowerCase();

    // For episodes and seasons, prefer grandparent thumb (show poster)
    if ((itemType == 'episode' || itemType == 'season') &&
        grandparentThumb != null) {
      return grandparentThumb!;
    }
    return thumb;
  }

  // Helper to determine if content is watched
  bool get isWatched {
    // For series/seasons, check if all episodes are watched
    if (leafCount != null && viewedLeafCount != null) {
      return viewedLeafCount! >= leafCount!;
    }

    // For individual items (movies, episodes), check viewCount
    return viewCount != null && viewCount! > 0;
  }

  factory PlexMetadata.fromJson(Map<String, dynamic> json) =>
      _$PlexMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PlexMetadataToJson(this);
}
