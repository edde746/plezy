import '../services/settings_service.dart' show EpisodePosterMode;
import '../utils/global_key_utils.dart';
import '../utils/json_utils.dart';
import 'media_backend.dart';
import 'media_kind.dart';
import 'media_part.dart';
import 'media_role.dart';
import 'media_version.dart';

/// Backend-neutral media item — the central domain type the app's UI,
/// providers, and persistence layer operate on. Each backend's adapter is
/// responsible for mapping its native representation (Plex `Metadata`,
/// Jellyfin `BaseItemDto`) into this shape.
///
/// Sealed root with two concrete subclasses: [PlexMediaItem] (carries
/// Plex-only fields like `trailerKey`, `playQueueItemId`, `audienceRating`)
/// and [JellyfinMediaItem] (only the backend-neutral fields). Read sites
/// that need a Plex-only field type-narrow with
/// `case PlexMediaItem(:final trailerKey?)` or
/// `if (item is PlexMediaItem) item.trailerKey`.
sealed class MediaItem {
  /// Backend-opaque identifier (Plex `ratingKey`, Jellyfin `Id`).
  final String id;
  final MediaBackend backend;
  final MediaKind kind;

  /// Stable cross-backend identifier (Plex `guid`, Jellyfin `Id` URI). Used
  /// for matching across servers and for Trakt-style external lookups.
  final String? guid;

  final String? title;
  final String? titleSort;
  final String? summary;
  final String? tagline;
  final String? originalTitle;
  final String? studio;
  final int? year;

  /// Original release date (`YYYY-MM-DD`).
  final String? originallyAvailableAt;
  final String? contentRating;

  final String? parentId;
  final String? parentTitle;
  final String? parentThumbPath;
  final int? parentIndex;
  final int? index;
  final String? grandparentId;
  final String? grandparentTitle;
  final String? grandparentThumbPath;
  final String? grandparentArtPath;

  final String? thumbPath;
  final String? artPath;
  final String? clearLogoPath;
  final String? backgroundSquarePath;

  final int? durationMs;

  /// Resume position in ms.
  final int? viewOffsetMs;
  final int? viewCount;
  final int? lastViewedAt;

  /// Total leaf items (episodes in a show/season, items in a collection).
  final int? leafCount;

  /// Watched leaf items.
  final int? viewedLeafCount;

  /// Direct children count (e.g. seasons in a show).
  final int? childCount;

  final int? addedAt;
  final int? updatedAt;

  final double? rating;
  final double? userRating;

  final List<String>? genres;
  final List<String>? directors;
  final List<String>? writers;
  final List<String>? producers;
  final List<String>? countries;
  final List<String>? collections;
  final List<String>? labels;
  final List<String>? styles;
  final List<String>? moods;
  final List<MediaRole>? roles;

  final List<MediaVersion>? mediaVersions;

  /// Backend-opaque library/section id this item belongs to.
  final String? libraryId;
  final String? libraryTitle;

  /// Preferred audio language for this item — used by track-selection
  /// fallback (Priority 3) on both backends. Plex persists changes via
  /// [PlexClient.setMetadataPreferences]; Jellyfin populates it from the
  /// per-user `PreferredMetadataLanguage` field but has no per-item write
  /// endpoint, so the value is read-only there.
  final String? audioLanguage;

  final String? serverId;
  final String? serverName;

  /// Untyped fall-through for backend-specific fields not yet mapped onto a
  /// typed accessor. Use sparingly; promote to typed fields when stable.
  final Map<String, Object?>? raw;

  const MediaItem._({
    required this.id,
    required this.backend,
    required this.kind,
    this.guid,
    this.title,
    this.titleSort,
    this.summary,
    this.tagline,
    this.originalTitle,
    this.studio,
    this.year,
    this.originallyAvailableAt,
    this.contentRating,
    this.parentId,
    this.parentTitle,
    this.parentThumbPath,
    this.parentIndex,
    this.index,
    this.grandparentId,
    this.grandparentTitle,
    this.grandparentThumbPath,
    this.grandparentArtPath,
    this.thumbPath,
    this.artPath,
    this.clearLogoPath,
    this.backgroundSquarePath,
    this.durationMs,
    this.viewOffsetMs,
    this.viewCount,
    this.lastViewedAt,
    this.leafCount,
    this.viewedLeafCount,
    this.childCount,
    this.addedAt,
    this.updatedAt,
    this.rating,
    this.userRating,
    this.genres,
    this.directors,
    this.writers,
    this.producers,
    this.countries,
    this.collections,
    this.labels,
    this.styles,
    this.moods,
    this.roles,
    this.mediaVersions,
    this.libraryId,
    this.libraryTitle,
    this.audioLanguage,
    this.serverId,
    this.serverName,
    this.raw,
  });

