import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_part.dart';
import '../media/media_role.dart';
import '../media/media_stream.dart';
import '../media/media_version.dart';
import '../utils/jellyfin_time.dart';
import '../utils/json_utils.dart';
import '../utils/resolution_label.dart';
import 'file_info_parser.dart';

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
    videoResolution: resolutionLabelFromHeight(height),
    videoCodec: hasParsedVideo ? parsedVideo.codec : rawVideo?['Codec'] as String?,
    bitrate: bitrateKbpsFromBps(flexibleInt(source['Bitrate'])),
    container: source['Container'] as String?,
    parts: [
      MediaPart(
        id: partId,
        streamPath: streamPath,
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
    return item.copyWith(
      thumbPath: absolutize(item.thumbPath),
      artPath: absolutize(item.artPath),
      clearLogoPath: absolutize(item.clearLogoPath),
      backgroundSquarePath: absolutize(item.backgroundSquarePath),
      parentThumbPath: absolutize(item.parentThumbPath),
      grandparentThumbPath: absolutize(item.grandparentThumbPath),
      grandparentArtPath: absolutize(item.grandparentArtPath),
      // Cast headshots come from the same /Items/{personId}/Images/Primary
      // endpoint and need the same absolutize+api_key treatment, otherwise
      // they get routed through Plex's photo proxy and 404.
      roles: item.roles
          ?.map((r) => MediaRole(id: r.id, tag: r.tag, role: r.role, thumbPath: absolutize(r.thumbPath)))
          .toList(),
    );
  }
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

  /// Map a Jellyfin `BaseItemDto` (the `Items[]` shape returned by most
  /// browse endpoints) into a [MediaItem]. Returns `null` when the server
  /// payload is missing `Id` — the mapped item would otherwise carry an
  /// empty-string id that breaks cache keys and image URLs (e.g.
  /// `/Items//Images/Primary`). Callers should filter nulls with
  /// `.whereType<MediaItem>()`.
  static MediaItem? mediaItem(
    Map<String, dynamic> item, {
    required String serverId,
    String? serverName,
    required JellyfinImageAbsolutizer? absolutizer,
  }) {
    final id = item['Id'] as String?;
    if (id == null || id.isEmpty) return null;
    final type = item['Type'] as String?;
    final kind = MediaKind.fromString(type);

    final mapped = JellyfinMediaItem(
      id: id,
      kind: kind,
      guid: id,
      title: item['Name'] as String?,
      titleSort: item['SortName'] as String?,
      summary: item['Overview'] as String?,
      tagline: _firstString(item['Taglines']),
      originalTitle: item['OriginalTitle'] as String?,
      studio: _firstStudioName(item['Studios']),
      year: item['ProductionYear'] as int?,
      originallyAvailableAt: jellyfinIsoToYmd(item['PremiereDate'] as String?),
      contentRating: item['OfficialRating'] as String?,
      parentId: item['SeasonId'] as String? ?? item['ParentId'] as String?,
      parentTitle: item['SeasonName'] as String?,
      parentThumbPath: _imagePath(item, 'SeasonId', 'SeasonPrimaryImageTag', 'Primary'),
      parentIndex: item['ParentIndexNumber'] as int?,
      index: item['IndexNumber'] as int?,
      grandparentId: item['SeriesId'] as String?,
      grandparentTitle: item['SeriesName'] as String?,
      grandparentThumbPath: _seriesPrimaryImage(item),
      grandparentArtPath: _parentBackdropImage(item) ?? _seriesBackdropImage(item),
      thumbPath: _selfImagePath(id, item, 'Primary'),
      artPath: _selfImagePath(id, item, 'Backdrop'),
      // Episodes/seasons don't carry their own logo — Jellyfin exposes the
      // parent's logo via ParentLogoItemId/ParentLogoImageTag, which is
      // what JF web renders on the hero card.
      clearLogoPath: _selfImagePath(id, item, 'Logo') ?? _parentLogoImage(item),
      durationMs: jellyfinTicksToMs(item['RunTimeTicks']),
      viewOffsetMs: jellyfinTicksToMs(_userData(item)?['PlaybackPositionTicks']),
      viewCount: _viewCount(item),
      lastViewedAt: jellyfinIsoToEpochSeconds(_userData(item)?['LastPlayedDate'] as String?),
      // Plex semantics: `leafCount` = total leaf items (episodes for series).
      // Jellyfin's `ChildCount` is direct children (seasons for a series),
      // while `RecursiveItemCount` is the recursive total (episodes). Prefer
      // the recursive count so series show episode counts, not season counts.
      leafCount: (item['RecursiveItemCount'] as int?) ?? (item['ChildCount'] as int?),
      viewedLeafCount: _viewedLeafCount(item),
      childCount: item['ChildCount'] as int?,
      addedAt: jellyfinIsoToEpochSeconds(item['DateCreated'] as String?),
      updatedAt: jellyfinIsoToEpochSeconds(item['DateLastSaved'] as String? ?? item['DateModified'] as String?),
      rating: (item['CommunityRating'] as num?)?.toDouble(),
      // Jellyfin stores a binary `Likes` flag rather than a numeric rating.
      // Map true → 10 / false → 0 so the existing UI's `userRating > 0`
      // check renders the chip as filled for liked items.
      userRating: switch (_userData(item)?['Likes']) {
        true => 10.0,
        false => 0.0,
        _ => null,
      },
      genres: _stringList(item['Genres']),
      directors: _peopleByType(item['People'], 'Director'),
      writers: _peopleByType(item['People'], 'Writer'),
      producers: _peopleByType(item['People'], 'Producer'),
      countries: _stringList(item['ProductionLocations']),
      collections: null,
      labels: _stringList(item['Tags']),
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

  /// Map a Jellyfin "view" (returned by `/Users/{userId}/Views`) into a
  /// [MediaLibrary]. The CollectionType field maps onto [MediaKind] roughly.
  /// Returns `null` when the view is missing `Id` — same rationale as
  /// [mediaItem].
  static MediaLibrary? library(Map<String, dynamic> view, {required String serverId, String? serverName}) {
    final id = view['Id'] as String?;
    if (id == null || id.isEmpty) return null;
    final collectionType = view['CollectionType'] as String?;
    return MediaLibrary(
      id: id,
      backend: MediaBackend.jellyfin,
      title: view['Name'] as String? ?? 'Library',
      kind: _libraryKindFromCollectionType(collectionType, view['Type'] as String?),
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
    required String serverId,
    String? serverName,
    MediaItem? Function(Map<String, dynamic>)? mapItem,
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
      more: items.length >= 20,
      serverId: serverId,
      serverName: serverName,
    );
  }

  static MediaKind _libraryKindFromCollectionType(String? collectionType, String? type) {
    final ct = collectionType?.toLowerCase();
    if (ct != null) {
      return switch (ct) {
        'movies' => MediaKind.movie,
        'tvshows' => MediaKind.show,
        'music' => MediaKind.artist,
        'musicvideos' => MediaKind.clip,
        'homevideos' => MediaKind.clip,
        'photos' => MediaKind.photo,
        'boxsets' => MediaKind.collection,
        'playlists' => MediaKind.playlist,
        'mixed' => MediaKind.unknown,
        _ => MediaKind.unknown,
      };
    }
    return MediaKind.fromString(type);
  }

  static Map<String, dynamic>? _userData(Map<String, dynamic> item) {
    final ud = item['UserData'];
    return ud is Map<String, dynamic> ? ud : null;
  }

  static int _viewCount(Map<String, dynamic> item) {
    final ud = _userData(item);
    if (ud?['Played'] != true) return 0;
    final playCount = ud?['PlayCount'];
    if (playCount is int && playCount > 0) return playCount;
    return 1;
  }

  static int? _viewedLeafCount(Map<String, dynamic> item) {
    final ud = _userData(item);
    final unplayed = ud?['UnplayedItemCount'] as int?;
    // Pair with `leafCount` semantics — episodes recursively, not seasons.
    final total = (item['RecursiveItemCount'] as int?) ?? (item['ChildCount'] as int?);
    if (total == null || unplayed == null) return null;
    final v = total - unplayed;
    return v < 0 ? 0 : v;
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
      final streams = _mediaStreams(src['MediaStreams']);
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

  static List<MediaStream> _mediaStreams(Object? raw) {
    if (raw is! List) return const [];
    final result = <MediaStream>[];
    for (final s in raw) {
      if (s is! Map<String, dynamic>) continue;
      final f = parseJellyfinStreamFields(s, fallbackIndex: result.length);
      final kind = switch (f.type) {
        'video' => MediaStreamKind.video,
        'audio' => MediaStreamKind.audio,
        'subtitle' => MediaStreamKind.subtitle,
        _ => MediaStreamKind.unknown,
      };
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
          selected: f.isDefault,
          channels: f.channels,
          frameRate: f.frameRate,
          forced: f.isForced,
          sidecarPath: f.isExternal ? f.deliveryUrl : null,
        ),
      );
    }
    return result;
  }

  static String? _selfImagePath(String id, Map<String, dynamic> item, String type) {
    final tags = item['ImageTags'];
    final backdropTags = item['BackdropImageTags'];
    String? tag;
    if (type == 'Backdrop' && backdropTags is List && backdropTags.isNotEmpty) {
      tag = backdropTags.first as String?;
      return tag != null ? _itemImagePath(id, 'Backdrop', tag: tag, imageIndex: 0) : null;
    }
    if (tags is Map<String, dynamic>) {
      final value = tags[type];
      if (value is String) tag = value;
    }
    if (tag == null) return null;
    return _itemImagePath(id, type, tag: tag);
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
  /// seasons (parent = series). Pulls the explicit
  /// `ParentBackdropItemId`/`ParentBackdropImageTags` pair Jellyfin
  /// inherits onto child items, falling back to a tagless URL when only
  /// the id is present.
  static String? _parentBackdropImage(Map<String, dynamic> item) {
    final parentId = item['ParentBackdropItemId'] as String?;
    if (parentId == null) return null;
    final tags = item['ParentBackdropImageTags'];
    if (tags is List && tags.isNotEmpty) {
      final tag = tags.first as String?;
      if (tag != null) return _itemImagePath(parentId, 'Backdrop', tag: tag, imageIndex: 0);
    }
    return _itemImagePath(parentId, 'Backdrop', imageIndex: 0);
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
