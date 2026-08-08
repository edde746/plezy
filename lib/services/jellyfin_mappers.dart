import '../media/media_browser_dialect.dart';
import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_part.dart';
import '../media/media_rating.dart';
import '../media/media_role.dart';
import '../media/media_stream.dart';
import '../media/media_version.dart';
import '../i18n/strings.g.dart';
import '../utils/jellyfin_time.dart';
import '../utils/json_utils.dart';
import '../utils/resolution_label.dart';
import 'file_info_parser.dart';
import 'jellyfin_display_metadata.dart';

// Re-export so existing callers that pulled `resolutionLabelFromHeight`
// from this file keep compiling without a bulk import rewrite.
export '../utils/resolution_label.dart' show resolutionLabelFromHeight;

Map<String, dynamic>? jellyfinFirstVideoStream(Object? streams) {
  if (streams is! List) return null;
  for (final stream in streams) {
    if (stream is Map<String, dynamic> && (stream['Type'] as String?)?.toLowerCase() == 'video') {
      return stream;
    }
  }
  return null;
}

MediaVersion jellyfinMediaSourceToVersion(
  Map<String, dynamic> source, {
  required String versionId,
  required String partId,
  String? streamPath,
  List<MediaStream> streams = const [],
  bool includePartDuration = false,
  bool requireParsedVideoStreamForDimensions = false,
  String? name,
}) {
  final rawVideo = jellyfinFirstVideoStream(source['MediaStreams']);
  final parsedVideo = streams.firstWhere(
    (stream) => stream.kind == MediaStreamKind.video,
    orElse: () => const MediaStream(id: '', kind: MediaStreamKind.unknown),
  );
  final hasParsedVideo = parsedVideo.kind == MediaStreamKind.video;
  final width = flexibleInt(source['Width']) ?? flexibleInt(rawVideo?['Width']);
  final height = flexibleInt(source['Height']) ?? flexibleInt(rawVideo?['Height']);
  final exposeDimensions = !requireParsedVideoStreamForDimensions || hasParsedVideo;
  return MediaVersion(
    id: versionId,
    width: exposeDimensions ? width : null,
    height: exposeDimensions ? height : null,
    videoResolution: resolutionLabelFromDimensions(width, height),
    videoCodec: hasParsedVideo ? parsedVideo.codec : rawVideo?['Codec'] as String?,
    bitrate: bitrateKbpsFromBps(flexibleInt(source['Bitrate'])),
    container: source['Container'] as String?,
    parts: [
      MediaPart(
        id: partId,
        streamPath: streamPath,
        file: source['Path'] as String?,
        sizeBytes: flexibleInt(source['Size']),
        container: source['Container'] as String?,
        durationMs: includePartDuration ? jellyfinTicksToMs(source['RunTimeTicks']) : null,
        streams: streams,
      ),
    ],
    name: name,
  );
}

/// Turns relative Jellyfin image paths (e.g. `/Items/{id}/Images/Primary?tag=…`)
/// into fully-qualified, self-authenticated URLs by prepending the server's
/// [baseUrl] and appending `&api_key=<accessToken>`. Pure string ops — safe
/// to use from worker isolates and from the cache layer that doesn't hold a
/// [JellyfinClient].
class JellyfinImageAbsolutizer {
  final String baseUrl;
  final String accessToken;
  const JellyfinImageAbsolutizer({required this.baseUrl, required this.accessToken});

  static Uri joinUri({required String baseUrl, required String urlOrPath}) {
    final raw = Uri.parse(urlOrPath);
    if (raw.hasScheme) return raw;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = urlOrPath.startsWith('/') ? urlOrPath : '/$urlOrPath';
    return Uri.parse('$cleanBase$cleanPath');
  }