  /// Backend-dispatching factory: constructs the right concrete subclass
  /// for the given [backend]. Non-const because the dispatch happens at
  /// runtime; the (rare) const construct sites have been adjusted.
  factory MediaItem({
    required String id,
    required MediaBackend backend,
    required MediaKind kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,
    String? studio,
    int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    int? parentIndex,
    int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    int? durationMs,
    int? viewOffsetMs,
    int? viewCount,
    int? lastViewedAt,
    int? leafCount,
    int? viewedLeafCount,
    int? childCount,
    int? addedAt,
    int? updatedAt,
    double? rating,
    double? userRating,
    List<String>? genres,
    List<String>? directors,
    List<String>? writers,
    List<String>? producers,
    List<String>? countries,
    List<String>? collections,
    List<String>? labels,
    List<String>? styles,
    List<String>? moods,
    List<MediaRole>? roles,
    List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,

    /// Plex-only — silently ignored when [backend] is Jellyfin (Jellyfin has
    /// no per-item subtitle preference write endpoint). Forwarded to
    /// [PlexMediaItem] only.
    String? subtitleLanguage,
    int? subtitleMode,
    String? serverId,
    String? serverName,
    Map<String, Object?>? raw,
  }) {
    return switch (backend) {
      MediaBackend.plex => PlexMediaItem(
        id: id,
        kind: kind,
        guid: guid,
        title: title,
        titleSort: titleSort,
        summary: summary,
        tagline: tagline,
        originalTitle: originalTitle,
        studio: studio,
        year: year,
        originallyAvailableAt: originallyAvailableAt,
        contentRating: contentRating,
        parentId: parentId,
        parentTitle: parentTitle,
        parentThumbPath: parentThumbPath,
        parentIndex: parentIndex,
        index: index,
        grandparentId: grandparentId,
        grandparentTitle: grandparentTitle,
        grandparentThumbPath: grandparentThumbPath,
        grandparentArtPath: grandparentArtPath,
        thumbPath: thumbPath,
        artPath: artPath,
        clearLogoPath: clearLogoPath,
        backgroundSquarePath: backgroundSquarePath,
        durationMs: durationMs,
        viewOffsetMs: viewOffsetMs,
        viewCount: viewCount,
        lastViewedAt: lastViewedAt,
        leafCount: leafCount,
        viewedLeafCount: viewedLeafCount,
        childCount: childCount,
        addedAt: addedAt,
        updatedAt: updatedAt,
        rating: rating,
        userRating: userRating,
        genres: genres,
        directors: directors,
        writers: writers,
        producers: producers,
        countries: countries,
        collections: collections,
        labels: labels,
        styles: styles,
        moods: moods,
        roles: roles,
        mediaVersions: mediaVersions,
        libraryId: libraryId,
        libraryTitle: libraryTitle,
        audioLanguage: audioLanguage,
        subtitleLanguage: subtitleLanguage,
        subtitleMode: subtitleMode,
        serverId: serverId,
        serverName: serverName,
        raw: raw,
      ),
      MediaBackend.jellyfin => JellyfinMediaItem(
        id: id,
        kind: kind,
        guid: guid,
        title: title,
        titleSort: titleSort,
        summary: summary,
        tagline: tagline,
        originalTitle: originalTitle,
        studio: studio,
        year: year,
        originallyAvailableAt: originallyAvailableAt,
        contentRating: contentRating,
        parentId: parentId,
        parentTitle: parentTitle,
        parentThumbPath: parentThumbPath,
        parentIndex: parentIndex,
        index: index,
        grandparentId: grandparentId,
        grandparentTitle: grandparentTitle,
        grandparentThumbPath: grandparentThumbPath,
        grandparentArtPath: grandparentArtPath,
        thumbPath: thumbPath,
        artPath: artPath,
        clearLogoPath: clearLogoPath,
        backgroundSquarePath: backgroundSquarePath,
        durationMs: durationMs,
        viewOffsetMs: viewOffsetMs,
        viewCount: viewCount,
        lastViewedAt: lastViewedAt,
        leafCount: leafCount,
        viewedLeafCount: viewedLeafCount,
        childCount: childCount,
        addedAt: addedAt,
        updatedAt: updatedAt,
        rating: rating,
        userRating: userRating,
        genres: genres,
        directors: directors,
        writers: writers,
        producers: producers,
        countries: countries,
        collections: collections,
        labels: labels,
        styles: styles,
        moods: moods,
        roles: roles,
        mediaVersions: mediaVersions,
        libraryId: libraryId,
        libraryTitle: libraryTitle,
        audioLanguage: audioLanguage,
        serverId: serverId,
        serverName: serverName,
        raw: raw,
      ),
    };
  }

  /// Global unique identifier across all servers (`serverId:id`). Falls back
  /// to bare [id] if [serverId] is missing.
  String get globalKey => serverId != null ? buildGlobalKey(serverId!, id) : id;

  /// Global unique identifier of this item's library section.
  String? get libraryGlobalKey => serverId != null && libraryId != null ? buildGlobalKey(serverId!, libraryId!) : null;

  /// Parent rating keys for hierarchical invalidation. For an episode:
  /// `[seasonId, showId]`. For a season: `[showId]`. For a movie: `[]`.
  List<String> get parentChain => [?parentId, ?grandparentId];

  /// Whether this item has started but not finished playback.
  bool get hasActiveProgress {
    if (durationMs == null || viewOffsetMs == null) return false;
    return viewOffsetMs! > 0 && viewOffsetMs! < durationMs!;
  }

  /// Whether this container (show/season) has some but not all leaves watched.
  bool get isPartiallyWatched =>
      viewedLeafCount != null && leafCount != null && viewedLeafCount! > 0 && viewedLeafCount! < leafCount!;

  /// Whether the item is fully watched. Series/seasons consult leaf counts;
  /// individual movies/episodes use [viewCount].
  bool get isWatched {
    if (leafCount != null && viewedLeafCount != null) {
      return viewedLeafCount! >= leafCount!;
    }
    return viewCount != null && viewCount! > 0;
  }

  /// Display-friendly title that prefers the show name for episodes/seasons.
  String get displayTitle {
    if ((kind == MediaKind.episode || kind == MediaKind.season) && grandparentTitle != null) {
      return grandparentTitle!;
    }
    if (kind == MediaKind.season && parentTitle != null) {
      return parentTitle!;
    }
    return title ?? '';
  }

  /// Subtitle line shown below [displayTitle] for episodes/seasons.
  String? get displaySubtitle {
    if (kind == MediaKind.episode || kind == MediaKind.season) {
      if (grandparentTitle != null || (kind == MediaKind.season && parentTitle != null)) {
        return title;
      }
    }
    return null;
  }

  /// Plex-only edition label (e.g. "Director's Cut"). Returns null on
  /// backends that don't model editions; lets callers avoid type-narrowing
  /// to [PlexMediaItem] just to read this field.
  String? get editionTitle => null;

