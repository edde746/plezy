// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'ids.dart';

import '../services/settings_service.dart' show EpisodePosterMode;
import '../utils/global_key_utils.dart';
import '../utils/json_utils.dart';
import 'media_backend.dart';
import 'media_kind.dart';
import 'media_role.dart';
import 'media_version.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

/// Backend-neutral media item shape used by UI, providers, persistence, and
/// playback. Concrete variants retain backend-only fields without forcing the
/// rest of the app to traffic in Plex/Jellyfin DTOs.
@Freezed(unionKey: 'backend', unionValueCase: FreezedUnionCase.none, equal: false, makeCollectionsUnmodifiable: false)
sealed class MediaItem with _$MediaItem {
  const MediaItem._();

  /// Backend-dispatching compatibility factory used by existing call sites.
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
    bool? isFavorite,
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
    String? serverId,
    String? serverName,
    String? backendFolderKey,
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
        isFavorite: isFavorite,
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
        backendFolderKey: backendFolderKey,
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
        isFavorite: isFavorite,
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
        backendFolderKey: backendFolderKey,
        raw: raw,
      ),
    };
  }

  /// Backend-tagged concrete subclass for items sourced from a Plex server.
  @FreezedUnionValue('plex')
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory MediaItem.plex({
    @JsonKey(readValue: readStringField, defaultValue: '') required String id,
    @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) required MediaKind kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,

    /// Plex `editionTitle` distinguishes versions of the same movie.
    String? editionTitle,
    String? studio,
    @JsonKey(fromJson: flexibleInt) int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    @JsonKey(fromJson: flexibleInt) int? parentIndex,
    @JsonKey(fromJson: flexibleInt) int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    @JsonKey(fromJson: flexibleInt) int? durationMs,
    @JsonKey(fromJson: flexibleInt) int? viewOffsetMs,
    @JsonKey(fromJson: flexibleInt) int? viewCount,
    @JsonKey(fromJson: flexibleInt) int? lastViewedAt,
    @JsonKey(fromJson: flexibleInt) int? leafCount,
    @JsonKey(fromJson: flexibleInt) int? viewedLeafCount,
    @JsonKey(fromJson: flexibleInt) int? childCount,
    @JsonKey(fromJson: flexibleInt) int? addedAt,
    @JsonKey(fromJson: flexibleInt) int? updatedAt,
    @JsonKey(fromJson: flexibleDouble) double? rating,
    @JsonKey(fromJson: flexibleDouble) double? audienceRating,
    @JsonKey(fromJson: flexibleDouble) double? userRating,
    bool? isFavorite,
    String? ratingImage,
    String? audienceRatingImage,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? genres,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? directors,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? writers,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? producers,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? countries,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? collections,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? labels,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? styles,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? moods,
    @JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? roles,
    @JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,
    String? subtitleLanguage,
    @JsonKey(fromJson: flexibleInt) int? subtitleMode,
    String? trailerKey,
    @JsonKey(fromJson: flexibleInt) int? playlistItemId,
    @JsonKey(fromJson: flexibleInt) int? playQueueItemId,
    String? subtype,
    @JsonKey(fromJson: flexibleInt) int? extraType,
    String? serverId,
    String? serverName,

    /// Relative folder key (`/library/sections/{id}/folder?parent=…`) for
    /// [MediaKind.folder] rows — what [MediaServerClient.fetchFolderChildren]
    /// tunes into. Stamped by the folder fetchers, null elsewhere.
    String? backendFolderKey,
    @JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? raw,
  }) = PlexMediaItem;

  /// Backend-tagged concrete subclass for items sourced from a Jellyfin server.
  @FreezedUnionValue('jellyfin')
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory MediaItem.jellyfin({
    @JsonKey(readValue: readStringField, defaultValue: '') required String id,
    @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) required MediaKind kind,
    String? guid,
    String? title,
    String? titleSort,
    String? summary,
    String? tagline,
    String? originalTitle,
    String? studio,
    @JsonKey(fromJson: flexibleInt) int? year,
    String? originallyAvailableAt,
    String? contentRating,
    String? parentId,
    String? parentTitle,
    String? parentThumbPath,
    @JsonKey(fromJson: flexibleInt) int? parentIndex,
    @JsonKey(fromJson: flexibleInt) int? index,
    String? grandparentId,
    String? grandparentTitle,
    String? grandparentThumbPath,
    String? grandparentArtPath,
    String? thumbPath,
    String? artPath,
    String? clearLogoPath,
    String? backgroundSquarePath,
    @JsonKey(fromJson: flexibleInt) int? durationMs,
    @JsonKey(fromJson: flexibleInt) int? viewOffsetMs,
    @JsonKey(fromJson: flexibleInt) int? viewCount,
    @JsonKey(fromJson: flexibleInt) int? lastViewedAt,
    @JsonKey(fromJson: flexibleInt) int? leafCount,
    @JsonKey(fromJson: flexibleInt) int? viewedLeafCount,
    @JsonKey(fromJson: flexibleInt) int? childCount,
    @JsonKey(fromJson: flexibleInt) int? addedAt,
    @JsonKey(fromJson: flexibleInt) int? updatedAt,
    @JsonKey(fromJson: flexibleDouble) double? rating,
    @JsonKey(fromJson: flexibleDouble) double? userRating,
    bool? isFavorite,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? genres,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? directors,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? writers,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? producers,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? countries,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? collections,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? labels,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? styles,
    @JsonKey(fromJson: _mediaItemStringList) List<String>? moods,
    @JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? roles,
    @JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? mediaVersions,
    String? libraryId,
    String? libraryTitle,
    String? audioLanguage,

    /// Jellyfin playlist entry id used by playlist write endpoints.
    String? playlistItemId,
    String? serverId,
    String? serverName,

    /// Always null on Jellyfin — folder children are fetched by [id]. Exists
    /// on both variants so the union exposes one neutral getter.
    String? backendFolderKey,
    @JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? raw,
  }) = JellyfinMediaItem;

  MediaBackend get backend => switch (this) {
    PlexMediaItem() => MediaBackend.plex,
    JellyfinMediaItem() => MediaBackend.jellyfin,
  };

  /// Restore a [MediaItem] from a [toJson] payload. Missing/unknown backend
  /// values use [MediaBackend.fromString] so old offline cache rows remain
  /// readable instead of throwing before union dispatch.
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return switch (MediaBackend.fromString(json['backend'] as String?)) {
      MediaBackend.plex => _$PlexMediaItemFromJson(json),
      MediaBackend.jellyfin => _$JellyfinMediaItemFromJson(json),
    };
  }

  Map<String, dynamic> toJson() {
    return switch (this) {
      final PlexMediaItem item => {'backend': MediaBackend.plex.id, ..._$PlexMediaItemToJson(item)},
      final JellyfinMediaItem item => {'backend': MediaBackend.jellyfin.id, ..._$JellyfinMediaItemToJson(item)},
    };
  }

  /// Global unique identifier across all servers (`serverId:id`). Falls back
  /// to bare [id] if [serverId] is missing.
  String get globalKey => serverId != null ? buildGlobalKey(ServerId(serverId!), id) : id;

  /// Global unique identifier of this item's library section.
  String? get libraryGlobalKey =>
      serverId != null && libraryId != null ? buildGlobalKey(ServerId(serverId!), libraryId!) : null;

  /// Global unique identifier of this item's series, for episodes/seasons.
  /// Null for movies and shows themselves — their own [globalKey] is already
  /// series-level.
  String? get seriesGlobalKey {
    final seriesId = switch (kind) {
      MediaKind.episode => grandparentId,
      MediaKind.season => grandparentId ?? parentId,
      _ => null,
    };
    if (seriesId == null) return null;
    return serverId != null ? buildGlobalKey(ServerId(serverId!), seriesId) : seriesId;
  }

  /// Parent rating keys for hierarchical invalidation. For an episode:
  /// `[seasonId, showId]`. For a season: `[showId]`. For a movie: `[]`.
  List<String> get parentChain => [?parentId, ?grandparentId];

  /// Server-side file paths across every version of this item. Plex
  /// represents a multi-episode file (`S02E24-E25.mkv`) as distinct episode
  /// items whose parts have *different* part ids but the same file, so the
  /// file path — not the part id — is the "same underlying file" signal
  /// (#1500).
  Set<String> get allPartFiles => {
    for (final version in mediaVersions ?? const <MediaVersion>[])
      for (final part in version.parts)
        if (part.file != null && part.file!.isNotEmpty) part.file!,
  };

  /// Whether [other] is backed by the same physical file as this item.
  /// [playedPartId] — the part actually being played, when known — pins the
  /// comparison to that part's file, so an episode with multiple versions
  /// only matches against the file on screen; otherwise any file overlap
  /// between the two items counts. Items without file metadata (Plex hides
  /// paths from restricted users) or from a different server never match.
  bool sharesFileWith(MediaItem other, {String? playedPartId}) {
    if (other.serverId != serverId) return false;
    final otherFiles = other.allPartFiles;
    if (otherFiles.isEmpty) return false;
    if (playedPartId != null) {
      final playedFile = _filePathForPart(playedPartId);
      if (playedFile != null) return otherFiles.contains(playedFile);
    }
    return allPartFiles.intersection(otherFiles).isNotEmpty;
  }

  /// The file path of this item's part with [partId], or null when unknown.
  String? _filePathForPart(String partId) {
    for (final version in mediaVersions ?? const <MediaVersion>[]) {
      for (final part in version.parts) {
        if (part.id == partId) return (part.file?.isEmpty ?? true) ? null : part.file;
      }
    }
    return null;
  }

  /// Recency used to order the Continue Watching / On Deck shelf: when the item
  /// was last watched, falling back to when it was added for never-watched rows.
  /// Shared by the per-client merge and the cross-server sort so they agree.
  int get recencySortKey => lastViewedAt ?? addedAt ?? 0;

  /// Whether this item has started but not finished playback.
  bool get hasActiveProgress {
    if (durationMs == null || viewOffsetMs == null) return false;
    return viewOffsetMs! > 0 && viewOffsetMs! < durationMs!;
  }

  /// Whether this item still counts toward an "unwatched only" selection:
  /// not fully watched, or watched-but-resumable (has active progress). The
  /// shared predicate behind every `unwatchedOnly` filter (downloads, sync
  /// rules, the unwatched-episode lookups in episode_collection.dart).
  bool get isUnwatchedOrInProgress => !isWatched || hasActiveProgress;

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

  /// Unwatched leaf count for container badges. Falls back to Jellyfin's
  /// `UserData.UnplayedItemCount` when leaf totals weren't requested
  /// (e.g. the folder tree's slim field set).
  int? get unwatchedCount {
    if (leafCount != null && viewedLeafCount != null) return leafCount! - viewedLeafCount!;
    final userData = raw?['UserData'];
    return userData is Map<String, dynamic> ? userData['UnplayedItemCount'] as int? : null;
  }

  /// Copy with the watched flag applied so [isWatched] reflects it for every
  /// kind: containers need their leaf counts patched, not just [viewCount].
  MediaItem withWatchedFlag(bool isWatched) {
    var updated = copyWith(viewCount: isWatched ? 1 : 0);
    if (leafCount != null || viewedLeafCount != null) {
      updated = updated.copyWith(viewedLeafCount: isWatched ? (leafCount ?? viewedLeafCount ?? 1) : 0);
    }
    return updated;
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

  /// Track number within its disc, for [MediaKind.track] items.
  int? get trackNumber => kind == MediaKind.track ? index : null;

  /// Disc number for [MediaKind.track] items (Plex `parentIndex`, Jellyfin
  /// `ParentIndexNumber`). Null/1 on single-disc albums.
  int? get discNumber => kind == MediaKind.track ? parentIndex : null;

  /// Album title for music items: a track's parent, an album's own title.
  String? get albumTitle => switch (kind) {
    MediaKind.track => parentTitle,
    MediaKind.album => title,
    _ => null,
  };

  /// Album-artist name for music items: a track's grandparent, an album's
  /// parent.
  String? get albumArtistTitle => switch (kind) {
    MediaKind.track => grandparentTitle,
    MediaKind.album => parentTitle,
    _ => null,
  };

  /// Performing artist of a track. Falls back to [albumArtistTitle] — both
  /// backends only populate a separate value when it differs (Plex stores a
  /// compilation track's own artist in `originalTitle`; the Jellyfin mapper
  /// mirrors that convention from `Artists`).
  String? get trackArtistTitle => kind == MediaKind.track ? (originalTitle ?? albumArtistTitle) : null;

  /// Plex-only edition label. Jellyfin returns null.
  String? get editionTitle => null;

  /// Returns the appropriate poster path based on episode poster mode.
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

    if (kind == MediaKind.clip) return thumbPath ?? artPath;

    return thumbPath;
  }

  /// Secondary poster path to try when [posterThumb] returns an image URL that
  /// exists syntactically but the server cannot serve it.
  String? posterThumbFallback({EpisodePosterMode mode = EpisodePosterMode.seriesPoster, bool mixedHubContext = false}) {
    if (kind != MediaKind.episode || mode != EpisodePosterMode.seasonPoster) return null;
    final fallback = grandparentThumbPath ?? thumbPath;
    return fallback != null && fallback != posterThumb(mode: mode, mixedHubContext: mixedHubContext) ? fallback : null;
  }

  /// True when the item should render in 16:9.
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

  /// The card silhouette this item renders with. Music items (artist/album/
  /// track) are square; everything else folds in the [usesWideAspectRatio]
  /// wide-vs-poster decision, so the two can never disagree.
  CardShape cardShape(EpisodePosterMode mode, {bool mixedHubContext = false}) {
    if (kind.isMusic) return CardShape.square;
    return usesWideAspectRatio(mode, mixedHubContext: mixedHubContext) ? CardShape.wide : CardShape.poster;
  }

  /// Returns the best hero art path based on the container's aspect ratio.
  String? heroArt({required double containerAspectRatio}) {
    final candidates = heroArtCandidates(containerAspectRatio: containerAspectRatio);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  /// Returns hero art candidates in display-preference order.
  List<String> heroArtCandidates({required double containerAspectRatio}) {
    final preferred = switch (kind) {
      MediaKind.episode when containerAspectRatio < 1.39 => [backgroundSquarePath, grandparentArtPath, artPath],
      MediaKind.episode => [grandparentArtPath, artPath, backgroundSquarePath],
      _ when containerAspectRatio < 1.39 => [backgroundSquarePath, artPath],
      _ => [artPath, backgroundSquarePath],
    };

    final candidates = <String>[];
    for (final path in preferred) {
      if (path == null || path.isEmpty || candidates.contains(path)) continue;
      candidates.add(path);
    }
    return candidates;
  }
}

/// The silhouette a media card renders with: 2:3 posters, 16:9 wide
/// thumbnails (episodes/clips), or 1:1 squares (music artwork; artists clip
/// to a circle). Resolved per item via [MediaItem.cardShape].
enum CardShape { poster, wide, square }

MediaKind _mediaKindFromJson(Object? raw) => MediaKind.fromString(raw as String?);

String _mediaKindToJson(MediaKind kind) => kind.id;

List<String>? _mediaItemStringList(Object? raw) => stringListFromRaw(raw, stringify: true);

List<MediaRole>? _mediaItemRolesFromJson(Object? raw) {
  return raw is List
      ? [
          for (final role in raw)
            if (role is Map<String, dynamic>) MediaRole.fromJson(role),
        ]
      : null;
}

List<MediaVersion>? _mediaItemVersionsFromJson(Object? raw) {
  return raw is List
      ? [
          for (final version in raw)
            if (version is Map<String, dynamic>) MediaVersion.fromJson(version),
        ]
      : null;
}

Map<String, Object?>? _mediaItemRawFromJson(Object? raw) => raw is Map ? Map<String, Object?>.from(raw) : null;