  String? absolutize(String? path) {
    if (path == null || path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final uri = joinUri(baseUrl: baseUrl, urlOrPath: path);
    final params = Map<String, String>.from(uri.queryParameters)..['api_key'] = accessToken;
    return uri.replace(queryParameters: params).toString();
  }

  /// Walk a [MediaItem] and replace every relative image path with the
  /// absolute, self-authenticated form. Cheap — touches a handful of
  /// nullable strings and reuses the existing [MediaItem.copyWith].
  MediaItem applyTo(MediaItem item) {
    final backdropPaths = item.backdropPaths?.map((path) => absolutize(path)!).toList(growable: false);
    final grandparentBackdropPaths = item.grandparentBackdropPaths
        ?.map((path) => absolutize(path)!)
        .toList(growable: false);
    return item.copyWith(
      thumbPath: absolutize(item.thumbPath),
      artPath: backdropPaths == null || backdropPaths.isEmpty ? absolutize(item.artPath) : backdropPaths.first,
      backdropPaths: backdropPaths,
      clearLogoPath: absolutize(item.clearLogoPath),
      backgroundSquarePath: absolutize(item.backgroundSquarePath),
      parentThumbPath: absolutize(item.parentThumbPath),
      grandparentThumbPath: absolutize(item.grandparentThumbPath),
      grandparentArtPath: grandparentBackdropPaths == null || grandparentBackdropPaths.isEmpty
          ? absolutize(item.grandparentArtPath)
          : grandparentBackdropPaths.first,
      grandparentBackdropPaths: grandparentBackdropPaths,
      // Cast headshots come from the same /Items/{personId}/Images/Primary
      // endpoint and need the same absolutize+api_key treatment, otherwise
      // they get routed through Plex's photo proxy and 404.
      roles: item.roles
          ?.map((r) => MediaRole(id: r.id, tag: r.tag, role: r.role, thumbPath: absolutize(r.thumbPath)))
          .toList(),
    );
  }
}

/// Absolute URL of a Jellyfin user's own profile picture, or `null` when the
/// user has none (absent [tag]) — returning null keeps us from firing a
/// request that can only 404.
///
/// Unlike item artwork this endpoint carries **no `api_key`**: the user-image
/// GET has never been authenticated (no `[Authorize]`, and Jellyfin sets no
/// ASP.NET `FallbackPolicy`) on any release from 10.6 through 12.0-dev.
/// Leaving the token out keeps it off the image cache key and out of anything
/// that logs or persists the URL.
///
/// The legacy `/Users/{id}/Images/Primary` route is used rather than 10.9's
/// `/UserImage` because Plezy declares no minimum server version; upstream
/// still routes the legacy shape and annotates it "Kept for backwards
/// compatibility". The `{imageType}` segment is bound but ignored server-side
/// — it always serves the profile image.
///
/// [tag] is the server's `PrimaryImageTag`, `MD5(imagePath + lastModified)`,
/// so the URL changes exactly when the picture does and is a safe immutable
/// cache key. [maxSize] is honoured up to 10.10 and silently ignored from
/// 10.11 on, so callers must still bound the decode themselves.
String? jellyfinUserImageUrl({
  required String baseUrl,
  required String userId,
  required String? tag,
  int maxSize = 240,
}) {
  if (baseUrl.isEmpty || userId.isEmpty || tag == null || tag.isEmpty) return null;
  final uri = JellyfinImageAbsolutizer.joinUri(
    baseUrl: baseUrl,
    urlOrPath: '/Users/${Uri.encodeComponent(userId)}/Images/Primary',
  );
  return uri.replace(queryParameters: {'tag': tag, 'maxWidth': '$maxSize', 'maxHeight': '$maxSize'}).toString();
}

/// Pure mapping functions from Jellyfin's `BaseItemDto` JSON shape into the
/// neutral [MediaItem] / [MediaLibrary] domain types.
///
/// Kept as top-level functions (no class) so they're trivially testable
/// against canned JSON fixtures and don't need a [JellyfinClient] instance.
class JellyfinMappers {
  JellyfinMappers._();

  static String _segment(String value) => Uri.encodeComponent(value);