  /// Returns the appropriate poster path based on episode poster mode.
  ///
  /// For episodes:
  /// - `seriesPoster`: grandparentThumb (series poster)
  /// - `seasonPoster`: parentThumb (season poster)
  /// - `episodeThumbnail`: thumb (16:9 episode still)
  ///
  /// For seasons: returns grandparentThumb (series poster), or art/thumb in
  /// mixed hub context.
  /// For movies/shows in mixed hub context with episode-thumbnail mode:
  /// returns art (16:9 background).
  /// For other types: returns thumb.
  String? posterThumb({EpisodePosterMode mode = EpisodePosterMode.seriesPoster, bool mixedHubContext = false}) {
    if (kind == MediaKind.episode) {
      switch (mode) {
        case EpisodePosterMode.episodeThumbnail:
          return thumbPath;
        case EpisodePosterMode.seasonPoster:
          return parentThumbPath ?? grandparentThumbPath ?? thumbPath;
        case EpisodePosterMode.seriesPoster:
          return grandparentThumbPath ?? thumbPath;
      }
    } else if (kind == MediaKind.season) {
      if (mixedHubContext && mode == EpisodePosterMode.episodeThumbnail) {
        return artPath ?? thumbPath;
      }
      if (grandparentThumbPath != null) {
        return grandparentThumbPath;
      }
    }

    if (mixedHubContext &&
        mode == EpisodePosterMode.episodeThumbnail &&
        (kind == MediaKind.movie || kind == MediaKind.show)) {
      return artPath ?? thumbPath;
    }

    return thumbPath;
  }

  /// True when the item should render in 16:9.
  /// - Clips are always 16:9.
  /// - Episodes are 16:9 in `episodeThumbnail` mode.
  /// - Movies/shows/seasons are 16:9 in mixed-hub `episodeThumbnail` context.
  bool usesWideAspectRatio(EpisodePosterMode mode, {bool mixedHubContext = false}) {
    if (kind == MediaKind.clip) return true;
    if (kind == MediaKind.episode && mode == EpisodePosterMode.episodeThumbnail) {
      return true;
    }
    if (mixedHubContext &&
        mode == EpisodePosterMode.episodeThumbnail &&
        (kind == MediaKind.movie || kind == MediaKind.show || kind == MediaKind.season)) {
      return true;
    }
    return false;
  }

  /// Returns the best hero art path based on the container's aspect ratio.
  /// Uses backgroundSquare when the container is closer to 1:1 than 16:9.
  String? heroArt({required double containerAspectRatio}) {
    final candidates = heroArtCandidates(containerAspectRatio: containerAspectRatio);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  /// Returns hero art candidates in display-preference order.
  /// Near-square containers prefer square art, then fall back to wide cover art.
  List<String> heroArtCandidates({required double containerAspectRatio}) {
    // Threshold = midpoint of 1:1 (1.0) and 16:9 (~1.78) ≈ 1.39
    final preferred = containerAspectRatio < 1.39 ? [backgroundSquarePath, artPath] : [artPath, backgroundSquarePath];

    final candidates = <String>[];
    for (final path in preferred) {
      if (path == null || path.isEmpty || candidates.contains(path)) continue;
      candidates.add(path);
    }
    return candidates;
  }

  MediaItem copyWith({
    String? id,
    MediaBackend? backend,
    MediaKind? kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,
    String? studio,
    int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    int? parentIndex,
    int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    int? durationMs,
    int? viewOffsetMs,
    int? viewCount,
    int? lastViewedAt,
    int? leafCount,
    int? viewedLeafCount,
    int? childCount,
    int? addedAt,
    int? updatedAt,
    double? rating,
    double? userRating,
    List<String>? genres,
    List<String>? directors,
    List<String>? writers,
    List<String>? producers,
    List<String>? countries,
    List<String>? collections,
    List<String>? labels,
    List<String>? styles,
    List<String>? moods,
    List<MediaRole>? roles,
    List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,

    /// Plex-only — forwarded only when this item is a [PlexMediaItem].
    String? subtitleLanguage,
    int? subtitleMode,
    String? serverId,
    String? serverName,
    Map<String, Object?>? raw,
  }) {
    return MediaItem(
      id: id ?? this.id,
      backend: backend ?? this.backend,
      kind: kind ?? this.kind,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      summary: summary ?? this.summary,
      tagline: tagline ?? this.tagline,
      originalTitle: originalTitle ?? this.originalTitle,
      studio: studio ?? this.studio,
      year: year ?? this.year,
      originallyAvailableAt: originallyAvailableAt ?? this.originallyAvailableAt,
      contentRating: contentRating ?? this.contentRating,
      parentId: parentId ?? this.parentId,
      parentTitle: parentTitle ?? this.parentTitle,
      parentThumbPath: parentThumbPath ?? this.parentThumbPath,
      parentIndex: parentIndex ?? this.parentIndex,
      index: index ?? this.index,
      grandparentId: grandparentId ?? this.grandparentId,
      grandparentTitle: grandparentTitle ?? this.grandparentTitle,
      grandparentThumbPath: grandparentThumbPath ?? this.grandparentThumbPath,
      grandparentArtPath: grandparentArtPath ?? this.grandparentArtPath,
      thumbPath: thumbPath ?? this.thumbPath,
      artPath: artPath ?? this.artPath,
      clearLogoPath: clearLogoPath ?? this.clearLogoPath,
      backgroundSquarePath: backgroundSquarePath ?? this.backgroundSquarePath,
      durationMs: durationMs ?? this.durationMs,
      viewOffsetMs: viewOffsetMs ?? this.viewOffsetMs,
      viewCount: viewCount ?? this.viewCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      leafCount: leafCount ?? this.leafCount,
      viewedLeafCount: viewedLeafCount ?? this.viewedLeafCount,
      childCount: childCount ?? this.childCount,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      userRating: userRating ?? this.userRating,
      genres: genres ?? this.genres,
      directors: directors ?? this.directors,
      writers: writers ?? this.writers,
      producers: producers ?? this.producers,
      countries: countries ?? this.countries,
      collections: collections ?? this.collections,
      labels: labels ?? this.labels,
      styles: styles ?? this.styles,
      moods: moods ?? this.moods,
      roles: roles ?? this.roles,
      mediaVersions: mediaVersions ?? this.mediaVersions,
      libraryId: libraryId ?? this.libraryId,
      libraryTitle: libraryTitle ?? this.libraryTitle,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      // [subtitleLanguage] / [subtitleMode] are Plex-only fields. Base
      // [MediaItem] doesn't carry them; [PlexMediaItem.copyWith] overrides
      // this method and forwards its own copies. For Jellyfin items the
      // params are silently dropped.
      subtitleLanguage: subtitleLanguage,
      subtitleMode: subtitleMode,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      raw: raw ?? this.raw,
    );
  }

  /// Serialize to a backend-neutral JSON map. Used by the offline cache so
  /// downloads retain their metadata without round-tripping through a
  /// backend-specific shape.
  ///
  /// Subclasses extend this with their own backend-specific keys
  /// ([PlexMediaItem.toJson] adds the Plex-only fields).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backend': backend.id,
      'kind': kind.id,
      if (guid != null) 'guid': guid,
      if (title != null) 'title': title,
      if (titleSort != null) 'titleSort': titleSort,
      if (summary != null) 'summary': summary,
      if (tagline != null) 'tagline': tagline,
      if (originalTitle != null) 'originalTitle': originalTitle,
      if (studio != null) 'studio': studio,
      if (year != null) 'year': year,
      if (originallyAvailableAt != null) 'originallyAvailableAt': originallyAvailableAt,
      if (contentRating != null) 'contentRating': contentRating,
      if (parentId != null) 'parentId': parentId,
      if (parentTitle != null) 'parentTitle': parentTitle,
      if (parentThumbPath != null) 'parentThumbPath': parentThumbPath,
      if (parentIndex != null) 'parentIndex': parentIndex,
      if (index != null) 'index': index,
      if (grandparentId != null) 'grandparentId': grandparentId,
      if (grandparentTitle != null) 'grandparentTitle': grandparentTitle,
      if (grandparentThumbPath != null) 'grandparentThumbPath': grandparentThumbPath,
      if (grandparentArtPath != null) 'grandparentArtPath': grandparentArtPath,
      if (thumbPath != null) 'thumbPath': thumbPath,
      if (artPath != null) 'artPath': artPath,
      if (clearLogoPath != null) 'clearLogoPath': clearLogoPath,
      if (backgroundSquarePath != null) 'backgroundSquarePath': backgroundSquarePath,
      if (durationMs != null) 'durationMs': durationMs,
      if (viewOffsetMs != null) 'viewOffsetMs': viewOffsetMs,
      if (viewCount != null) 'viewCount': viewCount,
      if (lastViewedAt != null) 'lastViewedAt': lastViewedAt,
      if (leafCount != null) 'leafCount': leafCount,
      if (viewedLeafCount != null) 'viewedLeafCount': viewedLeafCount,
      if (childCount != null) 'childCount': childCount,
      if (addedAt != null) 'addedAt': addedAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (rating != null) 'rating': rating,
      if (userRating != null) 'userRating': userRating,
      if (genres != null) 'genres': genres,
      if (directors != null) 'directors': directors,
      if (writers != null) 'writers': writers,
      if (producers != null) 'producers': producers,
      if (countries != null) 'countries': countries,
      if (collections != null) 'collections': collections,
      if (labels != null) 'labels': labels,
      if (styles != null) 'styles': styles,
      if (moods != null) 'moods': moods,
      if (roles != null) 'roles': [for (final r in roles!) _roleToJson(r)],
      if (mediaVersions != null) 'mediaVersions': [for (final v in mediaVersions!) _versionToJson(v)],
      if (libraryId != null) 'libraryId': libraryId,
      if (libraryTitle != null) 'libraryTitle': libraryTitle,
      if (audioLanguage != null) 'audioLanguage': audioLanguage,
      if (serverId != null) 'serverId': serverId,
      if (serverName != null) 'serverName': serverName,
      if (raw != null) 'raw': raw,
    };
  }

  /// Restore a [MediaItem] from a [toJson] payload. Dispatches to
  /// [PlexMediaItem.fromJson] when the payload's `backend` tag is Plex so
  /// the Plex-only fields round-trip correctly. Unknown shapes degrade to a
  /// minimal item carrying just `id` so cache misses don't crash.
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final backend = MediaBackend.fromString(json['backend'] as String?);
    if (backend == MediaBackend.plex) return PlexMediaItem.fromJson(json);
    return JellyfinMediaItem.fromJson(json);
  }
}

