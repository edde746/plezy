import 'package:json_annotation/json_annotation.dart';

import 'plex_role.dart';

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
  final double? rating;
  final double? audienceRating;
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
  final String? parentThumb; // Season poster for episodes
  final String? parentRatingKey; // Season rating key for episodes
  final int? parentIndex; // Season number
  final int? index; // Episode number
  final String? grandparentTheme; // Show theme music
  final int? viewOffset; // Resume position in ms
  final int? viewCount;
  final int? leafCount; // Total number of episodes in a series/season
  final int? viewedLeafCount; // Number of watched episodes in a series/season
  @JsonKey(name: 'Role')
  final List<PlexRole>? role; // Cast members
  final String? audioLanguage; // Per-media preferred audio language
  final String? subtitleLanguage; // Per-media preferred subtitle language
  final int? playlistItemID; // Playlist item ID (for dumb playlists only)

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
    this.audienceRating,
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
    this.parentThumb,
    this.parentRatingKey,
    this.parentIndex,
    this.index,
    this.grandparentTheme,
    this.viewOffset,
    this.viewCount,
    this.leafCount,
    this.viewedLeafCount,
    this.role,
    this.audioLanguage,
    this.subtitleLanguage,
    this.playlistItemID,
  });

  /// Create a copy of this metadata with optional field overrides
  PlexMetadata copyWith({
    String? ratingKey,
    String? key,
    String? guid,
    String? studio,
    String? type,
    String? title,
    String? contentRating,
    String? summary,
    double? rating,
    double? audienceRating,
    int? year,
    String? thumb,
    String? art,
    int? duration,
    int? addedAt,
    int? updatedAt,
    String? grandparentTitle,
    String? grandparentThumb,
    String? grandparentArt,
    String? grandparentRatingKey,
    String? parentTitle,
    String? parentThumb,
    String? parentRatingKey,
    int? parentIndex,
    int? index,
    String? grandparentTheme,
    int? viewOffset,
    int? viewCount,
    int? leafCount,
    int? viewedLeafCount,
    List<PlexRole>? role,
    String? audioLanguage,
    String? subtitleLanguage,
    int? playlistItemID,
  }) {
    final copy = PlexMetadata(
      ratingKey: ratingKey ?? this.ratingKey,
      key: key ?? this.key,
      guid: guid ?? this.guid,
      studio: studio ?? this.studio,
      type: type ?? this.type,
      title: title ?? this.title,
      contentRating: contentRating ?? this.contentRating,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      audienceRating: audienceRating ?? this.audienceRating,
      year: year ?? this.year,
      thumb: thumb ?? this.thumb,
      art: art ?? this.art,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      grandparentTitle: grandparentTitle ?? this.grandparentTitle,
      grandparentThumb: grandparentThumb ?? this.grandparentThumb,
      grandparentArt: grandparentArt ?? this.grandparentArt,
      grandparentRatingKey: grandparentRatingKey ?? this.grandparentRatingKey,
      parentTitle: parentTitle ?? this.parentTitle,
      parentThumb: parentThumb ?? this.parentThumb,
      parentRatingKey: parentRatingKey ?? this.parentRatingKey,
      parentIndex: parentIndex ?? this.parentIndex,
      index: index ?? this.index,
      grandparentTheme: grandparentTheme ?? this.grandparentTheme,
      viewOffset: viewOffset ?? this.viewOffset,
      viewCount: viewCount ?? this.viewCount,
      leafCount: leafCount ?? this.leafCount,
      viewedLeafCount: viewedLeafCount ?? this.viewedLeafCount,
      role: role ?? this.role,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      playlistItemID: playlistItemID ?? this.playlistItemID,
    );
    // Preserve clearLogo
    copy._clearLogo = _clearLogo;
    return copy;
  }

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
  // If useSeasonPoster is true, episodes will use season poster instead of series poster
  String? posterThumb({bool useSeasonPoster = false}) {
    final itemType = type.toLowerCase();

    if (itemType == 'episode') {
      // If season poster is enabled and available, use it
      if (useSeasonPoster && parentThumb != null) {
        return parentThumb!;
      }
      // Otherwise fall back to series poster, then item thumb
      if (grandparentThumb != null) {
        return grandparentThumb!;
      }
    } else if (itemType == 'season' && grandparentThumb != null) {
      // For seasons, always use series poster
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