  static String _query(String value) => Uri.encodeComponent(value);

  static String _itemImagePath(String id, String type, {String? tag, int? imageIndex}) {
    final indexPart = imageIndex != null ? '/$imageIndex' : '';
    final tagPart = tag != null ? '?tag=${_query(tag)}' : '';
    return '/Items/${_segment(id)}/Images/$type$indexPart$tagPart';
  }

  /// Map a MediaBrowser `BaseItemDto` (the `Items[]` shape returned by most
  /// browse endpoints) into a [MediaItem]. Returns `null` when the server
  /// payload is missing `Id` — the mapped item would otherwise carry an
  /// empty-string id that breaks cache keys and image URLs (e.g.
  /// `/Items//Images/Primary`). Callers should filter nulls with
  /// `.whereType<MediaItem>()`.
  ///
  /// [dialect] stamps the produced item so downstream UI resolves the right
  /// backend badge/label. Jellyfin and Emby DTOs are field-identical, so the
  /// mapping itself is shared.
  static MediaItem? mediaItem(
    Map<String, dynamic> item, {
    required ServerId serverId,
    String? serverName,
    required JellyfinImageAbsolutizer? absolutizer,
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
  }) {
    final id = item['Id'] as String?;
    if (id == null || id.isEmpty) return null;
    final type = item['Type'] as String?;
    // Untyped rows that Jellyfin still flags as folders (defensive — typed
    // Folder/CollectionFolder rows resolve via fromString) classify as
    // folders so folder browsing never falls back to raw-map sniffing.
    final kind = type == null && item['IsFolder'] == true ? MediaKind.folder : MediaKind.fromString(type);
    final childCount = _nonNegativeCount(item['ChildCount']);
    final leafCount = _nonNegativeCount(item['RecursiveItemCount']) ?? childCount;
    final albumPrimaryImage = kind == MediaKind.track ? _albumPrimaryImage(item) : null;
    final backdropPaths = _backdropImagePaths(id, item['BackdropImageTags']);
    final parentBackdropPaths = _parentBackdropImagePaths(item);
    final seriesBackdropPath = _seriesBackdropImage(item);
    final grandparentBackdropPaths = parentBackdropPaths.isNotEmpty
        ? parentBackdropPaths
        : seriesBackdropPath == null
        ? const <String>[]
        : <String>[seriesBackdropPath];

    final mapped = JellyfinMediaItem(
      dialect: dialect,
      id: id,
      kind: kind,
      guid: id,
      title: item['Name'] as String?,
      titleSort: item['SortName'] as String?,
      summary: item['Overview'] as String?,
      tagline: _firstString(item['Taglines']),
      // Music: a compilation track's own performer(s) go into originalTitle
      // (matching Plex's convention) so MediaItem.trackArtistTitle can prefer
      // it over the album artist. Only set when it actually differs.
      originalTitle: item['OriginalTitle'] as String? ?? _trackArtistsOriginalTitle(item),
      studio: _firstStudioName(item['Studios']),
      year: item['ProductionYear'] as int?,
      originallyAvailableAt: jellyfinIsoToYmd(item['PremiereDate'] as String?),
      contentRating: item['OfficialRating'] as String?,
      // Music mirrors the episode hierarchy, matching Plex's parent chain:
      // track parent = album (AlbumId / Album), track grandparent = album
      // artist (AlbumArtists[0] / AlbumArtist), and an *album's* parent is its
      // artist (Jellyfin album dtos link artists via tags, not ParentId).
      // Video rows never carry the Album* fields, so the extra fallbacks are
      // inert for them.
      parentId:
          item['SeasonId'] as String? ??
          item['AlbumId'] as String? ??
          (kind == MediaKind.album ? _firstAlbumArtistId(item) : null) ??
          item['ParentId'] as String?,
      parentTitle:
          item['SeasonName'] as String? ??
          item['Album'] as String? ??
          (kind == MediaKind.album ? item['AlbumArtist'] as String? : null),
      parentThumbPath: _imagePath(item, 'SeasonId', 'SeasonPrimaryImageTag', 'Primary') ?? albumPrimaryImage,
      parentIndex: item['ParentIndexNumber'] as int?,
      index: item['IndexNumber'] as int?,
      grandparentId: item['SeriesId'] as String? ?? (kind == MediaKind.track ? _firstAlbumArtistId(item) : null),
      grandparentTitle:
          item['SeriesName'] as String? ?? (kind == MediaKind.track ? item['AlbumArtist'] as String? : null),
      grandparentThumbPath: _seriesPrimaryImage(item),
      grandparentArtPath: grandparentBackdropPaths.firstOrNull,
      grandparentBackdropPaths: grandparentBackdropPaths.isEmpty ? null : grandparentBackdropPaths,
      thumbPath: _selfImagePath(id, item, 'Primary') ?? albumPrimaryImage,
      artPath: backdropPaths.firstOrNull,
      backdropPaths: backdropPaths.isEmpty ? null : backdropPaths,
      // Episodes/seasons don't carry their own logo — Jellyfin exposes the
      // parent's logo via ParentLogoItemId/ParentLogoImageTag, which is
      // what JF web renders on the hero card.
      clearLogoPath: _selfImagePath(id, item, 'Logo') ?? _parentLogoImage(item),
      durationMs: jellyfinTicksToMs(item['RunTimeTicks']),
      viewOffsetMs: jellyfinTicksToMs(_userData(item)?['PlaybackPositionTicks']),
      viewCount: _viewCount(item),
      lastViewedAt: jellyfinIsoToEpochSeconds(_userData(item)?['LastPlayedDate'] as String?),
      // leafCount also drives display counts. viewedLeafCount is watched-state
      // rollup and applies only to container kinds; Jellyfin may include
      // unrelated child counts on leaf DTOs.
      leafCount: leafCount,
      viewedLeafCount: kind.usesLeafWatchCounts ? _viewedLeafCount(item, leafCount) : null,
      childCount: childCount,
      addedAt: jellyfinIsoToEpochSeconds(item['DateCreated'] as String?),
      updatedAt: jellyfinIsoToEpochSeconds(item['DateLastSaved'] as String? ?? item['DateModified'] as String?),
      rating: (item['CommunityRating'] as num?)?.toDouble(),
      ratings: _ratingSources(item, kind),
      isFavorite: _userData(item)?['IsFavorite'] as bool?,
      genres: _stringListOrNamePairs(item['Genres'], item['GenreItems']),
      directors: _peopleByType(item['People'], 'Director'),
      writers: _peopleByType(item['People'], 'Writer'),
      producers: _peopleByType(item['People'], 'Producer'),
      countries: _stringList(item['ProductionLocations']),
      collections: null,
      labels: _stringListOrNamePairs(item['Tags'], item['TagItems']),
      styles: null,
      moods: null,
      roles: _actors(item['People']),
      mediaVersions: _mediaVersions(item['MediaSources']),
      libraryId: item['ParentLibraryId'] as String? ?? item['ParentId'] as String?,
      libraryTitle: item['ParentLibraryName'] as String? ?? item['SeriesStudio'] as String?,
      audioLanguage: item['PreferredMetadataLanguage'] as String?,
      // Only present when the item came out of `/Playlists/{id}/Items`; the
      // playlist write endpoints address rows by this id, not the media id.
      playlistItemId: item['PlaylistItemId'] as String?,
      serverId: serverId,
      serverName: serverName,
      raw: item,
    );
    return absolutizer == null ? mapped : absolutizer.applyTo(mapped);
  }