/// Shared parsing of the backend-neutral fields. Returns a typed record
/// consumed by both [JellyfinMediaItem.fromJson] and
/// [PlexMediaItem.fromJson] (which layers the Plex-only fields on top).
typedef _BaseFields = ({
  String id,
  MediaKind kind,
  String? guid,
  String? title,
  String? titleSort,
  String? summary,
  String? tagline,
  String? originalTitle,
  String? studio,
  int? year,
  String? originallyAvailableAt,
  String? contentRating,
  String? parentId,
  String? parentTitle,
  String? parentThumbPath,
  int? parentIndex,
  int? index,
  String? grandparentId,
  String? grandparentTitle,
  String? grandparentThumbPath,
  String? grandparentArtPath,
  String? thumbPath,
  String? artPath,
  String? clearLogoPath,
  String? backgroundSquarePath,
  int? durationMs,
  int? viewOffsetMs,
  int? viewCount,
  int? lastViewedAt,
  int? leafCount,
  int? viewedLeafCount,
  int? childCount,
  int? addedAt,
  int? updatedAt,
  double? rating,
  double? userRating,
  List<String>? genres,
  List<String>? directors,
  List<String>? writers,
  List<String>? producers,
  List<String>? countries,
  List<String>? collections,
  List<String>? labels,
  List<String>? styles,
  List<String>? moods,
  List<MediaRole>? roles,
  List<MediaVersion>? mediaVersions,
  String? libraryId,
  String? libraryTitle,
  String? audioLanguage,
  String? serverId,
  String? serverName,
  Map<String, Object?>? raw,
});

