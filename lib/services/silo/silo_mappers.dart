import '../../media/ids.dart';
import '../../media/media_backend.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_part.dart';
import '../../media/media_rating.dart';
import '../../media/media_role.dart';
import '../../media/media_version.dart';
import 'silo_json.dart';

/// Maps Silo `/api/v2` payloads onto Plezy's backend-neutral models.
///
/// Units on the wire: `runtime` is minutes, every `*_seconds` value and every
/// playback position is seconds, timestamps are RFC 3339. Plezy wants
/// milliseconds for durations/offsets and epoch seconds for timestamps.
class SiloMappers {
  SiloMappers({required this.serverId, required this.serverName, required this.resolveUrl});

  final ServerId serverId;
  final String serverName;

  /// Places server-relative artwork URLs (`/api/v2/artwork/...`) under the
  /// server's base URL and path prefix.
  final String Function(String url) resolveUrl;

  static MediaKind kindOf(Object? type) => switch (str(type).toLowerCase()) {
    'movie' => MediaKind.movie,
    'series' || 'show' || 'tv' => MediaKind.show,
    'season' => MediaKind.season,
    'episode' => MediaKind.episode,
    'collection' || 'library_collection' || 'user_collection' => MediaKind.collection,
    'extra' || 'trailer' || 'clip' => MediaKind.clip,
    _ => MediaKind.unknown,
  };

  /// Library types Plezy can browse: movies, TV and mixed video libraries.
  static bool isVideoLibrary(Object? type) => switch (str(type).toLowerCase()) {
    'movies' || 'movie' || 'tv' || 'shows' || 'series' || 'mixed' || 'video' || 'videos' || '' => true,
    _ => false,
  };

  String? _url(Object? value) {
    final s = strOrNull(value);
    return s == null ? null : resolveUrl(s);
  }

  // ---------------------------------------------------------------- library

  MediaLibrary? library(Map<String, dynamic> json) {
    final id = strOrNull(json['id']);
    if (id == null) return null;
    final type = str(json['type']).toLowerCase();
    final kind = switch (type) {
      'movies' || 'movie' => MediaKind.movie,
      'tv' || 'shows' || 'series' => MediaKind.show,
      _ => MediaKind.unknown,
    };
    return MediaLibrary(
      id: id,
      backend: MediaBackend.silo,
      title: str(json['name']).isEmpty ? 'Library' : str(json['name']),
      kind: kind,
      defaultBrowseKinds: kind == MediaKind.unknown ? const [MediaKind.movie, MediaKind.show] : const [],
      serverId: serverId,
      serverName: serverName,
    );
  }

  // ------------------------------------------------------------------ items

