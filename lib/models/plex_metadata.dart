import 'package:json_annotation/json_annotation.dart';

import 'mixins/multi_server_fields.dart';
import 'plex_role.dart';

part 'plex_metadata.g.dart';

/// Media type enum for type-safe media type handling
enum PlexMediaType {
  movie,
  show,
  season,
  episode,
  artist,
  album,
  track,
  collection,
  playlist,
  clip,
  photo,
  unknown;

  /// Whether this type represents video content
  bool get isVideo => this == movie || this == episode || this == clip;

  /// Whether this type is part of a show hierarchy
  bool get isShowRelated => this == show || this == season || this == episode;

  /// Whether this type represents music content
  bool get isMusic => this == artist || this == album || this == track;

  /// Whether this type can be played directly
  bool get isPlayable => isVideo || this == track;
}

@JsonSerializable()
class PlexMetadata with MultiServerFields {
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
  final int? lastViewedAt; // Timestamp when item was last viewed
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
  final int? childCount; // Number of items in a collection or playlist
  @JsonKey(name: 'Role')
  final List<PlexRole>? role; // Cast members
  final String? audioLanguage; // Per-media preferred audio language
  final String? subtitleLanguage; // Per-media preferred subtitle language
  final int? playlistItemID; // Playlist item ID (for dumb playlists only)
  final int? playQueueItemID; // Play queue item ID (unique even for duplicates)
  final int? librarySectionID; // Library section ID this item belongs to

  // Multi-server support fields (from MultiServerFields mixin)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;

  // Clear logo URL (extracted from Image array, but serialized for offline storage)
  final String? clearLogo;

  /// Global unique identifier across all servers (serverId:ratingKey)
  String get globalKey => serverId != null ? '$serverId:$ratingKey' : ratingKey;

  /// Parsed media type enum for type-safe comparisons
  PlexMediaType get mediaType {
    return switch (type.toLowerCase()) {
      'movie' => PlexMediaType.movie,
      'show' => PlexMediaType.show,
      'season' => PlexMediaType.season,
      'episode' => PlexMediaType.episode,
      'artist' => PlexMediaType.artist,
      'album' => PlexMediaType.album,
      'track' => PlexMediaType.track,
      'collection' => PlexMediaType.collection,
      'playlist' => PlexMediaType.playlist,
      'clip' => PlexMediaType.clip,
      'photo' => PlexMediaType.photo,
      _ => PlexMediaType.unknown,
    };
  }

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
    this.lastViewedAt,
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
    this.childCount,
    this.role,
    this.audioLanguage,
    this.subtitleLanguage,
    this.playlistItemID,
    this.playQueueItemID,
    this.librarySectionID,
    this.serverId,
    this.serverName,
    this.clearLogo,
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
    int? lastViewedAt,
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
    int? childCount,
    List<PlexRole>? role,
    String? audioLanguage,
    String? subtitleLanguage,
    int? playlistItemID,
    int? playQueueItemID,
    int? librarySectionID,
    String? serverId,
    String? serverName,
    String? clearLogo,
  }) {
    return PlexMetadata(
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
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
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
      childCount: childCount ?? this.childCount,
      role: role ?? this.role,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      playlistItemID: playlistItemID ?? this.playlistItemID,
      playQueueItemID: playQueueItemID ?? this.playQueueItemID,
      librarySectionID: librarySectionID ?? this.librarySectionID,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      clearLogo: clearLogo ?? this.clearLogo,
    );
  }

  /// Extract clearLogo from Image array in raw JSON
  static String? _extractClearLogoFromJson(Map<String, dynamic> json) {
    if (!json.containsKey('Image')) return null;

    final images = json['Image'] as List?;
    if (images == null) return null;

    for (var image in images) {
      if (image is Map && image['type'] == 'clearLogo') {
        return image['url'] as String?;
      }
    }
    return null;
  }

  /// Create from JSON with clearLogo extracted from Image array
  factory PlexMetadata.fromJsonWithImages(Map<String, dynamic> json) {
    // Extract clearLogo before parsing
    final clearLogoUrl = _extractClearLogoFromJson(json);
    // Add it to the json so it gets parsed
    if (clearLogoUrl != null) {
      json['clearLogo'] = clearLogoUrl;
    }
    return PlexMetadata.fromJson(json);
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