_BaseFields _parseBaseFields(Map<String, dynamic> json) {
  final rolesRaw = json['roles'];
  final versionsRaw = json['mediaVersions'];
  return (
    id: (json['id'] ?? '').toString(),
    kind: MediaKind.fromString(json['kind'] as String?),
    guid: json['guid'] as String?,
    title: json['title'] as String?,
    titleSort: json['titleSort'] as String?,
    summary: json['summary'] as String?,
    tagline: json['tagline'] as String?,
    originalTitle: json['originalTitle'] as String?,
    studio: json['studio'] as String?,
    year: flexibleInt(json['year']),
    originallyAvailableAt: json['originallyAvailableAt'] as String?,
    contentRating: json['contentRating'] as String?,
    parentId: json['parentId'] as String?,
    parentTitle: json['parentTitle'] as String?,
    parentThumbPath: json['parentThumbPath'] as String?,
    parentIndex: flexibleInt(json['parentIndex']),
    index: flexibleInt(json['index']),
    grandparentId: json['grandparentId'] as String?,
    grandparentTitle: json['grandparentTitle'] as String?,
    grandparentThumbPath: json['grandparentThumbPath'] as String?,
    grandparentArtPath: json['grandparentArtPath'] as String?,
    thumbPath: json['thumbPath'] as String?,
    artPath: json['artPath'] as String?,
    clearLogoPath: json['clearLogoPath'] as String?,
    backgroundSquarePath: json['backgroundSquarePath'] as String?,
    durationMs: flexibleInt(json['durationMs']),
    viewOffsetMs: flexibleInt(json['viewOffsetMs']),
    viewCount: flexibleInt(json['viewCount']),
    lastViewedAt: flexibleInt(json['lastViewedAt']),
    leafCount: flexibleInt(json['leafCount']),
    viewedLeafCount: flexibleInt(json['viewedLeafCount']),
    childCount: flexibleInt(json['childCount']),
    addedAt: flexibleInt(json['addedAt']),
    updatedAt: flexibleInt(json['updatedAt']),
    rating: flexibleDouble(json['rating']),
    userRating: flexibleDouble(json['userRating']),
    genres: _stringList(json['genres']),
    directors: _stringList(json['directors']),
    writers: _stringList(json['writers']),
    producers: _stringList(json['producers']),
    countries: _stringList(json['countries']),
    collections: _stringList(json['collections']),
    labels: _stringList(json['labels']),
    styles: _stringList(json['styles']),
    moods: _stringList(json['moods']),
    roles: rolesRaw is List
        ? [
            for (final r in rolesRaw)
              if (r is Map<String, dynamic>) _roleFromJson(r),
          ]
        : null,
    mediaVersions: versionsRaw is List
        ? [
            for (final v in versionsRaw)
              if (v is Map<String, dynamic>) _versionFromJson(v),
          ]
        : null,
    libraryId: json['libraryId'] as String?,
    libraryTitle: json['libraryTitle'] as String?,
    audioLanguage: json['audioLanguage'] as String?,
    serverId: json['serverId'] as String?,
    serverName: json['serverName'] as String?,
    raw: json['raw'] is Map ? Map<String, Object?>.from(json['raw'] as Map) : null,
  );
}

/// Backend-tagged concrete subclass for items sourced from a Plex server.
/// Carries the Plex-only fields that have no Jellyfin equivalent
/// (trailerKey, playlistItemId, playQueueItemId, subtype, extraType,
/// ratingImage, audienceRating, audienceRatingImage, editionTitle).
/// Read sites that need these fields type-narrow with
/// `case PlexMediaItem(:final trailerKey?)` or
/// `if (item is PlexMediaItem) item.trailerKey`.
final class PlexMediaItem extends MediaItem {
  /// Plex `editionTitle` — secondary title that distinguishes editions of
  /// the same movie ("Director's Cut", "Theatrical"). Jellyfin has no
  /// equivalent metadata field today.
  @override
  final String? editionTitle;

  /// Plex `audienceRating` (e.g. Rotten Tomatoes audience score). Jellyfin's
  /// `CommunityRating` lives on [rating]; there's no separate audience field.
  final double? audienceRating;

  /// Plex `ratingImage` URI ("rottentomatoes://image.rating.ripe"). Used by
  /// the rating chip to pick an icon. Jellyfin doesn't expose
  /// rating-source attribution.
  final String? ratingImage;

  /// Plex `audienceRatingImage` URI — companion to [ratingImage] for the
  /// audience score icon.
  final String? audienceRatingImage;

  /// Plex per-item subtitle language preference — persisted server-side via
  /// [PlexClient.setMetadataPreferences]. Jellyfin has no equivalent
  /// per-item write endpoint, so the field lives here rather than on the
  /// neutral [MediaItem] base.
  final String? subtitleLanguage;

  /// Plex per-item subtitle mode (`0` = manual, `1` = always on, `2` = match
  /// audio). Jellyfin doesn't expose a comparable knob.
  final int? subtitleMode;

  /// Plex `primaryExtraKey` — points at the main trailer extra. Jellyfin
  /// stores trailers separately via `RemoteTrailers`; not yet wired.
  final String? trailerKey;

  /// Plex playlist item id — only set when the item came out of a
  /// server-side playlist. Jellyfin has no per-playlist-item id.
  final int? playlistItemId;

  /// Plex play-queue item id — set when the item is part of a server-side
  /// `PlayQueue`. Jellyfin uses client-side queues; [PlaybackStateProvider]
  /// tracks synthetic IDs in a parallel map for those.
  final int? playQueueItemId;

  /// Plex clip subtype: `trailer`, `behindTheScenes`, `deleted`, etc.
  final String? subtype;

  /// Plex numeric extra type identifier.
  final int? extraType;

  const PlexMediaItem({
    required super.id,
    required super.kind,
    super.guid,
    super.title,
    super.titleSort,
    super.summary,
    super.tagline,
    super.originalTitle,
    this.editionTitle,
    super.studio,
    super.year,
    super.originallyAvailableAt,
    super.contentRating,
    super.parentId,
    super.parentTitle,
    super.parentThumbPath,
    super.parentIndex,
    super.index,
    super.grandparentId,
    super.grandparentTitle,
    super.grandparentThumbPath,
    super.grandparentArtPath,
    super.thumbPath,
    super.artPath,
    super.clearLogoPath,
    super.backgroundSquarePath,
    super.durationMs,
    super.viewOffsetMs,
    super.viewCount,
    super.lastViewedAt,
    super.leafCount,
    super.viewedLeafCount,
    super.childCount,
    super.addedAt,
    super.updatedAt,
    super.rating,
    this.audienceRating,
    super.userRating,
    this.ratingImage,
    this.audienceRatingImage,
    super.genres,
    super.directors,
    super.writers,
    super.producers,
    super.countries,
    super.collections,
    super.labels,
    super.styles,
    super.moods,
    super.roles,
    super.mediaVersions,
    super.libraryId,
    super.libraryTitle,
    super.audioLanguage,
    this.subtitleLanguage,
    this.subtitleMode,
    this.trailerKey,
    this.playlistItemId,
    this.playQueueItemId,
    this.subtype,
    this.extraType,
    super.serverId,
    super.serverName,
    super.raw,
  }) : super._(backend: MediaBackend.plex);