  /// Map a `CatalogItem`, `CatalogItemDetail`, `WatchDetail` or home card.
  MediaItem? item(Map<String, dynamic> json, {String? libraryId, String? libraryTitle}) {
    final id = strOrNull(json['content_id']);
    if (id == null) return null;
    final kind = kindOf(json['type']);
    final userState = asMap(json['user_state']);
    final userData = asMap(json['user_data']);

    final seriesId = strOrNull(json['series_id']);
    final seriesTitle = strOrNull(json['series_title']);
    final seasonNumber = intOrNull(json['season_number']);
    final episodeNumber = intOrNull(json['episode_number']);

    final durationMs =
        secondsToMs(json['duration_seconds']) ??
        secondsToMs(userData['duration_seconds']) ??
        _runtimeMs(json['runtime']);
    final positionMs = secondsToMs(json['position_seconds']) ?? secondsToMs(userData['position_seconds']);
    final played = boolOrNull(userData['played']) ?? boolOrNull(userState['played']) ?? false;
    final inProgress = boolOrNull(userData['is_in_progress']);

    // A played title the viewer has started again reports both `played` and
    // a fresh in-progress position; Plezy shows that as resumable.
    final viewOffsetMs = (positionMs != null && positionMs > 0 && (inProgress ?? true)) ? positionMs : null;

    final poster = _url(json['poster_url']);
    final posterIsStill = boolOr(json['poster_is_episode_still']);
    final backdrop = _url(json['backdrop_url']);
    final backdrops = [
      for (final u in strList(json['backdrop_urls'])) resolveUrl(u),
    ];

    // Container rollups: Silo counts episodes the viewer has watched.
    int? leafCount;
    int? viewedLeafCount;
    if (kind == MediaKind.show || kind == MediaKind.season) {
      final watched = intOrNull(userData['watched_count']);
      final unplayed = intOrNull(userData['unplayed_count']);
      leafCount = intOrNull(json['episode_count']) ?? ((watched != null && unplayed != null) ? watched + unplayed : null);
      viewedLeafCount = watched ?? (played && leafCount != null ? leafCount : null);
    }

    final cast = mapList(json['cast']);
    final crew = mapList(json['crew']);
    final versions = mapList(json['versions']);
    final files = mapList(json['files']);

    return MediaItem.silo(
      id: id,
      kind: kind,
      title: strOrNull(json['title']),
      titleSort: strOrNull(json['sort_title']),
      summary: strOrNull(json['overview']),
      tagline: strOrNull(json['tagline']),
      originalTitle: strOrNull(json['original_title']),
      studio: strList(json['studios']).firstOrNull ?? strList(json['networks']).firstOrNull,
      year: intOrNull(json['year']),
      originallyAvailableAt: strOrNull(json['release_date']) ?? strOrNull(json['air_date']),
      contentRating: strOrNull(json['content_rating']),
      // Episodes: parent = season (Silo has season content ids but cards
      // name the season by number), grandparent = series.
      parentId: switch (kind) {
        MediaKind.season => seriesId,
        MediaKind.episode => seriesId != null && seasonNumber != null ? siloSeasonId(seriesId, seasonNumber) : null,
        _ => null,
      },
      parentTitle: switch (kind) {
        MediaKind.season => seriesTitle,
        MediaKind.episode => seasonNumber != null ? 'Season $seasonNumber' : null,
        _ => null,
      },
      parentIndex: kind == MediaKind.episode ? seasonNumber : null,
      index: switch (kind) {
        MediaKind.episode => episodeNumber,
        MediaKind.season => seasonNumber,
        _ => null,
      },
      grandparentId: kind == MediaKind.episode ? seriesId : null,
      grandparentTitle: kind == MediaKind.episode ? seriesTitle : null,
      grandparentThumbPath: kind == MediaKind.episode && !posterIsStill ? poster : null,
      thumbPath: poster ?? _url(json['still_url']) ?? _url(json['thumb_url']),
      artPath: backdrop ?? backdrops.firstOrNull,
      backdropPaths: backdrops.isEmpty ? (backdrop == null ? null : [backdrop]) : backdrops,
      clearLogoPath: _url(json['logo_url']),
      durationMs: durationMs,
      viewOffsetMs: viewOffsetMs,
      viewCount: kind.usesLeafWatchCounts ? null : (played ? 1 : 0),
      lastViewedAt: isoToEpochSeconds(json['progress_updated_at']),
      leafCount: leafCount,
      viewedLeafCount: viewedLeafCount,
      childCount: kind == MediaKind.show ? intOrNull(json['season_count']) : null,
      addedAt: isoToEpochSeconds(json['added_at']),
      rating: doubleOrNull(json['rating_imdb']) ?? doubleOrNull(json['rating_tmdb']),
      userRating: doubleOrNull(json['user_rating']),
      ratings: _ratings(json),
      isFavorite: boolOrNull(userState['is_favorite']),
      genres: strList(json['genres']),
      directors: [
        for (final c in crew)
          if (str(c['job']).toLowerCase() == 'director' && str(c['name']).isNotEmpty) str(c['name']),
      ],
      writers: [
        for (final c in crew)
          if ((str(c['job']).toLowerCase() == 'writer' || str(c['job']).toLowerCase() == 'screenplay') &&
              str(c['name']).isNotEmpty)
            str(c['name']),
      ],
      countries: strList(json['countries']),
      labels: strList(json['keywords']),
      roles: cast.isEmpty
          ? null
          : [
              for (final c in cast)
                if (str(c['name']).isNotEmpty)
                  MediaRole(
                    id: strOrNull(c['person_id']),
                    tag: str(c['name']),
                    role: strOrNull(c['character']),
                    thumbPath: _url(c['photo_url']),
                  ),
            ],
      mediaVersions: versions.isNotEmpty
          ? [for (final v in versions) _version(v)]
          : (files.isNotEmpty ? [for (final f in files) _version(f)] : null),
      libraryId: libraryId,
      libraryTitle: libraryTitle,
      serverId: serverId,
      serverName: serverName,
      raw: json,
    );
  }

