import 'package:json_annotation/json_annotation.dart';

import '../services/settings_service.dart' show EpisodePosterMode;
import '../widgets/plex_optimized_image.dart' show kBlurArtwork, obfuscateText;
import 'mixins/multi_server_fields.dart';
import 'plex_role.dart';
import '../utils/global_key_utils.dart';

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

  /// Plex API type number for metadata editing endpoints
  int get typeNumber => switch (this) {
    PlexMediaType.movie => 1,
    PlexMediaType.show => 2,
    PlexMediaType.season => 3,
    PlexMediaType.episode => 4,
    PlexMediaType.artist => 8,
    PlexMediaType.album => 9,
    PlexMediaType.track => 10,
    _ => 0,
  };
}

@JsonSerializable()
class PlexMetadata with MultiServerFields {
  final String ratingKey;
  final String key;
  final String? guid;
  final String? studio;
  final String type;
  final String title;
  final String? titleSort;
  final String? contentRating;
  final String? summary;
  final double? rating;
  final double? audienceRating;
  final double? userRating;
  final int? year;
  final String? originallyAvailableAt; // Full release date (YYYY-MM-DD)
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
  final String? librarySectionTitle; // Library section title this item belongs to
  final String? ratingImage; // Rating source URI (e.g. rottentomatoes://image.rating.ripe)
  final String? audienceRatingImage; // Audience rating source URI
  final String? tagline;
  final String? originalTitle;
  final String? subtype; // Clip subtype: "trailer", "behindTheScenes", "deleted", etc.
  final int? extraType; // Numeric extra type identifier
  final String? primaryExtraKey; // Points to main trailer (e.g., "/library/metadata/52601")

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
  String get globalKey => serverId != null ? buildGlobalKey(serverId!, ratingKey) : ratingKey;

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
    this.titleSort,
    this.contentRating,
    this.summary,
    this.rating,
    this.audienceRating,
    this.userRating,
    this.year,
    this.originallyAvailableAt,
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
    this.librarySectionTitle,
    this.ratingImage,
    this.audienceRatingImage,
    this.tagline,
    this.originalTitle,
    this.subtype,
    this.extraType,
    this.primaryExtraKey,
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
    String? titleSort,
    String? contentRating,
    String? summary,
    double? rating,
    double? audienceRating,
    double? userRating,
    int? year,
    String? originallyAvailableAt,
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
    String? librarySectionTitle,
    String? ratingImage,
    String? audienceRatingImage,
    String? tagline,
    String? originalTitle,
    String? subtype,
    int? extraType,
    String? primaryExtraKey,
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
      titleSort: titleSort ?? this.titleSort,
      contentRating: contentRating ?? this.contentRating,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      audienceRating: audienceRating ?? this.audienceRating,
      userRating: userRating ?? this.userRating,
      year: year ?? this.year,
      originallyAvailableAt: originallyAvailableAt ?? this.originallyAvailableAt,
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
      librarySectionTitle: librarySectionTitle ?? this.librarySectionTitle,
      ratingImage: ratingImage ?? this.ratingImage,
      audienceRatingImage: audienceRatingImage ?? this.audienceRatingImage,
      tagline: tagline ?? this.tagline,
      originalTitle: originalTitle ?? this.originalTitle,
      subtype: subtype ?? this.subtype,
      extraType: extraType ?? this.extraType,
      primaryExtraKey: primaryExtraKey ?? this.primaryExtraKey,
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
    if ((itemType == 'episode' || itemType == 'season') && grandparentTitle != null) {
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
      if (grandparentTitle != null || (itemType == 'season' && parentTitle != null)) {
        return title;
      }
    }
    return null;
  }

  /// Returns the appropriate image path based on episode poster mode.
  /// For episodes:
  ///   - seriesPoster: grandparentThumb (series poster)
  ///   - seasonPoster: parentThumb (season poster)
  ///   - episodeThumbnail: thumb (16:9 episode still)
  /// For seasons: returns grandparentThumb (series poster), or art/thumb in mixed hub context
  /// For movies/shows/seasons in mixed hub context: returns art (16:9 background)
  /// For other types: returns thumb
  String? posterThumb({EpisodePosterMode mode = EpisodePosterMode.seriesPoster, bool mixedHubContext = false}) {
    final itemType = type.toLowerCase();

    if (itemType == 'episode') {
      switch (mode) {
        case EpisodePosterMode.episodeThumbnail:
          return thumb; // 16:9 episode thumbnail
        case EpisodePosterMode.seasonPoster:
          return parentThumb ?? grandparentThumb ?? thumb;
        case EpisodePosterMode.seriesPoster:
          return grandparentThumb ?? thumb;
      }
    } else if (itemType == 'season') {
      // In mixed hub with episode thumbnail mode, use art/thumb (16:9)
      if (mixedHubContext && mode == EpisodePosterMode.episodeThumbnail) {
        return art ?? thumb;
      }
      // Otherwise use series poster (2:3)
      if (grandparentThumb != null) {
        return grandparentThumb!;
      }
    }

    // For movies/shows in mixed hub context with episode thumbnail mode, use art (16:9)
    if (mixedHubContext && mode == EpisodePosterMode.episodeThumbnail && (itemType == 'movie' || itemType == 'show')) {
      return art ?? thumb;
    }

    return thumb;
  }

  /// Returns true if this item should use 16:9 aspect ratio.
  /// Episodes use 16:9 when in episodeThumbnail mode.
  /// Clips (trailers, extras) always use 16:9.
  /// Movies, shows, and seasons use 16:9 in mixed hub context with episodeThumbnail mode.
  bool usesWideAspectRatio(EpisodePosterMode mode, {bool mixedHubContext = false}) {
    final itemType = type.toLowerCase();
    // Clips (trailers, extras) are always 16:9
    if (itemType == 'clip') return true;
    if (itemType == 'episode' && mode == EpisodePosterMode.episodeThumbnail) {
      return true;
    }
    // Movies, shows, and seasons use 16:9 in mixed hubs with episode thumbnail mode
    if (mixedHubContext &&
        mode == EpisodePosterMode.episodeThumbnail &&
        (itemType == 'movie' || itemType == 'show' || itemType == 'season')) {
      return true;
    }
    return false;
  }

  /// Returns true if this item has started but not finished playback
  /// Only applicable for individual items (movies, episodes)
  bool get hasActiveProgress {
    if (duration == null || viewOffset == null) return false;
    return viewOffset! > 0 && viewOffset! < duration!;
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
      _$PlexMetadataFromJson(kBlurArtwork ? _obfuscateJson(json) : json);

  static Map<String, dynamic> _obfuscateJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    for (final key in const ['title', 'summary', 'tagline', 'grandparentTitle', 'parentTitle', 'studio']) {
      if (copy[key] is String) copy[key] = obfuscateText(copy[key] as String);
    }
    return copy;
  }

  Map<String, dynamic> toJson() => _$PlexMetadataToJson(this);
}