  @override
  PlexMediaItem copyWith({
    String? id,
    MediaBackend? backend,
    MediaKind? kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,
    String? editionTitle,
    String? studio,
    int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    int? parentIndex,
    int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    int? durationMs,
    int? viewOffsetMs,
    int? viewCount,
    int? lastViewedAt,
    int? leafCount,
    int? viewedLeafCount,
    int? childCount,
    int? addedAt,
    int? updatedAt,
    double? rating,
    double? audienceRating,
    double? userRating,
    String? ratingImage,
    String? audienceRatingImage,
    List<String>? genres,
    List<String>? directors,
    List<String>? writers,
    List<String>? producers,
    List<String>? countries,
    List<String>? collections,
    List<String>? labels,
    List<String>? styles,
    List<String>? moods,
    List<MediaRole>? roles,
    List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,
    String? subtitleLanguage,
    int? subtitleMode,
    String? trailerKey,
    int? playlistItemId,
    int? playQueueItemId,
    String? subtype,
    int? extraType,
    String? serverId,
    String? serverName,
    Map<String, Object?>? raw,
  }) {
    return PlexMediaItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      summary: summary ?? this.summary,
      tagline: tagline ?? this.tagline,
      originalTitle: originalTitle ?? this.originalTitle,
      editionTitle: editionTitle ?? this.editionTitle,
      studio: studio ?? this.studio,
      year: year ?? this.year,
      originallyAvailableAt: originallyAvailableAt ?? this.originallyAvailableAt,
      contentRating: contentRating ?? this.contentRating,
      parentId: parentId ?? this.parentId,
      parentTitle: parentTitle ?? this.parentTitle,
      parentThumbPath: parentThumbPath ?? this.parentThumbPath,
      parentIndex: parentIndex ?? this.parentIndex,
      index: index ?? this.index,
      grandparentId: grandparentId ?? this.grandparentId,
      grandparentTitle: grandparentTitle ?? this.grandparentTitle,
      grandparentThumbPath: grandparentThumbPath ?? this.grandparentThumbPath,
      grandparentArtPath: grandparentArtPath ?? this.grandparentArtPath,
      thumbPath: thumbPath ?? this.thumbPath,
      artPath: artPath ?? this.artPath,
      clearLogoPath: clearLogoPath ?? this.clearLogoPath,
      backgroundSquarePath: backgroundSquarePath ?? this.backgroundSquarePath,
      durationMs: durationMs ?? this.durationMs,
      viewOffsetMs: viewOffsetMs ?? this.viewOffsetMs,
      viewCount: viewCount ?? this.viewCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      leafCount: leafCount ?? this.leafCount,
      viewedLeafCount: viewedLeafCount ?? this.viewedLeafCount,
      childCount: childCount ?? this.childCount,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      audienceRating: audienceRating ?? this.audienceRating,
      userRating: userRating ?? this.userRating,
      ratingImage: ratingImage ?? this.ratingImage,
      audienceRatingImage: audienceRatingImage ?? this.audienceRatingImage,
      genres: genres ?? this.genres,
      directors: directors ?? this.directors,
      writers: writers ?? this.writers,
      producers: producers ?? this.producers,
      countries: countries ?? this.countries,
      collections: collections ?? this.collections,
      labels: labels ?? this.labels,
      styles: styles ?? this.styles,
      moods: moods ?? this.moods,
      roles: roles ?? this.roles,
      mediaVersions: mediaVersions ?? this.mediaVersions,
      libraryId: libraryId ?? this.libraryId,
      libraryTitle: libraryTitle ?? this.libraryTitle,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      subtitleMode: subtitleMode ?? this.subtitleMode,
      trailerKey: trailerKey ?? this.trailerKey,
      playlistItemId: playlistItemId ?? this.playlistItemId,
      playQueueItemId: playQueueItemId ?? this.playQueueItemId,
      subtype: subtype ?? this.subtype,
      extraType: extraType ?? this.extraType,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      raw: raw ?? this.raw,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      if (editionTitle != null) 'editionTitle': editionTitle,
      if (audienceRating != null) 'audienceRating': audienceRating,
      if (ratingImage != null) 'ratingImage': ratingImage,
      if (audienceRatingImage != null) 'audienceRatingImage': audienceRatingImage,
      if (subtitleLanguage != null) 'subtitleLanguage': subtitleLanguage,
      if (subtitleMode != null) 'subtitleMode': subtitleMode,
      if (trailerKey != null) 'trailerKey': trailerKey,
      if (playlistItemId != null) 'playlistItemId': playlistItemId,
      if (playQueueItemId != null) 'playQueueItemId': playQueueItemId,
      if (subtype != null) 'subtype': subtype,
      if (extraType != null) 'extraType': extraType,
    };
  }

  /// Restore a [PlexMediaItem] from a [toJson] payload. Reads the Plex-only
  /// keys on top of the backend-neutral fields parsed by [_parseBaseFields].
  factory PlexMediaItem.fromJson(Map<String, dynamic> json) {
    final base = _parseBaseFields(json);
    return PlexMediaItem(
      id: base.id,
      kind: base.kind,
      guid: base.guid,
      title: base.title,
      titleSort: base.titleSort,
      summary: base.summary,
      tagline: base.tagline,
      originalTitle: base.originalTitle,
      editionTitle: json['editionTitle'] as String?,
      studio: base.studio,
      year: base.year,
      originallyAvailableAt: base.originallyAvailableAt,
      contentRating: base.contentRating,
      parentId: base.parentId,
      parentTitle: base.parentTitle,
      parentThumbPath: base.parentThumbPath,
      parentIndex: base.parentIndex,
      index: base.index,
      grandparentId: base.grandparentId,
      grandparentTitle: base.grandparentTitle,
      grandparentThumbPath: base.grandparentThumbPath,
      grandparentArtPath: base.grandparentArtPath,
      thumbPath: base.thumbPath,
      artPath: base.artPath,
      clearLogoPath: base.clearLogoPath,
      backgroundSquarePath: base.backgroundSquarePath,
      durationMs: base.durationMs,
      viewOffsetMs: base.viewOffsetMs,
      viewCount: base.viewCount,
      lastViewedAt: base.lastViewedAt,
      leafCount: base.leafCount,
      viewedLeafCount: base.viewedLeafCount,
      childCount: base.childCount,
      addedAt: base.addedAt,
      updatedAt: base.updatedAt,
      rating: base.rating,
      audienceRating: flexibleDouble(json['audienceRating']),
      userRating: base.userRating,
      ratingImage: json['ratingImage'] as String?,
      audienceRatingImage: json['audienceRatingImage'] as String?,
      genres: base.genres,
      directors: base.directors,
      writers: base.writers,
      producers: base.producers,
      countries: base.countries,
      collections: base.collections,
      labels: base.labels,
      styles: base.styles,
      moods: base.moods,
      roles: base.roles,
      mediaVersions: base.mediaVersions,
      libraryId: base.libraryId,
      libraryTitle: base.libraryTitle,
      audioLanguage: base.audioLanguage,
      subtitleLanguage: json['subtitleLanguage'] as String?,
      subtitleMode: flexibleInt(json['subtitleMode']),
      trailerKey: json['trailerKey'] as String?,
      playlistItemId: flexibleInt(json['playlistItemId']),
      playQueueItemId: flexibleInt(json['playQueueItemId']),
      subtype: json['subtype'] as String?,
      extraType: flexibleInt(json['extraType']),
      serverId: base.serverId,
      serverName: base.serverName,
      raw: base.raw,
    );
  }
}