  /// Map a MediaBrowser "view" (returned by `/Users/{userId}/Views`) into a
  /// [MediaLibrary]. The CollectionType field maps onto [MediaKind] roughly.
  /// Returns `null` when the view is missing `Id` — same rationale as
  /// [mediaItem].
  static MediaLibrary? library(
    Map<String, dynamic> view, {
    required ServerId serverId,
    String? serverName,
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
  }) {
    final id = view['Id'] as String?;
    if (id == null || id.isEmpty) return null;
    final collectionType = view['CollectionType'] as String?;
    final type = view['Type'] as String?;
    return MediaLibrary(
      id: id,
      backend: dialect.backend,
      title: view['Name'] as String? ?? t.libraries.fallbackTitle,
      kind: _libraryKindFromCollectionType(collectionType, type),
      defaultBrowseKinds: _defaultBrowseKindsFromCollectionType(collectionType, type),
      updatedAt: jellyfinIsoToEpochSeconds(view['DateLastSaved'] as String? ?? view['DateModified'] as String?),
      createdAt: jellyfinIsoToEpochSeconds(view['DateCreated'] as String?),
      hidden: false,
      isShared: false,
      serverId: serverId,
      serverName: serverName,
    );
  }

  /// Build a [MediaHub] from a list of items pre-fetched for a synthesized
  /// home-screen row (Jellyfin doesn't have a single hub endpoint).
  ///
  /// [mapItem] lets the caller (typically [JellyfinClient]) inject its own
  /// mapping pipeline so per-instance concerns like absolutizing image paths
  /// against the connection's baseUrl/token can run. The mapper may return
  /// `null` (matching [mediaItem]'s contract for missing-`Id` rows); those
  /// entries are dropped from the hub.
  static MediaHub syntheticHub({
    required String identifier,
    required String title,
    required String type,
    required List<Map<String, dynamic>> items,
    required ServerId serverId,
    String? serverName,
    MediaItem? Function(Map<String, dynamic>)? mapItem,
    int? previewLimit,
  }) {
    final mapper = mapItem ?? ((it) => mediaItem(it, serverId: serverId, serverName: serverName, absolutizer: null));
    final mappedItems = items.map(mapper).whereType<MediaItem>().toList();
    return MediaHub(
      id: identifier,
      identifier: identifier,
      title: title,
      type: type,
      items: mappedItems,
      size: mappedItems.length,
      more: previewLimit != null && items.length >= previewLimit,
      serverId: serverId,
      serverName: serverName,
    );
  }