  /// A season row from `listSeriesSeasons`. Seasons are addressed by
  /// series id + number, so the item id is [siloSeasonId].
  MediaItem? season(Map<String, dynamic> json, {required String seriesId, String? seriesTitle, String? seriesPoster}) {
    final number = intOrNull(json['season_number']);
    if (number == null) return null;
    final userData = asMap(json['user_data']);
    final watched = intOrNull(userData['watched_count']);
    final episodes = intOrNull(json['episode_count']);
    return MediaItem.silo(
      id: siloSeasonId(seriesId, number),
      kind: MediaKind.season,
      title: strOrNull(json['title']) ?? (number == 0 ? 'Specials' : 'Season $number'),
      summary: strOrNull(json['overview']),
      originallyAvailableAt: strOrNull(json['air_date']),
      parentId: seriesId,
      parentTitle: seriesTitle,
      parentThumbPath: seriesPoster,
      index: number,
      thumbPath: _url(json['poster_url']) ?? seriesPoster,
      leafCount: episodes,
      viewedLeafCount: watched ?? (boolOr(userData['played']) ? episodes : null),
      serverId: serverId,
      serverName: serverName,
      raw: {...json, 'series_id': seriesId},
    );
  }

  /// An episode row from `listSeasonEpisodes`.
  MediaItem? episode(
    Map<String, dynamic> json, {
    required String seriesId,
    String? seriesTitle,
    String? seriesPoster,
    String? seriesBackdrop,
  }) {
    final id = strOrNull(json['content_id']);
    if (id == null) return null;
    final season = intOrNull(json['season_number']);
    final userData = asMap(json['user_data']);
    final runtimeMs = _runtimeMs(json['runtime']);
    final durationMs = secondsToMs(userData['duration_seconds']) ?? runtimeMs;
    final positionMs = secondsToMs(userData['position_seconds']);
    final inProgress = boolOrNull(userData['is_in_progress']);
    final files = mapList(json['files']);
    return MediaItem.silo(
      id: id,
      kind: MediaKind.episode,
      title: strOrNull(json['title']),
      summary: strOrNull(json['overview']),
      originallyAvailableAt: strOrNull(json['air_date']),
      parentId: season != null ? siloSeasonId(seriesId, season) : null,
      parentTitle: season != null ? (season == 0 ? 'Specials' : 'Season $season') : null,
      parentIndex: season,
      index: intOrNull(json['episode_number']),
      grandparentId: seriesId,
      grandparentTitle: seriesTitle,
      grandparentThumbPath: seriesPoster,
      grandparentArtPath: seriesBackdrop,
      thumbPath: _url(json['still_url']),
      artPath: seriesBackdrop,
      durationMs: durationMs,
      viewOffsetMs: (positionMs != null && positionMs > 0 && (inProgress ?? true)) ? positionMs : null,
      viewCount: boolOr(userData['played']) ? 1 : 0,
      mediaVersions: files.isEmpty ? null : [for (final f in files) _version(f)],
      serverId: serverId,
      serverName: serverName,
      raw: {...json, 'type': 'episode', 'series_id': seriesId, 'series_title': ?seriesTitle},
    );
  }