/// Backend-tagged concrete subclass for items sourced from a Jellyfin
/// server. Carries only the backend-neutral fields — Plex-only fields
/// (trailerKey, audienceRating, etc.) live on [PlexMediaItem] instead.
final class JellyfinMediaItem extends MediaItem {
  /// Jellyfin per-playlist item id — only set when the item came out of
  /// `/Playlists/{id}/Items`. Used as the `entryIds` / move-target id for
  /// the playlist write endpoints. Null outside playlist contexts.
  final String? playlistItemId;

  const JellyfinMediaItem({
    required super.id,
    required super.kind,
    super.guid,
    super.title,
    super.titleSort,
    super.summary,
    super.tagline,
    super.originalTitle,
    super.studio,
    super.year,
    super.originallyAvailableAt,
    super.contentRating,
    super.parentId,
    super.parentTitle,
    super.parentThumbPath,
    super.parentIndex,
    super.index,
    super.grandparentId,
    super.grandparentTitle,
    super.grandparentThumbPath,
    super.grandparentArtPath,
    super.thumbPath,
    super.artPath,
    super.clearLogoPath,
    super.backgroundSquarePath,
    super.durationMs,
    super.viewOffsetMs,
    super.viewCount,
    super.lastViewedAt,
    super.leafCount,
    super.viewedLeafCount,
    super.childCount,
    super.addedAt,
    super.updatedAt,
    super.rating,
    super.userRating,
    super.genres,
    super.directors,
    super.writers,
    super.producers,
    super.countries,
    super.collections,
    super.labels,
    super.styles,
    super.moods,
    super.roles,
    super.mediaVersions,
    super.libraryId,
    super.libraryTitle,
    super.audioLanguage,
    this.playlistItemId,
    super.serverId,
    super.serverName,
    super.raw,
  }) : super._(backend: MediaBackend.jellyfin);