  static MediaKind _libraryKindFromCollectionType(String? collectionType, String? type) {
    final ct = collectionType?.trim().toLowerCase();
    if (ct != null && ct.isNotEmpty) {
      return switch (ct) {
        'movies' => MediaKind.movie,
        'tvshows' => MediaKind.show,
        'music' => MediaKind.artist,
        'musicvideos' => MediaKind.clip,
        'homevideos' => MediaKind.clip,
        'photos' => MediaKind.photo,
        'boxsets' => MediaKind.collection,
        'playlists' => MediaKind.playlist,
        _ => MediaKind.unknown,
      };
    }
    return MediaKind.fromString(type);
  }

  static List<MediaKind> _defaultBrowseKindsFromCollectionType(String? collectionType, String? type) {
    final ct = collectionType?.trim();
    return (ct == null || ct.isEmpty) && type?.toLowerCase() == 'collectionfolder'
        ? const [MediaKind.movie, MediaKind.show]
        : const <MediaKind>[];
  }

  static Map<String, dynamic>? _userData(Map<String, dynamic> item) {
    final ud = item['UserData'];
    return ud is Map<String, dynamic> ? ud : null;
  }

  static int? _nonNegativeCount(Object? value) {
    final count = flexibleInt(value);
    return count != null && count >= 0 ? count : null;
  }

  static int _viewCount(Map<String, dynamic> item) {
    final ud = _userData(item);
    if (ud?['Played'] != true) return 0;
    final playCount = flexibleInt(ud?['PlayCount']);
    if (playCount != null && playCount > 0) return playCount;
    return 1;
  }