  MediaVersion _version(Map<String, dynamic> v) {
    final fileId = str(v['file_id']);
    final resolution = strOrNull(v['resolution']);
    final durationMs = secondsToMs(v['duration_seconds']) ?? secondsToMs(v['duration']);
    final unreadable = boolOr(v['unreadable']);
    return MediaVersion(
      id: fileId,
      videoResolution: resolution?.toLowerCase().replaceAll('p', ''),
      videoCodec: strOrNull(v['codec_video']),
      bitrate: () {
        final bps = intOrNull(v['bitrate']);
        return bps == null ? null : bitrateKbpsFromBps(bps);
      }(),
      container: strOrNull(v['container']),
      name: strOrNull(v['edition_raw']),
      parts: [
        MediaPart(
          id: fileId,
          file: strOrNull(v['file_path']) ?? strOrNull(v['file_name']),
          sizeBytes: intOrNull(v['file_size']),
          container: strOrNull(v['container']),
          durationMs: durationMs,
          accessible: unreadable ? false : null,
        ),
      ],
    );
  }

  List<MediaRatingSource>? _ratings(Map<String, dynamic> json) {
    final out = <MediaRatingSource>[
      if (doubleOrNull(json['rating_imdb']) case final v?) MediaRatingSource(source: 'imdb', value: v),
      if (doubleOrNull(json['rating_tmdb']) case final v?) MediaRatingSource(source: 'tmdb', value: v),
      if (doubleOrNull(json['rating_rt_critic']) case final v?)
        MediaRatingSource(source: 'rottenTomatoesCritic', value: v / 10),
      if (doubleOrNull(json['rating_rt_audience']) case final v?)
        MediaRatingSource(source: 'rottenTomatoesAudience', value: v / 10),
    ];
    return out.isEmpty ? null : out;
  }

  static int? _runtimeMs(Object? minutes) {
    final m = intOrNull(minutes);
    return m == null || m <= 0 ? null : m * 60 * 1000;
  }

  // ------------------------------------------------------------------- hubs

  /// One home section as a hub. Continue Watching keeps Plezy's identifier
  /// so the UI applies its resume affordances to it.
  MediaHub? hub(Map<String, dynamic> section) {
    final id = strOrNull(section['id']);
    if (id == null) return null;
    final type = str(section['section_type']);
    final items = [
      for (final card in mapList(section['items'])) ?item(card),
    ];
    if (items.isEmpty) return null;
    final total = intOrNull(section['total_count']) ?? items.length;
    final isContinue = type == siloContinueWatchingSection;
    return MediaHub(
      id: siloHubId(id),
      identifier: isContinue ? 'home.continue' : 'silo.$type',
      title: str(section['title']).isEmpty ? type : str(section['title']),
      type: _hubType(items),
      items: items,
      size: total,
      more: total > items.length,
      serverId: serverId,
      serverName: serverName,
    );
  }

  static String _hubType(List<MediaItem> items) {
    final kinds = items.map((i) => i.kind).toSet();
    if (kinds.length == 1) {
      return switch (kinds.single) {
        MediaKind.movie => 'movie',
        MediaKind.show => 'show',
        MediaKind.episode => 'episode',
        MediaKind.season => 'season',
        _ => 'mixed',
      };
    }
    return 'mixed';
  }
}

const siloContinueWatchingSection = 'continue_watching';

/// Seasons have no stable id in the card payloads Plezy navigates from, so a
/// season is addressed as `{seriesId}#season:{number}`. `#` never occurs in a
/// Silo content id.
String siloSeasonId(String seriesId, int seasonNumber) => '$seriesId#season:$seasonNumber';

({String seriesId, int seasonNumber})? parseSiloSeasonId(String id) {
  final at = id.lastIndexOf('#season:');
  if (at <= 0) return null;
  final number = int.tryParse(id.substring(at + '#season:'.length));
  if (number == null) return null;
  return (seriesId: id.substring(0, at), seasonNumber: number);
}

String siloHubId(String sectionId) => 'silo-section:$sectionId';

String? parseSiloHubId(String hubId) =>
    hubId.startsWith('silo-section:') ? hubId.substring('silo-section:'.length) : null;