  /// Override the base [MediaItem.copyWith] so [playlistItemId] survives
  /// round-trips through the absolutizer (which calls copyWith to rewrite
  /// image paths). Without this, every Jellyfin playlist item came out with
  /// `playlistItemId == null` after mapping, making the move/remove endpoints
  /// silently no-op.
  @override
  JellyfinMediaItem copyWith({
    String? id,
    MediaBackend? backend,
    MediaKind? kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,
    String? studio,
    int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    int? parentIndex,
    int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    int? durationMs,
    int? viewOffsetMs,
    int? viewCount,
    int? lastViewedAt,
    int? leafCount,
    int? viewedLeafCount,
    int? childCount,
    int? addedAt,
    int? updatedAt,
    double? rating,
    double? userRating,
    List<String>? genres,
    List<String>? directors,
    List<String>? writers,
    List<String>? producers,
    List<String>? countries,
    List<String>? collections,
    List<String>? labels,
    List<String>? styles,
    List<String>? moods,
    List<MediaRole>? roles,
    List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,
    String? subtitleLanguage,
    int? subtitleMode,
    String? playlistItemId,
    String? serverId,
    String? serverName,
    Map<String, Object?>? raw,
  }) {
    return JellyfinMediaItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      summary: summary ?? this.summary,
      tagline: tagline ?? this.tagline,
      originalTitle: originalTitle ?? this.originalTitle,
      studio: studio ?? this.studio,
      year: year ?? this.year,
      originallyAvailableAt: originallyAvailableAt ?? this.originallyAvailableAt,
      contentRating: contentRating ?? this.contentRating,
      parentId: parentId ?? this.parentId,
      parentTitle: parentTitle ?? this.parentTitle,
      parentThumbPath: parentThumbPath ?? this.parentThumbPath,
      parentIndex: parentIndex ?? this.parentIndex,
      index: index ?? this.index,
      grandparentId: grandparentId ?? this.grandparentId,
      grandparentTitle: grandparentTitle ?? this.grandparentTitle,
      grandparentThumbPath: grandparentThumbPath ?? this.grandparentThumbPath,
      grandparentArtPath: grandparentArtPath ?? this.grandparentArtPath,
      thumbPath: thumbPath ?? this.thumbPath,
      artPath: artPath ?? this.artPath,
      clearLogoPath: clearLogoPath ?? this.clearLogoPath,
      backgroundSquarePath: backgroundSquarePath ?? this.backgroundSquarePath,
      durationMs: durationMs ?? this.durationMs,
      viewOffsetMs: viewOffsetMs ?? this.viewOffsetMs,
      viewCount: viewCount ?? this.viewCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      leafCount: leafCount ?? this.leafCount,
      viewedLeafCount: viewedLeafCount ?? this.viewedLeafCount,
      childCount: childCount ?? this.childCount,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      userRating: userRating ?? this.userRating,
      genres: genres ?? this.genres,
      directors: directors ?? this.directors,
      writers: writers ?? this.writers,
      producers: producers ?? this.producers,
      countries: countries ?? this.countries,
      collections: collections ?? this.collections,
      labels: labels ?? this.labels,
      styles: styles ?? this.styles,
      moods: moods ?? this.moods,
      roles: roles ?? this.roles,
      mediaVersions: mediaVersions ?? this.mediaVersions,
      libraryId: libraryId ?? this.libraryId,
      libraryTitle: libraryTitle ?? this.libraryTitle,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      playlistItemId: playlistItemId ?? this.playlistItemId,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      raw: raw ?? this.raw,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), if (playlistItemId != null) 'playlistItemId': playlistItemId};
  }

  /// Restore a [JellyfinMediaItem] from a [toJson] payload. Used as the
  /// non-Plex fallback by [MediaItem.fromJson].
  factory JellyfinMediaItem.fromJson(Map<String, dynamic> json) {
    final base = _parseBaseFields(json);
    return JellyfinMediaItem(
      id: base.id,
      kind: base.kind,
      guid: base.guid,
      title: base.title,
      titleSort: base.titleSort,
      summary: base.summary,
      tagline: base.tagline,
      originalTitle: base.originalTitle,
      studio: base.studio,
      year: base.year,
      originallyAvailableAt: base.originallyAvailableAt,
      contentRating: base.contentRating,
      parentId: base.parentId,
      parentTitle: base.parentTitle,
      parentThumbPath: base.parentThumbPath,
      parentIndex: base.parentIndex,
      index: base.index,
      grandparentId: base.grandparentId,
      grandparentTitle: base.grandparentTitle,
      grandparentThumbPath: base.grandparentThumbPath,
      grandparentArtPath: base.grandparentArtPath,
      thumbPath: base.thumbPath,
      artPath: base.artPath,
      clearLogoPath: base.clearLogoPath,
      backgroundSquarePath: base.backgroundSquarePath,
      durationMs: base.durationMs,
      viewOffsetMs: base.viewOffsetMs,
      viewCount: base.viewCount,
      lastViewedAt: base.lastViewedAt,
      leafCount: base.leafCount,
      viewedLeafCount: base.viewedLeafCount,
      childCount: base.childCount,
      addedAt: base.addedAt,
      updatedAt: base.updatedAt,
      rating: base.rating,
      userRating: base.userRating,
      genres: base.genres,
      directors: base.directors,
      writers: base.writers,
      producers: base.producers,
      countries: base.countries,
      collections: base.collections,
      labels: base.labels,
      styles: base.styles,
      moods: base.moods,
      roles: base.roles,
      mediaVersions: base.mediaVersions,
      libraryId: base.libraryId,
      libraryTitle: base.libraryTitle,
      audioLanguage: base.audioLanguage,
      playlistItemId: json['playlistItemId'] as String?,
      serverId: base.serverId,
      serverName: base.serverName,
      raw: base.raw,
    );
  }
}

List<String>? _stringList(Object? raw) {
  return stringListFromRaw(raw, stringify: true);
}

Map<String, dynamic> _roleToJson(MediaRole role) => {
  if (role.id != null) 'id': role.id,
  'tag': role.tag,
  if (role.role != null) 'role': role.role,
  if (role.thumbPath != null) 'thumbPath': role.thumbPath,
};

MediaRole _roleFromJson(Map<String, dynamic> json) => MediaRole(
  id: json['id'] as String?,
  tag: (json['tag'] ?? '').toString(),
  role: json['role'] as String?,
  thumbPath: json['thumbPath'] as String?,
);

Map<String, dynamic> _versionToJson(MediaVersion v) => {
  'id': v.id,
  if (v.width != null) 'width': v.width,
  if (v.height != null) 'height': v.height,
  if (v.videoResolution != null) 'videoResolution': v.videoResolution,
  if (v.videoCodec != null) 'videoCodec': v.videoCodec,
  if (v.bitrate != null) 'bitrate': v.bitrate,
  if (v.container != null) 'container': v.container,
  if (v.name != null) 'name': v.name,
  'parts': [
    for (final p in v.parts)
      {
        'id': p.id,
        if (p.streamPath != null) 'streamPath': p.streamPath,
        if (p.sizeBytes != null) 'sizeBytes': p.sizeBytes,
        if (p.container != null) 'container': p.container,
        if (p.durationMs != null) 'durationMs': p.durationMs,
        if (p.accessible != null) 'accessible': p.accessible,
        if (p.exists != null) 'exists': p.exists,
      },
  ],
};

MediaVersion _versionFromJson(Map<String, dynamic> json) {
  final partsRaw = json['parts'];
  return MediaVersion(
    id: (json['id'] ?? '').toString(),
    width: flexibleInt(json['width']),
    height: flexibleInt(json['height']),
    videoResolution: json['videoResolution'] as String?,
    videoCodec: json['videoCodec'] as String?,
    bitrate: flexibleInt(json['bitrate']),
    container: json['container'] as String?,
    name: json['name'] as String?,
    parts: partsRaw is List
        ? [
            for (final p in partsRaw)
              if (p is Map<String, dynamic>)
                MediaPart(
                  id: (p['id'] ?? '').toString(),
                  streamPath: p['streamPath'] as String?,
                  sizeBytes: flexibleInt(p['sizeBytes']),
                  container: p['container'] as String?,
                  durationMs: flexibleInt(p['durationMs']),
                  accessible: p['accessible'] as bool?,
                  exists: p['exists'] as bool?,
                ),
          ]
        : const [],
  );
}