  static int? _viewedLeafCount(Map<String, dynamic> item, int? total) {
    final unplayed = _nonNegativeCount(_userData(item)?['UnplayedItemCount']);
    if (total == null || unplayed == null) return null;
    if (unplayed >= total) return 0;
    return total - unplayed;
  }

  /// Jellyfin's two rating slots, community score first.
  ///
  /// `BaseItemDto` has no per-source array — the server collapses whatever the
  /// metadata fetchers found into these two fields, so this is at most two
  /// entries. Both arrive on every response; neither is gated behind `Fields`.
  ///
  /// `CommunityRating` is 0-10 but its provenance is unknowable from the DTO
  /// (TMDB `vote_average`, IMDb via OMDb, or a local NFO — last writer wins),
  /// so it stays the generic `audience` source with no brand badge.
  /// `CriticRating` is the Rotten Tomatoes Tomatometer as a 0-100 percent, so
  /// it is divided rather than range-sniffed: a Tomatometer of 9 means 9%.
  static List<MediaRatingSource>? _ratingSources(Map<String, dynamic> item, MediaKind kind) {
    // Photo items reuse CommunityRating for the EXIF 0-5 star rating.
    if (kind == MediaKind.photo) return null;

    final ratings = <MediaRatingSource>[];
    if (_finiteRating(item['CommunityRating']) case final community? when community >= 0 && community <= 10) {
      ratings.add(MediaRatingSource(source: 'audience', value: community));
    }
    if (_finiteRating(item['CriticRating']) case final critic? when critic >= 0 && critic <= 100) {
      ratings.add(MediaRatingSource(source: 'rottenTomatoesCritic', value: critic / 10));
    }
    return ratings.isEmpty ? null : ratings;
  }

  static double? _finiteRating(Object? value) {
    final rating = flexibleDouble(value);
    return rating != null && rating.isFinite ? rating : null;
  }

  static String? _firstString(Object? list) {
    if (list is List && list.isNotEmpty && list.first is String) return list.first as String;
    return null;
  }

  static String? _firstStudioName(Object? list) {
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map<String, dynamic>) return first['Name'] as String?;
    }
    return null;
  }

  static List<String>? _stringList(Object? list) {
    return stringListFromRaw(list);
  }

  /// A `Genres`/`Tags` style list, falling back to its `…Items` name-pair
  /// sibling when the plain array is absent.
  ///
  /// Emby never returns the plain `Tags` array on an item DTO — only
  /// `TagItems` — whatever `Fields` the request asks for (measured on Emby
  /// 4.9.5), so reading the plain key alone silently drops every tag.
  static List<String>? _stringListOrNamePairs(Object? plain, Object? namePairs) {
    final direct = stringListFromRaw(plain);
    if (direct != null && direct.isNotEmpty) return direct;
    if (namePairs is! List) return direct;
    final result = <String>[];
    for (final entry in namePairs) {
      if (entry is! Map<String, dynamic>) continue;
      final name = entry['Name'];
      if (name is String && name.trim().isNotEmpty) result.add(name.trim());
    }
    return nullIfEmptyList(result) ?? direct;
  }

  static List<String>? _peopleByType(Object? list, String type) {
    if (list is! List) return null;
    final result = <String>[];
    for (final entry in list) {
      if (entry is Map<String, dynamic> && entry['Type'] == type) {
        final name = entry['Name'] as String?;
        if (name != null) result.add(name);
      }
    }
    return nullIfEmptyList(result);
  }

  static List<MediaRole>? _actors(Object? list) {
    if (list is! List) return null;
    final result = <MediaRole>[];
    for (final entry in list) {
      if (entry is Map<String, dynamic> && (entry['Type'] == 'Actor' || entry['Type'] == 'GuestStar')) {
        result.add(
          MediaRole(
            id: entry['Id'] as String?,
            tag: entry['Name'] as String? ?? '',
            role: entry['Role'] as String?,
            thumbPath: _personImage(entry),
          ),
        );
      }
    }
    return nullIfEmptyList(result);
  }

  static String? _personImage(Map<String, dynamic> person) {
    final id = person['Id'] as String?;
    final tag = person['PrimaryImageTag'] as String?;
    if (id == null) return null;
    return _itemImagePath(id, 'Primary', tag: tag);
  }

  static List<MediaVersion>? _mediaVersions(Object? sources) {
    if (sources is! List) return null;
    final result = <MediaVersion>[];
    for (final src in sources) {
      if (src is! Map<String, dynamic>) continue;
      final id = src['Id'] as String?;
      if (id == null || id.isEmpty) continue;
      final streams = _mediaStreams(src['MediaStreams'], source: src);
      result.add(
        jellyfinMediaSourceToVersion(
          src,
          versionId: id,
          partId: id,
          streamPath: '/Videos/${_segment(id)}/stream',
          streams: streams,
          includePartDuration: true,
          requireParsedVideoStreamForDimensions: true,
          name: src['Name'] as String?,
        ),
      );
    }
    return nullIfEmptyList(result);
  }

  static List<MediaStream> _mediaStreams(Object? raw, {Map<String, dynamic>? source}) {
    if (raw is! List) return const [];
    final result = <MediaStream>[];
    final defaultAudioStreamIndex = flexibleInt(source?['DefaultAudioStreamIndex']);
    final defaultSubtitleStreamIndex = flexibleInt(source?['DefaultSubtitleStreamIndex']);
    for (final s in raw) {
      if (s is! Map<String, dynamic>) continue;
      final f = parseJellyfinStreamFields(s, fallbackIndex: result.length);
      final kind = switch (f.type) {
        'video' => MediaStreamKind.video,
        'audio' => MediaStreamKind.audio,
        'subtitle' => MediaStreamKind.subtitle,
        _ => MediaStreamKind.unknown,
      };
      final isVideo = kind == MediaStreamKind.video;
      final isDolbyVision = isVideo && jellyfinVideoStreamIsDolbyVision(s);
      result.add(
        MediaStream(
          id: '${f.index}',
          kind: kind,
          index: f.index,
          codec: f.codec,
          language: f.language,
          languageCode: f.languageCode,
          title: f.title,
          displayTitle: f.displayTitle,
          selected: _jellyfinStreamSelected(
            kind,
            f,
            defaultAudioStreamIndex: defaultAudioStreamIndex,
            defaultSubtitleStreamIndex: defaultSubtitleStreamIndex,
          ),
          channels: f.channels,
          frameRate: f.frameRate,
          hdr: isVideo && jellyfinVideoStreamIsHdr(source ?? const <String, dynamic>{}, s),
          dolbyVision: isDolbyVision,
          dolbyVisionProfile: isDolbyVision ? jellyfinDolbyVisionProfile(s) : null,
          forced: f.isForced,
          sidecarPath: f.isExternalFile ? f.deliveryUrl : null,
        ),
      );
    }
    return result;
  }

  static bool _jellyfinStreamSelected(
    MediaStreamKind kind,
    JellyfinStreamFields stream, {
    int? defaultAudioStreamIndex,
    int? defaultSubtitleStreamIndex,
  }) {
    return switch (kind) {
      MediaStreamKind.audio when defaultAudioStreamIndex != null => stream.index == defaultAudioStreamIndex,
      MediaStreamKind.subtitle when defaultSubtitleStreamIndex != null => stream.index == defaultSubtitleStreamIndex,
      _ => stream.isDefault,
    };
  }

  static String? _selfImagePath(String id, Map<String, dynamic> item, String type) {
    final tags = item['ImageTags'];
    if (tags is! Map<String, dynamic>) return null;
    final tag = tags[type];
    if (tag is! String || tag.isEmpty) return null;
    return _itemImagePath(id, type, tag: tag);
  }

  static List<String> _backdropImagePaths(String id, Object? rawTags) {
    if (rawTags is! List) return const [];
    final paths = <String>[];
    final seenTags = <String>{};
    for (var index = 0; index < rawTags.length; index++) {
      final tag = rawTags[index];
      if (tag is! String || tag.isEmpty || !seenTags.add(tag)) continue;
      paths.add(_itemImagePath(id, 'Backdrop', tag: tag, imageIndex: index));
    }
    return paths;
  }

  /// First album-artist id for Audio/MusicAlbum rows — the music counterpart
  /// of `SeriesId` in the parent hierarchy.
  static String? _firstAlbumArtistId(Map<String, dynamic> item) {
    final albumArtists = item['AlbumArtists'];
    if (albumArtists is List && albumArtists.isNotEmpty) {
      final first = albumArtists.first;
      if (first is Map<String, dynamic>) return first['Id'] as String?;
    }
    return null;
  }

  /// Per-track performer(s) joined for display, only when they differ from
  /// the album artist (Jellyfin sets `Artists == [AlbumArtist]` on
  /// non-compilation tracks, where the value would be redundant).
  static String? _trackArtistsOriginalTitle(Map<String, dynamic> item) {
    final artists = stringListFromRaw(item['Artists']);
    if (artists == null || artists.isEmpty) return null;
    final joined = artists.join(', ');
    return joined == item['AlbumArtist'] as String? ? null : joined;
  }

  /// Album-cover fallback for Audio rows. Jellyfin normally supplies
  /// `AlbumPrimaryImageTag`, but the image endpoint does not require it and
  /// older/incompletely scanned libraries can still serve a primary image by
  /// `AlbumId`. Keep the tag when present for cache invalidation.
  static String? _albumPrimaryImage(Map<String, dynamic> item) {
    final albumId = item['AlbumId'] as String?;
    if (albumId == null || albumId.isEmpty) return null;
    return _itemImagePath(albumId, 'Primary', tag: item['AlbumPrimaryImageTag'] as String?);
  }

  static String? _seriesPrimaryImage(Map<String, dynamic> item) {
    final seriesId = item['SeriesId'] as String?;
    if (seriesId == null) return null;
    final tag = item['SeriesPrimaryImageTag'] as String?;
    return _itemImagePath(seriesId, 'Primary', tag: tag);
  }

  static String? _seriesBackdropImage(Map<String, dynamic> item) {
    final seriesId = item['SeriesId'] as String?;
    if (seriesId == null) return null;
    return _itemImagePath(seriesId, 'Backdrop', imageIndex: 0);
  }

  /// Parent backdrop helper — works for episodes (parent = series) and
  /// seasons (parent = series). Pulls every explicit
  /// `ParentBackdropItemId`/`ParentBackdropImageTags` pair Jellyfin inherits
  /// onto child items, falling back to a tagless URL when only the id exists.
  static List<String> _parentBackdropImagePaths(Map<String, dynamic> item) {
    final parentId = item['ParentBackdropItemId'] as String?;
    if (parentId == null || parentId.isEmpty) return const [];
    final paths = _backdropImagePaths(parentId, item['ParentBackdropImageTags']);
    return paths.isEmpty ? [_itemImagePath(parentId, 'Backdrop', imageIndex: 0)] : paths;
  }

  /// Parent logo helper — episodes/seasons inherit the series' logo via
  /// `ParentLogoItemId`/`ParentLogoImageTag`. Match Jellyfin web's hero
  /// card which always falls back to this for child items.
  static String? _parentLogoImage(Map<String, dynamic> item) {
    final parentId = item['ParentLogoItemId'] as String?;
    if (parentId == null) return null;
    final tag = item['ParentLogoImageTag'] as String?;
    return _itemImagePath(parentId, 'Logo', tag: tag);
  }

  static String? _imagePath(Map<String, dynamic> item, String idField, String tagField, String type) {
    final id = item[idField] as String?;
    if (id == null) return null;
    final tag = item[tagField] as String?;
    return _itemImagePath(id, type, tag: tag);
  }
}
